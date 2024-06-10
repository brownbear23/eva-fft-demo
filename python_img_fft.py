import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
import cv2, os


# image for input
def perform_fft(img):
    # computes fast fourier transform
    fft_result = np.fft.fft2(img)
    # real and imaginary components after performing fft
    real_part = np.real(fft_result)
    imag_part = np.imag(fft_result)
    # output
    return real_part, imag_part


# define paths
script_dir = os.path.dirname(os.path.abspath(__file__))
img_folder = "images"
img = "sample_img.jpg"
imgFolder = os.path.join(script_dir, img_folder)
inputImg = os.path.join(imgFolder, img)

# load original image
original_img = cv2.imread(inputImg)
if original_img is None:
    raise FileNotFoundError(f"Image at path {inputImg} not found")

# convert the image to grayscale for FFT processing
grayscale_image = cv2.cvtColor(original_img, cv2.COLOR_BGR2GRAY)

# perform FFT
real, imag = perform_fft(grayscale_image)
magnitude = np.log1p(np.abs(real))
phase = np.angle(real)

# display the original colorful image and transformed images
plt.figure(figsize=(16, 8))

plt.subplot(1, 3, 1)
# convert BGR to RGB for correct color display
plt.imshow(cv2.cvtColor(original_img, cv2.COLOR_BGR2RGB))
plt.title("Original Image")

plt.subplot(1, 3, 2)
plt.imshow(magnitude, cmap="gray")
plt.title("FFT Magnitude (Python)")

plt.subplot(1, 3, 3)
plt.imshow(phase, cmap="gray")
plt.title("FFT Phase (Python)")

plt.show()
