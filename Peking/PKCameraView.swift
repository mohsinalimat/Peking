//
//  PKCameraView.swift
//  Peking
//
//  Created by Meniny on 2015/11/14.
//  Copyright © 2015 Meniny. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import Photos

@objc protocol PKCameraViewDelegate: class {
    var mode: PekingControllerMode { get set }
    func cameraShotFinished(_ image: UIImage)
}

final class PKCameraView: UIView, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    
    weak var delegate: PKCameraViewDelegate? = nil
    
    fileprivate var session: AVCaptureSession?
    fileprivate var device: AVCaptureDevice?
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var imageOutput: AVCaptureStillImageOutput?
    fileprivate var focusView: UIView?
    
    fileprivate var flashOffImage: UIImage?
    fileprivate var flashOnImage: UIImage?
    
    fileprivate var motionManager: CMMotionManager?
    fileprivate var currentDeviceOrientation: UIDeviceOrientation?
    
    fileprivate var videoLayer: AVCaptureVideoPreviewLayer?
    
    static func instance() -> PKCameraView {
        
        return UINib(nibName: "PKCameraView", bundle: Bundle(for: PKCameraView.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! PKCameraView
    }
    
    func initialize() {
        
        if session != nil { return }
        
        self.backgroundColor = PekingAppearance.appearance.backgroundColor
        
        let bundle = Bundle(for: PKCameraView.classForCoder())
        
        flashOnImage = PekingAppearance.appearance.flashOnImage ?? UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage = PekingAppearance.appearance.flashOffImage ?? UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage = PekingAppearance.appearance.flipImage ?? UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)
        let shotImage = PekingAppearance.appearance.shotImage ?? UIImage(named: "ic_radio_button_checked", in: bundle, compatibleWith: nil)
        
        if PekingAppearance.appearance.tintIcons {
            
            flashButton.tintColor = PekingAppearance.appearance.baseTintColor
            flipButton.tintColor  = PekingAppearance.appearance.baseTintColor
            shotButton.tintColor  = PekingAppearance.appearance.baseTintColor
            
            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            flipButton.setImage(flipImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            shotButton.setImage(shotImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            
        } else {
            
            flashButton.setImage(flashOffImage, for: .normal)
            flipButton.setImage(flipImage, for: .normal)
            shotButton.setImage(shotImage, for: .normal)
        }
        
        self.isHidden = false
        
        // AVCapture
        session = AVCaptureSession()
        
        guard let session = session else { return }
        
        for device in AVCaptureDevice.devices() {
            
            if let device = device as? AVCaptureDevice,
                device.position == AVCaptureDevicePosition.back {
                
                self.device = device
                
                if !device.hasFlash {
                    
                    flashButton.isHidden = true
                }
            }
        }
        
        do {
            
            videoInput = try AVCaptureDeviceInput(device: device)
            session.addInput(videoInput)
            
            imageOutput = AVCaptureStillImageOutput()
            session.addOutput(imageOutput)
            
            videoLayer = AVCaptureVideoPreviewLayer(session: session)
            videoLayer?.frame = previewViewContainer.bounds
            videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            previewViewContainer.layer.addSublayer(videoLayer!)
            previewViewContainer.clipsToBounds = true
            
            session.sessionPreset = AVCaptureSessionPresetPhoto
            
            session.startRunning()
            
            // Focus View
            self.focusView         = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer      = UITapGestureRecognizer(target: self, action:#selector(PKCameraView.focus(_:)))
            tapRecognizer.delegate = self
            self.previewViewContainer.addGestureRecognizer(tapRecognizer)
            
        } catch {
            
        }
        
        flashConfiguration()
        
        self.startCamera()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PKCameraView.willEnterForegroundNotification(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PKCameraView.didEnterBackgroundNotification(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        self.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let kp = keyPath {
            if kp == "frame" {
                DispatchQueue.main.async {
                    self.stopCamera()
                    self.videoLayer?.frame = self.previewViewContainer.bounds
                    if let mode = self.delegate?.mode {
                        if mode == .camera {
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
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
            
        case .authorized:
            
            session?.startRunning()
            
            motionManager = CMMotionManager()
            motionManager!.accelerometerUpdateInterval = 0.2
            motionManager!.startAccelerometerUpdates(to: OperationQueue()) { [unowned self] (data, _) in
                
                if let data = data {
                    
                    if abs(data.acceleration.y) < abs(data.acceleration.x) {
                        
                        self.currentDeviceOrientation = data.acceleration.x > 0 ? .landscapeRight : .landscapeLeft
                        
                    } else {
                        
                        self.currentDeviceOrientation = data.acceleration.y > 0 ? .portraitUpsideDown : .portrait
                    }
                }
            }
            
        case .denied, .restricted:
            
            stopCamera()
            
        default:
            
            break
        }
    }
    
    func stopCamera() {
        
        session?.stopRunning()
        motionManager?.stopAccelerometerUpdates()
        currentDeviceOrientation = nil
    }
    
    @IBAction func shotButtonPressed(_ sender: UIButton) {
        
        guard let imageOutput = imageOutput else {
            
            return
        }
        
        DispatchQueue.global(qos: .default).async(execute: { () -> Void in
            
            let videoConnection = imageOutput.connection(withMediaType: AVMediaTypeVideo)
            
            let orientation = self.currentDeviceOrientation ?? UIDevice.current.orientation
            
            switch (orientation) {
                
            case .portrait:
                
                videoConnection?.videoOrientation = .portrait
                
            case .portraitUpsideDown:
                
                videoConnection?.videoOrientation = .portraitUpsideDown
                
            case .landscapeRight:
                
                videoConnection?.videoOrientation = .landscapeLeft
                
            case .landscapeLeft:
                
                videoConnection?.videoOrientation = .landscapeRight
                
            default:
                
                videoConnection?.videoOrientation = .portrait
            }
            
            imageOutput.captureStillImageAsynchronously(from: videoConnection) { (buffer, error) -> Void in
                
                self.stopCamera()
                
                guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
                    let image = UIImage(data: data) else {
                    return
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.delegate?.cameraShotFinished(image)
                    
//                    if autoSaveImage {
//                        self.saveImageToCameraRoll(image: image)
//                    }
                    
                    self.session       = nil
                    self.device        = nil
                    self.imageOutput   = nil
                    self.motionManager = nil
                })
            }
        })
    }
    
    @IBAction func flipButtonPressed(_ sender: UIButton) {
        
        if !cameraIsAvailable { return }
        
        session?.stopRunning()
        
        do {
            
            session?.beginConfiguration()
            
            if let session = session {
                
                for input in session.inputs {
                    
                    session.removeInput(input as! AVCaptureInput)
                }
                
                let position = (videoInput?.device.position == AVCaptureDevicePosition.front) ? AVCaptureDevicePosition.back : AVCaptureDevicePosition.front
                
                for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
                    
                    if let device = device as? AVCaptureDevice , device.position == position {
                        
                        videoInput = try AVCaptureDeviceInput(device: device)
                        session.addInput(videoInput)
                        
                    }
                }
                
            }
            
            session?.commitConfiguration()
            
            
        } catch {
            
        }
        
        session?.startRunning()
    }
    
    @IBAction func flashButtonPressed(_ sender: UIButton) {
        
        if !cameraIsAvailable { return }
        
        do {
            
            guard let device = device, device.hasFlash else { return }
            
            try device.lockForConfiguration()
            
            switch device.flashMode {
                
            case .off:
                
                device.flashMode = AVCaptureFlashMode.on
                flashButton.setImage(flashOnImage?.withRenderingMode(.alwaysTemplate), for: .normal)
                
            case .on:
                
                device.flashMode = AVCaptureFlashMode.off
                flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
                
            default:
                
                break
            }
            
            device.unlockForConfiguration()
            
        } catch _ {
            
            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            
            return
        }
        
    }
}

fileprivate extension PKCameraView {
    
    func saveImageToCameraRoll(image: UIImage) {
        
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetChangeRequest.creationRequestForAsset(from: image)
            
        }, completionHandler: nil)
    }
    
    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        
        let point = recognizer.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        
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
        
        guard let focusView = self.focusView else { return }
        
        focusView.alpha = 0.0
        focusView.center = point
        focusView.backgroundColor = UIColor.clear
        focusView.layer.borderColor = PekingAppearance.appearance.baseTintColor.cgColor
        focusView.layer.borderWidth = 1.0
        focusView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        addSubview(focusView)
        
        UIView.animate(withDuration: 0.8,
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
            
            if let device = device {
                
                guard device.hasFlash else { return }
                
                try device.lockForConfiguration()
                
                device.flashMode = AVCaptureFlashMode.off
                flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: .normal)
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            return
        }
    }
    
    var cameraIsAvailable: Bool {
        
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == AVAuthorizationStatus.authorized {
            
            return true
        }
        
        return false
    }
}
