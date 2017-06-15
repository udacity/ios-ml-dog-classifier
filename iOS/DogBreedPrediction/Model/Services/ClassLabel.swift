//
//  ClassLabel.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/13/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import Foundation

// MARK: - ClassLabel: Codable

struct ClassLabel: Codable {
    
    // MARK: Properties
    
    let id: String
    let label: String
    
    // MARK: Helper
    
    static func labelsFromJSON() -> [String: ClassLabel] {
        // NOTE: Grab all class label from JSON
        var labels: [ClassLabel]?
        do {
            if let file = Bundle.main.url(forResource: "ResnetLabels", withExtension: "json") {
                let data = try Data(contentsOf: file)
                labels = try? JSONDecoder().decode([ClassLabel].self, from: data)
            }
        } catch {
            print("couldn't parse resnet class labels")
        }
        
        // NOTE: Construct dictionary for quick look-up with class labels
        var labelsDictionary = [String: ClassLabel]()
        if let labels = labels {
            for classLabel in labels {
                labelsDictionary[classLabel.label] = classLabel
            }
        }
        return labelsDictionary
    }
}
