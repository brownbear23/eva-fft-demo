import Foundation
import Accelerate
import AppKit

// Function to generate an array of Float numbers from 1 to 100
func generateArray(from start: Int, to end: Int) -> [Float] {
    return (start...end).map { Float($0) }
}

var pixels: [Float] = generateArray(from: 1, to: 100)
print("input", pixels)

func printValues(_ label: String, realPart: [Float], width: Int, height: Int) {
    print(label)
    for i in 0..<height {
        for j in 0..<width {
            print(realPart[i * width + j], terminator: " ")
        }
        print("")
    }
    print("")
}

func performFFT(serialImagePixels: inout [Float], width: Int, height: Int) -> (real: [Float], imag: [Float]) {
    
    // Initialize the arrays for the real and imaginary parts of the complex numbers
    var complexReals = [Float](repeating: 0, count: width * height)
    var complexImaginaries = [Float](repeating: 0, count: width * height)

    complexReals = serialImagePixels
    
    complexReals.withUnsafeMutableBufferPointer { realPtr in
        complexImaginaries.withUnsafeMutableBufferPointer { imagPtr in
              
            var splitComplex = DSPSplitComplex(
                realp: realPtr.baseAddress!,
                imagp: imagPtr.baseAddress!)
            
            var output = Array(UnsafeBufferPointer(start: splitComplex.realp, count: width * height))
            printValues("before FFT", realPart: output, width: width, height: height)
            
            // The binary logarithm of `max(rowCount, columnCount)`.
            let setupLog2n = vDSP_Length(log2(Float(max(width, height))))

            let widthLog2n = vDSP_Length(log2(Float(width)))
            let heightLog2n = vDSP_Length(log2(Float(height)))
            
            if let fft = vDSP_create_fftsetup(setupLog2n, FFTRadix(kFFTRadix2)) {
                
                vDSP_fft2d_zip(fft, &splitComplex,
                               1, 0,
                               widthLog2n, heightLog2n,
                               FFTDirection(kFFTDirection_Forward))
                
                vDSP_destroy_fftsetup(fft)
            }
            
            output = Array(UnsafeBufferPointer(start: splitComplex.realp, count: width * height))
            printValues("after FFT", realPart: output, width: width, height: height)
        }
    }
    return (complexReals, complexImaginaries)
}

// Example of calling the function
let width = 10
let height = 10

let (real, imag) = performFFT(serialImagePixels: &pixels, width: width, height: height)
print("Real Part: \(real)")
print("Imaginary Part: \(imag)")
