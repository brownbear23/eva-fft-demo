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
    print("{}:".format(label))
    max_val_length = len("{:.2f}".format(np.max(np.abs(array)))) + 2 
    for row in array:
        formatted_row = []
        for val in row:
            formatted_row.append("{:>{}}".format("{:.2f}".format(val), max_val_length))
        print(" ".join(formatted_row))
    print("")

# example usage
image_pixels = list(range(1, 101))
width = 10
height = 10

real, imag = perform_fft(image_pixels, width, height)
# print input and output arrays
print("Input:")
max_val_length = len(str(np.max(image_pixels))) + 1 
for i in range(height):
    print(" ".join("{:>{}.0f}".format(val, max_val_length) for val in image_pixels[i * width : (i + 1) * width]))
print("")

print_values("Output-Real Part", real)
print_values("Output-Imaginary Part", imag)
