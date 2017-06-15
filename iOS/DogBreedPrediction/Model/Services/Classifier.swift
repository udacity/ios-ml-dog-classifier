//
//  Classifier.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/13/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import Foundation
import Vision

// MARK: - Classifier

class Classifier {
    
    // MARK: Properties
    
    var currentFrame: CIImage!
    
    private let studentDogModel = StudentDogModel()
    private let resnetDogClassLabels = ClassLabel.labelsFromJSON()
    private lazy var resnetDogDetectionRequest: VNCoreMLRequest? = {
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
            print("could not load resnet50 as vision core ml model")
            return nil
        }
        let request = VNCoreMLRequest(model: model, completionHandler: self.detectDogRequestHandler)
        request.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
        return request
    }()
    
    // MARK: Detection
    
    func detectDogRequestHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            return
        }
        
        let results = observations[0...4]
            .flatMap({ $0 as? VNClassificationObservation })
            .filter({ $0.confidence > 0.4 })
            .map({ $0.identifier })
        
        // NOTE: If dog class is indentified, then send notification to detect breed
        for result in results {
            if let _ = resnetDogClassLabels[result] {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("DogDetected"), object: self, userInfo: ["frame": self.currentFrame])
                }
                break
            }
        }
        
        // NOTE: Otherwise, send that dog is not found
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("DogNotFound"), object: self, userInfo: nil)
        }
    }
    
    // MARK: Classification
    
    func classifyVideoFrame(pixelBuffer: CVPixelBuffer, requestOptions: [VNImageOption: Any]) {
        // NOTE: This only supports portrait orientation (6) right now.
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: 6, options: requestOptions)
        do {
            try imageRequestHandler.perform([resnetDogDetectionRequest!])
        } catch {
            print(error)
        }
    }
    
    func classifyImageWithVision(image: CIImage, completionHandler: @escaping (String?, String?) -> Void) {
        guard let visionModel = try? VNCoreMLModel(for: studentDogModel.model) else {
            completionHandler(nil, "could not create vision model from coreml model")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                let top5 = observations
                    .prefix(through: 4)
                    .map { Prediction(category: $0.identifier, probability: Double($0.confidence)) }
                completionHandler(self.predictionString(predictions: top5), nil)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        try? handler.perform([request])
    }
    
    func classifyImageWithVision(image: CGImage, completionHandler: @escaping (String?, String?) -> Void) {
        guard let visionModel = try? VNCoreMLModel(for: studentDogModel.model) else {
            completionHandler(nil, "could not create vision model from coreml model")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {
                let top5 = observations
                    .prefix(through: 4)
                    .map { Prediction(category: $0.identifier, probability: Double($0.confidence)) }
                completionHandler(self.predictionString(predictions: top5), nil)
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image)
        try? handler.perform([request])
    }
    
    // MARK: Format Results
    
    func predictionString(predictions: [Prediction]) -> String {
        var s: [String] = []
        for (i, prediction) in predictions.enumerated() {
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, prediction.category, prediction.probability * 100))
        }
        return s.joined(separator: "\n\n")        
    }
    
    func top(_ k: Int, _ prob: [String: Double]) -> [Prediction] {
        precondition(k <= prob.count)
        return Array(prob.map { x in Prediction(category: x.key, probability: x.value) }
            .sorted(by: { a, b -> Bool in a.probability > b.probability })
            .prefix(through: k - 1))
    }
    
    // MARK: Legacy Classification
    
    func classifyImageWithCoreML(image: UIImage, completionHandler: @escaping (String?, String?) -> Void) {
        // NOTE: Do any pre-processing on background thread
        DispatchQueue.global(qos: .background).async {
            guard let normalizedImage = image.resize(newSize: CGSize(width: 224, height: 224)), let imageData = normalizedImage.pixelBuffer(colorspace: .rgb) else {
                completionHandler(nil, "preprocessing failed")
                return
            }
            
            // NOTE: Format results
            if let prediction = try? self.studentDogModel.prediction(image: imageData) {
                let top5 = self.top(5, prediction.classLabelProbs)
                completionHandler(self.predictionString(predictions: top5), nil)
            } else {
                completionHandler(nil, "prediction failed")
            }
        }
    }
}
