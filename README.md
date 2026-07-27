<div align="center">
  <img src="assets/icon.png" alt="icon" width="32" />
</div>

# GoldenDict Search In Group

Search clipboard text across dictionary groups using GoldenDict.

Authors: GLM-5🧙‍♂️, scillidan🤡

The icon is from [SimpleKeys](https://beamedeighth.itch.io/simplekeys-animated-pixel-keyboard-keys) by [beamedeighth](https://beamedeighth.itch.io/).

## Install

```sh
scoop bucket add pile https://github.com/scillidan/scoop-pile
scoop install pile/goldendict-search-in-group
```

## Usage

1. Go to: GoldenDict → Preferences → Hotkeys
2. Toggle: "Use the following hotkey to translate a word from clipboard"
	- **Enabled**: CLI searches open in popup windows. Set `ClipboardHotkeyEnabled=on` in INI.
	- **Disabled**: CLI searches open in the main window. Set `ClipboardHotkeyEnabled=off` in INI (default).
3. Configure dictionary groups and hotkeys in `GoldenDictSearchInGroup.ini`.