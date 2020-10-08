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
  
  func appUsed() -> UInt64? {
    
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
    print("phys_footprint (MB): ####\(info.phys_footprint/UInt64(divider))")
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
  
  init() {
    appUsed()
    print_free_memory()
    print("XXX SSD appsize: (MB) ####\(Storage.appSizeInBytes()/Double(divider))")
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
    
    let ram = evaluateRam()
    ramAvailable = ram.ramAvailable
    ramUsed = ram.ramUsed
    print("evaluateRam ramAvailable ####\(ram.ramAvailable ?? "-")")
    print("evaluateRam ramUsed ####\(ram.ramUsed ?? "-")")
  }
  
  func evaluateRam() -> ram{
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
    
    let mem_used: UInt64 = UInt64(vm_stat.active_count +
      vm_stat.inactive_count +
      vm_stat.wire_count) * UInt64(pagesize)
    ramUsed = "\(mem_used/UInt64(divider))"
    
    print("XXX activecount+inactive_count+wire_count:#### \(Int64(vm_stat.active_count+vm_stat.inactive_count+vm_stat.wire_count)*Int64(pagesize)/(divider))")
    
  
    let ramAvailable:String = "\(ProcessInfo.processInfo.physicalMemory/UInt64(divider))"
    print("xxxx totalRam: ####\(ramAvailable)")
    
    
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

