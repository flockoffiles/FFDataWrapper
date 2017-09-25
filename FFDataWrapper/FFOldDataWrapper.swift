//
//  FFOldDataWrapper.swift
//  FFDataWrapper
//
//  Created by Sergey Novitsky on 22/09/2017.
//  Copyright © 2017 Flock of Files. All rights reserved.
//

import Foundation

func address<T: AnyObject>(o: T) -> Int {
    return unsafeBitCast(o, to: Int.self)
}

func address(ptr: UnsafeRawPointer) -> Int {
    return Int(bitPattern: ptr)
}

class FFManagedByteBuffer: ManagedBuffer<Int, UInt8>
{
    func clone() -> FFManagedByteBuffer
    {
        return self.withUnsafeMutablePointerToElements { (oldElems: UnsafeMutablePointer<UInt8>) -> FFManagedByteBuffer in
            return FFManagedByteBuffer.create(minimumCapacity: self.capacity) { (newBuf) in
                newBuf.withUnsafeMutablePointerToElements { (newElems: UnsafeMutablePointer<UInt8>) ->Void in
                    newElems.initialize(from: oldElems, count: self.header)
                }
                return self.header
                } as! FFManagedByteBuffer
        }
    }
    
    deinit
    {
        print(String(format: "---- Deinit for buffer = %p", address(o: self)))
        
        let capacity = self.header
        self.withUnsafeMutablePointerToElements { elems -> Void in
            elems.initialize(to: 0, count: capacity)
            elems.deinitialize(count: capacity)
        }
    }
    
    func hexString() -> String
    {
        var result = String()
        withUnsafeMutablePointers {
            result.reserveCapacity($0.pointee * 2)
            for i in 0 ..< $0.pointee
            {
                result += String(format: "%02X", $1[i])
            }
        }
        
        return result
    }
    
}



/// Struct which wraps a data buffer and provides a way to keep the contents in obfuscated form.
public struct FFOldDataWrapper
{
    var buffer: FFManagedByteBuffer
    
    init(buffer: FFManagedByteBuffer)
    {
        self.buffer = buffer
    }
    
    public init(string: String)
    {
        let capacity = string.lengthOfBytes(using: .utf8)
        buffer = FFManagedByteBuffer.create(minimumCapacity: capacity) { _ in capacity } as! FFManagedByteBuffer
        buffer.withUnsafeMutablePointers {
            let utf8 = string.utf8CString
            
            for i in 0 ..< $0.pointee
            {
                $1[i] = UInt8(utf8[i])
            }
        }
        let selfAddrString = String(format:"%p", address(ptr: &self))
        let bufferAddrString = String(format: "%p", address(o: buffer))
        print("---- Constructed from string: \(string), self = \(selfAddrString), buffer = \(bufferAddrString)")
        
        
    }
    
    public init(data: Data)
    {
        let capacity = data.count
        buffer = FFManagedByteBuffer.create(minimumCapacity: capacity) { _ in capacity } as! FFManagedByteBuffer
        
        buffer.withUnsafeMutablePointers { _, targetBytePtr in
            data.copyBytes(to: targetBytePtr, count: capacity)
        }
    }
    
    public func hexString() -> String
    {
        return buffer.hexString()
    }
    
}

