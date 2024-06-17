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

// array of float values of pixel intensities of image and image's width and height for input
func performFFT(serialImagePixels: inout [Float], width: Int, height: Int) -> (real: [Float], imag: [Float]) {
    // initialize the real part of complex numbers
    var complexReals = serialImagePixels
    // initialize the imaginary part of the complex numbers
    var complexImaginaries = [Float](repeating: 0, count: width * height)

    // withUnsafeMutableBufferPointer used
    complexReals.withUnsafeMutableBufferPointer { realPtr in
        complexImaginaries.withUnsafeMutableBufferPointer { imagPtr in
            // initialize a DSPSplitComplex structure with pointers to the real and imaginary parts
            var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
            let setupLog2n = vDSP_Length(log2(Float(max(width, height))))
            let widthLog2n = vDSP_Length(log2(Float(width)))
            let heightLog2n = vDSP_Length(log2(Float(height)))

            // fft setup before performing FFT
            if let fft = vDSP_create_fftsetup(setupLog2n, FFTRadix(kFFTRadix2)) {
                // perform FFT
                vDSP_fft2d_zip(fft, &splitComplex, 1, 0, widthLog2n, heightLog2n, FFTDirection(kFFTDirection_Forward))
                // destory FFT setup to free up memory
                vDSP_destroy_fftsetup(fft)
            } else {
                // when FFT setup object can't be created
                print("Failed to create FFT setup.")
            }
        }
    }
    // real and imaginary parts after FFT
    return (complexReals, complexImaginaries)
}

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

        let (real, imag) = performFFT(serialImagePixels: &pixels, width: width, height: height)
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
