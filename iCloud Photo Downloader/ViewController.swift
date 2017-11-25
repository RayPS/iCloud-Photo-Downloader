//
//  ViewController.swift
//  iCloud Photo Downloader
//
//  Created by Ray on 20/11/2017.
//  Copyright © 2017 Ray. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var totalProgressBar: UIProgressView!
    @IBOutlet weak var downloadProgressBar: UIProgressView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var infomationLabel: UILabel!

    let manager = PHImageManager.default()
    var currentRequestID: PHImageRequestID! {
        willSet {
            print("----- Will set currentRequestID: ", newValue)
        }
    }

    var assets = [PHAsset]() {
        didSet { print("----- Assets Collected, Count: \(assets.count)") }
    }

    var currentIndex: Int = -1 {
        didSet {
            switch currentIndex {
            case 0...assets.count:
                requestAssets { info in
                    print("\nCurrent index requested: \(self.currentIndex)/\(self.assets.count)")
                    DispatchQueue.main.async {
                        if let info = info {
                            let pathURL = info["PHImageFileURLKey"] as! NSURL?
                            let pathStr: String = pathURL?.absoluteString! ?? "..."
//                            let itemType = String(describing: self.assets[self.currentIndex].mediaType)
                            self.infomationLabel.text = pathStr
                        }
                        self.totalProgress = Float(self.currentIndex) / Float(self.assets.count)
                    }
                    self.currentIndex += 1
                }
            case let i where i > assets.count:
                simpleAlert(title: "Done", message: "All photos & videos is downloaded to your device.")
            default:
                currentIndex = 0
            }
        }
    }

    enum RequestState {
        case stopped
        case downloading
        case disabled
    }

    var currentRequestState: RequestState = .stopped {
        didSet {
            switch currentRequestState {
            case .stopped: // Stop
                if oldValue == .downloading {
                    manager.cancelImageRequest(currentRequestID)
                    infomationLabel.text = "Stopped"
                }
                totalProgress = 0
                itemProgress = 0
                DispatchQueue.main.async {
                    self.button.setTitle("Start", for: .normal)
                    self.button.backgroundColor = UIColor(named: "iOS_Blue")
                }
            case .downloading: // Start
                currentIndex = 0
                DispatchQueue.main.async {
                    self.button.setTitle("Stop", for: .normal)
                    self.button.backgroundColor = .lightGray
                }
            case .disabled:
                DispatchQueue.main.async {
                    self.button.setTitle("Start", for: .normal)
                    self.button.backgroundColor = .lightGray
                }
            }
        }
    }


    var totalProgress: Float = 0.0 {
        didSet {
            DispatchQueue.main.async {
                self.totalLabel.text = String(format: "%d/%d", self.currentIndex, self.assets.count)
                self.totalProgressBar.setProgress(self.totalProgress, animated: true)
            }
        }
    }


    var itemProgress: Float = 0.0 {
        didSet {
            DispatchQueue.main.async {
                self.downloadLabel.text = String(format: "%.0f%%", self.itemProgress * 100)
                self.downloadProgressBar.setProgress(self.itemProgress, animated: false)
            }
        }
    }







    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        grantPhotoAccess {
            self.fetchAssets()
        }

        generate_204(
        success: {
        },
        failure: {
            self.simpleAlert(title: "Network Error", message: "No internet conections. Please check your settings.") })

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.resigningActive),
            name: NSNotification.Name.UIApplicationWillResignActive,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        totalProgressBar.setProgress(0, animated: false)
        downloadProgressBar.setProgress(0, animated: false)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
    }











    func fetchAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = true
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        fetchOptions.predicate = NSPredicate(format:
            "mediaType == %d || mediaType == %d",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaType.video.rawValue
        )

        var fectedObjects = [PHAsset]()
        let fetcher = PHAsset.fetchAssets(with: fetchOptions)
        fetcher.enumerateObjects({ (object, count, stop) in
            fectedObjects.append(object)
        })
        self.assets = fectedObjects
    }




    func requestAssets(completion: @escaping (_ info: [AnyHashable : Any]?) -> Void) {

        switch assets[currentIndex].mediaType {
        case .image:
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = .exact
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.progressHandler = { (progress, error, stop, info) in
                self.itemProgress = Float(progress)
            }

            currentRequestID = manager.requestImageData(for: assets[currentIndex], options: requestOptions) {
                (data, str, orientation, info) in
                completion(info)
            }
        case .video:
            let requestOptions = PHVideoRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.progressHandler = { (progress, error, stop, info) in
                self.itemProgress = Float(progress)
            }

            currentRequestID = manager.requestAVAsset(forVideo: assets[currentIndex], options: requestOptions) {
                (asset, audioMix, info) in
                completion(info)
            }

        default:
            completion(nil)
        }
    }







    @IBAction func buttonTapped(_ sender: Any) {
        Haptic.impact(.medium).generate()

        generate_204(
            success: {
                switch self.currentRequestState {
                case .stopped: self.currentRequestState = .downloading
                case .downloading: self.currentRequestState = .stopped
                case .disabled: self.grantPhotoAccess {}
                }
            },
            failure: {
                self.simpleAlert(title: "Network Error", message: "No internet conections. Please check your settings.")
            })
    }

    @IBAction func storyButtonTapped(_ sender: Any) {
        Haptic.impact(.medium).generate()
        performSegue(withIdentifier: "StoryViewControllerSegue", sender: self)
    }
}


extension ViewController {

    /// Network Condition
    func generate_204(
        success: @escaping () -> Void,
        failure: @escaping () -> Void
        ) {
        if let url = URL(string: "http://captive.apple.com/generate_204") {
            URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                print("----- generate_204: ", error ?? "No Error")
                if error == nil {
                    success()
                } else {
                    failure()
                }
            }.resume()
        }
    }


    func grantPhotoAccess(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .notDetermined:
                print("PHPhotoLibrary.requestAuthorization status is .notDetermined")
            case .restricted:
                print("PHPhotoLibrary.requestAuthorization status is .restricted")
            case .denied:
                self.currentRequestState = .disabled
                self.simpleAlert(title: "Access Denied", message: "Photo access for this app is denied, you can change it in System Settings")
            case .authorized:
                completion()
            }
        }

    }


    func simpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: {
        })
    }
}



extension ViewController {
    @objc fileprivate func resigningActive() {
        currentRequestState = .stopped
    }
}
