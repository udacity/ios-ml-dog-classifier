//
//  ClassifyVideoVC.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/9/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreMedia

// CREDIT: github.com/yulingtianxia/Core-ML-Sample

// MARK: - ClassifyVideoVC: UIViewController

class ClassifyVideoVC: UIViewController {
    
    // MARK: Properties
    
    private let classifier = VideoClassifier()
    private var videoCapture: VideoCapture!
    private let classifyVideoView: ClassifyVideoView = {
        let view = ClassifyVideoView(frame: .zero)
        return view
    }()
    
    // FIXME: Because of delayed processing, count frames without dogs until it reaches a threshold before displaying "Searching for dogs..."
    private var nullCount = 0
            
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        classifyVideoView.delegate = self
        classifyVideoView.frame = view.frame
        view = classifyVideoView
        
        // NOTE: Subscribe to dog detection events
        NotificationCenter.default.addObserver(self, selector: #selector(breedFound), name: NSNotification.Name("BreedFound"), object: classifier)
        NotificationCenter.default.addObserver(self, selector: #selector(dogNotFound), name: NSNotification.Name("DogNotFound"), object: classifier)        
        
        // NOTE: Initialize video camera
        // FIXME: Add square focus frame to camera
        let spec = VideoSpec(fps: 10, size: CGSize(width: 224, height: 224))
        videoCapture = VideoCapture(cameraType: .back,
                                    preferredSpec: spec,
                                    previewContainer: classifyVideoView.previewView.layer)
        
        videoCapture.imageBufferHandler = { [unowned self] (imageBuffer) in
            self.classifier.detectDog(sampleBuffer: imageBuffer)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let videoCapture = videoCapture else {return}
        videoCapture.stopCapture()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillDisappear(animated)
    }
    
    // MARK: Notifications
    
    @objc private func breedFound(notification: Notification) {
        nullCount = 0
        if let results = notification.userInfo?["results"] as? String {
            classifyVideoView.updatePredictionLabel(withText: results)
        }
    }
    
    @objc private func dogNotFound(notification: Notification) {
        nullCount += 1
        if nullCount >= 2 {
            classifyVideoView.updatePredictionLabel(withText: "Searching for dogs...")
        }
    }
}

// MARK: - ClassifyVideoVC: ClassifyVideoViewDelegate

extension ClassifyVideoVC: ClassifyVideoViewDelegate {
    func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}
