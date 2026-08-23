Option Explicit

Dim fileSystem, shell, scriptDirectory, projectDirectory
Dim pythonWindow, command

Set fileSystem = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
projectDirectory = fileSystem.GetParentFolderName(scriptDirectory)
pythonWindow = fileSystem.BuildPath(projectDirectory, ".venv\Scripts\pythonw.exe")

If Not fileSystem.FileExists(pythonWindow) Then
    MsgBox "SniffPlay virtual environment was not found:" & vbCrLf & pythonWindow & vbCrLf & vbCrLf & "Run uv sync --extra dev first.", vbCritical, "SniffPlay"
    WScript.Quit 1
End If

shell.CurrentDirectory = projectDirectory
command = Quote(pythonWindow) & " -m sniffplay"
shell.Run command, 0, False

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
