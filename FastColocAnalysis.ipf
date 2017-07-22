#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Fast Coloc Analysis...",  myIO_Panel()
End

Function myIO_Panel()
	// make global text wave to store paths and output folder
	Make/T/O/N=5 PathWave
	// make global numeric wave for other variables
	Make/O/N=8 gVarWave={0,0,1,1,5,0,1,1}
	DoWindow/K FilePicker
	NewPanel/N=FilePicker/K=1/W=(81,73,774,298)
	Button SelectFile1,pos={12,10},size={140,20},proc=ButtonProc,title="Select Ch1 TIFF"
	Button SelectFile2,pos={12,41},size={140,20},proc=ButtonProc,title="Select Ch2 TIFF"
	Button SelectFile3,pos={12,72},size={140,20},proc=ButtonProc,title="Select Ch1 ComDet"
	Button SelectFile4,pos={12,103},size={140,20},proc=ButtonProc,title="Select Ch2 ComDet"
	Button Output,pos={12,134},size={140,20},proc=ButtonProc,title="Select Output Folder"
	SetVariable File1,pos={168,13},size={500,14},value= PathWave[0]
	SetVariable File2,pos={168,44},size={500,14},value= PathWave[1]
	SetVariable File3,pos={168,75},size={500,14},value= PathWave[2]
	SetVariable File4,pos={168,106},size={500,14},value= PathWave[3]
	SetVariable File5,pos={168,137},size={500,14},value= PathWave[4]
	
//	CheckBox normCheck,pos={12,161},size={69,14},title="Normalise channels",value= gVarWave[2]
//	CheckBox tiffCheck,pos={12,181},size={69,14},title="Make Coloc Tiffs",value= gVarWave[3]
//	CheckBox soloCheck,pos={12,201},size={69,14},title="Do all plots?",value= gVarWave[6]
	CheckBox randCheck,pos={168,201},size={69,14},title="Randomise?",value= gVarWave[7]
	
//	SetVariable bg0SetVar,pos={168,161},size={166,15},title="Background Ch1:",format="%g",value= gVarWave[0]
//	SetVariable bg1SetVar,pos={168,181},size={166,15},title="Background Ch2:",format="%g",value= gVarWave[1]
	
	SetVariable timeSetVar,pos={348,161},size={126,15},title="Sec per frame:",format="%g",value= gVarWave[4]
	SetVariable lenSetVar,pos={348,181},size={126,15},title="Last frame (0 for all)",format="%g",value= gVarWave[5]
	
	Button DoIt,pos={564,181},size={100,20},proc=ButtonProc,title="Do It"
End
 
// define buttons
Function ButtonProc(ctrlName) : ButtonControl
	String ctrlName
 
		Wave/T PathWave
		Wave gVarWave
		Variable refnum
 
		strswitch(ctrlName)
 
			case "SelectFile1"	:
				// get File Paths
				Open/D/R/F="*.tif"/M="Select Ch1 Image" refNum
				if (strlen(S_FileName) == 0) // user cancelled or some error occured
					return -1
				endif
				PathWave[0] = S_fileName
				PathWave[2] = ReplaceString(".tif",S_fileName,".xls")
				break
 
			case "SelectFile2"	:
				// get File Paths
				Open/D/R/F="*.tif"/M="Select Ch2 Image" refNum
				if (strlen(S_FileName) == 0) 
					return -1
				endif
				PathWave[1] = S_fileName
				PathWave[3] = ReplaceString(".tif",S_fileName,".xls")
				break
			
			case "SelectFile3"	:
				// get File Paths
				Open/D/R/F="*.xls"/M="Select Ch1 ComDet Output" refNum
				if (strlen(S_FileName) == 0) 
					return -1
				endif
				PathWave[2] = S_fileName
				break
			
			case "SelectFile4"	:
				// get File Paths
				Open/D/R/F="*.xls"/M="Select Ch2 ComDetOutput" refNum
				if (strlen(S_FileName) == 0) 
					return -1
				endif
				PathWave[3] = S_fileName
				break
 
			case "Output"	:
				// set outputfolder
				NewPath/Q/O OutputPath
				PathInfo OutputPath
				PathWave[4] = S_Path
				break
 
			case "DoIt" :
				// run your loadwave commands and other functions
				ControlInfo/W=FilePicker normCheck
				gVarWave[2] = V_Value
				ControlInfo/W=FilePicker tiffCheck
				gVarWave[3] = V_Value
				ControlInfo/W=FilePicker soloCheck
				gVarWave[6] = V_Value
				ControlInfo/W=FilePicker randCheck
				gVarWave[7] = V_Value
				LoadAllFiles(PathWave)
				break
 
		EndSwitch
End
 
Function LoadAllFiles(path)
	Wave/T path
	Variable timer = startmstimer
	// Load channel 1 and 2 tiff
	ImageLoad/T=tiff/N=ch1tiff/O/S=0/C=-1 path[0]
	ImageLoad/T=tiff/N=ch2tiff/O/S=0/C=-1 path[1]
	Variable nFrames,nCh=0
	
	// Without ComDet Files, go straight to analysis
	if(strlen(path[2]) != 0 || strlen(path[3]) != 0)
		// Load ComDet Outputs
		if(strlen(path[2]) != 0)
			LoadWave/Q/A/J/D/W/O/L={0,1,0,1,3} path[2]
			Concatenate/O/KILL "Abs_Frame;X__px_;Y__px_;", mat1
			nFrames = dimsize(mat1,0)
			Make/O/N=(nFrames, 3) ComDet_1
			ComDet_1 = round(mat1[p][q])
			KillWaves mat1
			nCh +=1 // bit 0
		endif
		if(strlen(path[3]) != 0)
			LoadWave/Q/A/J/D/W/O/L={0,1,0,1,3} path[3]
			Concatenate/O/KILL "Abs_Frame;X__px_;Y__px_;", mat2
			nFrames = dimsize(mat2,0)
			Make/O/N=(nFrames, 3) ComDet_2
			ComDet_2 = round(mat2[p][q])
			KillWaves mat2
			nCh +=2 // bit 1
		endif
		Make2ChMasks(nCh)
	else
		Print "No ComDet files!"
	endif
	Print "LoadAllFiles takes"
	printf "%g\r", stopmstimer(timer)/1e6
	SaveExperiment/P=outputFolder as "ComDetPlots.pxp"
end

/// @param	nCh	bit parameter. Tells function which ComDet files were loaded
Function Make2ChMasks(nCh)
	Variable nCh
	
	// Check images for compatability
	WAVE/Z ch1tiff, ch2tiff
	if(dimsize(ch1tiff,2) != dimsize(ch2tiff,2))
		Abort "Different number of frames in each channel"
	endif
	if((dimsize(ch1tiff,0) != dimsize(ch2tiff,0)) || (dimsize(ch1tiff,1) != dimsize(ch2tiff,1)))
		Abort "Different sizes of frames in each channel"
	endif
	
	WAVE/Z ComDet_1,ComDet_2
	WAVE/Z gVarWave
	
	Variable xx,yy,zz
	Variable nSpots
	
	Variable i
	
	if ((nCh & 2^0) != 0) // bit 0 is set
		// ch1
		nSpots = dimsize(ComDet_1,0)
		Make/O/B/U/N=(dimsize(ch1tiff,0),dimsize(ch1tiff,1),dimsize(ch1tiff,2)) mask_1=0
		for(i = 0; i < nSpots; i += 1)
			xx = ComDet_1[i][1] - 1
			yy = ComDet_1[i][2] - 1
			zz = ComDet_1[i][0] - 1	// ImageJ is 1-based
			MakeThatMask(mask_1,xx,yy,zz)
		endfor
	endif
	if ((nCh & 2^1) != 0) // bit 1 is set
		// ch2
		nSpots = dimsize(ComDet_2,0)
		Make/O/B/U/N=(dimsize(ch1tiff,0),dimsize(ch1tiff,1),dimsize(ch1tiff,2)) mask_2=0
		for(i = 0; i < nSpots; i += 1)
			xx = ComDet_2[i][1] - 1
			yy = ComDet_2[i][2] - 1
			zz = ComDet_2[i][0] - 1 // ImageJ is 1-based
			MakeThatMask(mask_2,xx,yy,zz)
		endfor
	endif
	if ((nCh & 2^0) != 0 && (nCh & 2^1) !=0) // bit 0 AND bit 1 are set
		Make/O/B/U/N=(dimsize(ch1tiff,0),dimsize(ch1tiff,1),dimsize(ch1tiff,2)) mask_3
		// make an AND mask of the two channels in mask_3
		mask_3 = (mask_1[p][q][r] == 1 && mask_2[p][q][r] == 1) ? 1 : 0
		// was randomise checked?
		if (gVarWave[7] == 1)
			Wave randWave = RandomiseAndCheck(mask_2)
			// make a deep layer 3D wave (beam)
			Redimension/N=(1,1,dimsize(ch1tiff,2)) randWave
			// mask_5 will be mask_2 randomised, mask_4 will hold AND result
			Make/O/B/U/N=(dimsize(ch1tiff,0),dimsize(ch1tiff,1),dimsize(ch1tiff,2)) mask_4,mask_5
			mask_5 = mask_2[p][q][randWave[0][0][r]]
			// make an AND mask of the two channels in mask_5
			mask_4 = (mask_1[p][q][r] == 1 && mask_5[p][q][r] == 1) ? 1 : 0
			// print if there is likely to be an error
			if(gVarWave[5] > 0 && gVarWave[5] < 10)
				print "Too few frames for randomisation."
			endif
		endif
	endif
	
	KillWaves/Z ch1Tiff,ch2Tiff
	// now call next function
	MakeMaskedImagesAndAnalyse(nCh)
End

///	@param	m0		2D wave. matrix to work on
///	@param	xPos	xPosition from ComDet (rounded) in 0-based
///	@param	yPos	yPosition from ComDet (rounded) in 0-based
///	@param	zPos	zPosition from ComDet (rounded) in 0-based
Function MakeThatMask(m0,xPos,yPos,zPos)
	Wave m0
	Variable xPos,yPos,zPos
	Variable i,j
	
	for(i = 0; i < 3; i += 1)
		for(j = 0; j < 3; j += 1)
			m0[(i-1)+xPos][(j-1)+yPos][zPos] = 1
		endfor
	endfor
End

// Running this depends on Make2ChMasks()
/// @param	nCh	bit parameter. Tells function which ComDet files were loaded
Function MakeMaskedImagesAndAnalyse(nCh)
	Variable nCh
	
	WAVE/Z gVarWave
	
	String mList = ""
	if ((nCh & 2^0) != 0) // bit 0 is set
		mList += "mask_1;"
	endif
	if ((nCh & 2^1) != 0) // bit 1 is set
		mList += "mask_2;"
	endif
	if ((nCh & 2^0) != 0 && (nCh & 2^1) !=0) // bit 0 AND bit 1 are set
		mList += "mask_3;"
		if (gVarWave[7] == 1)
			mList += "mask_4;"
		endif
	endif
	
	SpotPlotOverTime(mList,9)	// divide pixels by 9 to get plot in units of numbers of spots
End

///	@param	m0		First channel TIFF stack
///	@param	m1		Second channel TIFF stack
///	@param	bg0		First channel background value
///	@param	bg1		Second channel background value
///	@param	frameNum		This function works on one layer/frame at a time
Function Coloc(m0,m1,bg0,bg1,frameNum)
	Wave m0,m1
	Variable bg0,bg1
	Variable frameNum
	
	Variable nXdim = dimsize(m0,0)
	Variable nYdim = dimsize(m0,1)
	Variable nPx = nXdim * nYdim
	
	Make/O/N=(nXdim,nYdim) d0,d1
	
	d0 = (m0[p][q][frameNum] <= bg0 || m1[p][q][frameNum] <= bg1) ? NaN : m0[p][q][frameNum]
	d1 = (m0[p][q][frameNum] <= bg0 || m1[p][q][frameNum] <= bg1) ? NaN : m1[p][q][frameNum]
	
	Redimension/N=(nPx) d0
	Redimension/N=(nPx) d1
	WaveTransform zapnans d0
	WaveTransform zapnans d1
End

// Utility function to look at number of spots per frame from ComDet results
/// @param	mList	stringlist of mask_n waves
/// @param	divVar	use this variable to divide spots, i.e. 1 spot is divVar pixels big
Function SpotPlotOverTime(mList,divVar)
	String mList
	Variable divVar // could be 1 or 9. 1 would give pixel value. 9 will give number of spots
	
	if(strlen(mList) == 0)
		return 0
	endif
	
	Wave gVarWave
	Variable tiffOpt = gVarWave[3]
	Variable secPerFrame = gVarWave[4]
	
	Wave/T PathWave
	String outputFolderName = PathWave[4]
	NewPath/C/O/Q/Z OutputFolder outputFolderName
	
	Variable nMask = ItemsInList(mList)
	String mName = StringFromList(0,mList)
	Wave m0 = $mName
	
	Variable nFrames
	if (gVarWave[5] == 0)
		nFrames = dimsize(m0,2)
	else
		if (gVarWave[5] < dimsize(m0,2))
			nFrames = gVarWave[5]
		else
			nFrames = dimsize(m0,2)
		endif
	endif
	
	Variable maxValL=0,maxValR=0
	String wName
	
	Variable i,j
	
	for(i = 0; i < nMask; i += 1)
		mName = StringFromList(i,mList)
		Wave m0 = $mName
		for(j = 0; j < nFrames; j += 1)
			if(j == 0)
				wName = ReplaceString("mask",mName,"nSpot")
				Make/O/N=(nFrames) $wName
				Wave w0 = $wName
			endif
			Duplicate/O/RMD=[][][j]/FREE m0,m1
			w0[j] = sum(m1)
		endfor
		w0 /= divVar
		SetScale/P x 0,secPerFrame,"", w0
		if(wavemax(w0) > maxValL)
			maxValL = wavemax(w0)
		endif
	endfor
	// declare all possible waves
	WAVE/Z nSpot_1,nSpot_2,nSpot_3,nSpot_4
	// find max value for right axis
	if(nMask > 1)
		maxValR = wavemax(nSpot_3)
	endif
	
	// Set-up window for display make it final first
	DoWindow/K spotPlot
	Display/N=spotPlot/W=(0,0,208,208)
	if(WaveExists(nSpot_1) == 1)
		AppendToGraph/W=spotPlot nSpot_1
		ModifyGraph rgb(nSpot_1)=(227*257,28*257,28*257,32768)
	endif
	if(WaveExists(nSpot_2) == 1)
		AppendToGraph/W=spotPlot nSpot_2
		ModifyGraph rgb(nSpot_2)=(21*257,234*257,21*257,32768)
	endif
	if(WaveExists(nSpot_3) == 1)
		AppendToGraph/W=spotPlot/R nSpot_3
		ModifyGraph rgb(nSpot_3)=(251*257,190*257,39*257,32768)
	endif
	ModifyGraph/W=spotPlot mode=0
	ModifyGraph/W=spotPlot lsize=2
	Label/W=spotPlot left "Number of spots (\\K(58339,7196,7196)ch1 \\K(5397,60138,5397)ch2\\K(0,0,0))"
	Label/W=spotPlot bottom "Time (s)"
	SetAxis/W=spotPlot bottom 0,((nFrames-1) * secPerFrame)
	SetAxis/W=spotPlot left 0,NearestTon(maxValL)
	if(nMask > 1)
		SetAxis/W=spotPlot right 0,NearestTen(maxValR)
		Label/W=spotPlot right "Number of spots (\\K(64507,48830,10023)ch1 " + U+2229 + " ch2\\K(0,0,0))"
	endif
	
	// Display randomised version in a window for reference if option was ticked
	if(gVarWave[7] == 1)
		DoWindow/K randPlot
		Display/N=randPlot/W=(0,0,208,208)
		if(WaveExists(nSpot_3) == 1)
			AppendToGraph/W=randPlot nSpot_3
			ModifyGraph rgb(nSpot_3)=(251*257,190*257,39*257,32768)
		endif
		if(WaveExists(nSpot_4) == 1)
			AppendToGraph/W=randPlot nSpot_4
			ModifyGraph rgb(nSpot_4)=(251*257,190*257,39*257,32768 / 2)
		endif
		ModifyGraph/W=randPlot mode=0
		ModifyGraph/W=randPlot lsize=2
		Label/W=randPlot left "Number of spots (\\K(58339,7196,7196)ch1 \\K(5397,60138,5397)ch2\\K(0,0,0))"
		Label/W=randPlot bottom "Time (s)"
		SetAxis/W=randPlot bottom 0,((nFrames-1) * secPerFrame)
		SetAxis/W=randPlot left 0,NearestTen(maxValR)
		Label/W=randPlot left "Number of spots (\\K(64507,48830,10023)ch1 " + U+2229 + " ch2\\K(0,0,0))"
	endif
	
	// export graphs as eps (will work on Windows as well as on a Mac)
	DoWindow/F spotPlot
	if(defined(WINDOWS) == 1)
		SavePICT/E=-3/P=outputFolder as "spotPlot.eps"
	else
		SavePICT/E=-2/P=outputFolder as "spotPlot.pdf"
	endif
	DoWindow/F randPlot
	if(defined(WINDOWS) == 1)
		SavePICT/E=-3/P=outputFolder as "randPlot.eps"
	else
		SavePICT/E=-2/P=outputFolder as "randPlot.pdf"
	endif
	KillWaves/Z mask_1,mask_2,mask_3,mask_4,mask_5
End

// for axis scaling
///	@param	value				this is the input value that requires rounding up
Static Function NearestTon(value)
	Variable value
	
	value /=100
	Variable newVal = ceil(value)
	newVal *=100
	return newVal
End

// for axis scaling
///	@param	value				this is the input value that requires rounding up
Static Function NearestTen(value)
	Variable value
	
	value /=10
	Variable newVal = ceil(value)
	newVal *=10
	return newVal
End

Function/WAVE RandomiseAndCheck(w0)
	Wave w0
	
	// nRows of randWave will be the number of frames of movie w0
	Variable nRows = dimsize(w0,2)
	
	Variable tempVar=0
	Variable i,j=0
	
	do
		Make/O/N=(nRows) randWave,keyw1
		randWave = p
		keyw1 = abs(enoise(1))
		Sort keyw1 randWave,keyw1 // randWave is now randomised
		tempVar = 0
	
		for (i = 0; i < nRows; i += 1)
			if(randWave[i] >= i - 2 && randWave[i] <= 2)
				tempVar = 1
			endif
		endfor
		j += 1
	while (tempVar == 0 || j == 1000)
	
	KillWaves/Z keyw1
	return randWave
End