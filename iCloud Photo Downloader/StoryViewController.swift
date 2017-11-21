//
//  StoryViewController.swift
//  iCloud Photo Downloader
//
//  Created by Ray on 21/11/2017.
//  Copyright © 2017 Ray. All rights reserved.
//

import UIKit
import StoreKit

class StoryViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var rateButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.clipsToBounds = false
        rateButton.clipsToBounds = false
        rateButton.layer.cornerRadius = 8
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.scrollView.alpha = 0
        }
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        Haptic.impact(.medium).generate()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func rateButtonTapped(_ sender: Any) {
        SKStoreReviewController.requestReview()
    }
}
