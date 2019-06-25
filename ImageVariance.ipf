#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function ImgVariancePerPixel(img0)
	Wave img0
	Variable nRow = DimSize(img0,0)
	Variable nCol = DimSize(img0,1)
	Variable nLayer = DimSize(img0,2)
	Make/O/N=(nRow,nCol)/D result
	
	Variable i,j
	
	for(i = 0; i < nRow; i += 1)
		for(j = 0; j < nCol; j += 1)
			MatrixOp/O/FREE tempW = beam(img0,i,j)
			result[i][j] = Variance(tempW)
		endfor
	endfor
End

Function ImgVariancePerLayer(img0)
	Wave img0
	Variable nRow = DimSize(img0,0)
	Variable nCol = DimSize(img0,1)
	Variable nLayer = DimSize(img0,2)
	Make/O/N=(nLayer)/D result
	
	Variable i
	
	for(i = 0; i < nLayer; i += 1)
		MatrixOp/O/FREE tempW = layer(img0,i)
		result[i] = Variance(tempW)
	endfor
End