#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
Function Coloc(m0,m1,bg0,bg1,frameNum)
	Wave m0,m1
	Variable bg0,bg1
	Variable frameNum
	
	Variable nPx = dimsize(m0,0) * dimsize(m1,1)
	
	Duplicate/O/RMD=[][][frameNum] m0,d0
	Duplicate/O/RMD=[][][frameNum] m1,d1
	
	d0 = ((d0[p][q] <= bg0) || (d1[p][q] <= bg1)) ? d0[p][q] : NaN
	d1 = ((d0[p][q] <= bg0) || (d1[p][q] <= bg1)) ? d1[p][q] : NaN
	
	Redimension/N=(nPx) d0
	Redimension/N=(nPx) d1
	
	Display d1 vs d0
End