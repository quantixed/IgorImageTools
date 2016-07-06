#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
// Menu item for easy execution
Menu "Macros"
	"Make Montage...",  MontageSetUp()
End

//Triggers load of TIFF stack for making montage
Function MontageSetUp()
	ImageLoad/O/Q/T=tiff/S=0/C=-1/LR3D/N=masterImage ""
	WAVE/Z masterImage
	if(!WaveExists(masterImage))
		Abort "Image load error"
	endif
	Variable nSlices = V_numImages
	if(nSlices < 2)
		Abort "Must have two or more slices"
	endif
	
	Variable rr=1,cc=1,gg=0
	String usrmsg = "        (note that your stack has " + num2str(nSlices) + " slices)"
	Prompt rr, "Rows:" + usrmsg
	Prompt cc, "Columns:"
	Prompt gg, "Grout (px):"
	DoPrompt "Montage details", rr,cc,gg
	if(V_Flag == 1)
		Abort "The user pressed Cancel"
	endif
	
	if(rr == 0 || cc == 0)
		Print "Rows or columns must be > 0"
		return -1
	elseif((rr * cc) < nSlices)
		Print "Montage shows first", (rr * cc), "slices only."
	elseif((rr * cc) > nSlices)
		Print "Montage has", ((rr * cc) - nSlices), "blanks."
	endif 
	
	MontageMaker(masterImage,rr,cc,gg,S_path)
End

//This procedure works in Igor 7.0 and later
////	@param	masterImage	TIFF stack to be split
////	@param	nRows			Montage will be nRows tall
////	@param	nColumns		Montage will be nColumns wide
////	@param	grout			Pixels of grouting between panels (no border)
////	@param	pathString	String containing path to original TIFF stack
Function MontageMaker(masterImage,nRows,nColumns,grout,pathString)
	Wave masterImage
	Variable nRows,nColumns,grout
	String pathString
	NewPath/O/Q imagePath, pathString
	
	if(!WaveExists(masterImage))
		Print "Image does not exist"
		return 0
	endif
	
	Variable tSize = dimsize(masterImage,3)
	Variable zSize = dimsize(masterImage,2)
	Variable xSize = dimsize(masterImage,1)
	Variable ySize = dimsize(masterImage,0)
	Variable x1 = (xSize * nColumns) + (grout * (nColumns-1))
	Variable y1 = (ySize * nRows) + (grout * (nRows-1))
	Variable nLayers
	if(tSize == 0)
		// case where there are no chunks assume BW stack
		nLayers = zSize
		Make/B/U/O/N=(x1,y1) newMontage = 255
	else
		// if there are chunks then assume RGB stack
		nLayers = tSize
		Make/B/U/O/N=(x1,y1,zSize) newMontage = 255
	endif
	
	Variable xPos=0,ypos=0
	Variable i,j
	
	for(i = 0; i < nLayers; i += 1)
		xPos = mod(i,nColumns)
		yPos = floor(i/nColumns)
		x1 = (xSize * xPos) + (grout * xPos)
		y1 = (ySize * yPos) + (grout * yPos)
		if(tSize == 0)
			Duplicate/O/FREE/RMD=[][][i,i] masterImage, subImage
			ImageTransform /INSI=subImage/INSX=(x1)/INSY=(y1) InsertImage newMontage
		else
			for(j = 0; j < 3; j += 1)
				Duplicate/O/FREE/RMD=[][][j][i,i] masterImage, subImage
				ImageTransform/P=(j)/INSI=subImage/INSX=(x1)/INSY=(y1) InsertImage newMontage
			endfor
		endif
	endfor
	KillWindow/Z result
	NewImage/N=result newMontage
	KillWaves masterImage
	ImageSave/P=imagePath/T="tiff" newMontage
End