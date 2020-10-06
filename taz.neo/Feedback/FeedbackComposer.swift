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
 - DONE Total BG (Anfasser auf Transparent)
 - DONE Text Area BG = BG
 - DONE LOng Touch to remove
 - DONE integrate screenshot
 - DONE integrate log
 - DONE tap to show
 - DONE send feedback
 - DONE move to taz.neo to reduce complexity
 - DONE Feedback Type error/feedback
 - show serverdata enable mail field...
 - refactor kill memory leaks
 */

public enum FeedbackType { case error, feedback }

open class FeedbackComposer : DoesLog{
  
  public static func send(type: FeedbackType,
                   subject: String,
                   bodyText: String,
                   screenshot: UIImage? = nil,
                   logData: Data? = nil,
                   gqlFeeder: GqlFeeder,
                   finishClosure: @escaping ((Bool) -> ())) {
    
    guard let currentVc = UIViewController.top() else {
      print("Error, no Controller to Present")
      return;
    }
    
    var feedbackBottomSheet : FeedbackBottomSheet?
    
    let feedbackViewController = FeedbackViewController(type: type,
                                                        subject: subject,
                                                        bodyText: bodyText,
                                                        screenshot: screenshot,
                                                        logData: logData,
                                                        gqlFeeder: gqlFeeder,
                                                        finishClosure: {
                                                          (send) in
                                                          feedbackBottomSheet?.sendSuccees = send
                                                          feedbackBottomSheet?.close()
                                                          finishClosure(send)
    })
    
    feedbackBottomSheet = FeedbackBottomSheet(slider: feedbackViewController,
                                                  into: currentVc)
    feedbackBottomSheet?.sliderView.backgroundColor = Const.SetColor.CTBackground.color
    feedbackBottomSheet?.coverageRatio = 1.0
    feedbackBottomSheet?.onClose(closure: { (slider) in
      var sendSuccess = false
      if let fb = feedbackBottomSheet {
        sendSuccess = fb.sendSuccees
      }
      finishClosure(sendSuccess)
      feedbackBottomSheet = nil//Important the memory leak!
    })
    feedbackBottomSheet?.open()
  }
}



