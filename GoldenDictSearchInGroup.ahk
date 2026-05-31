scriptDir := A_ScriptDir
iniPath := scriptDir . "\GoldenDictSearchInGroup.ini"
trayIcon := scriptDir . "\assets\icon.ico"

if (!FileExist(iniPath)) {
    MsgBox, 0x10, Error, Configuration file not found:`n%iniPath%`n`nPlease ensure GoldenDictSearchInGroup.ini exists in the same folder.
    ExitApp
}

IniRead, gdExecutable, %iniPath%, GoldenDict, Executable, goldendict
IniRead, primaryGroup, %iniPath%, Groups, PrimaryGroup, default
IniRead, secondaryGroup, %iniPath%, Groups, SecondaryGroup, translate
IniRead, primaryHotkey, %iniPath%, Hotkeys, PrimaryHotkey, !z
IniRead, secondaryHotkey, %iniPath%, Hotkeys, SecondaryHotkey, !+z
IniRead, noSelectionMsg, %iniPath%, Messages, NoSelectionMsg, No text copied. Please select the word to query first.

if (!InStr(gdExecutable, "\") && !InStr(gdExecutable, "/")) {
    gdCmd := gdExecutable
} else {
    gdCmd := gdExecutable
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
Menu, Tray, Tip, GoldenDict Search`n%primaryHotkey% = %primaryGroup%`n%secondaryHotkey% = %secondaryGroup%
Menu, Tray, Icon, %trayIcon%

Hotkey, %primaryHotkey%, SearchPrimary
Hotkey, %secondaryHotkey%, SearchSecondary
return

ToggleStartup:
    global shortcutPath
    if (FileExist(shortcutPath)) {
        FileDelete, %shortcutPath%
        if !ErrorLevel {
            Menu, Tray, Uncheck, Start with Windows
        }
    } else {
        FileCreateShortcut, %A_ScriptFullPath%, %shortcutPath%, %A_ScriptDir%
        if !ErrorLevel {
            Menu, Tray, Check, Start with Windows
        }
    }
return

SuspendHotkeys:
    Suspend, Toggle
    if (A_IsSuspended) {
        Menu, Tray, Check, Suspend Hotkeys
    } else {
        Menu, Tray, Uncheck, Suspend Hotkeys
    }
return

PauseScript:
    Pause, Toggle
    if (A_IsPaused) {
        Menu, Tray, Check, Pause Script
    } else {
        Menu, Tray, Uncheck, Pause Script
    }
return

ExitScript:
    ExitApp
return

SearchInGoldenDict(groupName) {
    global gdCmd, noSelectionMsg
    oldClipboard := ClipboardAll
    query := Trim(Clipboard)

    if (query != "") {
        Run, "%gdCmd%" --group-name=%groupName% "%query%"
    } else {
        MsgBox, %noSelectionMsg%
    }

    Clipboard := oldClipboard
    oldClipboard := ""
}

SearchPrimary:
    global primaryGroup
    SearchInGoldenDict(primaryGroup)
return

SearchSecondary:
    global secondaryGroup
    SearchInGoldenDict(secondaryGroup)
return
