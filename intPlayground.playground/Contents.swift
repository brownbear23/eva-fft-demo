import Foundation
import Accelerate
import AppKit

// function to generate an array of Float numbers from 1 to 100
func generateArray(from start: Int, to end: Int) -> [Float] {
    return (start...end).map { Float($0) }
}

var pixels: [Float] = generateArray(from: 1, to: 100)

func printValues(_ label: String, values: [Float], width: Int, height: Int) {
    print(label)
    let maxVal = values.map { abs($0) }.max() ?? 0
    let maxValLength = String(format: "%.2f", maxVal).count + 1 // Determine the width based on the maximum value
    
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

    complexReals = serialImagePixels
    complexReals.withUnsafeMutableBufferPointer { realPtr in
        complexImaginaries.withUnsafeMutableBufferPointer { imagPtr in
              
            var splitComplex = DSPSplitComplex(
                realp: realPtr.baseAddress!,
                imagp: imagPtr.baseAddress!)
            
            // binary logarithm of `max(rowCount, columnCount)`.
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
        }
    }
    return (complexReals, complexImaginaries)
}

// example of calling the function
let width = 10
let height = 10

printValues("Input:", values: pixels, width: width, height: height)
let (real, imag) = performFFT(serialImagePixels: &pixels, width: width, height: height)
printValues("Output-Real Part:", values: real, width: width, height: height)
printValues("Output-Imaginary Part:", values: imag, width: width, height: height)
