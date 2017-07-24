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

A randomised version is also used for comparison where no two timepoints match up to test for chance colocalisation.

There is a fast version of this code called `FastColocAnalysis` which just makes the line plots and saves them as PDF.

### Montages.ipf

Collection of procedures to arrange a TIFF stack into an m x n array, with specified grouting. *IP7 only*. Works on 8-bit images only.

### CorrectDrift.ipf

Correct for bleach or other drift using this simple UI. Choose between a quick and dirty method (using a line between two points), line fit to baseline or exponential fit to data to subtract from a copy of your wave.