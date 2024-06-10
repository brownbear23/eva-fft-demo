import numpy as np


# array of float values of pixel values and image's width and height for input
def perform_fft(image_pixels, width, height):
    # converts pixel array to 2D numpy array
    image_2d = np.array(image_pixels).reshape((height, width))
    # computes fast fourier transform
    fft_result = np.fft.fft2(image_2d)
    # real and imaginary components after performing fft
    real_part = np.real(fft_result)
    imag_part = np.imag(fft_result)
    # output
    return real_part, imag_part


# prints values in a formatted way
def print_values(label, array):
    print(f"{label}:")
    for row in array:
        print(" ".join(f"{val:.2f}" for val in row))
    print("")


# example usage
image_pixels = list(range(1, 101))
width = 10
height = 10

real, imag = perform_fft(image_pixels, width, height)
# print input and output arrays
print("Input:")
for i in range(height):
    print(image_pixels[i * width : (i + 1) * width])
print("")

print_values("Output-Real Part", real)
print_values("Output-Imaginary Part", imag)
