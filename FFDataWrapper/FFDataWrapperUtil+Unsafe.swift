//
//  FFDataWrapperUtil+Unsafe.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 13/10/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

/// The following code is UNSAFE. Use at your own risk!
public extension FFDataWrapper
{
    /// This function will attempt to wipe the backing store of the given mutable string.
    /// Although Swift strings are value types, they are copy-on-write, meaning that multiple strings can share the same backing store.
    /// If you are using this method, you must be sure that:
    /// - There are no copies floating around for the string you want to wipe.
    /// - The string itself has a mutable backing store - meaning that it was not assigned from some constant string literal, for example.
    ///
    /// - Parameters:
    ///   - string: The string whose backing store to wipe
    ///   - value: The byte value to use to write to the backing store. The default is 46 ('.' character)
    public static func unsafeWipe(_ string: inout String, with value: UInt8 = 32)
    {
        guard !string.isEmpty else { return }
        let core = { (_ o: UnsafeRawPointer) -> UnsafeRawPointer in o }(&string).assumingMemoryBound(to: FFString.self).pointee.core
        guard let basePtr = core.baseAddress, basePtr.isWritableMemory() else {
            return
        }
        
        basePtr.assumingMemoryBound(to: UInt8.self).initialize(repeating: value, count: core.elementWidth * core.count)
    }
    
    
    /// This function will attempt to wipe the backing store of the given mutable data.
    /// Although Swift data are value types, they are copy-on-write, meaning that multiple data structs can share the same backing store.
    /// If you are using this method, you must be sure that:
    /// - There are no more copies of data floating around for the data you want to wipe.
    /// - The data itself has a mutable backing store - meaning that it was NOT assigned from some constant read-only data buffer (e.g. located in the code segment).
    /// This function checks if the backing store is writable. Wiping will be skipped if it's NOT.
    /// - Parameters:
    ///   - data: The data whose backing store to wipe.
    ///   - value: The byte value to use to overwrite the backing store. The default is 0.
    public static func unsafeWipe(_ data: inout Data, with value: UInt8 = 0)
    {
        let length = data.count
        guard length > 0 else { return }
        // Depending on how the data was created, the unsafe pointer passed here is either pointing to the original backing store
        // or to a temporary copy.
        // A temporary copy is only created if the data was created with a custom reference (https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/Data.swift)
        // We currently DON'T support this case. (TODO)
        let wipeNativeBuffer = { (bytes: UnsafePointer<UInt8>) -> Void in
            let mutableRawBytes = UnsafeMutableRawPointer(OpaquePointer(bytes))
            guard mutableRawBytes.isWritableMemory() else { return }
            let mutableBytes = mutableRawBytes.assumingMemoryBound(to: UInt8.self)
            for i in 0 ..< length
            {
                mutableBytes[i] = value
            }
        }
        data.withUnsafeBytes(wipeNativeBuffer)
    }
    
    
    /// This function will attempt to wipe the bytes of an NSData or NSMutableData
    /// If you use this method, you must be sure that the underlying memory is writable (although the function checks for that).
    ///
    /// Limitations: this function may NOT work with custom implementations of NSData.
    /// - Parameters:
    ///   - nsData: NSData object whose contents to wipe.
    ///   - value: The byte value to use to overwrite the backing store. The default is 0.
    public static func unsafeWipe(_ nsData: NSData, with value: UInt8 = 0)
    {
        let length = nsData.length
        guard length > 0 else { return }
        
        let mutableRawBytes = UnsafeMutableRawPointer(OpaquePointer(nsData.bytes))
        guard mutableRawBytes.isWritableMemory() else { return }
        let mutableBytes = mutableRawBytes.assumingMemoryBound(to: UInt8.self)
        for i in 0 ..< length
        {
            mutableBytes[i] = value
        }
    }
}

extension UnsafeMutableRawPointer
{
    /// Check if the memory to which this pointer points is writable.
    func isWritableMemory() -> Bool
    {
        
        var vm_address = vm_address_t(UInt(bitPattern:self))
        var vm_size = vm_size_t(1)
        var vm_region_info = vm_region_basic_info_data_t()
        let vm_region_info_ptr = { (_ o: UnsafeMutableRawPointer) -> vm_region_info_t in o.assumingMemoryBound(to: Int32.self) } (&vm_region_info)
        var object = memory_object_name_t()

#if arch(x86_64) || arch(arm64)
        var info_count = mach_msg_type_number_t(MemoryLayout<vm_region_basic_info_data_64_t>.size / MemoryLayout<Int32>.size)
        let result = vm_region_64(mach_task_self_, &vm_address, &vm_size, VM_REGION_BASIC_INFO, vm_region_info_ptr, &info_count, &object)
#else
        var info_count = mach_msg_type_number_t(MemoryLayout<vm_region_basic_info_data_t>.size / MemoryLayout<Int32>.size)
        let result = vm_region(mach_task_self_, &vm_address, &vm_size, VM_REGION_BASIC_INFO, vm_region_info_ptr, &info_count, nil)
#endif
        guard result == 0 else {
            return false
        }
        return (vm_region_info.protection & VM_PROT_WRITE) != 0
    }
}

struct FFClassHeader
{
    let isa: UnsafeRawPointer
    let retainCounts: UInt64
}

/// Internal representation of Data.
/// Must match https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/Data.swift
struct FFData
{
    var backing : FFDataStorage
}

/// Internal types of data backing.
/// See: https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/Data.swift
enum FFDataBacking
{
    case swift
    case immutable(NSData) // This will most often (perhaps always) be NSConcreteData
    case mutable(NSMutableData) // This will often (perhaps always) be NSConcreteMutableData
    case customReference(NSData) // tracks data references that are only known to be immutable
    case customMutableReference(NSMutableData) // tracks data references that are known to be mutable
}

/// Internal representation of Data storage
/// Must match https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/Data.swift
class FFDataStorage
{
    var bytes: UnsafeMutableRawPointer? = nil
    var length: Int = 0
    var capacity: Int = 0
    var needToZero: Bool = false
    var deallocator: ((UnsafeMutableRawPointer, Int) -> Void)?
    var backing: FFDataBacking = .swift
}

/// Mimics the structure of Swift native string
struct FFString
{
    var core: FFStringCore
}

/// Mimics the structure of Swift string core.
struct FFStringCore
{
    var baseAddress: UnsafeMutableRawPointer?
    var countAndFlags: UInt
    var owner: AnyObject?
    
    /// Bitmask for the count part of `countAndFlags`.
    var countMask: UInt
    {
        return UInt.max &>> 2
    }
    
    /// Bitmask for the flags part of `countAndFlags`.
    var flagMask: UInt
    {
        return ~countMask
    }
    
    /// Get the number of elements.
    var count: Int
    {
        get
        {
            return Int(countAndFlags & countMask)
        }
    }
    
    /// Left shift amount to apply to an offset N so that when
    /// added to a UnsafeMutableRawPointer, it traverses N elements.
    var elementShift: Int
    {
        return Int(countAndFlags &>> (UInt.bitWidth - 1))
    }
    
    /// The number of bytes per element.
    ///
    /// If the string does not have an ASCII buffer available (including the case
    /// when we don't have a utf16 buffer) then it equals 2.
    public var elementWidth: Int
    {
        return elementShift &+ 1
    }
}


