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
    @IBOutlet weak var totalProgress: UIProgressView!
    @IBOutlet weak var downloadProgress: UIProgressView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var itemTypeLabel: UILabel!

    var assets = [PHAsset]()
    var currentIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        fetchAssets()
        print("\n")
    }

    override func viewWillAppear(_ animated: Bool) {
        totalProgress.setProgress(0, animated: false)
        downloadProgress.setProgress(0, animated: false)
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


    func requestAssets(byIndex index: Int!) {

        func setTotalProgress() {
            DispatchQueue.main.async {
                self.totalLabel.text = String(format: "%d/%d", index, self.assets.count)
                self.totalProgress.setProgress(Float(index) / Float(self.assets.count), animated: true)
                self.itemTypeLabel.text = {
                    let typeDict: [PHAssetMediaType: String] = [
                        .image: "Image",
                        .video: "Video"
                    ]
                    return typeDict[self.assets[index].mediaType]
                }()
            }
        }

        func setDownloadProgress(_ progress: Double) {
            DispatchQueue.main.async {
                self.downloadLabel.text = String(format: "%.0f%%", progress * 100)
                self.downloadProgress.setProgress(Float(progress), animated: false)
            }
        }

        func printCurrentItemInfo(_ info: [AnyHashable : Any]?) {
            print("Current index: \(self.currentIndex)/\(self.assets.count)")
            if let info = info {
                for (key, value) in info {
                    print(key, " ", value)
                }
            }
        }




        setTotalProgress()

        let manager = PHImageManager.default()
        switch assets[index].mediaType {
        case .image:
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = .exact
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.progressHandler = { (progress, error, stop, info) in
                setDownloadProgress(progress)
            }

            manager.requestImageData(for: assets[index], options: requestOptions) {
                (data, str, orientation, info) in
                printCurrentItemInfo(info)
                self.queueNextItem()
            }
        case .video:
            let requestOptions = PHVideoRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.progressHandler = { (progress, error, stop, info) in
                setDownloadProgress(progress)
            }

            manager.requestAVAsset(forVideo: assets[index], options: requestOptions) {
                (asset, audioMix, info) in
                printCurrentItemInfo(info)
                self.queueNextItem()
            }

        default:
            break
        }
    }

    func queueNextItem() {
        if currentIndex < assets.count {
            currentIndex += 1
            requestAssets(byIndex: currentIndex)
        } else {
            let alert = UIAlertController(title: "Done", message: "All photos & videos are downloaded to your device.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: {
            })
        }
        print("\n")
    }

    @IBAction func buttonTapped(_ sender: Any) {
        Haptic.impact(.medium).generate()
        self.button.alpha = 0.1
        self.button.isUserInteractionEnabled = false
        queueNextItem()
    }
}

