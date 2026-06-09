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
IniRead, clipboardHotkeyEnabled, %iniPath%, GoldenDict, ClipboardHotkeyEnabled, off
clipboardHotkeyEnabled := (clipboardHotkeyEnabled = "on" || clipboardHotkeyEnabled = "1" || clipboardHotkeyEnabled = "true")
IniRead, noSelectionMsg, %iniPath%, Messages, NoSelectionMsg, No text copied. Please select the word to query first.
EnvGet, envEditor, EDITOR
IniRead, scriptEditor, %iniPath%, AutoHotkey, ScriptEditor, __MISSING__
if (scriptEditor = "__MISSING__" || scriptEditor = "")
    scriptEditor := envEditor != "" ? envEditor : "notepad"

trayTipText := "GoldenDict Search"
trayTipText .= "`nGroups and hotkeys"

groupMap := {}
doublePressMap := {}
groupNameMap := {}
hotkeyToGroupKey := {}
lastPressTime := {}
DblClickTime := 400
hotkeyList := ""

Loop, 10
{
    groupKey := "Group_" . A_Index
    IniRead, groupName, %iniPath%, Groups, %groupKey%
    if (groupName != "" && groupName != "ERROR") {
        groupNameMap[groupKey] := groupName
        IniRead, hk, %iniPath%, Hotkeys, %groupKey%
        if (hk != "" && hk != "ERROR") {
            len := StrLen(hk)
            lastChar := SubStr(hk, len, 1)
            prevChar := SubStr(hk, len - 1, 1)
            if (len >= 2 && lastChar = prevChar) {
                baseHk := SubStr(hk, 1, len - 1)
                doublePressMap[baseHk] := groupKey
                hotkeyToGroupKey[hk] := groupKey
                Hotkey, %baseHk%, HandleDoublePress
                hotkeyList .= hk . "|"
            } else {
                groupMap[hk] := groupKey
                hotkeyToGroupKey[hk] := groupKey
                Hotkey, %hk%, HandleGroupHotkey
                hotkeyList .= hk . "|"
            }
        }
    }
}

if (hotkeyList != "") {
    Loop, Parse, hotkeyList, |
    {
        if (A_LoopField != "") {
            gk := hotkeyToGroupKey[A_LoopField]
            gn := groupNameMap.HasKey(gk) ? groupNameMap[gk] : gk
            trayTipText .= "`n  " . gn . " = " . A_LoopField
        }
    }
}

startupDir := A_StartMenu . "\Programs\Startup"
shortcutPath := startupDir . "\GoldenDict Search In Group.lnk"
isStartup := FileExist(shortcutPath)

Menu, Tray, NoStandard
Menu, Tray, DeleteAll
if (clipboardHotkeyEnabled) {
    Menu, Tray, Add, Clipboard Hotkey (Popup Search): On, ToggleClipboardHotkey
    Menu, Tray, Check, Clipboard Hotkey (Popup Search): On
} else {
    Menu, Tray, Add, Clipboard Hotkey (Popup Search): Off, ToggleClipboardHotkey
}
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

ToggleClipboardHotkey:
    global clipboardHotkeyEnabled, iniPath
    clipboardHotkeyEnabled := !clipboardHotkeyEnabled
    newVal := clipboardHotkeyEnabled ? "on" : "off"
    IniWrite, %newVal%, %iniPath%, GoldenDict, ClipboardHotkeyEnabled
    if (clipboardHotkeyEnabled) {
        Menu, Tray, Rename, Clipboard Hotkey (Popup Search): Off, Clipboard Hotkey (Popup Search): On
        Menu, Tray, Check, Clipboard Hotkey (Popup Search): On
    } else {
        Menu, Tray, Rename, Clipboard Hotkey (Popup Search): On, Clipboard Hotkey (Popup Search): Off
        Menu, Tray, Uncheck, Clipboard Hotkey (Popup Search): Off
    }
    GoSub, UpdateTrayTip
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
    global scriptEditor, iniPath
    Run, %scriptEditor% "%iniPath%"
return

ReloadApp:
    TrayTip, GoldenDict Search In Group, Config reloaded, 2, 1
    SetTimer, DoReload, -500
return

DoReload:
    Reload
return

UpdateTrayTip:
    global clipboardHotkeyEnabled, trayTipText
    tip := "GoldenDict Search"
    tip .= "`nGroups and hotkeys"
    Loop, 10
    {
        gk := "Group_" . A_Index
        if (groupNameMap.HasKey(gk)) {
            gn := groupNameMap[gk]
            Loop, Parse, hotkeyList, |
            {
                if (A_LoopField != "" && hotkeyToGroupKey[A_LoopField] = gk) {
                    tip .= "`n  " . gn . " = " . A_LoopField
                    break
                }
            }
        }
    }
    trayTipText := tip
    Menu, Tray, Tip, %tip%
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

ExecuteSearch(groupKey) {
    global groupNameMap
    groupName := groupNameMap.HasKey(groupKey) ? groupNameMap[groupKey] : groupKey
    SearchInGoldenDict(groupName)
}

SearchInGoldenDict(groupName) {
    global gdExecutable, noSelectionMsg, clipboardHotkeyEnabled
    oldClipboard := ClipboardAll
    query := Trim(Clipboard)

    if (query != "") {
        groupParam := clipboardHotkeyEnabled ? "--popup-group-name" : "--group-name"
        Run, "%gdExecutable%" %groupParam%="%groupName%" "%query%"
    } else {
        MsgBox, %noSelectionMsg%
    }
    Clipboard := oldClipboard
    oldClipboard := ""
}