//
//  FeedbackViewController.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 02.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import NorthLib

open class FeedbackViewController : UIViewController{
  
  public var subject : String? {
    didSet {
      feedbackView.subjectLabel.text = subject
    }
  }
  var gqlFeeder: GqlFeeder?
  public var logString: String? = "-"
  public var screenshot: UIImage? {
    didSet {
      feedbackView.screenshotAttachmentButton.image = screenshot
    }
  }
  
  @objc public func handleSend(){
    guard let feeder = gqlFeeder else { return }
    
    let message = (subject ?? "").isEmpty
      ? feedbackView.messageTextView.text
      : "\(subject ?? "")\n\n\(feedbackView.messageTextView.text ?? "-")"
    
    var screenshotData : String?
    var screenshotName : String?
    
    if let sc = screenshot {
      screenshotData = sc.pngData()?.base64EncodedString()
      screenshotName = "Screenshot_\(Date())"
    }
    
    let errorProtocol = logString ?? ""
    
    feeder.errorReport(message: message, errorProtocol: errorProtocol, eMail: nil, screenshotName: screenshotName, screenshot: screenshotData) { (result) in
      print("Result")
    }
  }
  
  
  public let feedbackView = FeedbackView()
  
  //TODO: Optimize, take care of Memory Leaks
  func showScreenshot(){
    print("Open detail View")
    let oi = OptionalImageItem()
    oi.image = self.feedbackView.screenshotAttachmentButton.image
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
    
    let child = self.feedbackView.screenshotAttachmentButton
    let fromFrame = child.convert(child.frame, to: self.view)
    
    overlay.openAnimated(fromFrame: fromFrame,
                         toFrame: openToRect)
  }
  
  //TODO: Optimize, take care of Memory Leaks
  func showLog(){
    let logVc = UIViewController()
    let logView = SimpleLogView()
    logView.append(txt: logString ?? "")
    logVc.view.addSubview(logView)
    pin(logView, to: logVc.view)
    self.present(logVc, animated: true) {
      print("done!!")
    }
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
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
  }
  
  lazy var logAttatchmentMenu : ContextMenu = {
    let menu = ContextMenu(view: self.feedbackView.logAttachmentButton)
    menu.addMenuItem(title: "View", icon: "eye") {[weak self]  (_) in
      self?.showLog()
    }
    menu.addMenuItem(title: "Löschen", icon: "trash.circle") { (_) in
      self.feedbackView.logAttachmentButton.removeFromSuperview()
    }
    menu.addMenuItem(title: "Abbrechen", icon: "multiply.circle") { (_) in }
    return menu
  }()
  
  lazy var screenshotAttatchmentMenu : ContextMenu = {
    let menu = ContextMenu(view: self.feedbackView.screenshotAttachmentButton)
    menu.addMenuItem(title: "View", icon: "eye") { [weak self]  (_) in
      self?.showScreenshot()
    }
    menu.addMenuItem(title: "Löschen", icon: "trash.circle") { (_) in
      self.feedbackView.screenshotAttachmentButton.removeFromSuperview()
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
    if textView == self.feedbackView.messageTextView {
      self.feedbackView.sendButton.isEnabled = !textView.text.isEmpty
    }
  }
}
