//
//  Stream.swift
//  WFHCam
//
//  Created by Alessandro Loi on 11/09/22.
//

import AVFoundation
import Vision
import AppKit
import Cocoa

class Stream: NSObject, Object {
    
    var objectID: CMIOObjectID = 0
    let name = "WFHCam"
    let width = 1280
    let height = 720
    let frameRate = 30
    
    private lazy var formatDescription: CMVideoFormatDescription? = {
        var formatDescription: CMVideoFormatDescription?
        let error = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32ARGB,
            width: Int32(width), height: Int32(height),
            extensions: nil,
            formatDescriptionOut: &formatDescription)
        guard error == noErr else {
            return nil
        }
        return formatDescription
    }()
    
    private lazy var clock: CFTypeRef? = {
        var clock: Unmanaged<CFTypeRef>? = nil
        
        let error = CMIOStreamClockCreate(
            kCFAllocatorDefault,
            "WFHCamPlugin clock" as CFString,
            Unmanaged.passUnretained(self).toOpaque(),
            CMTimeMake(value: 1, timescale: 10),
            100, 10,
            &clock)
        guard error == noErr else {
            return nil
        }
        return clock?.takeUnretainedValue()
    }()
    
    private lazy var queue: CMSimpleQueue? = {
        var queue: CMSimpleQueue?
        let error = CMSimpleQueueCreate(
            allocator: kCFAllocatorDefault,
            capacity: 30,
            queueOut: &queue)
        guard error == noErr else {
            return nil
        }
        return queue
    }()
    
    private lazy var videoOutput: AVCaptureVideoDataOutput = {
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
        ]
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        return videoOutput
    }()
    
    private var sequenceNumber: UInt64 = 0
    private var queueAlteredProc: CMIODeviceStreamQueueAlteredProc?
    private var queueAlteredRefCon: UnsafeMutableRawPointer?
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private var cooldownTimer: Timer?
    private var cooldownTimerCount = 3
    private let cooldownTime = 3
    private var personDetected = false
    
    lazy var properties: [Int : Property] = [
        kCMIOObjectPropertyName: Property(name),
        kCMIOStreamPropertyFormatDescription: Property(formatDescription!),
        kCMIOStreamPropertyFormatDescriptions: Property([formatDescription!] as CFArray),
        kCMIOStreamPropertyDirection: Property(UInt32(0)),
        kCMIOStreamPropertyFrameRate: Property(Float64(frameRate)),
        kCMIOStreamPropertyFrameRates: Property(Float64(frameRate)),
        kCMIOStreamPropertyMinimumFrameRate: Property(Float64(frameRate)),
        kCMIOStreamPropertyFrameRateRanges: Property(AudioValueRange(mMinimum: Float64(frameRate), mMaximum: Float64(frameRate))),
        kCMIOStreamPropertyClock: Property(CFTypeRefWrapper(ref: clock!)),
    ]
    
    func start() {
        sessionQueue.async { [weak self] in
            guard
                let self = self,
                let captureDevice = AVCaptureDevice.default(for: .video),
                let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice)
            else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.addInput(captureDeviceInput)
            self.captureSession.addOutput(self.videoOutput)
            self.videoOutput.setSampleBufferDelegate(self, queue: .main)
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard
                let self = self,
                let captureDevice = AVCaptureDevice.default(for: .video),
                let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice)
            else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.removeOutput(self.videoOutput)
            self.captureSession.removeInput(captureDeviceInput)
            self.captureSession.commitConfiguration()
            self.captureSession.stopRunning()
        }
    }
    
    func copyBufferQueue(queueAlteredProc: CMIODeviceStreamQueueAlteredProc?, queueAlteredRefCon: UnsafeMutableRawPointer?) -> CMSimpleQueue? {
        self.queueAlteredProc = queueAlteredProc
        self.queueAlteredRefCon = queueAlteredRefCon
        return self.queue
    }
    
    private func enqueueBuffer(sampleBuffer: CVImageBuffer?) {
        guard
            let queue = queue,
            let pixelPuffer = sampleBuffer,
            CMSimpleQueueGetCount(queue) < CMSimpleQueueGetCapacity(queue)
        else { return }
        
        let scale = UInt64(frameRate) * 100
        let duration = CMTime(value: CMTimeValue(scale / UInt64(frameRate)), timescale: CMTimeScale(scale))
        let timestamp = CMTime(value: duration.value * CMTimeValue(sequenceNumber), timescale: CMTimeScale(scale))
        
        var timing = CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: timestamp,
            decodeTimeStamp: timestamp
        )
        
        var error = noErr
        error = CMIOStreamClockPostTimingEvent(timestamp, mach_absolute_time(), true, clock)
        guard error == noErr else {
            return
        }
        
        var formatDescription: CMFormatDescription?
        error = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelPuffer,
            formatDescriptionOut: &formatDescription)
        guard error == noErr else {
            return
        }
        
        var sampleBufferUnmanaged: Unmanaged<CMSampleBuffer>? = nil
        error = CMIOSampleBufferCreateForImageBuffer(
            kCFAllocatorDefault,
            pixelPuffer,
            formatDescription,
            &timing,
            sequenceNumber,
            UInt32(kCMIOSampleBufferNoDiscontinuities),
            &sampleBufferUnmanaged
        )
        guard error == noErr else {
            return
        }
        
        CMSimpleQueueEnqueue(queue, element: sampleBufferUnmanaged!.toOpaque())
        queueAlteredProc?(objectID, sampleBufferUnmanaged!.toOpaque(), queueAlteredRefCon)
        
        sequenceNumber += 1
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension Stream: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        detectPerson(from: sampleBuffer)
    }
    
    private func detectPerson(from sampleBuffer: CMSampleBuffer) {
        guard
            !personDetected
        else { return }
        
        let visionRequest = VNDetectHumanRectanglesRequest { [weak self] request,_  in
            self?.personDetected = (request.results?.count ?? 0) > 1
        }
        
        DispatchQueue.main.async { [weak self] in
            guard
                let self = self
            else { return }
            
            let visionrequestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
            try? visionrequestHandler.perform([visionRequest])
            
            if self.personDetected == true {
                self.startCooldownTimer()
                self.enqueueBuffer(sampleBuffer: CVPixelBuffer.create(size: CGSize(width: self.width, height: self.height)))
            } else {
                self.enqueueBuffer(sampleBuffer: sampleBuffer.imageBuffer)
            }
        }
    }
    
    private func startCooldownTimer() {
        cooldownTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                             target: self,
                                             selector: #selector(updateTimer),
                                             userInfo: nil,
                                             repeats: true)
    }
    
    @objc private func updateTimer() {
        DispatchQueue.main.async { [unowned self] in
            if self.cooldownTimerCount != 0 {
                self.cooldownTimerCount -= 1
            } else {
                self.cooldownTimer?.invalidate()
                self.cooldownTimer = nil
                self.cooldownTimerCount = self.cooldownTime
                self.personDetected = false
            }
        }
    }
}

