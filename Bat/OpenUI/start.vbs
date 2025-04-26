Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' 获取当前 .vbs 文件的路径
strCurrentPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' 拼接 OpenUI.bat 文件路径
strBatPath = strCurrentPath & "\OpenUI.bat"

' 运行 OpenUI.bat
objShell.Run """" & strBatPath & """", 0, False