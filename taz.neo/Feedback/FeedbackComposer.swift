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
 - refactor/mode todos (to own files)
 */

class Storage
{

    static func getFreeSpace() -> Int64
    {
        do
        {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])

            return attributes[FileAttributeKey.systemFreeSize] as! Int64
        }
        catch
        {
            return 0
        }
    }

    static func getTotalSpace() -> Int64
    {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            return attributes[FileAttributeKey.systemSize] as! Int64
        } catch {
            return 0
        }
    }

    static func getUsedSpace() -> Int64
    {
        return getTotalSpace() - getFreeSpace()
    }




}




public struct DeviceData : DoesLog {
  typealias ram = (ramUsed:String?, ramAvailable:String?)
  
  var ramUsed : String?
  var ramAvailable : String?
  var storageAvailable : String?
  var storageTotal : String?
  
  init() {
    
    print("getTotalSpace: \(Storage.getTotalSpace()/(1024 * 1024))MB")
    print("getFreeSpace: \(Storage.getFreeSpace()/(1024 * 1024))MB")
    print("getUsedSpace: \(Storage.getUsedSpace()/(1024 * 1024))MB")
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let fileURL = URL(fileURLWithPath: paths[0] as String)
    //Alternative: nsfilesystemsize, free size filesystemsize in bytes
//    do {
//      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
//      if let capacity = values.volumeAvailableCapacityForImportantUsage {
//        storageAvailable = "\(capacity/(1024 * 1024))MB"
//        print("volumeAvailableCapacityForImportantUsage: \(capacity/(1024 * 1024))MB")
//      }
//    } catch {
//      log("Error retrieving capacity: \(error.localizedDescription)")
//    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
      if let capacity = values.volumeAvailableCapacity {
        storageAvailable = "\(capacity/(1024 * 1024))MB"
//        print("volumeAvailableCapacity: \(capacity/(1024 * 1024))MB")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
//    do {
//      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
//      if let capacity = values.volumeAvailableCapacityForOpportunisticUsage {
//        print("volumeAvailableCapacityForOpportunisticUsage: \(capacity/(1024 * 1024))MB")
//      }
//    } catch {
//      log("Error retrieving capacity: \(error.localizedDescription)")
//    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
      if let capacity = values.volumeTotalCapacity {
        storageTotal = "\(capacity/(1024 * 1024))MB"
//        print("volumeTotalCapacity: \(capacity/(1024 * 1024))MB")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    let ram = evaluateRam()
    ramAvailable = ram.ramAvailable
    ramUsed = ram.ramUsed
  }
  
  func evaluateRam() -> ram{
    var ramAvailable:String?
    var ramUsed:String?
    
    var pagesize: vm_size_t = 0
    
    let host_port: mach_port_t = mach_host_self()
    var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
    host_page_size(host_port, &pagesize)
    
    var vm_stat: vm_statistics = vm_statistics_data_t()
    withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
      vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
        if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
          log("Error: Failed to fetch vm statistics")
        }
      }
    }
    
    let mem_free: Int64 = Int64(vm_stat.free_count) * Int64(pagesize)
    
    let mem_used: Int64 = Int64(vm_stat.active_count +
      vm_stat.inactive_count +
      vm_stat.wire_count) * Int64(pagesize)
    ramUsed = "\(mem_used/(1024 * 1024))MB"
    ramAvailable = "\(mem_free/(1024 * 1024))MB"
    
    return (ramUsed, ramAvailable)
  }
  
  func evaluateRamAlternative() -> ram{
    //Total Ram including not available one
    let ramAvailable:String = "\(ProcessInfo.processInfo.physicalMemory/(1024 * 1024))MB"
    var ramUsed:String?
    
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    if kerr == KERN_SUCCESS {
      ramUsed = "\(taskInfo.resident_size/(1024 * 1024))MB"
    }
    return (ramUsed, ramAvailable)
  }
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
                                                        deviceData: deviceData,
                                                        logData: logData,
                                                        gqlFeeder: gqlFeeder,
                                                        finishClosure: {
                                                          (send) in
                                                          feedbackBottomSheet?.sendSuccees = send
                                                          feedbackBottomSheet?.close()//Calls Closure
    })
    
    feedbackBottomSheet = FeedbackBottomSheet(slider: feedbackViewController,
                                              into: currentVc)
    feedbackBottomSheet?.sliderView.backgroundColor = Const.SetColor.CTBackground.color
    feedbackBottomSheet?.coverageRatio = 1.0
    
    feedbackBottomSheet?.onUserSlideToClose = ({
      guard let feedbackBottomSheet = feedbackBottomSheet else { return }
      if feedbackBottomSheet.sendSuccees {
        feedbackBottomSheet.slide(toOpen: false, animated: true)
        return
      }
      feedbackBottomSheet.slide(toOpen: true, animated: true)
      Alert.confirm(message: Localized("feedback_cancel_title"),
                    isDestructive: true) { (close) in
                      if close {
                        feedbackBottomSheet.slide(toOpen: false, animated: true)
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



