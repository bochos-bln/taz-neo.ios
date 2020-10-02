//
//  FeedbackComposer.swift
//  taz.neo
//
//  Created by Ringo Müller-Gromes on 25.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit
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


open class FeedbackComposer : DoesLog{
  static let shared = FeedbackComposer()
  public init() {}
  ///Remember Bottom Sheet due its strong reference to active (VC) it wount be de-inited
  public private(set) var feedbackBottomSheet : FeedbackBottomSheet?
  
  
  let _feedbackViewController = FeedbackViewController()
  open var feedbackViewController : FeedbackViewController {
    get { return _feedbackViewController }
  }
  
  
  public func send(subject: String, bodyText: String, screenshot: UIImage? = nil, logData: Data? = nil, gqlFeeder: GqlFeeder, finishClosure: @escaping ((Bool) -> ())) {
    _feedbackViewController.gqlFeeder = gqlFeeder
    
    
    
    
    guard let currentVc = UIViewController.top() else {
      log("Error, no Controller to Present")
      return;
    }
    
    //ToDo may do nothing if still presented!?
    if feedbackBottomSheet == nil {
      feedbackBottomSheet = FeedbackBottomSheet(slider: feedbackViewController,
                                                into: currentVc)
      
    }
    else {
      feedbackBottomSheet?.activeVC = currentVc
    }
    
    
    feedbackBottomSheet?.sliderView.backgroundColor = Const.SetColor.CTBackground.color
    
    if let feedbackCtrl = feedbackBottomSheet?.sliderVC as? FeedbackViewController {
      feedbackCtrl.feedbackView.messageTextView.text = bodyText
      feedbackCtrl.screenshot = screenshot
      if let data = logData {
        feedbackCtrl.logString = String(data:data , encoding: .utf8)
      }
      
      feedbackCtrl.subject = subject
      feedbackCtrl.feedbackView.sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
    }
    
    guard let feedbackBottomSheet = feedbackBottomSheet else { return }
    
    feedbackBottomSheet.onClose { (slida) in
      finishClosure(true)
      self.feedbackBottomSheet = nil
    }
    self.feedbackBottomSheet?.coverageRatio = 1.0
    self.feedbackBottomSheet?.open()
  }
  
  @objc open func handleSend(){
    if let feedbackCtrl = feedbackBottomSheet?.sliderVC as? FeedbackViewController {
      feedbackCtrl.handleSend()
    }
  }
}



