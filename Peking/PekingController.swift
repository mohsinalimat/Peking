//
//  PekingController.swift
//  Peking
//
//  Created by Meniny on 2015/11/14.
//  Copyright © 2015 Meniny. All rights reserved.
//

import UIKit
import Photos

open class PekingImage {
    open var image: UIImage
    open var metadata: PekingImageMetadata? = nil
    
    public init(_ image: UIImage, metadata: PekingImageMetadata? = nil) {
        self.image = image
        self.metadata = metadata
    }
}

public extension Array where Element: PekingImage {
    public var images: [UIImage] {
        var imgs = [UIImage]()
        for i in self {
            imgs.append(i.image)
        }
        return imgs
    }
}

public protocol PekingDelegate: class {
    func peking(_ peking: PekingController, didSelectImages images: [PekingImage])
    func peking(_ peking: PekingController, didCaptureVideo videoURL: URL)
    func peking(_ peking: PekingController, didCapturePhoto photo: UIImage)
    func pekingCameraRollUnauthorized(_ peking: PekingController)
    
    // optional
    func pekingDidDismiss(_ peking: PekingController)
    func pekingWillDismiss(_ peking: PekingController)
}

public extension PekingDelegate {
    func peking(_ peking: PekingController, didCaptureVideo videoURL: URL) {}
    func peking(_ peking: PekingController, didCapturePhoto photo: UIImage) {}
    func pekingDidDismiss(_ peking: PekingController) {}
    func pekingWillDismiss(_ peking: PekingController) {}
}

@objc
public enum PekingControllerMode: Int {
    case camera
    case library
    case video
}

public struct PekingImageMetadata {
    public let mediaType: PHAssetMediaType
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let creationDate: Date?
    public let modificationDate: Date?
    public let location: CLLocation?
    public let duration: TimeInterval
    public let isFavourite: Bool
    public let isHidden: Bool
}

public class PekingAppearance {
    public var baseTintColor   = UIColor.hex("#FFFFFF", alpha: 1.0)
    public var tintColor       = UIColor.hex("#FC5750", alpha: 1.0)
    public var backgroundColor = UIColor.hex("#3C3C46", alpha: 1.0)
    
    public var albumImage: UIImage?
    public var cameraImage: UIImage?
    public var videoImage: UIImage?
    public var checkImage: UIImage?
    public var closeImage: UIImage?
    public var flashOnImage: UIImage?
    public var flashOffImage: UIImage?
    public var flipImage: UIImage?
    public var shotImage: UIImage?
    
    public var videoStartImage: UIImage?
    public var videoStopImage: UIImage?
    
    public var cameraRollTitle = "CAMERA ROLL"
    public var cameraTitle     = "PHOTO"
    public var videoTitle      = "VIDEO"
    public var titleFont       = UIFont(name: "AvenirNext-DemiBold", size: 15)
    
    public var tintIcons: Bool = true
    
    public static var appearance: PekingAppearance = PekingAppearance()
}

@objc public class PekingController: UIViewController {
    
    public var isVideoModeEnabled: Bool = false
    public var allowMultipleSelection: Bool = false
    
    internal var mode: PekingControllerMode = .library
    public var defaultMode: PekingControllerMode = .library
    
    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!
    @IBOutlet weak var videoShotContainer: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    lazy var albumView  = PKAlbumView.instance()
    lazy var cameraView = PKCameraView.instance()
    lazy var videoView  = PKVideoCameraView.instance()
    
    fileprivate var hasGalleryPermission: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    public weak var delegate: PekingDelegate? = nil
    
    public init(mode dm: PekingControllerMode = .library, multipleSelection: Bool = false, videoDisabled: Bool = true, delegate de: PekingDelegate?) {
        if dm == .video {
            isVideoModeEnabled = true
        } else {
            isVideoModeEnabled = !videoDisabled
        }
        defaultMode = dm
        allowMultipleSelection = multipleSelection
        delegate = de
        super.init(nibName: "PekingController", bundle: Bundle(for: PekingController.classForCoder()))
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "PekingController", bundle: Bundle(for: PekingController.classForCoder()))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func loadView() {
        if let view = UINib(nibName: "PekingController", bundle: Bundle(for: PekingController.classForCoder())).instantiate(withOwner: self, options: nil).first as? UIView {
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = PekingAppearance.appearance.backgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self
        videoView.delegate  = self
        
        menuView.backgroundColor = view.backgroundColor
        menuView.addBottomBorder(UIColor.black, width: 1.0)
        
        albumView.allowMultipleSelection = allowMultipleSelection
        
        let bundle = Bundle(for: PekingController.classForCoder())
        
        // Get the custom button images if they're set
        let albumImage = PekingAppearance.appearance.albumImage ?? UIImage(named: "ic_insert_photo", in: bundle, compatibleWith: nil)
        let cameraImage = PekingAppearance.appearance.cameraImage ?? UIImage(named: "ic_photo_camera", in: bundle, compatibleWith: nil)
        
        let videoImage = PekingAppearance.appearance.videoImage ?? UIImage(named: "ic_videocam", in: bundle, compatibleWith: nil)
        
        
        let checkImage = PekingAppearance.appearance.checkImage ?? UIImage(named: "ic_check", in: bundle, compatibleWith: nil)
        let closeImage = PekingAppearance.appearance.closeImage ?? UIImage(named: "ic_close", in: bundle, compatibleWith: nil)
        
        if PekingAppearance.appearance.tintIcons {
            
            let albumImage  = albumImage?.withRenderingMode(.alwaysTemplate)
            let cameraImage = cameraImage?.withRenderingMode(.alwaysTemplate)
            let closeImage  = closeImage?.withRenderingMode(.alwaysTemplate)
            let videoImage  = videoImage?.withRenderingMode(.alwaysTemplate)
            let checkImage  = checkImage?.withRenderingMode(.alwaysTemplate)
            
            libraryButton.setImage(albumImage, for: .normal)
            libraryButton.setImage(albumImage, for: .highlighted)
            libraryButton.setImage(albumImage, for: .selected)
            libraryButton.tintColor = PekingAppearance.appearance.tintColor
            libraryButton.adjustsImageWhenHighlighted = false
            
            cameraButton.setImage(cameraImage, for: .normal)
            cameraButton.setImage(cameraImage, for: .highlighted)
            cameraButton.setImage(cameraImage, for: .selected)
            cameraButton.tintColor = PekingAppearance.appearance.tintColor
            cameraButton.adjustsImageWhenHighlighted = false
            
            closeButton.setImage(closeImage, for: .normal)
            closeButton.setImage(closeImage, for: .highlighted)
            closeButton.setImage(closeImage, for: .selected)
            closeButton.tintColor = PekingAppearance.appearance.baseTintColor
            
            videoButton.setImage(videoImage, for: .normal)
            videoButton.setImage(videoImage, for: .highlighted)
            videoButton.setImage(videoImage, for: .selected)
            videoButton.tintColor = PekingAppearance.appearance.tintColor
            videoButton.adjustsImageWhenHighlighted = false
            
            doneButton.setImage(checkImage, for: .normal)
            doneButton.setImage(checkImage, for: .highlighted)
            doneButton.setImage(checkImage, for: .selected)
            doneButton.tintColor = PekingAppearance.appearance.baseTintColor
            
        } else {
            
            libraryButton.setImage(albumImage, for: .normal)
            libraryButton.setImage(albumImage, for: .highlighted)
            libraryButton.setImage(albumImage, for: .selected)
            libraryButton.tintColor = nil
            
            cameraButton.setImage(cameraImage, for: .normal)
            cameraButton.setImage(cameraImage, for: .highlighted)
            cameraButton.setImage(cameraImage, for: .selected)
            cameraButton.tintColor = nil
            
            videoButton.setImage(videoImage, for: .normal)
            videoButton.setImage(videoImage, for: .highlighted)
            videoButton.setImage(videoImage, for: .selected)
            videoButton.tintColor = nil
            
            closeButton.setImage(closeImage, for: .normal)
            doneButton.setImage(checkImage, for: .normal)
        }
        
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true
        videoButton.clipsToBounds   = true
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)
        
        titleLabel.textColor = PekingAppearance.appearance.baseTintColor
        titleLabel.font      = PekingAppearance.appearance.titleFont
        
        if !isVideoModeEnabled {
            
            videoButton.removeFromSuperview()
            
            self.view.addConstraint(NSLayoutConstraint(
                item:       self.view,
                attribute:  .trailing,
                relatedBy:  .equal,
                toItem:     cameraButton,
                attribute:  .trailing,
                multiplier: 1.0,
                constant:   0
            ))
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        albumView.frame  = CGRect(origin: CGPoint.zero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
        cameraView.frame = CGRect(origin: CGPoint.zero, size: cameraShotContainer.frame.size)
        cameraView.layoutIfNeeded()
        
        albumView.initialize()
        cameraView.initialize()
        
        if isVideoModeEnabled {
            
            videoView.frame = CGRect(origin: CGPoint.zero, size: videoShotContainer.frame.size)
            videoView.layoutIfNeeded()
            videoView.initialize()
        }
        
        changeMode(defaultMode)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        self.stopAll()
    }
    
    override public var prefersStatusBarHidden : Bool {
        
        return true
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        self.delegate?.pekingWillDismiss(self)
        self.dismiss(animated: true) {
            self.delegate?.pekingDidDismiss(self)
        }
    }
    
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        changeMode(PekingControllerMode.library)
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
        changeMode(PekingControllerMode.camera)
    }
    
    @IBAction func videoButtonPressed(_ sender: UIButton) {
        changeMode(PekingControllerMode.video)
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        pekingDidFinishPickingImages()
    }
    private func requestImage(with asset: PHAsset/*, cropRect: CGRect*/, completion: @escaping (PHAsset, UIImage) -> Void) {
        
        DispatchQueue.global(qos: .default).async(execute: {
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.resizeMode = .exact
            
            let targetSize   = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
            
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, info in
                    guard let result = result else { return }
                    
                    DispatchQueue.main.async(execute: {
                        completion(asset, result)
                    })
            }
        })
    }
    
    private func pekingDidFinishPickingImages() {
        var images = [PekingImage]()
        
        for asset in albumView.selectedAssets {
            
            requestImage(with: asset) { asset, result in
                images.append(PekingImage(result))
                if asset == self.albumView.selectedAssets.last {
                    DispatchQueue.main.async {
                        self.delegate?.peking(self, didSelectImages: images)
                    }
                }
            }
        }
    }
}

extension PekingController: PKAlbumViewDelegate, PKCameraViewDelegate, PKVideoCameraViewDelegate {
    
    // MARK: PKCameraViewDelegate
    func cameraShotFinished(_ image: UIImage) {
        DispatchQueue.main.async {
            self.delegate?.peking(self, didCapturePhoto: image)
        }
    }
    
    public func albumViewCameraRollAuthorized() {
        
        // in the case that we're just coming back from granting photo gallery permissions
        // ensure the done button is visible if it should be
        self.updateDoneButtonVisibility()
    }
    
    public func updateTitle() {
        switch mode {
        case .library:
            let suffix = (albumView.selectedAssets.count > 0) ? " (\(albumView.selectedAssets.count))" : ""
            titleLabel.text = NSLocalizedString(PekingAppearance.appearance.cameraRollTitle, comment: "") + suffix
            break
        case .camera:
            titleLabel.text = NSLocalizedString(PekingAppearance.appearance.cameraTitle, comment: "")
            break
        default:
            titleLabel.text = NSLocalizedString(PekingAppearance.appearance.videoTitle, comment: "")
            break
        }
    }
    
    // MARK: PKAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        delegate?.pekingCameraRollUnauthorized(self)
    }
    
    func videoFinished(withFileURL fileURL: URL) {
        DispatchQueue.main.async {
            self.delegate?.peking(self, didCaptureVideo: fileURL)
        }
    }
    
}

private extension PekingController {
    
    func stopAll() {
        if isVideoModeEnabled {
            self.videoView.stopCamera()
        }
        self.cameraView.stopCamera()
    }
    
    func changeMode(_ toMode: PekingControllerMode) {
        
        if self.mode == toMode { return }
        
        //operate this switch before changing mode to stop cameras
        switch toMode {
        case .camera:
            self.cameraView.startCamera()
            self.videoView.stopCamera()
            break
        case .video:
            self.cameraView.stopCamera()
            self.videoView.startCamera()
            break
        default:
            self.cameraView.stopCamera()
            self.videoView.stopCamera()
            break
        }
        
        self.mode = toMode
        
        dishighlightButtons()
        updateDoneButtonVisibility()
        
        switch mode {
        case .library:
            updateTitle()
            highlightButton(libraryButton)
            self.view.bringSubview(toFront: photoLibraryViewerContainer)
            break
        case .camera:
            updateTitle()
            highlightButton(cameraButton)
            self.view.bringSubview(toFront: cameraShotContainer)
            cameraView.startCamera()
            break
        default: // .video:
            updateTitle()
            highlightButton(videoButton)
            self.view.bringSubview(toFront: videoShotContainer)
            videoView.startCamera()
            break
        }
        
        self.view.bringSubview(toFront: menuView)
    }
    
    func updateDoneButtonVisibility() {
        
        // don't show the done button without gallery permission
        if !hasGalleryPermission {
            self.doneButton.isHidden = true
            return
        }
        
        switch self.mode {
        case .library:
            self.doneButton.isHidden = false
            break
        default:
            self.doneButton.isHidden = true
            break
        }
    }
    
    func dishighlightButtons() {
        
        cameraButton.tintColor  = PekingAppearance.appearance.baseTintColor
        libraryButton.tintColor = PekingAppearance.appearance.baseTintColor
        
        if cameraButton.layer.sublayers?.count > 1,
            let sublayers = cameraButton.layer.sublayers {
            
            for layer in sublayers {
                
                if let borderColor = layer.borderColor,
                    UIColor(cgColor: borderColor) == PekingAppearance.appearance.tintColor {
                    
                    layer.removeFromSuperlayer()
                }
            }
        }
        
        if libraryButton.layer.sublayers?.count > 1,
            let sublayers = libraryButton.layer.sublayers {
            
            for layer in sublayers {
                
                if let borderColor = layer.borderColor,
                    UIColor(cgColor: borderColor) == PekingAppearance.appearance.tintColor {
                    
                    layer.removeFromSuperlayer()
                }
            }
        }
        
        if let videoButton = videoButton,
            videoButton.layer.sublayers?.count > 1,
            let sublayers = videoButton.layer.sublayers {
            
            videoButton.tintColor = PekingAppearance.appearance.baseTintColor
            
            for layer in sublayers {
                
                if let borderColor = layer.borderColor,
                    UIColor(cgColor: borderColor) == PekingAppearance.appearance.tintColor {
                    
                    layer.removeFromSuperlayer()
                }
            }
        }
    }
    
    func highlightButton(_ button: UIButton) {
        button.tintColor = PekingAppearance.appearance.tintColor
        button.addBottomBorder(PekingAppearance.appearance.tintColor, width: 3)
    }
}
