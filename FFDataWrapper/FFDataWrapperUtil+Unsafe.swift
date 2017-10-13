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
        let core = { (_ o: UnsafeRawPointer) -> UnsafeRawPointer in o }(&string).assumingMemoryBound(to: FFString.self).pointee.core
        guard let basePtr = core.baseAddress, basePtr.isWritableMemory() else {
            return
        }
        
        basePtr.assumingMemoryBound(to: UInt8.self).initialize(to: value, count: core.elementWidth * core.count)
    }
}

extension UnsafeMutableRawPointer
{
    /// Check if the memory to which this pointer points is writable.
    func isWritableMemory() -> Bool
    {
        var vm_address = vm_address_t(bitPattern:self)
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


/// Mimics the structure of Swift native string
fileprivate struct FFString
{
    var core: FFStringCore
}

/// Mimics the structure of Swift string core.
fileprivate struct FFStringCore
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


