//
//  Prediction.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/7/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

// MARK: - Prediction

struct Prediction {
    
    // MARK: Properties
    
    let category: String
    let probability: Double
    
    // MARK: Format Results
    
    static func topPredictions(_ k: Int, _ prob: [String: Double]) -> String {
        precondition(k <= prob.count)
        let topPredictions = Array(prob.map { x in Prediction(category: x.key, probability: x.value) }
            .sorted(by: { a, b -> Bool in a.probability > b.probability })
            .prefix(through: k - 1))
        return predictionString(predictions: topPredictions)
    }
    
    static func predictionString(predictions: [Prediction]) -> String {
        var s: [String] = []
        for (i, prediction) in predictions.enumerated() {
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, prediction.category, prediction.probability * 100))
        }
        return s.joined(separator: "\n\n")
    }
}
