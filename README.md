
<p align="center">
  <img src="https://i.loli.net/2017/08/03/59831a2e826d0.png" alt="Peking">
  <br/><a href="https://cocoapods.org/pods/Peking">
  <img alt="Version" src="https://img.shields.io/badge/version-1.1.0-brightgreen.svg">
  <img alt="Author" src="https://img.shields.io/badge/author-Meniny-blue.svg">
  <img alt="Build Passing" src="https://img.shields.io/badge/build-passing-brightgreen.svg">
  <img alt="Swift" src="https://img.shields.io/badge/swift-3.0%2B-orange.svg">
  <br/>
  <img alt="Platforms" src="https://img.shields.io/badge/platform-iOS-lightgrey.svg">
  <img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <br/>
  <img alt="Cocoapods" src="https://img.shields.io/badge/cocoapods-compatible-brightgreen.svg">
  <img alt="Carthage" src="https://img.shields.io/badge/carthage-working%20on-red.svg">
  <img alt="SPM" src="https://img.shields.io/badge/swift%20package%20manager-working%20on-red.svg">
  </a>
</p>

## What's this?

`Peking` is a tiny image picker library.

## Preview

![59834b3c5d654.jpg](https://i.loli.net/2017/08/04/59834b3c5d654.jpg)

![59834b4a7058a.jpg](https://i.loli.net/2017/08/04/59834b4a7058a.jpg)

![59834b5031654.jpg](https://i.loli.net/2017/08/04/59834b5031654.jpg)

## Requirements

* iOS 8.0+
* Xcode 8 with Swift 3

## Installation

#### CocoaPods

```ruby
use_frameworks!
pod 'Peking'
```

## Contribution

You are welcome to fork and submit pull requests.

## License

`Peking` is open-sourced software, licensed under the `MIT` license.

## Usage

```swift
import Peking

class ViewController: UIViewController, PekingDelegate {

    // ...

    func picking(_ sender: AnyObject) {
        let peking = PekingController(mode: .library, multipleSelection: true, delegate: self)
        self.present(peking, animated: true, completion: nil)
    }

    // MARK: PekingDelegate Protocol
    func peking(_ peking: PekingController, didSelectImages images: [PekingImage]) {
        print("Number of selection images: \(images.count)")
        peking.dismiss(animated: true, completion: nil)
    }

    func peking(_ peking: PekingController, didCaptureVideo videoURL: URL) {
        print("video completed and output to file: \(videoURL)")
        peking.dismiss(animated: true, completion: nil)
    }

    func peking(_ peking: PekingController, didCapturePhoto photo: UIImage) {
        self.imageView.image = photo
        peking.dismiss(animated: true, completion: nil)
    }

    func pekingCameraRollUnauthorized(_ peking: PekingController) {
        peking.dismiss(animated: true, completion: nil)
        print("Camera roll unauthorized")
    }

    func pekingDidDismiss(_ peking: PekingController) {
        print("Called when the PekingController dismissed")
    }

    func pekingWillDismiss(_ peking: PekingController) {
        print("Called when the close button is pressed")
    }
}
```
