//
//  PKVideoCameraView.swift
//  Peking
//
//  Created by Brendan Kirchner on 3/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol PKVideoCameraViewDelegate: class {
    var mode: PekingControllerMode { get set }
    func videoFinished(withFileURL fileURL: URL)
}

final class PKVideoCameraView: UIView {
    
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    
    weak var delegate: PKVideoCameraViewDelegate? = nil
    
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var videoOutput: AVCaptureMovieFileOutput?
    var focusView: UIView?
    
    var flashOffImage: UIImage?
    var flashOnImage: UIImage?
    var videoStartImage: UIImage?
    var videoStopImage: UIImage?
    
    var videoLayer: AVCaptureVideoPreviewLayer?
    
    fileprivate var isRecording = false
    
    static func instance() -> PKVideoCameraView {
        
        return UINib(nibName: "PKVideoCameraView", bundle: Bundle(for: PKVideoCameraView.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! PKVideoCameraView
    }
    
    func initialize() {
        
        if session != nil { return }
        
        self.backgroundColor = PekingAppearance.appearance.backgroundColor
        
        self.isHidden = false
        
        // AVCapture
        session = AVCaptureSession()
        
        guard let session = session else { return }
        
        for device in AVCaptureDevice.devices() {
            
            if let device = device as? AVCaptureDevice,
                device.position == AVCaptureDevicePosition.back {
                
                self.device = device
            }
        }
        
        do {
            
            videoInput = try AVCaptureDeviceInput(device: device)
            
            session.addInput(videoInput)
            
            videoOutput = AVCaptureMovieFileOutput()
            let totalSeconds = 60.0 //Total Seconds of capture time
            let timeScale: Int32 = 30 //FPS
            
            let maxDuration = CMTimeMakeWithSeconds(totalSeconds, timeScale)
            
            videoOutput?.maxRecordedDuration = maxDuration
            videoOutput?.minFreeDiskSpaceLimit = 1024 * 1024 //SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            videoLayer = AVCaptureVideoPreviewLayer(session: session)
            videoLayer?.frame = self.previewViewContainer.bounds
            videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            self.previewViewContainer.layer.addSublayer(videoLayer!)
            
            session.startRunning()
            
            // Focus View
            self.focusView         = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer      = UITapGestureRecognizer(target: self, action: #selector(PKVideoCameraView.focus(_:)))
            self.previewViewContainer.addGestureRecognizer(tapRecognizer)
            
        } catch {
            
        }
        
        let bundle = Bundle(for: PKVideoCameraView.classForCoder())
        
        flashOnImage = PekingAppearance.appearance.flashOnImage ?? UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage = PekingAppearance.appearance.flashOffImage ?? UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage = PekingAppearance.appearance.flipImage ?? UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)
        videoStartImage = PekingAppearance.appearance.videoStartImage ?? UIImage(named: "video_button", in: bundle, compatibleWith: nil)
        videoStopImage = PekingAppearance.appearance.videoStopImage ?? UIImage(named: "video_button_rec", in: bundle, compatibleWith: nil)
        
        if PekingAppearance.appearance.tintIcons {
            
            flashButton.tintColor = PekingAppearance.appearance.baseTintColor
            flipButton.tintColor  = PekingAppearance.appearance.baseTintColor
            shotButton.tintColor  = PekingAppearance.appearance.baseTintColor
            
            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            flipButton.setImage(flipImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            shotButton.setImage(videoStartImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            
        } else {
            
            flashButton.setImage(flashOffImage, for: .normal)
            flipButton.setImage(flipImage, for: .normal)
            shotButton.setImage(videoStartImage, for: .normal)
        }
        
        flashConfiguration()
        
        self.startCamera()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PKVideoCameraView.willEnterForegroundNotification(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PKVideoCameraView.didEnterBackgroundNotification(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        self.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let kp = keyPath {
            if kp == "frame" {
                DispatchQueue.main.async {
                    self.stopCamera()
                    self.videoLayer?.frame = self.previewViewContainer.bounds
                    if let mode = self.delegate?.mode {
                        if mode == .video {
                            self.startCamera()
                        }
                    }
                }
            }
        }
    }
    
    func willEnterForegroundNotification(_ notification: Notification) {
        startCamera()
    }
    
    func didEnterBackgroundNotification(_ notification: Notification) {
        stopCamera()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startCamera() {
        
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == AVAuthorizationStatus.authorized {
            
            session?.startRunning()
            
        } else if status == AVAuthorizationStatus.denied ||
            status == AVAuthorizationStatus.restricted {
            
            session?.stopRunning()
        }
    }
    
    func stopCamera() {
        if self.isRecording {
            self.toggleRecording()
        }
        
        session?.stopRunning()
    }
    
    @IBAction func shotButtonPressed(_ sender: UIButton) {
        
        self.toggleRecording()
    }
    
    @IBAction func flipButtonPressed(_ sender: UIButton) {
        
        guard let session = session else { return }
        
        session.stopRunning()
        
        do {
            
            session.beginConfiguration()
            
            for input in session.inputs {
                
                if let input = input as? AVCaptureInput {
                    
                    session.removeInput(input)
                }
            }
            
            let position = videoInput?.device.position == AVCaptureDevicePosition.front ? AVCaptureDevicePosition.back : AVCaptureDevicePosition.front
            
            for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
                
                if let device = device as? AVCaptureDevice,
                    device.position == position {
                    
                    videoInput = try AVCaptureDeviceInput(device: device)
                    session.addInput(videoInput)
                }
            }
            
            session.commitConfiguration()
            
        } catch {
            
        }
        
        session.startRunning()
    }
    
    @IBAction func flashButtonPressed(_ sender: UIButton) {
        guard let device = device else {
            return
        }
        do {
            try device.lockForConfiguration()
            let mode = device.flashMode
            
            switch mode {
            case .off:
                device.flashMode = AVCaptureFlashMode.on
                flashButton.setImage(flashOnImage, for: .normal)
                break
            default:
                device.flashMode = AVCaptureFlashMode.off
                flashButton.setImage(flashOffImage, for: .normal)
                break
            }
            device.unlockForConfiguration()
        } catch _ {
            flashButton.setImage(flashOffImage, for: .normal)
            return
        }
    }
}

extension PKVideoCameraView: AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        
        print("started recording to: \(fileURL)")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        print("finished recording to: \(outputFileURL)")
        self.delegate?.videoFinished(withFileURL: outputFileURL)
    }
}

fileprivate extension PKVideoCameraView {
    
    func toggleRecording() {
        
        guard let videoOutput = videoOutput else { return }
        
        self.isRecording = !self.isRecording
        
        let shotImage = self.isRecording ? videoStopImage : videoStartImage
        
        self.shotButton.setImage(shotImage, for: .normal)
        
        if self.isRecording {
            
            let outputPath = "\(NSTemporaryDirectory())output.mov"
            let outputURL = URL(fileURLWithPath: outputPath)
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: outputPath) {
                
                do {
                    try fileManager.removeItem(atPath: outputPath)
                } catch {
                    print("error removing item at path: \(outputPath)")
                    self.isRecording = false
                    return
                }
            }
            
            self.flipButton.isEnabled = false
            self.flashButton.isEnabled = false
            videoOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
            
        } else {
            videoOutput.stopRecording()
            self.flipButton.isEnabled = true
            self.flashButton.isEnabled = true
        }
    }
    
    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        
        let point    = recognizer.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y / viewsize.height, y: 1.0-point.x / viewsize.width)
        
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            return
        }
        
        do {
            try device.lockForConfiguration()
        } catch _ {
            return
        }
        
        if device.isFocusModeSupported(AVCaptureFocusMode.autoFocus) == true {
            
            device.focusMode = AVCaptureFocusMode.autoFocus
            device.focusPointOfInterest = newPoint
        }
        
        if device.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure) == true {
            
            device.exposureMode = AVCaptureExposureMode.continuousAutoExposure
            device.exposurePointOfInterest = newPoint
        }
        
        device.unlockForConfiguration()
        
        guard let focusView = focusView else { return }
        
        focusView.alpha  = 0.0
        focusView.center = point
        focusView.backgroundColor   = UIColor.clear
        focusView.layer.borderColor = UIColor.white.cgColor
        focusView.layer.borderWidth = 1.0
        focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        addSubview(focusView)
        
        UIView.animate(
            withDuration: 0.8,
            delay: 0.0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 3.0,
            options: UIViewAnimationOptions.curveEaseIn,
            animations: {
                
                focusView.alpha = 1.0
                focusView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                
        }, completion: {(finished) in
            
            focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            focusView.removeFromSuperview()
        })
    }
    
    func flashConfiguration() {
        do {
            guard let device = device else { return }
            
            try device.lockForConfiguration()
            
            device.flashMode = AVCaptureFlashMode.off
            flashButton.setImage(flashOffImage, for: .normal)
            
            device.unlockForConfiguration()
            
        } catch _ {
            
            return
        }
    }
}
