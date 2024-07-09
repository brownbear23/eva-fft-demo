import Foundation
import Accelerate
import AppKit
import PlaygroundSupport

// load image and convert to grayscale pixel data
func loadImage(path: String) -> (image: NSImage?, pixelData: [Float]?, width: Int, height: Int)? {
    guard let image = NSImage(contentsOfFile: path) else {
        print("Failed to load image from path: \(path)")
        return nil
    }
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else {
        print("Failed to get bitmap representation of the image.")
        return nil
    }
    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh

    var pixelData = [Float](repeating: 0.0, count: width * height)

    for y in 0..<height {
        for x in 0..<width {
            guard let color = bitmap.colorAt(x: x, y: y) else {
                print("Failed to get color at x: \(x), y: \(y)")
                continue
            }
            let gray = 0.299 * Float(color.redComponent) + 0.587 * Float(color.greenComponent) + 0.114 * Float(color.blueComponent)
            pixelData[y * width + x] = gray
        }
    }
    return (image, pixelData, width, height)
}


func printValues(_ label: String, values: [Float], width: Int, height: Int) {
    print(label)
    let maxVal = values.map { abs($0) }.max() ?? 0
    let maxValLength = String(format: "%.2f", maxVal).count + 1
    
    for i in 0..<6 {
        var formattedRow: [String] = []
        for j in 0..<6 {
            let val = values[i * width + j]
            let formattedVal = String(format: "%\(maxValLength).2f", val)
            formattedRow.append(formattedVal)
        }
        print(formattedRow.joined(separator: " "))
    }
    print("")
}

func nextPowerOfTwo(_ n: Int) -> Int {
    return Int(pow(2.0, ceil(log2(Double(n)))))
}

// array of float values of pixel intensities of image and image's width and height for input
func performFFT(imageData: inout [Float], width: Int, height: Int) -> (real: [Float], imag: [Float]) {
    let rowCount = nextPowerOfTwo(height)
    let columnCount  = nextPowerOfTwo(width)
    let frameCount = height * width
    let paddedSize = nextPowerOfTwo(height * width)
    print(rowCount,columnCount,paddedSize)
    
    // create split complex format for FFT
    var realParts = UnsafeMutableBufferPointer<Float>.allocate(capacity: paddedSize)
    defer {realParts.deallocate()}

    var imaginaryParts = UnsafeMutableBufferPointer<Float>.allocate(capacity: paddedSize)
    defer {imaginaryParts.deallocate()}
    

    // initialize the real buffer with the original data and pad the rest with zeros
    _ = realParts.initialize(from: imageData + Array(repeating: 0.0, count: paddedSize - frameCount))
       
    imaginaryParts.initialize(repeating: 0.0)
    
    var splitComplex = DSPSplitComplex(realp: realParts.baseAddress!, imagp: imaginaryParts.baseAddress!)
    
    // perform the FFT
    let log2n = vDSP_Length(Int(log2(Float(max(rowCount, columnCount)))))
    let widthLog2n = vDSP_Length(Int(log2(Float(columnCount))))
    let heightLog2n = vDSP_Length(Int(log2(Float(rowCount))))
    
    if let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) {
        vDSP_fft2d_zip(fftSetup, &splitComplex, 1, 0, widthLog2n, heightLog2n, FFTDirection(FFT_FORWARD))
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    let realOutput = Array(realParts)
    let imagOutput = Array(imaginaryParts)
    
    return (realOutput, imagOutput)
}

func generateArray(from start: Int, to end: Int) -> [Float] {
    return (start...end).map { Float($0) }
}
let width = 512
let height = 1024
var pixels: [Float] = generateArray(from: 1, to: width*height)

let (real, imag) = performFFT(imageData: &pixels, width: width, height: height)
printValues("Output-Real Part:", values: real, width: width, height: height)
printValues("Output-Imaginary Part:", values: imag, width: width, height: height)

// compute magnitude and phase from FFT results
func computeMagnitudeAndPhase(real: [Float], imag: [Float]) -> (magnitude: [Float], phase: [Float]) {
    var magnitudes = [Float](repeating: 0, count: real.count)
    var phases = [Float](repeating: 0, count: real.count)

    real.withUnsafeBufferPointer { realPtr in
        imag.withUnsafeBufferPointer { imagPtr in
            var splitComplex = DSPSplitComplex(realp: UnsafeMutablePointer(mutating: realPtr.baseAddress!), imagp: UnsafeMutablePointer(mutating: imagPtr.baseAddress!))

            vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(real.count))
            vDSP_zvphas(&splitComplex, 1, &phases, 1, vDSP_Length(real.count))
        }
    }

    // apply log scale to magnitudes for better visualization
    var logMagnitudes = [Float](repeating: 0, count: real.count)
    var N = Int32(real.count)
    vvlog1pf(&logMagnitudes, magnitudes, &N)

    return (logMagnitudes, phases)
}

// create NSImage from pixel data
func createImage(from pixelData: [Float], width: Int, height: Int) -> NSImage? {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceWhite, bytesPerRow: width, bitsPerPixel: 8)

    guard let bitmapRep = bitmap else {
        print("Failed to create bitmap representation.")
        return nil
    }

    for y in 0..<height {
        for x in 0..<width {
            let pixelValue = UInt8(min(max(pixelData[y * width + x] * 255.0, 0), 255))
            bitmapRep.bitmapData?[y * width + x] = pixelValue
        }
    }

    let image = NSImage(size: NSSize(width: width, height: height))
    image.addRepresentation(bitmapRep)

    return image
}

// function to save NSImage to file
func saveImage(_ image: NSImage, to path: String) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to get PNG representation of the image.")
        return false
    }

    do {
        try data.write(to: URL(fileURLWithPath: path))
        return true
    } catch {
        print("Error saving image: \(error)")
        return false
    }
}

// use the Playground's Documents directory to save the images
let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

if let imagePath = Bundle.main.path(forResource: "sample_img", ofType: "jpg") {
    if let (originalImage, pixelData, width, height) = loadImage(path: imagePath),
       var pixels = pixelData {

        let (real, imag) = performFFT(imageData: &pixels, width: width, height: height)
        let (magnitude, phase) = computeMagnitudeAndPhase(real: real, imag: imag)

        let magnitudeImage = createImage(from: magnitude, width: width, height: height)
        let phaseImage = createImage(from: phase, width: width, height: height)

        if let originalImage = originalImage,
           let magnitudeImage = magnitudeImage,
           let phaseImage = phaseImage {

            let imageViewOriginal = NSImageView(image: originalImage)
            let imageViewMagnitude = NSImageView(image: magnitudeImage)
            let imageViewPhase = NSImageView(image: phaseImage)

            let stackView = NSStackView(views: [imageViewOriginal, imageViewMagnitude, imageViewPhase])
            stackView.orientation = .horizontal
            stackView.alignment = .centerY
            stackView.distribution = .equalSpacing

            // Save images to the Documents directory
            let originalImagePath = documentsDirectory.appendingPathComponent("original_image.png").path
            let magnitudeImagePath = documentsDirectory.appendingPathComponent("magnitude_image.png").path
            let phaseImagePath = documentsDirectory.appendingPathComponent("phase_image.png").path

            _ = saveImage(originalImage, to: originalImagePath)
            _ = saveImage(magnitudeImage, to: magnitudeImagePath)
            _ = saveImage(phaseImage, to: phaseImagePath)

            // Display the images in the Playground live view
            PlaygroundPage.current.liveView = stackView
            PlaygroundPage.current.needsIndefiniteExecution = true
        } else {
            print("Failed to create one or more images.")
        }
    } else {
        print("Failed to load the image or create pixel data.")
    }
} else {
    print("Failed to find the image in the playground resources.")
}
