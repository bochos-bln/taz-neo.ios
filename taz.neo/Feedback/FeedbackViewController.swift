//
//  FeedbackViewController.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 02.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import NorthLib

/**
 Feedback oder Fehler
 
 Bei Feedback Ihre Nachricht
 
 bei Fehler:
 
 Ihre Nachhricht
 Beschreiben Sie ihr Problem bitte hier.
 
 Letzte Interaktion
 Was waren die letzten Aktionen, die Sie mit der App durchgeführt haben, bevor das Problem aufgetreten ist?
 
 Zustand
 Beschreiben Sie mögliche Außeneinflüsse bitte hier. War das WLAN an?, Benutzen Sie eine Firewall, Proxy? Gab es Netzwerkprobleme, genügend Speicher, aussreichend Akku...
 */

public class FeedbackViewController : UIViewController{
  
  deinit {
    print("deinit: FeedbackViewController ;-)")
  }
  
  var type: FeedbackType?
  var bodyText: String?
  var screenshot: UIImage? {
    didSet{
      feedbackView?.screenshotAttachmentButton.image = screenshot
    }
  }
  var logData: Data? = nil
  var gqlFeeder: GqlFeeder?
  var finishClosure: ((Bool) -> ())?
  
  public var feedbackView : FeedbackView?
  
  init(type: FeedbackType,
       subject: String,
       bodyText: String,
       screenshot: UIImage? = nil,
       logData: Data? = nil,
       gqlFeeder: GqlFeeder,
       finishClosure: @escaping ((Bool) -> ())) {
    self.feedbackView = FeedbackView(type: type, subject:subject, bodyText:bodyText)
    self.screenshot = screenshot
    self.type = type
    self.logData = logData
    self.gqlFeeder = gqlFeeder
    self.finishClosure = finishClosure
    super.init(nibName: nil, bundle: nil)
  }
  
  public override func viewDidDisappear(_ animated: Bool) {
    self.feedbackView = nil
    self.type = nil
    self.screenshot = nil
    self.logData = nil
    self.gqlFeeder = nil
    self.finishClosure = nil
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    guard let feedbackView = self.feedbackView else { return; }
    //didSet not called in init, so set the button`s image here
    feedbackView.screenshotAttachmentButton.image = screenshot
    
    if gqlFeeder?.authToken != nil {
      //User is logged In
      feedbackView.additionalInfoLabel.text = "additionalInfoLabel.text"
      feedbackView.senderMail.placeholder = "Antwort Mail"
    }
    else {
      //User is not logged in
      feedbackView.additionalInfoLabel.text = "additionalInfoLabel.text"
      feedbackView.senderMail.placeholder = "Antwort Mail"
    }
    
    self.view.addSubview(feedbackView)
    pin(feedbackView, to:self.view)
    
    feedbackView.screenshotAttachmentButton.onTapping { [weak self] (_) in
      self?.showScreenshot()
    }
    
    feedbackView.logAttachmentButton.onTapping {  [weak self] (_) in
      self?.showLog()
    }
    
    feedbackView.messageTextView.delegate = self
    /// Setup Attatchment Menus
    _ = logAttatchmentMenu
    _ = screenshotAttatchmentMenu
    
    feedbackView.sendButton.addTarget(self,
                                      action: #selector(handleSend),
                                      for: .touchUpInside)
  }
  
  @objc public func handleSend(){
    guard let message = feedbackView?.messageTextView.text else {
      log("Send not possible no message")
      return;
    }
    
    var screenshotData : String?
    var screenshotName : String?
    
//    if let sc = screenshot {
//      screenshotData = sc.pngData()?.base64EncodedString()
//      screenshotName = "Screenshot_\(Date())"
//    }
//
    var logString:String?
//    if let data = logData {
//      logString = String(data:data , encoding: .utf8)
//    }
    
    
    gqlFeeder?.errorReport(message: message,
                           lastAction: feedbackView?.lastInteractionTextView.text,
                           conditions: feedbackView?.environmentTextView.text,
                           errorProtocol: logString,
                           eMail: feedbackView?.senderMail.text,
                           screenshotName: screenshotName,
                           screenshot: screenshotData) { (result) in
      print("Result")
    }
  }
  
  //TODO: Optimize, take care of Memory Leaks
  func showScreenshot(){
    print("Open detail View")
    let oi = OptionalImageItem()
    //    oi.image = self.feedbackView.screenshotAttachmentButton.image
    let ziv = ZoomedImageView(optionalImage:oi)
    let vc = UIViewController()
    vc.view.addSubview(ziv)
    pin(ziv, to: vc.view)
    let overlay = Overlay(overlay: vc, into: self)
    
    vc.view.frame = self.view.frame
    vc.view.setNeedsLayout()
    vc.view.layoutIfNeeded()
    overlay.overlaySize = self.view.frame.size
    let openToRect = self.view.frame
    
    ziv.addBorder(.green)
    
    guard let child = self.feedbackView?.screenshotAttachmentButton else {
      //tapped button disapeared - impossible
      return;
    }
    let fromFrame = child.convert(child.frame, to: self.view)
    
    overlay.openAnimated(fromFrame: fromFrame,
                         toFrame: openToRect)
//    overlay.onClose {
//      overlay = nil
//      ziv = nil
//      io = nil
//      vc = nil
//    }
  }
  
  func showLog(){
    let logVc = UIViewController()
    let logView = SimpleLogView()
    
    var logString:String?
    if let data = logData {
      logString = String(data:data , encoding: .utf8)
    }
    
    logView.append(txt: logString ?? "")
    logVc.view.addSubview(logView)
    pin(logView, to: logVc.view)
    self.present(logVc, animated: true) {
      print("done!!")
    }
  }
  
  lazy var logAttatchmentMenu : ContextMenu? = {
    guard let target = self.feedbackView?.logAttachmentButton else { return nil }
    let menu = ContextMenu(view: target)
    menu.addMenuItem(title: "View", icon: "eye") {[weak self]  (_) in
      self?.showLog()
    }
    menu.addMenuItem(title: "Löschen", icon: "trash.circle") { (_) in
      self.feedbackView?.logAttachmentButton.removeFromSuperview()
    }
    menu.addMenuItem(title: "Abbrechen", icon: "multiply.circle") { (_) in }
    return menu
  }()
  
  lazy var screenshotAttatchmentMenu : ContextMenu? = {
    guard let target = self.feedbackView?.screenshotAttachmentButton else { return nil}
    let menu = ContextMenu(view: target)
    menu.addMenuItem(title: "View", icon: "eye") { [weak self]  (_) in
      self?.showScreenshot()
    }
    menu.addMenuItem(title: "Löschen", icon: "trash.circle") { (_) in
      self.feedbackView?.screenshotAttachmentButton.removeFromSuperview()
      //self.screenshot = nil
    }
    menu.addMenuItem(title: "Abbrechen", icon: "multiply.circle") { (_) in }
    return menu
  }()
  
  /// Define the menu to display on long touch of a MomentView
  public var attatchmentMenu: [(title: String, icon: String, closure: (String)->())] = []
  
  /// Add an additional menu item
  public func addMenuItem(title: String, icon: String, closure: @escaping (String)->()) {
    attatchmentMenu += (title: title, icon: icon, closure: closure)
  }
  
  public var mainmenu1 : ContextMenu?
  public var mainmenu2 : ContextMenu?
  
}

extension FeedbackViewController : UITextViewDelegate {
  public func textViewDidEndEditing(_ textView: UITextView){
    if textView == self.feedbackView?.messageTextView {
      self.feedbackView?.sendButton.isEnabled = !textView.text.isEmpty
    }
  }
}
