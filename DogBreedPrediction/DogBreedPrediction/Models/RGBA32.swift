//
//  RGBA32.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/8/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import CoreGraphics

struct RGBA32: Equatable {
    private var color: UInt32
    
    var redComponent: UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    var greenComponent: UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    var blueComponent: UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    var alphaComponent: UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    var normalizedColor: RGBA32 {
        let normalizedRed: UInt8 = redComponent - 104
        let normalizedGreen: UInt8 = greenComponent - 117
        let normalizedBlue: UInt8 = blueComponent - 124
        return RGBA32(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: alphaComponent)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }
    
    static let visualNetMean: [UInt8] = [104, 117, 124]
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    
    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return lhs.color == rhs.color
    }
}
