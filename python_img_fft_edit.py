import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
import cv2, os


# array of float values of pixel values and image's width and height for input
def perform_fft(img):
    # computes fast fourier transform
    fft_result = np.fft.fft2(img)
    # real and imaginary components after performing fft
    real_part = np.real(fft_result)
    imag_part = np.imag(fft_result)
    # output
    return real_part, imag_part


def print_values(label, array):
    print(f"{label}:")
    for row in array:
        print(" ".join(f"{val:.2f}" for val in row))
    print("")


# Define paths
script_dir = os.path.dirname(os.path.abspath(__file__))
img_folder = 'images'
img = 'sample_img.jpg'
imgFolder = os.path.join(script_dir, img_folder)
inputImg = os.path.join(imgFolder, img)

# Load original image
original_img = cv2.imread(inputImg)
if original_img is None:
    raise FileNotFoundError(f"Image at path {inputImg} not found")


# # Convert the image to grayscale for FFT processing
# grayscale_image = original_img.convert("L")
#
# image_pixels = np.asarray(grayscale_image).flatten()
# width, height = grayscale_image.size

# Perform FFT
real, imag = perform_fft(original_img)
# print_values("Real Part (Python)", real)

# Display the original colorful image, grayscale image, and transformed images
plt.figure(figsize=(16, 8))

plt.subplot(1, 4, 1)
# Convert BGR to RGB for correct color display
plt.imshow(cv2.cvtColor(original_img, cv2.COLOR_BGR2RGB))
plt.title("Original Image")

plt.subplot(1, 4, 2)
plt.imshow(real)
plt.title("FFT Image")


# plt.subplot(1, 4, 2)
# plt.imshow(grayscale_image, cmap="gray")
# plt.title("Grayscale Image")
#
# plt.subplot(1, 4, 3)
# plt.imshow(np.log1p(np.abs(real)), cmap="gray")
# plt.title("FFT Magnitude (Python)")
#
# plt.subplot(1, 4, 4)
# plt.imshow(np.angle(real), cmap="gray")
# plt.title("FFT Phase (Python)")

plt.show()
