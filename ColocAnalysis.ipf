#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <ImageSlider>
#include <3DWaveDisplay>
#include <loadFolderImages>
#include <MovieFromStack>

Menu "Macros"
	"ColocAnalysis...",  myIO_Panel()
End

Function myIO_Panel()
	// make global text wave to store paths and output folder
	Make/T/O/N=5 PathWave
	// make global numeric wave for other variables
	Make/O/N=4 gVarWave={0,0,1,0}
	DoWindow/K FilePicker
	NewPanel/N=FilePicker/W=(81,73,774,298)
	Button SelectFile1,pos={12.00,10.00},size={140.00,20.00},proc=ButtonProc,title="Select Ch1 TIFF"
	Button SelectFile2,pos={12.00,41.00},size={140.00,20.00},proc=ButtonProc,title="Select Ch2 TIFF"
	Button SelectFile3,pos={12.00,72.00},size={140.00,20.00},proc=ButtonProc,title="Select Ch1 ComDet"
	Button SelectFile4,pos={12.00,103.00},size={140.00,20.00},proc=ButtonProc,title="Select Ch2 ComDet"
	Button Output,pos={12.00,134.00},size={140.00,20.00},proc=ButtonProc,title="Select Output Folder"
	SetVariable File1,pos={168.00,13.00},size={500.00,14.00},value= PathWave[0]
	SetVariable File2,pos={168.00,44.00},size={500.00,14.00},value= PathWave[1]
	SetVariable File3,pos={168.00,75.00},size={500.00,14.00},value= PathWave[2]
	SetVariable File4,pos={168.00,106.00},size={500.00,14.00},value= PathWave[3]
	SetVariable File5,pos={168.00,137.00},size={500.00,14.00},value= PathWave[4]
	
	CheckBox normCheck,pos={12,161},size={69,14},title="Normalise channels",value= gVarWave[2]
	CheckBox tiffCheck,pos={12,181},size={69,14},title="Make Coloc Tiffs",value= gVarWave[3]
	
	SetVariable bg0SetVar,pos={168,161},size={166,15},title="Background Ch1:",format="%g",value= gVarWave[0]
	SetVariable bg1SetVar,pos={168,181},size={166,15},title="Background Ch2:",format="%g",value= gVarWave[1]
	
	Button DoIt,pos={564.00,181.00},size={100.00,20.00},proc=ButtonProc,title="Do It"
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
				break
 
			case "SelectFile2"	:
				// get File Paths
				Open/D/R/F="*.tif"/M="Select Ch2 Image" refNum
				if (strlen(S_FileName) == 0) 
					return -1
				endif
				PathWave[1] = S_fileName
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
				LoadAllFiles(PathWave)
				break
 
		EndSwitch
End
 
Function LoadAllFiles(path)
	Wave/T path
	
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
		WAVE/Z ch1tiff,ch2tiff
		MakeColocMovie(ch1tiff,ch2tiff,"noMask")
	endif
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
	endif
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
	
	WAVE ch1tiff, ch2tiff
	
	String mList = ""
	if ((nCh & 2^0) != 0) // bit 0 is set
		mList += "mask_1;"
	endif
	if ((nCh & 2^1) != 0) // bit 1 is set
		mList += "mask_2;"
	endif
	if ((nCh & 2^0) != 0 && (nCh & 2^1) !=0) // bit 0 AND bit 1 are set
		mList += "mask_3;"
	endif
	
	String mName
	
	Variable i,j
	
	for(i = 0; i < ItemsInList(mList); i += 1)
		mName = StringFromList(i, mList)
		Wave mask = $mName
		MatrixOp/O out0 = ch1tiff * mask
		MatrixOp/O out1 = ch2tiff * mask
		// send for analysis
		MakeColocMovie(out0,out1,mName)
	endfor
	KillWaves out0,out1
	SpotPlotOverTime(mList,9)	// divide pixels by 9 to get plot in units of numbers of spots
	MakeFinalImage(nCh)
End


///	@param	m0		First channel TIFF stack
///	@param	m1		Second channel TIFF stack
///	@param	subFolderName		String containing the Name for subfolder
// Limit is 9999 frames
// Movie goes to OutputFolder/Subfolder
// TIFFs go to OutputFolder/Subfolder/TIFFs
Function MakeColocMovie(m0,m1,subFolderName)
	Wave m0,m1
	String subFolderName
	
	Wave gVarWave
	Variable bg0 = gVarWave[0]
	Variable bg1 = gVarWave[1]
	// 0 is no norm (graph scaled to Movie max), 1 is normalise to channel max for whole movie
	Variable normOpt = gVarWave[2]
	Variable tiffOpt = gVarWave[3]
	
	Wave/T PathWave
	String outputFolderName = PathWave[4]

	// Define Paths for OutputSubFolder and OutputTIFFFolder
	String folderStr = OutputFolderName + subFolderName + ":"
	NewPath/C/O/Q/Z OutputSubFolder folderStr
	if(tiffOpt == 1)
		folderStr += "TIFFs:"
		NewPath/C/O/Q/Z OutputTIFFFolder folderStr
	endif
	
	WaveStats/Q m0
	Variable m0Max = V_max
	Variable m0Frames = dimsize(m0,2)
	WaveStats/Q m1
	Variable m1Max = V_max
	Variable XYmax = max(m0Max,m1Max)
	
	if(m0Frames != dimsize(m1,2))
		Abort "Different number of frames in each channel"
	endif
	
	if((dimsize(m0,0) != dimsize(m1,0)) || (dimsize(m0,1) != dimsize(m1,1)))
		Abort "Different sizes of frames in each channel"
	endif
	
	Variable i
	
	// Set-up window for display
	DoWindow/K Result
	Make/O/N=1 d0,d1
	Display/N=Result/W=(0,0,208,208) d1 vs d0
	ModifyGraph/W=Result mode=2
	ModifyGraph/W=Result rgb(d1)=(0,0,65535)
	ModifyGraph/W=Result width={Plan,1,bottom,left}
	if(normOpt == 0)
		SetAxis/W=Result left 0,XYmax
		SetAxis/W=Result bottom 0,XYmax
	elseif(normOpt == 1)
		SetAxis/W=Result left 0,1
		SetAxis/W=Result bottom 0,1
	endif
	ModifyGraph/W=Result gbRGB=(62258,62258,62258) // 5% grey
	ModifyGraph/W=Result margin=5
	ModifyGraph/W=Result noLabel=2
	ModifyGraph/W=Result grid=1
	ModifyGraph/W=Result gridStyle=5,gridHair=0
	ModifyGraph/W=Result manTick={0,0.2,0,2},manMinor={0,1}
	ModifyGraph/W=Result axRGB=(65535,65535,65535),tlblRGB=(65535,65535,65535),alblRGB=(65535,65535,65535),gridRGB=(65535,65535,65535)
	TextBox/W=Result/C/N=text0/F=0/B=1/A=LT/X=0.00/Y=0.00 NameOfWave(m1)
	TextBox/W=Result/C/N=text1/F=0/B=1/A=RB/X=0.00/Y=0.00 NameOfWave(m0)
	
	String iString, tiffName
	
	for(i = 0; i < m0Frames; i += 1)
		Coloc(m0,m1,bg0,bg1,i)
		if(normOpt ==1)
			d0 -= bg0
			d1 -= bg1
			d0 /= (m0Max - bg0)
			d1 /= (m1Max - bg1)
		endif
		TextBox/W=Result/C/N=text2/F=0/B=1/A=RT/X=0.00/Y=0.00 num2str(i)
		// take snap
		DoUpdate
		DoWindow/F Result
		if(i == 0)
			NewMovie/O/P=OutputSubFolder/CTYP="jpeg"/F=15 as "coloc"
		endif
		AddMovieFrame
		
		// Optional: save out pics for gif assembly in ImageJ
		if(tiffOpt == 1)
			if( i >= 0 && i < 10)
				iString = "000" + num2str(i)
			elseif( i >=10 && i < 100)
				iString = "00" + num2str(i)
				elseif(i >= 100 && i < 1000)
				iString = "0" + num2str(i)
			elseif(i >= 1000 && i < 10000)
				iString = num2str(i)
			endif
			tiffName = "coloc" + iString + ".tif"
			SavePICT/O/P=OutputTIFFFolder/E=-7/B=288 as tiffName
		endif
	endfor
	CloseMovie
	DoWindow/K Result
	KillWaves d0,d1
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
	
	Wave/T PathWave
	String outputFolderName = PathWave[4]

	// Define Paths for OutputSubFolder and OutputTIFFFolder
	String folderStr = OutputFolderName + "spotPlot:"
	NewPath/C/O/Q/Z OutputSubFolder folderStr
	if(tiffOpt == 1)
		folderStr += "TIFFs:"
		NewPath/C/O/Q/Z OutputTIFFFolder folderStr
	endif
	
	Variable nMask = ItemsInList(mList)
	String mName = StringFromList(0,mList)
	Wave m0 = $mName
	Variable nFrames = dimsize(m0,2)
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
		if(wavemax(w0) > maxValL)
			maxValL = wavemax(w0)
		endif
	endfor
	// declare all possible waves
	WAVE/Z nSpot_1,nSpot_2,nSpot_3
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
	// ModifyGraph/W=spotPlot width={Plan,1,bottom,left}
	SetAxis/W=spotPlot bottom 0,nFrames-1
	SetAxis/W=spotPlot left 0,NearestTon(maxValL)
	if(nMask > 1)
		SetAxis/W=spotPlot right 0,NearestTon(maxValR)
		Label/W=spotPlot right "Number of spots (\\K(64507,48830,10023)ch1 | ch2\\K(0,0,0))"
	endif
	
	String wList = ReplaceString("mask",mList,"nSpot")
	String iString, tiffName
	
	for(i = 0; i < nFrames; i += 1)
		for(j = 0; j < nMask; j +=1)
			wName = StringFromList(j,wList)
			ReplaceWave/W=spotPlot trace=$wName, $wName[0,i]
		endfor
		// take snap
		DoUpdate
		DoWindow/F spotPlot
		if(i == 0)
			NewMovie/O/P=OutputSubFolder/CTYP="jpeg"/F=15 as "coloc"
		endif
		AddMovieFrame
		
		// Optional: save out pics for gif assembly in ImageJ
		if(tiffOpt == 1)
			if( i >= 0 && i < 10)
				iString = "000" + num2str(i)
			elseif( i >=10 && i < 100)
				iString = "00" + num2str(i)
				elseif(i >= 100 && i < 1000)
				iString = "0" + num2str(i)
			elseif(i >= 1000 && i < 10000)
				iString = num2str(i)
			endif
			tiffName = "coloc" + iString + ".tif"
			SavePICT/O/P=OutputTIFFFolder/E=-7/B=288 as tiffName
//			tiffName = "coloc" + iString
//			SavePICT/O/P=_PictGallery_/E=-7/B=288 as tiffName
		endif
	endfor
	CloseMovie
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

Function MakeFinalImage(nCh)
	Variable nCh
	WAVE gVarWave
	
	//make 2 ch overlay tiff
	WAVE ch1tiff,ch2tiff
	MatrixOp/O ch1G = uint8(255 * (ch1tiff/maxVal(ch1tiff)))
	MatrixOp/O ch2R = uint8(255 * (ch2tiff/maxVal(ch2tiff)))
	Variable xx = dimsize(ch1tiff,0)
	Variable yy = dimsize(ch1tiff,1)
	Variable zz = dimsize(ch1tiff,2)
	Make/O/N=(xx,yy,zz)/B/U ch3B=0
	// make green panel grayscale
	Concatenate/O {ch1G,ch1G,ch1G}, tempMat
	ImageTransform/TM4D=1284 transpose4D tempMat
	WAVE M_4DTranspose
	Duplicate/O M_4DTranspose, panel1
	KillWaves tempMat
	// make green panel grayscale
	Concatenate/O {ch2R,ch2R,ch2R}, tempMat
	ImageTransform/TM4D=1284 transpose4D tempMat
	Duplicate/O M_4DTranspose, panel2
	KillWaves tempMat
	// make merge
	Concatenate/O {ch1G,ch2R,ch3B}, tempMat
	ImageTransform/TM4D=1284 transpose4D tempMat
	Duplicate/O M_4DTranspose, panel3
	// make montage
	WAVE panel1,panel2,panel3
	Concatenate/O/KILL/NP=0 {panel1,panel2,panel3}, montageTiff
	// clean up
	KillWaves/Z tempMat,M_4DTranspose,ch1G,ch2R,ch3B
	
//	// display image with slider
//	DoWindow/K montage
//	NewImage/N=montage montageTiff
//	DoWindow/F montage
//	WMAppend3DImageSlider()
	
	WAVE/T PathWave
	String OutputFolderName = PathWave[4]
	String folderStr
	
	if(gVarWave[3] == 1)
		if ((nCh & 2^0) != 0) // bit 0 is set
			// ch1
			folderStr = OutputFolderName + "mask_1:TIFFs:"
			LoadAndStack(folderStr)
			WAVE M_Stack
			Rename M_Stack, Stack_1
		endif
		if ((nCh & 2^1) != 0) // bit 1 is set
			// ch2
			folderStr = OutputFolderName + "mask_2:TIFFs:"
			NewPath/O/Q OutputTIFFFolder folderStr
			LoadAndStack(folderStr)
			WAVE M_Stack
			Rename M_Stack, Stack_2
		endif
		if ((nCh & 2^0) != 0 && (nCh & 2^1) !=0) // bit 0 AND bit 1 are set
			// two channels
			folderStr = OutputFolderName + "mask_3:TIFFs:"
			NewPath/O/Q OutputTIFFFolder folderStr
			LoadAndStack(folderStr)
			WAVE M_Stack
			Rename M_Stack, Stack_3
		endif
		// spotPlot
		folderStr = OutputFolderName + "spotPlot:TIFFs:"
		NewPath/O/Q OutputTIFFFolder folderStr
		LoadAndStack(folderStr)
		WAVE M_Stack
		Rename M_Stack, Stack_4
	endif
	WAVE/Z Stack_1,Stack_2,Stack_3,Stack_4
	Concatenate/O/KILL/NP=0 {Stack_1,Stack_2}, Stack_Top
	Concatenate/O/KILL/NP=0 {Stack_3,Stack_4}, Stack_Bottom
	Concatenate/O/KILL/NP=1 {Stack_Top,Stack_Bottom}, Stack_Plots
	
//	DoWindow/K plotImage
//	NewImage/N=plotImage Stack_Plots
//	DoWindow/F PlotImage
//	WMAppend3DImageSlider()
	if(dimsize(montageTIFF,1) == dimsize(stack_Plots,1))
		Concatenate/O/NP=0 {montageTIFF,Stack_Plots}, finalTIFF
	elseif(dimsize(montageTIFF,1) > dimsize(stack_Plots,1))
		// make stackplot bigger then concatenate
		Make/O/B/U/N=(dimsize(stack_Plots,0),dimsize(montageTIFF,1)-dimsize(stack_Plots,1),dimsize(stack_Plots,2),dimsize(stack_Plots,3)) greyStack
		Concatenate/O/NP=1 {stack_Plots,greyStack}, tempStack
		Concatenate/O/NP=0 {montageTIFF,tempStack}, finalTIFF
		KillWaves tempStack,greyStack
	elseif(dimsize(montageTIFF,1) < dimsize(stack_Plots,1))
		// make montageTIFF bigger then concatenate
		Make/O/B/U/N=(dimsize(montageTIFF,0),dimsize(stack_Plots,1)-dimsize(montageTIFF,1),dimsize(montageTIFF,2),dimsize(montageTIFF,3)) greyStack
		Concatenate/O/NP=1 {montageTIFF,greyStack}, tempStack
		Concatenate/O/NP=0 {tempStack,stack_Plots}, finalTIFF
		KillWaves tempStack,greyStack
	endif
	DoWindow/K finalImage
	NewImage/N=finalImage finalTIFF
	NewPath/O/Q OutputTIFFFolder outputFolderName
	ImageSave/O/S/U/P=OutputTIFFFolder finalTIFF as "finalTIFF.tif"
	DoWindow/F finalImage
	WMAppend3DImageSlider()
	// save image as tiff stack

End

Static Function LoadAndStack(folderStr)
	String folderStr
	
	NewPath/O/Q OutputTIFFFolder folderStr
	String listAllFiles=indexedfile(OutputTIFFFolder,-1,".tif")
	
	String fileName
	Variable i=0,numImages=0
	String wavestr,myStr, firstWave

	do
		fileName=StringFromList(i,listAllFiles)
		if(strlen(fileName)<=0)
			break
		endif
		ImageLoad/Q/P=OutputTIFFFolder/T=tiff fileName
		waveStr=StringFromList(0,S_waveNames)
		sprintf myStr,"%s%04d","temp",i
		Rename $wavestr,$myStr
			if(i==0)
			firstWave=myStr
		endif
		numImages+=1
		i+=1
	while(1)
	ImageTransform/K stackImages $firstWave
End