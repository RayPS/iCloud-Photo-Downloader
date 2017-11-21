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
    @IBOutlet weak var itemTypeLabel: UILabel!

    let manager = PHImageManager.default()
    var assets = [PHAsset]()
    var currentRequestID: PHImageRequestID!

    var currentIndex: Int = 0 {
        didSet {
            if (currentIndex >= 0) && (currentIndex <= assets.count) {
                requestAssets()
            } else if currentIndex > assets.count {
                simpleAlert(title: "Done", message: "All photos & videos is downloaded to your device.")
            }
        }
    }

    enum RequestState {
        case stopped
        case downloading
    }

    var currentRequestState: RequestState = .stopped {
        didSet {
            switch currentRequestState {
            case .stopped: // Stop
                manager.cancelImageRequest(currentRequestID)
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
            }
        }
    }


    var totalProgress: Float = 0.0 {
        didSet {
            DispatchQueue.main.async {
                self.totalLabel.text = String(format: "%d/%d", self.currentIndex, self.assets.count)
                self.totalProgressBar.setProgress(self.totalProgress, animated: true)
                self.itemTypeLabel.text = {
                    let typeDict: [PHAssetMediaType: String] = [
                        .image: "Image",
                        .video: "Video"
                    ]
                    return typeDict[self.assets[self.currentIndex].mediaType]
                }()
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
        fetchAssets()

        generate_204(
        success: {
        },
        failure: {
            self.simpleAlert(title: "Network Error", message: "No internet conections. Please check your settings.") })
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

        let fetcher = PHAsset.fetchAssets(with: fetchOptions)
        fetcher.enumerateObjects({ (object, count, stop) in
            self.assets.append(object)
        })
    }




    func requestAssets() {

        totalProgress = Float(currentIndex) / Float(assets.count)

        switch assets[currentIndex].mediaType {
        case .image:
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = .exact
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.progressHandler = { (progress, _, _, _) in
                self.itemProgress = Float(progress)
            }

            currentRequestID = manager.requestImageData(for: assets[currentIndex], options: requestOptions) {
                (data, str, orientation, info) in
                printCurrentItemInfo(info)
                self.currentIndex += 1

            }
        case .video:
            let requestOptions = PHVideoRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.progressHandler = { (progress, _, _, _) in
                self.itemProgress = Float(progress)
            }

            currentRequestID = manager.requestAVAsset(forVideo: assets[currentIndex], options: requestOptions) {
                (asset, audioMix, info) in
                printCurrentItemInfo(info)
                self.currentIndex += 1
            }

        default:
            break
        }



        func printCurrentItemInfo(_ info: [AnyHashable : Any]?) {
            print("\nCurrent index: \(self.currentIndex)/\(self.assets.count)")
            if let info = info {
                for (key, value) in info {
                    print(key, " ", value)
                }
            }
        }
    }





    @IBAction func buttonTapped(_ sender: Any) {
        Haptic.impact(.medium).generate()

        generate_204(
            success: {
                switch self.currentRequestState {
                case .stopped: self.currentRequestState = .downloading
                case .downloading: self.currentRequestState = .stopped
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

    func generate_204( // Network Condition
        success: @escaping () -> Void,
        failure: @escaping () -> Void
        ) {
        if let url = URL(string: "http://captive.apple.com/generate_204") {
            URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                print("generate_204: ", "error == \(String(describing: error))\n")
                if error == nil {
                    success()
                } else {
                    failure()
                }
            }.resume()
        }
    }


    func simpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true, completion: {
        })
    }
}
