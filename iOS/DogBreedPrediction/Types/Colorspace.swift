//
//  Colorspace.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/9/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import CoreVideo

// MARK: - Colorspace

enum Colorspace {
    case rgb, bgr
    
    var type: OSType {
        switch self {
        case .rgb:
            return kCVPixelFormatType_32ARGB
        case .bgr:
            return kCVPixelFormatType_32BGRA
        }
    }
}
