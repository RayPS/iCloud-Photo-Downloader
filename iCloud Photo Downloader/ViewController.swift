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
//                let isDownloading = progress < 1.0
                let isDownloading = index != self.assets.count
                self.button.alpha = isDownloading ? 0.25 : 1
                self.button.isUserInteractionEnabled = isDownloading ? false : true
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
//                self.imageView.backgroundColor = .black
//                self.imageView.image = UIImage(data: data!)
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
        currentIndex += 1
        requestAssets(byIndex: currentIndex)
        print("\n")
    }

    @IBAction func buttonTapped(_ sender: Any) {
        if totalProgress.progress == 1.0 {
            currentIndex = -1
        }
        queueNextItem()
    }
}





extension ViewController {

    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let alert = UIAlertController(title: "Enter a number", message: nil, preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.text = String(self.currentIndex)
                textField.clearsOnBeginEditing = true
                textField.keyboardType = .numberPad
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let ok = UIAlertAction(title: "OK", style: .default, handler: { _ in
                let textField = alert.textFields!.first
                if let number = Int(textField!.text!) {
                    self.currentIndex = number - 1
                    self.requestAssets(byIndex: self.currentIndex)
                    print("\n")
                }
            })
            alert.addAction(cancel)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }
}
