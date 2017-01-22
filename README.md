# IgorImageTools
Image processing tools for IgorPro

### ColocAnalysis
A workflow to analyse colocalisation in IgorPro (IP7 only). Currently, the workflow is to run from the Macros menu. User selects the TIFFs for channel 1 and 2, then the output from [ComDet](https://github.com/ekatrukha/ComDet) (channel 1 and channel 2) and then specify an output directory. A movie of pixel intensities for the two channels is generated (as a mov or a directory of TIFFs).

*TO DO:* Some work is required

1. to pull out additional data.
2. to add sliders to look at data interactively in Igor

### Montages.ipf

collection of procedures to arrange a TIFF stack into an m x n array, with specified grouting. *IP7 only*. Works on 8-bit images only.