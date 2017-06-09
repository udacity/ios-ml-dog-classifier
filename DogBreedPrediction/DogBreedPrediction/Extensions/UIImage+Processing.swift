//
//  UIImage+Processing.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/7/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit

// CREDIT: medium.com/towards-data-science/welcoming-core-ml-8ba325227a28

// MARK: - UIImage (Processing)

extension UIImage {
    
    func resize(newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func pixelBuffer(forPixelFormat pixelFormat: OSType) -> CVPixelBuffer? {
        // NOTE: Create pixel buffer with specified pixel format
        var pixelBuffer: CVPixelBuffer?
        let options = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), pixelFormat, options, &pixelBuffer)
        guard status == kCVReturnSuccess, let bgrPixelBuffer = pixelBuffer else {
            return nil
        }
        
        // NOTE: Create context ("canvas") for drawing pixels
        CVPixelBufferLockBaseAddress(bgrPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(bgrPixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(bgrPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // NOTE: Draw pixels on the context, updates pixel buffer
        UIGraphicsPushContext(context)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(bgrPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return bgrPixelBuffer
    }
    
    func normalizeRGB(averageRGB: RGBA32) -> UIImage? {
        guard let cgImage = cgImage else {
            return nil
        }
        
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = cgImage.width
        let height           = cgImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo
        let averageRed       = averageRGB.redComponent
        let averageGreen     = averageRGB.greenComponent
        let averageBlue      = averageRGB.blueComponent
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else {
            print("unable to get context data")
            return nil
        }
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
        
        for row in 0 ..< Int(height) {
            for column in 0 ..< Int(width) {
                let offset = row * width + column
                let normalizedRed = pixelBuffer[offset].redComponent > averageRed ? pixelBuffer[offset].redComponent - averageRed : 0                                                
                let normalizedGreen = pixelBuffer[offset].greenComponent > averageGreen ? averageRGB.greenComponent - averageGreen : 0
                let normalizedBlue = pixelBuffer[offset].blueComponent > averageBlue ? averageRGB.blueComponent - averageBlue : 0
                pixelBuffer[offset] = RGBA32(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: pixelBuffer[offset].alphaComponent)
            }
        }
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: scale, orientation: imageOrientation)
        
        return outputImage
    }
}
