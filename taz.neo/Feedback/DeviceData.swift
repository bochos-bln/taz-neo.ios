//
//  DeviceData.swift
//  taz.neo
//
//  Created by Ringo.Mueller on 08.10.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import NorthLib



public struct DeviceData : DoesLog {
  typealias ram = (ramUsed:String?, ramAvailable:String?)
  let divider:Int64 = 1024 * 1024
  let udivider:UInt64 = 1024 * 1024
  
  static let sudivider:UInt64 = 1024 * 1024
  static let sdivider:Int64 = 1024 * 1024
  
  /**
   1000 RAM:50,9/1000  HD: 10,2/16GB app:95,7MB
>   appsize: 89.995822MB Missing: 5,7MB!!!
   getTotalSpace: 15999MB
   getFreeSpace: 4615MB
   getUsedSpace: 11384MB
   volumeAvailableCapacityForImportantUsage: 5805MB
   volumeAvailableCapacity: 4615MB
   volumeAvailableCapacityForOpportunisticUsage: 4521MB
>   volumeTotalCapacity: 15999MB
   evaluateRam ramAvailable Optional("11MB")
   evaluateRam ramUsed Optional("808MB")
>   evaluateRamAlternative ramAvailable Optional("1048MB")
   evaluateRamAlternative ramUsed Optional("197MB")

   1024  RAM:51,7 / 1000  HD: 5,81 verf 10,2/16GB app:95,7MB
   appsize: 85.82670402526855MB
   getTotalSpace: 15258MB
   getFreeSpace: 4402MB
   getUsedSpace: 10855MB
   volumeAvailableCapacityForImportantUsage: 5538MB
   volumeAvailableCapacity: 4402MB
   volumeAvailableCapacityForOpportunisticUsage: 4314MB
   volumeTotalCapacity: 15258MB
   evaluateRam ramAvailable Optional("12MB")
   evaluateRam ramUsed Optional("763MB")
   evaluateRamAlternative ramAvailable Optional("1000MB")
   evaluateRamAlternative ramUsed Optional("187MB")

   1024 RAM 66/1000 HD 5,81/16 96,1
   appsize: 86.22774600982666MB
   getTotalSpace: 15258MB
   getFreeSpace: 4402MB
   getUsedSpace: 10856MB
   volumeAvailableCapacityForImportantUsage: 5538MB
   volumeAvailableCapacity: 4402MB
   volumeAvailableCapacityForOpportunisticUsage: 4314MB
   volumeTotalCapacity: 15258MB
   evaluateRam ramAvailable Optional("25MB")
   evaluateRam ramUsed Optional("715MB")
   evaluateRamAlternative ramAvailable Optional("1000MB")
   evaluateRamAlternative ramUsed Optional("45MB")
   
   

   Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
   The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.
   phys_footprint: 96.03173MB
   limit_bytes_remaining: 0.0MB
   ledger_phys_footprint_peak: 0.0MB
   device: 0.0MB
   resident_size: 230.71484MB
   virtual_size: 4875.961MB
   formattedMemoryFootprint: 96.03173065185547MB
   appsize: 86.24704837799072MB
   getTotalSpace: 15258MB
   getFreeSpace: 4395MB
   getUsedSpace: 10862MB
   volumeAvailableCapacityForImportantUsage: 5531MB
   volumeAvailableCapacity: 4395MB
   volumeAvailableCapacityForOpportunisticUsage: 4307MB
   volumeTotalCapacity: 15258MB
   activecount: 256MB
   inactive_count: 254MB
   wire_count: 235MB
   free_count: 11MB
   evaluateRam ramAvailable Optional("11MB")
   evaluateRam ramUsed Optional("746MB")
   evaluateRamAlternative ramAvailable Optional("1000MB")
   evaluateRamAlternative ramUsed Optional("230MB")
   
   
   free ram =   evaluateRamAlternative ramAvailable Optional("1000MB") -   evaluateRam ramUsed Optional("746MB")  -   phys_footprint: 96.03173MB
   
   */
  
  
  static func evaluateRamTotal() -> UInt64{
    let totalRam = ProcessInfo.processInfo.physicalMemory
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
           print("Error: Failed to fetch vm statistics")
         }
       }
     }
    
    
    let totalUsedRam = (UInt64(vm_stat.active_count+vm_stat.inactive_count+vm_stat.wire_count)*UInt64(pagesize))
    print("Free: \((totalRam-totalUsedRam)/(sudivider)))")
    return totalRam - totalUsedRam
   }
  
  static func appUsed() -> UInt64? {

    // From Quinn the Eskimo at Apple.
    // https://forums.developer.apple.com/thread/105088#357415

        // The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
        // complex for the Swift C importer, so we have to define them ourselves.
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT
        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard
            kr == KERN_SUCCESS,
            count >= TASK_VM_INFO_REV1_COUNT
            else { return nil }
      print("\(info.phys_footprint/(sudivider))")
        return info.phys_footprint
  }
  
  
  
  func print_free_memory ()
  {
  var pagesize: vm_size_t = 0

  let host_port: mach_port_t = mach_host_self()
  var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
  host_page_size(host_port, &pagesize)

  var vm_stat: vm_statistics = vm_statistics_data_t()
  withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
      vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
          if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
              NSLog("Error: Failed to fetch vm statistics")
          }
      }
  }

  /* Stats in bytes */
  let mem_used: Int64 = Int64(vm_stat.active_count +
          vm_stat.inactive_count +
          vm_stat.wire_count) * Int64(pagesize)
    
  
    
    
  let mem_free: Int64 = Int64(vm_stat.free_count) * Int64(pagesize)
    let mem_sum = mem_free+mem_used
    let div:Int64 = 1024*1024
    print("mem_free: \(mem_free/div), mem_used: \(mem_used/div), mem_sum: \(mem_sum/div) pagesize: \(pagesize)")
  }
  
 
  var ramUsed : String?
  var ramAvailable : String?
  var storageAvailable : String?
  var storageTotal : String?
  
  func report_memory() {
      var info = mach_task_basic_info()
      let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
      var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

      let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
          $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
              task_info(mach_host_self(),
                        task_flavor_t(MACH_TASK_BASIC_INFO),
                        $0,
                        &count)
          }
      }

      if kerr == KERN_SUCCESS {
          print("Memory in use (in bytes): \(info.resident_size/udivider)")
      }
      else {
          print("Error with task_info(): " +
              (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
      }
  }
  
  init() {
    report_memory()
    DeviceData.evaluateRamTotal()
    DeviceData.appUsed()
    print_free_memory()
    print("formattedMemoryFootprint: \(Storage.formattedMemoryFootprint())")
    print("appsize: \(Storage.appSizeInBytes()/Double(divider))MB")
    print("getTotalSpace: \(Storage.getTotalSpace()/(divider))MB")
    print("getFreeSpace: \(Storage.getFreeSpace()/(divider))MB")
    print("getUsedSpace: \(Storage.getUsedSpace()/(divider))MB")
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let fileURL = URL(fileURLWithPath: paths[0] as String)
    //Alternative: nsfilesystemsize, free size filesystemsize in bytes
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
      if let capacity = values.volumeAvailableCapacityForImportantUsage {
        storageAvailable = "\(capacity/(divider))MB"
        print("volumeAvailableCapacityForImportantUsage: \(capacity/(divider))MB")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
      if let capacity = values.volumeAvailableCapacity {
        storageAvailable = "\(capacity/Int(divider))MB"
        print("volumeAvailableCapacity: \(capacity/Int(divider))MB")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
      if let capacity = values.volumeAvailableCapacityForOpportunisticUsage {
        print("volumeAvailableCapacityForOpportunisticUsage: \(capacity/(divider))MB")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
      if let capacity = values.volumeTotalCapacity {
        storageTotal = "\(capacity/Int(divider))MB"
        print("volumeTotalCapacity: \(capacity/Int(divider))MB")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    let ram = evaluateRam()
    ramAvailable = ram.ramAvailable
    ramUsed = ram.ramUsed
    print("evaluateRam ramAvailable \(ram.ramAvailable)")
    print("evaluateRam ramUsed \(ram.ramUsed)")
    
    let ram2 = evaluateRamAlternative()
    print("evaluateRamAlternative ramAvailable \(ram2.ramAvailable)")
    print("evaluateRamAlternative ramUsed \(ram2.ramUsed)")
  }
  
  func evaluateRam() -> ram{
    var ramAvailable:String?
    var ramUsed:String?
    
    var pagesize: vm_size_t = 0
    
    let host_port: mach_port_t = mach_host_self()
    var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
    host_page_size(host_port, &pagesize)
    
    var vm_stat: vm_statistics64 = vm_statistics64_data_t()
    withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
      vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
        if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
          log("Error: Failed to fetch vm statistics")
        }
      }
    }
    
    let mem_free: UInt64 = UInt64(vm_stat.free_count) * UInt64(pagesize)
    
    let mem_used: UInt64 = UInt64(vm_stat.active_count +
      vm_stat.inactive_count +
      vm_stat.wire_count) * UInt64(pagesize)
    ramUsed = "\(mem_used/UInt64(divider))MB"
    ramAvailable = "\(mem_free/UInt64(divider))MB"
    
    print("activecount: \(Int64(vm_stat.active_count)*Int64(pagesize)/(divider))MB")
    print("inactive_count: \(Int64(vm_stat.inactive_count)*Int64(pagesize)/(divider))MB")
    print("wire_count: \(Int64(vm_stat.wire_count)*Int64(pagesize)/(divider))MB")
    print("free_count: \(Int64(vm_stat.free_count)*Int64(pagesize)/(divider))MB")
    
    print("activecount+inactive_count+wire_count: \(Int64(vm_stat.active_count+vm_stat.inactive_count+vm_stat.wire_count)*Int64(pagesize)/(divider))MB")
    
      print("activecount+inactive_count+wire_count+free_count: \(Int64(vm_stat.active_count+vm_stat.inactive_count+vm_stat.wire_count+vm_stat.free_count)*Int64(pagesize)/(divider))MB")
    
    
    return (ramUsed, ramAvailable)
  }
  
  
  func evaluateRamAlternative() -> ram{
    //bei 1000 divider ramAvailable: "1048MB", ramUsed: "205MB" statt 52
    //ramUsed: "175MB", architecture: "iPhone6,2", ramAvailable: "1000MB" wenn der xcode 52MB anzeigt
    //Total Ram including not available one
    let ramAvailable:String = "\(ProcessInfo.processInfo.physicalMemory/UInt64(divider))MB"
    var ramUsed:String?
    
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    if kerr == KERN_SUCCESS {
      ramUsed = "\(taskInfo.resident_size/UInt64(divider))MB"
    }
    return (ramUsed, ramAvailable)
  }

}



class Storage
{
  
  static func appSizeInBytes() -> Float64 { // approximate value
       var totalSize: Float64 = 0
     // create list of directories
     var paths = [Bundle.main.bundlePath] // main bundle
     let docDirDomain = FileManager.SearchPathDirectory.documentDirectory
     let docDirs = NSSearchPathForDirectoriesInDomains(docDirDomain, .userDomainMask, true)
      
    for dir in docDirs {
      paths.append(dir)
    }
     let libDirDomain = FileManager.SearchPathDirectory.libraryDirectory
     let libDirs = NSSearchPathForDirectoriesInDomains(libDirDomain, .userDomainMask, true)
    for dir in libDirs {
      paths.append(dir)
    }
     paths.append(NSTemporaryDirectory() as String) // temp directory
    
     // combine sizes
     for path in paths {
         if let size = bytesIn(directory: path) {
             totalSize += size
         }
     }
     return totalSize
 }

 private static func bytesIn(directory: String) -> Float64? {
     let fm = FileManager.default
     guard let subdirectories = try? fm.subpathsOfDirectory(atPath: directory) as NSArray else {
         return nil
     }
     let enumerator = subdirectories.objectEnumerator()
     var size: UInt64 = 0
     while let fileName = enumerator.nextObject() as? String {
         do {
             let fileDictionary = try fm.attributesOfItem(atPath: directory.appending("/" + fileName)) as NSDictionary
             size += fileDictionary.fileSize()
         } catch let err {
             print("err getting attributes of file \(fileName): \(err.localizedDescription)")
         }
     }
     return Float64(size)
 }
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



      // From Quinn the Eskimo at Apple.
      // https://forums.developer.apple.com/thread/105088#357415

       static func memoryFootprint() -> Float? {
          // The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
          // complex for the Swift C importer, so we have to define them ourselves.
          let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
          let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
          var info = task_vm_info_data_t()
          var count = TASK_VM_INFO_COUNT
          let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
              infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                  task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
              }
          }
          guard
              kr == KERN_SUCCESS,
              count >= TASK_VM_INFO_REV1_COUNT
              else { return nil }

          let usedBytes = Float(info.phys_footprint)
        
        
          print("internal: \(Float(info.internal)/(1024*1024))MB")
          print("compressed: \(Float(info.compressed)/(1024*1024))MB")
        
                  print("compressed+internal: \(Float(info.internal + info.compressed)/(1024*1024))MB")
        
          print("phys_footprint: \(Float(info.phys_footprint)/(1024*1024))MB")
        print("limit_bytes_remaining: \(Float(info.limit_bytes_remaining)/(1024*1024))MB")
        print("ledger_phys_footprint_peak: \(Float(info.ledger_phys_footprint_peak)/(1024*1024))MB")
        print("device: \(Float(info.device)/(1024*1024))MB")
        print("resident_size: \(Float(info.resident_size)/(1024*1024))MB")
        print("virtual_size: \(Float(info.virtual_size)/(1024*1024))MB")
          return usedBytes
      }

       static func formattedMemoryFootprint() -> String
      {
          let usedBytes: UInt64? = UInt64(self.memoryFootprint() ?? 0)
          let usedMB = Double(usedBytes ?? 0) / 1024 / 1024
          let usedMBAsString: String = "\(usedMB)MB"
          return usedMBAsString
       }

}

