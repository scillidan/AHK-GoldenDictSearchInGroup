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

trayTipText := "GoldenDict Search"

groupMap := {}
doublePressMap := {}
lastPressTime := {}
DblClickTime := 400
hotkeyList := ""

Loop, 10
{
    groupKey := "Group_" . A_Index
    IniRead, groupName, %iniPath%, Groups, %groupKey%
    if (groupName != "" && groupName != "ERROR") {
        IniRead, hk, %iniPath%, Hotkeys, %groupKey%
        if (hk != "" && hk != "ERROR") {
            len := StrLen(hk)
            lastChar := SubStr(hk, len, 1)
            prevChar := SubStr(hk, len - 1, 1)
            if (len >= 2 && lastChar = prevChar) {
                baseHk := SubStr(hk, 1, len - 1)
                doublePressMap[baseHk] := groupName
                Hotkey, %baseHk%, HandleDoublePress
                hotkeyList .= hk . "|"
            } else {
                groupMap[hk] := groupName
                Hotkey, %hk%, HandleGroupHotkey
                hotkeyList .= hk . "|"
            }
        }
    }
}

if (hotkeyList != "") {
    trayTipText .= "`n"
    Loop, Parse, hotkeyList, |
    {
        if (A_LoopField != "")
            trayTipText .= "`n" . A_LoopField . " = " . (groupMap.HasKey(A_LoopField) ? groupMap[A_LoopField] : doublePressMap[SubStr(A_LoopField, 1, StrLen(A_LoopField)-1)])
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
Menu, Tray, Add, Edit Config, EditConfig
Menu, Tray, Add, Reload, ReloadApp
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

EditConfig:
    Run, edit "%iniPath%"
return

ReloadApp:
    TrayTip, GoldenDict Search In Group, Config reloaded, 2, 1
    SetTimer, DoReload, -500
return

DoReload:
    Reload
return

ExitScript:
    ExitApp
return

HandleGroupHotkey:
    global groupMap
    hk := A_ThisHotkey
    if (groupMap.HasKey(hk))
        ExecuteSearch(groupMap[hk])
return

HandleDoublePress:
    global doublePressMap, lastPressTime, DblClickTime
    hk := A_ThisHotkey
    currentTime := A_TickCount
    if (lastPressTime.HasKey(hk) && currentTime - lastPressTime[hk] < DblClickTime) {
        lastPressTime[hk] := 0
        if (doublePressMap.HasKey(hk))
            ExecuteSearch(doublePressMap[hk])
    } else {
        lastPressTime[hk] := currentTime
    }
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