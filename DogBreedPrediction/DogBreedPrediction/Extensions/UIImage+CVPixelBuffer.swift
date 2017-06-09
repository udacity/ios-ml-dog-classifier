import UIKit

// CREDIT: medium.com/towards-data-science/welcoming-core-ml-8ba325227a28

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
                let normalizedRed = pixelBuffer[offset].redComponent - averageRGB.redComponent
                let normalizedGreen = pixelBuffer[offset].greenComponent - averageRGB.greenComponent
                let normalizedBlue = pixelBuffer[offset].blueComponent - averageRGB.blueComponent
                pixelBuffer[offset] = RGBA32(red: normalizedRed, green: normalizedGreen, blue: normalizedBlue, alpha: pixelBuffer[offset].alphaComponent)
            }
        }
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: scale, orientation: imageOrientation)
        
        return outputImage
    }
}

//func pixelBufferLong() -> CVPixelBuffer? {
//    let newImage = resize(newSize: CGSize(width: 224/3.0, height: 224/3.0))
//    let ciimage = CIImage(image: newImage!)
//    let tmpcontext = CIContext(options: nil)
//    let cgimage =  tmpcontext.createCGImage(ciimage!, from: ciimage!.extent)
//    let cfnumPointer = UnsafeMutablePointer<UnsafeRawPointer>.allocate(capacity: 1)
//    let cfnum = CFNumberCreate(kCFAllocatorDefault, .intType, cfnumPointer)
//    let keys: [CFString] = [kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey, kCVPixelBufferBytesPerRowAlignmentKey]
//    let values: [CFTypeRef] = [kCFBooleanTrue, kCFBooleanTrue, cfnum!]
//    let keysPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
//    let valuesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 1)
//
//    keysPointer.initialize(to: keys)
//    valuesPointer.initialize(to: values)
//
//    let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, keys.count, nil, nil)
//
//    let width = cgimage!.width
//    let height = cgimage!.height
//
//    var pxbuffer: CVPixelBuffer?
//    var status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
//                                     kCVPixelFormatType_32BGRA, options, &pxbuffer)
//    status = CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
//    guard status == kCVReturnSuccess, let bgrPixelBuffer = pxbuffer else {
//        return nil
//    }
//
//    let bufferAddress = CVPixelBufferGetBaseAddress(bgrPixelBuffer)
//    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//    let bytesperrow = CVPixelBufferGetBytesPerRow(bgrPixelBuffer)
//    let context = CGContext(data: bufferAddress,
//                            width: width,
//                            height: height,
//                            bitsPerComponent: 8,
//                            bytesPerRow: bytesperrow,
//                            space: rgbColorSpace,
//                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
//    context?.concatenate(CGAffineTransform(rotationAngle: 0))
//    context?.concatenate(__CGAffineTransformMake(1, 0, 0, -1, 0, CGFloat(height))) // Flip Vertical
//
//    context?.draw(cgimage!, in: CGRect(x:0, y:0, width:CGFloat(width), height:CGFloat(height)))
//    status = CVPixelBufferUnlockBaseAddress(bgrPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//    return bgrPixelBuffer
//}

//func convert() -> CVPixelBuffer? {
//    // NOTE: Scale source image to 224x224 (distortion is okay)
//    let imageSize = CGSize(width: 224, height: 224)
//    let imageRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
//    UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
//    draw(in: imageRect)
//    guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else {
//        return nil
//    }
//    UIGraphicsEndImageContext()
//
//    // NOTE: Create a pixel buffer for redrawing scaled image as BGR
//    var pixelBuffer: CVPixelBuffer?
//    let options = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
//    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(imageSize.width), Int(imageSize.height), kCVPixelFormatType_32ARGB, options, &pixelBuffer)
//    guard status == kCVReturnSuccess, let bgrPixelBuffer = pixelBuffer else {
//        return nil
//    }
//    // FIXME: Correctly convert between colorspaces (use OpenCV?)
//    // kCVPixelFormatType_32BGRA (works, but not right colorspace)
//    // kCVPixelFormatType_32ARGB (works, but not right colorspace)
//
//    // NOTE: Create BGR context ("canvas") for redrawing scaled image
//    CVPixelBufferLockBaseAddress(bgrPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//    let pixelData = CVPixelBufferGetBaseAddress(bgrPixelBuffer)
//    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//    guard let context = CGContext(data: pixelData, width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(bgrPixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
//        return nil
//    }
//    context.translateBy(x: 0, y: scaledImage.size.height)
//    context.scaleBy(x: 1.0, y: -1.0)
//
//    // NOTE: Redraw scaled image using BGR context, the pixelBuffer is updated
//    UIGraphicsPushContext(context)
//    scaledImage.draw(in: imageRect)
//    UIGraphicsPopContext()
//    CVPixelBufferUnlockBaseAddress(bgrPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//    return pixelBuffer
//}

