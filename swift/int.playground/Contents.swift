import Foundation
import Accelerate
import AppKit

// generate an array of Float numbers from 1 to 64
func generateArray(from start: Int, to end: Int) -> [Float] {
    return (start...end).map { Float($0) }
}

var pixels: [Float] = generateArray(from: 1, to: 64)

func printValues(_ label: String, values: [Float], width: Int, height: Int) {
    print(label)
    let maxVal = values.map { abs($0) }.max() ?? 0
    let maxValLength = String(format: "%.2f", maxVal).count + 1
    
    for i in 0..<height {
        var formattedRow: [String] = []
        for j in 0..<width {
            let val = values[i * width + j]
            let formattedVal = String(format: "%\(maxValLength).2f", val)
            formattedRow.append(formattedVal)
        }
        print(formattedRow.joined(separator: " "))
    }
    print("")
}

func performFFT(serialImagePixels: inout [Float], width: Int, height: Int) -> (real: [Float], imag: [Float]) {
    // initialize the arrays for the real and imaginary parts of the complex numbers
    var complexReals = [Float](repeating: 0, count: width * height)
    var complexImaginaries = [Float](repeating: 0, count: width * height)

    // copy input image pixles into real part array
    complexReals = serialImagePixels
    // withUnsafeMutableBufferPointer is used to get pointers to arrays
    complexReals.withUnsafeMutableBufferPointer { realPtr in
        complexImaginaries.withUnsafeMutableBufferPointer { imagPtr in
            // initializing for DSPlitComplex Structure
            var splitComplex = DSPSplitComplex(
                realp: realPtr.baseAddress!,
                imagp: imagPtr.baseAddress!)
            
            // binary logarithm of `max(rowCount, columnCount)`.
            let setupLog2n = vDSP_Length(log2(Float(max(width, height))))
            let widthLog2n = vDSP_Length(log2(Float(width)))
            let heightLog2n = vDSP_Length(log2(Float(height)))
            
            // fft setup object
            if let fft = vDSP_create_fftsetup(setupLog2n, FFTRadix(kFFTRadix2)) {
                // perform FFT on the split complex data
                vDSP_fft2d_zip(fft, &splitComplex,
                               1, 0,
                               widthLog2n, heightLog2n,
                               FFTDirection(kFFTDirection_Forward))
                // destroy FFT setup to free up memory
                vDSP_destroy_fftsetup(fft)
            }
        }
    }
    // return real and imaginary parts after performing FFT
    return (complexReals, complexImaginaries)
}

// example of calling the function
let width = 8
let height = 8

printValues("Input:", values: pixels, width: width, height: height)
let (real, imag) = performFFT(serialImagePixels: &pixels, width: width, height: height)
printValues("Output-Real Part:", values: real, width: width, height: height)
printValues("Output-Imaginary Part:", values: imag, width: width, height: height)
