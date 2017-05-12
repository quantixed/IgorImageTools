#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <WaveSelectorWidget>
#include <PopupWaveSelector>

Menu "Macros"
	"Correct Drift", CDPopupWaveSelector()
end

// This function presents each wave, user specifies a region of baseline
// Igor uses these two values to Correct Drift
// Option 0 = quick and dirty - line between points is used
// Option 1 = line method - a line fit to the data is used
// Option 2 = exponential method - an exponential fit to the data is used
Function CorrectDrift(w0,optVar)
	Wave w0
	Variable optVar
		
	String wName = NameOfWave(w0)
	Variable xlow=0, xhi=1, ylow=0, yhi=0
	Duplicate/O w0 $(wName + "_n")
	Wave w1 = $(wName + "_n")
	
	String graphName = "offsetGraph"
	
	KillWindow/Z $graphName
	Display/K=1 /N=$graphName w0
	ShowInfo
	DoWindow $graphName
	if (V_Flag == 0) // Verify that graph exists
		Abort "UserCursorAdjust: No such graph."
		return -1
	endif
	
	NewPanel/K=2 /W=(187,368,437,531) as "Pause for Cursor"
	DoWindow/C tmp_PauseforCursor					// Set to an unlikely name
	AutoPositionWindow/E/M=1/R=$graphName			// Put panel near the graph
	DrawText 21,20,"Adjust the cursors and then"
	DrawText 21,40,"Click Continue."
	Button button0,pos={80,58},size={92,20},title="Continue"
	Button button0,proc=UserCursorAdjust_ContButtonProc
	PauseForUser tmp_PauseforCursor,$graphName
	if (strlen(CsrWave(A))>0 && strlen(CsrWave(B))>0)	// Cursors are on trace?
		if(optVar == 0)
			xlow = xcsr(a)
			xhi = xcsr(b)
			ylow = vcsr(a)
			yhi = vcsr(b)
		elseif(optVar == 1)
			CurveFit/Q/NTHR=0 line w0[pcsr(A),pcsr(B)]
			WAVE/Z W_coef
		elseif(optVar == 2)
			CurveFit/Q/NTHR=0 exp w0[pcsr(A),pcsr(B)]
			WAVE/Z W_coef
		endif
	endif
	
	if(optVar == 0)
		w1 -= ((yhi - ylow) / (xhi - xlow)) * x
	elseif(optVar == 1)
		w1 -= (W_coef[1] * x) + W_coef[0]
	elseif(optVar == 2)
		w1 -= W_coef[0] + W_coef[1] * exp(-W_coef[2] * x)
	endif
	
	AppendToGraph/W=offsetGraph w1
End

// This is for marquee control
Function UserCursorAdjust_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K tmp_PauseforCursor				// Kill self
End

Function CDPopupWaveSelector()
	
	KillWindow/Z DemoPopupWaveSelectorPanel
	NewPanel/K=1/W=(450,50,870,180) as "Correct Drift"
	RenameWindow $S_name, DemoPopupWaveSelectorPanel
	
	Button PopupWaveSelectorB1,pos={20,40},size={250,20}
	MakeButtonIntoWSPopupButton("DemoPopupWaveSelectorPanel", "PopupWaveSelectorB1", "DemoPopupWaveSelectorNotify", options=PopupWS_OptionFloat, content=WMWS_Waves)
	TitleBox WSPopupTitle1,pos={20,20},size={115,12},title="Select wave for drift correction:"
	TitleBox WSPopupTitle1,frame=0

	Button CDQD,pos={20,104},size={121,20},proc=CDButtonProc,title="Quick and dirty"
	Button CDLF,pos={149,104},size={121,20},proc=CDButtonProc,title="Line fit"
	Button CDEF,pos={279,104},size={121,20},proc=CDButtonProc,title="Exponential fit"
EndMacro

Function DemoPopupWaveSelectorNotify(event, wavepath, windowName, ctrlName)
	Variable event
	String wavepath
	String windowName
	String ctrlName
	
	String/G gCDWName = wavepath
	
	Print "Selected",wavepath, " for correction."
end

Function CDButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	SVAR CDWName = gCDWName
	Wave w0 = $CDWName
	
	strswitch(ctrlName)
 
		case "CDQD"	:
			if (strlen(CDWName) == 0) // user cancelled or some error occured
				return -1
			endif
			CorrectDrift(w0,0)
			Print "Using quick and dirty method."
			break
 
		case "CDLF"	:
			if (strlen(CDWName) == 0) // user cancelled or some error occured
				return -1
			endif
			CorrectDrift(w0,1)
			Print "Using line fit method."
			break
		
		case "CDEF"	:
			if (strlen(CDWName) == 0) // user cancelled or some error occured
				return -1
			endif
			CorrectDrift(w0,2)
			Print "Using exponential fit method."
			break

	EndSwitch
	KillWindow/Z DemoPopupWaveSelectorPanel
End