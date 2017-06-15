//
//  ClassifyVideoVC.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/9/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

// MARK: - ClassifyVideoVC: UIViewController

class ClassifyVideoVC: UIViewController {
    
    // MARK: Properties
    
    private let classifier = Classifier()
    private var session: AVCaptureSession?
    private var output: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?    
        
    private let resultLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 90.0))
        label.backgroundColor = .black
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 15.0)
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    private let closeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(#imageLiteral(resourceName: "close"), for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        return button
    }()
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NOTE: Subscribe to dog detection events
        NotificationCenter.default.addObserver(self, selector: #selector(dogDetected), name: NSNotification.Name("DogDetected"), object: classifier)
        NotificationCenter.default.addObserver(self, selector: #selector(dogNotFound), name: NSNotification.Name("DogNotFound"), object: classifier)
        
        // NOTE: Check and initialize camera
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let cameraLabel = UILabel(frame: view.bounds)
            cameraLabel.text = "Must use a device with a camera."
            cameraLabel.backgroundColor = .black
            cameraLabel.textColor = .white
            cameraLabel.font = .boldSystemFont(ofSize: 15.0)
            cameraLabel.numberOfLines = 0
            cameraLabel.textAlignment = .center
            view.addSubview(cameraLabel)
            return
        }
        initializeCamera()
        
        // NOTE: Begin video feed
        if let session = session {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            if let previewLayer = previewLayer {
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.width)
                view.layer.addSublayer(previewLayer)
            }
        }
        session?.startRunning()
        
        // NOTE: Add remaining views
        view.addSubview(resultLabel)
        view.addSubview(closeButton)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.width)
        resultLabel.frame = CGRect(x: 0.0, y: view.frame.size.height - resultLabel.frame.size.height, width: view.frame.size.width, height: resultLabel.frame.size.height)
        closeButton.frame = CGRect(x: view.frame.size.width - 64, y: 32, width: 48, height: 48)
    }
    
    // MARK: Dismiss
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Camera Methods
    
    private func initializeCamera() {
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSession.Preset.high
        if let device = AVCaptureDevice.default(for: AVMediaType.video),
            let input = try? AVCaptureDeviceInput(device: device) {
            session?.addInput(input)
        }
        
        // NOTE: Use a background queue when processing the session output
        let queue = DispatchQueue.global(qos: .background)
        output = AVCaptureVideoDataOutput()
        output?.setSampleBufferDelegate(self, queue: queue)
        if let output = output {
            session?.addOutput(output)
        }
    }
    
    // MARK: Determine Dog Breed
    
    @objc private func dogDetected(notification: Notification) {
        if let dogDetectedFrame = notification.userInfo?["frame"] as? CIImage {
            classifier.classifyImageWithVision(image: dogDetectedFrame) { (predictionString, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self.resultLabel.text = error
                    } else {
                        self.resultLabel.text = predictionString!
                    }                    
                }                
            }
        } else {
            print("frame not found")
        }
    }
    
    @objc private func dogNotFound(notification: Notification) {
        self.resultLabel.text = "No dogs present..."
    }
}

// MARK: - ClassifyVideoVC: AVCaptureVideoDataOutputSampleBufferDelegate

extension ClassifyVideoVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // NOTE: Get pixel buffer for current video frame
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // NOTE: Save frame for classifier
        classifier.currentFrame = CIImage(cvPixelBuffer: pixelBuffer)
        
        // NOTE: Tell the classifer to start!
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions[.cameraIntrinsics] = cameraIntrinsicData
        }
        classifier.classifyVideoFrame(pixelBuffer: pixelBuffer, requestOptions: requestOptions)
    }
}
