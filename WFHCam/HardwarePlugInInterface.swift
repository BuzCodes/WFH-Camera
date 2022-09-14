//
//  HardwarePlugInInterface.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

class HardwarePlugInInterface {
    
    static let shared = HardwarePlugInInterface ()
    
    private var objects = [CMIOObjectID: Object]()

    private init() {}
    
    private func addObject(object: Object) {
        objects[object.objectID] = object
    }
    
    private func queryInterface(plugin: UnsafeMutableRawPointer?, uuid: REFIID, interface: UnsafeMutablePointer<LPVOID?>?) -> HRESULT {
        let pluginRefPtr = UnsafeMutablePointer<CMIOHardwarePlugInRef?>(OpaquePointer(interface))
        pluginRefPtr?.pointee = HardwarePlugInInterface.shared.reference
        return HRESULT(noErr)
    }
    
    private func initializeWithObjectID(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID) -> OSStatus {
        guard let plugin = plugin else {
            return OSStatus(kCMIOHardwareIllegalOperationError)
        }
        
        var error = noErr
        
        let pluginObject = Plugin()
        pluginObject.objectID = objectID
        addObject(object: pluginObject)
        
        let device = Device()
        error = CMIOObjectCreate(plugin, CMIOObjectID(kCMIOObjectSystemObject), CMIOClassID(kCMIODeviceClassID), &device.objectID)
        guard error == noErr else {
            return error
        }
        addObject(object: device)
        
        let stream = Stream()
        error = CMIOObjectCreate(plugin, device.objectID, CMIOClassID(kCMIOStreamClassID), &stream.objectID)
        guard error == noErr else {
            return error
        }

        addObject(object: stream)
        
        device.streamID = stream.objectID
        
        error = CMIOObjectsPublishedAndDied(plugin, CMIOObjectID(kCMIOObjectSystemObject), 1, &device.objectID, 0, nil)
        guard error == noErr else {
            return error
        }
        
        error = CMIOObjectsPublishedAndDied(plugin, device.objectID, 1, &stream.objectID, 0, nil)
        guard error == noErr else {
            return error
        }
        
        return noErr
    }
    
    private func objectHasProperty(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?) -> DarwinBoolean {
        
        guard let address = address?.pointee else {
            return false
        }
        guard let object = objects[objectID] else {
            return false
        }
        return DarwinBoolean(object.hasProperty(address: address))
    }

    private func objectIsPropertySettable(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, isSettable: UnsafeMutablePointer<DarwinBoolean>?) -> OSStatus {
        
        guard let address = address?.pointee else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        guard let object = objects[objectID] else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        let settable = object.isPropertySettable(address: address)
        isSettable?.pointee = DarwinBoolean(settable)
        return noErr
    }

    private func objectGetPropertyDataSize(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, qualifiedDataSize: UInt32, qualifiedData: UnsafeRawPointer?, dataSize: UnsafeMutablePointer<UInt32>?) -> OSStatus {
        
        guard let address = address?.pointee else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        guard let object = objects[objectID] else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        dataSize?.pointee = object.getPropertyDataSize(address: address)
        return noErr
    }

    private func objectGetPropertyData(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, qualifiedDataSize: UInt32, qualifiedData: UnsafeRawPointer?, dataSize: UInt32, dataUsed: UnsafeMutablePointer<UInt32>?, data: UnsafeMutableRawPointer?) -> OSStatus {
        
        guard let address = address?.pointee else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        guard let object = objects[objectID] else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        guard let data = data else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        var dataUsed_: UInt32 = 0
        object.getPropertyData(address: address, dataSize: &dataUsed_, data: data)
        dataUsed?.pointee = dataUsed_
        return noErr
    }

    private func objectSetPropertyData(plugin: CMIOHardwarePlugInRef?, objectID: CMIOObjectID, address: UnsafePointer<CMIOObjectPropertyAddress>?, qualifiedDataSize: UInt32, qualifiedData: UnsafeRawPointer?, dataSize: UInt32, data: UnsafeRawPointer?) -> OSStatus {
        
        guard let address = address?.pointee else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        
        guard let object = objects[objectID] else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        guard let data = data else {
            
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        object.setPropertyData(address: address, data: data)
        return noErr
    }

    private func deviceStartStream(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID, streamID: CMIOStreamID) -> OSStatus {
        guard let stream = objects[streamID] as? Stream else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        stream.start()
        return noErr
    }

    private func deviceStopStream(plugin: CMIOHardwarePlugInRef?, deviceID: CMIODeviceID, streamID: CMIOStreamID) -> OSStatus {
        guard let stream = objects[streamID] as? Stream else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        stream.stop()
        return noErr
    }

    private func streamCopyBufferQueue(plugin: CMIOHardwarePlugInRef?, streamID: CMIOStreamID, queueAlteredProc: CMIODeviceStreamQueueAlteredProc?, queueAlteredRefCon: UnsafeMutableRawPointer?, queueOut: UnsafeMutablePointer<Unmanaged<CMSimpleQueue>?>?) -> OSStatus {
        
        guard let queueOut = queueOut else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        guard let stream = objects[streamID] as? Stream else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        guard let queue = stream.copyBufferQueue(queueAlteredProc: queueAlteredProc, queueAlteredRefCon: queueAlteredRefCon) else {
            return OSStatus(kCMIOHardwareBadObjectError)
        }
        queueOut.pointee = Unmanaged<CMSimpleQueue>.passRetained(queue)
        return noErr
    }
    
    let reference: CMIOHardwarePlugInRef = {
        let pluginInterface = CMIOHardwarePlugInInterface(_reserved: nil,
                                                          QueryInterface: { plugin, uuid, interface in
            HardwarePlugInInterface.shared.queryInterface(plugin: plugin, uuid: uuid, interface: interface)
        },
                                                          AddRef: { _ in return 0 },
                                                          Release: { _ in return 0 },
                                                          Initialize: { _ in return OSStatus(kCMIOHardwareIllegalOperationError) },
                                                          InitializeWithObjectID: { (plugin, objectID) in
            HardwarePlugInInterface.shared.initializeWithObjectID(plugin: plugin, objectID: objectID)
        },
                                                          Teardown: { _ in return noErr },
                                                          ObjectShow: { _,_ in },
                                                          ObjectHasProperty: { (plugin, objectID, address) in
            HardwarePlugInInterface.shared.objectHasProperty(plugin: plugin, objectID: objectID, address: address)
        },
                                                          ObjectIsPropertySettable: { (plugin, objectID, address, isSettable) in
            HardwarePlugInInterface.shared.objectIsPropertySettable(plugin: plugin, objectID: objectID, address: address, isSettable: isSettable)
        },
                                                          ObjectGetPropertyDataSize: { (plugin, objectID, address, qualifiedDataSize, qualifiedData, dataSize) in
            HardwarePlugInInterface.shared.objectGetPropertyDataSize(plugin: plugin, objectID: objectID, address: address, qualifiedDataSize: qualifiedDataSize, qualifiedData: qualifiedData, dataSize: dataSize)
        },
                                                          ObjectGetPropertyData: { (plugin, objectID, address, qualifiedDataSize, qualifiedData, dataSize, dataUsed, data) in
            HardwarePlugInInterface.shared.objectGetPropertyData(plugin: plugin, objectID: objectID, address: address, qualifiedDataSize: qualifiedDataSize, qualifiedData: qualifiedData, dataSize: dataSize, dataUsed: dataUsed, data: data)
        },
                                                          ObjectSetPropertyData: { (plugin, objectID, address, qualifiedDataSize, qualifiedData, dataSize, data) in
            HardwarePlugInInterface.shared.objectSetPropertyData(plugin: plugin, objectID: objectID, address: address, qualifiedDataSize: qualifiedDataSize, qualifiedData: qualifiedData, dataSize: dataSize, data: data)
        },
                                                          DeviceSuspend: { _,_ in return noErr },
                                                          DeviceResume: { _,_ in return noErr },
                                                          DeviceStartStream: { (plugin, deviceID, streamID) in
            HardwarePlugInInterface.shared.deviceStartStream(plugin: plugin, deviceID: deviceID, streamID: streamID)
        },
                                                          DeviceStopStream: { (plugin, deviceID, streamID) in
            HardwarePlugInInterface.shared.deviceStopStream(plugin: plugin, deviceID: deviceID, streamID: streamID)
        },
                                                          DeviceProcessAVCCommand: { _, _,_  in OSStatus(kCMIOHardwareIllegalOperationError) },
                                                          DeviceProcessRS422Command: { _, _,_  in OSStatus(kCMIOHardwareIllegalOperationError) },
                                                          StreamCopyBufferQueue: { (plugin, streamID, queueAlteredProc, queueAlteredRefCon, queueOut) in
            HardwarePlugInInterface.shared.streamCopyBufferQueue(plugin: plugin, streamID: streamID, queueAlteredProc: queueAlteredProc, queueAlteredRefCon: queueAlteredRefCon, queueOut: queueOut)
        },
                                                          StreamDeckPlay: { _,_ in return OSStatus(kCMIOHardwareIllegalOperationError) },
                                                          StreamDeckStop: { _,_ in return OSStatus(kCMIOHardwareIllegalOperationError) },
                                                          StreamDeckJog: { _,_,_  in return OSStatus(kCMIOHardwareIllegalOperationError) },
                                                          StreamDeckCueTo: { _,_,_,_  in return OSStatus(kCMIOHardwareIllegalOperationError) })
        
        let interfacePtr = UnsafeMutablePointer<CMIOHardwarePlugInInterface>.allocate(capacity: 1)
        interfacePtr.pointee = pluginInterface
        
        let pluginRef = CMIOHardwarePlugInRef.allocate(capacity: 1)
        pluginRef.pointee = interfacePtr
        return pluginRef
    }()
}

