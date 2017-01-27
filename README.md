# IgorImageTools
Image processing tools for IgorPro

### ColocAnalysis
A workflow to analyse colocalisation in IgorPro (IP7 only). Select Coloc Analysis... from the Macros menu. Then in the panel selects the TIFFs for channel 1 and 2, then (optionally) the output from [ComDet](https://github.com/ekatrukha/ComDet) (channel 1 and/or channel 2) and then specify an output directory. The result is a move called finalTIFF which shows:

- each channel in grayscale along with a red/green merge
- plots of pixel intensities from each channel
	- ch1 spots
	- ch2 spots
	- overlap between ch1 ch2
- a line plot to show the number of spots detected for each channel and the number of spots which coincide.

### Montages.ipf

collection of procedures to arrange a TIFF stack into an m x n array, with specified grouting. *IP7 only*. Works on 8-bit images only.