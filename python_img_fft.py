import numpy as np
from PIL import Image
import matplotlib.pyplot as plt


# array of float values of pixel values and image's width and height for input
def perform_fft(image_pixels, width, height):
    # converts pixel array to 2D numpy array
    image_2d = np.array(image_pixels).reshape((height, width))
    # computes fast fourier transform
    fft_result = np.fft.fft2(image_2d)
    # real and imaginary compoenets after performing fft
    real_part = np.real(fft_result)
    imag_part = np.imag(fft_result)
    # output
    return real_part, imag_part


def print_values(label, array):
    print(f"{label}:")
    for row in array:
        print(" ".join(f"{val:.2f}" for val in row))
    print("")


original_image = Image.open("images/sample_img.jpg")
# Convert the image to grayscale for FFT processing
grayscale_image = original_image.convert("L")

image_pixels = np.asarray(grayscale_image).flatten()
width, height = grayscale_image.size

# Perform FFT
real, imag = perform_fft(image_pixels, width, height)
print_values("Real Part (Python)", real)

# Display the original colorful image, grayscale image, and transformed images
plt.figure(figsize=(16, 8))

plt.subplot(1, 4, 1)
plt.imshow(original_image)
plt.title("Original Colorful Image")

plt.subplot(1, 4, 2)
plt.imshow(grayscale_image, cmap="gray")
plt.title("Grayscale Image")

plt.subplot(1, 4, 3)
plt.imshow(np.log1p(np.abs(real)), cmap="gray")
plt.title("FFT Magnitude (Python)")

plt.subplot(1, 4, 4)
plt.imshow(np.angle(real), cmap="gray")
plt.title("FFT Phase (Python)")

plt.show()
