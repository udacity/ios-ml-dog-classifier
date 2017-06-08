import UIKit

// CREDIT: Based on code from github.com/cieslak/CoreMLCrap.

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
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(imageSize.width), Int(imageSize.height), kCVPixelFormatType_32BGRA, options, &pixelBuffer)
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
}
