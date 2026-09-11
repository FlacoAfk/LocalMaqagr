; ============================================================
; MaqAgr Local Installer - Inno Setup 6 Script
; Bundles: Node portable + PostgreSQL portable + backend + frontend
; 100% offline, no cloud dependencies
; ============================================================

#define MyAppName      "MaqAgr"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "MaqAgr"
#define MyAppExeName   "start-maqagr.bat"

[Setup]
AppId={{MAQAGR-LOCAL-2024-07-30}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={commonpf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=build
OutputBaseFilename=MaqAgr-Setup
SetupIconFile=MaqAgr.ico
UninstallDisplayIcon={app}\MaqAgr.ico
Compression=lzma2/ultra
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
WizardStyle=modern
DisableDirPage=no
DisableReadyPage=yes
DiskSpanning=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un acceso directo en el escritorio"; GroupDescription: "Additional shortcuts:"

[Dirs]
; Runtime upload data only: normal users need modify/delete rights.
Name: "{commonappdata}\MaqAgr\uploads";           Permissions: users-modify
Name: "{commonappdata}\MaqAgr\uploads\tractors";  Permissions: users-modify
Name: "{commonappdata}\MaqAgr\uploads\implements"; Permissions: users-modify
Name: "{commonappdata}\MaqAgr\uploads\users";     Permissions: users-modify
Name: "{commonappdata}\MaqAgr\uploads\general";   Permissions: users-modify

[Files]
; --- Launcher scripts ---
Source: "scripts\launcher.ps1";       DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "scripts\start-maqagr.bat";   DestDir: "{app}\scripts"; Flags: ignoreversion

; --- Application icon ---
Source: "MaqAgr.ico";                  DestDir: "{app}";        Flags: ignoreversion

; --- Node.js portable runtime ---
Source: "runtime\node\*";              DestDir: "{app}\runtime\node";  Flags: recursesubdirs ignoreversion

; --- PostgreSQL portable runtime ---
Source: "runtime\pgsql\*";            DestDir: "{app}\runtime\pgsql"; Flags: recursesubdirs ignoreversion

; --- Backend (source + node_modules + database SQL) ---
; Excludes: .git (VCS), .env (dev config — launcher sets env at runtime), uploads (dev artifacts)
Source: "backend\*";                   DestDir: "{app}\app\backend"; Excludes: ".git\*,.env,uploads\*"; Flags: recursesubdirs ignoreversion

; --- Frontend production build (dist only) ---
Source: "frontend\dist\*";            DestDir: "{app}\app\frontend-dist"; Flags: recursesubdirs ignoreversion

; --- Local seed images (installed to ProgramData so the app can serve them) ---
Source: "install-assets\uploads\tractors\*";   DestDir: "{commonappdata}\MaqAgr\uploads\tractors";   Flags: ignoreversion
Source: "install-assets\uploads\implements\*"; DestDir: "{commonappdata}\MaqAgr\uploads\implements"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";         Filename: "{app}\scripts\{#MyAppExeName}"; IconFilename: "{app}\MaqAgr.ico"; WorkingDir: "{app}\scripts"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\scripts\{#MyAppExeName}"; IconFilename: "{app}\MaqAgr.ico"; WorkingDir: "{app}\scripts"; Tasks: desktopicon

[Run]
Filename: "{app}\scripts\{#MyAppExeName}"; Description: "Iniciar MaqAgr ahora"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Clean up writable data in ProgramData on uninstall
Type: filesandordirs; Name: "{commonappdata}\MaqAgr"
