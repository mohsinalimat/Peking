//
//  ViewController.swift
//  Sample
//
//  Created by Meniny on 2015-04-03.
//  Copyright © 2015 Meniny. All rights reserved.
//

import UIKit
import Peking

class ViewController: UIViewController, PekingDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var fileUrlLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showButton.layer.cornerRadius = 2.0
        self.fileUrlLabel.text = ""
    }
    
    @IBAction func showButtonPressed(_ sender: AnyObject) {
        let peking = PekingController(mode: .video, multipleSelection: false, delegate: self)
        self.present(peking, animated: true, completion: nil)
    }
    
    // MARK: PekingDelegate Protocol
    func peking(_ peking: PekingController, didSelectImages images: [PekingImage]) {
        print("Number of selection images: \(images.count)")
        
        var count: Double = 0
        for pi in images {
            DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 * count)) {
                self.imageView.image = pi.image
                print("w: \(pi.image.size.width) - h: \(pi.image.size.height)")
                if let metaData = pi.metadata {
                    print("Image mediatype: \(metaData.mediaType)")
                    print("Source image size: \(metaData.pixelWidth)x\(metaData.pixelHeight)")
                    print("Creation date: \(String(describing: metaData.creationDate))")
                    print("Modification date: \(String(describing: metaData.modificationDate))")
                    print("Video duration: \(metaData.duration)")
                    print("Is favourite: \(metaData.isFavourite)")
                    print("Is hidden: \(metaData.isHidden)")
                    print("Location: \(String(describing: metaData.location))")
                }
            }
            count += 1
        }
        peking.dismiss(animated: true, completion: nil)
    }
    
    func peking(_ peking: PekingController, didCaptureVideo videoURL: URL) {
        print("video completed and output to file: \(videoURL)")
        self.fileUrlLabel.text = "file output to: \(videoURL.absoluteString)"
        peking.dismiss(animated: true, completion: nil)
    }
    
    func peking(_ peking: PekingController, didCapturePhoto photo: UIImage) {
        self.imageView.image = photo
        peking.dismiss(animated: true, completion: nil)
    }
    
    func pekingCameraRollUnauthorized(_ peking: PekingController) {
        peking.dismiss(animated: true, completion: nil)
        print("Camera roll unauthorized")
        
        let alert = UIAlertController(title: "Access Requested",
                                      message: "Saving image needs to access your photo album",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { (action) -> Void in
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in })
        
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = view.frame
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func pekingDidDismiss(_ peking: PekingController) {
        print("Called when the PekingController dismissed")
    }
    
    func pekingWillDismiss(_ peking: PekingController) {
        print("Called when the close button is pressed")
    }
    
}
