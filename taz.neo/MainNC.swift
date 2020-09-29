//
//  MainNC.swift
//
//  Created by Norbert Thies on 10.08.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit
import MessageUI
import NorthLib


class MainNC: NavigationController, IssueVCdelegate, UIStyleChangeDelegate,
              MFMailComposeViewControllerDelegate {
  
  /// Number of seconds to wait until we stop polling for email confirmation
  let PollTimeout: Int64 = 25*3600
  /* Prevent Black Screen / White Screen Issue
   
   Description:
   - Black Screen appears if 0.4.X Version starts without Internet
      - Issue Scider (Overview) displayed, no Feeder Success Callback, No Downloads, Nothing
   - White Screen appears, if new Istallation, User starts the App an is logged in before Ressources are downloaded
   
   Generell Idea: let monitor = Network.NWPathMonitor()
   react on Internet on/off not available due min iOS 12, currently Build for iOS 11.3
   
   Idea: Popup User should check Internet, if press OK retry...
   */
  
  
  var showAnimations = false
  lazy var consoleLogger = Log.Logger()
  lazy var viewLogger = Log.ViewLogger()
  lazy var fileLogger = Log.FileLogger()
  let net = NetAvailability()
  var _gqlFeeder: GqlFeeder!
  var gqlFeeder: GqlFeeder { return _gqlFeeder }
  var feeder: Feeder { return gqlFeeder }
  lazy var authenticator = DefaultAuthenticator(feeder: self.gqlFeeder)
  var _feed: Feed?
  var feed: Feed { return _feed! }
  var storedFeeder: StoredFeeder!
  var storedFeed: StoredFeed!
  lazy var dloader = Downloader(feeder: feeder)
  static var singleton: MainNC!
  private var isErrorReporting = false
  private var isForeground = false
  private var pollingTimer: Timer?
  private var pollEnd: Int64?
  public var pushToken: String?
  private var inIntro = false
  public var ovwIssues: [Issue]?

  func setupLogging() {
    let logView = viewLogger.logView
    logView.isHidden = true
    view.addSubview(logView)
    logView.pinToView(view)
    Log.append(logger: consoleLogger, /*viewLogger,*/ fileLogger)
    Log.minLogLevel = .Debug
    Log.onFatal { msg in 
      self.log("fatal closure called, error id: \(msg.id)") 
      self.reportFatalError(err: msg)
    }
    net.onChange { (flags) in self.log("net changed: \(flags)") }
    net.whenUp { self.log("Network up") }
    net.whenDown { self.log("Network down") }
    if !net.isAvailable { error("Network not available") }
    let nd = UIApplication.shared.delegate as! AppDelegate
    nd.onSbTap { tview in
      if nd.wantLogging {
        if logView.isHidden {
          self.view.bringSubviewToFront(logView)
          logView.scrollToBottom()
          logView.isHidden = false
        }
        else {
          self.view.sendSubviewToBack(logView)
          logView.isHidden = true
        }
      }
    }
    log("App: \"\(App.name)\" \(App.bundleVersion)-\(App.buildNumber)\n" +
        "\(Device.singleton): \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\n" +
        "Path: \(Dir.appSupportPath)")
  }
  
  func setupRemoteNotifications() {
    let nd = UIApplication.shared.delegate as! AppDelegate
    let dfl = Defaults.singleton
    let oldToken = dfl["pushToken"]
    self.pushToken = oldToken
    nd.onReceivePush { (pn, payload) in
      self.debug(payload.toString())
    }
    nd.permitPush { pn in
      if pn.isPermitted {
        self.debug("Push permission granted")
        self.pushToken = pn.deviceId
      }
      else {
        self.debug("No push permission")
        self.pushToken = nil
      }
      dfl["pushToken"] = self.pushToken
      if oldToken != self.pushToken {
        let isTextNotification = dfl["isTextNotification"]!.bool
        self.gqlFeeder.notification(pushToken: self.pushToken, oldToken: oldToken,
                                    isTextNotification: isTextNotification) { res in
          if let err = res.error() { self.error(err) }
        }
      }
    }
  }
  
  func produceErrorReport(recipient: String, subject: String = "Feedback",
                          completion: (()->())? = nil) {
    if MFMailComposeViewController.canSendMail() {
      let mail =  MFMailComposeViewController()
      let screenshot = UIWindow.screenshot?.jpeg
      let logData = fileLogger.data
      mail.mailComposeDelegate = self
      mail.setToRecipients([recipient])
      
      var tazIdText = ""
      let data = DefaultAuthenticator.getUserData()
      if let tazID = data.id, tazID.isEmpty == false {
        tazIdText = " taz-ID: \(tazID)"
      }
      
      mail.setSubject("\(subject) \"\(App.name)\" (iOS)\(tazIdText)")
      mail.setMessageBody("App: \"\(App.name)\" \(App.bundleVersion)-\(App.buildNumber)\n" +
        "\(Device.singleton): \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\n\n...\n",
        isHTML: false)
      if let screenshot = screenshot {
        mail.addAttachmentData(screenshot, mimeType: "image/jpeg",
                               fileName: "taz.neo-screenshot.jpg")
      }
      if let logData = logData {
        mail.addAttachmentData(logData, mimeType: "text/plain",
                               fileName: "taz.neo-logfile.txt")
      }
      
      mail.modalPresentationStyle = .overCurrentContext
      mail.modalTransitionStyle = .coverVertical
      self.topmostModalVc.present(mail, animated: true, completion: completion)
    }
  }
  
  func sendErrorReport(subject: String = "Feedback",
                          completion: (()->())? = nil) {
    let data = DefaultAuthenticator.getUserData()
      var tazIdText = ""
    if let tazID = data.id, tazID.isEmpty == false {
      tazIdText = " taz-ID: \(tazID)"
    }
    let preparedMessage = "Meine taz-Id: \(tazIdText)\n\nHallo,\n[Ihre Nachricht!, Fehlerbeschreibung, Kritik, Lob]\n\nViele Grüße"
    FeedbackComposer.send(subject: subject,
                          bodyText: preparedMessage,
                          screenshot: UIWindow.screenshot,
                          logData: fileLogger.data) { didSend in
      print("Feedback send? \(didSend)")
                            completion?()
    }
  }
  
  func mailComposeController(_ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true)
    isErrorReporting = false
  }
  
  @objc func errorReportActivated(_ sender: UIGestureRecognizer) {
    if isErrorReporting == true { return }//Prevent multiple Calls
    isErrorReporting = true
    
    guard let recog = sender as? UILongPressGestureRecognizer,
      MFMailComposeViewController.canSendMail()
      else {
        self.sendErrorReport(subject: "Rückmeldung") {
              self.isErrorReporting = false
        }

        return;
        Alert.message(title: Localized("no_mail_title"), message: Localized("no_mail_text"), closure: {
          self.isErrorReporting = false
        })
        return
    }
    Alert.confirm(title: "Rückmeldung",
      message: "Wollen Sie uns eine Fehlermeldung senden oder haben Sie einen " +
               "Kommentar zu unserer App?") { yes in
      if yes {
        var recipient = "app@taz.de"
        if recog.numberOfTouchesRequired == 3 { recipient = "ios-entwickler@taz.de" }
        self.produceErrorReport(recipient: recipient)
      }
      else { self.isErrorReporting = false }
    }
  }
  
  func reportFatalError(err: Log.Message) {
    guard !isErrorReporting else { return }
    isErrorReporting = true
    if self.presentedViewController != nil {
      dismiss(animated: false)
    }
    Alert.confirm(title: "Interner Fehler",
                  message: "Es liegt ein schwerwiegender interner Fehler vor, möchten Sie uns " +
                           "darüber mit einer Nachricht informieren?\n" +
                           "Interne Fehlermeldung:\n\(err)") { yes in
      if yes {
        self.produceErrorReport(recipient: "app@taz.de", subject: "Interner Fehler") 
      }
      else { self.isErrorReporting = false }
    }
  }
  
  @objc func threeFingerTouch(_ sender: UIGestureRecognizer) {
//    let logView = viewLogger.logView
    let actions: [UIAlertAction] = [
      Alert.action("Fehlerbericht senden") {_ in self.errorReportActivated(sender) },
      Alert.action("Alle Ausgaben löschen") {_ in self.deleteAll() },
      Alert.action("Kundendaten löschen") {_ in self.deleteUserData() },
      Alert.action("Abo-Verknüpfung löschen") {_ in self.unlinkSubscriptionId() },
      Alert.action("Abo-Push anfordern") {_ in self.testNotification(type: NotificationType.subscription) },
      Alert.action("Download-Push anfordern") {_ in self.testNotification(type: NotificationType.newIssue) },
//      Alert.action("Protokoll an/aus") {_ in
//        if logView.isHidden {
//          self.view.bringSubviewToFront(logView)
//          logView.scrollToBottom()
//          logView.isHidden = false
//        }
//        else {
//          self.view.sendSubviewToBack(logView)
//          logView.isHidden = true
//        }
//      }
    ]
    Alert.actionSheet(title: "Beta (v) \(App.version)-\(App.buildNumber)",
      actions: actions)
  }
  
  func setupTopMenus(view:UIView? = nil) {
    let reportLPress2 = UILongPressGestureRecognizer(target: self,
        action: #selector(errorReportActivated))
    let reportLPress3 = UILongPressGestureRecognizer(target: self,
        action: #selector(threeFingerTouch))
    reportLPress2.numberOfTouchesRequired = 2
    reportLPress3.numberOfTouchesRequired = 3
    if let targetView = UIApplication.shared.keyWindow {
      targetView.isUserInteractionEnabled = true
      targetView.addGestureRecognizer(reportLPress2)
      targetView.addGestureRecognizer(reportLPress3)
    }
  }
    
  func handleFeederError(_ err: FeederError) {
    var text = ""
    switch err {
    case .invalidAccount: text = "Ihre Kundendaten sind nicht korrekt."
    case .expiredAccount: text = "Ihr Abo ist abgelaufen."
    case .changedAccount: text = "Ihre Kundendaten haben sich geändert."
    case .unexpectedResponse:
      Alert.message(title: "Fehler",
                    message: "Es gab ein Problem bei der Kommunikation mit dem Server") {
        exit(0)
      }
    }
    deleteUserData()
    Alert.message(title: "Fehler", message: text) {
      Notification.send("userLogin", object: nil)
    }
  }
  
  func getOverview() {
    gqlFeeder.issues(feed: feed, count: 20) { res in
      if let issues = res.value() {
        Notification.send("overviewReceived", object: issues)
      }
      else if let err = res.error() as? FeederError {
        self.handleFeederError(err)
      }
    }
  }
  
  func overviewReceived(issues: [Issue]) {
    ovwIssues = issues
//    for issue in issues {
//      let sissues = StoredIssue.get(date: issue.date, inFeed: storedFeed)
//    }
    if !inIntro { showIssueVC() }
  }
  
  func setupPolling() {
    self.authenticator.whenPollingRequired { self.startPolling() }
    if let peStr = Defaults.singleton["pollEnd"] {
      let pe = Int64(peStr)
      if pe! <= UsTime.now().sec { endPolling() }
      else {
        pollEnd = pe
        self.pollingTimer = Timer.scheduledTimer(withTimeInterval: 60.0,
          repeats: true) { _ in self.doPolling() }
      }
    }
  }
  
  func startPolling() {
    self.pollEnd = UsTime.now().sec + PollTimeout
    Defaults.singleton["pollEnd"] = "\(pollEnd!)"
    self.pollingTimer = Timer.scheduledTimer(withTimeInterval: 60.0,
      repeats: true) { _ in self.doPolling() }
  }
  
  func doPolling() {
    self.authenticator.pollSubscription { [weak self] doContinue in
      guard let self = self else { return }
      guard let pollEnd = self.pollEnd else { self.endPolling(); return }
      if doContinue { if UsTime.now().sec > pollEnd { self.endPolling() } }
      else {
        self.endPolling()
        if self.gqlFeeder.isAuthenticated { /*reloadIssue()*/ }
      }
    }
  }
  
  func endPolling() {
    self.pollingTimer?.invalidate()
    self.pollEnd = nil
    Defaults.singleton["pollEnd"] = nil
  }
  
  func userLogin(closure: @escaping (Error?)->()) {
    let (_,_,token) = DefaultAuthenticator.getUserData()
    if let token = token {
      self.gqlFeeder.authToken = token
      closure(nil)
    }
    else {
      self.setupPolling()
      Notification.receive("authenticationSucceeded") {_ in
        closure(nil)
      }
      self.authenticator.authenticate()
    }
  }
    
  func setupFeeder(closure: @escaping (Result<Feeder,Error>)->()) {
    self._gqlFeeder = GqlFeeder(title: "taz", url: "https://dl.taz.de/appGraphQl") { [weak self] (res) in
      guard let self = self else { return }
      guard res.value() != nil else {
        Alert.message(title: "Fehler",
                       message: Localized("communication_breakdown")) { [weak self] in
                        guard let self = self else {return}
                        self.setupFeeder(closure: closure)
        }
        return;
      }
      self.debug(self.gqlFeeder.toString())
      self._feed = self.gqlFeeder.feeds[0]
      self.storedFeeder = StoredFeeder.persist(object: self.gqlFeeder)
      Notification.receive("overviewReceived") { [weak self] issues in
        if let issues = issues as? [Issue] {
          self?.overviewReceived(issues: issues)
        }
      }
      self.dloader.downloadResources{ _ in}
      
      Notification.receive("userLogin") { [weak self] _ in
        self?.userLogin() { [weak self] err in
          guard let self = self else { return }
          if err != nil { exit(0) }
          /// #1 Update authToken: [SOLVED]
          /// in GqlFeeder => public func authenticate
          /// ...
          /// case .success(let auth):
          /// let atoken = auth["authToken"]!
          /// self?.status?.authInfo = atoken.authInfo
          /// ...
          /// Not In:  extension GqlFeeder => subscriptionPoll, subscriptionId2tazId, trialSubscription
          /// Previous Version did update this by authenticate(closure: @escaping (Error?, String?)->())
          /// Still had some edge cases with just Preview Articles, after App Restart they worked
          /// ...
          /// So moved update the shared gqlFeeder.auth when setting token to keychain
          /// ...
          ///  Other Option acces here the Keychain stored earlier is more complicated due store keychain needs to be called before callback
          ///  Maybe refactor:  extension Authenticator => public static func storeUserData(id: String, password: String, token: String)
          ///  to instance function to update its feeder, but then the GqlFeeder => public func authenticate makes his own thing
          ///  nth Option: let (_,_,token) = DefaultAuthenticator.getUserData()
          ///
          /// #2 Problem, lange verzögerung bis download files abgeglichen sind und Intro gezeigt wird [SOLVED]
          /// together with line 281: self.dloader.downloadResou... and authToken Store this is the best Solution!
          ///
          /// #3 User accepts AGB and more twice
          /// due he still accept is in various cases in createtazID or trialSubscription
          /// so we need seperate intro store userDefaults for already seen Intro!
//          self.showIntro()
          ///@Norbert Integration
          self.dloader.downloadResources {_ in
            self.showIntro()
            self.getOverview()
          }
        }
      }
      Notification.send("userLogin")
      closure(.success(self.feeder))
    }
  }
    
  func showIssueVC() {
    self.setupRemoteNotifications()
    let ivc = IssueVC()
    ivc.delegate = self
    replaceTopViewController(with: ivc, animated: false)
  }
  
  func showIntro() {
    let hasAccepted = Keychain.singleton["dataPolicyAccepted"]
    if hasAccepted == nil || !hasAccepted!.bool {
      debug("Showing Intro")
      inIntro = true
      let introVC = IntroVC()
      introVC.htmlDataPolicy = feeder.dataPolicy
      introVC.htmlIntro = feeder.welcomeSlides
      Notification.receive("dataPolicyAccepted") { [weak self] obj in
        self?.introHasFinished()
      }
      pushViewController(introVC, animated: false)
    }
    else if ovwIssues != nil { showIssueVC() }
  }
  
  func introHasFinished() {
    popViewController(animated: false)
    let kc = Keychain.singleton
    kc["dataPolicyAccepted"] = "true"
    if ovwIssues != nil { showIssueVC() }
  }
  
  func startup() {
    let dfl = Defaults.singleton
    dfl.setDefaults(values: ConfigDefaults)
    let oneWeek = 7*24*3600
    let nStarted = dfl["nStarted"]!.int!
    let lastStarted = dfl["lastStarted"]!.usTime
    debug("Startup: #\(nStarted), last: \(lastStarted.isoDate())")
    let now = UsTime.now()
    self.showAnimations = (nStarted < 2) || (now.sec - lastStarted.sec) > oneWeek
    IssueVC.showAnimations = self.showAnimations
    SectionVC.showAnimations = self.showAnimations
    ContentTableVC.showAnimations = self.showAnimations
    dfl["nStarted"] = "\(nStarted + 1)"
    dfl["lastStarted"] = "\(now.sec)"
    Database.dbRename(old: "ArticleDB", new: "taz")
    ArticleDB(name: "taz") { [weak self] err in
      guard let self = self else { return }
      guard err == nil else { exit(1) }
      self.debug("DB opened: \(ArticleDB.singleton!)")
      self.setupFeeder { [weak self] _ in
        guard let self = self else { return }
        self.debug("Feeder ready.")
      }
    }
  }
  
  @objc func goingBackground() {
    isForeground = false
    debug("Going background")
  }
  
  @objc func goingForeground() {
    isForeground = true
    debug("Entering foreground")
  }
 
  func deleteAll() {
    popToRootViewController(animated: false)
    for f in Dir.appSupport.scan() {
      debug("remove: \(f)")
      try! FileManager.default.removeItem(atPath: f)
    }
    exit(0)
  }
  
  func unlinkSubscriptionId() {
    SimpleAuthenticator(feeder: self.gqlFeeder).unlinkSubscriptionId()
  }
  
  func getUserData() -> (token: String?, id: String?, password: String?) {
    let dfl = Defaults.singleton
    let kc = Keychain.singleton
    var token = kc["token"]
    var id = kc["id"]
    let password = kc["password"]
    if token == nil {
      token = dfl["token"]
      if token != nil { kc["token"] = token }
    }
    else { dfl["token"] = token }
    if id == nil {
      id = dfl["id"]
      if id != nil { kc["id"] = id }
    }
    return(token, id, password)
  }
  
  func deleteUserData() {
    let dfl = Defaults.singleton
    let kc = Keychain.singleton
    kc["token"] = nil
    kc["id"] = nil
    kc["password"] = nil
    kc["dataPolicyAccepted"] = nil
    dfl["token"] = nil
    dfl["id"] = nil
    dfl["pushToken"] = nil
    dfl["isTextNotification"] = "true"
    dfl["nStarted"] = "0"
    dfl["lastStarted"] = "0"
    endPolling()
  }
  
  func testNotification(type: NotificationType) {
    self.gqlFeeder.testNotification(pushToken: self.pushToken, request: type) {_ in}
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    pushViewController(StartupVC(), animated: false)
    MainNC.singleton = self
    isNavigationBarHidden = true
    isForeground = true
    onPopViewController { vc in
      if vc is IssueVC || vc is IntroVC {
        return false
      }
      return true
    }
    // isEdgeDetection = true
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(goingBackground),
      name: UIApplication.willResignActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(goingForeground),
                   name: UIApplication.willEnterForegroundNotification, object: nil)
    setupLogging()
    startup()
    registerForStyleUpdates()
  }
  func applyStyles() {
      self.view.backgroundColor = Const.SetColor.HBackground.color
    setNeedsStatusBarAppearanceUpdate()

  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupTopMenus()
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return Defaults.darkMode ?  .lightContent : .default
  }

      

} // MainNC
