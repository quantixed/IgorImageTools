#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
// These procedures will take an image and make a new image with the pixel values overlaid.
// It is intended for small grayscale images. Untested for other applications

///	@param	m0	2D matrix (image) to be represented as pixel values
Function PixelValueDemo(m0)
	Wave m0
	Variable matsize = numpnts(m0)
	Duplicate/O m0, pixelValImg,pixelValWave
	KillWindow/Z pixelVal0
	NewImage/N=pixelVal0 pixelValImg
	pixelValImg = 255
	KillWindow/Z pixelVal1
	NewImage/N=pixelVal1 m0
	String m0Name = NameOfWave(m0)
	
	String textName,labelValStr
	Redimension/N=(matsize) pixelValWave
	Variable offset = x2pnt(m0, 0)
	
	Variable i

	for(i = 0; i < matsize; i += 1)
		textName = "text" + num2str(i)
		labelValStr = num2str(pixelValWave[i])
		Tag/C/N=$textName/F=0/B=1/X=0.00/Y=0.00/L=0/W=pixelVal0 PixelValImg, i-offset, labelValStr
		if(pixelValWave[i] > (wavemin(m0) + round(0.5 * (wavemax(m0) - wavemin(m0)))))
			Tag/C/N=$textName/F=0/B=1/X=0.00/Y=0.00/L=0/W=pixelVal1 $m0Name, i-offset, labelValStr
		else
			Tag/C/N=$textName/F=0/B=1/X=0.00/Y=0.00/L=0/W=pixelVal1/G=(65535,65535,65535) $m0Name, i-offset, labelValStr
		endif
	endfor
End

///	@param	m0	2D matrix (image) to be represented as pixel values
Function SavePixelValue(m0)
	Wave m0
	Variable matsize = numpnts(m0)
	Duplicate/O m0, pixelValImg,pixelValWave
	String ImgWinName = "px_" + NameOfWave(m0)
	String ValWinName = "vl_" + NameOfWave(m0)
	KillWindow/Z $ImgWinName
	NewImage/N=$ImgWinName/S=0 pixelValImg
	pixelValImg = 255
	KillWindow/Z $ValWinName
	NewImage/N=$ValWinName/S=0 m0
	String m0Name = NameOfWave(m0)
	
	String textName,labelValStr
	Redimension/N=(matsize) pixelValWave
	Variable offset = x2pnt(m0, 0)
	
	Variable i

	for(i = 0; i < matsize; i += 1)
		textName = "text" + num2str(i)
		labelValStr = num2str(pixelValWave[i])
		Tag/C/N=$textName/F=0/B=1/X=0.00/Y=0.00/L=0/W=$ImgWinName PixelValImg, i-offset, labelValStr
		if(pixelValWave[i] > (wavemin(m0) + round(0.5 * (wavemax(m0) - wavemin(m0)))))
			Tag/C/N=$textName/F=0/B=1/X=0.00/Y=0.00/L=0/W=$ValWinName $m0Name, i-offset, labelValStr
		else
			Tag/C/N=$textName/F=0/B=1/X=0.00/Y=0.00/L=0/W=$ValWinName/G=(65535,65535,65535) $m0Name, i-offset, labelValStr
		endif
	endfor
	String fileName = NameOfWave(m0) + ".pdf"
	SavePICT/E=-2 as fileName
End