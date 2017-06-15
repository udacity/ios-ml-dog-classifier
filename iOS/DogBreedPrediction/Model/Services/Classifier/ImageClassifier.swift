//
//  ImageClassifier.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/13/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import Foundation
import Vision
import CoreMedia

// MARK: - ImageClassifier

class ImageClassifier {
    
    // MARK: Properties
    
    private let studentDogModel = StudentDogModel()
    
    // MARK: Image Classification
    
    func classifyImageWithVision(image: CGImage, completionHandler: @escaping (String) -> Void) {
        guard let visionModel = try? VNCoreMLModel(for: studentDogModel.model) else {
            completionHandler("could not create vision model from coreml model")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let observations = request.results as? [VNClassificationObservation] {                
                let top3 = observations
                    .prefix(through: 2)
                    .map { Prediction(category: $0.identifier, probability: Double($0.confidence)) }
                completionHandler(Prediction.predictionString(predictions: top3))
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image)
        try? handler.perform([request])
    }
    
    // MARK: Legacy Image Classification
    
    func classifyImageWithCoreML(image: UIImage, completionHandler: @escaping (String) -> Void) {
        // NOTE: Do any pre-processing on background thread
        DispatchQueue.global(qos: .background).async {
            guard let normalizedImage = image.resize(newSize: CGSize(width: 224, height: 224)), let imageData = normalizedImage.pixelBuffer() else {
                completionHandler("preprocessing failed")
                return
            }
            
            // NOTE: Format results
            if let prediction = try? self.studentDogModel.prediction(image: imageData) {
                completionHandler(Prediction.topPredictions(5, prediction.classLabelProbs))
            } else {
                completionHandler("prediction failed")
            }
        }
    }        
}
