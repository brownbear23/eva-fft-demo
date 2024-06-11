# FFT Documentation
There is discrepancy between python's np.fft.fft2 function and swift's performFFT function. Same image and array of numbers with width and height are used for both functions' inputs and outputs are displayed individually below. 


## Python FFT function
np.fft.fft2 function is performed on the left image and output is shown on middle and right images which are fast fourier transform's magnitude and phase.

![Python output](outputs/python_output.png)

np.fft.fft2 function is performed in python
Input:
   1    2    3    4    5    6    7    8    9   10
  11   12   13   14   15   16   17   18   19   20
  21   22   23   24   25   26   27   28   29   30
  31   32   33   34   35   36   37   38   39   40
  41   42   43   44   45   46   47   48   49   50
  51   52   53   54   55   56   57   58   59   60
  61   62   63   64   65   66   67   68   69   70
  71   72   73   74   75   76   77   78   79   80
  81   82   83   84   85   86   87   88   89   90
  91   92   93   94   95   96   97   98   99  100.

Output-Real Part:
  5050.00    -50.00    -50.00    -50.00    -50.00    -50.00    -50.00    -50.00    -50.00    -50.00
  -500.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00     -0.00      0.00     -0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00     -0.00      0.00     -0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
  -500.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

Output-Imaginary Part:
     0.00    153.88     68.82     36.33     16.25     -0.00    -16.25    -36.33    -68.82   -153.88
  1538.84      0.00      0.00      0.00     -0.00      0.00     -0.00      0.00      0.00      0.00
   688.19      0.00      0.00      0.00     -0.00      0.00     -0.00      0.00      0.00     -0.00
   363.27      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
   162.46      0.00      0.00      0.00     -0.00      0.00     -0.00      0.00     -0.00     -0.00
    -0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
  -162.46      0.00      0.00      0.00      0.00      0.00      0.00      0.00     -0.00     -0.00
  -363.27      0.00      0.00      0.00     -0.00      0.00     -0.00      0.00      0.00      0.00
  -688.19      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00     -0.00
 -1538.84      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00


## Swift FFT function
performFFT function is performed on the left image and output is shown on middle and right images which are fast fourier transform's magnitude and phase.

![Swift output](outputs/Swift_output.png)

performFFT function is performed in swift



