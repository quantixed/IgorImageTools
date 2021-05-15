#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later
#include <ImageSlider>

// we have a directory of images taken from the Pi camera.
// filenames are e.g. 2019-08-24_0830.jpg
// at the moment this code is hard coded to take a 464 x 783 excerpt
// from midday across three years and array them next to one another
// this gives a 16:9 ratio for the resulting movie

Function GenerateMovie()
	// 464 wide, 783 tall
	Make/O/N=(464 * 3,783,3,365)/B theMovie=127
	
	Variable BaseDate = Date2secs(2019,1,1) + (12 * 60 * 60)
	Make/O/N=(365)/T date2019
	date2019[] = Secs2Date(BaseDate + (p * 24 * 60 * 60),-2)
	
	NewPath/O/Q/M="Please find disk folder" diskFolder
	if (V_flag != 0)
		DoAlert 0, "Disk folder error"
		return -1
	endif
	
	String fileName
	Variable i
	
	for (i = 0; i < 365; i += 1)
		fileName = date2019[i] + "_1200.jpg"
		
		if(mod(i,30) == 0)
			Print fileName
		endif
		
		ImageLoad/T=jpeg/Q/N=image/P=diskFolder/Z fileName
		WAVE/Z image
		if(WaveExists(image))
			theMovie[0,463][0,782][][i] = image[1726 + p - 0][799 + q][r]
			KillWaves/Z image
		endif
		// now do 2020
		fileName = ReplaceString("2019-",fileName,"2020-")
		ImageLoad/T=jpeg/Q/N=image/P=diskFolder/Z fileName
		WAVE/Z image
		if(WaveExists(image))
			theMovie[464,927][0,782][][i] = image[1726 + p - 464][799 + q][r]
			KillWaves/Z image
		endif
		// now do 2021
		fileName = ReplaceString("2020-",fileName,"2021-")
		ImageLoad/T=jpeg/Q/N=image/P=diskFolder/Z fileName
		WAVE/Z image
		if(WaveExists(image))
			theMovie[928,1391][0,782][][i] = image[1726 + p - 928][799 + q][r]
			KillWaves/Z image
		endif
	endfor
End

/////////////////////////////////////////////////////////////

Function GetAverageValues()
	// 1230 wide, 498 tall
	// starting at 1086, 348
	Variable BaseDate = Date2secs(2019,1,1) + (12 * 60 * 60)
	Make/O/N=(365)/T date2019
	date2019[] = Secs2Date(BaseDate + (p * 24 * 60 * 60),-2)
	Duplicate/O/T date2019, date2020, date2021
	date2020[] = ReplaceString("2019-",date2019[p],"2020-")
	date2021[] = ReplaceString("2019-",date2019[p],"2021-")
	Concatenate/O/T/NP=0/KILL {date2019,date2020,date2021}, theDateW
	Variable nDays = numpnts(theDateW)
	// make a matrix to hold the excerpt in
	Make/O/N=(1230,498,3)/D/FREE excerpt
	// wave to hold results
	Make/O/N=(nDays,3) resultW
	Variable pixels = 1230 * 498
	
	NewPath/O/Q/M="Please find disk folder" diskFolder
	if (V_flag != 0)
		DoAlert 0, "Disk folder error"
		return -1
	endif
	
	String fileName
	Variable i
	
	for (i = 0; i < nDays; i += 1)
		fileName = theDateW[i] + "_1200.jpg"
		
		if(mod(i,30) == 0)
			Print fileName
		endif
		
		ImageLoad/T=jpeg/Q/N=image/P=diskFolder/Z fileName
		WAVE/Z image
		if(WaveExists(image))
			excerpt[][][] = image[1086 + p][348 + q][r]
			MatrixOp/O/FREE rgbValue = sqrt(sumsqr(excerpt) / pixels)
			resultW[i][] = rgbValue[0][0][q]
			KillWaves/Z image
		else
			resultW[i][] = NaN
		endif
	endfor
End

Function ArraySpots()
	WAVE/Z/T theDateW
	// first year is 2019
	Variable nSpots = numpnts(theDateW)
	Make/O/N=(nSpots,2) xyW
	String dateStr
	
	Variable i
	
	for(i = 0; i < nSpots; i += 1)
		dateStr = theDateW[i]
		xyW[i][1] = ((str2num(dateStr[0,3]) - 2019) * 12) + str2num(dateStr[5,6])
		xyW[i][0] = str2num(dateStr[8,9]) + dateOffset(dateStr)
	endfor
	
	WAVE/Z rgbW
	KillWindow/Z p_calendar
	Display/N=p_calendar/W=(630,53,1505,886) xyW[][1] vs xyW[][0]
	ModifyGraph/W=p_calendar mode=3,marker=19,zColor(xyW)={rgbW,*,*,directRGB,0}
	SetAxis/A/R/W=p_calendar left
	// x-axis
	Make/O/N=38 xPos = p + 1
	String DaysOfWeek = "S;M;T;W;T;F;S;"
	Make/O/N=38/T xLabel = StringFromList(mod(xPos[p] - 1,7), DaysOfWeek)
	// y-axis
	Duplicate/O/T/FREE theDateW, tempW
	tempW[] = theDateW[p][1][1][1][0,6]
	FindDuplicates/RT=yLabel tempW
	Make/O/N=(numpnts(yLabel)) yPos = p + 1
	// apply axes
	ModifyGraph/W=p_calendar userticks(bottom)={xPos,xLabel}
	ModifyGraph/W=p_calendar userticks(left)={yPos,yLabel}
	ModifyGraph/W=p_calendar gfSize=10
End

STATIC Function dateOffset(STRING s)
	Variable yyyy = str2num(s[0,3])
	Variable mm = str2num(s[5,6])
	// 1st of month is
	String offset = Secs2Date(date2secs(yyyy,mm,1),-1)
	
	return str2num(offset[12]) - 1
End
	