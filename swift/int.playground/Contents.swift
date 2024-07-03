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
    var realParts = [Float](repeating: 0.0, count: rowCount * columnCount / 2)
    var imaginaryParts = [Float](repeating: 0.0, count: rowCount * columnCount / 2)
    var splitComplex = DSPSplitComplex(realp: &realParts, imagp: &imaginaryParts)
    
    // convert input data to complex format
    imageData.withUnsafeBufferPointer { imageDataPtr in
        imageDataPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: imageData.count) { complexPtr in
            vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(rowCount * columnCount / 2))
        }
    }
    
    // perform the FFT
    let log2n = vDSP_Length(log2(Float(columnCount)))
    if let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) {
        vDSP_fft2d_zrip(fftSetup, &splitComplex, 1, 0, log2n, log2n, FFTDirection(FFT_FORWARD))
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    // scale the results
    let scaleFactor = 1.0 / Float(rowCount * columnCount)
    vDSP_vsmul(splitComplex.realp, 1, [scaleFactor], splitComplex.realp, 1, vDSP_Length(rowCount * columnCount / 2))
    vDSP_vsmul(splitComplex.imagp, 1, [scaleFactor], splitComplex.imagp, 1, vDSP_Length(rowCount * columnCount / 2))
    
    // unpack the complex results
    var realOutput = [Float](repeating: 0.0, count: rowCount * columnCount)
    var imagOutput = [Float](repeating: 0.0, count: rowCount * columnCount)
    
    for i in 0..<rowCount {
        for j in 0..<columnCount / 2 {
            realOutput[i * columnCount + j] = splitComplex.realp[i * columnCount / 2 + j]
            imagOutput[i * columnCount + j] = splitComplex.imagp[i * columnCount / 2 + j]
            if j > 0 {
                realOutput[i * columnCount + (columnCount - j)] = splitComplex.realp[i * columnCount / 2 + j]
                imagOutput[i * columnCount + (columnCount - j)] = -splitComplex.imagp[i * columnCount / 2 + j]
            }
        }
    }
    
    // handle the Nyquist component separately
    for i in 0..<rowCount {
        realOutput[i * columnCount + columnCount / 2] = splitComplex.realp[i * columnCount / 2]
        imagOutput[i * columnCount + columnCount / 2] = splitComplex.imagp[i * columnCount / 2]
    }
    
    return (realOutput, imagOutput)
}

// example of calling the function
let width = 8
let height = 8

printValues("Input:", values: pixels, width: width, height: height)
let (real, imag) = performFFT(imageData: &pixels, width: width, height: height)
printValues("Output-Real Part:", values: real, width: width, height: height)
printValues("Output-Imaginary Part:", values: imag, width: width, height: height)
