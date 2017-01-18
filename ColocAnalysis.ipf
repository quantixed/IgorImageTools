#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
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
	
	DoWindow/K Result
	Display/N=Result d1 vs d0
	ModifyGraph/W=Result mode=2
	ModifyGraph/W=Result width={Plan,1,bottom,left}
	SetAxis/W=Result/A/N=1/E=1 left
	SetAxis/W=Result/A/N=1/E=1 bottom
End