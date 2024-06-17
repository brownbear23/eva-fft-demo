import Foundation
import Accelerate
import AppKit
import PlaygroundSupport

// function to load image and convert to grayscale pixel data
func loadImage(path: String) -> (image: NSImage?, pixelData: [Float]?, width: Int, height: Int)? {
    guard let image = NSImage(contentsOfFile: path),
          let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else {
        return nil
    }
    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh
    
    var pixelData = [Float](repeating: 0.0, count: width * height)
    
    for y in 0..<height {
        for x in 0..<width {
            let color = bitmap.colorAt(x: x, y: y)!
            let gray = 0.299 * Float(color.redComponent) + 0.587 * Float(color.greenComponent) + 0.114 * Float(color.blueComponent)
            pixelData[y * width + x] = gray
        }
    }
    return (image, pixelData, width, height)
}

// array of float values of pixel intensities of image and image's width and height for input
func performFFT(serialImagePixels: inout [Float], width: Int, height: Int) -> (real: [Float], imag: [Float]) {
    var complexReals = serialImagePixels
    var complexImaginaries = [Float](repeating: 0, count: width * height)
    
    complexReals.withUnsafeMutableBufferPointer { realPtr in
        complexImaginaries.withUnsafeMutableBufferPointer { imagPtr in
            var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
            let setupLog2n = vDSP_Length(log2(Float(max(width, height))))
            let widthLog2n = vDSP_Length(log2(Float(width)))
            let heightLog2n = vDSP_Length(log2(Float(height)))
            
            if let fft = vDSP_create_fftsetup(setupLog2n, FFTRadix(kFFTRadix2)) {
                vDSP_fft2d_zip(fft, &splitComplex, 1, 0, widthLog2n, heightLog2n, FFTDirection(kFFTDirection_Forward))
                vDSP_destroy_fftsetup(fft)
            }
        }
    }
    // real and imaginary parts after FFT
    return (complexReals, complexImaginaries)
}

// function to compute magnitude and phase from FFT results
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

// function to create NSImage from pixel data
func createImage(from pixelData: [Float], width: Int, height: Int) -> NSImage? {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 1, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceWhite, bytesPerRow: width, bitsPerPixel: 8)
    
    guard let bitmapRep = bitmap else { return nil }
    
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

// Use the correct path for the image within the Playground
if let resourcePath = Bundle.main.path(forResource: "sample_img", ofType: "jpg"),
   let (originalImage, pixelData, width, height) = loadImage(path: resourcePath),
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
        
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let window = NSWindow(contentRect: NSMakeRect(0, 0, 1800, 600), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.contentView = stackView
        window.makeKeyAndOrderFront(nil)
        app.run()
    }
}

// Keep the Playground running
PlaygroundPage.current.needsIndefiniteExecution = true
