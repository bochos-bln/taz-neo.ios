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
 - evaluate values for free ram & more on open not send
 - show serverdata enable mail field...
 - handle fatal Errors.. & test...
 - iOS 11/12 Contect Menü Icons?
 - handle empty important fields
 - refactor/mode todos (to own files)
 */

public struct DeviceData {
  init() {
    freeRam = 2.0
  }
  var freeRam : Float
}

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
    
    /******
    let data = DefaultAuthenticator.getUserData()
      var tazIdText = ""
    if let tazID = data.id, tazID.isEmpty == false {
      tazIdText = " taz-ID: \(tazID)"
    }
    */
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
//    Alert.actionSheet(title: "Rückmeldung",
//                      message: "Möchten Sie einen Fehler melden oder uns Feedback geben?",
//                      actions: [feedbackAction, errorReportAction])
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
    
    let feedbackViewController = FeedbackViewController(type: type,
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
    
    feedbackBottomSheet?.onUserSlideToClose = ({
      feedbackBottomSheet?.slide(toOpen: true, animated: true)
      Alert.confirm(message: Localized("feedback_cancel_title"),
                    isDestructive: true) { (close) in
                      if close {
                        feedbackBottomSheet?.slide(toOpen: false, animated: true)
                      }
      }
    })
    
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



