#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Load in two images
// Create M_ImageThesh for both, i.e. duplicate and give unique names
// Feed these into AnimatingLogos function

Function AnimatingLogos(m0,m2)
	Wave m0,m2
	
	ConvertMatrixToXYZTriplet(m0,"tripletA")
	Wave tripletA
	Make/O/N=(DimSize(tripletA,0)) xA,yA
	xA[] = (tripletA[p][2] == 0) ? tripletA[p][0] : NaN
	yA[] = (tripletA[p][2] == 0) ? tripletA[p][1] : NaN
	WaveTransform zapnans xA
	WaveTransform zapnans yA
	Concatenate/O/KILL {xA,yA}, matA
	
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
	
	AnimateThis(matA,matB,16,maxW,maxH)
	KillWaves/Z matA,matB
End

// Taken from MatrixToXYZ.ipf
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

Function AnimateThis(m0,m2,frames,width,height)
	Wave m0,m2 // image 1 and image 2 as xy coords
	Variable frames,width,height
	
	Variable minRow = floor(0.5 * (min(DimSize(m0,0),DimSize(m2,0))))
	
	// subsample minRow from both coord sets
//	Wave s0 = Subsample(m0,minRow)
//	Wave s2 = Subsample(m2,minRow)
	StatsSample/MC/N=(minRow) m0
	WAVE/Z M_Sampled
	Duplicate/O M_Sampled, s0
	StatsSample/MC/N=(minRow) m2
	Duplicate/O M_Sampled, s2
	// randomise to get s1 and s3
	Wave s1 = RandomiseMat(s0,width,height)
	Wave s3 = RandomiseMat(s2,width,height)
	
	Variable nRow = DimSize(s0,0)
	Make/O/N=(nRow,2,frames)/FREE tempMat0,tempMat1,tempMat2,tempMat3
	
	Variable i
	
	for(i = 0; i < nRow; i += 1)
		tempMat0[i][0][] = s0[i][0] + ((s1[i][0] - s0[i][0]) / frames) * r
		tempMat0[i][1][] = s0[i][1] + ((s1[i][1] - s0[i][1]) / frames) * r
		tempMat1[i][0][] = s1[i][0] + ((s2[i][0] - s1[i][0]) / frames) * r
		tempMat1[i][1][] = s1[i][1] + ((s2[i][1] - s1[i][1]) / frames) * r
		tempMat2[i][0][] = s2[i][0] + ((s3[i][0] - s2[i][0]) / frames) * r
		tempMat2[i][1][] = s2[i][1] + ((s3[i][1] - s2[i][1]) / frames) * r
		tempMat3[i][0][] = s3[i][0] + ((s0[i][0] - s3[i][0]) / frames) * r
		tempMat3[i][1][] = s3[i][1] + ((s0[i][1] - s3[i][1]) / frames) * r
	endfor
	
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
	ModifyGraph/W=imgWin rgb=(65535,0,0,32768)
	// save first frame
	NewPath/M="Choose output folder"/O/Q/Z outputFolder
	i = 0
	Variable nFrame = DimSize(M_Animate,2)
	String numstr = PadNumber(i,nFrame)
	String imgName = "output_" + numstr + ".png"
	SavePICT/WIN=imgWin/E=-5/RES=300/P=outputFolder as imgName
	
	for(i = 1; i < nFrame; i += 1)
		ReplaceWave/W=imgWin trace=M_Animate, M_Animate[][1][i]
		ReplaceWave/W=imgWin /X trace=M_Animate, M_Animate[][0][i]
		numstr = PadNumber(i,nFrame)
		imgName = "output_" + numstr + ".png"
		SavePICT/WIN=imgWin/E=-5/RES=300/P=outputFolder as imgName
	endfor
	KillWindow/Z imgWin
	KillWaves/Z M_Animate,s0,s1,s2,s3,M_Sampled
End

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

Function/S PadNumber(num,maxnum)
	Variable num,maxnum
	
	Variable pad = strlen(num2str(maxnum))
	
	String s = num2str(num)
	
	do
		s = "0" + s
	while(strlen(s) < pad + 1)

	return s
End