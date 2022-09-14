//
//  PropertyValue.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

protocol PropertyValue {
    var dataSize: UInt32 { get }
    func toData(data: UnsafeMutableRawPointer)
    
    static func fromData(data: UnsafeRawPointer) -> Self
}

extension String: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<CFString>.size)
    }
    
    func toData(data: UnsafeMutableRawPointer) {
        let cfString = self as CFString
        let unmanagedCFString = Unmanaged<CFString>.passRetained(cfString)
        UnsafeMutablePointer<Unmanaged<CFString>>(OpaquePointer(data)).pointee = unmanagedCFString
    }

    static func fromData(data: UnsafeRawPointer) -> Self {
        fatalError("not implemented")
    }
}

extension CMFormatDescription: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<Self>.size)
    }
    func toData(data: UnsafeMutableRawPointer) {
        let unmanaged = Unmanaged<Self>.passRetained(self as! Self)
        UnsafeMutablePointer<Unmanaged<Self>>(OpaquePointer(data)).pointee = unmanaged
    }

    static func fromData(data: UnsafeRawPointer) -> Self {
        fatalError("not implemented")
    }
}

extension CFArray: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<Self>.size)
    }
    
    func toData(data: UnsafeMutableRawPointer) {
        let unmanaged = Unmanaged<Self>.passRetained(self as! Self)
        UnsafeMutablePointer<Unmanaged<Self>>(OpaquePointer(data)).pointee = unmanaged
    }
    
    static func fromData(data: UnsafeRawPointer) -> Self {
        fatalError("not implemented")
    }
}

struct CFTypeRefWrapper {
    let ref: CFTypeRef
}

extension CFTypeRefWrapper: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<CFTypeRef>.size)
    }
    
    func toData(data: UnsafeMutableRawPointer) {
        let unmanaged = Unmanaged<CFTypeRef>.passRetained(ref)
        UnsafeMutablePointer<Unmanaged<CFTypeRef>>(OpaquePointer(data)).pointee = unmanaged
    }
    
    static func fromData(data: UnsafeRawPointer) -> Self {
        fatalError("not implemented")
    }
}

extension UInt32: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<UInt32>.size)
    }

    func toData(data: UnsafeMutableRawPointer) {
        UnsafeMutablePointer<Self>(OpaquePointer(data)).pointee = self
    }
    
    static func fromData(data: UnsafeRawPointer) -> Self {
        UnsafePointer<Self>(OpaquePointer(data)).pointee
    }
}

extension Int32: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<Self>.size)
    }
    
    func toData(data: UnsafeMutableRawPointer) {
        UnsafeMutablePointer<Self>(OpaquePointer(data)).pointee = self
    }
    
    static func fromData(data: UnsafeRawPointer) -> Self {
        UnsafePointer<Self>(OpaquePointer(data)).pointee
    }
}

extension Float64: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<Self>.size)
    }
    
    func toData(data: UnsafeMutableRawPointer) {
        UnsafeMutablePointer<Self>(OpaquePointer(data)).pointee = self
    }
    
    static func fromData(data: UnsafeRawPointer) -> Self {
        UnsafePointer<Self>(OpaquePointer(data)).pointee
    }
}

extension AudioValueRange: PropertyValue {
    var dataSize: UInt32 {
        UInt32(MemoryLayout<Self>.size)
    }
    
    func toData(data: UnsafeMutableRawPointer) {
        UnsafeMutablePointer<Self>(OpaquePointer(data)).pointee = self
    }
    
    static func fromData(data: UnsafeRawPointer) -> Self {
        UnsafePointer<Self>(OpaquePointer(data)).pointee
    }
}

