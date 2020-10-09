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
 - DONE refactor kill memory leaks =>   Overlay&ZoomedImageView ... Optimize, take care of Memory Leaks
 - Check if still working in Article & more!!
 - Overlay, seams to work testet in Simulator in ArticleCV && deinit for Overlay Called
 - not for ZoomedImageView? =>  its ContentImageVC => also not => Ticket created #12863
 - ZoomedImageView
 - DONE handle close by pull down
 - DONE fix status bar hidden
 - WORKAROUND DONE fix screenshot fullscreen border, not using overlay, not using zoomed ImageView
 - DONE handle difference between feedback and error report
 - DONE evaluate values for free ram & more on open not send
 -  show serverdata
 - DONE mail field is enabled permanently // SOLVED DIFFERNTLY enable mail field...
 - handle fatal Errors.. & test...
 - DONE iOS 11/12 Contect Menü Icons? ...only doc icon needed context menüs not!
 - DONE DarkMode Colors
 - DONE handle empty important fields
 - DONE refactor/mode todos (to own files)
 - DONE Prevent Multi Send /Block UI
 - DONE RESIZE Image to have smaller send footprint
 - FEEDBACK REQUIRED make the buttons similar 
 */

public enum FeedbackType { case error, feedback, fatalError }

open class FeedbackComposer : DoesLog{
  
  public static func requestSendFatal(logData: Data? = nil,
                                      gqlFeeder: GqlFeeder,
                                      finishClosure: @escaping ((Bool) -> ())) {
    print("toDo")
  }
  
  public static func requestFeedback(logData: Data? = nil,
                                     gqlFeeder: GqlFeeder,
                                     finishClosure: @escaping ((Bool) -> ())) {
    let screenshot = UIWindow.screenshot
    let deviceData = DeviceData()
    
    let feedbackAction = UIAlertAction(title: "Feedback geben", style: .default) { _ in
      FeedbackComposer.send(type: FeedbackType.feedback,
                            gqlFeeder: gqlFeeder,
                            finishClosure: finishClosure)
    }
    
    let errorReportAction = UIAlertAction(title: "Fehler melden", style: .destructive) { _ in
      FeedbackComposer.send(type: FeedbackType.error,
                            deviceData: deviceData,
                            screenshot: screenshot,
                            logData: logData,
                            gqlFeeder: gqlFeeder,
                            finishClosure: finishClosure)
    }
    let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel) { _ in finishClosure(false) }
    
    Alert.message(title: "Rückmeldung", message: "Möchten Sie einen Fehler melden oder uns Feedback geben?", actions: [feedbackAction, errorReportAction, cancelAction])
  }
  
  public static func send(type: FeedbackType,
                          deviceData: DeviceData? = nil,
                          screenshot: UIImage? = nil,
                          logData: Data? = nil,
                          gqlFeeder: GqlFeeder,
                          finishClosure: @escaping ((Bool) -> ())) {
    
    guard let currentVc = UIViewController.top() else {
      print("Error, no Controller to Present")
      return;
    }
    
    var feedbackBottomSheet : FeedbackBottomSheet?
    
    let feedbackViewController
      = FeedbackViewController(
        type: type,
        screenshot: screenshot,
        deviceData: deviceData,
        logData: logData,
        gqlFeeder: gqlFeeder){
          feedbackBottomSheet?.slide(toOpen: false, animated: true)
          
    }
                                                       
    feedbackBottomSheet = FeedbackBottomSheet(slider: feedbackViewController,
                                              into: currentVc)
    feedbackBottomSheet?.sliderView.backgroundColor = Const.SetColor.CTBackground.color
    feedbackBottomSheet?.coverageRatio = 1.0
    
    feedbackBottomSheet?.onUserSlideToClose = ({
      guard let feedbackBottomSheet = feedbackBottomSheet else { return }
      feedbackBottomSheet.slide(toOpen: true, animated: true)
      Alert.confirm(message: Localized("feedback_cancel_title"),
                    isDestructive: true) { (close) in
                      if close {
                        feedbackBottomSheet.slide(toOpen: false, animated: true)
                      }
      }
    })
    
    feedbackBottomSheet?.onClose(closure: { (slider) in
      finishClosure(feedbackViewController.sendSuccess)
      feedbackBottomSheet = nil//Important the memory leak!
    })
    feedbackBottomSheet?.open()
  }
}



