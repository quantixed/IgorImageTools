#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Load in two images
// Create M_ImageThesh for both, i.e. duplicate and give unique names
// Feed these into AnimatingLogos function
// then use ffmpeg to make the movie, example:
// ffmpeg -framerate 15 -pattern_type glob -i '*.png' -c:v libx264 -pix_fmt yuv420p -vf scale=480:-2 out.mp4
// ffmpeg -framerate 15 -pattern_type glob -i '*.png' -vf scale=480:-2 colour.gif

///	@param	m0	2D wave of first segmented image
///	@param	m2	2D wave of second segmented image
Function AnimatingLogos(m0,m2)
	Wave m0,m2
	
	// Convert the image to a list of XYZ values (one row per pixel
	ConvertMatrixToXYZTriplet(m0,"tripletA")
	Wave tripletA
	// get rid of zero Z values
	Make/O/N=(DimSize(tripletA,0)) xA,yA
	xA[] = (tripletA[p][2] == 0) ? tripletA[p][0] : NaN
	yA[] = (tripletA[p][2] == 0) ? tripletA[p][1] : NaN
	WaveTransform zapnans xA
	WaveTransform zapnans yA
	Concatenate/O/KILL {xA,yA}, matA
	// same operation on the second image
	ConvertMatrixToXYZTriplet(m2,"tripletB")
	Wave tripletB
	Make/O/N=(DimSize(tripletB,0)) xB,yB
	xB[] = (tripletB[p][2] == 0) ? tripletB[p][0] : NaN
	yB[] = (tripletB[p][2] == 0) ? tripletB[p][1] : NaN
	WaveTransform zapnans xB
	WaveTransform zapnans yB
	Concatenate/O/KILL {xB,yB}, matB
	KillWaves/Z tripletA,tripletB
	
	Variable maxW, maxH
	// centralise the coord sets
	if(DimSize(m0,0) > DimSize(m2,0))
		matB[][0] += (DimSize(m0,0) / 2) - (DimSize(m2,0) / 2)
		maxW = DimSize(m0,0)
	elseif(DimSize(m0,0) < DimSize(m2,0))
		matA[][0] += (DimSize(m2,0) / 2) - (DimSize(m0,0) / 2)
		maxW = DimSize(m2,0)
	else // if they are equal
		maxW = DimSize(m0,0)
	endif
	
	if(DimSize(m0,1) > DimSize(m2,1))
		matB[][1] += (DimSize(m0,1) / 2) - (DimSize(m2,1) / 2)
		maxH = DimSize(m0,1)
	elseif(DimSize(m0,1) < DimSize(m2,1))
		matA[][1] += (DimSize(m2,1) / 2) - (DimSize(m0,1) / 2)
		maxH = DimSize(m2,1)
	else
		maxH = DimSize(m0,1)
	endif
	
	// animate the transitions between the two images
	AnimateThis(matA,matB,16,maxW,maxH,0.1)
	KillWaves/Z matA,matB
End

// Taken from MatrixToXYZ.ipf
///	@param	matrixWave	2D imagewave
///	@param	outputName	string to label the output triplet wave
STATIC Function ConvertMatrixToXYZTriplet(matrixWave, outputName)
	Wave matrixWave
	String outputName	
	
	Variable dimx = DimSize(matrixWave,0)
	Variable dimy = DimSize(matrixWave,1)
	Variable rows = dimx*dimy
	Make/O/N=(rows,3) $outputName
	WAVE TripletWave= $outputName
	
	Variable xStart,xDelta
	Variable yStart,yDelta
	
	xStart = DimOffset(matrixWave,0)
	yStart = DimOffset(matrixWave,1)
	xDelta = DimDelta(matrixWave,0)
	yDelta = DimDelta(matrixWave,1)
	
	Variable i, j, count=0
	Variable xVal, yVal
	for(i = 0; i < dimy; i += 1)		// i is y (column)
		yVal = yStart + i * yDelta
		for(j = 0; j < dimx; j += 1)	// j is x (row)
			xVal = xStart + j * xDelta
			TripletWave[count][0] = xVal
			TripletWave[count][1] = yVal
			TripletWave[count][2] = matrixWave[j][i]	// [row][col]
			count += 1
		endfor
	endfor
End

// this is the main function to animate the images
// we will go from 1st image to random to second image to random to first image (so looping is possible)
///	@param	m0	2D wave of first segmented image (XY coords of segmented pixels)
///	@param	m2	2D wave of second segmented image (XY coords of segmented pixels)
///	@param	frames	number of frames for each transition
///	@param	width	width of the output (currently this is the largest width of two images)
///	@param	height	height of the output (currently this is the largest height of two images)
///	@param	quality	this variable from (0,1] sets the number of pixels. 1 is all pixels (least of inputs), 0.5 is half
Function AnimateThis(m0,m2,frames,width,height,quality)
	Wave m0,m2 // image 1 and image 2 as xy coords
	Variable frames,width,height,quality
	
	quality = limit(quality,0.0000001,1)
	Variable minRow = floor(quality * (min(DimSize(m0,0),DimSize(m2,0))))
	
	// subsample minRow from both coord sets
	StatsSample/MC/N=(minRow) m0
	WAVE/Z M_Sampled
	Duplicate/O M_Sampled, s0
	StatsSample/MC/N=(minRow) m2
	Duplicate/O M_Sampled, s2
	// randomise to get s1 and s3 - these are the transition positions
	Wave s1 = RandomiseMat(s0,width,height)
	Wave s3 = RandomiseMat(s2,width,height)
	// we will hold the data in temporary matrices that are XY coord sets with layers as frames
	Variable nRow = DimSize(s0,0)
	Make/O/N=(nRow,2,frames)/FREE tempMat0,tempMat1,tempMat2,tempMat3
	// tempMat0 goes from s0 to the state before s1, tempmat1 goes from s1 to the frame before s2 and so on
	Variable i
	
	for(i = 0; i < nRow; i += 1)
		// interpolate pixel positions to transit from one XY set to the other
		tempMat0[i][0][] = s0[i][0] + ((s1[i][0] - s0[i][0]) / frames) * r
		tempMat0[i][1][] = s0[i][1] + ((s1[i][1] - s0[i][1]) / frames) * r
		tempMat1[i][0][] = s1[i][0] + ((s2[i][0] - s1[i][0]) / frames) * r
		tempMat1[i][1][] = s1[i][1] + ((s2[i][1] - s1[i][1]) / frames) * r
		tempMat2[i][0][] = s2[i][0] + ((s3[i][0] - s2[i][0]) / frames) * r
		tempMat2[i][1][] = s2[i][1] + ((s3[i][1] - s2[i][1]) / frames) * r
		tempMat3[i][0][] = s3[i][0] + ((s0[i][0] - s3[i][0]) / frames) * r
		tempMat3[i][1][] = s3[i][1] + ((s0[i][1] - s3[i][1]) / frames) * r
	endfor
	
	// Noe in code review: I think the addition of s1 and s2 etc may be unnecessary
	Concatenate/O/NP=2 {tempMat0,s1,tempMat1,s2,tempMat2,s3,tempMat3,s0}, M_Animate
	KillWindow/Z imgWin
	// make window
	Display/N=imgWin/W=(35,45,500,500)/HIDE=1 M_Animate[][1][0] vs M_Animate[][0][0]
	// format graph window
	SetAxis/W=imgWin left height,0
	SetAxis/W=imgWin bottom 0,width
	ModifyGraph/W=imgWin width={Plan,1,bottom,left}
	ModifyGraph/W=imgWin noLabel=2,axThick=0,standoff=0
	ModifyGraph/W=imgWin margin=1
	ModifyGraph/W=imgWin mode=2
//		ModifyGraph/W=imgWin rgb=(65535,0,0,32768)
		ModifyGraph/W=imgWin rgb=(203 * 257,32 * 257,39 * 257,32768)
//		Make/O/N=(nRow) colorIndexW = p
//		ModifyGraph/W=imgWin zcolor(M_Animate)={colorIndexW,*,*,Rainbow}

	// save first frame
	NewPath/M="Choose output folder"/O/Q/Z outputFolder
	i = 0
	Variable nFrame = DimSize(M_Animate,2)
	String imgName
	sprintf imgName, "output%04d.png", i
	SavePICT/WIN=imgWin/E=-5/RES=300/P=outputFolder as imgName
	
	for(i = 1; i < nFrame; i += 1)
		ReplaceWave/W=imgWin trace=M_Animate, M_Animate[][1][i]
		ReplaceWave/W=imgWin /X trace=M_Animate, M_Animate[][0][i]
		sprintf imgName, "output%04d.png", i // limit is 9999 images
		SavePICT/WIN=imgWin/E=-5/RES=300/P=outputFolder as imgName
	endfor
	KillWindow/Z imgWin
	KillWaves/Z M_Animate,s0,s1,s2,s3,M_Sampled,colorIndexW
End

///	@param	m0	2D wave of XY coords
///	@param	ww	max width of randomised coord set (width can be from 0 to ww)
///	@param	hh	max width of randomised coord set (height can be from 0 to hh)
Function/WAVE RandomiseMat(m0,ww,hh)
	Wave m0 // xy coords
	Variable ww,hh
	
	SplitWave/NAME="xTemp;yTemp;" m0
	WAVE/Z xTemp,yTemp
	Variable nRow = numpnts(xTemp)
	Variable midW = floor(ww / 2)
	Variable midH = floor(hh / 2)
	// randomise
	xTemp[] = midW + enoise(midW)
	yTemp[] = midH + enoise(midH)
	// put back into 2 column wave
	String mName = NameOfWave(m0) + "_XYrand"
	Concatenate/O/KILL {xTemp,yTemp}, $mName
	Wave m1 = $mName
	
	return m1
End