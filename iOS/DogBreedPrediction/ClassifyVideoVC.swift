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
    
    private var session: AVCaptureSession?
    private var output: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var classificationRequest: VNCoreMLRequest?
    
    private let resultLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 44.0))
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
    
    // MARK: Vision Methods
    
    private func initializeVision() {
        guard let visionModel = try? VNCoreMLModel(for: Resnet50().model) else {
            fatalError("Couldn't load Resnet50 model.")
        }
        
        classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassification)
        classificationRequest?.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
    }
    
    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            DispatchQueue.main.async {
                self.resultLabel.text = "Not seeing any dogs..."
            }
            return
        }
        
        // NOTE: Limit to 5 results and at least 20% confidence
        let result = observations[0...4]
            .flatMap({ $0 as? VNClassificationObservation })
            .filter({ $0.confidence > 0.2 })
            .map({ $0.identifier })
            .joined(separator: ", ")
        
        DispatchQueue.main.async {
            self.resultLabel.text = result
        }
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NOTE: Check for camera
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
        initializeVision()
        
        // NOTE: Begin video feed
        if let session = session {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            if let previewLayer = previewLayer {
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewLayer.frame = view.bounds
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
        previewLayer?.frame = view.bounds
        resultLabel.frame = CGRect(x: 0.0, y: view.frame.size.height - resultLabel.frame.size.height, width: view.frame.size.width, height: resultLabel.frame.size.height)
        closeButton.frame = CGRect(x: view.frame.size.width - 64, y: 32, width: 48, height: 48)
    }
}

// MARK: - ClassifyVideoVC: AVCaptureVideoDataOutputSampleBufferDelegate

extension ClassifyVideoVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let request = classificationRequest else {
            return
        }
        
        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        // TODO: Get the orientation from the device. This only supports portrait orientation (6) right now.
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: 6, options: requestOptions)
        do {
            try imageRequestHandler.perform([request])
        } catch {
            print(error)
        }
    }
}
