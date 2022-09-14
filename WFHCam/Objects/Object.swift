//
//  Object.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

import Foundation

protocol Object: AnyObject {
    var objectID: CMIOObjectID { get }
    var properties: [Int: Property] { get }
    
    func hasProperty(address: CMIOObjectPropertyAddress) -> Bool
    
    func isPropertySettable(address: CMIOObjectPropertyAddress) -> Bool

    func getPropertyDataSize(address: CMIOObjectPropertyAddress) -> UInt32

    func getPropertyData(address: CMIOObjectPropertyAddress, dataSize: inout UInt32, data: UnsafeMutableRawPointer)

    func setPropertyData(address: CMIOObjectPropertyAddress, data: UnsafeRawPointer)
}

extension Object {
    
    func hasProperty(address: CMIOObjectPropertyAddress) -> Bool {
        properties[Int(address.mSelector)] != nil
    }

    func isPropertySettable(address: CMIOObjectPropertyAddress) -> Bool {
        guard let property = properties[Int(address.mSelector)] else {
            return false
        }
        return property.isSettable
    }

    func getPropertyDataSize(address: CMIOObjectPropertyAddress) -> UInt32 {
        guard let property = properties[Int(address.mSelector)] else {
            return 0
        }
        return property.dataSize
    }

    func getPropertyData(address: CMIOObjectPropertyAddress, dataSize: inout UInt32, data: UnsafeMutableRawPointer) {
        guard let property = properties[Int(address.mSelector)] else {
            return
        }
        dataSize = property.dataSize
        property.getData(data: data)
    }

    func setPropertyData(address: CMIOObjectPropertyAddress, data: UnsafeRawPointer) {
        guard let property = properties[Int(address.mSelector)] else {
            return
        }
        property.setData(data: data)
    }
}
