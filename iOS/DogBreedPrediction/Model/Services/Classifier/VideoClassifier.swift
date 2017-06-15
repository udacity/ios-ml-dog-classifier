//
//  VideoClassifier.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/15/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import Vision
import CoreMedia

// MARK: - VideoClassifier

class VideoClassifier {
    
    // MARK: Properties
    
    private let studentDogModel = StudentDogModel()
    private let resnetDogClassLabels = ClassLabel.labelsFromJSON()
    var sampleBuffer: CMSampleBuffer!
    
    // NOTE: Only support back camera (impulseadventure.com/photo/exif-orientation.html)
    var exifOrientationFromDeviceOrientation: Int32 {
        let exifOrientation: DeviceOrientation
        enum DeviceOrientation: Int32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = .top0ColLeft
        case .landscapeRight:
            exifOrientation = .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
    
    // MARK: Vision Requests
    
    private lazy var dogDetectionRequest: VNCoreMLRequest? = {
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
            print("could not load resnet50 as vision core ml model")
            return nil
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let observations = request.results else {
                return
            }
            
            // NOTE: Grab top 5 results
            let results = observations
                .prefix(through: 4)
                .flatMap({ $0 as? VNClassificationObservation })
                .map({ $0.identifier })
            
            // NOTE: Is there a dog in this image?
            var dogFound = false
            for result in results {
                if let _ = self.resnetDogClassLabels[result] {
                    dogFound = true
                    break
                }
            }
            
            // If a dog is a found, then classify it!
            if dogFound {
                self.classifyDogBreed(sampleBuffer: self.sampleBuffer)
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("DogNotFound"), object: self, userInfo: nil)
                }
            }
        }
            
        request.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
        return request
    }()
    
    private lazy var breedClassificationRequest: VNCoreMLRequest? = {
        guard let visionModel = try? VNCoreMLModel(for: self.studentDogModel.model) else {
            print("could not create vision model from coreml model")
            return nil
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                let top3 = observations
                    .prefix(through: 2)
                    .map { Prediction(category: $0.identifier, probability: Double($0.confidence)) }
                let results = Prediction.predictionString(predictions: top3)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("BreedFound"), object: self, userInfo: ["results": results])
                }
            }
        }
        
        request.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
        return request
    }()
    
    // MARK: Dog Detection
    
    func detectDog(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // NOTE: Save buffer for classification
        self.sampleBuffer = sampleBuffer
        
        // NOTE: Start classification pipeline
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: self.exifOrientationFromDeviceOrientation, options: getOptionsForImageBuffer(pixelBuffer))
        do {
            try imageRequestHandler.perform([dogDetectionRequest!])
        } catch {
            print(error)
        }
    }
    
    // MARK: Breed Classification
    
    func classifyDogBreed(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: self.exifOrientationFromDeviceOrientation, options: getOptionsForImageBuffer(pixelBuffer))
        do {
            try imageRequestHandler.perform([breedClassificationRequest!])
        } catch {
            print(error)
        }
    }
    
    // MARK: Helper
    
    func getOptionsForImageBuffer(_ imageBuffer: CVImageBuffer) -> [VNImageOption:Any] {
        var requestOptions: [VNImageOption:Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(imageBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
        }
        return requestOptions
    }
}

