#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <All IP Procedures>
Menu "Macros"
	"ColocAnalysis...",  ColocAnalysis()
End

Function ColocAnalysis()
	Load2ChComDetResults()
	Make2ChMasks()
End

Function MakeColocMovie(m0,m1,bg0,bg1,normOpt)
	Wave m0,m1
	Variable bg0,bg1
	Variable normOpt
	
	NewPath/O/Q/M="Please find disk folder" OutputFolder
	if (V_flag!=0)
		DoAlert 0, "Disk folder error"
		Return -1
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
			NewMovie/O/P=OutputFolder/CTYP="jpeg"/F=15 as "coloc"
		endif
		AddMovieFrame
		//save out pics for gif assembly in ImageJ
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
		SavePICT/P=OutputFolder/E=-7/B=288 as tiffName
	endfor
	CloseMovie
End

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

// Load results from ComDet 0.3.5
Function Load2ChComDetResults()
	// Load Channel 1 output from ComDet
	LoadWave/Q/A/J/D/W/O/L={0,1,0,1,3} ""
	Concatenate/O/KILL "Abs_Frame;X__px_;Y__px_;", mat1
	// Load Channel 2 output from ComDet
	LoadWave/Q/A/J/D/W/O/L={0,1,0,1,3} ""
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
End

Function Make2ChMasks()
	WAVE ComDet_1,ComDet_2
	// hard code the tiffs
	Wave m0 = 'ch1.tif'
	Wave m1 = 'ch2.tif'
	
	if(dimsize(m0,2) != dimsize(m1,2))
		Abort "Different number of frames in each channel"
	endif
	
	if((dimsize(m0,0) != dimsize(m1,0)) || (dimsize(m0,1) != dimsize(m1,1)))
		Abort "Different sizes of frames in each channel"
	endif
	
	Make/O/N=(dimsize(m0,0),dimsize(m0,1),dimsize(m0,2)) mask_1=0,mask_2=0
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
End

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
