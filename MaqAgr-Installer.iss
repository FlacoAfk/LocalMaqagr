; ============================================================
; MaqAgr Local Installer - Inno Setup 6 Script
; Bundles: Node portable + PostgreSQL portable + backend + frontend
; 100% offline, no cloud dependencies
; ============================================================

#define MyAppName      "MaqAgr"
; Version can be overridden from the CLI (CI passes the release tag):
;   ISCC.exe /DMyAppVersionOverride=1.2.3 MaqAgr-Installer.iss
#ifndef MyAppVersionOverride
  #define MyAppVersion   "1.5.0"
#else
  #define MyAppVersion   MyAppVersionOverride
#endif
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
; Runtime database, logs and uploads must be writable by standard users.
; Application binaries remain protected under Program Files.
; node_modules stays writable so the launcher can self-heal a partially
; extracted install from the vendor backup (some machines deterministically
; lose node_modules/ip-address during extraction).
Name: "{app}\app\backend\node_modules";  Permissions: users-modify
Name: "{commonappdata}\MaqAgr\pgdata";            Permissions: users-modify; Flags: uninsneveruninstall
Name: "{commonappdata}\MaqAgr\logs";              Permissions: users-modify; Flags: uninsneveruninstall
Name: "{commonappdata}\MaqAgr\uploads";           Permissions: users-modify; Flags: uninsneveruninstall
Name: "{commonappdata}\MaqAgr\uploads\tractors";  Permissions: users-modify; Flags: uninsneveruninstall
Name: "{commonappdata}\MaqAgr\uploads\implements"; Permissions: users-modify; Flags: uninsneveruninstall
Name: "{commonappdata}\MaqAgr\uploads\users";     Permissions: users-modify; Flags: uninsneveruninstall
Name: "{commonappdata}\MaqAgr\uploads\general";   Permissions: users-modify; Flags: uninsneveruninstall

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
Source: "backend\*";                   DestDir: "{app}\app\backend"; Excludes: ".git\*,.env,.env.*,.env.*\*,uploads\*,coverage\*,tests\*,src\__tests__\*"; Flags: recursesubdirs ignoreversion

; --- Frontend production build (dist only) ---
Source: "frontend\dist\*";            DestDir: "{app}\app\frontend-dist"; Flags: recursesubdirs ignoreversion

; --- Local seed images (installed to ProgramData so the app can serve them) ---
Source: "install-assets\uploads\tractors\*";   DestDir: "{commonappdata}\MaqAgr\uploads\tractors";   Flags: onlyifdoesntexist uninsneveruninstall
Source: "install-assets\uploads\implements\*"; DestDir: "{commonappdata}\MaqAgr\uploads\implements"; Flags: onlyifdoesntexist uninsneveruninstall

; --- Léeme de primeros pasos (se muestra al terminar la instalación) ---
Source: "LEEME-PRIMEROS-PASOS.txt"; DestDir: "{app}"; Flags: isreadme ignoreversion

[Icons]
Name: "{group}\{#MyAppName}";         Filename: "{app}\scripts\{#MyAppExeName}"; IconFilename: "{app}\MaqAgr.ico"; WorkingDir: "{app}\scripts"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\scripts\{#MyAppExeName}"; IconFilename: "{app}\MaqAgr.ico"; WorkingDir: "{app}\scripts"; Tasks: desktopicon

[Run]
Filename: "{app}\scripts\{#MyAppExeName}"; Description: "Iniciar MaqAgr ahora"; Flags: nowait postinstall skipifsilent

; Uninstall removes application binaries only. ProgramData databases/uploads
; and per-user signing keys deliberately survive uninstall and reinstallation.
