import numpy as np

def perform_fft(image_pixels, width, height):
    image_2d = np.array(image_pixels).reshape((height, width))

    fft_result = np.fft.fft2(image_2d)
    
    real_part = np.real(fft_result)
    imag_part = np.imag(fft_result)
    
    return real_part, imag_part

def print_values(label, array):
    print(f"{label}:")
    for row in array:
        print(" ".join(f"{val:.2f}" for val in row))
    print("")

# Example usage
image_pixels = list(range(1, 101))
width = 10
height = 10

real, imag = perform_fft(image_pixels, width, height)
print(image_pixels)
print_values("Real Part", real)
print_values("Imaginary Part", imag)
