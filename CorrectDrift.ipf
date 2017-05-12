#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include <WaveSelectorWidget>
#include <PopupWaveSelector>

Menu "Macros"
	"Correct Drift", CDPopupWaveSelector()
end

// This function presents each wave, user specifies a region of baseline
// Igor uses these two values to Correct Drift (Quick and Dirty Method)
Function CorrectDriftQD(w0)
	Wave w0
		
	String wName = NameOfWave(w0)
	Variable xlow=0, xhi=1, ylow=0, yhi=0
	Duplicate/O w0 $(wName + "_n")
	Wave w1 = $(wName + "_n")
	
	String graphName = "offsetGraph"
	
	KillWindow/Z $graphName
	Display /N=$graphName w0
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
		xlow = xcsr(a)
		xhi = xcsr(b)
		ylow = vcsr(a)
		yhi = vcsr(b)
	endif
	
	w1 -= ((yhi - ylow) / (xhi - xlow)) * x
	AppendToGraph/W=offsetGraph w1
End

// This function presents each wave, user specifies a region of baseline
// Igor uses these two values to fit a line and Correct Drift
Function CorrectDrift(w0)
	Wave w0
		
	String wName = NameOfWave(w0)
	Variable xlow=0, xhi=1, ylow=0, yhi=0
	Duplicate/O w0 $(wName + "_n")
	Wave w1 = $(wName + "_n")
	
	String graphName = "offsetGraph"
	
	KillWindow/Z $graphName
	Display /N=$graphName w0
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
		CurveFit/Q/NTHR=0 line w0[pcsr(A),pcsr(B)]
	endif
	WAVE/Z W_coef
	w1 -= (W_coef[1] * x) + W_coef[0]
	AppendToGraph/W=offsetGraph w1
End

// This is for marquee control
Function UserCursorAdjust_ContButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/K tmp_PauseforCursor				// Kill self
End

Function CDPopupWaveSelector()
	
	KillWindow/Z DemoPopupWaveSelectorPanel
	NewPanel/K=1/W=(150,50,570,180) as "Correct Drift"
	RenameWindow $S_name, DemoPopupWaveSelectorPanel
	
	Button PopupWaveSelectorB1,pos={20,40},size={250,20}
	MakeButtonIntoWSPopupButton("DemoPopupWaveSelectorPanel", "PopupWaveSelectorB1", "DemoPopupWaveSelectorNotify", options=PopupWS_OptionFloat, content=WMWS_Waves)
	TitleBox WSPopupTitle1,pos={20,20},size={115,12},title="Select wave for drift correction:"
	TitleBox WSPopupTitle1,frame=0

	Button CDQDButton,pos={20,104},size={121,20},proc=CDQDButtonProc,title="Quick and dirty"
	Button CDLFButton,pos={149,104},size={121,20},proc=CDLFButtonProc,title="Line fit"
	Button CDEFButton,pos={279,104},size={121,20},proc=CDEFButtonProc,title="Exponential fit"
EndMacro

Function DemoPopupWaveSelectorNotify(event, wavepath, windowName, ctrlName)
	Variable event
	String wavepath
	String windowName
	String ctrlName
	
	print "Selected wave:",wavepath, " using control", ctrlName
end

Function CDQDButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DisplayProcedure "fDemoPopupWaveSelector"
End

Function CDLFButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DisplayProcedure "fDemoPopupWaveSelector"
End

Function CDEFButtonProc(ctrlName) : ButtonControl
	String ctrlName

	DisplayProcedure "fDemoPopupWaveSelector"
End
