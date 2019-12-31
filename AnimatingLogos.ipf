#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <MatrixToXYZ>

Function AnimateThis(m0,m2,frames,width,height)
	Wave m0,m2 // image 1 and image 2 as xy coords
	Variable frames,width,height
	
	Variable minRow = floor(0.5 * (min(DimSize(m0,0),DimSize(m2,0))))
	
	// subsample minRow from both coord sets
//	Wave s0 = Subsample(m0,minRow)
//	Wave s2 = Subsample(m2,minRow)
	StatsSample/MC/N=(minRow) m0
	WAVE/Z M_Sampled
	Duplicate/O/FREE M_Sampled, s0
	StatsSample/MC/N=(minRow) m2
	Duplicate/O/FREE M_Sampled, s2
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
	// could hide this window for speed
	Display/N=imgWin M_Animate[][1][0] vs M_Animate[][0][0]
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
	String imgName = "output_0.png"
	SavePICT/WIN=imgWin/E=-5/RES=300/P=outputFolder as imgName
	Variable nFrame = DimSize(M_Animate,2)
	
	for(i = 1; i < nFrame; i += 1)
		ReplaceWave/W=imgWin trace=M_Animate, M_Animate[][1][i]
		ReplaceWave/W=imgWin /X trace=M_Animate, M_Animate[][0][i]
		imgName = "output_" + num2str(i) + ".png"
		SavePICT/WIN=imgWin/E=-5/RES=300/P=outputFolder as imgName
	endfor
	KillWaves/Z M_Animate
End

//Function/WAVE Subsample(m0,nRow)
//	Wave m0
//	Variable nRow
//	
//	Make/O/FREE/N=(DimSize(m0,0)) tempW = p
//	StatsSample
//	Wave m1
//	
//	return m1
//End

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

Function RandomiseXY(x0,y0,ww,hh)
	Wave x0, y0
	Variable ww,hh
	String xName = NameOfWave(x0) + "_rand"
	Duplicate/O x0, $xName
	Wave x1 = $xName
	String yName = NameOfWave(y0) + "_rand"
	Duplicate/O y0, $yName
	Wave y1 = $yName
	Variable nRow = numpnts(x1)
	Variable midW = floor(ww / 2)
	Variable midH = floor(hh / 2)
	
	x1[] = midW + enoise(midW)
	y1[] = midH + enoise(midH)
	
//	Variable i
//	
//	for(i = 0; i < nRow; i += 1)
//		x1[i] = midW + enoise(midW)
//		y1[i] = midH + enoise(midH)
//	endfor
End