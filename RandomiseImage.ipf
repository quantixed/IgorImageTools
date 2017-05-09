#pragma TextEncoding = "MacRoman"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function RandomiseImage(inWave)
    Wave inWave
    Duplicate/O inWave, outWave
    
    Variable xx = dimsize(inWave,0)
    Variable yy = dimsize(inWave,1)
    Variable zz = dimsize(inWave,2)
    
    Variable i
    
    for(i = 0; i < zz; i += 1)
        MatrixOp/O/FREE tempLayer = layer(inWave,i)
        Redimension/N=(xx*yy) tempLayer
        StatsSample/N=(xx*yy) tempLayer
        WAVE/Z W_Sampled
        Redimension/N=(xx,yy) W_Sampled
        outWave[][][i] = W_Sampled[p][q]
    endfor
End