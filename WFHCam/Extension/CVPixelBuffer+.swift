//
//  CVPixelBuffer+.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

extension CVPixelBuffer {
    
    static func create(size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ] as [String: Any]
        
        let error = CVPixelBufferCreate(
            kCFAllocatorSystemDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            options as CFDictionary,
            &pixelBuffer)
        
        guard error == noErr else {
            return nil
        }
        
        return pixelBuffer
    }
}

