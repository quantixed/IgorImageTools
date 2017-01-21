#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <All IP Procedures>
Menu "Macros"
	"ColocAnalysis...",  myIO_Panel()
End

Function myIO_Panel()
	// make global text wave to store paths and output folder
	Make/T/O/N=5 PathWave
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
	
	
	
	Button DoIt,pos={296.00,181.00},size={100.00,20.00},proc=ButtonProc,title="Do It"
End
 
// define buttons
Function ButtonProc(ctrlName) : ButtonControl
	String ctrlName
 
		Wave/T PathWave
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
				LoadAllFiles(PathWave)
				break
 
		EndSwitch
End
 
function LoadAllFiles(path)
	Wave/T path
	// Load channel 1 and 2 tiff
	ImageLoad/T=tiff/N=ch1tiff/O/S=0/C=-1 path[0]
	ImageLoad/T=tiff/N=ch2tiff/O/S=0/C=-1 path[1]
	// Without ComDet Files, go straight to analysis
	if(strlen(path[2]) != 0 || strlen(path[3]) != 0)
		// Load ComDet Outputs
		LoadWave/Q/A/J/D/W/O/L={0,1,0,1,3} path[2]
		Concatenate/O/KILL "Abs_Frame;X__px_;Y__px_;", mat1
		LoadWave/Q/A/J/D/W/O/L={0,1,0,1,3} path[3]
		Concatenate/O/KILL "Abs_Frame;X__px_;Y__px_;", mat2
		// Now make 2D waves
		Variable nFrames
		nFrames = dimsize(mat1,0)
		Make/O/N=(nFrames, 3) ComDet_1
		ComDet_1 = round(mat1[p][q])
		nFrames = dimsize(mat2,0)
		Make/O/N=(nFrames, 3) ComDet_2
		ComDet_2 = round(mat2[p][q])
		// Cleanup
		KillWaves mat1,mat2
		Make2ChMasks()
	else
		MakeColocMovie(ch1tiff,ch2tiff,0,0,1,0,"noMask")
		// MakeColocMovie(m0,m1,bg0,bg1,normOpt,tiffOpt,subFolderName)
	endif
end

Function Make2ChMasks()

	WAVE ComDet_1,ComDet_2
	WAVE ch1tiff, ch2tiff
	
	if(dimsize(ch1tiff,2) != dimsize(ch2tiff,2))
		Abort "Different number of frames in each channel"
	endif
	
	if((dimsize(ch1tiff,0) != dimsize(ch2tiff,0)) || (dimsize(ch1tiff,1) != dimsize(ch2tiff,1)))
		Abort "Different sizes of frames in each channel"
	endif
	
	Make/O/B/U/N=(dimsize(ch1tiff,0),dimsize(ch1tiff,1),dimsize(ch1tiff,2)) mask_1=0, mask_2=0, mask_3
	Variable xx,yy,zz
	Variable nSpots
	
	Variable i
	
	// ch1
	nSpots = dimsize(ComDet_1,0)
	for(i = 0; i < nSpots; i += 1)
		xx = ComDet_1[i][1] - 1
		yy = ComDet_1[i][2] - 1
		zz = ComDet_1[i][0] - 1	// ImageJ is 1-based
		MakeThatMask(mask_1,xx,yy,zz)
	endfor
	// ch2
	nSpots = dimsize(ComDet_2,0)
	for(i = 0; i < nSpots; i += 1)
		xx = ComDet_2[i][1] - 1
		yy = ComDet_2[i][2] - 1
		zz = ComDet_2[i][0] - 1 // ImageJ is 1-based
		MakeThatMask(mask_2,xx,yy,zz)
	endfor
	// make an AND mask of the two channels in mask_3
	mask_3 = (mask_1[p][q][r] == 1 && mask_2[p][q][r] == 1) ? 1 : 0
	// now call next function
	MakeMaskedImagesAndAnalyse()
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
Function MakeMaskedImagesAndAnalyse()
	
	WAVE ch1tiff, ch2tiff
	String mList = "mask_1;mask_2;mask_3;"
	String mName
	
	Variable i,j
	
	for(i = 0; i < 3; i += 1)
		mName = StringFromList(i, mList)
		Wave mask = $mName
		MatrixOp/O out0 = ch1tiff * mask
		MatrixOp/O out1 = ch2tiff * mask
		// send for analysis
		MakeColocMovie(out0,out1,0,0,1,0,mName)
		// clean up as we go
		Killwaves/Z out0,out1,mask
	endfor
End


///	@param	m0		First channel TIFF stack
///	@param	m1		Second channel TIFF stack
///	@param	bg0		First channel background value
///	@param	bg1		Second channel background value
///	@param	normOpt		Normalisation option
///	@param	tiffOpt		Output Tiffs? 0 = No, 1 = Yes
///	@param	subFolderName		String containing the Name for subfolder
// Limit is 9999 frames
// Movie goes to OutputFolder/Subfolder
// TIFFs go to OutputFolder/Subfolder/TIFFs
Function MakeColocMovie(m0,m1,bg0,bg1,normOpt,tiffOpt,subFolderName)
	Wave m0,m1
	Variable bg0,bg1
	Variable normOpt // 0 is no norm (graph scaled to Movie max), 1 is normalise to channel max for whole movie
	Variable tiffOpt
	String subFolderName
	
	Wave/T PathWave
	String outputFolderName = PathWave[4]

	// Define Paths for OutputSubFolder and OutputTIFFFolder
	String folderStr = OutputFolderName + subFolderName + ":"
	NewPath/C/O/Q/Z OutputSubFolder folderStr
	folderStr += "TIFFs:"
	NewPath/C/O/Q/Z OutputTIFFFolder folderStr
	
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
	Display/N=Result d1 vs d0
	ModifyGraph/W=Result mode=2
	ModifyGraph/W=Result rgb(d1)=(0,0,65535)
	ModifyGraph/W=Result width={Plan,1,bottom,left}
	if(normOpt == 0)
		SetAxis/W=Result left 0,XYmax
		SetAxis/W=Result bottom 0,XYmax
	elseif(normOpt == 1)
		SetAxis/W=Result left 0,1
		SetAxis/W=Result bottom 0,1
	else
		Abort "Use 0 or 1 for normalisation option"
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
			SavePICT/P=OutputTIFFFolder/E=-7/B=288 as tiffName
		endif
	endfor
	CloseMovie
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
// requires the KillWaves line from MakeMaskedImagesAndAnalyse() to be commented out
Function CountTheSpots(m0,divVar)
	Wave m0
	Variable divVar // could be 1 or 9. 1 would give pixel value. 9 will give number of spots
	Variable nFrames = dimsize(m0,2)
	Make/O/N=(nFrames) nSpotWave
	Variable i
	
	for(i = 0; i < nFrames; i += 1)
		Duplicate/O/RMD=[][][i]/FREE m0,m1
		nSpotWave[i] = sum(m1)
	endfor
End