//
//  TazFeedbackComposer.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 30.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import NorthLib
/**
 TODOS
 - Total BG (Anfasser auf Transparent)
 - Text Area BG = BG
 - LOng Touch to remove
 - integrate screenshot
 - integrate log
 - tap to show
 - send feedback
 */

open class TazFeedbackComposer : FeedbackComposer{
  public static let tazShared = TazFeedbackComposer()
  
  override public init() {
    super.init()
  }
  
  //todo on remove screenshot
  
  public func send(subject: String, bodyText: String, screenshot: UIImage? = nil, logData: Data? = nil, gqlFeeder: GqlFeeder, finishClosure: @escaping ((Bool) -> ())) {
    _myfeedbackViewController.gqlFeeder = gqlFeeder
    
    super.send(subject: subject, bodyText: bodyText, screenshot: screenshot, logData: logData, finishClosure: finishClosure)
  }
  
  let _myfeedbackViewController = TazFeedbackViewController()
  public override var feedbackViewController : FeedbackViewController {
    get {
      return _myfeedbackViewController
      
    }
  }
}
open class TazFeedbackViewController : FeedbackViewController{
  
  var gqlFeeder: GqlFeeder?
  
  @objc public override func handleSend(){
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
    
    feeder.errorReport(message: message, errorProtocol: errorProtocol, screenshotName: screenshotName, screenshot: screenshotData) { (result) in
      print("Result")
    }
  }
  
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    feedbackView.backgroundColor
      = Const.SetColor.CTBackground.color
    feedbackView.messageTextView.backgroundColor
      = Const.SetColor.ForegroundLight.color
    feedbackView.messageTextView.textColor = Const.SetColor.HText.color
  }
}
