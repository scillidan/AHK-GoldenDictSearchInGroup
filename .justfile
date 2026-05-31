set shell := ["pwsh", "-NoLogo", "-Command"]

dist:
	Ahk2Exe /in "GoldenDictSearchInGroup.ahk" /icon "assets/icon.ico" /out "GoldenDictSearchInGroup.exe"

clean:
	rm GoldenDictSearchInGroup.exe