; Inno Setup script for SSHub. Produces a single setup.exe that installs to
; Program Files, creates Start Menu and optional desktop shortcuts, and
; registers an uninstaller. Build with: iscc windows\packaging\sshub.iss

#define MyAppName "SSHub"
#define MyAppVersion "3.0.0"
#define MyAppPublisher "Mohammed Farhan K C"
#define MyAppExeName "sshub.exe"

[Setup]
AppId={{FBE4C2B1-DC99-4362-ADC4-A0A301BD999A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#SourcePath}\..\..\dist
OutputBaseFilename=sshub-windows-setup
SetupIconFile={#SourcePath}\..\runner\resources\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourcePath}\..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
