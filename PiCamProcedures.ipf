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
	MakeDates()
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

STATIC Function MakeDates()
	// secs from 1904-01-01 for 2019-01-01 midday
	Variable BaseDate = Date2secs(2019,1,1) + (12 * 60 * 60)
	Make/O/N=(365)/T date2019
	date2019[] = Secs2Date(BaseDate + (p * 24 * 60 * 60),-2)
End
