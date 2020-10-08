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
    print("Free: (MB) ####\((totalRam-totalUsedRam)/(sudivider))")
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
    print("phys_footprint (MB): ####\(info.phys_footprint/(sudivider))")
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
    print("mem_free:####\(mem_free/div) \nmem_used:####\(mem_used/div)\nmem_sum:####\(mem_sum/div) \npagesize:####\(pagesize)")
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
      print("Memory in use (in bytes): resident_size####:\(info.resident_size/udivider)")
    }
    else {
      print("Error with task_info(): " +
        (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
    }
  }
  
  init() {
    print("Memory Report\nDevice:\nRAM Total:\nRAM app used:\nRAM Total Used:\nRAM Free:\n\nSSD Total:\nSSD app used:\nSSD free:")
    report_memory()
    DeviceData.evaluateRamTotal()
    DeviceData.appUsed()
    print_free_memory()
    print("SSD formattedMemoryFootprint:(MB)####\(Storage.formattedMemoryFootprint())")
    print("XXX SSD appsize: (MB) ####\(Storage.appSizeInBytes()/Double(divider))")
    print("SSD getTotalSpace: (MB) ####\(Storage.getTotalSpace()/(divider))")
    print("SSD getFreeSpace: (MB) ####\(Storage.getFreeSpace()/(divider))")
    print("SSD getUsedSpace: (MB) ####\(Storage.getUsedSpace()/(divider))")
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let fileURL = URL(fileURLWithPath: paths[0] as String)
    //Alternative: nsfilesystemsize, free size filesystemsize in bytes
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
      if let capacity = values.volumeAvailableCapacityForImportantUsage {
        storageAvailable = "\(capacity/(divider))"
        print("XXX SSD volumeAvailableCapacityForImportantUsage (MB): ####\(capacity/(divider))")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
      if let capacity = values.volumeAvailableCapacity {
        storageAvailable = "\(capacity/Int(divider))"
        print("SSD volumeAvailableCapacity:(MB)####\(capacity/Int(divider))")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
      if let capacity = values.volumeAvailableCapacityForOpportunisticUsage {
        print("SSD volumeAvailableCapacityForOpportunisticUsage:(MB)####\(capacity/(divider))")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
      if let capacity = values.volumeTotalCapacity {
        storageTotal = "\(capacity/Int(divider))"
        print("SSD volumeTotalCapacity:(MB) ####\(capacity/Int(divider))")
      }
    } catch {
      log("Error retrieving capacity: \(error.localizedDescription)")
    }
    
    let ram = evaluateRam()
    ramAvailable = ram.ramAvailable
    ramUsed = ram.ramUsed
    print("evaluateRam ramAvailable ####\(ram.ramAvailable ?? "-")")
    print("evaluateRam ramUsed ####\(ram.ramUsed ?? "-")")
    
    let ram2 = evaluateRamAlternative()
    print("evaluateRamAlternative ramAvailable ####\(ram2.ramAvailable ?? "-")")
    print("evaluateRamAlternative ramUsed ####\(ram2.ramUsed ?? "-")")
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
    ramUsed = "\(mem_used/UInt64(divider))"
    ramAvailable = "\(mem_free/UInt64(divider))"
    
    print("activecount:(MB) ####\(Int64(vm_stat.active_count)*Int64(pagesize)/(divider))")
    print("inactive_count:(MB) ####\(Int64(vm_stat.inactive_count)*Int64(pagesize)/(divider))")
    print("wire_count:(MB) ####\(Int64(vm_stat.wire_count)*Int64(pagesize)/(divider))")
    print("free_count:(MB) ####\(Int64(vm_stat.free_count)*Int64(pagesize)/(divider))")
    
    print("XXX activecount+inactive_count+wire_count:#### \(Int64(vm_stat.active_count+vm_stat.inactive_count+vm_stat.wire_count)*Int64(pagesize)/(divider))")
    
    print("activecount+inactive_count+wire_count+free_count:#### \(Int64(vm_stat.active_count+vm_stat.inactive_count+vm_stat.wire_count+vm_stat.free_count)*Int64(pagesize)/(divider))")
    
    
    return (ramUsed, ramAvailable)
  }
  
  
  func evaluateRamAlternative() -> ram{
    //bei 1000 divider ramAvailable: "1048MB", ramUsed: "205MB" statt 52
    //ramUsed: "175MB", architecture: "iPhone6,2", ramAvailable: "1000MB" wenn der xcode 52MB anzeigt
    //Total Ram including not available one
    let ramAvailable:String = "\(ProcessInfo.processInfo.physicalMemory/UInt64(divider))"
    print("xxxx totalRam: ####\(ramAvailable)")
    var ramUsed:String?
    
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    if kerr == KERN_SUCCESS {
      ramUsed = "\(taskInfo.resident_size/UInt64(divider))"
      print("ramUsed (MB): ####\(ramUsed ?? "-")")
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
    
    
    print("internal: (MB)####\(Float(info.internal)/(1024*1024))")
    print("compressed: (MB)####\(Float(info.compressed)/(1024*1024))")
    
    print("compressed+internal: ####\(Float(info.internal + info.compressed)/(1024*1024))")
    
    print("phys_footprint:  (MB)####\(Float(info.phys_footprint)/(1024*1024))")
    print("limit_bytes_remaining:  (MB)####\(Float(info.limit_bytes_remaining)/(1024*1024))")
    print("ledger_phys_footprint_peak:  (MB)####\(Float(info.ledger_phys_footprint_peak)/(1024*1024))")
    print("device:  (MB)####\(Float(info.device)/(1024*1024))")
    print("resident_size:  (MB)####\(Float(info.resident_size)/(1024*1024))")
    print("virtual_size:  (MB)####\(Float(info.virtual_size)/(1024*1024))")
    return usedBytes
  }
  
  static func formattedMemoryFootprint() -> String
  {
    let usedBytes: UInt64? = UInt64(self.memoryFootprint() ?? 0)
    let usedMB = Double(usedBytes ?? 0) / 1024 / 1024
    let usedMBAsString: String = "\(usedMB)"
    return usedMBAsString
  }
  
}

