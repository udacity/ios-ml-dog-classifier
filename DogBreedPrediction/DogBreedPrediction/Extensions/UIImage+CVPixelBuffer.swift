import UIKit

// CREDIT: Based on code from github.com/cieslak/CoreMLCrap.
// CREDIT: Based on code from stackoverflow.com/questions/31661023/change-color-of-certain-pixels-in-a-uiimage

extension UIImage {
    
    func convert() -> CVPixelBuffer? {                
        // NOTE: Scale source image to 224x224 (distortion is okay)
        let imageSize = CGSize(width: 224, height: 224)
        let imageRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
        draw(in: imageRect)
        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        
        // NOTE: Create a pixel buffer for redrawing scaled image as BGR
        var pixelBuffer: CVPixelBuffer?
        let options = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(imageSize.width), Int(imageSize.height), kCVPixelFormatType_32ARGB, options, &pixelBuffer)
        guard status == kCVReturnSuccess, let bgrPixelBuffer = pixelBuffer else {
            return nil
        }
        // FIXME: Correctly convert between colorspaces (use OpenCV?)
        // kCVPixelFormatType_32BGRA (works, but not right colorspace)
        // kCVPixelFormatType_32ARGB (works, but not right colorspace)
        
        // NOTE: Create BGR context ("canvas") for redrawing scaled image
        CVPixelBufferLockBaseAddress(bgrPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(bgrPixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(bgrPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        context.translateBy(x: 0, y: scaledImage.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // NOTE: Redraw scaled image using BGR context, the pixelBuffer is updated
        UIGraphicsPushContext(context)
        scaledImage.draw(in: imageRect)
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(bgrPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
    
    func subtractImageNetMean() -> UIImage? {
        guard let imageAsCGImage = cgImage else {
            print("unable to get cgImage")
            return nil
        }
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = imageAsCGImage.width
        let height           = imageAsCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("unable to create context")
            return nil
        }
        context.draw(imageAsCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else {
            print("unable to get context data")
            return nil
        }
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)

        for row in 0 ..< Int(height) {
            for column in 0 ..< Int(width) {
                let offset = row * width + column                
                pixelBuffer[offset] = pixelBuffer[offset].normalizedColor
            }
        }
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: scale, orientation: imageOrientation)
        
        return outputImage
    }
}
