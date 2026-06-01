#NoEnv
#SingleInstance, Force
SendMode Input
SetWorkingDir %A_ScriptDir%

scriptDir := A_ScriptDir
iniPath := scriptDir . "\GoldenDictSearchInGroup.ini"
trayIcon := scriptDir . "\assets\icon.ico"

if (!FileExist(iniPath)) {
    MsgBox, 0x10, Error, Configuration file not found:`n%iniPath%`n`nPlease ensure GoldenDictSearchInGroup.ini exists in the same folder.
    ExitApp
}

IniRead, gdExecutable, %iniPath%, GoldenDict, Executable, goldendict
IniRead, defaultWindowMode, %iniPath%, GoldenDict, DefaultWindowMode, popup
IniRead, noSelectionMsg, %iniPath%, Messages, NoSelectionMsg, No text copied. Please select the word to query first.

hkToGroup := {}
trayTipText := "GoldenDict Search"


groupIndex := 1
Loop {
    currentGroupKey := "Group_" . groupIndex
    IniRead, groupName, %iniPath%, Groups, %currentGroupKey%, __MISSING__
    if (groupName == "__MISSING__" || groupName == "")
        break

    IniRead, hk, %iniPath%, Hotkeys, %currentGroupKey%, __MISSING__
    IniRead, wMode, %iniPath%, WindowModes, %currentGroupKey%, %defaultWindowMode%

    if (hk != "__MISSING__" && hk != "") {
        Hotkey, %hk%, HandleGroupSearch
        hkToGroup[hk] := groupName . "|" . wMode
        trayTipText .= "`n" . hk . " = " . groupName
    }
    groupIndex++
}


IniRead, triggerKey, %iniPath%, SpecialHotkeys, TriggerKey, __MISSING__

if (triggerKey != "__MISSING__" && triggerKey != "") {
    singleClickMap := {}
    dblClickMap := {}
    lastPressTime := {}
    pendingSingleLetter := ""
    DblClickTime := 300
    letters := ""

    IniRead, specialSection, %iniPath%, SpecialHotkeys

    if (specialSection != "ERROR") {
        Loop, Parse, specialSection, `n, `r
        {
            if (A_LoopField == "")
                continue

            StringSplit, kv, A_LoopField, =
            keyName := Trim(kv1)
            groupName := Trim(kv2)

            if (keyName == "TriggerKey" || groupName == "")
                continue

            if (InStr(keyName, "_Double")) {
                baseLetter := StrReplace(keyName, "_Double")
                dblClickMap[baseLetter] := groupName
                if (!InStr(letters, baseLetter))
                    letters .= baseLetter
            } else {
                singleClickMap[keyName] := groupName
                if (!InStr(letters, keyName))
                    letters .= keyName
            }
        }

        Loop, Parse, letters
        {
            hk := triggerKey . A_LoopField
            Hotkey, %hk%, HandleSpecialTrigger
        }

        trayTipText .= "`n[Prefix: " . triggerKey . "]"
        Loop, Parse, letters
        {
            letter := A_LoopField
            if (singleClickMap.HasKey(letter)) {
                tip := triggerKey . letter
                if (dblClickMap.HasKey(letter))
                    tip .= " (x1)"
                trayTipText .= "`n" . tip . " = " . singleClickMap[letter]
            }
            if (dblClickMap.HasKey(letter)) {
                trayTipText .= "`n" . triggerKey . letter . letter . " (x2) = " . dblClickMap[letter]
            }
        }
    }
}

startupDir := A_StartMenu . "\Programs\Startup"
shortcutPath := startupDir . "\GoldenDict Search In Group.lnk"
isStartup := FileExist(shortcutPath)

Menu, Tray, NoStandard
Menu, Tray, DeleteAll
if (isStartup) {
    Menu, Tray, Add, Start with Windows, ToggleStartup
    Menu, Tray, Check, Start with Windows
} else {
    Menu, Tray, Add, Start with Windows, ToggleStartup
}
Menu, Tray, Add, Suspend Hotkeys, SuspendHotkeys
Menu, Tray, Add, Pause Script, PauseScript
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Tip, %trayTipText%

if (FileExist(trayIcon))
    Menu, Tray, Icon, %trayIcon%
return

ToggleStartup:
    global shortcutPath
    if (FileExist(shortcutPath)) {
        FileDelete, %shortcutPath%
        if !ErrorLevel
            Menu, Tray, Uncheck, Start with Windows
    } else {
        FileCreateShortcut, %A_ScriptFullPath%, %shortcutPath%, %A_ScriptDir%
        if !ErrorLevel
            Menu, Tray, Check, Start with Windows
    }
return
SuspendHotkeys:
    Suspend, Toggle
    if (A_IsSuspended)
        Menu, Tray, Check, Suspend Hotkeys
    else
        Menu, Tray, Uncheck, Suspend Hotkeys
return
PauseScript:
    Pause, Toggle
    if (A_IsPaused)
        Menu, Tray, Check, Pause Script
    else
        Menu, Tray, Uncheck, Pause Script
return
ExitScript:
    ExitApp
return

HandleGroupSearch:
    if (hkToGroup.HasKey(A_ThisHotkey)) {
        data := StrSplit(hkToGroup[A_ThisHotkey], "|")
        SearchInGoldenDict(data[1], data[2])
    }
return

HandleSpecialTrigger:
    global triggerKey, DblClickTime, lastPressTime, pendingSingleLetter
    global singleClickMap, dblClickMap

    letter := SubStr(A_ThisHotkey, StrLen(triggerKey) + 1)

    if (dblClickMap.HasKey(letter)) {
        currentTime := A_TickCount
        if (currentTime - lastPressTime[letter] < DblClickTime) {
            lastPressTime[letter] := 0
            SetTimer, ExecutePendingSingle, Off
            ExecuteSearch(dblClickMap[letter])
        } else {
            lastPressTime[letter] := currentTime
            pendingSingleLetter := letter
            SetTimer, ExecutePendingSingle, % -DblClickTime
        }
    } else {
        if (singleClickMap.HasKey(letter)) {
            ExecuteSearch(singleClickMap[letter])
        }
    }
return

ExecutePendingSingle:
    global pendingSingleLetter, singleClickMap
    if (pendingSingleLetter != "" && singleClickMap.HasKey(pendingSingleLetter)) {
        ExecuteSearch(singleClickMap[pendingSingleLetter])
    }
    pendingSingleLetter := ""
return

ExecuteSearch(groupName) {
    global iniPath, defaultWindowMode
    IniRead, wMode, %iniPath%, WindowModes, %groupName%, %defaultWindowMode%
    SearchInGoldenDict(groupName, wMode)
}

SearchInGoldenDict(groupName, windowMode) {
    global gdExecutable, noSelectionMsg
    oldClipboard := ClipboardAll
    query := Trim(Clipboard)

    if (query != "") {
        groupParam := (windowMode = "main") ? "--group-name" : "--popup-group-name"
        Run, "%gdExecutable%" %groupParam%="%groupName%" "%query%"
    } else {
        MsgBox, %noSelectionMsg%
    }
    Clipboard := oldClipboard
    oldClipboard := ""
}