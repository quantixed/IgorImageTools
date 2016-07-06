#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
// Menu item for easy execution
Menu "Macros"
	"Make Montage...",  MontageSetUp()
End

//Triggers load of TIFF stack for making montage
Function MontageSetUp()
	ImageLoad/O/T=tiff/S=0/C=-1/LR3D/N=masterImage ""
	WAVE/Z masterImage
	String imagePath = S_path
	
	Variable rr,cc,gg
	Prompt rr, "Rows"
	Prompt cc, "Columns"
	Prompt gg, "Grout (px)"
	DoPrompt "Montage details", rr,cc,gg
	MontageMaker(masterImage,rr,cc,gg, imagePath)
End

//This procedure works in Igor 7.0 and later
////	@param	masterImage	TIFF stack to be split
////	@param	nRows			Montage will be nRows tall
////	@param	nColumns		Montage will be nColumns wide
////	@param	grout			Pixels of grouting between panels (no border)
Function MontageMaker(masterImage,nRows,nColumns,grout,imagePath)
	Wave masterImage
	Variable nRows,nColumns,grout
	String imagePath
	
	if(!WaveExists(masterImage))
		Print "Image does not exist"
		return 0
	endif
	
	Variable nLayers = dimsize(masterImage,2)
	Variable xSize = dimsize(masterImage,1)
	Variable ySize = dimsize(masterImage,0)
	Variable x1 = (xSize * nColumns) + (grout * (nColumns-1))
	Variable y1 = (ySize * nRows) + (grout * (nRows-1))
	Make/B/U/O/N=(x1,y1) newMontage=255
	
	Variable xPos=0,ypos=0
	Variable i
	
	for(i = 0; i < nLayers; i += 1)
		Duplicate/O/FREE/RMD=[][][i,i] masterImage, subImage
		xPos = mod(i,nColumns)
		yPos = floor(i/nColumns)
		x1 = (xSize * xPos) + (grout * xPos)
		y1 = (ySize * yPos) + (grout * yPos)
		ImageTransform /INSI=subImage/INSX=(x1)/INSY=(y1) InsertImage newMontage
	endfor
	KillWindow/Z result
	NewImage/N=result newMontage
	ImageSave/P=imagePath/T="tiff" newMontage
End