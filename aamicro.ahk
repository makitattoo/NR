#Requires AutoHotkey v2.0

#Include BidClickMapV2.ahk
#Include ExtensionButton.ahk
#Include LicenseManager.ahk

; ===== LICENSE VERIFICATION =====
; License system uses GitHub Gist for verification
; Bot starts immediately, license checked every 10 seconds in background

; Flag to signal license revocation
global licenseRevoked := false

; Silent license check at startup
CheckLicense()

; Start license verification timer - check every 10 seconds
SetTimer(LicenseCheckTimer, 10000)

; Set DPI Awareness to handle browser zoom and Windows scaling correctly
DllCall("SetThreadDpiAwarenessContext", "ptr", -3) ; DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
SetTitleMatchMode 2 ; Allow matching window titles that contain the string anywhere

CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")
CoordMode("ToolTip", "Screen")
global activeBidPID := 0
global activeBidType := ""
; Button detection now handled by Chrome Extension (ExtensionButton.ahk)
toggle := 0
global pressCount := 0
global allowF11 := false
global allowF10 := false
global pauseCountSession := false
global SessionGui := ""
global SessionText := ""
global SessionToggleBtn := ""
global SessionMinusBtn := ""
global SessionPlusBtn := ""
global SessionClockText := ""
global AuctionUIDLinkBtn := ""
global lastSessionClockDisplay := ""
global CalcGui := ""
global CalcInput := ""
global CalcBaseText := ""
global CalcTierText := ""
global isLoadingSettings := false
global currentLotDidBid := false
global UrlInput := ""
global CalcResultLabel := ""
global CalcTierLabel := ""
global CalcRemapBtn := ""
global CalcSpamFastRadio := ""
global CalcSpamMediumRadio := ""
global CalcSpamSlowRadio := ""
global CalcPercent1Radio := ""
global CalcPercent5Radio := ""
global CalcPercent10Radio := ""
global spamDelayMode := "fast"
global lastSubScript := ""
global PacingLPHFrame := ""
global PacingLotsFrame := ""
global PacingHourFrame := ""
global PacingMinFrame := ""
; global countdownSecondsRemaining := 0  ; Removed - using timer.mp3 instead
global manualPaused := false
global sessionCountPaused := false
global scriptPaused := false
; OCR removed - using Chrome Extension for price reading
global allowF8 := true
global allowF9 := true
global f11Paused := false
; Extension-based button detection active
global extensionMonitoringActive := false  ; Track if extension monitoring is on
global CurrentActiveLotID := ""
global currentAuctionProgressPct := ""
global currentAuctionProgressText := ""
global currentAuctionProgressNumber := 0
global lastValidAuctionProgressNumber := 0
global lastBiddingDurationSeconds := 5
global currentBiddingStartTime := 0
global lastF8Tick := 0
global pacingTargetAbsoluteLotMark := 0
global pacingAbsoluteDeadline := ""
global lastPacingTargetTotalTime := 0
global pacingStartLot := 0
global pacingStartTime := ""
global CurrentAuctionUID := ""
global lastExtensionPrice := ""  ; Last price from extension
global f9AutoBidTriggered := false  ; Track if auto-bid already executed
global f9ExtraStepArmed := false  ; Allows one manual extra F9 press after STOP
global f9ExtraStepUsed := false  ; Ensure only one extra press per session
global windowPosSaveFile := A_Temp "\bidhelper_micro_window_pos.txt"
global nextBidDisplayFile := A_Temp "\bidhelper_next_price.txt"
global sessionSaveFile := A_Temp "\bidhelper_session_count.txt"
global finalValueFile := A_Temp "\bidhelper_final_value.txt"
global lotTokenFile := A_Temp "\bidhelper_lot_token.txt"
global lotTokenCounter := 0
global repeatF8SignalFile := A_Temp "\bidhelper_repeat_f8.txt"
global comboCycleResetFile := A_Temp "\bidhelper_combo_cycle_reset.txt"
global domEstimateFile := A_Temp "\bidhelper_dom_estimate.txt"
global priceSnapshotFile := A_Temp "\bidhelper_price_snapshot.json"
global percentModeFile := A_Temp "\bidhelper_percent_mode.txt"
global targetPercentMode := "10"
global speedModeFile := A_Temp "\bidhelper_speed_mode.txt"
global internetBidPriceFile := A_Temp "\bidhelper_internet_bid_price.txt"
global checkButtonLatched := false
global ExtCoordsCache := Map()
global fastBidInternetWaitMs := 500
global fastBidInternetPollMs := 15
global fastBidClickGapMs := 200
global fastBidEnterCooldownMs := 60
global fastBidF8CooldownMs := 750
global lastSavedPressCount := 0  ; Track session memory for auto-resume
global f10F11PressLock := false
global f10F11LockAskValue := ""
global lastPersistentInternetPrice := "0"
global lastInternetBeepPrice := "0"
global internetInterruptFired := false
global internetExtendFired := false
global internetPriceResetTick := 0
global statusTxt := ""
global reloadStateRestored := false
global reloadPreservedPacingTarget := 0
global manualTargetLPH := 0
global globalLotDeficit := 0
global pacingLotAutoValue := ""
global pacingLotManualOverride := false
global pacingLotAutoUpdating := false

SetTitleMatchMode(2) ; Match anywhere in title
SetTitleMatchMode("Slow") ; Match case-insensitively if needed (AutoHotkey v2 behavior)

; ===============================
; AUTO-EXECUTE SECTION
; ===============================

#SingleInstance Force
#Warn
SetWorkingDir A_ScriptDir

global serverPID := 0

; --- NUCLEAR STARTUP: Kill all other scripts to prevent mouse-stealing ---
DetectHiddenWindows(true)
scriptList := WinGetList("ahk_class AutoHotkey")
for hwnd in scriptList
{
    if (hwnd != A_ScriptHwnd)
        WinClose("ahk_id " hwnd)
}
DetectHiddenWindows(false)

; Start extension server if not running
StartExtensionServer()

; Watchdog: check every 5 seconds if server is still alive, restart if not
SetTimer(ServerWatchdog, 5000)

; Register function to run on script exit
OnExit(ExitFunc)

; ===============================
; COMBO GLOBALS (Merged from combo.ahk)
; ===============================
global progressiveF8Step := 0
global progressiveLastLotToken := ""
global progressiveLockedLotToken := ""
global progressiveLastFinalValue := ""
global lastRepeatF8Signal := ""
global lastComboCycleResetSignal := ""
global autoClerkActive := false
global lastAutoClerkLotToken := ""
global lastAutoClerkLotNumber := 0
global autoClerkPhase := "BIDDING" ; Phases: BIDDING, WAITING, NEXT
global timerCueSeconds := 6
global timerCueMs := timerCueSeconds * 1000
global pacingFinishReserveSeconds := 0
global autoClerkWaitMs := timerCueMs ; Default wait time matches timer.mp3 cue
global lastHourTracked := -1
global lotAtTopOfHour := -1
global hourDeficit := 0
global pacingCurrentHourLeft := 0
global pacingHourKey := ""
global pacingHourStartLot := 0
global pacingHourQuota := 0
global pacingHourBaseCap := 0
global pacingHourTargetLot := 0
global pacingCarryDebt := 0
global pacingChunkStartLot := 0
global pacingChunkTargetLot := 0
global pacingChunkDeadline := ""
global isUpdatingPaceDisplay := false
global F10DangerBeepPlayed := false
global f10TriggerTime := 0
global autoClerkStartedLotToken := ""
global autoClerkInitialAnalysisDone := false
global lastInternetSeenTime := 0
global autoClerkBiddingStartTime := 0
global lastAutoClerkRetryTime := 0
global pendingStarterBid := false
global autoClerkLotIDChanged := false
global pacingStopPending := false
global timerSoundFired := false
global helperConfigs := Map()

; Define helper configs
helperConfigs["micro"] := {threshold: 500, bidValues: Map("F1", 125, "F2", 150, "F3", 250, "F4", 300, "F5", 350, "F6", 450, "F7", 500, "NumpadDiv", 500, "NumpadMult", 600, "NumpadSub", 650), start1: 100, start2: 125, steps: 5}
helperConfigs["small"] := {threshold: 1000, bidValues: Map("F1", 150, "F2", 200, "F3", 250, "F4", 350, "F5", 400, "F6", 450, "F7", 500, "NumpadDiv", 700, "NumpadMult", 900, "NumpadSub", 1000), start1: 100, start2: 200, steps: 7}
helperConfigs["medium"] := {threshold: 5000, bidValues: Map("F1", 300, "F2", 500, "F3", 700, "F4", 900, "F5", 1000, "F6", 1500, "F7", 2000, "NumpadDiv", 3000, "NumpadMult", 3500, "NumpadSub", 4000), start1: 100, start2: 300, steps: 8}
helperConfigs["large"] := {threshold: 10000, bidValues: Map("F1", 500, "F2", 1000, "F3", 3000, "F4", 5000, "F5", 10000, "F6", 13000, "F7", 15000, "NumpadDiv", 30000, "NumpadMult", 40000, "NumpadSub", 50000), start1: 100, start2: 500, steps: 7}
helperConfigs["ultra"] := {threshold: 50000, bidValues: Map("F1", 500, "F2", 1000, "F3", 3000, "F4", 5000, "F5", 7000, "F6", 10000, "F7", 30000, "NumpadDiv", 70000, "NumpadMult", 100000, "NumpadSub", 150000), start1: 100, start2: 500, steps: 8}
helperConfigs["mega"] := {threshold: 999999999, bidValues: Map("F1", 500, "F2", 1000, "F3", 3000, "F4", 5000, "F5", 10000, "F6", 15000, "F7", 20000, "NumpadDiv", 50000, "NumpadMult", 100000, "NumpadSub", 150000), start1: 100, start2: 500, steps: 10}

; ===============================
; F8 PROGRESSIVE LADDER CONFIG (Loads from AuctionSessions.ini)
; ===============================
global f8LadderBrackets := Map()  ; Stores loaded ladder configurations
global f8LadderConfigLoaded := false

; ===== F8 LADDER CONFIGURATION FUNCTIONS (Early Definition) =====
LoadF8LadderConfig()
{
    global f8LadderBrackets, f8LadderConfigLoaded
    
    configFile := A_ScriptDir "\AuctionSessions.ini"
    
    ; Check if config file exists
    if (!FileExist(configFile))
    {
        f8LadderConfigLoaded := false
        return
    }
    
    ; Load all bracket sections
    LoadBracketFromConfig("Bracket_Under1000", f8LadderBrackets, configFile, 0, 999)
    LoadBracketFromConfig("Bracket_1000to2500", f8LadderBrackets, configFile, 1000, 2500)
    LoadBracketFromConfig("Bracket_2500to5000", f8LadderBrackets, configFile, 2501, 5000)
    LoadBracketFromConfig("Bracket_5000to10000", f8LadderBrackets, configFile, 5001, 10000)
    LoadBracketFromConfig("Bracket_10000to25000", f8LadderBrackets, configFile, 10001, 25000)
    LoadBracketFromConfig("Bracket_25000to50000", f8LadderBrackets, configFile, 25001, 50000)
    LoadBracketFromConfig("Bracket_50000plus", f8LadderBrackets, configFile, 50001, 999999999)
    
    f8LadderConfigLoaded := true
}

LoadBracketFromConfig(sectionName, bracketMap, configFile, minVal, maxVal)
{
    try {
        rungsStr := IniRead(configFile, sectionName, "rungs", "")
        
        if (rungsStr = "")
            return false
        
        ; Parse comma-separated values
        rungsArray := StrSplit(rungsStr, ",")
        rungsClean := []
        
        for i, rung in rungsArray
        {
            rungNum := Trim(rung) + 0
            if (rungNum > 0)
                rungsClean.Push(rungNum)
        }
        
        ; Store bracket configuration
        bracketMap[sectionName] := {
            minValue: minVal,
            maxValue: maxVal,
            rungs: rungsClean
        }
        
        return true
    }
    catch as err
    {
        return false
    }
}

GetF8LadderForValue(targetValue)
{
    global f8LadderBrackets, f8LadderConfigLoaded
    
    if (!f8LadderConfigLoaded)
        return []
    
    for key, bracket in f8LadderBrackets
    {
        if (targetValue >= bracket.minValue && targetValue <= bracket.maxValue)
            return bracket.rungs
    }
    
    return []
}

ReloadF8LadderConfig()
{
    global f8LadderBrackets
    f8LadderBrackets := Map()
    LoadF8LadderConfig()
    MsgBox("F8 Ladder configuration reloaded!", "Success", "0x1040")
}

; ===== END F8 LADDER CONFIGURATION FUNCTIONS =====

; ===============================
; COMBO HOTKEYS (Merged from combo.ahk)
; ===============================
#HotIf WinActive("ahk_exe chrome.exe") && (WinActive("Auction") || WinActive("Clerk"))
F1::ForceUpdateCoordsCache()
F7::ResetProgressiveF8Manual()
F8::HandleProgressiveF8()

ExitFunc(*)
{
    global serverPID
    SaveSessionWindowPosition()

    ; Close the extension server if we started it
    if (serverPID != 0)
    {
        try {
            ProcessClose(serverPID)
        }
    }

    ; Kill node process and close sub-scripts when app closes
    try {
        ; Kill extension-server.js
        psScript := 'Get-CimInstance Win32_Process | Where-Object { $_.Name -eq "node.exe" -and $_.CommandLine -like "*extension-server.js*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }'
        RunWait('powershell -NoProfile -Command "' psScript '"', , "Hide")
    }
    ; Close all sub-scripts
    CloseSubScripts()
}

GuiDrag(wParam, lParam, msg, hwnd)
{
    if (hwnd = SessionGui.Hwnd)
    {
        PostMessage(0xA1, 2, , , "ahk_id " hwnd)
    }
}

LoadBidClickMapV2()
LoadF8LadderConfig()  ; Load F8 ladder configuration from AuctionSessions.ini
InitSessionWindow()
LaunchDomHelperLauncher()
StartExtensionMonitoring()  ; Start continuous OCR by default
SetTimer(CheckButton, 300)
SetTimer(WatchTargetTab, 500)
SetTimer(PollActiveLotState, 250)
SetTimer(TryAutoEnableF11FromBE, 250)
SetTimer(TryAutoEnableF10FromFinal, 250)
SetTimer(() => UpdateSessionClock(), 1000)  ; Try function reference syntax
; SetTimer(UpdateNextF8Display, 1000)  ; Disabled - replaced with timer
UpdateSessionClock()  ; Initial clock update

; --- CHECK FOR RELOAD RESUME STATE ---
stateFile := A_Temp "\bidhelper_reload_resume.ini"
if FileExist(stateFile)
{
    try
    {
        resumeState := Trim(FileRead(stateFile))
        FileDelete(stateFile)
        
        if RegExMatch(resumeState, "PressCount=(\d+)", &reloadMatch)
        {
            global pressCount := reloadMatch[1] + 0
            reloadStateRestored := true
            UpdateSessionWindow()
        }
        
        if RegExMatch(resumeState, "PacingTarget=(\d+)", &reloadMatch)
        {
            global pacingTargetAbsoluteLotMark := reloadMatch[1] + 0
            if (pacingTargetAbsoluteLotMark > 0 && IsObject(PacingLotsInput))
            {
                global pacingLotAutoUpdating := true
                global pacingLotAutoValue := pacingTargetAbsoluteLotMark . ""
                global pacingLotManualOverride := false
                PacingLotsInput.Value := pacingLotAutoValue
                pacingLotAutoUpdating := false
            }
        }

        if RegExMatch(resumeState, "LastPacingTarget=(\d+)", &reloadMatch)
        {
            global reloadPreservedPacingTarget := reloadMatch[1] + 0
            if (pacingTargetAbsoluteLotMark <= 0 && reloadPreservedPacingTarget > 0 && IsObject(PacingLotsInput))
            {
                global pacingLotAutoUpdating := true
                global pacingLotAutoValue := reloadPreservedPacingTarget . ""
                global pacingLotManualOverride := true
                PacingLotsInput.Value := pacingLotAutoValue
                pacingLotAutoUpdating := false
            }
        }
            
        if RegExMatch(resumeState, "PacingDeadline=([^\r\n]+)", &reloadMatch)
            global pacingAbsoluteDeadline := reloadMatch[1]
            
        if RegExMatch(resumeState, "PacingStart=(\d+)", &reloadMatch)
            global pacingStartLot := reloadMatch[1] + 0
            
        if RegExMatch(resumeState, "PacingStartTime=([^\r\n]+)", &reloadMatch)
            global pacingStartTime := reloadMatch[1]
            
        if RegExMatch(resumeState, "ManualLPH=(\d+)", &reloadMatch)
        {
            global manualTargetLPH := reloadMatch[1] + 0
            if (manualTargetLPH > 0 && IsObject(PacingLPHInput))
                PacingLPHInput.Value := manualTargetLPH
        }
        
        if RegExMatch(resumeState, "LotAtTopOfHour=(-?\d+)", &reloadMatch)
            global lotAtTopOfHour := reloadMatch[1] + 0

        if RegExMatch(resumeState, "PacingHourKey=([^\r\n]*)", &reloadMatch)
            global pacingHourKey := reloadMatch[1]
        if RegExMatch(resumeState, "PacingHourStartLot=(-?\d+)", &reloadMatch)
            global pacingHourStartLot := reloadMatch[1] + 0
        if RegExMatch(resumeState, "PacingHourQuota=(-?\d+)", &reloadMatch)
            global pacingHourQuota := reloadMatch[1] + 0
        if RegExMatch(resumeState, "PacingHourBaseCap=(-?\d+)", &reloadMatch)
            global pacingHourBaseCap := reloadMatch[1] + 0
        if RegExMatch(resumeState, "PacingHourTargetLot=(-?\d+)", &reloadMatch)
            global pacingHourTargetLot := reloadMatch[1] + 0
        if RegExMatch(resumeState, "PacingCarryDebt=(-?\d+)", &reloadMatch)
            global pacingCarryDebt := reloadMatch[1] + 0
            
        if RegExMatch(resumeState, "ClerkPhase=([^\r\n]+)", &reloadMatch)
        {
            savedPhase := Trim(reloadMatch[1])
            if (savedPhase = "WAITING" || savedPhase = "NEXT")
            {
                global autoClerkPhase := savedPhase
                elapsedWaitMs := 0
                if RegExMatch(resumeState, "ElapsedWaitMs=(\d+)", &reloadMatch)
                    elapsedWaitMs := reloadMatch[1] + 0
                global f10TriggerTime := A_TickCount - elapsedWaitMs
                
                if RegExMatch(resumeState, "AutoClerkWaitMs=(\d+)", &reloadMatch)
                    global autoClerkWaitMs := reloadMatch[1] + 0
            }
        }
            
        if (pacingTargetAbsoluteLotMark > 0)
        {
            if IsObject(PacingToggleBtn)
            {
                PacingToggleBtn.Text := "STOP BOT"
                PacingToggleBtn.SetFont("cFF4444")
            }
        }
        
        if (InStr(resumeState, "AutoClerk=1") && InStr(resumeState, "ResumeAtNextHour=1"))
        {
            SetTimer(ResumeAutoClerkAtNextHour, -1000)
        }
        else if (InStr(resumeState, "AutoClerk=1"))
        {
            SetTimer(ResumeAutoClerkFromReload, -1500)
        }
        
        if (InStr(resumeState, "ShowSafetyAlert=1"))
        {
            SetTimer(ShowSafetyAlertMsg, -2000)
        }
        
        if (InStr(resumeState, "ShowDesignatedLotAlert=1"))
        {
            SetTimer(ShowDesignatedLotAlertMsg, -2000)
        }

        if (InStr(resumeState, "ShowOneHourPauseAlert=1"))
        {
            SetTimer(ShowOneHourPauseAlertMsg, -1000)
        }
        
        if (InStr(resumeState, "ShowF4ReloadAlert=1"))
        {
            SetTimer(ShowF4ReloadAlarmMsg, -1000)
        }
    }
}

global SafetyAlertAlarmActive := false
global SafetyAlertGui := ""
global SafetyAlertSoundLoopMs := 4300

ShowSafetyAlertMsg()
{
    global SafetyAlertAlarmActive, SafetyAlertGui
    SafetyAlertAlarmActive := true

    try
    {
        if IsObject(SafetyAlertGui)
            SafetyAlertGui.Destroy()
    }

    SafetyAlertGui := Gui("+AlwaysOnTop +ToolWindow", "Limit Reached")
    SafetyAlertGui.BackColor := "0B0F0C"
    SafetyAlertGui.SetFont("s10 c00FF66 Bold", "Segoe UI")
    SafetyAlertGui.AddText("x14 y14 w302 h46 cFF4444 Center", "WE GOT A BID!`nBOT STOPPED - CHECK BE/LE")
    okBtn := SafetyAlertGui.AddButton("x120 y72 w90 h28 Default", "OK")
    okBtn.OnEvent("Click", StopSafetyAlertMsg)
    SafetyAlertGui.OnEvent("Close", StopSafetyAlertMsg)
    SafetyAlertGui.Show("w330 h112")

    PlaySafetyAlertAlarm()
}

StopSafetyAlertMsg(*)
{
    global SafetyAlertAlarmActive, SafetyAlertGui
    SafetyAlertAlarmActive := false
    SetTimer(PlaySafetyAlertAlarm, 0)
    try SoundPlay("*-1")
    try
    {
        if IsObject(SafetyAlertGui)
            SafetyAlertGui.Destroy()
    }
    SafetyAlertGui := ""
}

PlaySafetyAlertAlarm()
{
    global SafetyAlertAlarmActive, SafetyAlertSoundLoopMs
    if (!SafetyAlertAlarmActive)
        return

    soundPath := A_ScriptDir "\nakabenta.mp3"
    if FileExist(soundPath)
    {
        try
        {
            SoundPlay(soundPath)
        }
        catch
        {
            SoundBeep(1200, 180)
        }
    }
    else
    {
        SoundBeep(1200, 180)
    }

    if (SafetyAlertAlarmActive)
        SetTimer(PlaySafetyAlertAlarm, -SafetyAlertSoundLoopMs)
}

ShowDesignatedLotAlertMsg()
{
    Loop 3 {
        SoundBeep(1000, 200)
        Sleep(100)
    }
    MsgBox("Reached the Designated Lot", "Goal Met", "Iconi")
}

global OneHourPauseAlertGui := ""

ShowOneHourPauseAlertMsg()
{
    global OneHourPauseAlertGui

    try
    {
        if IsObject(OneHourPauseAlertGui)
            OneHourPauseAlertGui.Destroy()
    }

    Loop 2 {
        SoundBeep(900, 150)
        Sleep(80)
    }

    OneHourPauseAlertGui := Gui("+AlwaysOnTop +ToolWindow", "FastBid Pause")
    OneHourPauseAlertGui.BackColor := "101010"
    OneHourPauseAlertGui.SetFont("s11 cFFFFFF Bold", "Segoe UI")
    OneHourPauseAlertGui.AddText("x16 y14 w250 Center", "1 hour passed, pausing")
    OneHourPauseAlertGui.SetFont("s9 cBBBBBB", "Segoe UI")
    OneHourPauseAlertGui.AddText("x16 y44 w250 Center", "Bot will resume at :00")
    OneHourPauseAlertGui.Show("w282 h82 NoActivate")
}

CloseOneHourPauseAlert()
{
    global OneHourPauseAlertGui
    try
    {
        if IsObject(OneHourPauseAlertGui)
            OneHourPauseAlertGui.Destroy()
    }
    OneHourPauseAlertGui := ""
}

global F4ReloadAlarmActive := false

ShowF4ReloadAlarmMsg()
{
    global F4ReloadAlarmActive
    F4ReloadAlarmActive := true
    SetTimer(PlayF4AlarmSound, 6000)
    PlayF4AlarmSound()
    SetTimer(CheckF4ReloadLotTransition, 500)
    
    result := MsgBox("Reloaded", "F4 Force Reload", "Iconi")
    if (result == "OK" || result == "Timeout")
    {
        StopF4ReloadAlarm()
    }
}

PlayF4AlarmSound()
{
    global F4ReloadAlarmActive
    if (F4ReloadAlarmActive)
    {
        SoundPlay(A_ScriptDir "\RELOAD.mp3")
    }
}

CheckF4ReloadLotTransition()
{
    global F4ReloadAlarmActive, CurrentActiveLotID, lastAutoClerkLotToken
    if (!F4ReloadAlarmActive)
    {
        SetTimer(CheckF4ReloadLotTransition, 0)
        return
    }
    
    if (CurrentActiveLotID != "" && lastAutoClerkLotToken != "" && CurrentActiveLotID != lastAutoClerkLotToken)
    {
        if WinExist("F4 Force Reload ahk_class #32770")
            WinClose("F4 Force Reload ahk_class #32770")
        StopF4ReloadAlarm()
    }
}

StopF4ReloadAlarm()
{
    global F4ReloadAlarmActive
    F4ReloadAlarmActive := false
    SetTimer(PlayF4AlarmSound, 0)
    SetTimer(CheckF4ReloadLotTransition, 0)
    try SoundPlay("NonExistent.mp3")
}

ResumeAutoClerkFromReload()
{
    global autoClerkActive, AutoClerkToggleBtn, SessionClockText
    global autoClerkPhase, autoClerkWaitMs, f10TriggerTime, pacingTargetAbsoluteLotMark
    global lastAutoClerkLotToken, CurrentActiveLotID
    global f10F11PressLock, f10F11LockAskValue

    CloseOneHourPauseAlert()
    
    ; Force clear locks on reload to prevent deadlock
    f10F11PressLock := false
    f10F11LockAskValue := ""
    
    ; Check current ask first to decide the next step
    askRaw := ReadCurrentAskPrice()
    askNum := NormalizeToNumber(askRaw)
    
    finalClean := IsObject(CalcFinalText) ? RegExReplace(CalcFinalText.Text, "[^\d\.]") : ""
    finalNum := finalClean != "" ? finalClean + 0 : 0
    
    if (finalNum > 0 && askNum < finalNum && autoClerkPhase = "WAITING")
    {
        autoClerkPhase := "PLAYING" ; Reset to playing if price is below final
    }
    
    autoClerkActive := true
    
    if (CurrentActiveLotID != "")
        lastAutoClerkLotToken := CurrentActiveLotID
    
    if (pacingTargetAbsoluteLotMark > 0)
    {
        RecalibratePacing()
        SetTimer(RecalibratePacing, 1000)
        SetTimer(UpdatePacingMonitor, 50)
    }
    
    if (autoClerkPhase = "WAITING" && f10TriggerTime > 0)
    {
        remainingMs := autoClerkWaitMs - (A_TickCount - f10TriggerTime)
        remainingSec := Max(1, Ceil(remainingMs / 1000))
        StartCountdown(remainingSec, false) ; Visual only on resume
    }
    
    if IsObject(SessionClockText)
        SessionClockText.Text := "BOT: PLAYING"
    if IsObject(AutoClerkToggleBtn)
        AutoClerkToggleBtn.Text := "⏹"
    SetTimer(AutoClerkTick, GetSpamDelay(100))
    ToolTip("AutoClerk Resumed!")
    SetTimer(() => ToolTip(), -2000)
}

ResumeAutoClerkAtNextHour()
{
    global SessionClockText, AutoClerkToggleBtn, CalcTimerText, PacingProgressText

    phTime := GetPHTime()
    currentMin := (phTime != "") ? SubStr(phTime, 11, 2) : ""

    if IsPacingPauseMinute(currentMin)
    {
        if IsObject(SessionClockText)
            SessionClockText.Text := "BOT: WAITING :00"
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "BOT: WAITING :00"
        if IsObject(PacingProgressText)
        {
            PacingProgressText.Text := "WAITING :00"
            PacingProgressText.SetFont("cFFD166")
        }
        if IsObject(AutoClerkToggleBtn)
            AutoClerkToggleBtn.Text := "⏸"
        SetTimer(ResumeAutoClerkAtNextHour, -1000)
        return
    }

    ResumeAutoClerkFromReload()
}

IsPacingPauseMinute(minute := "")
{
    if (minute = "")
    {
        phTime := GetPHTime()
        minute := (phTime != "") ? SubStr(phTime, 11, 2) : ""
    }
    return (minute = "59")
}

End::
{
    ForceTempLowSession()
}


SignalRepeatCurrentF8Step()
{
    global repeatF8SignalFile

    try
    {
        if FileExist(repeatF8SignalFile)
            FileDelete(repeatF8SignalFile)
        FileAppend(A_TickCount, repeatF8SignalFile)
    }
}

SignalComboCycleReset()
{
    global comboCycleResetFile

    try
    {
        if FileExist(comboCycleResetFile)
            FileDelete(comboCycleResetFile)
        FileAppend(A_TickCount, comboCycleResetFile)
    }
}

LaunchDomHelperLauncher()
{
    ; Fresh start: kill all Node processes first.
    Run('taskkill /F /IM node.exe', , "Hide")
    Sleep(500)

    ; Start extension server (button-state/current-ask endpoints).
    serverPath := A_ScriptDir "\extension-server.js"
    if FileExist(serverPath)
    {
        Run('node "' serverPath '"', A_ScriptDir, "Hide")
        Sleep(800)
    }

    ; Start DOM helper launcher (estimate-reader.js + debug Chrome if needed).
    launcherPath := A_ScriptDir "\LaunchDomHelper.bat"
    if FileExist(launcherPath)
    {
        Run('"' launcherPath '"', A_ScriptDir, "Hide")
        Sleep(1000)
    }
}

InitSessionWindow()
{
            global SessionGui, SessionText, SessionToggleBtn, SessionMinusBtn, SessionPlusBtn, SessionClockText, AutoClerkToggleBtn
    global CalcInput, CalcBaseText, CalcTierText, CalcFinalText, CalcTimerText
    global CalcAmountLabel, CalcBaseLabel, CalcResultLabel, CalcInternetLabel, CalcInternetText, CalcTierLabel, CalcRemapBtn
    global CalcSpamFastRadio, CalcSpamMediumRadio, CalcSpamSlowRadio, CalcPercent1Radio, CalcPercent5Radio, CalcPercent10Radio
    global CalcWaitDropDown, PacingLotsLabel, PacingLotsInput, PacingLPHLabel, PacingLPHInput, PacingMinsLabel, PacingHourDrop, PacingMinDrop, PacingAmPmDrop, PacingToggleBtn, PacingProgressText, PacingNextLabel, PacingHourlyRemainingText, AuctionUIDLinkBtn
    global PacingLPHFrame, PacingLotsFrame, PacingHourFrame, PacingMinFrame
    global timerMuted := false, countdownSeconds := 0, timerActive := false, MuteBtn, CloseBtn

    SessionGui := Gui("+AlwaysOnTop +ToolWindow -Caption", "BidHelper v2 by MAKITATTOO")
    SessionGui.BackColor := "0B0F0C"
    SessionGui.SetFont("s10 c00D94A Bold", "Segoe UI")
    
    ; Transparent-style red close control at top-right of whole window.
    CloseBtn := SessionGui.AddText("x748 y8 w22 h22 cFF4D4F BackgroundTrans Center", "X")
    CloseBtn.SetFont("s13 Bold", "Segoe UI")
    CloseBtn.OnEvent("Click", (*) => ExitApp())
    
    ; Make window draggable
    OnMessage(0x0201, GuiDrag)
    SessionGui.OnEvent("Size", ResizeSessionWindow)
    
    ; === TOP: Session / Controls / Clock ===
    SessionText := SessionGui.AddText("x12 y8 w260 h24 Center", "Auction Tools")
    SessionToggleBtn := SessionGui.AddText("x12 y34 w260 h18 c7F8C83 Center", "Session: 0 [Live]")
    SessionMinusBtn := SessionGui.AddText("x14 y34 w18 h18 c00D94A Center", "-")
    SessionPlusBtn := SessionGui.AddText("x252 y34 w18 h18 c00D94A Center", "+")
    SessionText.SetFont("s11 c00D94A Bold", "Segoe UI")
    SessionToggleBtn.SetFont("s9 c7F8C83 Bold", "Segoe UI")
    SessionMinusBtn.SetFont("s13 c00D94A Bold", "Segoe UI")
    SessionPlusBtn.SetFont("s13 c00D94A Bold", "Segoe UI")
    
    ; === BOT STATUS CONSOLE (Replaces Clock/F8 Steps) ===
    SessionClockText := SessionGui.AddText("x12 y68 w200 h32 c00FF66 Center", "BOT: PAUSED")
    AutoClerkToggleBtn := SessionGui.AddText("x217 y66 w35 h28 c00D94A Background000000 Border Center", "▶")
    AutoClerkToggleBtn.SetFont("s12 c00D94A Bold", "Segoe UI Emoji")
    AutoClerkToggleBtn.OnEvent("Click", ToggleAutoClerk)
    SessionClockText.SetFont("s13 Bold", "Segoe UI")
    
    ; === Calculator Fields ===
    CalcAmountLabel := SessionGui.AddText("x12 y120 w110 h24", "Estimate")
    CalcInput := SessionGui.AddEdit("x122 y116 w150 h31 c00FF66 Background111A13 Center -E0x200")
    
    CalcBaseLabel := SessionGui.AddText("x12 y150 w110 h24", "Bid Estimate")
    CalcBaseText := SessionGui.AddText("x122 y152 w150 h31 c00FF66 Background111A13 Center", "0")
    
    CalcResultLabel := SessionGui.AddText("x12 y180 w110 h24", "Final")
    CalcFinalText := SessionGui.AddText("x122 y188 w150 h31 c00FF66 Background111A13 Center", "0")
    
    CalcInternetLabel := SessionGui.AddText("x12 y215 w110 h24", "Internet")
    CalcInternetText := SessionGui.AddText("x122 y222 w150 h31 cFFD700 Background111A13 Center", "$0")
    CalcInternetLabel.SetFont("s10 cFFD700 Bold", "Segoe UI")
    CalcInternetText.SetFont("s14 cFFD700 Bold", "Segoe UI")
    
    ; Timer button where Next was - shows countdown when muted
    CalcTimerText := SessionGui.AddText("x12 y240 w200 h22 c00D94A", "BOT: PAUSED")
    CalcTimerText.SetFont("s10 Bold", "Segoe UI")
    
    ; Mute button
    MuteBtn := SessionGui.AddText("x220 y238 w50 h26 c00D94A Background000000 Border Center", "🔊")
    MuteBtn.SetFont("s13 c00D94A Bold", "Segoe UI Emoji")
    MuteBtn.OnEvent("Click", ToggleMute)
    
    ; Settings button for ladder editor
    SettingsBtn := SessionGui.AddText("x20 y295 w158 h24 c00D94A Background000000 Border Center", "⚙ LADDER SETTINGS")
    SettingsBtn.SetFont("s9 c00D94A Bold", "Segoe UI")
    SettingsBtn.OnEvent("Click", (*) => OpenF8LadderSettings())
    
    CalcPercent1Radio := SessionGui.AddRadio("x150 y620 w68 h22 Group Hidden", "1%")
    CalcPercent5Radio := SessionGui.AddRadio("x150 y652 w68 h22 Hidden", "5%")
    CalcPercent10Radio := SessionGui.AddRadio("x150 y684 w68 h22 Checked Hidden", "10%")
    
    PacingLPHLabel := SessionGui.AddText("c00D94A BackgroundTrans", "LPH:")
    PacingLPHLabel.SetFont("s10 c00D94A Bold", "Segoe UI")
    tgtLPHMem := ""
    try tgtLPHMem := IniRead(A_ScriptDir "\AuctionSessions.ini", "Pacing", "TargetLPH", "")
    PacingLPHFrame := SessionGui.AddText("Background00D94A")
    PacingLPHInput := SessionGui.AddEdit("c00FF66 Background111A13 Center -E0x200", tgtLPHMem)
    PacingLPHInput.SetFont("s10 Bold", "Segoe UI")
    PacingNextLabel := SessionGui.AddText("c00FF66 BackgroundTrans", "Calc")
    PacingNextLabel.SetFont("s10 Bold", "Segoe UI")
    AuctionUIDLinkBtn := SessionGui.AddText("c00D94A Background000000 Border Center +0x200", "EOA")
    AuctionUIDLinkBtn.SetFont("s11 c00D94A Bold", "Segoe UI")
    AuctionUIDLinkBtn.OnEvent("Click", OpenCurrentAuctionUIDLink)


    ; Auto-Clerk Wait Selection (DropDownList: 6s - 60s)
    CalcWaitDropDown := SessionGui.AddComboBox("x12 y751 w192 h22 Choose1", ["6s (DEFAULT)","10s","15s","20s","25s","30s","35s","40s","45s","50s","55s","60s"])
    ; CalcCountdownText removed - using timer.mp3 instead
    
    ; === ROW 8: Remap Button ===
    CalcRemapBtn := SessionGui.AddText("x12 y331 w260 h36 c00D94A Background000000 Border Center Hidden", "Remap")
    
    
    ; === ROW 15-17: Speed Selection ===
    CalcSpamFastRadio := SessionGui.AddRadio("x12 y620 w54 h22 Checked", "⚡ Fast")
    CalcSpamMediumRadio := SessionGui.AddRadio("x70 y620 w62 h22 Hidden", "Medium")
    CalcSpamSlowRadio := SessionGui.AddRadio("x136 y620 w48 h22 Hidden", "Slow")
    CalcSpamFastRadio.Opt("+Hidden")


    ; Typography cleanup for consistent visual weight.



    ; Typography cleanup for consistent visual weight.
    CalcAmountLabel.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcBaseLabel.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcResultLabel.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcInput.SetFont("s14 c00FF66 Bold", "Segoe UI")
    CalcBaseText.SetFont("s14 c00FF66 Bold", "Segoe UI")
    CalcFinalText.SetFont("s15 c00FF66 Bold", "Segoe UI")
    CalcRemapBtn.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcPercent1Radio.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcPercent5Radio.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcPercent10Radio.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcSpamSlowRadio.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcSpamMediumRadio.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcSpamFastRadio.SetFont("s10 c00D94A Bold", "Segoe UI")
    CalcWaitDropDown.SetFont("s10 c00D94A Bold", "Segoe UI")
    
    PacingLotsLabel := SessionGui.AddText("c00D94A BackgroundTrans", "Stop Lot:")
    tgtLotsMem := ""
    tgtHourMem := 6
    tgtMinMem  := 1
    tgtAmPmMem := 2
    
    ; NEW: Always check General first for F4 reliability
    iniFile := A_ScriptDir "\AuctionSessions.ini"
    try tgtLotsMem := IniRead(iniFile, "Pacing_General", "TargetLots", "")
    try tgtHourMem := IniRead(iniFile, "Pacing_General", "TargetHour", 6)
    try tgtMinMem  := IniRead(iniFile, "Pacing_General", "TargetMin", 1)
    try tgtAmPmMem := IniRead(iniFile, "Pacing_General", "TargetAmPm", 2)
    
    ; Try specific auction if possible
    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
    if (auctionId != "General")
    {
        try tgtLotsMem := IniRead(iniFile, "Pacing_" auctionId, "TargetLots", tgtLotsMem)
        try tgtHourMem := IniRead(iniFile, "Pacing_" auctionId, "TargetHour", tgtHourMem)
        try tgtMinMem  := IniRead(iniFile, "Pacing_" auctionId, "TargetMin", tgtMinMem)
        try tgtAmPmMem := IniRead(iniFile, "Pacing_" auctionId, "TargetAmPm", tgtAmPmMem)
    }

    PacingLotsFrame := SessionGui.AddText("Background00D94A")
    PacingHourFrame := SessionGui.AddText("Background00D94A")
    PacingMinFrame := SessionGui.AddText("Background00D94A")
    PacingLotsInput := SessionGui.AddEdit("c00FF66 Background111A13 Center Number -E0x200", tgtLotsMem)
    PacingMinsLabel := SessionGui.AddText("c00D94A BackgroundTrans", "PH Time (GMT+8):")
    PacingHourDrop  := SessionGui.AddEdit("c00FF66 Background111A13 Center Number -E0x200", Clamp(Integer(tgtHourMem), 1, 12))
    PacingMinDrop   := SessionGui.AddEdit("c00FF66 Background111A13 Center Number -E0x200", Format("{:02}", Clamp(Integer(tgtMinMem) - 1, 0, 59)))
    amPmText := (Integer(tgtAmPmMem) = 2) ? "PM" : "AM"
    PacingAmPmDrop  := SessionGui.AddText("c00FF66 Background000000 Border Center", amPmText)
    
    PacingHourDrop.OnEvent("Change", PacingTimeChanged)
    PacingMinDrop.OnEvent("Change", PacingTimeChanged)
    PacingAmPmDrop.OnEvent("Click", TogglePacingAmPm)
    PacingToggleBtn := SessionGui.AddText("c00D94A Background000000 Border Center", "BOT LOCK")
    PacingToggleBtn.SetFont("s11 c00D94A Bold", "Segoe UI")
    PacingToggleBtn.OnEvent("Click", TogglePacing)
    PacingLotsLabel.SetFont("s9 c00D94A Bold", "Segoe UI")
    PacingMinsLabel.SetFont("s9 c00D94A Bold", "Segoe UI")
    
    PacingProgressText := SessionGui.AddText("c00FF66 BackgroundTrans Center", "Lots: RUNNING")
    PacingProgressText.SetFont("s8 c00FF66", "Segoe UI")

    PacingHourlyRemainingText := SessionGui.AddText("c00FF66 BackgroundTrans Left", "Lots: --")
    PacingHourlyRemainingText.SetFont("s8 c00FF66", "Segoe UI")

    ApplyUILayout()
    UpdateAuctionUIDLinkButton()

    ; Event handlers
    PacingLPHInput.OnEvent("Change", PacingLPHChanged)
    PacingLotsInput.OnEvent("Change", PacingLotsChanged)
    SessionToggleBtn.OnEvent("Click", ToggleSessionCountPaused)
    SessionMinusBtn.OnEvent("Click", DecreaseSessionCount)
    SessionPlusBtn.OnEvent("Click", IncreaseSessionCount)
    CalcInput.OnEvent("Change", UpdateCalculatorWindow)
    CalcSpamFastRadio.OnEvent("Click", SetSpamFastMode)
    CalcSpamMediumRadio.OnEvent("Click", SetSpamMediumMode)
    CalcSpamSlowRadio.OnEvent("Click", SetSpamSlowMode)
    CalcPercent1Radio.OnEvent("Click", SetPercent1Mode)
    CalcPercent5Radio.OnEvent("Click", SetPercent5Mode)
    CalcPercent10Radio.OnEvent("Click", SetPercent10Mode)
    CalcWaitDropDown.OnEvent("Change", SetWaitModeFromDropDown)
    global isLoadingSettings
    isLoadingSettings := true ; Ensure lock is on during build
    
    ; Load saved calculator value on startup
    LoadSessionCount()
    LoadSpeedMode()
    LoadPercentMode()
    LoadWaitMode() ; Load Auto-Clerk wait preference
    
    UpdateSessionWindow()
    UpdateCalculatorWindow()
    ; Remove Next display - replaced with timer
    ; UpdateNextF8Display()  ; Disabled
    SessionGui.Show(GetSavedWindowShowOptions())
    SessionGui.GetPos(, , &startW, &startH)
    ResizeSessionWindow(SessionGui, 0, startW, startH)
}

UpdateSessionWindow()
{
    global SessionText, SessionToggleBtn, pressCount, scriptPaused, pauseCountSession, sessionCountPaused

    displaySession := pressCount
    statusText := scriptPaused ? "Off Tab" : "Live"
    if sessionCountPaused
        statusText .= ", Count Paused"
    if (pressCount >= 11 && pauseCountSession)
    {
        displaySession := 10
        statusText := "TEMPORARY"
    }

    if IsObject(SessionText)
        SessionText.Text := "Auction Tools"

    if IsObject(SessionToggleBtn)
    {
        if (statusText = "TEMPORARY")
        {
            SessionToggleBtn.Text := "TEMPORARY"
            SessionToggleBtn.SetFont("c7F8C83")
        }
        else
        {
            SessionToggleBtn.Text := "Session: " displaySession " [" statusText "]"
            SessionToggleBtn.SetFont("c00D94A")
        }
    }

}

SaveSessionCount()
{
    global pressCount, CurrentAuctionUID
    
    ; Identify which auction this progress belongs to
    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"

    iniFile := A_ScriptDir "\AuctionSessions.ini"
    try 
    {
        IniWrite(pressCount, iniFile, "Sessions", auctionId)
        IniWrite(A_YYYY A_MM A_DD, iniFile, "Timestamps", auctionId)
    }
}

LoadSessionCount()
{
    global pressCount, CurrentAuctionUID, reloadStateRestored
    global PacingLPHInput, PacingLotsInput, PacingHourDrop, PacingMinDrop, PacingAmPmDrop, isLoadingSettings
    global pacingLotAutoValue, pacingLotManualOverride, pacingLotAutoUpdating
    global lotAtTopOfHour, lastHourTracked, pacingStartLot, pacingStartTime, hourDeficit, pacingTargetAbsoluteLotMark, pacingAbsoluteDeadline, PacingToggleBtn
    global pacingHourKey, pacingHourStartLot, pacingHourQuota, pacingHourBaseCap, pacingHourTargetLot, pacingCarryDebt
    global reloadPreservedPacingTarget
    
    if (reloadStateRestored && pressCount > 1)
    {
        reloadStateRestored := false
        return
    }
    reloadStateRestored := false ; Clear it anyway if it was 1 or less
    
    ; Identify which auction to load for
    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"

    iniFile := A_ScriptDir "\AuctionSessions.ini"
    if !FileExist(iniFile)
        return

    try 
    {
        ; --- 2-DAY PERSISTENCE LOGIC ---
        saveDate := IniRead(iniFile, "Timestamps", auctionId, "")
        currentDate := A_YYYY A_MM A_DD
        
        if (saveDate != "")
        {
            ; Calculate days between today and the last save
            daysPassed := DateDiff(currentDate, saveDate, "days")
            
            ; Reset only if more than 2 days have passed
            if (daysPassed > 2)
            {
                pressCount := 1
                SaveSessionCount()
                UpdateSessionWindow()
                return
            }
        }

        val := IniRead(iniFile, "Sessions", auctionId, "OFF")
        if (val != "OFF")
        {
            pressCount := Integer(val)
            if (pressCount < 1) pressCount := 1
            if (pressCount > 14) pressCount := 1
            UpdateSessionWindow()
        }
        
        ; Always ensure we have today's timestamp if we successfully loaded a session
        if (saveDate == "")
            SaveSessionCount()
            
        ; --- LOAD PACING SETTINGS FOR THIS AUCTION ---
        isLoadingSettings := true ; START GUARD
        
        ; Only overwrite UI if a saved value actually exists (avoiding the 'reset to blank' on new UID)
        savedLPH := IniRead(iniFile, "Pacing_" auctionId, "TargetLPH", "SKIP")
        if (savedLPH != "SKIP" && IsObject(PacingLPHInput))
            PacingLPHInput.Value := savedLPH
            
        shouldAutoCalcLotAfterLoad := false
        savedLots := IniRead(iniFile, "Pacing_" auctionId, "TargetLots", "SKIP")
        savedLotsManual := Integer(IniRead(iniFile, "Pacing_" auctionId, "TargetLotsManual", 0))
        if (pacingTargetAbsoluteLotMark > 0 && IsObject(PacingLotsInput))
        {
            pacingLotAutoUpdating := true
            pacingLotAutoValue := pacingTargetAbsoluteLotMark . ""
            PacingLotsInput.Value := pacingLotAutoValue
            pacingLotAutoUpdating := false
            pacingLotManualOverride := false
        }
        else if (reloadPreservedPacingTarget > 0 && IsObject(PacingLotsInput))
        {
            pacingLotAutoUpdating := true
            pacingLotAutoValue := reloadPreservedPacingTarget . ""
            PacingLotsInput.Value := pacingLotAutoValue
            pacingLotAutoUpdating := false
            pacingLotManualOverride := true
        }
        else if (savedLots != "SKIP" && Trim(savedLots) != "" && savedLotsManual && IsObject(PacingLotsInput))
        {
            PacingLotsInput.Value := savedLots
            pacingLotAutoValue := savedLots
            pacingLotManualOverride := true
        }
        else if IsObject(PacingLotsInput)
        {
            PacingLotsInput.Value := ""
            pacingLotAutoValue := ""
            pacingLotManualOverride := false
            shouldAutoCalcLotAfterLoad := true
        }
            
        savedHour := IniRead(iniFile, "Pacing_" auctionId, "TargetHour", "SKIP")
        if (savedHour != "SKIP" && IsObject(PacingHourDrop))
            PacingHourDrop.Value := Clamp(Integer(savedHour), 1, 12)
            
        savedMin := IniRead(iniFile, "Pacing_" auctionId, "TargetMin", "SKIP")
        if (savedMin != "SKIP" && IsObject(PacingMinDrop))
            PacingMinDrop.Value := Format("{:02}", Clamp(Integer(savedMin) - 1, 0, 59))
            
        savedAmPm := IniRead(iniFile, "Pacing_" auctionId, "TargetAmPm", "SKIP")
        if (savedAmPm != "SKIP" && IsObject(PacingAmPmDrop))
            PacingAmPmDrop.Text := (Integer(savedAmPm) = 2) ? "PM" : "AM"
            
        ; --- RESTORE HOUR TRACKING STATE ---
        lotAtTopOfHour  := Integer(IniRead(iniFile, "Pacing_" auctionId, "StartLotOfHour", -1))
        lastHourTracked := Integer(IniRead(iniFile, "Pacing_" auctionId, "LastHourTracked", -1))
        hourDeficit     := Integer(IniRead(iniFile, "Pacing_" auctionId, "HourDeficit", 0))
        pacingHourKey := IniRead(iniFile, "Pacing_" auctionId, "PacingHourKey", "")
        pacingHourStartLot := Integer(IniRead(iniFile, "Pacing_" auctionId, "PacingHourStartLot", 0))
        pacingHourQuota := Integer(IniRead(iniFile, "Pacing_" auctionId, "PacingHourQuota", 0))
        pacingHourBaseCap := Integer(IniRead(iniFile, "Pacing_" auctionId, "PacingHourBaseCap", 0))
        pacingHourTargetLot := Integer(IniRead(iniFile, "Pacing_" auctionId, "PacingHourTargetLot", 0))
        pacingCarryDebt := Integer(IniRead(iniFile, "Pacing_" auctionId, "PacingCarryDebt", 0))
        
        savedStartLot := IniRead(iniFile, "Pacing_" auctionId, "SessionStartLot", -1)
        if (savedStartLot != -1)
            pacingStartLot := Integer(savedStartLot)
            
        savedStartTime := IniRead(iniFile, "Pacing_" auctionId, "SessionStartTime", "")
        if (savedStartTime != "")
            pacingStartTime := savedStartTime

        savedDeadline := IniRead(iniFile, "Pacing_" auctionId, "Deadline", "")
        if (savedDeadline != "")
            pacingAbsoluteDeadline := savedDeadline

        ; Saved target values refill the UI only. A normal script start should
        ; not auto-lock the bot; F4 recovery uses the temp resume file above.
        if (pacingTargetAbsoluteLotMark <= 0)
        {
            pacingTargetAbsoluteLotMark := 0
            pacingAbsoluteDeadline := ""
            pacingStartTime := ""
        }
            
        isLoadingSettings := false ; END GUARD
        if (shouldAutoCalcLotAfterLoad)
            UpdateCalculatedStopLot(true)
    }
}

GetSavedWindowShowOptions()
{
    global windowPosSaveFile

    defaultOptions := "x20 y20 w320 h185 NoActivate"
    if !FileExist(windowPosSaveFile)
        return defaultOptions

    try
    {
        savedValue := Trim(FileRead(windowPosSaveFile))
        parts := StrSplit(savedValue, ",")
        if (parts.Length != 2)
            return defaultOptions

        savedX := Integer(Trim(parts[1]))
        savedY := Integer(parts[2])
        return "x" savedX " y" savedY " w320 h185 NoActivate"
    }
    catch
    {
        return defaultOptions
    }
}

SaveSessionWindowPosition()
{
    global SessionGui, windowPosSaveFile

    if !IsObject(SessionGui)
        return

    try
    {
        SessionGui.GetPos(&savedX, &savedY)
        if FileExist(windowPosSaveFile)
            FileDelete(windowPosSaveFile)
        FileAppend(savedX "," savedY, windowPosSaveFile)
    }
}

UpdateSessionVisibility()
{
    global SessionGui

    if !IsObject(SessionGui)
        return

    ; User requested: always show the GUI even when not in Chrome
    SessionGui.Show("NoActivate")
}

ResizeSessionWindow(guiObj, minMax, width, height)
{
    ApplyUILayout(minMax)
}

ApplyUILayout(minMax := 0)
{
    global SessionGui, SessionText, SessionToggleBtn, SessionMinusBtn, SessionPlusBtn, SessionClockText, CloseBtn, AutoClerkToggleBtn
    global CalcAmountLabel, CalcBaseLabel, CalcResultLabel
    global CalcInput, CalcBaseText, CalcFinalText, CalcInternetLabel, CalcInternetText, CalcTimerText, MuteBtn
    global CalcRemapBtn
    global CalcSpamSlowRadio, CalcSpamMediumRadio, CalcSpamFastRadio
    global CalcPercent1Radio, CalcPercent5Radio, CalcPercent10Radio
    global CalcWaitDropDown, PacingLotsLabel, PacingLotsInput, PacingMinsLabel, PacingHourDrop, PacingMinDrop, PacingAmPmDrop, PacingApplyBtn, PacingStopBtn, PacingProgressText, PacingLPHLabel, PacingLPHInput, PacingToggleBtn, PacingNextLabel, PacingHourlyRemainingText, AuctionUIDLinkBtn
    global PacingLPHFrame, PacingLotsFrame, PacingHourFrame, PacingMinFrame

    if (minMax = -1)
        return

    ; --- COMPACT VERTICAL STATUS DASHBOARD ---
    fullW := 198
    CloseBtn.Move(fullW - 20, 1, 18, 20)
    CloseBtn.SetFont("s10 Bold")
    
    margin := 8
    boxW := fullW - (margin * 2)
    topY := 16
    off := 2000

    ; Session row
    SessionMinusBtn.Move(margin, 3, 20, 22)
    SessionToggleBtn.Move(32, 3, 126, 22)
    SessionPlusBtn.Move(160, 3, 18, 22)
    SessionToggleBtn.SetFont("s9 c00D94A Bold")

    ; Main number stack. FINAL stays alive off-screen for bot calculations.
    CalcBaseLabel.Text := "BID EST"
    CalcInternetLabel.Text := "INTERNET"
    CalcBaseLabel.Move(margin, 30, boxW, 12)
    CalcResultLabel.Move(off, off)
    CalcInternetLabel.Move(margin, 85, boxW, 12)
    CalcBaseLabel.SetFont("s7 c7F8C83")
    CalcInternetLabel.SetFont("s7 c7F8C83")

    CalcBaseText.Move(margin, 43, boxW, 38)
    CalcBaseText.SetFont("s15 Bold")

    CalcFinalText.Move(off, off)

    CalcInternetText.Move(margin, 98, boxW, 38)
    CalcInternetText.SetFont("s15 Bold")

    ; Bot timer row. The old small LPH status is hidden because the larger
    ; bottom status label now shows RELAXING/RUSHING/SLOWING/WORKING.
    SessionClockText.Move(off, off)

    PacingNextLabel.Move(margin, 143, 112, 24)
    PacingNextLabel.SetFont("s12 Bold")
    if IsObject(AuctionUIDLinkBtn)
    {
        AuctionUIDLinkBtn.Move(124, 143, 66, 24)
        AuctionUIDLinkBtn.SetFont("s11 c00D94A Bold")
    }

    ; Pace settings row
    PacingLPHLabel.Text := "LPH"
    PacingLPHLabel.Move(margin, 172, 28, 20)
    PacingLPHLabel.SetFont("s9 c00D94A Bold")
    PacingLPHFrame.Move(40, 170, 46, 24)
    PacingLPHInput.Move(42, 172, 42, 20)
    PacingLPHInput.SetFont("s10 Bold")

    if IsObject(PacingHourlyRemainingText)
    {
        PacingHourlyRemainingText.Move(102, 170, 64, 24)
        PacingHourlyRemainingText.SetFont("s9 Bold")
    }

    if IsObject(AutoClerkToggleBtn)
    {
        AutoClerkToggleBtn.Move(170, 168, 20, 24)
        AutoClerkToggleBtn.SetFont("s10 c00D94A Bold")
    }

    if IsObject(CalcWaitDropDown)
        CalcWaitDropDown.Move(off, off)

    ; Stop lot row
    PacingLotsFrame.Move(margin, 201, 74, 24)
    PacingLotsInput.Move(margin + 2, 203, 70, 20)
    PacingLotsInput.SetFont("s10 Bold")
    if IsObject(PacingToggleBtn)
    {
        PacingToggleBtn.Move(94, 201, 96, 24)
        PacingToggleBtn.SetFont("s9 Bold")
    }

    ; PH deadline row
    PacingHourFrame.Move(margin, 232, 42, 24)
    PacingHourDrop.Move(margin + 2, 234, 38, 20)
    PacingHourDrop.SetFont("s10 Bold")
    PacingMinsLabel.Text := ":"
    PacingMinsLabel.Move(54, 234, 8, 20)
    PacingMinsLabel.SetFont("s11 c00D94A Bold")
    PacingMinFrame.Move(66, 232, 42, 24)
    PacingMinDrop.Move(68, 234, 38, 20)
    PacingMinDrop.SetFont("s10 Bold")
    PacingAmPmDrop.Move(122, 232, 68, 24)
    PacingAmPmDrop.SetFont("s10 c00FF66 Bold")

    PacingProgressText.Move(margin, 260, boxW, 28)
    PacingProgressText.SetFont("s13 Bold")

    ; HIDE ALL OTHER CONTROLS (Move off-screen)
    SessionText.Move(off, off)
    CalcRemapBtn.Move(off, off)
    CalcAmountLabel.Move(off, off)
    CalcInput.Move(off, off)
    CalcTimerText.Move(off, off)
    MuteBtn.Move(off, off)
    CalcSpamFastRadio.Move(off, off)
    CalcSpamMediumRadio.Move(off, off)
    CalcSpamSlowRadio.Move(off, off)
    CalcPercent1Radio.Move(off, off)
    CalcPercent5Radio.Move(off, off)
    CalcPercent10Radio.Move(off, off)
    PacingLotsLabel.Move(off, off)

    ; Dynamic Window Sizing
    if (minMax != -1)
    {
        SessionGui.Show("w198 h324 NoActivate")
    }
}

InitCalculatorWindow()
{
    return
}

UpdateCalculatorWindow(*)
{
    global CalcInput, CalcBaseText, CalcFinalText

    rawValue := IsObject(CalcInput) ? CalcInput.Value : ""
    cleanedValue := RegExReplace(rawValue, "[^\d\.]")
    divisor := 1.3

    if (
        cleanedValue = ""
        || !RegExMatch(cleanedValue, "^\d*\.?\d*$")
    )
    {
        if IsObject(CalcBaseText)
            CalcBaseText.Text := "BE"
        if IsObject(CalcFinalText)
            CalcFinalText.Text := "---"
        SaveCurrentFinalValue("")
        return
    }

    amount := cleanedValue + 0
    if IsObject(CalcInput)
    {
        formattedEstimate := FormatNumberWithCommas(amount)
        if (CalcInput.Value != formattedEstimate)
            CalcInput.Value := formattedEstimate
    }
    baseValue := Round(amount / divisor, 0)
    finalValue := CalculateFinalValue(baseValue)

    if IsObject(CalcBaseText)
        CalcBaseText.Text := FormatNumberWithCommas(baseValue)

    if IsObject(CalcFinalText)
        CalcFinalText.Text := FormatNumberWithCommas(finalValue)

    ; Update progressiveLastFinalValue for accurate F8 bidding
    global progressiveLastFinalValue
    progressiveLastFinalValue := finalValue

    SaveCurrentFinalValue(finalValue)
}

; Format number with thousand separators
FormatNumberWithCommas(number)
{
    if (number = "" || number = 0)
        return "0"
    
    ; Convert to integer
    num := Integer(number)
    if (num = 0)
        return "0"
    
    ; Build string with commas
    result := ""
    negative := false
    
    if (num < 0)
    {
        negative := true
        num := -num
    }
    
    digitCount := 0
    while (num > 0)
    {
        if (digitCount > 0 && Mod(digitCount, 3) = 0)
            result := "," . result
        digit := Mod(num, 10)
        result := String(digit) . result
        num := num // 10
        digitCount++
    }
    
    if (negative)
        result := "-" . result
    
    return result
}

StartCountdown(seconds := "", playSound := true)
{
    global timerMuted, countdownSeconds, timerActive, CalcTimerText, timerSoundFired, timerCueSeconds
    
    if (seconds = "")
        seconds := timerCueSeconds

    ; Always show visual countdown
    countdownSeconds := seconds
    timerActive := true
    UpdateTimerDisplay()
    SetTimer(UpdateCountdown, 1000)
    
    ; Also play sound if requested and not already fired
    if (playSound && !timerMuted && !timerSoundFired)
    {
        if PlayTimerSound()
            timerSoundFired := true
    }
}

UpdateTimerDisplay()
{
    global CalcTimerText, countdownSeconds, timerActive
    if IsObject(CalcTimerText)
    {
        if (timerActive && countdownSeconds >= 0)
            CalcTimerText.Text := "TIMER: " countdownSeconds "s"
        else
            CalcTimerText.Text := "TIMER"
    }
}

UpdateCountdown()
{
    global countdownSeconds, timerActive
    countdownSeconds--
    UpdateTimerDisplay()
    
    if (countdownSeconds <= 0)
    {
        timerActive := false
        SetTimer(UpdateCountdown, 0)  ; Stop timer
    }
}

ToggleMute(*)
{
    global timerMuted, MuteBtn
    timerMuted := !timerMuted
    
    if IsObject(MuteBtn)
    {
        if (timerMuted)
            MuteBtn.Text := "🔇"
        else
            MuteBtn.Text := "🔊"
    }
}

PlayTimerSound()
{
    ; Play timer.mp3 without blocking price updates or system audio
    timerPath := A_ScriptDir "\timer.mp3"
    if FileExist(timerPath)
    {
        try
        {
            SoundPlay(timerPath)
            return true
        }
    }
    return false
}

UpdateCountdownTick()
{
    ; Disabled - no countdown tick
}

UpdateCountdownDisplay()
{
    ; Disabled - no countdown display
}

; Read price from Chrome Extension (no OCR)
ReadPriceFromExtension()
{
    global domEstimateFile

    snapshotPrice := ReadPriceSnapshotField("estimate")
    parsedSnapshotPrice := ParseFirstPriceNumber(snapshotPrice)
    if (parsedSnapshotPrice != "")
        return parsedSnapshotPrice

    if !FileExist(domEstimateFile)
        return ""

    try
    {
        savedValue := Trim(FileRead(domEstimateFile))

        return ParseFirstPriceNumber(savedValue)
    }
    catch
    {
    }

    return ""
}

GetPreferredEstimatePrice(rawPrice := "")
{
    extPrice := ReadPriceFromExtension()
    if (extPrice != "")
        return extPrice

    if (rawPrice != "" && RegExMatch(rawPrice, "(\d+\.?\d*)", &match))
        return match[1]

    return ""
}

; ===============================
; CONTINUOUS EXTENSION MONITORING (replaces OCR)
; ===============================

StartExtensionMonitoring()
{
    global extensionMonitoringActive
    
    if (extensionMonitoringActive)
        return
        
    extensionMonitoringActive := true
    UpdateExtensionCurrentPrice()  ; Immediate first read
    SetTimer(UpdateExtensionCurrentPrice, 50)  ; Every 50ms
}

StopExtensionMonitoring()
{
    global extensionMonitoringActive
    
    extensionMonitoringActive := false
    SetTimer(UpdateExtensionCurrentPrice, 0)  ; Stop timer
}

ToggleExtensionMonitoring()
{
    global extensionMonitoringActive
    
    if (extensionMonitoringActive)
        StopExtensionMonitoring()
    else
        StartExtensionMonitoring()
        
    return extensionMonitoringActive
}

UpdateExtensionCurrentPrice()
{
    global extensionMonitoringActive, lastExtensionPrice, CalcInput
    
    if (!extensionMonitoringActive)
        return
        
    ; Read from Chrome Extension only (no OCR)
    currentPrice := ReadPriceFromExtension()
    
    ; Only update if price changed and is valid
    if (currentPrice != "" && currentPrice != lastExtensionPrice)
    {
        lastExtensionPrice := currentPrice
        UnlockF10F11OnNewAsk(currentPrice)
        
        ; Update calculator Amount field
        if (IsObject(CalcInput))
        {
            CalcInput.Value := currentPrice
            UpdateCalculatorWindow()
            MarkNewBidSequence()
        }

        ; Auto-launch sub-script based on !!!! value (not raw price)
        cleanedValue := RegExReplace(Trim(currentPrice), "[^\d\.]")
        if (cleanedValue == "")
            return
            
        amount := cleanedValue + 0
        divisor := 1.3
        if (amount > 0)
        {
            baseValue := Round(amount / divisor, 0)         ; Exact result - shown as Bid Estimate
            snappedBase := SnapToAuctionIncrement(baseValue) ; Snapped - used only for F8 targeting
            
            finalValue := CalculateFinalValue(snappedBase)
            
            CalcBaseText.Text := FormatNumberWithCommas(baseValue)   ; Show EXACT (e.g. 15,610)
            CalcFinalText.Text := FormatNumberWithCommas(finalValue)
            LaunchSubScriptByFinalValue(finalValue, 1)
        }
    }
    
    ; Always update the Internet display regardless of ask price changes.
    ; Read direct extension state first so the UI does not lag behind the bot.
    intRaw := ReadInternetBidPrice()
    global lastPersistentInternetPrice, lastInternetBeepPrice, autoClerkPhase
    liveIntRaw := ReadInternetBidPriceFromExtension()
    liveIntNum := NormalizeToNumber(liveIntRaw)
    beepIntNum := liveIntNum
    if (beepIntNum <= 0 && IsPriceSnapshotForCurrentLot())
        beepIntNum := NormalizeToNumber(ReadPriceSnapshotField("internet"))
    if (intRaw = "" && liveIntNum > 0)
        intRaw := liveIntRaw
    
    if (intRaw != "" && IsObject(CalcInternetText))
    {
        ; Extract only the price portion (e.g., "$110" from "Internet $110")
        if RegExMatch(intRaw, "\$?\s*([\d,]+)", &m)
        {
            priceOnly := StrReplace(m[1], " ", "")
            ; Only update if the new price is valid (non-zero)
            if (priceOnly != "" && priceOnly != "0")
            {
                if (autoClerkPhase != "NEXT" && beepIntNum > 0 && beepIntNum != NormalizeToNumber(lastInternetBeepPrice))
                {
                    SoundBeep(800, 100)
                    lastInternetBeepPrice := beepIntNum
                }
                lastPersistentInternetPrice := priceOnly 
            }
        }
        
        ; Proximity Warning: Turn RED if close to Bid Estimate
        bidEstNum := NormalizeToNumber(IsObject(CalcBaseText) ? CalcBaseText.Text : "")
        currIntNum := NormalizeToNumber(lastPersistentInternetPrice)
        
        ; Stop Alert - only force reload from the live Internet button. The
        ; persistent display can briefly belong to the previous lot/session.
        if (bidEstNum > 0 && currIntNum > 0 && (currIntNum >= bidEstNum))
        {
            CalcInternetText.SetFont("cFF0000 Bold") ; Danger Red
            
            ; --- SAFETY INTERRUPT ---
            global autoClerkActive, internetInterruptFired
            if (autoClerkActive && !internetInterruptFired)
            {
                if CheckInternetLimitReload()
                    internetInterruptFired := true
            }
        }
        else
            CalcInternetText.SetFont("cFFD700 Bold") ; Safe Gold

        ; Always display the persistent price (which is now the highest seen this lot)
        CalcInternetText.Text := (lastPersistentInternetPrice != "0") ? "$" . lastPersistentInternetPrice : "$0"
    }
    else if (intRaw == "" && IsObject(CalcInternetText))
    {
        ; Persistence: Keep showing the last known price until next lot
        CalcInternetText.Text := (lastPersistentInternetPrice != "0") ? "$" . lastPersistentInternetPrice : "$0"
    }
}


GetLastExtensionPrice()
{
    global lastExtensionPrice
    return lastExtensionPrice
}

OpenRemapWizard(*)
{
    wizardPath := A_ScriptDir "\RemapWizardPro.ahk"
    if FileExist(wizardPath)
        Run(wizardPath)
    else
        MsgBox("Remap wizard not found:`n" wizardPath, "BidCalc")
}

ReturnToChrome()
{
    ; Removed focus-stealing WinActivate
}

CloseSubScripts()
{
    DetectHiddenWindows(true)  ; Find hidden windows too
    subScripts := ["combo.ahk", "micro.ahk", "small.ahk", "medium.ahk", "large.ahk", "ultra.ahk"]
    for script in subScripts
    {
        try {
            ; Method 1: By window title with ahk_class
            if WinExist(script " ahk_class AutoHotkey")
                WinClose(script " ahk_class AutoHotkey")
            
            ; Method 2: Partial title match
            SetTitleMatchMode(2)
            if WinExist(script)
                WinClose(script)
            SetTitleMatchMode(1)
        }
    }
    
    ; Also close any orphaned CMD windows
    try {
        if WinExist("ahk_exe cmd.exe")
            WinClose("ahk_exe cmd.exe")
    }
    
    DetectHiddenWindows(false)
    Sleep(200)
}

IsSubScriptRunning(scriptName)
{
    DetectHiddenWindows(true)

    if WinExist(scriptName " ahk_class AutoHotkey")
    {
        DetectHiddenWindows(false)
        return true
    }

    SetTitleMatchMode(2)
    foundScript := !!WinExist(scriptName)
    SetTitleMatchMode(1)
    DetectHiddenWindows(false)
    return foundScript
}

SetAutoClickStatus(enabled)
{
    statusFile := A_Temp "\ocr_autoclick_status.txt"
    try {
        if (FileExist(statusFile))
            FileDelete(statusFile)
        FileAppend(enabled ? "1" : "0", statusFile)
    }
}

ResolveSubScriptByFinalValue(finalValue)
{
    return "combo.ahk"
}

LaunchSubScriptByFinalValue(finalValue, autoClickEnabled := 1, forceLaunch := false)
{
    global lastSubScript

    newSubScript := ResolveSubScriptByFinalValue(finalValue)

    if (newSubScript = "combo.ahk")
    {
        ; Combo is now built-in, just set auto-click status
        SetAutoClickStatus(autoClickEnabled)
        ; Reset F8 step for new lot
        ResetProgressiveF8IfNeeded()
        return
    }

    if (forceLaunch || newSubScript != lastSubScript || !IsSubScriptRunning(newSubScript))
    {
        CloseSubScripts()
        Sleep(100)
        SetAutoClickStatus(autoClickEnabled)

        scriptPath := A_ScriptDir "\" newSubScript
        if FileExist(scriptPath)
        {
            Run(scriptPath)
            lastSubScript := newSubScript
        }
    }
    else
    {
        SetAutoClickStatus(autoClickEnabled)
    }
}

LaunchCurrentCalculatorSubScript(autoClickEnabled := 1, forceLaunch := false)
{
    global CalcInput

    cleanedValue := IsObject(CalcInput) ? RegExReplace(Trim(CalcInput.Value), "[^\d\.]") : ""

    if (cleanedValue = "")
        return

    amount := cleanedValue + 0
    divisor := 1.3
    baseValue := Round(amount / divisor, 0)
    finalValue := CalculateFinalValue(baseValue)
    LaunchSubScriptByFinalValue(finalValue, autoClickEnabled, forceLaunch)
}

SetSpamFastMode(*)
{
    global spamDelayMode, CalcSpamFastRadio, CalcSpamMediumRadio, CalcSpamSlowRadio, autoClerkActive
    spamDelayMode := "fast"
    CalcSpamFastRadio.Value := 1
    CalcSpamMediumRadio.Value := 0
    CalcSpamSlowRadio.Value := 0
    SaveSpeedMode()
    if (autoClerkActive)
        SetTimer(AutoClerkTick, GetSpamDelay(100))
        if IsObject(AutoClerkToggleBtn)
            AutoClerkToggleBtn.Text := "▶"
}

SetSpamMediumMode(*)
{
    global spamDelayMode, CalcSpamFastRadio, CalcSpamMediumRadio, CalcSpamSlowRadio, autoClerkActive
    spamDelayMode := "medium"
    CalcSpamFastRadio.Value := 0
    CalcSpamMediumRadio.Value := 1
    CalcSpamSlowRadio.Value := 0
    SaveSpeedMode()
    if (autoClerkActive)
        SetTimer(AutoClerkTick, GetSpamDelay(100))
        if IsObject(AutoClerkToggleBtn)
            AutoClerkToggleBtn.Text := "▶"
}

SetSpamSlowMode(*)
{
    global spamDelayMode, CalcSpamFastRadio, CalcSpamMediumRadio, CalcSpamSlowRadio, autoClerkActive
    spamDelayMode := "slow"
    CalcSpamFastRadio.Value := 0
    CalcSpamMediumRadio.Value := 0
    CalcSpamSlowRadio.Value := 1
    SaveSpeedMode()
    if (autoClerkActive)
        SetTimer(AutoClerkTick, GetSpamDelay(100))
        if IsObject(AutoClerkToggleBtn)
            AutoClerkToggleBtn.Text := "▶"
}

SaveSpeedMode()
{
    global spamDelayMode, speedModeFile

    try
    {
        if FileExist(speedModeFile)
            FileDelete(speedModeFile)
        FileAppend(spamDelayMode, speedModeFile)
    }
}

LoadSpeedMode()
{
    global spamDelayMode, speedModeFile
    global CalcSpamFastRadio, CalcSpamMediumRadio, CalcSpamSlowRadio

    if FileExist(speedModeFile)
    {
        try
        {
            savedMode := Trim(FileRead(speedModeFile))
            if (savedMode = "fast" || savedMode = "medium" || savedMode = "slow")
                spamDelayMode := savedMode
        }
    }

    if IsObject(CalcSpamFastRadio)
        CalcSpamFastRadio.Value := (spamDelayMode = "fast") ? 1 : 0
    if IsObject(CalcSpamMediumRadio)
        CalcSpamMediumRadio.Value := (spamDelayMode = "medium") ? 1 : 0
    if IsObject(CalcSpamSlowRadio)
        CalcSpamSlowRadio.Value := (spamDelayMode = "slow") ? 1 : 0

    SaveSpeedMode()
}

SavePercentMode()
{
    global targetPercentMode, percentModeFile

    try
    {
        if FileExist(percentModeFile)
            FileDelete(percentModeFile)
        FileAppend(targetPercentMode, percentModeFile)
    }
}

LoadPercentMode()
{
    global targetPercentMode, percentModeFile, CalcPercent1Radio, CalcPercent5Radio, CalcPercent10Radio

    if FileExist(percentModeFile)
    {
        try
        {
            savedMode := Trim(FileRead(percentModeFile))
            if (savedMode = "1" || savedMode = "5" || savedMode = "10")
                targetPercentMode := savedMode
        }
    }

    if IsObject(CalcPercent1Radio)
        CalcPercent1Radio.Value := (targetPercentMode = "1") ? 1 : 0
    if IsObject(CalcPercent5Radio)
        CalcPercent5Radio.Value := (targetPercentMode = "5") ? 1 : 0
    if IsObject(CalcPercent10Radio)
        CalcPercent10Radio.Value := (targetPercentMode = "10") ? 1 : 0

    SavePercentMode()
}

SetPercent1Mode(*)
{
    global targetPercentMode, CalcPercent1Radio, CalcPercent5Radio, CalcPercent10Radio
    targetPercentMode := "1"
    CalcPercent1Radio.Value := 1
    CalcPercent5Radio.Value := 0
    CalcPercent10Radio.Value := 0
    SavePercentMode()
}

SetPercent5Mode(*)
{
    global targetPercentMode, CalcPercent1Radio, CalcPercent5Radio, CalcPercent10Radio
    CalcPercent1Radio.Value := 0
    targetPercentMode := "5"
    CalcPercent5Radio.Value := 1
    CalcPercent10Radio.Value := 0
    SavePercentMode()
}

SetPercent10Mode(*)
{
    global targetPercentMode, CalcPercent1Radio, CalcPercent5Radio, CalcPercent10Radio
    CalcPercent1Radio.Value := 0
    targetPercentMode := "10"
    CalcPercent5Radio.Value := 0
    CalcPercent10Radio.Value := 1
    SavePercentMode()
}

GetSpamDelay(baseDelay)
{
    global spamDelayMode
    if (spamDelayMode = "slow")
        return Round(baseDelay * 1.5)
    if (spamDelayMode = "medium")
        return Round(baseDelay * 1.25)
    ; Fast mode baseline.
    return Round(baseDelay * 1.0)
}

SetCalculatorAmount(amount)
{
    global CalcInput

    if IsObject(CalcInput)
    {
        CalcInput.Value := amount
        UpdateCalculatorWindow()
        
        ; Write price to temp file so sub-scripts can read it
        priceFile := A_Temp "\ocr_current_price.txt"
        if (FileExist(priceFile))
            FileDelete(priceFile)
        FileAppend(amount, priceFile)

        MarkNewBidSequence()
    }
}

SaveCurrentFinalValue(finalValue)
{
    global finalValueFile

    try
    {
        if FileExist(finalValueFile)
            FileDelete(finalValueFile)
        FileAppend(finalValue, finalValueFile)
    }
}

MarkNewBidSequence()
{
    global lotTokenCounter, lotTokenFile

    lotTokenCounter += 1
    try
    {
        if FileExist(lotTokenFile)
            FileDelete(lotTokenFile)
        FileAppend(lotTokenCounter, lotTokenFile)
    }
}


GetCalculatorTier(baseValue)
{
    ; Unified tier logic to match the pricing table
    return GetBidIncrement(baseValue)
}

GetBracketReference(baseValue)
{
    if (baseValue >= 1010 && baseValue < 2500)
    {
        bracketSize := 25
        bracketNum := Floor((baseValue - 1011) / bracketSize)
        if (bracketNum < 0)
            bracketNum := 0
        return 1025 + (bracketNum * bracketSize)
    }
    else if (baseValue >= 2520 && baseValue < 5000)
    {
        bracketSize := 50
        bracketNum := Floor((baseValue - 2521) / bracketSize)
        if (bracketNum < 0)
            bracketNum := 0
        return 2545 + (bracketNum * bracketSize)
    }
    else if (baseValue >= 5040 && baseValue < 10000)
    {
        bracketSize := 100
        bracketNum := Floor((baseValue - 5041) / bracketSize)
        if (bracketNum < 0)
            bracketNum := 0
        return 5090 + (bracketNum * bracketSize)
    }
    else if (baseValue >= 10100)
    {
        bracketSize := 250
        bracketNum := Floor((baseValue - 10101) / bracketSize)
        if (bracketNum < 0)
            bracketNum := 0
        return 10250 + (bracketNum * bracketSize)
    }
    else
    {
        return baseValue
    }
}



CalculateFinalValue(baseValue)
{
    tier := GetBidIncrement(baseValue)
    if (tier <= 0)
        return 0
        
    ; Round up estimate to next tier
    roundedEst := Ceil(baseValue / tier) * tier
    
    ; Calculate final by simulating 7 steps down with correct increments
    currVal := roundedEst
    Loop 7
    {
        inc := GetBidIncrement(currVal)
        currVal := currVal - inc
    }
    
    return Round(currVal, 0)
}

UpdateSessionClock()
{
    ; Clock updates disabled to keep Status area clean for bot telemetry
    return
}

ToggleSessionCountPaused(*)
{
    global sessionCountPaused
    sessionCountPaused := !sessionCountPaused
    UpdateSessionWindow()
}

IsTargetTabActive()
{
    global SessionGui

    ; Strict visibility: only show on target auction tab/window.
    return (WinActive("ahk_exe chrome.exe") && (WinActive("Auction") || WinActive("Clerk")))
        || (IsObject(SessionGui) && WinActive("ahk_id " SessionGui.Hwnd))
}

SyncPauseState()
{
    global scriptPaused, checkButtonLatched

    ; Keep automation active regardless of focused window.
    scriptPaused := false
    UpdateSessionVisibility()
    UpdateSessionWindow()
}

WatchTargetTab()
{
    SyncPauseState()
}

ForceTempLowSession(*)
{
    global pressCount, pauseCountSession, scriptPaused

    if scriptPaused
        return

    if (pressCount >= 11)
    {
        pauseCountSession := true
        UpdateSessionWindow()
    }
}

IncreaseSessionCount(*)
{
    global pressCount, sessionCountPaused, pauseCountSession, lastSavedPressCount
    
    if sessionCountPaused
        return

    ; CLEAR STUCK STATES: Forcefully kill any temporary or fallback states
    pauseCountSession := false
    lastSavedPressCount := 0

    pressCount += 1
    if (pressCount > 14)
        pressCount := 1

    ToolTip("Session: " pressCount)
    SetTimer(() => ToolTip(), -1000)

    SaveSessionCount()
    UpdateSessionWindow()
}

DecreaseSessionCount(*)
{
    global pressCount, sessionCountPaused, pauseCountSession

    if sessionCountPaused
        return

    pressCount--
    if (pressCount < 1)
        pressCount := 14

    pauseCountSession := false
    SaveSessionCount()
    UpdateSessionWindow()
}

DebugCheckButton()
{
    ; Extension-based button detection (no pixel search)
    isVisible := IsExtensionButtonVisible()
    MsgBox(
        "Extension Button Detection`n"
        . "Button visible: " (isVisible ? "YES" : "NO"),
        "CheckButton Debug"
    )
}

ClickPoint(point, label := "", count := 1)
{
    ; Physical click removed
    ClickNoMoveXY(point[1], point[2], count)
}

ClickNoMove(point, label := "", count := 1)
{
    ; Physical fallback removed
    ClickNoMoveXY(point[1], point[2], count)
}

WaitForExtensionButton(timeoutMs := 0, pollMs := 100)
{
    global scriptPaused

    if scriptPaused
        return false

    if (timeoutMs <= 0)
        timeoutMs := 1000  ; 1 second timeout

    startTick := A_TickCount

    Loop
    {
        if scriptPaused
            return false

        if IsExtensionButtonVisible()
            return true

        if ((A_TickCount - startTick) >= timeoutMs)
            return false

        Sleep(pollMs)
    }
}

IsExtensionButtonVisible()
{
    ; Read button state from file written by Chrome Extension
    ; Returns true if button is visible/enabled on the page
    return ExtensionButton.IsVisible()
}

AdvanceSessionCount()
{
    global pressCount, sessionCountPaused, pauseCountSession, checkButtonLatched
    global f9ExtraStepArmed, f9ExtraStepUsed
    global allowF8, allowF9, allowF10, allowF11

    if sessionCountPaused
        return

    pressCount += 1
    if (pressCount > 14)
    {
        pressCount := 1
    }

    pauseCountSession := false
    checkButtonLatched := false
    
    ; Start of Session: F8/F9 are Ready, F10/F11 are Locked for safety
    allowF8 := true
    allowF9 := true
    allowF10 := false 
    allowF11 := false

    ; Reset one-time overrides
    f9ExtraStepArmed := false
    f9ExtraStepUsed := false
    
    SaveSessionCount()
    UpdateSessionWindow()
}

; ===============================
; INSERT – WORKS LIKE F11 WITHOUT F10 TRIGGER
; ===============================

Insert::
{
    return
}


; ===============================
; F9 – CLICKS INTERNET + COMPETING
; ===============================

F9::HandleF9()

HandleF9()
{
    global allowF10, allowF11, scriptPaused, CalcFinalText, CalcBaseText, f9AutoBidTriggered, CurrentActiveLotID, ExtCoordsCache
    global f9ExtraStepArmed, f9ExtraStepUsed, licenseRevoked

    ; CHECK IF LICENSE WAS REVOKED
    if (licenseRevoked) {
        MsgBox("Your license has been revoked.", "License Revoked", 0x10)
        ExitApp(0)
    }

    if scriptPaused
        return

    ; Fast single-read safety check
    currentAskPrice := ReadCurrentAskPrice()
    finalValue := GetProgressiveF8FullValue()
    askClean := RegExReplace(currentAskPrice, "[^\d\.]")
    finalClean := RegExReplace(finalValue, "[^\d\.]")
    if ((finalClean = "" || finalClean = "0") && IsObject(CalcFinalText))
        finalClean := RegExReplace(CalcFinalText.Text, "[^\d\.]")
    
    if (askClean != "" && finalClean != "")
    {
        currentAskNum := askClean + 0
        finalNum := finalClean + 0
        if (currentAskNum > 0 && finalNum > 0)
        {
            nextAskNum := currentAskNum + GetBidIncrement(currentAskNum)
            useIncrementAware := (finalNum >= 301 && finalNum <= 500)
            if (currentAskNum >= finalNum || (useIncrementAware ? (nextAskNum >= finalNum) : (nextAskNum > finalNum)))
            {
                if (f9ExtraStepArmed && !f9ExtraStepUsed)
                {
                    f9ExtraStepUsed := true
                }
                else
                {
                    f9ExtraStepArmed := true
                    return
                }
            }
        }
    }

    ; --- FAST BIDDING PATH ---
    if (CurrentActiveLotID != "" && ExtCoordsCache.Has(CurrentActiveLotID))
    {
        lotCache := ExtCoordsCache[CurrentActiveLotID]
        if lotCache.Has("internet") && lotCache.Has("competing")
        {
            ; If Internet price exists, wait for Internet to become clickable
            ; before Competing. Otherwise skip Internet and click Competing only.
            if (GetVisibleInternetPriceNumber() > 0)
            {
                ClickInternetAfterPriceSeen()
                Sleep(GetSpamDelay(50))
                ClickPrimaryButtonNative("competing")
            }
            else
            {
                ClickPrimaryButtonNative("competing")
            }
            return
        }
    }

    ; --- REFINED F9 SEQUENCE ---
    ; Pass finalNum to the clicking helper so it can stop perfectly at the limit.
    finalNum := GetProgressiveF8FullValue()
    ClickInternetThenCompeting(fastBidInternetWaitMs, fastBidInternetPollMs, false, finalNum)
}



; ===============================
; F10 – SHARED SPAM + FAIR/GOING + PASS/SOLD
; ===============================

F10::HandleF10()

HandleF10()
{
    global pressCount, allowF11, allowF10, pauseCountSession, scriptPaused, f10F11PressLock
    global extensionMonitoringActive, resumeExtensionAfterF10, autoClerkActive, autoClerkBiddingStartTime, F10DangerBeepPlayed
    global pacingStopPending, pacingTargetAbsoluteLotMark, currentAuctionProgressNumber, licenseRevoked
    
    ; CHECK IF LICENSE WAS REVOKED
    if (licenseRevoked) {
        MsgBox("Your license has been revoked.", "License Revoked", 0x10)
        ExitApp(0)
    }
    
    F10DangerBeepPlayed := false

    ; --- STARTUP SAFETY WINDOW ---
    ; User Feedback: 500ms is enough to compare prices.
    if (autoClerkActive && (A_TickCount - autoClerkBiddingStartTime < 500))
        return

    if scriptPaused
        return

    if f10F11PressLock
        return

    ; Now that we passed the startup safety window, mark F10 as done for AutoClerk tracking
    global CalcBaseText
    finalValueForSave := (IsObject(CalcBaseText)) ? RegExReplace(CalcBaseText.Text, "[^\d\.]") + 0 : 0
    if (autoClerkActive && finalValueForSave >= 140)
        SaveLotEvent("F10")

    LockF10F11UntilNewAsk()

    ; Initial delay to let price settle before mode selection
    Sleep(1000)

    ; Strict Price Match Condition (defaults to EQUALS if price unreadable)
    compareResult := ComparePriceToFinal()
    if (compareResult = "UNKNOWN")
        compareResult := "EQUALS"

    allowF10 := false
    allowF11 := true
    resumeExtensionAfterF10 := extensionMonitoringActive

    ; Spam FIRST — bidding rhythm before auctioneer call
    allowF10 := true
    
    ; 2026-05-10 MUTED: Safety check return muted so Going/Fair still clicks even if limit reached.
    ; if SharedSpam(compareResult)
    ; {
    ;     allowF10 := true ; Keep F10 ready for next attempt after bid handled
    ;     global autoClerkPhase, f10TriggerTime
    ;     autoClerkPhase := "WAITING"
    ;     f10TriggerTime := A_TickCount ; Start wait timer even if interrupted
    ;     return
    ; }
    SharedSpam(compareResult) ; Run it but ignore the early return
    
    ; Settle and align Current Ask before Going/Fair. SharedSpam is fast and
    ; can read stale prices; this slower pass enforces the target tier.
    AlignAskToBidEstimateBeforeGoingFair()
    
    ; User requested: 500ms delay before Fair/Going becomes active
    Sleep(500)

    ; Going/Fair AFTER spam
    if (pressCount >= 11 && !pauseCountSession)
    {
        ClickFairSmart()
        if (IsObject(PacingProgressText) && PacingProgressText.Text = "RUSHING")
            Sleep 1000
        else
            Sleep Random(1000, 6000)
        ClickPrimaryButtonNative("sendmessage")
    }
    else
    {
        ClickGoingSmart()
    }

    ; Designated lot rule: F10 must fully enter the WAITING/F11 path before
    ; any final goal reload is allowed.
    if (IsPacingLockActive() && IsPacingGoalExact())
    {
        pacingStopPending := true
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "GOAL: F10 DONE"
    }

    if (resumeExtensionAfterF10)
        StartExtensionMonitoring()

    ; For Pacing/Auto-Clerk: Start the wait clock AFTER all clicks are done
    global autoClerkActive, f10TriggerTime, autoClerkPhase, pacingTargetAbsoluteLotMark, pacingTargetTotalLotMs, currentBiddingStartTime, autoClerkWaitMs, CalcWaitDropDown, CalcTimerText, timerSoundFired
    
    ; If Pacing is locked, we want to see the countdown starting from F10
    if (pacingTargetAbsoluteLotMark > 0)
    {
        RecalibratePacing() ; Refresh the latest wait time
        f10TriggerTime := A_TickCount
        timerSoundFired := false
        
        finalClean := IsObject(CalcFinalText) ? RegExReplace(CalcFinalText.Text, "[^\d\.]") : ""
        finalNum := finalClean != "" ? finalClean + 0 : 0
        
        autoClerkPhase := "WAITING"
        
        if (autoClerkActive)
        {
            autoClerkPhase := "WAITING"
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "WAITING..."
        }
        else
        {
            StartCountdown()
        }
    }
    else
    {
        f10TriggerTime := A_TickCount
        timerSoundFired := false ; Reset for manual F10
        if (autoClerkActive)
        {
            autoClerkPhase := "WAITING"
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "WAITING..."
        }
        else
            StartCountdown()
    }
}

Trigger6SecondCountdown()
{
    global autoClerkActive, autoClerkPhase
    if (autoClerkActive && autoClerkPhase = "WAITING")
    {
        StartCountdown()
    }
}


AlignAskToBidEstimateBeforeGoingFair()
{
    global CalcBaseText, ExtCoordsCache, CurrentActiveLotID

    baseClean := ""
    if IsObject(CalcBaseText)
        baseClean := RegExReplace(CalcBaseText.Text, "[^\d\.]")
    if (baseClean = "")
        return false

    ; Get coordinates ONCE for high-speed clicking
    cX := 0, cY := 0
    if (CurrentActiveLotID != "" && ExtCoordsCache.Has(CurrentActiveLotID) && ExtCoordsCache[CurrentActiveLotID].Has("competing"))
    {
        cX := ExtCoordsCache[CurrentActiveLotID]["competing"].x
        cY := ExtCoordsCache[CurrentActiveLotID]["competing"].y
    }
    else
    {
        ; Fallback: Fetch once
        body := FetchButtonStates()
        targetHwnd := GetChromeTargetHwnd()
        if (targetHwnd)
        {
            mapHwnd := GetChromeRenderWidgetHwnd(targetHwnd)
            if (!mapHwnd)
                mapHwnd := targetHwnd
            ResolveButtonScreenXY(body, "competing", mapHwnd, &cX, &cY)
        }
    }

    if (cX = 0 || cY = 0)
        return false

    ; Read price with high reliability. Keep the F10 alignment inside the
    ; live Internet tier window:
    ; - Internet below BE: target Internet, so an ask one tier under can click
    ;   Competing once into the safety-reload tier.
    ; - Internet above BE: target Internet + 1 tier, then safety-reload.
    askNum := ReadSettledCurrentAskNumber(350, 25, 2)
    liveInternetNum := GetLiveInternetSafetyNumber()
    if (askNum <= 0)
        return false

    baseNum := baseClean + 0
    if (liveInternetNum > 0)
    {
        internetTier := GetBidIncrement(liveInternetNum)
        if (liveInternetNum < baseNum)
        {
            baseNum := liveInternetNum
        }
        else if (liveInternetNum > baseNum)
        {
            if (liveInternetNum > askNum)
                askNum := liveInternetNum
            baseNum := liveInternetNum + internetTier
        }
        else
        {
            baseNum := liveInternetNum
        }
    }

    if (askNum >= baseNum)
        return true

    ; --- ENFORCE PRICE FLOOR ---
    if IsObject(SessionClockText)
        SessionClockText.Text := "BOT: ALIGNING..."

    ; Calculate exact number of clicks needed to clear the estimate
    projectedAsk := askNum
    clicksNeeded := 0
    maxCeiling := baseNum * 1.01 ; Strict 1% ceiling
    
    Loop 15 ; Cap at 15 clicks for safety
    {
        increment := GetBidIncrement(projectedAsk)
        if (increment <= 0)
            break
            
        ; Safety: If the NEXT bid would put us more than 1% over the estimate, STOP.
        if ((projectedAsk + increment) > maxCeiling && projectedAsk >= baseNum)
            break
            
        projectedAsk += increment
        clicksNeeded += 1
        
        if (projectedAsk >= baseNum)
            break
    }

    if (clicksNeeded <= 0)
        return true

    ; Execute high-speed native clicks (No HTTP overhead inside this loop)
    Loop clicksNeeded
    {
        ClickNoMoveXY(cX, cY)
        if (A_Index < clicksNeeded)
            Sleep(150) ; Tight 150ms gap
    }

    return true
}

ReadSettledCurrentAskNumber(timeoutMs := 220, pollMs := 25, stableReadsNeeded := 2)
{
    deadline := A_TickCount + timeoutMs
    lastValue := 0
    sameCount := 0
    highestSeen := 0

    while (A_TickCount <= deadline)
    {
        askRaw := ReadCurrentAskPrice()
        askClean := RegExReplace(askRaw, "[^\d\.]")
        askNum := (askClean = "") ? 0 : (askClean + 0)

        if (askNum > highestSeen)
            highestSeen := askNum

        if (askNum > 0 && askNum = lastValue)
        {
            sameCount += 1
            if (sameCount >= stableReadsNeeded)
                return askNum
        }
        else
        {
            sameCount := 0
            lastValue := askNum
        }

        Sleep(pollMs)
    }

    return (highestSeen > 0) ? highestSeen : lastValue
}



; ===============================
; F11 – MAIN ACTION (Sold/Pass, Next, CopyPrice, Sub-scripts)
; ===============================

F11::HandleF11()

HandleF11(isAuto := false)
{
    global activeBidPID, activeBidType, pressCount
    global allowF11, pauseCountSession, scriptPaused, checkButtonLatched, f11Paused, f10F11PressLock, autoClerkPhase, licenseRevoked

    ; CHECK IF LICENSE WAS REVOKED
    if (licenseRevoked) {
        MsgBox("Your license has been revoked.", "License Revoked", 0x10)
        ExitApp(0)
    }

    if scriptPaused
        return

    if ForceReloadIfInternetAtBidEstimate(true)
        return

    if f10F11PressLock
        return

    ; --- INTERNET SAFETY CHECK ---
    ; Only refuse to sell if there is an ACTUAL internet bid (with a price).
    if IsInternetReadyFromExtension(true)
    {
        if ForceReloadIfInternetAtBidEstimate(true)
            return

        ClickPrimaryButtonNative("internet")
        SoundBeep(800, 100)
        
        allowF11 := true ; Stay on F11 mode
        UpdateSessionWindow()
        return
    }

    LockF10F11UntilNewAsk()
    allowF11 := false

    ; Read price from Chrome DOM immediately before processing
    domPrice := ReadPriceFromExtension()
    if (domPrice != "" && IsObject(CalcInput))
    {
        CalcInput.Value := domPrice
        UpdateCalculatorWindow()
    }

    checkButtonLatched := false

    ; Safety check: If internet bid or current ask is at or above estimate, do NOT sell!
    GetInternetLimitNumbers(&bidEstNum, &intBidNum)
    askNum := NormalizeToNumber(ReadCurrentAskPrice())
    
    tier := GetBidIncrement(bidEstNum)
    if (CheckInternetLimitReload()) {
        return
    }

    if (pressCount >= 11 && !pauseCountSession)
    {
        ClickPassSmart()
    }
    else
    {
        ClickSoldSmart()
    }

    pauseCountSession := false
    UpdateSessionWindow()

    ; Wait 1 second and check for button color
    Sleep 1000
    
    ; If check button is live, pause until F12 resume (ONLY for manual use, skip for Auto-Clerk)
    if (IsExtensionButtonVisible() && !autoClerkActive)
    {
        global f11Paused
        f11Paused := true
        while (f11Paused)
        {
            Sleep(50)
        }
    }

    Sleep(500)
    ; Safety re-check right before Next: do not continue if Internet is live (Skip for Auto-Clerk)
    if (IsExtensionButtonVisible() && !autoClerkActive)
    {
        global f11Paused
        f11Paused := true
        while (f11Paused)
        {
            Sleep(50)
        }
    }
    ; --- NEXT SAFETY GATE ---
    ; If internet bid is at or above bid estimate, do NOT click Next.
    ; Stop Auto-Clerk and fire the same zone-stop alarm as the BIDDING phase.
    global CalcBaseText, autoClerkActive, AutoClerkToggleBtn, SessionClockText
    GetInternetLimitNumbers(&bidEstNum, &intBidNum)
    skipNext := false
    if (IsInternetAtBidEstimate(&bidEstNum, &intBidNum))
    {
        if (true)
        {
            skipNext := true
            
            ; Full Auto-Clerk stop — same as BIDDING phase zone-stop
            autoClerkActive := false
            SetTimer(AutoClerkTick, 0)
            if IsObject(AutoClerkToggleBtn)
                AutoClerkToggleBtn.Text := "▶"
            if IsObject(SessionClockText)
                SessionClockText.Text := "BOT: PAUSED (INT @ LIMIT)"
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "HOLD: INT BID @ LIMIT"
            
            ForceReloadByReason("internet_limit")
        }
    }
    
    
    ; --- FINAL GOAL SAFETY: NEVER PRESS NEXT ON THE DESIGNATED LOT ---
    if (pacingTargetAbsoluteLotMark > 0 && IsPacingGoalExact())
    {
        ToolTip("FINAL GOAL REACHED: STOPPING AT LOT " currentAuctionProgressNumber, 10, 10, 7)
        SetTimer(() => ToolTip(,,, 7), -10000)

        autoClerkPhase := "STOPPED"
        ForceReloadDesignatedLotStop()
        return
    }
    
    if (!skipNext)
        ClickPrimaryButtonNativeWhenEnabled("next", 3000, 100)
    AdvanceSessionCount()
    SetTimer(CheckButton, 300)

    ; Prime the helper from the current !!!! before waiting on the color gate.
    LaunchCurrentCalculatorSubScript(1)
    SignalComboCycleReset()

    ; Read price from Chrome DOM (position 4) - NOW BEFORE WAIT
    domPrice := ReadPriceFromExtension()
    if (domPrice != "" && IsObject(CalcInput))
    {
        CalcInput.Value := domPrice
        UpdateCalculatorWindow()
    }

    ; WaitForExtensionButton removed to prevent script freezing
}



; ===============================
; OTHER HOTKEYS
; ===============================

NumpadEnter::
{
    global scriptPaused, fastBidInternetWaitMs, fastBidInternetPollMs, fastBidEnterCooldownMs

    if scriptPaused
        return

    ; NumpadEnter should always attempt Internet -> Competing native clicks.
    ClickInternetThenCompeting(fastBidInternetWaitMs, fastBidInternetPollMs)
    Sleep fastBidEnterCooldownMs
    ; Highlight temporarily disabled for troubleshooting click timing.
}
NumpadAdd::
{
    global scriptPaused

    if scriptPaused
        return

    ; Removed focus-stealing WinActivate
    FocusSelectCurrentAskInputNative()
}

Pause::
{
    global scriptPaused

    if scriptPaused
        return

    ClickFairSmart()
    StartCountdown()
    Sleep 100
    Sleep 300
    ReturnToChrome()
    Sleep 100 ; Reduced from 7200 to prevent script freeze
    ClickPassSmart()
}



; ===============================
; AUTO-CLERK
; ===============================

ToggleAutoClerk(*)
{
    global autoClerkActive, lastAutoClerkLotToken, scriptPaused, autoClerkPhase, progressiveF8Step, autoClerkStartedLotToken, lastAutoClerkRetryTime, CurrentActiveLotID, autoClerkInitialAnalysisDone, autoClerkBiddingStartTime, lastAutoClerkLotNumber
    global pacingTargetAbsoluteLotMark, pacingAbsoluteDeadline, pacingStopPending, PacingToggleBtn
    
    if scriptPaused
        return

    autoClerkActive := !autoClerkActive
    if (autoClerkActive)
    {
        ; Manual Play should not inherit a stale pacing target. Only the BOT
        ; LOCK/STOP BOT control is allowed to make AutoClerk obey end-lot pace.
        if (!IsPacingLockActive())
        {
            pacingTargetAbsoluteLotMark := 0
            pacingAbsoluteDeadline := ""
            pacingStopPending := false
        }

        if (pacingTargetAbsoluteLotMark > 0 && currentAuctionProgressNumber > 0 && pacingTargetAbsoluteLotMark > currentAuctionProgressNumber)
        {
            autoClerkActive := false
            if IsObject(PacingToggleBtn)
                PacingToggleBtn.Text := "START BOT"
            MsgBox("Update Your End LOT", "FastBid Safety", 48)
            return
        }
        ; --- SAFETY GATE: Don't start if Pacing Goal is already met ---
        global pacingTargetAbsoluteLotMark, currentAuctionProgressNumber, pacingStartLot
        if (pacingTargetAbsoluteLotMark > 0)
        {
            if (currentAuctionProgressNumber <= 0)
            {
                autoClerkActive := false
                ToolTip("TELEMETRY SYNC ERROR: NO LOT NUMBER")
                SetTimer(() => ToolTip(), -3000)
                return
            }

            isCountingDown := (pacingStartLot > pacingTargetAbsoluteLotMark)
            lotsToGo := isCountingDown ? (currentAuctionProgressNumber - pacingTargetAbsoluteLotMark)
                                        : (pacingTargetAbsoluteLotMark - currentAuctionProgressNumber)
            
            ; Diagnostic ToolTip
            ToolTip("Start: " pacingStartLot " | Target: " pacingTargetAbsoluteLotMark " | Current: " currentAuctionProgressNumber " | Left: " lotsToGo)
            SetTimer(() => ToolTip(), -3000)

            if (IsPacingGoalPassed())
            {
                autoClerkActive := false
                ToolTip("GOAL ALREADY PASSED (" currentAuctionProgressNumber ")")
                SetTimer(() => ToolTip(), -3000)
                return
            }
        }

        ; --- FRESH START POLICY ---
        lastAutoClerkLotToken := (CurrentActiveLotID != "") ? CurrentActiveLotID : "NOVALUE"
        lastAutoClerkLotNumber := currentAuctionProgressNumber
        autoClerkInitialAnalysisDone := false  ; Forces re-read and 500ms wait
        autoClerkBiddingStartTime := A_TickCount + 1000000 ; Defensive future offset
        autoClerkStartedLotToken := "INIT"         ; For F8 ladder sync
        autoClerkPhase := "BIDDING"      ; Resets transition state
        progressiveF8Step := 0           ; Re-Syncs ladder to current price
        
        if IsObject(SessionClockText)
            SessionClockText.Text := "BOT: PLAYING"
        SetTimer(AutoClerkTick, GetSpamDelay(100))
        if IsObject(AutoClerkToggleBtn)
            AutoClerkToggleBtn.Text := "⏹"
    }
    else
    {
        if IsObject(SessionClockText)
            SessionClockText.Text := "BOT: PAUSED"
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "BOT: PAUSED"
        SetTimer(AutoClerkTick, 0)
        autoClerkPhase := "BIDDING" ; Reset phase so pacing engine can update timer
        if IsObject(AutoClerkToggleBtn)
            AutoClerkToggleBtn.Text := "▶"
    }
}

AutoClerkTick()
{
    global autoClerkActive, lastAutoClerkLotToken, progressiveF8Step, f10F11PressLock
    global autoClerkPhase, f10TriggerTime, autoClerkStartedLotToken, lastAutoClerkRetryTime, CurrentActiveLotID, autoClerkInitialAnalysisDone, autoClerkBiddingStartTime, currentBiddingStartTime
    global pacingCurrentHourLeft
    global pacingTargetAbsoluteLotMark, currentAuctionProgressNumber, CalcTimerText, lastF8Tick, lastBiddingDurationSeconds, lotIsClosed
    global timerCueSeconds, timerCueMs
    global pacingStopPending
    
    if !autoClerkActive
    {
        SetTimer(AutoClerkTick, 0)
        if IsObject(AutoClerkToggleBtn)
            AutoClerkToggleBtn.Text := "▶"
        return
    }

    if (pacingStopPending && IsPacingGoalPassed())
    {
        ForceReloadAdvancedGoalResume()
        return
    }

    if HandleDesignatedLotStopGuard("tick")
        return


    ; --- PHASE: WAITING AFTER F10 ---
    if (autoClerkPhase = "WAITING")
    {
        if ForceReloadIfInternetAtBidEstimate()
            return

        if (currentBiddingStartTime > 0)
        {
            global lastBiddingDurationSeconds
            lastBiddingDurationSeconds := (A_TickCount - currentBiddingStartTime) / 1000
            currentBiddingStartTime := 0 ; Reset for next lot
        }
        ; Internet during WAITING should extend the timer. Dangerous Internet
        ; prices are already handled by ForceReloadIfInternetAtBidEstimate()
        ; at the top of this WAITING phase.
        /*
        intBidRaw := ReadInternetBidPrice()
        currAskRaw := ReadCurrentAskPrice()
        intNum := NormalizeToNumber(intBidRaw)
        askNum := NormalizeToNumber(currAskRaw)
        
        ; Stop ONLY if we have a valid internet price that is currently competitive
        if (intNum > 0 && IsInternetReadyFromExtension(true))
        {
            autoClerkActive := false
            SetTimer(AutoClerkTick, 0)
            if IsObject(AutoClerkToggleBtn)
                AutoClerkToggleBtn.Text := "▶"
            if (IsObject(SessionClockText)) {
                SessionClockText.Text := "BOT: PAUSED (INT BID)"
            }
            SoundBeep(300, 200)
            return
        }
        */

        ; --- EXTEND TIMER IF INTERNET BID ACTIVE ---
        remainingWaitMs := autoClerkWaitMs - (A_TickCount - f10TriggerTime)
        global internetExtendFired, CalcBaseText, CalcInternetText, lastPersistentInternetPrice
        
        liveInternetNum := GetLiveInternetSafetyNumber()
        visibleInternetNum := liveInternetNum
        if (visibleInternetNum <= 0)
            visibleInternetNum := NormalizeToNumber(ReadInternetBidPrice())
        if (visibleInternetNum <= 0)
            visibleInternetNum := NormalizeToNumber(lastPersistentInternetPrice)
        if (visibleInternetNum <= 0 && IsObject(CalcInternetText))
            visibleInternetNum := NormalizeToNumber(CalcInternetText.Text)

        ; Any UI-visible Internet price extends once per lot. The flag is reset
        ; only when the next lot is detected, so repeated reads do not stack.
        ; Safety reload above still requires the stricter live-button price.
        if (visibleInternetNum > 0 && !internetExtendFired)
        {
            bidEstNum := NormalizeToNumber(IsObject(CalcBaseText) ? CalcBaseText.Text : "")
            extendSeconds := 30
            if (bidEstNum > 0)
            {
                internetPctOfBE := visibleInternetNum / bidEstNum
                if (internetPctOfBE >= 0.75)
                    extendSeconds := 120
                else if (internetPctOfBE >= 0.50)
                    extendSeconds := 60
            }

            f10TriggerTime += extendSeconds * 1000
            internetExtendFired := true
            
            global countdownSeconds, timerActive
            countdownSeconds += extendSeconds
            if (!timerActive) {
                timerActive := true
                SetTimer(UpdateCountdown, 1000)
            }
            
            if IsObject(SessionClockText)
                SessionClockText.Text := "BOT: EXTENDED +" extendSeconds "S"

            remainingWaitMs := autoClerkWaitMs - (A_TickCount - f10TriggerTime)
        }

        ; --- 59th MINUTE REST FEATURE (PACING ONLY) ---
        if (IsPacingLockActive())
        {
            RecalibratePacing()
            if (pacingCurrentHourLeft <= 0 && lotIsClosed && !IsPacingGoalExact() && !IsPacingGoalPassed())
            {
                if IsObject(CalcTimerText)
                    CalcTimerText.Text := "HOUR QUOTA REST"
                return
            }
        }
        remainingWaitMs := autoClerkWaitMs - (A_TickCount - f10TriggerTime)

        ; --- 59th MINUTE REST FEATURE (PACING ONLY) ---
        phTime := GetPHTime()
        currentMin := SubStr(phTime, 11, 2)
        if (IsPacingLockActive() && currentMin == "59")
        {
            RecalibratePacing()
            if (pacingCurrentHourLeft <= 0 && liveInternetNum <= 0 && lotIsClosed)
            {
                ; Rest at :59 only after the current lot is already finished.
                ; If it is still active, bypass the rest and finish the lot.
                f10TriggerTime := A_TickCount - autoClerkWaitMs - 1 
                return
            }

            ; If the current hour still has lots left, do not take the 1-minute
            ; rest. Keep the protected 6s tail, then move to the next lot.
            remainingHourWaitMs := autoClerkWaitMs - (A_TickCount - f10TriggerTime)
            if (remainingHourWaitMs > timerCueMs)
            {
                f10TriggerTime := A_TickCount - autoClerkWaitMs + timerCueMs
                return
            }
        }

        ; --- SYNCED 6S COUNTDOWN TRIGGER ---
        ; This must happen before the F11 transition check. If the wait already
        ; expired without the cue firing, force a real 6s tail instead of F11.
        global timerActive, timerSoundFired, timerMuted
        if (remainingWaitMs <= timerCueMs && !timerSoundFired)
        {
            if (!timerMuted)
                timerSoundFired := PlayTimerSound()
            else
                timerSoundFired := true

            StartCountdown(timerCueSeconds, false)

        if (remainingWaitMs < timerCueMs)
        {
            f10TriggerTime := A_TickCount - autoClerkWaitMs + timerCueMs
            return
        }
    }

        if HandleDesignatedLotStopGuard("wait")
            return

        ; --- TRANSITION FLOW ---
        global autoClerkWaitMs
        if (A_TickCount - f10TriggerTime > autoClerkWaitMs)
        {
            if (!timerSoundFired)
            {
                if (!timerMuted)
                    timerSoundFired := PlayTimerSound()
                else
                    timerSoundFired := true

                StartCountdown(timerCueSeconds, false)
                ; DON'T reset f10TriggerTime - let the countdown proceed to F11
                return
            }

            autoClerkPhase := "NEXT"
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "WAITING FOR LOT TO END..."
            if IsObject(SessionClockText)
                SessionClockText.Text := "BOT: READY FOR NEXT"
            
            ; --- ENABLED AUTO-SOLD/NEXT ---
            ; We now move aggressively when the timer is done
            global allowF11
            allowF11 := true
            SaveLotEvent("F11")
            ClearF10F11LockForAutoF11()
            HandleF11(true)
            return
        }
        else if (A_TickCount - f10TriggerTime > autoClerkWaitMs + 15000)
        {
            ; --- STUCK RECOVERY ---
            f10TriggerTime := A_TickCount ; Reset timer
            global allowF11
            allowF11 := true
            ClearF10F11LockForAutoF11()
            HandleF11(true)
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "FORCE NEXT (STUCK)"
        }
        
        ; NEW: Periodically recalibrate pacing DURING the wait to show real-time drift
        ; BUT ONLY if pacing is actually locked/active!
        if (IsPacingLockActive() && Mod(A_TickCount, 1000) < 100)
            RecalibratePacing()

        return
    }

    ; --- PHASE: NEXT LOT RESET ---
    if (autoClerkPhase = "NEXT")
    {
        ; PHASE CHANGE DETECTOR: wait for the real active lot ID to change.
        ; The progress lot number can update before the old lot's buttons are gone.
        global currentAuctionProgressNumber, lastAutoClerkLotNumber, lastAutoClerkLotToken
        if (CurrentActiveLotID != "" && lastAutoClerkLotToken != "" && CurrentActiveLotID != lastAutoClerkLotToken)
        {
            lastAutoClerkLotNumber := currentAuctionProgressNumber
            lastAutoClerkLotToken := CurrentActiveLotID
            global currentLotDidBid, internetExtendFired, timerSoundFired, countdownSeconds, timerActive, lastInternetSeenTime
            currentLotDidBid := false ; Reset here!
            internetExtendFired := false ; Reset here!
            lastInternetSeenTime := 0 ; Reset previous-lot internet recency
            timerSoundFired := false ; Reset for new lot!
            countdownSeconds := 0
            timerActive := false
            SetTimer(UpdateCountdown, 0)
            autoClerkStartedLotToken := "" 
            
            ; --- AUTO-CLICK SEQUENCE FOR NEW LOT ---
            ; If Internet has/just had a price, give the page a careful first
            ; settle once per lot. Otherwise use the normal quick opening rhythm.
            hasNewLotInternet := IsInternetPriceActiveOrRecent(2000)
            if hasNewLotInternet
            {
                if IsObject(CalcTimerText)
                    CalcTimerText.Text := "INT PRICE: SLOW"
                Sleep(1000)
            }
            else
            {
                Sleep(200)
            }
            internetPriceNow := GetLiveInternetSafetyNumber()
            if (internetPriceNow <= 0)
                internetPriceNow := NormalizeToNumber(ReadInternetBidPrice())
            hasVisibleInternetPrice := (hasNewLotInternet || internetPriceNow > 0)

            if (hasVisibleInternetPrice && ForceReloadIfInternetAtBidEstimate(true))
                return

            if (hasVisibleInternetPrice)
            {
                ClickInternetAfterPriceSeen()
                Sleep(200)
            }
            ClickPrimaryButtonNative("competing")
            Sleep(200)
            
            autoClerkPhase := "BIDDING"
            currentBiddingStartTime := A_TickCount  ; Start the Learning Stopwatch
            progressiveF8Step := 0
            autoClerkInitialAnalysisDone := false   ; Re-read ask on EVERY new lot (not just first)
            
            ClearLotEvents()   ; Re-read ask on EVERY new lot (not just first)
            
            ; Clear internet bid price file to prevent stale data trigger
            global internetBidPriceFile
            if FileExist(internetBidPriceFile)
                FileDelete(internetBidPriceFile)
            
            ; --- CLEAR LOCK FOR NEW LOT ---
            global f10F11PressLock, f10F11LockAskValue
            f10F11PressLock := false
            f10F11LockAskValue := ""
            
            if IsObject(SessionClockText)
                SessionClockText.Text := "BOT: PLAYING"
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "TIMER"
            return
        }
        
        ; --- SMART RECOVERY LOGIC ---
        timeInNext := A_TickCount - f10TriggerTime
        if (timeInNext > autoClerkWaitMs + 3000) ; Start checking after 3 seconds
        {
            ; Commented out to prevent loops of Last Call 3x / Going 1x
            ; if (bidEstNum > 0 && currentAsk > 0 && currentAsk < (bidEstNum - (bidEstNum * 0.01)))
            ; {
            ;     if IsObject(SessionClockText)
            ;         SessionClockText.Text := "BOT: RE-ENTERING BID"
            ;     autoClerkPhase := "BIDDING"
            ;     return
            ; }

            ; --- HARD RESET GUARD ---
            if (timeInNext > autoClerkWaitMs + 10000) ; Stuck for 10+ seconds
            {
                if IsObject(SessionClockText)
                    SessionClockText.Text := "BOT: HARD RESET"
                lastAutoClerkLotToken := "FORCE_NEW" ; Wipe memory
                autoClerkPhase := "BIDDING"
                return
            }

            ; Only attempt a hardware click retry every 5 seconds if we are truly finished
            ; if (A_TickCount - lastAutoClerkRetryTime > 5000)
            ; {
            ;     lastAutoClerkRetryTime := A_TickCount
            ;     
            ;     if IsObject(SessionClockText)
            ;         SessionClockText.Text := "BOT: RETRYING NEXT..."
            ;     if IsObject(CalcTimerText)
            ;         CalcTimerText.Text := "BOT: FORCE NEXT"
            ;     
            ;     ; Direct click 'next' - do NOT call HandleF11() again as it re-locks f10F11PressLock
            ;     global f10F11PressLock
            ;     f10F11PressLock := false  ; Force-clear any stale lock
            ;     ClickPrimaryButtonNative("next")
            ; }
        }
        return
    }

    ; --- PHASE: BIDDING ---
    if (lotIsClosed)
    {
        if ForceReloadIfInternetAtBidEstimate()
            return

        autoClerkPhase := "NEXT"
        global currentLotDidBid
        
        currentAskRaw := ReadCurrentAskPrice()
        askNum := NormalizeToNumber(currentAskRaw)
        bidEstRaw := (IsObject(CalcBaseText)) ? CalcBaseText.Text : ""
        bidEstNum := NormalizeToNumber(bidEstRaw)
        tier := GetBidIncrement(bidEstNum)
        
        if (currentLotDidBid || (askNum >= bidEstNum - tier && askNum <= bidEstNum + tier))
        {
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "AUTO: CLOSED"
            ClearF10F11LockForAutoF11()
            HandleF11(true)
        }
        else
        {
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "AUTO: WAITING LOT"
            if HandleDesignatedLotStopGuard("closed_wait")
                return
        }
        return
    }
    
    ; --- AUTO-CLOSE IF STUCK AT ESTIMATE ON LAST CALL ---
    currentAskRaw := ReadCurrentAskPrice()
    askNum := NormalizeToNumber(currentAskRaw)
    bidEstRaw := (IsObject(CalcBaseText)) ? CalcBaseText.Text : ""
    bidEstNum := NormalizeToNumber(bidEstRaw)
    
    if ((lotIsLastCall || lotIsFairWarning) && askNum > 0 && askNum >= bidEstNum)
    {
        if ForceReloadIfInternetAtBidEstimate()
            return

        autoClerkPhase := "NEXT"
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "AUTO: CLOSING"
        ClearF10F11LockForAutoF11()
        HandleF11(true)
        return
    }
        
    ; NEW: Periodically recalibrate pacing DURING bidding wars to show real-time drift
    if (Mod(A_TickCount, 5000) < 100)
        RecalibratePacing()

    if ForceReloadIfInternetAtBidEstimate()
        return

    ; Internet price is handled inside the actual Internet/Competing actions.
        
    ; STARTUP ANALYSIS: 500ms wait and 5% proximity check
    if (!autoClerkInitialAnalysisDone)
    {
        Sleep(200) ; Initial "Wait and Read" Delay (Reduced from 500ms)
        
        currentAskRaw := ReadCurrentAskPrice()
        askNum := NormalizeToNumber(currentAskRaw)
        bidEstRaw := (IsObject(CalcBaseText)) ? CalcBaseText.Text : ""
        bidEstNum := NormalizeToNumber(bidEstRaw)
        finalValue := GetProgressiveF8FullValue()
        finalNum := NormalizeToNumber(finalValue)
        
        ; 5% Proximity Calculation
        isNearEstimate := (bidEstNum > 0 && Abs(askNum - bidEstNum) <= (bidEstNum * 0.05))
        isNearFinal := (finalNum > 0 && Abs(askNum - finalNum) <= (finalNum * 0.05))
        
        ; If price is within 5% or over, skip starter bid
        if (isNearEstimate || isNearFinal || (finalNum > 0 && askNum >= finalNum))
        {
            autoClerkInitialAnalysisDone := true
            autoClerkBiddingStartTime := A_TickCount
            autoClerkStartedLotToken := CurrentActiveLotID
            return
        }
        
        ; Only fire starter bid if safely outside 5% AND we have valid numbers
        if (finalNum > 0 && bidEstNum > 0)
        {
            HandleF9()
            autoClerkInitialAnalysisDone := true
            autoClerkBiddingStartTime := A_TickCount
            autoClerkStartedLotToken := CurrentActiveLotID
        }
        ; If we don't have valid numbers yet (waiting for extension), loop and try again next tick
        return
    }

    currentAskRaw := ReadCurrentAskPrice()
    askNum := NormalizeToNumber(currentAskRaw)

    ; 1. INTERNET ESTIMATE STOP: If an Internet Bid reaches the Middle Box (769), Beep and Stop
    if IsInternetReadyFromExtension()
    {
        bidEstRaw := (IsObject(CalcBaseText)) ? CalcBaseText.Text : ""
        bidEstNum := NormalizeToNumber(bidEstRaw)
        
        ; Internet-limit stop only depends on Internet price, not current ask.
        if (CheckInternetLimitReload(false))
        {
            return
        }
    }

    if (f10F11PressLock)
        return

    finalValue := GetProgressiveF8FullValue()
    finalNum := NormalizeToNumber(finalValue)

    ; Goal lot reached: mark it as the final lot, but let the normal
    ; ask/final-price threshold trigger F10 so the closer does not fire early.
    if (IsPacingLockActive() && IsPacingGoalExact())
        pacingStopPending := true

    if (finalNum <= 0)
        return

    ; Ladder Phase (F8)
    if (finalNum > 0 && askNum < finalNum)
    {
        ; --- CONTINUOUS LADDER SYNC (Smart Jump) ---
        ; Each tick, ensure we aren't trying to bid a milestone the room already passed.
        ; STALE-PRICE GUARD: Only sync-forward if askNum is above the very first rung.
        ; If askNum <= ladder[1] the lot just started; never skip the opening rungs.
        f8Target := GetProgressiveF8Target()
        ladder := BuildProgressiveF8Ladder(f8Target)
        if (ladder.Length > 0)
        {
            firstRung := ladder[1]
            if (progressiveF8Step = 0 && askNum <= firstRung)
            {
                ; Fresh lot - ask is at or below first rung. Fire step 1 directly, no sync.
                HandleProgressiveF8()
                return
            }

            while (progressiveF8Step < ladder.Length && ladder[progressiveF8Step + 1] <= askNum)
            {
                progressiveF8Step++
            }
            
            ; Execute Ladder Bid (Forward momentum)
            if (progressiveF8Step < ladder.Length)
            {
                HandleProgressiveF8()
                return
            }
        }
        
        autoClerkStartedLotToken := lastAutoClerkLotToken ; Mark sync as processed for this tick
    }

    ; Fast-calculate next iteration logic
    nextAskNum := askNum + GetBidIncrement(askNum)

    ; TRIGGER THE CLOSER (F10) using the Bottom Box
    ; Stops when we matched final, or if any subsequent F9 would break the mathematical limit!
    if (finalNum > 0 && (askNum >= finalNum || nextAskNum > finalNum))
    {
        if ((!WasEventDone("F10") || finalNum < 140) && autoClerkPhase != "WAITING")
        {
            global allowF10 := true
            HandleF10() 
            return
        }
        else if (autoClerkPhase = "BIDDING")
        {
            SharedSpam()

            if HandleDesignatedLotStopGuard("closer")
                return
            
            ; STEP 4: SYNC MASTER - Calculate first, then sound, then immediate UI update
            RecalibratePacing()
            autoClerkPhase := "WAITING"
            f10TriggerTime := A_TickCount
            
            global timerSoundFired
            timerSoundFired := false
            StartCountdown(Max(1, Ceil(autoClerkWaitMs / 1000)), false)
            UpdatePacingMonitor() ; Force UI refresh now
            
            lastAutoClerkLotToken := CurrentActiveLotID
            autoClerkBiddingStartTime := 0
        }
    }

    ; F9 Filler (Rhythm controlled by Fast/Medium/Slow radios)
    if (finalNum > 0 && nextAskNum <= finalNum)
    {
        static lastF9Tick := 0
        if (A_TickCount - lastF9Tick > GetSpamDelay(100))
        {
            HandleF9()
            lastF9Tick := A_TickCount
        }
    }
}

#HotIf ; Reset hotkey context 

; ===============================
; SHARED SPAM
; ===============================

SharedSpam(mode := "EQUALS")
{
    global CalcBaseText, CalcTimerText

    if (CheckSharedSpamDangerBeep())
        return true

    ; Helper function for custom sequences — all clicks by button name, no stored coords
    DoCustomSequence(lc1, intCmp1, lc2, intCmp2)
    {
        Loop lc1
        {
            if (CheckSharedSpamDangerBeep())
                return true
            ClickPrimaryButtonNative("lastcall")
            Sleep GetSpamDelay(200)
        }
        Loop intCmp1
        {
            if (CheckSharedSpamDangerBeep())
                return true
            if (GetVisibleInternetPriceNumber() > 0)
                ClickInternetAfterPriceSeen()
            Sleep GetSpamDelay(200)
            if (CheckSharedSpamDangerBeep())
                return true
            currNum := NormalizeToNumber(ReadCurrentAskPrice())
            if (bidEstNum > 0 && currNum > 0 && currNum < bidEstNum)
            {
                ClickPrimaryButtonNative("competing")
                Sleep GetSpamDelay(400)
            }
        }
        Loop lc2
        {
            if (CheckSharedSpamDangerBeep())
                return true
            ClickPrimaryButtonNative("lastcall")
            Sleep GetSpamDelay(200)
        }
        Loop intCmp2
        {
            if (CheckSharedSpamDangerBeep())
                return true
            if (GetVisibleInternetPriceNumber() > 0)
                ClickInternetAfterPriceSeen()
            Sleep GetSpamDelay(200)
            if (CheckSharedSpamDangerBeep())
                return true
            currNum := NormalizeToNumber(ReadCurrentAskPrice())
            if (bidEstNum > 0 && currNum > 0 && currNum < bidEstNum)
            {
                ClickPrimaryButtonNative("competing")
                Sleep GetSpamDelay(400)
            }
        }
        return true
    }

    ; Initial Anchor - Only once at the start
    ClickPrimaryButtonNative("lastcall")
    global currentLotDidBid
    currentLotDidBid := true
    Sleep 100

    ; Phase 1: 4 Cycles of Internet + Competing
    Loop 4
    {
        if (CheckSharedSpamDangerBeep())
            return true
        if (GetVisibleInternetPriceNumber() > 0)
            ClickInternetAfterPriceSeen()
        Sleep GetSpamDelay(200)

        if (CheckSharedSpamDangerBeep())
            return true

        bidEstNum := NormalizeToNumber(IsObject(CalcBaseText) ? CalcBaseText.Text : "")
        currNum := NormalizeToNumber(ReadCurrentAskPrice())
        if (bidEstNum > 0 && currNum > 0 && currNum < bidEstNum)
        {
            ClickPrimaryButtonNative("competing")
            Sleep GetSpamDelay(400)
        }
    }

    ; Phase 2: 3 Cycles of Internet + Last Call (Mid Anchors)
    Loop 3
    {
        if (CheckSharedSpamDangerBeep())
            return true
        if (GetVisibleInternetPriceNumber() > 0)
            ClickInternetAfterPriceSeen()
        Sleep GetSpamDelay(200)

        if (CheckSharedSpamDangerBeep())
            return true
        ClickPrimaryButtonNative("lastcall")
        Sleep GetSpamDelay(200)
    }

    ; Phase 3: 3 Cycles of Internet + Competing (Finish Cycles)
    Loop 3
    {
        if (CheckSharedSpamDangerBeep())
            return true
        if (GetVisibleInternetPriceNumber() > 0)
            ClickInternetAfterPriceSeen()
        Sleep GetSpamDelay(200)

        if (CheckSharedSpamDangerBeep())
            return true

        bidEstNum := NormalizeToNumber(IsObject(CalcBaseText) ? CalcBaseText.Text : "")
        currNum := NormalizeToNumber(ReadCurrentAskPrice())
        if (bidEstNum > 0 && currNum > 0 && currNum < bidEstNum)
        {
            ClickPrimaryButtonNative("competing")
            Sleep GetSpamDelay(400)
        }
    }

    return false
}

CheckSharedSpamDangerBeep()
{
    global CalcBaseText, F10DangerBeepPlayed
    
    if (F10DangerBeepPlayed)
        return false 
        
    if (!IsInternetAtBidEstimate(&bidEstNum, &intBidNum))
        return false ; No limit set
        
    ; Stop and reload when a live Internet bid reaches the near-tier safety floor.
    ; Current ask can naturally rise above BID EST during Last Call.
    F10DangerBeepPlayed := true
    ForceReloadByReason("internet_limit")
    return true
}


ClickInternetSmart()
{
    ; Old ClickNoMove-style behavior for normal flow:
    ; click Internet immediately regardless of enabled/disabled state.
    ClickPrimaryButtonNativeRetry("internet", 2, 35)
    return true
}

ClickInternetThenCompeting(waitMs := 0, pollMs := 0, requireInternetReady := false, limitNum := 0)
{
    global fastBidClickGapMs, pressCount, pauseCountSession, lastPersistentInternetPrice
    global lastInternetSeenTime, currentBiddingStartTime
    
    ; Click Internet only when a visible Internet price exists. If no Internet
    ; price is active, this action becomes Competing-only.
    if (GetVisibleInternetPriceNumber() > 0)
    {
        ClickInternetAfterPriceSeen()
    
        ; --- INTERNET COOLDOWN GAP ---
        ; 1. If we see the internet button NOW, reset the cooldown
        ; 2. If it's been less than 2 seconds since we last saw it, stay at 200ms
        ; 3. Otherwise, speed up to 100ms
        lastInternetSeenTime := A_TickCount
        if (lastInternetSeenTime < currentBiddingStartTime)
            lastInternetSeenTime := currentBiddingStartTime
            
        cooldownMs := A_TickCount - lastInternetSeenTime
        
        if (cooldownMs < 2000)
            effectiveGap := 200
        else
            effectiveGap := 100
            
        Sleep(effectiveGap)
    
        ; Limit Guard: Double-check if we reached the limit before firing the second click
        if (limitNum > 0)
        {
            currentAsk := ReadCurrentAskPrice()
            currentAskNum := NormalizeToNumber(currentAsk)
            
            if (currentAskNum >= limitNum)
                return true ; STOP HERE - The Internet click was enough!
        }
    }

    ; Click Competing. This still fires when Internet price is absent.
    ClickPrimaryButtonNative("competing")
    
    return true
}

ClickCompetingSmart()
{
    ; Always use button name — no stored coords
    ClickPrimaryButtonNativeRetry("competing", 2, 35)
    Sleep(180)
}

ClickLastCallSmart()
{
    ClickPrimaryButtonNative("lastcall")
}

ClickSoldSmart()
{
    ClickPrimaryButtonNative("sold")
}

ClickPassSmart()
{
    ClickPrimaryButtonNative("pass")
}

ClickNextSmart()
{
    ClickPrimaryButtonNative("next")
}

ClickFairSmart()
{
    ClickPrimaryButtonNative("fair")
}

ClickGoingSmart()
{
    if (!ClickPrimaryButtonNative("going"))
        ClickPrimaryButtonNative("lastcall")
}

ForceUpdateCoordsCache()
{
    global ExtCoordsCache, CalcTimerText, CurrentActiveLotID
    
    if (CurrentActiveLotID = "")
    {
        if IsObject(CalcTimerText)
        {
            CalcTimerText.Text := "CACHE FAIL (NO LOT)"
            CalcTimerText.SetFont("cFF0000 Bold")
            SetTimer(ResetF9TimerText, 1500)
        }
        return
    }

    body := FetchButtonStates()
    if (body = "")
    {
        if IsObject(CalcTimerText)
        {
            CalcTimerText.Text := "CACHE FAIL"
            CalcTimerText.SetFont("cFF0000 Bold")
            SetTimer(ResetF9TimerText, 1500)
        }
        return
    }
        
    targetHwnd := GetChromeTargetHwnd()
    if !targetHwnd
        return
    mapHwnd := GetChromeRenderWidgetHwnd(targetHwnd)
    if !mapHwnd
        mapHwnd := targetHwnd
        
    buttons := ["internet", "competing", "lastcall", "sold", "pass", "next", "fair", "going", "sendmessage"]
    
    if !ExtCoordsCache.Has(CurrentActiveLotID)
        ExtCoordsCache[CurrentActiveLotID] := Map()
        
    lotCache := ExtCoordsCache[CurrentActiveLotID]
    lotCache.Clear()
    
    successCount := 0
    for index, btn in buttons
    {
        if ResolveButtonScreenXY(body, btn, mapHwnd, &mx, &my)
        {
            lotCache[btn] := {x: mx, y: my}
            successCount++
        }
    }
    
    if IsObject(CalcTimerText)
    {
        CalcTimerText.Text := "CACHED (" successCount "/8)"
        CalcTimerText.SetFont("c00FF00 Bold")
        SetTimer(ResetF9TimerText, 1500)
    }
}

ExtractAuctionProgressLotNumber(progressText, activeLotId := "")
{
    text := Trim(progressText)
    if (text = "")
        return 0

    ; "Lot 12 of 688" is an auction position counter. AAMICRO pacing counts
    ; down from remaining lots, so the active lot value is 688 - 12 + 1.
    if RegExMatch(text, "i)\bLot\s*#?\s*[:\-]?\s*(\d+)\s*(?:of|/)\s*\d+", &lotMatch)
    {
        if RegExMatch(text, "i)\bLot\s*#?\s*[:\-]?\s*(\d+)\s*(?:of|/)\s*(\d+)", &lotOfMatch)
        {
            lotPosition := lotOfMatch[1] + 0
            totalLots := lotOfMatch[2] + 0
            if (totalLots > 0 && lotPosition > 0 && lotPosition <= totalLots)
                return totalLots - lotPosition + 1
        }
    }

    ; Plain "Lot 688" telemetry is already the countdown/current lot value.
    if RegExMatch(text, "i)\bLot\s*#?\s*[:\-]?\s*(\d+)", &lotMatch)
        return lotMatch[1] + 0

    if RegExMatch(text, "i)\b(?:Current|Now)\s*[:\-]?\s*(\d+)", &currentMatch)
        return currentMatch[1] + 0

    ; Fall back to the first standalone number only when no stronger signal is
    ; available. This preserves older telemetry strings such as "688".
    if RegExMatch(text, "\b(\d+)\b", &numMatch)
        return numMatch[1] + 0

    return 0
}

PollActiveLotState()
{
    global CurrentActiveLotID, CalcRemapBtn, pendingStarterBid, pressCount, pauseCountSession, lastSavedPressCount, checkButtonLatched, currentAuctionProgressPct, currentAuctionProgressText, currentAuctionProgressNumber, lastValidAuctionProgressNumber, lotIsClosed, lotIsLastCall, lotIsFairWarning
    global CalcInternetText, lastPersistentInternetPrice
    global PacingLotsInput, pacingLotManualOverride
    try
    {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "http://localhost:9999/active-state", false)
        req.SetRequestHeader("Cache-Control", "no-cache")
        req.Send()
        if (req.Status = 200)
        {
            body := req.ResponseText
            activeLotIdFromBody := ""
            if RegExMatch(body, '"activeLotId"\s*:\s*"([^"]+)"', &activeIdMatch)
                activeLotIdFromBody := activeIdMatch[1]

            if RegExMatch(body, '"progress".*?"pct"\s*:\s*"([^"]*)"', &pctMatch)
                currentAuctionProgressPct := pctMatch[1]
            if RegExMatch(body, '"progress".*?"text"\s*:\s*"([^"]*)"', &txtMatch) {
                currentAuctionProgressText := txtMatch[1]
                parsedLotNumber := ExtractAuctionProgressLotNumber(currentAuctionProgressText, activeLotIdFromBody)
                if (parsedLotNumber > 0)
                {
                    currentAuctionProgressNumber := parsedLotNumber
                    lastValidAuctionProgressNumber := parsedLotNumber
                    if (IsObject(PacingLotsInput) && Trim(PacingLotsInput.Text) = "" && !pacingLotManualOverride && !IsPacingLockActive())
                        UpdateCalculatedStopLot(true)
                }
            }
            
            ; --- EXTRACT AUCTION LOG FLAGS ---
            if RegExMatch(body, '"lotIsClosed"\s*:\s*(true|false)', &closedMatch)
                lotIsClosed := (closedMatch[1] = "true")
            else
                lotIsClosed := false
                
            if RegExMatch(body, '"lotIsLastCall"\s*:\s*(true|false)', &lcMatch)
                lotIsLastCall := (lcMatch[1] = "true")
            else
                lotIsLastCall := false
                
            if RegExMatch(body, '"lotIsFairWarning"\s*:\s*(true|false)', &fwMatch)
                lotIsFairWarning := (fwMatch[1] = "true")
            else
                lotIsFairWarning := false
                
            ; Target-lot handling must run after activeLotId is processed below.
            global autoClerkActive, pacingTargetAbsoluteLotMark
            if (lotIsClosed && HandleDesignatedLotStopGuard("poll_closed"))
                return

            if IsObject(PacingProgressText) {
                if (pacingTargetAbsoluteLotMark <= 0) {
                    if (currentAuctionProgressText != "")
                        PacingProgressText.Text := currentAuctionProgressText
                    else
                        PacingProgressText.Text := "TRACKING"
                }
            }

            if (activeLotIdFromBody != "")
            {
                newLotId := activeLotIdFromBody
                
                ; --- STABILITY GUARD ---
                ; Only process changes if the ID is valid (not empty or undefined)
                if (newLotId == "" || newLotId == "undefined")
                    return

                if (newLotId != CurrentActiveLotID)
                {
                    ; Split the composite ID (UID_LOTNUM) to check if the AUCTION changed
                    newAuctionUID := ""
                    if (InStr(newLotId, "_"))
                        newAuctionUID := StrSplit(newLotId, "_")[1]
                    else
                        newAuctionUID := newLotId

                    ; --- GLOBAL AUCTION TRACKER ---
                    global CurrentAuctionUID
                    
                    ; ONLY LOAD from file if we physically switched to a different auction tab (UID change)
                    ; Standard lot advancement within the same tab should NOT trigger a reload.
                    if (newAuctionUID != CurrentAuctionUID)
                    {
                        CurrentAuctionUID := newAuctionUID
                        UpdateAuctionUIDLinkButton()
                        LoadSessionCount()
                    }

                    ; --- PENDING STOP HANDLER ---
                    global pacingStopPending
                    if (pacingStopPending)
                    {
                        ForceReloadDesignatedLotStop()
                        return
                    }

                    ; Update the lot identity
                    CurrentActiveLotID := newLotId
                    global currentBiddingStartTime, autoClerkPhase, soundPlayed
                    if (autoClerkPhase != "NEXT")
                    {
                        autoClerkPhase := "BIDDING" ; End the rest period from the previous lot
                        currentBiddingStartTime := A_TickCount ; Reset stopwatch for accurate pacing on new lot
                        RecalibratePacing()
                    }

                    if IsObject(CalcRemapBtn)
                    {
                        if (InStr(CurrentActiveLotID, "_"))
                        {
                            parts := StrSplit(CurrentActiveLotID, "_")
                            CalcRemapBtn.Text := "Lot: " parts[2] "   UID: " parts[1]
                        }
                        else
                        {
                            CalcRemapBtn.Text := "Lot: " CurrentActiveLotID
                        }
                    }
                    

                    ; Reset persistent internet price for new lot
                    global lastPersistentInternetPrice, lastInternetBeepPrice, internetInterruptFired, internetBidPriceFile, internetPriceResetTick, pauseCountSession, checkButtonLatched
                    lastPersistentInternetPrice := "0"
                    lastInternetBeepPrice := "0"
                    internetPriceResetTick := A_TickCount
                    internetInterruptFired := false
                    pauseCountSession := false
                    checkButtonLatched := false
                    if IsObject(CalcInternetText)
                        CalcInternetText.Text := "$0"
                    UpdateSessionWindow()
                        
                    ; --- STALE DATA GUARD ---
                    ; Clear the temp file that Chrome writes to so we don't read the PREVIOUS lot's price.
                    try {
                        if FileExist(internetBidPriceFile)
                            FileDelete(internetBidPriceFile)
                    } catch {
                    }
                }
            }
        }
        
        ; --- AUTO-TEMPORARY DETECTION (LATCHED) ---
        ; Trigger on Internet readiness or the UI-visible Internet price for
        ; sessions 11-14. The UI can see price before the button enables.
        ; Using a LATCH to ensure it only happens ONCE per bid.
        if (pressCount >= 11 && !pauseCountSession)
        {
            visibleInternetNum := GetLiveInternetSafetyNumber()
            if (visibleInternetNum <= 0)
                visibleInternetNum := NormalizeToNumber(ReadInternetBidPrice())
            if (visibleInternetNum <= 0)
                visibleInternetNum := NormalizeToNumber(lastPersistentInternetPrice)

            internetTempActive := IsInternetReadyFromExtension(false) || visibleInternetNum > 0
            if internetTempActive
            {
                if (!checkButtonLatched)
                {
                    lastSavedPressCount := pressCount
                    pressCount := 11
                    pauseCountSession := true
                    checkButtonLatched := true ; Lock the switch
                    UpdateSessionWindow()
                    SoundBeep(800, 100)
                }
            }
            else
            {
                checkButtonLatched := false ; Reset latch when button is gray/disabled
            }
        }
        else if (!IsInternetReadyFromExtension(false))
        {
            checkButtonLatched := false ; Reset latch for manual overrides
        }

        ; --- AUTO RELOAD IF STUCK FOR 2.5 MINUTES ---
        global currentBiddingStartTime, autoClerkActive
        if (autoClerkActive && currentBiddingStartTime > 0 && CurrentActiveLotID != "")
        {
            if (A_TickCount - currentBiddingStartTime > 150000) ; 150,000 ms = 2.5 minutes
            {
                currentBiddingStartTime := A_TickCount ; Reset to prevent infinite loops
                SetTimer(() => ForceReloadWithResume(1), -10)
            }
        }
    }
    catch
    {
    }
}

; Fetch raw JSON from extension server in one HTTP call.
FetchButtonStates()
{
    try
    {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "http://localhost:9999/active-state", false)
        req.Send()
        if (req.Status = 200)
            return req.ResponseText
    }
    catch
    {
    }
    return ""
}

; Parse button screen coords from already-fetched JSON body (no HTTP).
ResolveButtonScreenXY(body, buttonName, mapHwnd, &screenX, &screenY)
{
    screenX := 0
    screenY := 0
    if (body = "")
        return false

    clientX := ""
    clientY := ""

    ; Prefer device-pixel coords (DPI-safe).
    patternDevice := '"' buttonName '"\s*:\s*\{[^}]*"centerXDevice"\s*:\s*(-?\d+|null)[^}]*"centerYDevice"\s*:\s*(-?\d+|null)'
    if RegExMatch(body, patternDevice, &md)
    {
        if !(md[1] = "null" || md[2] = "null")
        {
            clientX := md[1] + 0
            clientY := md[2] + 0
        }
    }

    ; Fallback to CSS-pixel coords.
    if (clientX = "")
    {
        pattern := '"' buttonName '"\s*:\s*\{[^}]*"centerX"\s*:\s*(-?\d+|null)[^}]*"centerY"\s*:\s*(-?\d+|null)'
        if !RegExMatch(body, pattern, &m)
            return false
        if (m[1] = "null" || m[2] = "null")
            return false
        clientX := m[1] + 0
        clientY := m[2] + 0
    }

    return ClientPointToScreen(mapHwnd, clientX, clientY, &screenX, &screenY)
}

GetPrimaryButtonClientCenter(buttonName, &centerX, &centerY)
{
    centerX := ""
    centerY := ""
    try
    {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "http://localhost:9999/button-states", false)
        req.SetRequestHeader("Cache-Control", "no-cache")
        req.Send()
        if (req.Status != 200)
            return false

        body := req.ResponseText
        
        ; Use device-pixel coordinates (DevicePixelRatio aware) for pinpoint accuracy
        patternDevice := '"' buttonName '"\s*:\s*\{[^}]*"centerXDevice"\s*:\s*(-?\d+|null)[^}]*"centerYDevice"\s*:\s*(-?\d+|null)'
        if RegExMatch(body, patternDevice, &matchDevice)
        {
            if !(matchDevice[1] = "null" || matchDevice[2] = "null")
            {
                centerX := matchDevice[1] + 0
                centerY := matchDevice[2] + 0
                return true
            }
        }

        ; Fallback: CSS-pixel center coordinates (Logical).
        pattern := '"' buttonName '"\s*:\s*\{[^}]*"centerX"\s*:\s*(-?\d+|null)[^}]*"centerY"\s*:\s*(-?\d+|null)'
        if RegExMatch(body, pattern, &match)
        {
            if !(match[1] = "null" || match[2] = "null")
            {
                centerX := match[1] + 0
                centerY := match[2] + 0
                return true
            }
        }

        return false
    }
    catch
    {
        return false
    }
}

ClickPrimaryButtonNative(buttonName)
{
    if !GetPrimaryButtonClientCenter(buttonName, &clientX, &clientY)
        return false

    targetHwnd := GetChromeTargetHwnd()
    if !targetHwnd
        return false

    ; DOM coordinates are viewport-relative; map through Chrome render widget.
    mapHwnd := GetChromeRenderWidgetHwnd(targetHwnd)
    if !mapHwnd
        mapHwnd := targetHwnd

    if !ClientPointToScreen(mapHwnd, clientX, clientY, &screenX, &screenY)
        return false

    ClickNoMoveXY(screenX, screenY)
    return true
}


GetChromeRenderWidgetHwnd(targetHwnd)
{
    if !targetHwnd
        return 0

    try controls := WinGetControlsHwnd("ahk_id " targetHwnd)
    catch
        return 0

    for ctrlHwnd in controls
    {
        try cls := WinGetClass("ahk_id " ctrlHwnd)
        catch
            continue

        if (cls = "Chrome_RenderWidgetHostHWND")
            return ctrlHwnd
    }

    return 0
}

GetChromeTargetHwnd()
{
    local hwnd := 0
    
    ; Try Chrome first (any state: visible, minimized, hidden)
    hwnd := WinExist("ahk_exe chrome.exe")
    if hwnd
        return hwnd
    
    ; If Chrome not found, try Brave
    hwnd := WinExist("ahk_exe brave.exe")
    if hwnd
        return hwnd
    
    ; Last resort: check if active window is Chrome/Brave
    if WinActive("ahk_exe chrome.exe") || WinActive("ahk_exe brave.exe")
        return WinExist("A")
    
    ; If we still haven't found it, the browser is likely closed/minimized
    return 0
}

ClientPointToScreen(hwnd, clientX, clientY, &screenX, &screenY)
{
    screenX := 0
    screenY := 0
    if !hwnd
        return false

    pt := Buffer(8, 0)
    NumPut("Int", clientX, pt, 0)
    NumPut("Int", clientY, pt, 4)
    if !DllCall("ClientToScreen", "Ptr", hwnd, "Ptr", pt, "Int")
        return false

    screenX := NumGet(pt, 0, "Int")
    screenY := NumGet(pt, 4, "Int")
    return true
}

ClickPrimaryButtonNativeRetry(buttonName, attempts := 1, delayMs := 0)
{
    Loop attempts
    {
        if ClickPrimaryButtonNative(buttonName)
            return true
        if (delayMs > 0)
            Sleep(delayMs)
    }
    return false
}

ClickPrimaryButtonNativeWhenEnabled(buttonName, timeoutMs := 260, pollMs := 35)
{
    deadline := A_TickCount + timeoutMs
    while (A_TickCount <= deadline)
    {
        if IsPrimaryExtensionButtonEnabled(buttonName, false)
            return ClickPrimaryButtonNativeRetry(buttonName, 1, 0)
        Sleep(pollMs)
    }
    return false
}

ClickInternetAfterPriceSeen(timeoutMs := 2200)
{
    if ClickPrimaryButtonNativeWhenEnabled("internet", timeoutMs, 50)
        return true

    ; Fallback for helper lag: if the button-state endpoint misses the enabled
    ; transition, still try the direct native click once before moving on.
    return ClickPrimaryButtonNative("internet")
}

GetVisibleInternetPriceNumber()
{
    internetNum := GetLiveInternetSafetyNumber()
    if (internetNum <= 0)
        internetNum := NormalizeToNumber(ReadInternetBidPrice())
    return internetNum
}

IsPrimaryExtensionButtonEnabled(buttonName, defaultValue := true)
{
    try
    {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "http://localhost:9999/button-states", false)
        req.Send()
        if (req.Status != 200)
            return defaultValue

        body := req.ResponseText
        ; Match: "internet":{"exists":true,"enabled":false,...}
        pattern := '"' buttonName '"\s*:\s*\{[^}]*"enabled"\s*:\s*(true|false)'
        if RegExMatch(body, pattern, &match)
            return (match[1] = "true")
    }
    catch
    {
    }

    return defaultValue
}

; True when content script marks internet as live: enabled and (price in label or recent style/disabled change).
IsInternetReadyFromExtension(requirePrice := false)
{
    try
    {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "http://localhost:9999/button-states", false)
        req.Send()
        if (req.Status != 200)
            return false

        body := req.ResponseText
        
        ; If we require a price (for safety stops), check for BOTH enabled:true AND a non-zero price
        if (requirePrice)
        {
            ; Must be enabled
            if !RegExMatch(body, '"internet"\s*:\s*\{[^}]*"enabled"\s*:\s*true')
                return false
                
            ; For safety stops, require the live button label itself to contain
            ; a real dollar price. Plain "Internet" means no active internet bid.
            intBidRaw := ReadInternetBidPriceFromExtensionBody(body)
            if !RegExMatch(intBidRaw, "\$\s*[\d,]+")
                return false

            return (NormalizeToNumber(intBidRaw) > 0)
        }

        ; Otherwise (for bidding), just check if Internet button is ENABLED
        if RegExMatch(body, '"internet"\s*:\s*\{[^}]*"enabled"\s*:\s*true')
            return true
    }
    catch
    {
    }

    return false
}

WaitForInternetDisabled(timeoutMs := 1000, pollMs := 90)
{
    deadline := A_TickCount + timeoutMs
    while (A_TickCount <= deadline)
    {
        if !IsPrimaryExtensionButtonEnabled("internet", true)
            return true
        Sleep(pollMs)
    }
    return false
}

IsAskCloseToBidEstimate(thresholdPercent := 5)
{
    global CalcBaseText

    askRaw := ReadCurrentAskPrice()
    askClean := RegExReplace(askRaw, "[^\d\.]")
    if (askClean = "")
        return false

    baseClean := ""
    if IsObject(CalcBaseText)
        baseClean := RegExReplace(CalcBaseText.Text, "[^\d\.]")
    if (baseClean = "")
        return false

    askNum := askClean + 0
    baseNum := baseClean + 0
    if (askNum <= 0 || baseNum <= 0)
        return false

    return Abs(askNum - baseNum) <= (baseNum * (thresholdPercent / 100))
}

ComparePriceToFinal()
{
    global CalcFinalText

    askRaw := ReadCurrentAskPrice()
    askClean := RegExReplace(askRaw, "[^\d\.]")
    if (askClean = "")
        return "UNKNOWN"

    finalClean := ""
    if IsObject(CalcFinalText)
        finalClean := RegExReplace(CalcFinalText.Text, "[^\d\.]")
    if (finalClean = "")
        return "UNKNOWN"

    askNum := askClean + 0
    finalValueUnrounded := finalClean + 0
    if (askNum <= 0 || finalValueUnrounded <= 0)
        return "UNKNOWN"

    ; Smart Rounding based on tiered increments
    increment := GetBidIncrement(askNum)
    finalNum := Round(finalValueUnrounded / increment) * increment

    if (askNum < finalNum)
        return "LOWER"
    else if (askNum = finalNum)
        return "EQUALS"
    else
        return "HIGHER"
}

; ===============================
; HELPER
; ===============================

ClickAndBack(x, y)
{
    ; Physical fallback removed
    ClickNoMoveXY(x, y)
}

ClickX(x, y) {
    ; Physical fallback removed
    ClickNoMoveXY(x, y)
}

ClickNoMoveXY(x, y, count := 1)
{
    targetHwnd := GetChromeTargetHwnd()
    if (!targetHwnd)
        return

    mapHwnd := GetChromeRenderWidgetHwnd(targetHwnd)
    if (!mapHwnd)
        mapHwnd := targetHwnd

    ; Verify handle is still valid before clicking
    if (!WinExist("ahk_id " mapHwnd))
        return

    ; Convert screen coordinates to window-relative for ControlClick
    pt := Buffer(8)
    NumPut("int", x, "int", y, pt)
    if (!DllCall("ScreenToClient", "Ptr", mapHwnd, "Ptr", pt))
        return
    
    cX := NumGet(pt, 0, "int")
    cY := NumGet(pt, 4, "int")

    Loop count
    {
        try
        {
            ; ControlClick with NA (No Activate) - keeps window in background
            ; Use the render widget for most accurate clicking
            ControlClick("X" cX " Y" cY, "ahk_id " mapHwnd, , "Left", 1, "NA")
        }
        catch
        {
            ; If that fails, try the main window as fallback
            try
            {
                ControlClick("X" cX " Y" cY, "ahk_id " targetHwnd, , "Left", 1, "NA")
            }
            catch
            {
                ; Both failed silently
                return
            }
        }
        if (A_Index < count)
            Sleep(20)
    }
}

PgUp::
{
    return
}



; ===============================
; COMBO FUNCTIONS (Merged from combo.ahk)
; ===============================

; ===============================
; CTRL+R – FORCE RELOAD WITH STATE RESUME
; ===============================
F4::ForceReloadWithResume()

ForceReloadWithResume(showMsg := 0)
{
    global autoClerkActive, stateFile, pressCount
    global pacingTargetAbsoluteLotMark, pacingAbsoluteDeadline, pacingStartLot, pacingStartTime
    global manualTargetLPH, autoClerkPhase, f10TriggerTime, lotAtTopOfHour, elapsedWaitMs
    
    ; Save normal session count (AuctionSessions.ini)
    SaveSessionCount()
    SavePacingSettings()
    SavePacingCarryState()
    
    ; Create a temporary file to signal that this is a state-resuming reload
    stateFile := A_Temp "\bidhelper_reload_resume.ini"
    try
    {
        if FileExist(stateFile)
            FileDelete(stateFile)
            
        outStr := "AutoClerk=" (autoClerkActive ? "1" : "0") "`n"
        outStr .= "PressCount=" pressCount "`n"
        outStr .= "PacingTarget=" pacingTargetAbsoluteLotMark "`n"
        outStr .= "PacingDeadline=" pacingAbsoluteDeadline "`n"
        outStr .= "PacingStart=" pacingStartLot "`n"
        outStr .= "PacingStartTime=" pacingStartTime "`n"
        outStr .= "ManualLPH=" manualTargetLPH "`n"
        outStr .= "ClerkPhase=" autoClerkPhase "`n"
        outStr .= "LotAtTopOfHour=" lotAtTopOfHour "`n"
        elapsedWaitMs := (autoClerkPhase = "WAITING" && f10TriggerTime > 0) ? (A_TickCount - f10TriggerTime) : 0
        outStr .= "ElapsedWaitMs=" elapsedWaitMs "`n"
        global autoClerkWaitMs
        outStr .= "AutoClerkWaitMs=" autoClerkWaitMs "`n"
        outStr := AppendReloadPacingSnapshot(outStr)
        
        if (showMsg == 1)
            outStr .= "ShowF4ReloadAlert=1`n"
        
        FileAppend(outStr, stateFile)
    }
    
    ToolTip("Reloading FastBid...")
    Sleep(500)
    if A_IsCompiled
        Run('"' A_ScriptFullPath '"')
    else
        Run('"' A_AhkPath '" "' A_ScriptFullPath '"')
    ExitApp()
}

ForceReloadSafetyStop()
{
    global stateFile, pressCount
    global pacingAbsoluteDeadline, pacingStartLot, pacingStartTime
    global manualTargetLPH, autoClerkPhase, lotAtTopOfHour
    
    SaveSessionCount()
    SavePacingSettings()
    SavePacingCarryState()
    
    stateFile := A_Temp "\bidhelper_reload_resume.ini"
    try
    {
        if FileExist(stateFile)
            FileDelete(stateFile)
            
        outStr := "AutoClerk=0`n"
        outStr .= "PressCount=" pressCount "`n"
        outStr .= "PacingTarget=0`n"
        outStr .= "PacingDeadline=" pacingAbsoluteDeadline "`n"
        outStr .= "PacingStart=" pacingStartLot "`n"
        outStr .= "PacingStartTime=" pacingStartTime "`n"
        outStr .= "ManualLPH=" manualTargetLPH "`n"
        outStr .= "ClerkPhase=" autoClerkPhase "`n"
        outStr .= "LotAtTopOfHour=" lotAtTopOfHour "`n"
        outStr .= "ElapsedWaitMs=0`n"
        global autoClerkWaitMs
        outStr .= "AutoClerkWaitMs=" autoClerkWaitMs "`n"
        outStr := AppendReloadPacingSnapshot(outStr)
        outStr .= "ShowSafetyAlert=1`n"
        
        FileAppend(outStr, stateFile)
    }
    
    ToolTip("Safety Limit: Reloading FastBid...")
    Sleep(500)
    if A_IsCompiled
        Run('"' A_ScriptFullPath '"')
    else
        Run('"' A_AhkPath '" "' A_ScriptFullPath '"')
    ExitApp()
}

ForceReloadDesignatedLotStop()
{
    global stateFile, pressCount
    global pacingAbsoluteDeadline, pacingStartLot, pacingStartTime
    global manualTargetLPH, autoClerkPhase, lotAtTopOfHour
    global pacingTargetAbsoluteLotMark, autoClerkActive, pacingStopPending, CurrentAuctionUID

    ; If this is an hourly/multi-hour pacing session, reaching the designated
    ; lot means pause for the hour boundary and resume, not final-stop.
    if (pacingAbsoluteDeadline != "" && DateDiff(pacingAbsoluteDeadline, A_Now, "Seconds") > 3600)
        return ForceReloadAdvancedGoalResume()
    
    SaveSessionCount()
    SavePacingSettings()
    SavePacingCarryState()
    reloadSnapshot := AppendReloadPacingSnapshot("")
    autoClerkActive := false
    pacingStopPending := false
    pacingTargetAbsoluteLotMark := 0
    pacingAbsoluteDeadline := ""
    SetTimer(RecalibratePacing, 0)
    SetTimer(UpdatePacingMonitor, 0)
    SetTimer(AutoClerkTick, 0)

    try {
        auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
        iniFile := A_ScriptDir "\AuctionSessions.ini"
        IniWrite("", iniFile, "Pacing_" auctionId, "Deadline")
        IniWrite("", iniFile, "Pacing_" auctionId, "SessionStartTime")
        IniWrite("", iniFile, "Pacing_General", "Deadline")
    }
    
    stateFile := A_Temp "\bidhelper_reload_resume.ini"
    try
    {
        if FileExist(stateFile)
            FileDelete(stateFile)
            
        outStr := "AutoClerk=0`n"
        outStr .= "PressCount=" pressCount "`n"
        outStr .= "PacingTarget=0`n"
        outStr .= "PacingDeadline=`n"
        outStr .= "PacingStart=" pacingStartLot "`n"
        outStr .= "PacingStartTime=`n"
        outStr .= "ManualLPH=" manualTargetLPH "`n"
        outStr .= "ClerkPhase=" autoClerkPhase "`n"
        outStr .= "LotAtTopOfHour=" lotAtTopOfHour "`n"
        outStr .= "ElapsedWaitMs=0`n"
        global autoClerkWaitMs
        outStr .= "AutoClerkWaitMs=" autoClerkWaitMs "`n"
        outStr .= reloadSnapshot
        outStr .= "ShowDesignatedLotAlert=1`n"
        
        FileAppend(outStr, stateFile)
    }
    
    ToolTip("Goal Met: Reloading FastBid...")
    Sleep(500)
    if A_IsCompiled
        Run('"' A_ScriptFullPath '"')
    else
        Run('"' A_AhkPath '" "' A_ScriptFullPath '"')
    ExitApp()
}

ForceReloadAdvancedGoalResume()
{
    global stateFile, pressCount
    global pacingAbsoluteDeadline, pacingStartLot
    global manualTargetLPH, lotAtTopOfHour, autoClerkWaitMs
    global autoClerkActive, pacingStopPending, pacingTargetAbsoluteLotMark, CurrentAuctionUID

    phTime := GetPHTime()
    resumeAtNextHour := (phTime != "" && IsPacingPauseMinute(SubStr(phTime, 11, 2)))
    secondsRemaining := (pacingAbsoluteDeadline != "") ? DateDiff(pacingAbsoluteDeadline, A_Now, "Seconds") : 0
    shouldResumeSession := (secondsRemaining > 3600)

    SaveSessionCount()
    SavePacingSettings()
    SavePacingCarryState()
    reloadSnapshot := AppendReloadPacingSnapshot("")
    autoClerkActive := false
    pacingStopPending := false
    pacingTargetAbsoluteLotMark := 0
    pacingAbsoluteDeadline := ""
    SetTimer(RecalibratePacing, 0)
    SetTimer(UpdatePacingMonitor, 0)
    SetTimer(AutoClerkTick, 0)

    try {
        auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
        iniFile := A_ScriptDir "\AuctionSessions.ini"
        IniWrite("", iniFile, "Pacing_" auctionId, "Deadline")
        IniWrite("", iniFile, "Pacing_" auctionId, "SessionStartTime")
        IniWrite("", iniFile, "Pacing_General", "Deadline")
    }

    stateFile := A_Temp "\bidhelper_reload_resume.ini"
    try
    {
        if FileExist(stateFile)
            FileDelete(stateFile)

        outStr := "AutoClerk=" (shouldResumeSession ? "1" : "0") "`n"
        outStr .= "PressCount=" pressCount "`n"
        outStr .= "PacingTarget=0`n"
        outStr .= "PacingDeadline=`n"
        outStr .= "PacingStart=" pacingStartLot "`n"
        outStr .= "PacingStartTime=`n"
        outStr .= "ManualLPH=" manualTargetLPH "`n"
        outStr .= "ClerkPhase=BIDDING`n"
        outStr .= "LotAtTopOfHour=" lotAtTopOfHour "`n"
        outStr .= "ElapsedWaitMs=0`n"
        outStr .= "AutoClerkWaitMs=" autoClerkWaitMs "`n"
        outStr .= reloadSnapshot
        if (shouldResumeSession && resumeAtNextHour)
            outStr .= "ResumeAtNextHour=1`n"
        if (shouldResumeSession)
            outStr .= "ShowOneHourPauseAlert=1`n"
        if (!shouldResumeSession)
            outStr .= "ShowDesignatedLotAlert=1`n"

        FileAppend(outStr, stateFile)
    }

    ToolTip(shouldResumeSession ? (resumeAtNextHour ? "Goal passed: reload, resume at :00..." : "Goal passed: reloading and resuming bot...") : "Goal passed: reloading and stopping...")
    Sleep(500)
    if A_IsCompiled
        Run('"' A_ScriptFullPath '"')
    else
        Run('"' A_AhkPath '" "' A_ScriptFullPath '"')
    ExitApp()
}

ForceReloadInternetLimitStop()
{
    ; Internet >= Bid Estimate is a real safety stop, not an F4 stuck-bot resume.
    ForceReloadSafetyStop()
}

ForceReloadByReason(reason)
{
    if (reason = "internet_limit")
        return ForceReloadInternetLimitStop()
    if (reason = "goal_lot")
        return ForceReloadDesignatedLotStop()
    if (reason = "safety")
        return ForceReloadSafetyStop()
    if (reason = "f4")
        return ForceReloadWithResume(1)

    return ForceReloadSafetyStop()
}

IsPacingLockActive()
{
    global PacingToggleBtn
    return IsObject(PacingToggleBtn) && (PacingToggleBtn.Text = "STOP BOT" || PacingToggleBtn.Text = "STOP PACE")
}

PauseAutoClerkAtDesignatedLot(statusText := "PAUSED: GOAL F10")
{
    global autoClerkActive, autoClerkPhase, pacingStopPending
    global CalcTimerText, SessionClockText, AutoClerkToggleBtn, PacingProgressText

    autoClerkActive := false
    autoClerkPhase := "STOPPED"
    pacingStopPending := false
    SetTimer(AutoClerkTick, 0)

    if IsObject(CalcTimerText)
        CalcTimerText.Text := statusText
    if IsObject(SessionClockText)
        SessionClockText.Text := statusText
    if IsObject(AutoClerkToggleBtn)
        AutoClerkToggleBtn.Text := "â–¶"
    if IsObject(PacingProgressText)
    {
        PacingProgressText.Text := "PAUSED"
        PacingProgressText.SetFont("cFFD166")
    }

    SoundBeep(750, 180)
    return true
}

HandleDesignatedLotStopGuard(source := "")
{
    global autoClerkActive, pacingTargetAbsoluteLotMark, currentAuctionProgressNumber
    global pacingStopPending, lotIsClosed, autoClerkPhase, CalcTimerText

    if (!autoClerkActive || !IsPacingLockActive() || pacingTargetAbsoluteLotMark <= 0 || currentAuctionProgressNumber <= 0)
        return false

    ; If telemetry jumped past the target, stop immediately.
    if IsPacingGoalPassed()
    {
        ForceReloadAdvancedGoalResume()
        return true
    }

    if !IsPacingGoalExact()
        return false

    ; FASTBID behavior: reaching the designated lot means finish/end this lot,
    ; not pause at F10. F11's final goal safety will stop before Next.
    pacingStopPending := true
    if IsObject(CalcTimerText)
        CalcTimerText.Text := "GOAL: FINISH LOT"

    ; Never finish/reload the designated lot until F10 has actually fired for
    ; this exact lot. This prevents the last lot from hanging/stopping at F10.
    if (!WasEventDone("F10"))
        return false

    if (lotIsClosed || autoClerkPhase = "NEXT" || autoClerkPhase = "STOPPED")
    {
        ForceReloadDesignatedLotStop()
        return true
    }

    return false
}

IsPacingGoalReached()
{
    global pacingTargetAbsoluteLotMark, currentAuctionProgressNumber, pacingStartLot

    if (pacingTargetAbsoluteLotMark <= 0 || currentAuctionProgressNumber <= 0)
        return false

    if (currentAuctionProgressNumber = pacingTargetAbsoluteLotMark)
        return true

    if (pacingStartLot > pacingTargetAbsoluteLotMark)
        return currentAuctionProgressNumber <= pacingTargetAbsoluteLotMark

    if (pacingStartLot < pacingTargetAbsoluteLotMark)
        return currentAuctionProgressNumber >= pacingTargetAbsoluteLotMark

    return false
}

IsPacingGoalExact()
{
    global pacingTargetAbsoluteLotMark, currentAuctionProgressNumber

    if (pacingTargetAbsoluteLotMark <= 0 || currentAuctionProgressNumber <= 0)
        return false

    return (currentAuctionProgressNumber = pacingTargetAbsoluteLotMark)
}

IsPacingGoalPassed()
{
    global pacingTargetAbsoluteLotMark, currentAuctionProgressNumber, pacingStartLot

    if (pacingTargetAbsoluteLotMark <= 0 || currentAuctionProgressNumber <= 0)
        return false

    if (currentAuctionProgressNumber = pacingTargetAbsoluteLotMark)
        return false

    if (pacingStartLot > pacingTargetAbsoluteLotMark)
        return currentAuctionProgressNumber < pacingTargetAbsoluteLotMark

    if (pacingStartLot < pacingTargetAbsoluteLotMark)
        return currentAuctionProgressNumber > pacingTargetAbsoluteLotMark

    return false
}

; --- LOT EVENT TRACKING ---
SaveLotEvent(eventName)
{
    global CurrentActiveLotID
    eventsFile := A_Temp "\bidhelper_lot_events.ini"
    
    content := ""
    try content := FileRead(eventsFile)
    
    f10_val := 0
    f11_val := 0
    lot_val := ""
    
    if RegExMatch(content, "LotID=([^\r\n]+)", &m)
        lot_val := m[1]
    if RegExMatch(content, "F10=(\d+)", &m)
        f10_val := m[1] + 0
    if RegExMatch(content, "F11=(\d+)", &m)
        f11_val := m[1] + 0
        
    if (eventName = "F10")
        f10_val := 1
    if (eventName = "F11")
        f11_val := 1
        
    global currentAuctionProgressNumber
    lot_val := currentAuctionProgressNumber
    
    outStr := "LotNum=" lot_val "`n"
    outStr .= "F10=" f10_val "`n"
    outStr .= "F11=" f11_val "`n"
    
    try
    {
        if FileExist(eventsFile)
            FileDelete(eventsFile)
        FileAppend(outStr, eventsFile)
    }
}

WasEventDone(eventName)
{
    global CurrentActiveLotID
    eventsFile := A_Temp "\bidhelper_lot_events.ini"
    
    try
    {
        content := FileRead(eventsFile)
        if RegExMatch(content, "LotNum=([^\r\n]+)", &m)
        {
            savedLot := m[1]
            global currentAuctionProgressNumber
            if (savedLot != String(currentAuctionProgressNumber))
                return false
                
            if RegExMatch(content, eventName "=(\d+)", &m)
                return (m[1] = "1")
        }
    }
    return false
}

ClearLotEvents()
{
    eventsFile := A_Temp "\bidhelper_lot_events.ini"
    try
    {
        if FileExist(eventsFile)
            FileDelete(eventsFile)
    }
}

WriteNextBidDisplay(currentHotkey)
{
    global progressiveF8Step, helperConfigs
    config := helperConfigs[GetCurrentMode()]
    
    if (currentHotkey = "F8")
    {
        target := GetProgressiveF8Target()
        ladder := BuildProgressiveF8Ladder(target)
        
        ; Find the next rung blindly (Smart Jump disabled)
        displayStep := progressiveF8Step
        nextBid := 0
        if (displayStep < ladder.Length)
        {
            nextBid := ladder[displayStep + 1]
        }
        
        if (nextBid > 0)
        {
            ; F8 ladder info removed from UI
        }
        else
        {
            ; F8 ladder info removed from UI
        }
    }
}

HandleProgressiveF8()
{
    global InternetBtn, CompetingBtn, allowF10, CalcFinalText
    
    global lastF8Tick
    if (A_TickCount - lastF8Tick < 1300)
        return
    lastF8Tick := A_TickCount

    ; Safety gate: Stop F8 if !!!! is 0 or below.
    finalValue := GetProgressiveF8FullValue()
    if (finalValue <= 0)
    {
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "F8 STOPPED (<=0)"
        return
    }
    
    amount := AdvanceProgressiveF8()
    if (amount = "")
        return

    ; Bidding successfully unlocks F10 for ending the lot
    allowF10 := true
    SaveSessionCount()
    BidAmount(amount)
    global currentLotDidBid
    currentLotDidBid := true
    WriteNextBidDisplay("F8")
}

ResetProgressiveF8Manual()
{
    global progressiveF8Step, allowF10, allowF11, progressiveLockedLotToken
    
    if (progressiveF8Step = 0)
        return
    
    allowF10 := false  ; Reset F10 on manual reset
    allowF11 := true  ; Re-enable F11 after reset
    progressiveLockedLotToken := ""  ; UNLOCK the F8 mechanism!
    
    progressiveF8Step := 0
    if IsObject(CalcTimerText)
        CalcTimerText.Text := "⏱ TIMER"
}

GetProgressiveF8FullValue()
{
    global progressiveLastFinalValue, CalcFinalText
    
    if (progressiveLastFinalValue != "" && progressiveLastFinalValue != 0)
        return progressiveLastFinalValue
    
    if (!IsObject(CalcFinalText))
        return 0
    
    cleanVal := RegExReplace(CalcFinalText.Text, "[^\d\.]")
    if (cleanVal = "")
        return 0
        
    return cleanVal + 0
}

SetWaitModeFromDropDown(*) {
    global autoClerkWaitMs, CalcWaitDropDown, isUpdatingPaceDisplay
    
    if (isUpdatingPaceDisplay)
        return
    
    txt := CalcWaitDropDown.Text
    seconds := NormalizeToNumber(txt)
    if (seconds <= 0)
        seconds := 6 ; Fallback to default
    autoClerkWaitMs := seconds * 1000
    SaveWaitMode()
}

SaveWaitMode() {
    global autoClerkWaitMs
    try {
        waitModeObj := FileOpen(A_Temp "\bidhelper_wait_mode.txt", "w")
        waitModeObj.Write(autoClerkWaitMs)
        waitModeObj.Close()
    }
}

LoadWaitMode() {
    global autoClerkWaitMs, CalcWaitDropDown
    path := A_Temp "\bidhelper_wait_mode.txt"
    if !FileExist(path)
        return
    try {
        rawVal := FileRead(path)
        val := RegExReplace(Trim(rawVal, " `t`r`n"), "[^\d]")
        ms := val + 0
        if (ms >= 6000 && ms <= 120000) {
            autoClerkWaitMs := ms
            ; The dropdown text will be updated by the caller if needed
        } else {
            autoClerkWaitMs := timerCueMs
        }
    }
}

GetCurrentMode()
{
    global helperConfigs
    fullValue := GetProgressiveF8FullValue()
    
    if (fullValue <= helperConfigs["micro"].threshold)
        return "micro"
    if (fullValue <= helperConfigs["small"].threshold)
        return "small"
    if (fullValue <= helperConfigs["medium"].threshold)
        return "medium"
    if (fullValue <= helperConfigs["large"].threshold)
        return "large"
    if (fullValue <= helperConfigs["ultra"].threshold)
        return "ultra"
    return "mega"
}

ShouldRepeatCurrentF8Step()
{
    global repeatF8SignalFile, lastRepeatF8Signal
    
    signalValue := ReadHelperFile(repeatF8SignalFile)
    if (signalValue = "" || signalValue = lastRepeatF8Signal)
        return false
    
    lastRepeatF8Signal := signalValue
    return true
}

AdvanceProgressiveF8()
{
    global progressiveF8Step, progressiveLockedLotToken, helperConfigs, lotTokenFile
    
    ; Basic checks and reset
    ResetProgressiveF8IfNeeded()
    
    ; Lock check (prevent repeat bid on same lot if fully done)
    currentLotToken := GetCurrentLotToken()
    if (currentLotToken != "" && currentLotToken = progressiveLockedLotToken)
        return ""

    ; Get the target and the ladder
    target := GetProgressiveF8Target()
    ladder := BuildProgressiveF8Ladder(target)
    if (ladder.Length = 0)
        return ""

    ; Note: step sync is handled by AutoClerkTick before calling this function.
    ; No second sync here to prevent double-skipping of ladder rungs.

    ; Handle repeat signals
    if (ShouldRepeatCurrentF8Step() && progressiveF8Step >= 1)
    {
        return ladder[progressiveF8Step]
    }

    ; Increment the step for the actual click
    progressiveF8Step += 1
    
    ; Boundary check
    if (progressiveF8Step > ladder.Length)
    {
        if (currentLotToken != "")
            progressiveLockedLotToken := currentLotToken
        return ""
    }

    return ladder[progressiveF8Step]
}

GetProgressiveF8Target()
{
    fullValue := GetProgressiveF8FullValue()
    percentMultiplier := GetProgressiveTargetMultiplier()
    target := RoundDownProgressiveAmount(Integer(fullValue * percentMultiplier))
    if (target < 0)
        target := 0
    return target
}

GetProgressiveTargetMultiplier()
{
    global targetPercentMode, percentModeFile
    ; Prefer the live UI-selected mode first.
    percentMode := targetPercentMode
    if !(percentMode = "1" || percentMode = "5" || percentMode = "10")
        percentMode := ReadHelperFile(percentModeFile)

    if (percentMode = "1")
        return 0.99
    return (percentMode = "5") ? 0.95 : 0.90
}

BuildProgressiveF8Ladder(target)
{
    global f8LadderConfigLoaded
    
    if (target <= 0)
        return [0]
    
    ; ===== STEP 1: Try to load from AuctionSessions.ini config =====
    if (f8LadderConfigLoaded)
    {
        configLadder := GetF8LadderForValue(target)
        if (configLadder.Length > 0)
        {
            ; Filter ladder to only include rungs below target
            filteredLadder := []
            for rung in configLadder
            {
                if (rung < target)
                    filteredLadder.Push(rung)
            }
            
            ; Add target as final rung if not already included
            if (filteredLadder.Length = 0 || filteredLadder[filteredLadder.Length] < target)
                filteredLadder.Push(target)
            
            if (filteredLadder.Length > 0)
                return filteredLadder  ; Use config ladder!
        }
    }
    
    ; ===== STEP 2: Fallback to hardcoded defaults =====
    snappedTarget := SnapToAuctionIncrement(target)
    ladder := []
    milestones := []
    
    ; 1. Define milestones based on Digit count (Granular steps)
    if (target < 1000) ; 3 Digits - Every $100
    {
        milestones := [200, 300, 400, 500, 600, 700, 800, 900]
    }
    else if (target <= 2500) ; 1001-2500 Bracket
    {
        milestones := [300, 500, 700, 1000, 1200, 1500, 2000]
    }
    else if (target <= 5000) ; 2501-5000 Bracket
    {
        milestones := [300, 500, 700, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500]
    }
    else if (target <= 10000) ; 5001-10000 Bracket
    {
        milestones := [300, 500, 700, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]
    }
    else if (target <= 25000) ; 10001-25000 Bracket
    {
        milestones := [300, 500, 700, 1000, 3000, 5000, 7000, 10000, 15000, 20000, 24000]
    }
    else if (target <= 50000) ; 25001-50000 Bracket
    {
        milestones := [300, 500, 700, 1000, 3000, 5000, 7000, 10000, 15000, 20000, 25000, 30000, 35000, 40000, 45000]
    }
    else if (target < 100000) ; 5 Digits - pattern: 100,500,1k,3k,5k,7k,10k,30k,50k,70k...
    {
        milestones := [100, 500, 1000, 3000, 5000, 7000, 10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]
    }
    else if (target <= 250000) ; 100001-250000 Bracket
    {
        milestones := [300, 500, 700, 1000, 3000, 5000, 7000, 10000, 30000, 50000, 70000, 100000, 150000, 200000, 240000]
    }
    else if (target <= 500000) ; 250001-500000 Bracket
    {
        milestones := [300, 500, 700, 1000, 3000, 5000, 7000, 10000, 30000, 50000, 70000, 100000, 150000, 200000, 250000, 300000, 350000, 400000, 450000]
    }
    else if (target <= 1000000) ; 500001-1000000 Bracket
    {
        milestones := [100, 500, 1000, 3000, 5000, 7000, 10000, 30000, 50000, 70000, 100000, 200000, 300000, 400000, 500000, 600000, 700000, 800000, 900000, 1000000]
    }
    else if (target <= 2500000) ; 1000001-2500000 Bracket
    {
        milestones := [300, 500, 700, 1000, 3000, 5000, 7000, 10000, 30000, 50000, 70000, 100000, 300000, 500000, 700000, 1000000, 1500000, 2000000, 2400000]
    }
    else if (target <= 5000000) ; 2500001-5000000 Bracket
    {
        milestones := [300, 500, 700, 1000, 3000, 5000, 7000, 10000, 30000, 50000, 70000, 100000, 300000, 500000, 700000, 1000000, 1500000, 2000000, 2500000, 3000000, 3500000, 4000000, 4500000]
    }
    else if (target <= 10000000) ; 5000001-10000000 Bracket
    {
        milestones := [100, 500, 1000, 3000, 5000, 7000, 10000, 30000, 50000, 70000, 100000, 300000, 500000, 700000, 1000000, 2000000, 3000000, 4000000, 5000000, 6000000, 7000000, 8000000, 9000000, 10000000]
    }
    else ; 10M+ fallback - same base pattern then larger steps
    {
        milestones := [100, 500, 1000, 3000, 5000, 7000, 10000, 30000, 50000, 70000, 100000]
        
        ; Continue with MUCH larger leaps up to target for high value items
        curr := 100000
        leapSize := (target > 1000000) ? 50000 : 10000
        while (curr < target && curr < 10000000) ; Cap at 10M safety
        {
            curr += leapSize
            milestones.Push(curr)
        }
    }
    
    ; 2. Build the Final Ladder (Filter and Dedup)
    lastVal := 0
    for m in milestones
    {
        snappedM := SnapToAuctionIncrement(m)
        if (snappedM > lastVal && snappedM < snappedTarget)
        {
            ladder.Push(snappedM)
            lastVal := snappedM
        }
    }
    
    ; 2b. CLEAN FLOOR RUNG (Global Rule):
    ; Always land F8 on the nearest clean round number BELOW the target.
    ; F9 then fills the remaining individual increments up to the target.
    ; Examples: $15,000 target → stop at $14,000 | $1,500 target → stop at $1,000 | $500 target → stop at $400
    if (snappedTarget >= 10000)
        roundUnit := 1000       ; e.g. $15,000 → $14,000
    else if (snappedTarget >= 1000)
        roundUnit := 500        ; e.g. $1,500  → $1,000
    else if (snappedTarget >= 100)
        roundUnit := 50         ; e.g. $480 → $450  |  $800 → $750  (~5-6 tiers gap)
    else
        roundUnit := 25         ; e.g. $75 → $50
        
    cleanFloorRung := Floor(snappedTarget / roundUnit) * roundUnit
    if (cleanFloorRung > lastVal && cleanFloorRung < snappedTarget)
    {
        ladder.Push(cleanFloorRung)
        lastVal := cleanFloorRung
    }
    
    ; 3. Always end with the snapped target
    if (snappedTarget > lastVal)
        ladder.Push(snappedTarget)
    else if (ladder.Length = 0)
        ladder.Push(target)
        
    return ladder
}

SnapTo(val, increment)
{
    rounded := Round(val / increment) * increment
    if (rounded < increment)
        rounded := increment
    return rounded
}

RoundDownProgressiveAmount(value)
{
    increment := 25
    rounded := Floor(value / increment) * increment
    if (rounded < 0)
        rounded := 0
    return rounded
}

GetProgressiveIncrement(target)
{
    return 50
}

ResetProgressiveF8IfNeeded()
{
    global lotTokenFile, progressiveF8Step, progressiveLastLotToken, progressiveLockedLotToken, progressiveLastFinalValue, comboCycleResetFile, lastComboCycleResetSignal
    
    currentLotToken := GetCurrentLotToken()
    currentFinalValue := GetProgressiveF8FullValue()
    resetSignalValue := ReadHelperFile(comboCycleResetFile)
    
    if (resetSignalValue != "" && resetSignalValue != lastComboCycleResetSignal)
    {
        progressiveF8Step := 0
        progressiveLockedLotToken := ""
        lastComboCycleResetSignal := resetSignalValue
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "⏱ TIMER"
    }
    
    if (currentFinalValue != progressiveLastFinalValue)
    {
        progressiveF8Step := 0
        progressiveLockedLotToken := ""
        progressiveLastFinalValue := currentFinalValue
    }
    
    if (currentLotToken = "")
        return
    
    if (currentLotToken != progressiveLastLotToken)
    {
        progressiveF8Step := 0
        progressiveLastLotToken := currentLotToken
        progressiveLockedLotToken := ""
    }
}

GetCurrentLotToken()
{
    global lotTokenFile
    return ReadHelperFile(lotTokenFile)
}

ReadInternetBidPrice()
{
    global internetBidPriceFile, internetPriceResetTick

    snapshotInternet := ReadPriceSnapshotField("internet")
    if (snapshotInternet != "" && IsPriceSnapshotForCurrentLot())
        return snapshotInternet

    ; Right after a lot change, ignore the untagged temp-file fallback. It can
    ; be rewritten by the helper with the previous lot's Internet text before
    ; the current lot snapshot catches up.
    if (internetPriceResetTick > 0 && A_TickCount - internetPriceResetTick < 2500)
        return ""

    if !FileExist(internetBidPriceFile)
        return ""
    try {
        return Trim(FileRead(internetBidPriceFile))
    } catch {
        return ""
    }
}

ReadInternetBidPriceFromExtension()
{
    body := FetchButtonStates()
    return ReadInternetBidPriceFromExtensionBody(body)
}

ReadInternetBidPriceFromExtensionBody(body)
{
    if (body = "")
        return ""

    if RegExMatch(body, '"internet"\s*:\s*\{[^}]*"text"\s*:\s*"([^"]*)"', &m)
        return m[1]

    return ""
}

IsPriceSnapshotForCurrentLot()
{
    global priceSnapshotFile, CurrentActiveLotID

    if (CurrentActiveLotID = "")
        return true
    if !FileExist(priceSnapshotFile)
        return false

    try
    {
        body := FileRead(priceSnapshotFile)
        if RegExMatch(body, '"activeLotId"\s*:\s*"([^"]*)"', &m)
            return (m[1] = CurrentActiveLotID)
    }
    catch
    {
    }

    return false
}

ReadPriceSnapshotField(fieldName)
{
    global priceSnapshotFile

    if !FileExist(priceSnapshotFile)
        return ""

    try
    {
        body := FileRead(priceSnapshotFile)
        pattern := '"' fieldName '"\s*:\s*"([^"]*)"'
        if RegExMatch(body, pattern, &m)
            return StrReplace(m[1], '\"', '"')
    }
    catch
    {
    }

    return ""
}

ParseFirstPriceNumber(rawValue)
{
    if (rawValue = "")
        return ""

    savedValue := Trim(rawValue)
    if RegExMatch(savedValue, "^\d+(?:\.\d+)?$")
        return savedValue

    ; Parse range format like "$ 377 - 490" or "$2,691 - $3,498".
    ; Extract the FIRST number only.
    if RegExMatch(savedValue, "\$?\s*([\d,]+)", &m)
    {
        firstNum := StrReplace(m[1], ",", "")
        if (firstNum != "" && firstNum + 0 > 0)
            return firstNum + 0
    }

    return ""
}

IsInternetPriceActiveOrRecent(recentMs := 2000)
{
    global lastInternetSeenTime

    intBidNum := GetLiveInternetSafetyNumber()
    if (intBidNum <= 0)
        intBidNum := NormalizeToNumber(ReadInternetBidPriceFromExtension())
    if (intBidNum <= 0)
        intBidNum := NormalizeToNumber(ReadInternetBidPrice())

    if (intBidNum > 0)
    {
        lastInternetSeenTime := A_TickCount
        return true
    }

    return (lastInternetSeenTime > 0 && (A_TickCount - lastInternetSeenTime) <= recentMs)
}

ReadHelperFile(path)
{
    if !FileExist(path)
        return ""
    try {
        return Trim(FileRead(path))
    } catch {
        return ""
    }
}

ReadCurrentAskPrice()
{
    currentAskPriceFile := A_Temp "\bidhelper_current_ask_price.txt"
    if !FileExist(currentAskPriceFile)
        return ""
    try {
        raw := Trim(FileRead(currentAskPriceFile))
        ; Handle ranges or formatted prices: extract the FIRST valid number
        if RegExMatch(raw, "\$?\s*([\d,]+)", &m)
            return StrReplace(m[1], ",", "")
        return raw
    } catch {
        return ""
    }
}

NormalizeAskValue(rawValue)
{
    return RegExReplace(rawValue "", "[^\d\.]")
}

NormalizeToNumber(val)
{
    if (val = "" || IsObject(val))
        return 0
    str := String(val)
    
    ; Priority: Number following a $ sign
    if RegExMatch(str, "\$\s*([\d,]+(?:\.\d+)?)", &m)
    {
        clean := StrReplace(m[1], ",", "")
        return (clean = "" ? 0 : clean + 0)
    }
    
    ; Fallback: First numerical sequence (digits, commas, dots)
    if RegExMatch(str, "[\d,]+(?:\.\d+)?", &m)
    {
        clean := StrReplace(m[0], ",", "")
        return (clean = "" ? 0 : clean + 0)
    }
    return 0
}

GetInternetLimitNumbers(&bidEstNum, &intBidNum)
{
    global CalcBaseText, CalcInternetText, lastPersistentInternetPrice

    bidEstNum := NormalizeToNumber(IsObject(CalcBaseText) ? CalcBaseText.Text : "")
    intBidNum := NormalizeToNumber(ReadInternetBidPrice())

    if (intBidNum <= 0)
        intBidNum := NormalizeToNumber(ReadInternetBidPriceFromExtension())

    ; The extension can update the visible/persistent value before the temp file
    ; is refreshed, so use the best known internet price for safety stops.
    if (intBidNum <= 0)
        intBidNum := NormalizeToNumber(lastPersistentInternetPrice)

    if (intBidNum <= 0 && IsObject(CalcInternetText))
        intBidNum := NormalizeToNumber(CalcInternetText.Text)
}

GetLiveInternetSafetyNumber()
{
    body := FetchButtonStates()
    intBidRaw := ReadInternetBidPriceFromExtensionBody(body)

    ; Only the live button text "Internet $xxx" is valid for safety reload.
    if !RegExMatch(intBidRaw, "\$\s*[\d,]+")
        return 0

    return NormalizeToNumber(intBidRaw)
}

ForceReloadIfInternetAtBidEstimate(allowNearTier := false)
{
    return CheckInternetLimitReload(allowNearTier)
}

IsInternetAtBidEstimate(&bidEstNum, &intBidNum)
{
    global CalcBaseText
    bidEstNum := NormalizeToNumber(IsObject(CalcBaseText) ? CalcBaseText.Text : "")
    intBidNum := GetLiveInternetSafetyNumber()
    snappedBidEstNum := SnapToAuctionIncrement(bidEstNum)
    tier := GetBidIncrement(snappedBidEstNum)
    safetyFloor := snappedBidEstNum - tier
    safetyCeiling := snappedBidEstNum + tier
    return (bidEstNum > 0 && intBidNum > 0 && intBidNum >= safetyFloor && intBidNum <= safetyCeiling)
}

IsInternetAtSnappedBidEstimate(&bidEstNum, &intBidNum)
{
    global CalcBaseText
    bidEstNum := NormalizeToNumber(IsObject(CalcBaseText) ? CalcBaseText.Text : "")
    intBidNum := GetLiveInternetSafetyNumber()
    snappedBidEstNum := SnapToAuctionIncrement(bidEstNum)
    return (bidEstNum > 0 && intBidNum > 0 && intBidNum >= snappedBidEstNum)
}

CheckInternetLimitReload(allowNearTier := true)
{
    if (allowNearTier)
        hitLimit := IsInternetAtBidEstimate(&bidEstNum, &intBidNum)
    else
        hitLimit := IsInternetAtSnappedBidEstimate(&bidEstNum, &intBidNum)

    if (IsInternetReadyFromExtension(true) && hitLimit)
    {
        ForceReloadByReason("internet_limit")
        return true
    }

    return false
}

ClearF10F11LockForAutoF11()
{
    global f10F11PressLock, f10F11LockAskValue, allowF11

    f10F11PressLock := false
    f10F11LockAskValue := ""
    allowF11 := true
}

LockF10F11UntilNewAsk()
{
    global f10F11PressLock, f10F11LockAskValue, allowF10, allowF11

    f10F11PressLock := true
    f10F11LockAskValue := NormalizeAskValue(ReadCurrentAskPrice())
    allowF10 := false
    allowF11 := false
}

UnlockF10F11OnNewAsk(currentAskRaw := "")
{
    global f10F11PressLock, f10F11LockAskValue

    if !f10F11PressLock
        return false

    askClean := NormalizeAskValue(currentAskRaw)
    if (askClean = "")
        askClean := NormalizeAskValue(ReadCurrentAskPrice())
    if (askClean = "")
        return false

    if (f10F11LockAskValue = "")
    {
        f10F11PressLock := false
        return true
    }

    if (askClean != f10F11LockAskValue)
    {
        f10F11PressLock := false
        f10F11LockAskValue := ""
        return true
    }

    return false
}

FocusSelectCurrentAskInputNative()
{
    if !ClickPrimaryButtonNative("currentask")
        return false

    Sleep(40)

    ; Use ControlSend to target Chrome directly - avoids sending to wrong window
    ; when user is focused on another window
    targetHwnd := GetChromeTargetHwnd()
    if targetHwnd
    {
        mapHwnd := GetChromeRenderWidgetHwnd(targetHwnd)
        if !mapHwnd
            mapHwnd := targetHwnd
        ControlSend("^a", , "ahk_id " mapHwnd)
    }
    else
        Send("^a")  ; fallback only if Chrome not found

    return true
}

TryAutoEnableF11FromBE()
{
    global allowF11, CalcBaseText, f10F11PressLock

    UnlockF10F11OnNewAsk()
    if f10F11PressLock
        return

    askRaw := ReadCurrentAskPrice()
    askClean := RegExReplace(askRaw, "[^\d\.]")
    if (askClean = "")
        return

    baseClean := ""
    if IsObject(CalcBaseText)
        baseClean := RegExReplace(CalcBaseText.Text, "[^\d\.]")
    if (baseClean = "")
        return

    askNum := NormalizeToNumber(askClean)
    baseNum := NormalizeToNumber(baseClean)
    if (askNum <= 0 || baseNum <= 0)
        return

    ; Non-F9 rule: enable F11 when ask matches, exceeds, or is within +/-5% of BE.
    if (askNum >= baseNum || Abs(askNum - baseNum) <= (baseNum * 0.05))
        allowF11 := true
}

TryAutoEnableF10FromFinal()
{
    global allowF10, CalcFinalText, f10F11PressLock

    UnlockF10F11OnNewAsk()
    if f10F11PressLock
        return

    askRaw := ReadCurrentAskPrice()
    askClean := RegExReplace(askRaw, "[^\d\.]")
    if (askClean = "")
        return

    finalClean := ""
    if IsObject(CalcFinalText)
        finalClean := RegExReplace(CalcFinalText.Text, "[^\d\.]")
    if (finalClean = "")
        return

    askNum := NormalizeToNumber(askClean)
    finalNum := NormalizeToNumber(finalClean)
    ; Non-F9 rule: enable F10 when ask matches, exceeds, or is within +/-5% of FINAL.
    if (askNum >= finalNum || Abs(askNum - finalNum) <= (finalNum * 0.05))
        allowF10 := true
}

SnapToAuctionIncrement(price)
{
    if (price <= 0)
    {
        return 0
    }
    
    inc := GetBidIncrement(price)
    if (inc <= 0)
    {
        return price
    }
    
    return Round(price / inc) * inc
}

GetBidIncrement(price)
{
    ; Returns the bid increment based on price tiers provided by the user
    if (price > 100 && price <= 500)
        return 5
    else if (price >= 501 && price <= 1000)
        return 10
    else if (price >= 1001 && price <= 2500)
        return 25
    else if (price >= 2501 && price <= 5000)
        return 50
    else if (price >= 5001 && price <= 10000)
        return 100
    else if (price >= 10001 && price <= 50000)
        return 250
    else if (price >= 50001 && price <= 100000)
        return 500
    else if (price >= 100001 && price <= 1000000)
        return 1000
    else
        return 2  ; Default for prices below $100
}

ResetF9TimerText()
{
    global CalcTimerText, autoClerkActive
    if IsObject(CalcTimerText)
    {
        CalcTimerText.Text := autoClerkActive ? "BOT: PLAYING" : "BOT: PAUSED"
        CalcTimerText.SetFont("cFFFFFF Bold")
        SetTimer(ResetF9TimerText, 0)  ; Stop timer
    }
}



SetCurrentAskInputViaExtension(value, timeoutMs := 1200)
{
    sanitized := Trim(RegExReplace(value "", "[^\d\.]"))
    if (sanitized = "")
        return false

    try
    {
        postReq := ComObject("WinHttp.WinHttpRequest.5.1")
        postReq.Open("POST", "http://localhost:9999/set-current-ask", false)
        postReq.SetRequestHeader("Content-Type", "application/json")
        payload := '{"value":"' sanitized '"}'
        postReq.Send(payload)

        if (postReq.Status != 200)
            return false

        responseText := postReq.ResponseText
        if !RegExMatch(responseText, '"commandId"\s*:\s*"([^"]+)"', &idMatch)
            return false

        commandId := idMatch[1]
        deadline := A_TickCount + timeoutMs
        statusUrl := "http://localhost:9999/set-current-ask-status?id=" commandId

        while (A_TickCount < deadline)
        {
            try
            {
                statusReq := ComObject("WinHttp.WinHttpRequest.5.1")
                statusReq.Open("GET", statusUrl, false)
                statusReq.Send()

                if (statusReq.Status = 200)
                {
                    statusBody := statusReq.ResponseText
                    if RegExMatch(statusBody, '"status"\s*:\s*"done"')
                    {
                        return RegExMatch(statusBody, '"success"\s*:\s*true')
                    }
                }
            }
            catch
            {
            }

            Sleep(80)
        }
    }
    catch
    {
        return false
    }

    return false
}

FocusSelectCurrentAskInputViaExtension(timeoutMs := 900)
{
    try
    {
        postReq := ComObject("WinHttp.WinHttpRequest.5.1")
        postReq.Open("POST", "http://localhost:9999/set-current-ask", false)
        postReq.SetRequestHeader("Content-Type", "application/json")
        postReq.Send('{"selectOnly":true}')

        if (postReq.Status != 200)
            return false

        responseText := postReq.ResponseText
        if !RegExMatch(responseText, '"commandId"\s*:\s*"([^"]+)"', &idMatch)
            return false

        commandId := idMatch[1]
        deadline := A_TickCount + timeoutMs
        statusUrl := "http://localhost:9999/set-current-ask-status?id=" commandId

        while (A_TickCount < deadline)
        {
            try
            {
                statusReq := ComObject("WinHttp.WinHttpRequest.5.1")
                statusReq.Open("GET", statusUrl, false)
                statusReq.Send()

                if (statusReq.Status = 200)
                {
                    statusBody := statusReq.ResponseText
                    if RegExMatch(statusBody, '"status"\s*:\s*"done"')
                        return RegExMatch(statusBody, '"success"\s*:\s*true')
                }
            }
            catch
            {
            }

            Sleep(80)
        }
    }
    catch
    {
        return false
    }

    return false
}

StartExtensionServer()
{
    global serverPID
    
    ; Check if server is already running on port 9999
    try {
        httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        httpRequest.Open("GET", "http://localhost:9999", false)
        httpRequest.Send()
        
        ; If we get here, server is already running
        return
    } catch {
        ; Server not running, start it
    }
    
    ; Start the Node.js server
    serverPath := A_ScriptDir "\extension-server.js"
    if FileExist(serverPath)
    {
        try {
            Run('node "' serverPath '"', A_ScriptDir, "Hide", &serverPID)
            Sleep(1000)  ; Give server time to start
            
            ; Verify server started
            serverStarted := false
            Loop 5 {
                try {
                    httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
                    httpRequest.Open("GET", "http://localhost:9999", false)
                    httpRequest.Send()
                    serverStarted := true
                    break
                } catch {
                    Sleep(1000)
                }
            }
            if !serverStarted
                MsgBox("Failed to start extension server!", "FastBid Error", "Icon!")
        } catch {
            MsgBox("Failed to launch extension server!", "FastBid Error", "Icon!")
        }
    }
}

; Watchdog: silently restart extension server if it goes down
ServerWatchdog()
{
    global serverPID
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "http://localhost:9999", false)
        req.SetTimeouts(1000, 1000, 1000, 1000)
        req.Send()
        ; Server is alive, nothing to do
        return
    } catch {
        ; Server is down - restart it silently
        serverPath := A_ScriptDir "\extension-server.js"
        if FileExist(serverPath) {
            try {
                Run('node "' serverPath '"', A_ScriptDir, "Hide", &serverPID)
            } catch {
                ; silently fail
            }
        }
    }
}

SetCurrentAskInputViaDOM(amount)
{
    buttonStatesFile := A_Temp "\bidhelper_button_states.txt"
    
    ; Wait for the file to exist (extension updates it every 25ms)
    loop 20
    {
        if FileExist(buttonStatesFile)
            break
        Sleep(25)
    }
    
    if !FileExist(buttonStatesFile)
        return false
    
    try {
        buttonStates := FileRead(buttonStatesFile)
        
        targetHwnd := WinExist("Live Auction Clerk Console ahk_exe chrome.exe")
        if !targetHwnd
            targetHwnd := WinExist("Live Auction Clerk ahk_exe chrome.exe")
        if !targetHwnd
            targetHwnd := WinExist("ahk_exe chrome.exe")
            
        mapHwnd := GetChromeRenderWidgetHwnd(targetHwnd)
        
        if !ResolveButtonScreenXY(buttonStates, "currentask", mapHwnd, &inputX, &inputY)
        {
            ToolTip("CurrentAsk Coords FAILED", 10, 10)
            Sleep(800)
            ToolTip()
            return false
        }
        
        global currentAskInputX, currentAskInputY
        currentAskInputX := inputX
        currentAskInputY := inputY
        
        ; NUCLEAR CLEARING SEQUENCE (Background)
        ClickNoMoveXY(inputX, inputY, 3) ; Silent background triple-click
        Sleep(50)
        ControlSend("^a", , "ahk_id " mapHwnd) ; Secondary Force-Select
        Sleep(30)
        ControlSend("{Backspace}", , "ahk_id " mapHwnd) ; Delete everything
        Sleep(50) 
        
        ; Type the new bid amount cleanly in the background wrapper
        ControlSend(amount, , "ahk_id " mapHwnd)
        Sleep(250) ; Settle time (Custom)
        
        return true
    } catch {
        return false
    }
}

BidAmount(amount)
{
    global CalcTimerText, fastBidInternetWaitMs, fastBidInternetPollMs, fastBidF8CooldownMs

    ; WAVE 1: Accept immediate internet bid only when a visible internet price
    ; exists. If no internet price is active, continue with the F8 bid path.
    if (GetVisibleInternetPriceNumber() > 0)
        ClickInternetAfterPriceSeen()
    
    ; --- STATE SYNC DELAY ---
    ; We must wait for the site to settle at the new tier (e.g. 105) before injecting our jump (e.g. 500)
    ; 50ms was too fast; 150ms ensures the site state has updated.
    Sleep(150) 
    actualAsk := ReadSettledCurrentAskNumber(150, 25)
    if (actualAsk > 0 && actualAsk > amount)
    {
        ; Auction already exceeded our ladder amount — just click Competing and move on
        ClickPrimaryButtonNative("competing")
        return true
    }
    if (actualAsk > 0 && actualAsk = amount)
    {
        ; Price is exactly at our rung — accept it with Competing (opening bid)
        ClickPrimaryButtonNative("competing")
        return true
    }

    ; INJECTION: Set the new bid amount DIRECTLY via the Chrome Extension
    if !SetCurrentAskInputViaExtension(amount)
    {
        if IsObject(CalcTimerText)
        {
            CalcTimerText.Text := "DOM INJECTION FAILED"
            CalcTimerText.SetFont("cFF0000 Bold")
            SetTimer(ResetF9TimerText, 1500)
        }
        return false
    }

    ; WAVE 2: Submit the injected bid by clicking Competing
    Sleep(200)
    ClickPrimaryButtonNative("competing")

    ; Cooldown AFTER the bid to prevent accidental spamming
    SetTimer(() => UpdateSessionWindow(), -fastBidF8CooldownMs)
    return true
}
















TogglePacing(*)
{
    global pacingTargetAbsoluteLotMark
    if (pacingTargetAbsoluteLotMark > 0)
        StopPacing()
    else
        ApplyPacingCalculation()
}

StopPacing(silent := false)
{
    global pacingTargetAbsoluteLotMark, pacingAbsoluteDeadline, CalcWaitDropDown, pacingTargetTotalLotMs, PacingToggleBtn, PacingProgressText
    global pacingHourKey, pacingHourStartLot, pacingHourQuota, pacingHourBaseCap, pacingCarryDebt, pacingCurrentHourLeft
    pacingTargetAbsoluteLotMark := 0
    pacingAbsoluteDeadline := ""
    pacingTargetTotalLotMs := 0
    pacingCurrentHourLeft := 0
    SavePacingCarryState()
    SetTimer(RecalibratePacing, 0)
    SetTimer(UpdatePacingMonitor, 0)
    LoadWaitMode()
    
    if IsObject(PacingToggleBtn)
    {
        PacingToggleBtn.Text := "BOT LOCK"
        PacingToggleBtn.SetFont("c00D94A") ; Green
    }
    
        if IsObject(PacingProgressText)
        {
            PacingProgressText.Text := "STOPPED"
            PacingProgressText.SetFont("c00D94A")
        }
    
    ; AUTO-STOP BOT: Stopping pace now automatically stops the Auto-Clerk
    global autoClerkActive
    if (autoClerkActive)
        ToggleAutoClerk()
    
    ToolTip(,,, 5) ; Hide persistent pacing monitor
    
    ; if (!silent)
    ;     MsgBox("Pacing stopped. You can now use manual speed controls.", "Pace Stopped", "Iconi T2")
}

GetPacingHourValue()
{
    global PacingHourDrop
    raw := IsObject(PacingHourDrop) ? PacingHourDrop.Text : "6"
    hour := NormalizeToNumber(raw)
    hour := Clamp(Integer(hour), 1, 12)
    return hour
}

AppendReloadPacingSnapshot(outStr)
{
    global pacingHourKey, pacingHourStartLot, pacingHourQuota, pacingHourBaseCap, pacingHourTargetLot, pacingCarryDebt
    global pacingTargetAbsoluteLotMark, pacingAbsoluteDeadline, pacingStartLot, pacingStartTime

    outStr .= "LastPacingTarget=" pacingTargetAbsoluteLotMark "`n"
    outStr .= "LastPacingDeadline=" pacingAbsoluteDeadline "`n"
    outStr .= "LastPacingStart=" pacingStartLot "`n"
    outStr .= "LastPacingStartTime=" pacingStartTime "`n"
    outStr .= "PacingHourKey=" pacingHourKey "`n"
    outStr .= "PacingHourStartLot=" pacingHourStartLot "`n"
    outStr .= "PacingHourQuota=" pacingHourQuota "`n"
    outStr .= "PacingHourBaseCap=" pacingHourBaseCap "`n"
    outStr .= "PacingHourTargetLot=" pacingHourTargetLot "`n"
    outStr .= "PacingCarryDebt=" pacingCarryDebt "`n"
    return outStr
}

GetPacingMinuteValue()
{
    global PacingMinDrop
    raw := IsObject(PacingMinDrop) ? PacingMinDrop.Text : "00"
    minute := NormalizeToNumber(raw)
    minute := Clamp(Integer(minute), 0, 59)
    return minute
}

GetPacingMinuteIndex()
{
    ; Keep the old saved format: index 1 = 00, index 60 = 59.
    return GetPacingMinuteValue() + 1
}

TogglePacingAmPm(*)
{
    global PacingAmPmDrop, pacingLotManualOverride
    if !IsObject(PacingAmPmDrop)
        return

    PacingAmPmDrop.Text := (PacingAmPmDrop.Text = "PM") ? "AM" : "PM"
    pacingLotManualOverride := false
    UpdateCalculatedStopLot(true)
    SavePacingSettings()
}

UpdateAuctionUIDLinkButton()
{
    global AuctionUIDLinkBtn, CurrentAuctionUID
    if !IsObject(AuctionUIDLinkBtn)
        return

    AuctionUIDLinkBtn.Text := "EOA"
}

OpenCurrentAuctionUIDLink(*)
{
    global CurrentAuctionUID
    uid := Trim(CurrentAuctionUID)
    if !RegExMatch(uid, "^\d{6}$")
        return

    Run("https://classic.liveauctioneers.com/auctioneers/EOA-new-" uid ".html")
}

GetPacingAmPmIndex()
{
    global PacingAmPmDrop
    return (IsObject(PacingAmPmDrop) && PacingAmPmDrop.Text = "PM") ? 2 : 1
}

GetPacingAmPmText()
{
    return (GetPacingAmPmIndex() = 2) ? "PM" : "AM"
}

PacingLPHChanged(*)
{
    global pacingLotManualOverride
    pacingLotManualOverride := false
    SavePacingSettings()
    UpdateCalculatedStopLot(true)
}

PacingTimeChanged(*)
{
    global pacingLotManualOverride
    pacingLotManualOverride := false
    SavePacingSettings()
    UpdateCalculatedStopLot(true)
}

PacingLotsChanged(*)
{
    global pacingLotAutoUpdating, pacingLotAutoValue, pacingLotManualOverride, PacingLotsInput

    if (pacingLotAutoUpdating)
        return

    if IsObject(PacingLotsInput)
    {
        enteredLot := Trim(PacingLotsInput.Text)
        if (enteredLot = "")
            pacingLotManualOverride := false
        else
            pacingLotManualOverride := (pacingLotAutoValue = "" || enteredLot != pacingLotAutoValue)
    }

    SavePacingSettings()
    RecalibratePacing()
}

GetSelectedPacingDeadlinePH()
{
    phNow := GetPHTime()
    if (phNow = "")
        return ""

    tgtHour := GetPacingHourValue()
    tgtMin := GetPacingMinuteValue()
    ampm := GetPacingAmPmText()

    if (ampm = "PM" && tgtHour != 12)
        tgtHour += 12
    if (ampm = "AM" && tgtHour = 12)
        tgtHour := 0

    deadline := SubStr(phNow, 1, 8) . Format("{:02}", tgtHour) . Format("{:02}", tgtMin) . "00"
    if (DateDiff(deadline, phNow, "Seconds") <= 0)
        deadline := DateAdd(deadline, 1, "Days")

    return deadline
}

UpdateCalculatedStopLot(force := false)
{
    global PacingLotsInput, PacingLPHInput, currentAuctionProgressNumber
    global pacingLotAutoValue, pacingLotManualOverride, pacingLotAutoUpdating

    if !IsObject(PacingLotsInput) || !IsObject(PacingLPHInput)
        return
    if (IsPacingLockActive())
        return
    if (!force && pacingLotManualOverride)
        return

    currentLot := currentAuctionProgressNumber + 0
    targetLPH := NormalizeToNumber(PacingLPHInput.Text)
    if (currentLot <= 0 || targetLPH <= 0)
        return

    phNow := GetPHTime()
    deadlinePH := GetSelectedPacingDeadlinePH()
    if (phNow = "" || deadlinePH = "")
        return

    secondsRemaining := DateDiff(deadlinePH, phNow, "Seconds")
    if (secondsRemaining <= 0)
        return

    hourBlocks := Ceil(secondsRemaining / 3600)
    lotsToRun := targetLPH * hourBlocks
    if (lotsToRun <= 0)
        lotsToRun := 1

    targetLot := currentLot - lotsToRun
    if (targetLot < 1)
        targetLot := 1

    existingLot := Trim(PacingLotsInput.Text)
    if (!force && pacingLotAutoValue != "" && existingLot != "" && existingLot != pacingLotAutoValue)
    {
        pacingLotManualOverride := true
        return
    }

    pacingLotAutoValue := targetLot . ""
    pacingLotAutoUpdating := true
    PacingLotsInput.Value := pacingLotAutoValue
    pacingLotAutoUpdating := false
    ClearSavedAutoPacingTargetLots()
}

ClearSavedAutoPacingTargetLots()
{
    global CurrentAuctionUID
    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
    iniFile := A_ScriptDir "\AuctionSessions.ini"
    try IniDelete(iniFile, "Pacing_" auctionId, "TargetLots")
    try IniDelete(iniFile, "Pacing_General", "TargetLots")
    try IniDelete(iniFile, "Pacing_" auctionId, "TargetLotsManual")
    try IniDelete(iniFile, "Pacing_General", "TargetLotsManual")
}

ApplyPacingCalculation(silent := false)
{
    global PacingLotsInput, PacingLPHInput, PacingHourDrop, PacingMinDrop, PacingAmPmDrop, currentAuctionProgressNumber, currentAuctionProgressText, autoClerkWaitMs, CalcWaitDropDown, pacingTargetAbsoluteLotMark, pacingAbsoluteDeadline, pacingStartLot, pacingStartTime
    global PacingProgressText, PacingToggleBtn, CalcTimerText, SessionClockText, CurrentActiveLotID, autoClerkActive, autoClerkPhase
    global pacingChunkStartLot, pacingChunkTargetLot, pacingChunkDeadline, pacingHourKey, pacingHourStartLot, pacingHourQuota, pacingHourBaseCap, pacingHourTargetLot, pacingCarryDebt
    global lastAutoClerkLotToken, lastAutoClerkLotNumber, autoClerkInitialAnalysisDone, autoClerkBiddingStartTime, autoClerkStartedLotToken, progressiveF8Step
    
    tgtLots := PacingLotsInput.Value
    if (tgtLots == "")
        return
        
    if (currentAuctionProgressNumber <= 0)
    {
        MsgBox("Cannot read current lots from 'Bots Speed' telemetry!", "Error", "Iconx T2")
        return
    }
    
    ; Read hour/min/ampm from compact time controls.
    tgtHour := GetPacingHourValue()
    tgtMin  := GetPacingMinuteValue()
    ampm    := GetPacingAmPmText()
    
    ; Convert 12-hour AM/PM to 24-hour
    if (ampm = "PM" && tgtHour != 12)
        tgtHour += 12
    if (ampm = "AM" && tgtHour = 12)
        tgtHour := 0
    
    ; Build deadline from the entered Philippines Time (UTC+8), then convert
    ; to local system time so DateDiff(A_Now) comparisons stay valid.
    phNow := GetPHTime()
    targetDate := SubStr(phNow, 1, 8) ; Use the CURRENT PHILIPPINES DATE
    enteredDeadlinePH := targetDate . Format("{:02}", tgtHour) . Format("{:02}", tgtMin) . "00"

    ; === PHILIPPINES TIME (UTC+8) -> LOCAL SYSTEM TIME CONVERSION ===
    ; A_Now is local clock; A_NowUTC is UTC. Difference gives local UTC offset in minutes.
    localOffsetMinutes := DateDiff(A_Now, A_NowUTC, "Minutes")   ; e.g. -420 for PDT (UTC-7)
    phOffsetMinutes    := 8 * 60                                  ; UTC+8 = +480 min
    adjustMinutes      := localOffsetMinutes - phOffsetMinutes    ; e.g. -420 - 480 = -900
    deadline           := DateAdd(enteredDeadlinePH, adjustMinutes, "Minutes")
    enteredDeadline    := deadline

    ; Use the exact entered PH time. 5:59 means 5:59, not tomorrow's 5:59.
    timeAlreadyPassed := (DateDiff(enteredDeadline, A_Now, "Seconds") < -60)
    if (timeAlreadyPassed)
    {
        pacingTargetAbsoluteLotMark := 0
        pacingAbsoluteDeadline := ""
        pacingStartTime := ""
        SetTimer(RecalibratePacing, 0)
        SetTimer(UpdatePacingMonitor, 0)
        SetTimer(AutoClerkTick, 0)
        
        autoClerkActive := false
        autoClerkPhase := "STOPPED"
        
        if IsObject(PacingToggleBtn)
        {
            PacingToggleBtn.Text := "BOT LOCK"
            PacingToggleBtn.SetFont("c00D94A")
        }
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "TIME ALREADY PASSED"
        if IsObject(SessionClockText)
            SessionClockText.Text := "BOT: TIME PASSED"
        if IsObject(PacingProgressText)
        {
            PacingProgressText.Text := "TIME PASSED"
            PacingProgressText.SetFont("cFF5555")
        }
        MsgBox("TIME ALREADY PASSED`n`nUpdate the target time before starting BOT LOCK.", "FastBid Safety", 48)
        return
    }
    
    pacingAbsoluteDeadline := deadline
    pacingTargetAbsoluteLotMark := tgtLots + 0
    
    ; Refresh current lot one last time for the most accurate baseline
    currentLotNum := currentAuctionProgressNumber + 0
    if (currentLotNum <= 0) {
        ; Fallback to regex if the global isn't updated yet
        currentLotNum := ExtractAuctionProgressLotNumber(currentAuctionProgressText, CurrentActiveLotID)
    }

    targetLotNum := tgtLots + 0
    ; AAMICRO lot progress counts down. Example: current 688, target 687 is
    ; still one lot away; current 686 means target 687 was already passed.
    if (targetLotNum > 0 && currentLotNum > 0 && currentLotNum < targetLotNum)
    {
        pacingTargetAbsoluteLotMark := 0
        pacingAbsoluteDeadline := ""
        pacingStartTime := ""
        SetTimer(RecalibratePacing, 0)
        SetTimer(UpdatePacingMonitor, 0)
        SetTimer(AutoClerkTick, 0)

        autoClerkActive := false
        autoClerkPhase := "STOPPED"

        if IsObject(PacingToggleBtn)
        {
            PacingToggleBtn.Text := "BOT LOCK"
            PacingToggleBtn.SetFont("c00D94A")
        }
        if IsObject(SessionClockText)
            SessionClockText.Text := "BOT: PASSED"
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "GOAL ALREADY PASSED"
        MsgBox("GOAL ALREADY PASSED`n`nCurrent lot: " currentLotNum "`nTarget lot: " targetLotNum, "FastBid Safety", 48)
        if IsObject(PacingProgressText)
        {
            PacingProgressText.Text := "PASSED"
            PacingProgressText.SetFont("cFF5555")
        }
        return
    }
    
    pacingStartLot := (currentLotNum > 0) ? currentLotNum : 1
    pacingStartTime := A_Now
    pacingChunkStartLot := pacingStartLot
    pacingChunkTargetLot := 0
    pacingChunkDeadline := ""
    SavePacingCarryState()
    global currentBiddingStartTime, CurrentAuctionUID
    currentBiddingStartTime := A_TickCount ; START THE CLOCK IMMEDIATELY

    global manualTargetLPH
    manualTargetLPH := (IsObject(PacingLPHInput) && PacingLPHInput.Text != "") ? PacingLPHInput.Text : 0
    
    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
    iniFile := A_ScriptDir "\AuctionSessions.ini"
    
    try {
        IniWrite(tgtLots, iniFile, "Pacing_" auctionId, "TargetLots")
        IniWrite(GetPacingHourValue(), iniFile, "Pacing_" auctionId, "TargetHour")
        IniWrite(GetPacingMinuteIndex(), iniFile, "Pacing_" auctionId, "TargetMin")
        IniWrite(GetPacingAmPmIndex(), iniFile, "Pacing_" auctionId, "TargetAmPm")
        IniWrite(pacingStartLot, iniFile, "Pacing_" auctionId, "SessionStartLot")
        IniWrite(pacingStartTime, iniFile, "Pacing_" auctionId, "SessionStartTime")
        IniWrite(pacingAbsoluteDeadline, iniFile, "Pacing_" auctionId, "Deadline")
        
        if (manualTargetLPH > 0)
            IniWrite(manualTargetLPH, iniFile, "Pacing_" auctionId, "TargetLPH")
    }
    
    RecalibratePacing() ; Run once instantly
    SetTimer(RecalibratePacing, 1000) ; LIVE HEARTBEAT: Recalculate every second
    SetTimer(UpdatePacingMonitor, 50) ; Live refresh for the 'Next' countdown

    ; AUTO-RESET WAIT FLOOR: Ensure the dropdown doesn't block "Haste" mode
    ; if IsObject(CalcWaitDropDown)
    ; {
    ;     CalcWaitDropDown.Text := "6.0s"
    ;     LoadWaitMode()
    ; }

    ; Show PH time (what user entered) and local system time equivalent for confirmation
    localHour  := SubStr(deadline, 9, 2) + 0
    localMin   := SubStr(deadline, 11, 2)
    localAmPm  := (localHour >= 12) ? "PM" : "AM"
    localHour12 := (localHour = 0) ? 12 : (localHour > 12 ? localHour - 12 : localHour)
    ; Rebuild original PH 12-hour display (tgtHour was already shifted to 24h above, re-derive 12h)
    origPHHour := GetPacingHourValue()
    origPH24   := (ampm = "PM" && origPHHour != 12) ? origPHHour + 12
                : (ampm = "AM" && origPHHour = 12)  ? 0
                : origPHHour
    phDisp12   := (origPH24 = 0) ? 12 : (origPH24 > 12 ? origPH24 - 12 : origPH24)
    if IsObject(PacingToggleBtn)
    {
        PacingToggleBtn.Text := "STOP BOT"
        PacingToggleBtn.SetFont("cFF4444") ; Red
    }

    if IsPacingPauseMinute()
    {
        autoClerkActive := false
        autoClerkPhase := "BIDDING"
        SetTimer(AutoClerkTick, 0)
        SetTimer(RecalibratePacing, 0)
        SetTimer(UpdatePacingMonitor, 0)
        lastAutoClerkLotToken := (CurrentActiveLotID != "") ? CurrentActiveLotID : "NOVALUE"
        lastAutoClerkLotNumber := currentAuctionProgressNumber
        autoClerkInitialAnalysisDone := false
        autoClerkBiddingStartTime := A_TickCount + 1000000
        autoClerkStartedLotToken := "INIT"
        progressiveF8Step := 0
        SetTimer(ResumeAutoClerkAtNextHour, -1000)
        if IsObject(SessionClockText)
            SessionClockText.Text := "BOT: WAITING :00"
        if IsObject(CalcTimerText)
            CalcTimerText.Text := "BOT: WAITING :00"
        if IsObject(PacingProgressText)
        {
            PacingProgressText.Text := "WAITING :00"
            PacingProgressText.SetFont("cFFD166")
        }
        return
    }

    ; AUTO-START BOT: Engaging pace lock now automatically starts the Auto-Clerk
    global autoClerkActive
    if (!autoClerkActive)
        ToggleAutoClerk()

    ; MsgBox("PACING LOCK ENGAGED! 🇵🇭`n`n"
    ;     . "The bot will recalculate speed on every lot to stay on pace.", "PH Pacing Active", "Iconi T3")
}

RecalibratePacing()
{
    global pacingTargetAbsoluteLotMark, pacingAbsoluteDeadline, currentAuctionProgressNumber, autoClerkWaitMs, CalcWaitDropDown, PacingHourDrop, PacingAmPmDrop
    global pacingStartLot, pacingStartTime, pacingTargetTotalLotMs, PacingProgressText, statusTxt, globalLotDeficit, autoClerkActive, autoClerkPhase, CalcTimerText
    global f10TriggerTime, timerSoundFired, timerCueMs, pacingFinishReserveSeconds
    global PacingLPHInput, PacingLotsInput, PacingHourlyRemainingText, pacingCurrentHourLeft, pacingHourKey, pacingHourStartLot, pacingHourQuota, pacingHourBaseCap, pacingHourTargetLot, pacingCarryDebt
    global pacingChunkStartLot, pacingChunkTargetLot, pacingChunkDeadline
    global PacingToggleBtn, isUpdatingPaceDisplay
    global spamDelayMode, targetPercentMode, currentBiddingStartTime
    global CalcSpamFastRadio, CalcSpamMediumRadio, CalcSpamSlowRadio, CalcPercent1Radio, CalcPercent5Radio, CalcPercent10Radio
    global lastHourTracked, lotAtTopOfHour, hourDeficit, manualTargetLPH, pacingStopPending, lotIsClosed, lastBiddingDurationSeconds
    
    if (!IsPacingLockActive())
        return
    
    ; --- 1. GET GOALS & TARGETS ---
    rawLPH := (IsObject(PacingLPHInput) && PacingLPHInput.Text != "") ? PacingLPHInput.Text : 0
    manualTargetLPH := NormalizeToNumber(rawLPH)
    uiStopGoal := NormalizeToNumber(PacingLotsInput.Text)
    
    phNow := GetPHTime()
    if (phNow == "" || currentAuctionProgressNumber <= 0)
        return 
        
    currH := Integer(SubStr(phNow, 9, 2))
    currM := Integer(SubStr(phNow, 11, 2))
    currS := Integer(SubStr(phNow, 13, 2))
    
    ; Read target time from compact time controls.
    tgtH := GetPacingHourValue()
    ampm := GetPacingAmPmText()
    if (ampm == "PM" && tgtH < 12)
        tgtH += 12
    if (ampm == "AM" && tgtH == 12)
        tgtH := 0
    
    ; --- 2. CALCULATE "HOUR: LEFT" ---
    isDescending := (pacingStartLot > pacingTargetAbsoluteLotMark)
    totalDistance := isDescending ? (currentAuctionProgressNumber - pacingTargetAbsoluteLotMark) 
                                  : (pacingTargetAbsoluteLotMark - currentAuctionProgressNumber)

    if (pacingTargetAbsoluteLotMark > 0)
    {
        lotsToGo := isDescending ? (currentAuctionProgressNumber - pacingTargetAbsoluteLotMark)
                                 : (pacingTargetAbsoluteLotMark - currentAuctionProgressNumber)
        if (autoClerkActive && IsPacingGoalExact())
        {
            pacingStopPending := true
            if IsObject(CalcTimerText)
                CalcTimerText.Text := "GOAL: FINISH LOT"
        }
    }
    else
    {
        lotsToGo := 0
    }

    secondsRemaining := (pacingAbsoluteDeadline != "") ? DateDiff(pacingAbsoluteDeadline, A_Now, "Seconds") : 0
    if (pacingAbsoluteDeadline != "" && secondsRemaining <= 0)
    {
        pacingStopPending := true
        if IsObject(CalcTimerText)
            CalcTimerText.Text := IsPacingGoalExact() ? "TIME: FINISH LOT" : "TIME: CATCH TARGET"

        ; Time-up means hurry to the exact designated lot, then finish/end it.
        ; Keep the bot moving at the minimum protected wait until the target
        ; lot is closed or the page advances past the target.
        autoClerkWaitMs := timerCueMs
        if IsPacingGoalPassed()
            ForceReloadAdvancedGoalResume()
        else if (IsPacingGoalExact() && (lotIsClosed || autoClerkPhase = "NEXT" || autoClerkPhase = "STOPPED"))
            ForceReloadDesignatedLotStop()
        return
    }
    
    ; Current-hour cap: LPH is the hard base cap. Carried debt may add up to
    ; 25% of LPH, but the hour quota never exceeds total remaining distance.
    secondsUntilNextHour := Max(1, ((59 - currM) * 60) + (60 - currS))
    currentHourWindowSeconds := Min(secondsUntilNextHour, Max(1, secondsRemaining))
    if (secondsRemaining > 0 && totalDistance > 0)
    {
        plannedCurrentHourLots := Ceil(totalDistance * (currentHourWindowSeconds / secondsRemaining))
    }
    else
    {
        plannedCurrentHourLots := totalDistance
    }

    currentHourKey := SubStr(phNow, 1, 10)
    hourTargetChanged := (pacingHourTargetLot != pacingTargetAbsoluteLotMark)
    if (pacingHourKey != currentHourKey || pacingHourStartLot <= 0 || hourTargetChanged)
    {
        if (!hourTargetChanged && pacingHourKey != "" && pacingHourStartLot > 0)
        {
            previousHourDone := Abs(pacingHourStartLot - currentAuctionProgressNumber)
            previousHourBasePlan := Min(pacingHourBaseCap, pacingHourQuota)
            pacingCarryDebt := Max(0, pacingCarryDebt + previousHourBasePlan - previousHourDone)
        }

        pacingHourKey := currentHourKey
        pacingHourStartLot := currentAuctionProgressNumber
        pacingHourTargetLot := pacingTargetAbsoluteLotMark
        if (manualTargetLPH > 0)
            pacingHourBaseCap := Max(0, Round(manualTargetLPH))
        else
            pacingHourBaseCap := Max(0, totalDistance)
        pacingHourQuota := Min(Max(0, totalDistance), pacingHourBaseCap)
    }

    completedThisHour := Abs(pacingHourStartLot - currentAuctionProgressNumber)
    if (completedThisHour > pacingHourQuota || (completedThisHour + Max(0, totalDistance)) < pacingHourQuota || pacingHourTargetLot != pacingTargetAbsoluteLotMark)
    {
        pacingHourStartLot := currentAuctionProgressNumber
        pacingHourTargetLot := pacingTargetAbsoluteLotMark
        completedThisHour := 0
        if (manualTargetLPH > 0)
            pacingHourBaseCap := Max(0, Round(manualTargetLPH))
        else
            pacingHourBaseCap := Max(0, totalDistance)
        pacingHourQuota := Min(Max(0, totalDistance), pacingHourBaseCap)
        SavePacingCarryState()
    }
    ; The schedule may require more than the LPH base this hour. Admit only
    ; 25% extra as catch-up, and carry the rest forward.
    scheduleCarryDebt := Max(0, plannedCurrentHourLots - pacingHourBaseCap)
    pacingCarryDebt := Max(pacingCarryDebt, scheduleCarryDebt)
    catchupCap := Round(pacingHourBaseCap * 0.25)
    catchupQuota := Min(pacingCarryDebt, catchupCap)
    hourAvailableDistance := completedThisHour + Max(0, totalDistance)
    desiredHourQuota := Min(hourAvailableDistance, pacingHourBaseCap + catchupQuota)
    if (desiredHourQuota > pacingHourQuota)
    {
        pacingHourQuota := desiredHourQuota
        SavePacingCarryState()
    }

    currentHourLeft := Max(0, pacingHourQuota - completedThisHour)
    pacingCurrentHourLeft := currentHourLeft
    
    ; UI Update: show the capped current-hour remaining lots.
    if IsObject(PacingHourlyRemainingText)
    {
        if (currentHourLeft > 0)
            PacingHourlyRemainingText.Text := "Lots: " . currentHourLeft
        else
            PacingHourlyRemainingText.Text := "Lots: DONE"
    }

    ; --- 3. CURRENT-HOUR TIME RHYTHM ---
    ; Adaptive AANOReserveB timing: divide the remaining pace window by the
    ; remaining hourly quota. Delays shorten later waits to catch up, while
    ; getting ahead lengthens later waits. The hard cap is enforced separately.
    if (pacingStartTime != "" && pacingTargetAbsoluteLotMark > 0 && lotsToGo > 0 && secondsRemaining > 0)
    {
        paceWindowSeconds := Max(1, Min(secondsUntilNextHour, secondsRemaining) - pacingFinishReserveSeconds)
        hourLotsToPace := Max(1, currentHourLeft)
        effectiveTargetLPH := (hourLotsToPace / paceWindowSeconds) * 3600

        if (effectiveTargetLPH > 75) {
            spamDelayMode := "fast"
            targetPercentMode := "1"
        } else if (effectiveTargetLPH < 45) {
            spamDelayMode := "slow"
            targetPercentMode := "10"
        } else {
            spamDelayMode := "medium"
            targetPercentMode := "5"
        }

        if IsObject(CalcSpamFastRadio)
        {
            CalcSpamFastRadio.Value := (spamDelayMode = "fast" ? 1 : 0)
            CalcSpamMediumRadio.Value := (spamDelayMode = "medium" ? 1 : 0)
            CalcSpamSlowRadio.Value := (spamDelayMode = "slow" ? 1 : 0)
        }
        if IsObject(CalcPercent1Radio)
        {
            CalcPercent1Radio.Value := (targetPercentMode = "1" ? 1 : 0)
            CalcPercent5Radio.Value := (targetPercentMode = "5" ? 1 : 0)
            CalcPercent10Radio.Value := (targetPercentMode = "10" ? 1 : 0)
        }
        SaveSpeedMode()
        SavePercentMode()

        globalLotDeficit := 0
        baseLotDurationMs := (paceWindowSeconds / hourLotsToPace) * 1000
        timeSpentBiddingMs := (currentBiddingStartTime > 0)
                           ? (A_TickCount - currentBiddingStartTime)
                           : ((autoClerkPhase = "WAITING" && lastBiddingDurationSeconds > 0) ? Round(lastBiddingDurationSeconds * 1000) : 0)
        calculatedWaitMs := Round(baseLotDurationMs - timeSpentBiddingMs)

        newWaitMs := Min(120000, Max(timerCueMs, calculatedWaitMs))
        
        ; Once F10 waiting starts, keep that lot's F11 timer fixed.
        ; Recalibration may update the display, but the active wait should
        ; still fire F11 after the chosen 6s-120s lot timer.
        if (autoClerkPhase != "WAITING")
            autoClerkWaitMs := newWaitMs
        
        if IsObject(CalcWaitDropDown)
        {
            statusTxt := (newWaitMs >= 60000) ? "s SLOW"
                       : (calculatedWaitMs < timerCueMs) ? "s MIN"
                       : "s OK"
            isUpdatingPaceDisplay := true
            CalcWaitDropDown.Text := Round(newWaitMs / 1000, 1) . statusTxt
            isUpdatingPaceDisplay := false
        }

        if IsObject(PacingProgressText)
        {
            if (newWaitMs >= 60000)
            {
                PacingProgressText.SetFont("c55FF55")
                PacingProgressText.Text := "SLOWING"
            }
            else if (calculatedWaitMs < timerCueMs)
            {
                PacingProgressText.SetFont("cFF5555")
                PacingProgressText.Text := "RUSHING"
            }
            else if (autoClerkActive && autoClerkPhase = "WAITING")
            {
                PacingProgressText.SetFont("c00FF66")
                PacingProgressText.Text := "RELAXING"
            }
            else if (autoClerkActive)
            {
                PacingProgressText.SetFont("c00FF66")
                PacingProgressText.Text := "WORKING"
            }
            else
            {
                PacingProgressText.SetFont("c00FF66")
                PacingProgressText.Text := "STOPPED"
            }
        }
    }
    
    if (autoClerkActive)
        SetTimer(AutoClerkTick, 50)
}

































GetWaitModeMs()
{
    global CalcWaitDropDown
    if !IsObject(CalcWaitDropDown)
        return 6000
        
    valStr := CalcWaitDropDown.Text
    if (InStr(valStr, "6s"))
        return 6000
    if (InStr(valStr, "10s"))
        return 10000
    if (InStr(valStr, "15s"))
        return 15000
    if (InStr(valStr, "20s"))
        return 20000
    if (InStr(valStr, "25s"))
        return 25000
    if (InStr(valStr, "30s"))
        return 30000
    if (InStr(valStr, "35s"))
        return 35000
    if (InStr(valStr, "40s"))
        return 40000
    if (InStr(valStr, "45s"))
        return 45000
    if (InStr(valStr, "50s"))
        return 50000
    if (InStr(valStr, "55s"))
        return 55000
    if (InStr(valStr, "60s"))
        return 60000
    return 6000
}




















SavePacingSettings(*)
{
    global PacingLPHInput, PacingLotsInput, PacingHourDrop, PacingMinDrop, PacingAmPmDrop, CurrentAuctionUID, isLoadingSettings
    global lotAtTopOfHour, lastHourTracked, hourDeficit
    global pacingLotAutoValue, pacingLotManualOverride
    global pacingHourKey, pacingHourStartLot, pacingHourQuota, pacingHourBaseCap, pacingHourTargetLot, pacingCarryDebt
    
    ; --- BLINKING GUARD ---
    if (isLoadingSettings)
        return

    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
    iniFile := A_ScriptDir "\AuctionSessions.ini"
    
    try {
        if IsObject(PacingLPHInput)
            IniWrite(PacingLPHInput.Text, iniFile, "Pacing_" auctionId, "TargetLPH")
        saveLotValue := !(IsObject(PacingLotsInput) && !pacingLotManualOverride && pacingLotAutoValue != "" && Trim(PacingLotsInput.Text) = pacingLotAutoValue)
        if IsObject(PacingLotsInput) && saveLotValue
        {
            IniWrite(PacingLotsInput.Text, iniFile, "Pacing_" auctionId, "TargetLots")
            IniWrite(1, iniFile, "Pacing_" auctionId, "TargetLotsManual")
        }
        if IsObject(PacingHourDrop)
            IniWrite(GetPacingHourValue(), iniFile, "Pacing_" auctionId, "TargetHour")
        if IsObject(PacingMinDrop)
            IniWrite(GetPacingMinuteIndex(), iniFile, "Pacing_" auctionId, "TargetMin")
        if IsObject(PacingAmPmDrop)
            IniWrite(GetPacingAmPmIndex(), iniFile, "Pacing_" auctionId, "TargetAmPm")
            
        ; Always save to General as a fallback for F4 reloads
        IniWrite(PacingLPHInput.Text, iniFile, "Pacing_General", "TargetLPH")
        if saveLotValue
        {
            IniWrite(PacingLotsInput.Text, iniFile, "Pacing_General", "TargetLots")
            IniWrite(1, iniFile, "Pacing_General", "TargetLotsManual")
        }
        IniWrite(GetPacingHourValue(), iniFile, "Pacing_General", "TargetHour")
        IniWrite(GetPacingMinuteIndex(), iniFile, "Pacing_General", "TargetMin")
        IniWrite(GetPacingAmPmIndex(), iniFile, "Pacing_General", "TargetAmPm")
            
        ; Save tracking state for F4 recovery
        IniWrite(lotAtTopOfHour, iniFile, "Pacing_" auctionId, "StartLotOfHour")
        IniWrite(lastHourTracked, iniFile, "Pacing_" auctionId, "LastHourTracked")
        IniWrite(hourDeficit, iniFile, "Pacing_" auctionId, "HourDeficit")
        IniWrite(pacingHourKey, iniFile, "Pacing_" auctionId, "PacingHourKey")
        IniWrite(pacingHourStartLot, iniFile, "Pacing_" auctionId, "PacingHourStartLot")
        IniWrite(pacingHourQuota, iniFile, "Pacing_" auctionId, "PacingHourQuota")
        IniWrite(pacingHourBaseCap, iniFile, "Pacing_" auctionId, "PacingHourBaseCap")
        IniWrite(pacingHourTargetLot, iniFile, "Pacing_" auctionId, "PacingHourTargetLot")
        IniWrite(pacingCarryDebt, iniFile, "Pacing_" auctionId, "PacingCarryDebt")
    }
}

SavePacingCarryState()
{
    global CurrentAuctionUID, pacingHourKey, pacingHourStartLot, pacingHourQuota, pacingHourBaseCap, pacingHourTargetLot, pacingCarryDebt
    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
    iniFile := A_ScriptDir "\AuctionSessions.ini"
    try {
        IniWrite(pacingHourKey, iniFile, "Pacing_" auctionId, "PacingHourKey")
        IniWrite(pacingHourStartLot, iniFile, "Pacing_" auctionId, "PacingHourStartLot")
        IniWrite(pacingHourQuota, iniFile, "Pacing_" auctionId, "PacingHourQuota")
        IniWrite(pacingHourBaseCap, iniFile, "Pacing_" auctionId, "PacingHourBaseCap")
        IniWrite(pacingHourTargetLot, iniFile, "Pacing_" auctionId, "PacingHourTargetLot")
        IniWrite(pacingCarryDebt, iniFile, "Pacing_" auctionId, "PacingCarryDebt")
    }
}

ClearSavedPacingCarryState()
{
    global CurrentAuctionUID
    auctionId := (CurrentAuctionUID != "") ? CurrentAuctionUID : "General"
    iniFile := A_ScriptDir "\AuctionSessions.ini"
    try {
        IniDelete(iniFile, "Pacing_" auctionId, "PacingHourKey")
        IniDelete(iniFile, "Pacing_" auctionId, "PacingHourStartLot")
        IniDelete(iniFile, "Pacing_" auctionId, "PacingHourQuota")
        IniDelete(iniFile, "Pacing_" auctionId, "PacingHourBaseCap")
        IniDelete(iniFile, "Pacing_" auctionId, "PacingHourTargetLot")
        IniDelete(iniFile, "Pacing_" auctionId, "PacingCarryDebt")
    }
}

; Bidding Speed Functions Removed - using 200ms default

UpdatePacingMonitor()
{
    global pacingStartTime, autoClerkWaitMs, globalLotDeficit, currentBiddingStartTime, statusTxt, SessionClockText, autoClerkPhase, f10TriggerTime, manualTargetLPH, PacingNextLabel, autoClerkActive, pacingCurrentHourLeft
    global pacingTargetAbsoluteLotMark, currentAuctionProgressNumber, pacingStartLot
    
    if (pacingStartTime = "")
        return

    displayWaitMs := autoClerkWaitMs
    if (autoClerkPhase = "WAITING") {
        remainingWaitMs := displayWaitMs - (A_TickCount - f10TriggerTime)
    } else {
        timeSpentOnLot := (currentBiddingStartTime > 0) ? (A_TickCount - currentBiddingStartTime) : 0
        remainingWaitMs := displayWaitMs - timeSpentOnLot
    }
    
    phTime := GetPHTime()
    currentMin := SubStr(phTime, 11, 2)
    
    if (currentMin == "59" && autoClerkActive)
    {
        global pacingCurrentHourLeft
        if (pacingCurrentHourLeft <= 0)
        {
            if IsObject(SessionClockText)
                SessionClockText.Text := "BOT: RESTING"
                
            if IsObject(PacingNextLabel)
                PacingNextLabel.Text := "Timer Wait"
        }
        else
        {
            if IsObject(SessionClockText)
                SessionClockText.Text := "BOT: RUSHING"
                
            if IsObject(PacingNextLabel)
                PacingNextLabel.Text := "Timer " . Max(0, Ceil(remainingWaitMs / 1000)) . "s"
        }
    }
    else
    {
        if IsObject(SessionClockText)
            SessionClockText.Text := "Lots: " . pacingCurrentHourLeft . statusTxt
            
        if IsObject(PacingNextLabel)
        {
            if (autoClerkActive && autoClerkPhase != "WAITING")
            {
                dotCount := Mod(Floor(A_TickCount / 333), 5) + 1
                dotStr := ""
                Loop dotCount
                    dotStr .= "."
                PacingNextLabel.Text := "Calc" . dotStr
            }
            else if (autoClerkActive && autoClerkPhase == "WAITING")
            {
                remainingWaitSec := Max(0, Ceil(remainingWaitMs / 1000))
                PacingNextLabel.Text := "Timer " . remainingWaitSec . "s"
            }
            else
            {
                PacingNextLabel.Text := "Timer Off"
            }
        }
    }
}

GetPHTime()
{
    ; Convert local A_Now to Philippines Time (GMT+8)
    localOffsetMinutes := DateDiff(A_Now, A_NowUTC, "Minutes")   ; e.g. -420 for PDT (UTC-7)
    phOffsetMinutes    := 8 * 60                                  ; UTC+8 = +480 min
    adjustMinutes      := phOffsetMinutes - localOffsetMinutes    ; e.g. 480 - (-420) = 900
    return DateAdd(A_Now, adjustMinutes, "Minutes")
}

Clamp(val, minV, maxV)
{
    return (val < minV) ? minV : (val > maxV ? maxV : val)
}


; ===== LICENSE CHECK TIMER =====
; Runs every 1 minute to verify license is still valid



; ===== F8 LADDER CONFIGURATION LOADER =====
; Load F8 ladder brackets from AuctionSessions.ini file
; Allows users to customize ladder rungs without editing code
; ============================================

; ===== F8 LADDER SETTINGS WINDOW =====
; Allows users to view and edit F8 ladder configurations

global F8SettingsGui := ""
global F8LadderEdits := Map()  ; Store edit controls for each bracket

OpenF8LadderSettings()
{
    global F8SettingsGui, f8LadderBrackets, F8LadderEdits
    
    ; Close if already open
    if IsObject(F8SettingsGui)
    {
        F8SettingsGui.Destroy()
    }
    
    F8SettingsGui := Gui()
    F8SettingsGui.Title := "Ladder Settings - Bid Ladder Configuration"
    F8SettingsGui.BackColor := "0B0F0C"
    F8SettingsGui.SetFont("s9 c00D94A", "Segoe UI")
    
    ; ===== HEADER SECTION =====
    F8SettingsGui.SetFont("s14 c00FF66 Bold")
    F8SettingsGui.AddText("x15 y15 w600 h30", "⚙ LADDER SETTINGS")
    
    F8SettingsGui.SetFont("s9 cBBBBBB")
    F8SettingsGui.AddText("x15 y50 w600 h50", "Configure bid amounts for each price bracket. Edit the comma-separated values below (e.g., 100,200,300,500,1000). Click 'Apply' to save changes. Restart the bot to apply.")
    
    ; ===== BRACKET EDITING SECTION =====
    F8SettingsGui.SetFont("s10 c00D94A Bold")
    F8SettingsGui.AddText("x15 y110 w600 h20", "Price Brackets")
    
    F8SettingsGui.SetFont("s8 c7F8C83")
    F8SettingsGui.AddText("x15 y135 w150 h16", "Bracket Range")
    F8SettingsGui.AddText("x170 y135 w450 h16", "Bid Ladder Rungs (comma-separated)")
    
    F8SettingsGui.SetFont("s9 c00D94A")
    
    y := 160
    rowHeight := 50
    
    ; Bracket definitions
    brackets := [
        {name: "Under $1,000", key: "Bracket_Under1000"},
        {name: "$1,001 - $2,500", key: "Bracket_1000to2500"},
        {name: "$2,501 - $5,000", key: "Bracket_2500to5000"},
        {name: "$5,001 - $10,000", key: "Bracket_5000to10000"},
        {name: "$10,001 - $25,000", key: "Bracket_10000to25000"},
        {name: "$25,001 - $50,000", key: "Bracket_25000to50000"},
        {name: "$50,001+", key: "Bracket_50000plus"}
    ]
    
    ; Create edit fields for each bracket
    for bracket in brackets
    {
        ; Bracket name label (left side)
        F8SettingsGui.AddText("x15 y" y " w150 h35 c00D94A +Border", bracket.name)
        
        ; Rungs input field (right side - larger)
        rungsStr := ""
        if f8LadderBrackets.Has(bracket.key)
        {
            rungs := f8LadderBrackets[bracket.key].rungs
            rungsStr := StrJoin(",", rungs*)
        }
        
        editCtrl := F8SettingsGui.AddEdit("x170 y" (y+5) " w450 h28 c00FF66 Background111A13", rungsStr)
        editCtrl.SetFont("s9 Bold")
        F8LadderEdits[bracket.key] := editCtrl
        
        y += rowHeight
    }
    
    ; ===== BUTTONS SECTION =====
    F8SettingsGui.SetFont("s10 c00D94A Bold")
    
    buttonY := y + 10
    
    applyBtn := F8SettingsGui.AddButton("x15 y" buttonY " w135 h32 cFFFFFF", "✓ APPLY")
    applyBtn.SetFont("s10 cFFFFFF Bold")
    applyBtn.OnEvent("Click", SaveF8LadderSettings)
    
    reloadBtn := F8SettingsGui.AddButton("x160 y" buttonY " w135 h32", "↻ RELOAD")
    reloadBtn.OnEvent("Click", (*) => ReloadF8LadderConfig())
    
    editorBtn := F8SettingsGui.AddButton("x305 y" buttonY " w135 h32", "📝 EDIT FILE")
    editorBtn.OnEvent("Click", OpenF8LadderFile)
    
    settingsCloseBtn := F8SettingsGui.AddButton("x450 y" buttonY " w170 h32 cFF4D4F", "✕ CLOSE")
    settingsCloseBtn.SetFont("s10 cFF4D4F Bold")
    settingsCloseBtn.OnEvent("Click", (*) => F8SettingsGui.Destroy())
    
    ; Show window (larger size now)
    F8SettingsGui.Show("w640 h" (buttonY + 45))
}

SaveF8LadderSettings(GuiCtrlObj, Info)
{
    global F8LadderEdits
    
    configFile := A_ScriptDir "\AuctionSessions.ini"
    
    ; Validate file exists
    if (!FileExist(configFile))
    {
        MsgBox("AuctionSessions.ini not found!`nLocation: " configFile, "Error", "0x1010")
        return
    }
    
    brackets := ["Bracket_Under1000", "Bracket_1000to2500", "Bracket_2500to5000", "Bracket_5000to10000", "Bracket_10000to25000", "Bracket_25000to50000", "Bracket_50000plus"]
    
    ; Save each bracket
    for bracketKey in brackets
    {
        if F8LadderEdits.Has(bracketKey)
        {
            rungsStr := F8LadderEdits[bracketKey].Value
            
            ; Validate format (comma-separated numbers)
            if (!ValidateRungsFormat(rungsStr))
            {
                MsgBox("Invalid format for " bracketKey "!`nUse comma-separated numbers (e.g., 100,200,300)", "Validation Error", "0x1010")
                return
            }
            
            ; Write to INI
            IniWrite(rungsStr, configFile, bracketKey, "rungs")
        }
    }
    
    MsgBox("F8 Ladder configuration saved!`n`nRestart the bot to apply changes.", "Success", "0x1040")
}

ValidateRungsFormat(rungsStr)
{
    ; Check if format is valid (comma-separated positive integers)
    if (rungsStr = "")
        return false
    
    parts := StrSplit(rungsStr, ",")
    for part in parts
    {
        trimmed := Trim(part)
        if (!RegExMatch(trimmed, "^\d+$"))
            return false
    }
    
    return true
}

OpenF8LadderFile(GuiCtrlObj, Info)
{
    configFile := A_ScriptDir "\AuctionSessions.ini"
    
    if (!FileExist(configFile))
    {
        MsgBox("AuctionSessions.ini not found!`nLocation: " configFile, "Error", "0x1010")
        return
    }
    
    ; Open file with default editor
    Run("notepad.exe " configFile)
}

StrJoin(delimiter, params*)
{
    result := ""
    for i, val in params
    {
        if (i > 1)
            result .= delimiter
        result .= val
    }
    return result
}

