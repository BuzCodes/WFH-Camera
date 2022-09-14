//
//  Main.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

@_cdecl("WFHCamMain")
public func WFHCamMain(allocator: CFAllocator, requestedTypeUUID: CFUUID) -> CMIOHardwarePlugInRef {
    HardwarePlugInInterface.shared.reference
}
