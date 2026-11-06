#define AppVersion "1.0.6"


[Setup]
AppId={{9DF0F16A-06C7-41A5-9F87-2FDF0241A74C}
AppName=Mustek Studio
AppVersion={#AppVersion}
AppVerName=Mustek Studio {#AppVersion}
AppPublisher=Mustek Studio
DefaultDirName={localappdata}\Programs\MustekStudio
DefaultGroupName=Mustek Studio
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupArchitecture=x64
MinVersion=10.0
WizardStyle=modern dynamic
OutputDir=..\..
OutputBaseFilename=MustekStudio-Setup
SetupIconFile=..\app\assets\mustek-scanner-app-icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
UninstallDisplayIcon={app}\MustekStudio.exe
CreateUninstallRegKey=not ValidationMode
UsePreviousAppDir=not ValidationMode
UsePreviousLanguage=no
DisableProgramGroupPage=yes
AllowNoIcons=yes
CloseApplications=yes
RestartApplications=no
InfoAfterFile=INSTALL-RU.txt
SetupLogging=yes

[Languages]
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
ru.DesktopIcon=Создать ярлык на рабочем столе
en.DesktopIcon=Create a desktop shortcut
ru.ScannerConnection=Подключение и настройка сканера
en.ScannerConnection=Scanner connection and setup
ru.FinishSetup=Завершить настройку сканера и открыть Mustek Studio
en.FinishSetup=Complete scanner setup and open Mustek Studio
ru.DeleteScans=Удалить PDF, PNG и рабочие страницы из папки данных Mustek Studio? Нажмите «Нет», чтобы сохранить их.
en.DeleteScans=Delete PDF files, PNG files, and working pages from the Mustek Studio data folder? Select No to keep them.
ru.CloseStudio=Закройте Mustek Studio и повторите операцию.
en.CloseStudio=Close Mustek Studio and try again.
ru.CleanupFailed=Не удалось удалить часть файлов Mustek Studio. Проверьте, что они закрыты.
en.CleanupFailed=Some Mustek Studio files could not be removed. Make sure they are closed.

[Tasks]
Name: "desktopicon"; Description: "{cm:DesktopIcon}"; Flags: unchecked

[Files]
Source: "..\build\MustekStudio.exe"; DestDir: "{app}"; DestName: "MustekStudio.exe"; Flags: ignoreversion
Source: "..\build\ScannerConnection.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\downloads\zadig-2.9.exe"; DestDir: "{app}\tools"; Flags: ignoreversion
Source: "INSTALL-RU.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "INSTALL-EN.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "ZADIG-NOTICE.txt"; DestDir: "{app}\tools"; Flags: ignoreversion
Source: "..\licenses\libiconv\COPYING"; DestDir: "{app}\tools"; DestName: "COPYING-GPL3.txt"; Flags: ignoreversion

[Icons]
Name: "{group}\Mustek Studio"; Filename: "{app}\MustekStudio.exe"; WorkingDir: "{app}"; Check: not ValidationMode
Name: "{group}\{cm:ScannerConnection}"; Filename: "{app}\ScannerConnection.exe"; Parameters: "--language {language}"; WorkingDir: "{app}"; Check: not ValidationMode
Name: "{group}\{cm:UninstallProgram,Mustek Studio}"; Filename: "{uninstallexe}"; Check: not ValidationMode
Name: "{autodesktop}\Mustek Studio"; Filename: "{app}\MustekStudio.exe"; WorkingDir: "{app}"; Tasks: desktopicon; Check: not ValidationMode

[Run]
Filename: "{app}\MustekStudio.exe"; WorkingDir: "{app}"; Flags: nowait runasoriginaluser; Check: IsUpdate
Filename: "{app}\ScannerConnection.exe"; Parameters: "--finish --language {language}"; WorkingDir: "{app}"; Description: "{cm:FinishSetup}"; Flags: nowait postinstall skipifsilent runasoriginaluser; Check: not IsUpdate

[UninstallDelete]
Type: files; Name: "{app}\tools\zadig.ini"

[Code]
var
  DeleteScans: Boolean;

function IsUpdate: Boolean;
begin
  Result := ExpandConstant('{param:UPDATE|0}') = '1';
end;

function InitializeSetup: Boolean;
var
  MutexName: String;
  Attempts: Integer;
begin
  Result := True;
  if not IsUpdate then Exit;
  MutexName := ExpandConstant('{param:WAITMUTEX|}');
  if MutexName = '' then Exit;
  Attempts := 0;
  while CheckForMutexes(MutexName) and (Attempts < 100) do
  begin
    Sleep(200);
    Attempts := Attempts + 1;
  end;
  Result := not CheckForMutexes(MutexName);
  if not Result then MsgBox(CustomMessage('CloseStudio'), mbError, MB_OK);
end;

function ValidationMode: Boolean;
begin
  Result := ExpandConstant('{param:VALIDATE|0}') = '1';
end;

function IsReparsePoint(const Path: String): Boolean;
var
  Entry: TFindRec;
begin
  Result := False;
  if FindFirst(Path, Entry) then
  begin
    Result := (Entry.Attributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0;
    FindClose(Entry);
  end;
end;

{ Keep image exports and working pages, including those in a custom subfolder. }
function PruneData(const Path: String): Boolean;
var
  Entry: TFindRec;
  Child, Ext: String;
  Removed: Boolean;
begin
  Result := True;
  if not DirExists(Path) then Exit;
  if IsReparsePoint(Path) then
  begin
    Result := DelTree(Path, True, True, True);
    Exit;
  end;
  if FindFirst(Path + '\*', Entry) then
  begin
    try
      repeat
        if (Entry.Name <> '.') and (Entry.Name <> '..') then
        begin
          Child := Path + '\' + Entry.Name;
          if (Entry.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
            Removed := PruneData(Child)
          else
          begin
            Ext := Lowercase(ExtractFileExt(Entry.Name));
            Removed := (Ext = '.pdf') or (Ext = '.png');
            if not Removed then Removed := DelTree(Child, False, True, False);
          end;
          if not Removed then Result := False;
        end;
      until not FindNext(Entry);
    finally
      FindClose(Entry);
    end;
  end;
  RemoveDir(Path);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and not IsReparsePoint(ExpandConstant('{app}\MustekStudio.Data')) then
  begin
    if not PruneData(ExpandConstant('{app}\MustekStudio.Data\engine')) then
      Log('Some obsolete scanner runtime files could not be removed.');
  end;
end;

function InitializeUninstall: Boolean;
begin
  Result := not CheckForMutexes('Local\MustekStudio-Installed');
  if not Result then
  begin
    SuppressibleMsgBox(CustomMessage('CloseStudio'), mbError, MB_OK, IDOK);
    Exit;
  end;
  DeleteScans := False;
  if DirExists(ExpandConstant('{app}\MustekStudio.Data')) and not UninstallSilent then
    DeleteScans := MsgBox(CustomMessage('DeleteScans'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  DataPath: String;
  Removed: Boolean;
begin
  if CurUninstallStep <> usPostUninstall then Exit;
  DataPath := ExpandConstant('{app}\MustekStudio.Data');
  if not DirExists(DataPath) then Exit;
  if DeleteScans then Removed := DelTree(DataPath, True, True, True)
  else Removed := PruneData(DataPath);
  if not Removed then SuppressibleMsgBox(CustomMessage('CleanupFailed'), mbError, MB_OK, IDOK);
  RemoveDir(ExpandConstant('{app}'));
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = wpInfoAfter) and (ActiveLanguage = 'en') then
    WizardForm.InfoAfterMemo.Lines.LoadFromFile(ExpandConstant('{app}\INSTALL-EN.txt'));
end;
