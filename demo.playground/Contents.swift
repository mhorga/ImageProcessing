
import UIKit

struct Pixel {
    var value: UInt32
    var red: UInt8 {
        get { return UInt8(value & 0xFF) }
        set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
    }
    var green: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
        set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
    }
    var blue: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
        set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
    }
    var alpha: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
        set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
    }
}

struct RGBA {
    var pixels: UnsafeMutableBufferPointer<Pixel>
    var width: Int
    var height: Int
    init?(image: UIImage) {
        guard let cgImage = image.CGImage else { return nil }
        width = Int(image.size.width)
        height = Int(image.size.height)
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let imageData = UnsafeMutablePointer<Pixel>.alloc(width * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
        guard let imageContext = CGBitmapContextCreate(imageData, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo) else { return nil }
        CGContextDrawImage(imageContext, CGRect(origin: CGPointZero, size: image.size), cgImage)
        pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
    }
    
    func toUIImage() -> UIImage? {
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.ByteOrder32Big.rawValue
        bitmapInfo |= CGImageAlphaInfo.PremultipliedLast.rawValue & CGBitmapInfo.AlphaInfoMask.rawValue
        let imageContext = CGBitmapContextCreateWithData(pixels.baseAddress, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo, nil, nil)
        guard let cgImage = CGBitmapContextCreateImage(imageContext) else {return nil}
        let image = UIImage(CGImage: cgImage)
        return image
    }
}

let image = UIImage(named: "image")!
let rgba = RGBA(image: image)!
var totalRed = 0
var totalGreen = 0
var totalBlue = 0

for y in 0..<rgba.height {
    for x in 0..<rgba.width {
        let index = y * rgba.width + x
        let pixel = rgba.pixels[index]
        totalRed += Int(pixel.red)
        totalGreen += Int(pixel.green)
        totalBlue += Int(pixel.blue)
    }
}

let pixelCount = rgba.width * rgba.height
let avgRed = totalRed / pixelCount
let avgGreen = totalGreen / pixelCount
let avgBlue = totalBlue / pixelCount

func contrast(image: RGBA) -> RGBA {
    for y in 0..<image.height {
        for x in 0..<image.width {
            let index = y * image.width + x
            var pixel = image.pixels[index]
            let redDelta = Int(pixel.red) - avgRed
            let greenDelta = Int(pixel.green) - avgGreen
            let blueDelta = Int(pixel.blue) - avgBlue
            pixel.red = UInt8(max(min(255, avgRed + 3 * redDelta), 0))
            pixel.green = UInt8(max(min(255, avgGreen + 3 * greenDelta), 0))
            pixel.blue = UInt8(max(min(255, avgBlue + 3 * blueDelta), 0))
            image.pixels[index] = pixel
        }
    }
    return image
}

let newImage = contrast(rgba).toUIImage()
image
