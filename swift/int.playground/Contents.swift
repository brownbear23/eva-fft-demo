import Foundation
import Accelerate
import AppKit

// generate an array of Float numbers from 1 to 64
func generateArray(from start: Int, to end: Int) -> [Float] {
    return (start...end).map { Float($0) }
}

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

func nextPowerOfTwo(_ n: Int) -> Int {
    return Int(pow(2.0, ceil(log2(Double(n)))))
}

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

// example of calling the function
let width = 8
let height = 8
var pixels: [Float] = generateArray(from: 1, to: width*height)

printValues("Input:", values: pixels, width: width, height: height)
let (real, imag) = performFFT(imageData: &pixels, width: width, height: height)
printValues("Output-Real Part:", values: real, width: width, height: height)
printValues("Output-Imaginary Part:", values: imag, width: width, height: height)


