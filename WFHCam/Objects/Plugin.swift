//
//  Plugin.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

import Foundation

class Plugin: Object {
    var objectID: CMIOObjectID = 0
    let name = "WFMCamPlugin"

    lazy var properties: [Int : Property] = [
        kCMIOObjectPropertyName: Property(name),
    ]
}

