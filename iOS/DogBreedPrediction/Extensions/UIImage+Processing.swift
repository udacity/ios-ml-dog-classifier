 //
//  UIImage+Processing.swift
//  DogBreedPrediction
//
//  Created by Jarrod Parkes on 6/7/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreImage

// CREDIT: medium.com/towards-data-science/welcoming-core-ml-8ba325227a28

// MARK: - UIImage (Processing)

extension UIImage {
    
    // MARK: Transformations
    
    func resize(newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func pixelBuffer(colorspace: Colorspace) -> CVPixelBuffer? {
        // NOTE: Create pixel buffer with specified pixel format
        var pixelBuffer: CVPixelBuffer?
        let options = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), colorspace.type, options, &pixelBuffer)
        guard status == kCVReturnSuccess, let finalPixelBuffer = pixelBuffer else {
            return nil
        }
        
        // NOTE: Create context ("canvas") for drawing pixels
        CVPixelBufferLockBaseAddress(finalPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(finalPixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(finalPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // NOTE: Draw pixels on the context, updates pixel buffer
        UIGraphicsPushContext(context)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(finalPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return finalPixelBuffer
    }
    
    // MARK: Processing Filters
    // NOTE: This is done automatically when generating CoreML models. See example of red, green, blue bias for Keras --> CoreML conversions: pythonhosted.org/coremltools/generated/coremltools.converters.keras.convert.html
    
    func swapRedBlueChannels() -> UIImage? {
        guard let cgImage = cgImage, let context = createEmptyContext() else {
            return nil
        }
        
        let width = Int(size.width)
        let height = Int(size.height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else {
            print("unable to get context data")
            return nil
        }
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
        
        for row in 0 ..< Int(height) {
            for column in 0 ..< Int(width) {
                let offset = row * width + column
                let pixel = pixelBuffer[offset]
                pixelBuffer[offset] = RGBA32(red: pixel.blueComponent, green: pixel.greenComponent, blue: pixel.redComponent, alpha: pixel.alphaComponent)
            }
        }
        
        return UIImage(cgImage: context.makeImage()!)
    }
    
    func subtractMeanRGB(red: Double, green: Double, blue: Double) -> UIImage? {
        guard let cgImage = cgImage else {
            return nil
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let normalizedImage = ciImage.applyingFilter("CIColorMatrix", withInputParameters: [
            "inputRVector": CIVector(x: 0.408, y: 0, z: 0),
            "inputGVector": CIVector(x: 0, y: 0.458, z: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.485)
        ])
        
        return UIImage(ciImage: normalizedImage)
    }
    
    // MARK: Helper
    
    private func createEmptyContext() -> CGContext? {
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = size.width
        let height           = size.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * Int(size.width)
        let bitmapInfo       = RGBA32.bitmapInfo
        return CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
    }
}
