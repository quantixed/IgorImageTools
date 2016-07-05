#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function MontageMaker(nRows,nColumns,grout)
	Variable nRows,nColumns,grout
	
	Wave/Z image
	if(!WaveExists(image))
		return 0
	endif
	
	Variable nLayers = dimsize(image,2)
	Variable xSize = dimsize(image,1)
	Variable ySize = dimsize(image,0)
	Variable x1 = (xSize * nColumns) + (grout * (nColumns-1))
	Variable y1 = (ySize * nRows) + (grout * (nRows-1))
	Make/B/U/O/N=(x1,y1) newMontage=255
	
	Variable xPos=0,ypos=0
	Variable i
	
	for(i = 0; i < nLayers; i += 1)
		Duplicate/O/FREE/RMD=[][][i,i] image, subImage
		xPos = mod(i,nColumns)
		yPos = floor(i/nColumns)
		x1 = (xSize * xPos) + (grout * xPos)
		y1 = (ySize * yPos) + (grout * yPos)
		ImageTransform /INSI=subImage/INSX=(x1)/INSY=(y1) InsertImage newMontage
	endfor
	ImageSave/T="tiff" newMontage
End