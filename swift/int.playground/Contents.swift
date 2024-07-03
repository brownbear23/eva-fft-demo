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

func performFFT(imageData: inout [Float], width: Int, height: Int) -> (real: [Float], imag: [Float]) {
    let rowCount = height
    let columnCount = width
    
    // create split complex format for FFT
    var realParts = [Float](repeating: 0.0, count: rowCount * columnCount)
    var imaginaryParts = [Float](repeating: 0.0, count: rowCount * columnCount)
    var splitComplex = DSPSplitComplex(realp: &realParts, imagp: &imaginaryParts)
    
    // convert input data to complex format
    realParts.withUnsafeMutableBufferPointer { realBuffer in
        imaginaryParts.withUnsafeMutableBufferPointer { imagBuffer in
            var splitComplex = DSPSplitComplex(realp: realBuffer.baseAddress!,
                                               imagp: imagBuffer.baseAddress!)
            imageData.withUnsafeBufferPointer { imageDataPtr in
                imageDataPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: imageData.count) { complexPtr in
                    vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(rowCount * columnCount / 2))
                }
            }
        }
    }
    
    // perform the FFT
    let log2n = vDSP_Length(log2(Float(columnCount)))
    if let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) {
        vDSP_fft2d_zrip(fftSetup, &splitComplex, 1, 0, log2n, log2n, FFTDirection(FFT_FORWARD))
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    return (realParts, imaginaryParts)
}

// example of calling the function
let width = 8
let height = 8

printValues("Input:", values: pixels, width: width, height: height)
let (real, imag) = performFFT(imageData: &pixels, width: width, height: height)
printValues("Output-Real Part:", values: real, width: width, height: height)
printValues("Output-Imaginary Part:", values: imag, width: width, height: height)
