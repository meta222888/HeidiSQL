unit updatecheck;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls, System.IniFiles, Vcl.Controls, Vcl.Graphics,
  apphelpers, gnugettext, Vcl.ExtCtrls, extra_controls, System.StrUtils, Vcl.Dialogs,
  Vcl.Menus, Vcl.Clipbrd, generic_types, System.DateUtils, System.IOUtils, System.JSON;

type
  TfrmUpdateCheck = class(TExtForm)
    btnCancel: TButton;
    groupBuild: TGroupBox;
    btnBuild: TButton;
    groupRelease: TGroupBox;
    LinkLabelRelease: TLinkLabel;
    lblStatus: TLabel;
    memoRelease: TMemo;
    memoBuild: TMemo;
    btnChangelog: TButton;
    popupDownloadRelease: TPopupMenu;
    CopydownloadURL1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure btnBuildClick(Sender: TObject);
    procedure LinkLabelReleaseLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure FormShow(Sender: TObject);
    procedure btnChangelogClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CopydownloadURL1Click(Sender: TObject);
  const
    SLinkDownloadRelease= 'download-release';
    SLinkInstructionsPortable = 'instructions-portable';
    SLinkChangelog = 'changelog';
  private
    BuildURL: String;
    ReleaseDownloadURL: String;
    ReleasePageURL: String;
    FLastStatusUpdate: Cardinal;
    FRestartTaskName: String;
    procedure Status(txt: String);
    procedure DownloadProgress(Sender: TObject);
    function GetLinkUrl(Sender: TObject; LinkType: String): String;
    function GetTaskXmlFileContents: String;
    function AppDirIsWritable: Boolean;
    function ParseReleaseTag(const Tag: String; out Major, Minor, Release, Revision: Word): Boolean;
    function IsRemoteVersionNewer(Major, Minor, Release, Revision: Word): Boolean;
    function PickReleaseAsset(Assets: TJSONArray): String;
  public
    BuildRevision: Integer;
    procedure ReadCheckFile;
  end;

procedure DeleteRestartTask;


implementation

uses main;

{$R *.dfm}

{$I const.inc}



procedure TfrmUpdateCheck.FormCreate(Sender: TObject);
begin
  HasSizeGrip := True;
  FRestartTaskName := 'yet_invalid';
  groupBuild.Visible := False;
end;

procedure TfrmUpdateCheck.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  AppSettings.WriteIntDpiAware(asUpdateCheckWindowWidth, Self, Width);
  AppSettings.WriteIntDpiAware(asUpdateCheckWindowHeight, Self, Height);
  if ModalResult <> btnBuild.ModalResult then begin
    DeleteRestartTask;
  end;
end;

procedure TfrmUpdateCheck.Status(txt: String);
begin
  lblStatus.Caption := txt;
  lblStatus.Repaint;
end;

procedure TfrmUpdateCheck.FormShow(Sender: TObject);
begin
  Width := AppSettings.ReadIntDpiAware(asUpdateCheckWindowWidth, Self);
  Height := AppSettings.ReadIntDpiAware(asUpdateCheckWindowHeight, Self);
  Caption := f_('Check for %s updates', [APPNAME]) + ' ...';
  Screen.Cursor := crHourglass;
  try
    Status(_('Downloading check file')+' ...');
    ReadCheckFile;
    if Mainform.AppVerRevision = 0 then
      Status(_('Error: Cannot determine current revision. Using a developer version?'))
    else if groupRelease.Enabled then
      Status(_('Updates available.'))
    else
      Status(f_('Your %s is up-to-date (no update available).', [APPNAME]));
  except
    on E:Exception do
      Status(E.Message);
  end;
  Screen.Cursor := crDefault;
  btnCancel.TrySetFocus;
end;

function TfrmUpdateCheck.ParseReleaseTag(const Tag: String; out Major, Minor, Release, Revision: Word): Boolean;
var
  S: String;
  Parts: TArray<String>;
begin
  S := Trim(Tag);
  if S.StartsWith('v', True) then
    Delete(S, 1, 1);
  Parts := S.Split(['.']);
  Major := StrToIntDef(Parts[0], 0);
  if Length(Parts) > 1 then Minor := StrToIntDef(Parts[1], 0) else Minor := 0;
  if Length(Parts) > 2 then Release := StrToIntDef(Parts[2], 0) else Release := 0;
  if Length(Parts) > 3 then Revision := StrToIntDef(Parts[3], 0) else Revision := 0;
  Result := Major > 0;
end;

function TfrmUpdateCheck.IsRemoteVersionNewer(Major, Minor, Release, Revision: Word): Boolean;
var
  Parts: TArray<String>;
  LocalMajor, LocalMinor, LocalRelease, LocalRevision: Word;
begin
  Parts := Mainform.AppVersion.Split(['.']);
  LocalMajor := StrToIntDef(Parts[0], 0);
  LocalMinor := StrToIntDef(IfThen(Length(Parts) > 1, Parts[1], '0'), 0);
  LocalRelease := StrToIntDef(IfThen(Length(Parts) > 2, Parts[2], '0'), 0);
  LocalRevision := StrToIntDef(IfThen(Length(Parts) > 3, Parts[3], '0'), 0);
  if Major <> LocalMajor then Exit(Major > LocalMajor);
  if Minor <> LocalMinor then Exit(Minor > LocalMinor);
  if Release <> LocalRelease then Exit(Release > LocalRelease);
  Result := Revision > LocalRevision;
end;

function JsonString(AJson: TJSONObject; const AName, ADefault: String): String;
var
  V: TJSONValue;
begin
  V := AJson.GetValue(AName);
  if V = nil then
    Result := ADefault
  else
    Result := V.Value;
end;

function TfrmUpdateCheck.PickReleaseAsset(Assets: TJSONArray): String;
var
  i: Integer;
  AssetName, NameLower: String;
  BestPortable, BestInstaller: String;

  function ScorePortable(const Name: String): Integer;
  begin
    Result := 0;
    if Name.Contains('portable') then Inc(Result, 10);
    if GetExecutableBits = 64 then begin
      if Name.Contains('64') then Inc(Result, 5);
    end else if Name.Contains('32') then
      Inc(Result, 5);
    if Name.EndsWith('.zip', True) then Inc(Result, 1);
  end;

begin
  Result := '';
  BestPortable := '';
  BestInstaller := '';
  for i := 0 to Assets.Count-1 do begin
    AssetName := JsonString(Assets.Items[i] as TJSONObject, 'name', '');
    NameLower := AssetName.ToLower;
    if NameLower.Contains('portable') then begin
      if (BestPortable = '') or (ScorePortable(NameLower) > ScorePortable(BestPortable.ToLower)) then
        BestPortable := JsonString(Assets.Items[i] as TJSONObject, 'browser_download_url', '');
    end else if NameLower.Contains('setup') and NameLower.EndsWith('.exe') then
      BestInstaller := JsonString(Assets.Items[i] as TJSONObject, 'browser_download_url', '');
  end;
  if AppSettings.PortableMode then
    Result := BestPortable
  else
    Result := BestInstaller;
  if Result = '' then
    Result := BestPortable;
end;

procedure TfrmUpdateCheck.ReadCheckFile;
var
  CheckfileDownload: THttpDownload;
  JsonText: String;
  Json: TJSONObject;
  Assets: TJSONArray;
  Tag, ReleaseVersion, ReleaseDate, ReleaseNotes: String;
  RemoteMajor, RemoteMinor, RemoteRelease, RemoteRevision: Word;
begin
  LinkLabelRelease.Enabled := False;
  btnBuild.Enabled := False;
  groupRelease.Enabled := False;
  memoRelease.Clear;
  memoBuild.Clear;
  ReleaseDownloadURL := '';
  ReleasePageURL := APPGITHUB_RELEASES;
  BuildRevision := Mainform.AppVerRevision;

  CheckfileDownload := THttpDownload.Create(Self);
  try
    CheckfileDownload.TimeOut := 15;
    CheckfileDownload.URL := 'https://api.github.com/repos/' + APPGITHUB_REPO + '/releases/latest';
    CheckfileDownload.SendRequest('');
    JsonText := CheckfileDownload.LastContent;
  finally
    CheckfileDownload.Free;
  end;

  AppSettings.WriteString(asUpdatecheckLastrun, DateTimeToStr(Now));

  Json := TJSONObject.ParseJSONValue(JsonText) as TJSONObject;
  if Json = nil then
    raise Exception.Create(_('Could not parse update information from GitHub.'));
  try
    Tag := JsonString(Json, 'tag_name', 'unknown');
    ReleasePageURL := JsonString(Json, 'html_url', APPGITHUB_RELEASES);
    ReleaseDate := JsonString(Json, 'published_at', '');
    ReleaseNotes := JsonString(Json, 'body', '');
    if not ParseReleaseTag(Tag, RemoteMajor, RemoteMinor, RemoteRelease, RemoteRevision) then
      raise Exception.Create(_('Could not parse release version tag.'));

    ReleaseVersion := Format('%d.%d.%d.%d', [RemoteMajor, RemoteMinor, RemoteRelease, RemoteRevision]);
    memoRelease.Lines.Add(f_('Version %s (yours: %s)', [ReleaseVersion, Mainform.AppVersion]));
    if ReleaseDate <> '' then
      memoRelease.Lines.Add(f_('Released: %s', [Copy(ReleaseDate, 1, 10)]));
    if ReleaseNotes <> '' then begin
      memoRelease.Lines.Add(_('Notes') + ':');
      memoRelease.Lines.Add(ReleaseNotes);
    end;

    Assets := Json.GetValue('assets') as TJSONArray;
    if Assets <> nil then
      ReleaseDownloadURL := PickReleaseAsset(Assets);

    LinkLabelRelease.Caption := f_('Download version %s', [ReleaseVersion]);
    LinkLabelRelease.Caption := '<a id="'+SLinkDownloadRelease+'">' + LinkLabelRelease.Caption + '</a>';
    if AppSettings.PortableMode then
      LinkLabelRelease.Caption := LinkLabelRelease.Caption + '   <a id="'+SLinkInstructionsPortable+'">'+_('Update instructions')+'</a>';

    groupRelease.Enabled := IsRemoteVersionNewer(RemoteMajor, RemoteMinor, RemoteRelease, RemoteRevision)
      and (ReleaseDownloadURL <> '');
    LinkLabelRelease.Enabled := groupRelease.Enabled and (ReleaseDownloadURL <> '');
    memoRelease.Enabled := groupRelease.Enabled;
    if not memoRelease.Enabled then
      memoRelease.Font.Color := GetThemeColor(cl3DDkShadow)
    else
      memoRelease.Font.Color := GetThemeColor(clWindowText);
  finally
    Json.Free;
  end;
end;

procedure TfrmUpdateCheck.LinkLabelReleaseLinkClick(Sender: TObject;
  const Link: string; LinkType: TSysLinkType);
begin
  case LinkType of
    sltURL: ShellExec(Link);
    sltID: begin
      if Link = SLinkDownloadRelease then begin
        ShellExec(GetLinkUrl(Sender, Link));
        Close;
      end
      else if Link = SLinkInstructionsPortable then begin
        MessageDialog(f_('Download the portable package and extract it in %s', [GetAppDir]), mtInformation, [mbOK]);
      end;
    end;
  end;
end;

procedure TfrmUpdateCheck.btnChangelogClick(Sender: TObject);
begin
  ShellExec(GetLinkUrl(Sender, SLinkChangelog));
end;

procedure TfrmUpdateCheck.CopydownloadURL1Click(Sender: TObject);
begin
  Clipboard.TryAsText := GetLinkUrl(LinkLabelRelease, SLinkDownloadRelease);
end;

procedure TfrmUpdateCheck.btnBuildClick(Sender: TObject);
var
  Download: THttpDownLoad;
  ExeName, DownloadFilename, UpdaterFilename: String;
  ResInfoblockHandle: HRSRC;
  ResHandle: THandle;
  ResPointer: PChar;
  Stream: TMemoryStream;
  BuildSizeDownloaded: Int64;
  DoOverwrite: Boolean;
  UpdaterAge: TDateTime;
begin
  Download := THttpDownload.Create(Self);
  Download.URL := BuildURL;
  ExeName := ExtractFileName(Application.ExeName);
  DownloadFilename := GetTempDir + ExeName;
  Download.OnProgress := DownloadProgress;
  if FileExists(DownloadFilename) then
    DeleteFile(DownloadFilename);
  try
    Download.SendRequest(DownloadFilename);
    if not FileExists(DownloadFilename) then
      Raise Exception.CreateFmt(_('Downloaded file not found: %s'), [DownloadFilename]);
    BuildSizeDownloaded := _GetFileSize(DownloadFilename);
    if BuildSizeDownloaded < SIZE_MB then
      Raise Exception.CreateFmt(_('Downloaded file corrupted: %s (Size is %d / too small)'), [DownloadFilename, BuildSizeDownloaded]);
    Status(_('Update in progress')+' ...');
    ResInfoblockHandle := FindResource(HInstance, 'UPDATER', 'EXE');
    ResHandle := LoadResource(HInstance, ResInfoblockHandle);
    if ResHandle <> 0 then begin
      Stream := TMemoryStream.Create;
      try
        ResPointer := LockResource(ResHandle);
        Stream.WriteBuffer(ResPointer[0], SizeOfResource(HInstance, ResInfoblockHandle));
        Stream.Position := 0;
        UpdaterFilename := GetTempDir + AppName+'_updater.exe';
        DoOverwrite := True;
        if FileExists(UpdaterFilename) and (Stream.Size = _GetFileSize(UpdaterFilename)) then begin
          FileAge(UpdaterFilename, UpdaterAge);
          if Abs(DaysBetween(Now, UpdaterAge)) < 30 then
            DoOverwrite := False;
        end;
        if DoOverwrite then
          Stream.SaveToFile(UpdaterFilename);
        ShellExec(UpdaterFilename, '', '"'+ParamStr(0)+'" "'+DownloadFilename+'" "'+FRestartTaskName+'"');
      finally
        UnlockResource(ResHandle);
        FreeResource(ResHandle);
        Stream.Free;
      end;
    end;
  except
    on E:Exception do
      ErrorDialog(E.Message);
  end;
end;

procedure TfrmUpdateCheck.DownloadProgress(Sender: TObject);
var
  Download: THttpDownload;
begin
  if FLastStatusUpdate > GetTickCount-200 then
    Exit;
  Download := Sender as THttpDownload;
  Status(f_('Downloading: %s', [FormatByteNumber(Download.BytesRead)]) + ' ...');
  FLastStatusUpdate := GetTickCount;
end;

function TfrmUpdateCheck.GetLinkUrl(Sender: TObject; LinkType: String): String;
begin
  if LinkType = SLinkDownloadRelease then
    Result := ReleaseDownloadURL
  else if LinkType = SLinkChangelog then
    Result := ReleasePageURL
  else
    Result := APPGITHUB_RELEASES;
end;

function TfrmUpdateCheck.GetTaskXmlFileContents: String;
begin
  Result := '<?xml version="1.0" encoding="UTF-16"?>' + sLineBreak +
    '<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">' + sLineBreak +
    '  <RegistrationInfo>' + sLineBreak +
    '    <Date>2022-12-24T12:39:17.5068755</Date>' + sLineBreak +
    '    <Author>' + APPNAME + ' ' + MainForm.AppVersion + '</Author>' + sLineBreak +
    '    <URI>\' + APPNAME + '_restart</URI>' + sLineBreak +
    '  </RegistrationInfo>' + sLineBreak +
    '  <Triggers>' + sLineBreak +
    '    <TimeTrigger>' + sLineBreak +
    '      <StartBoundary>2022-12-24T12:42:36</StartBoundary>' + sLineBreak +
    '      <Enabled>true</Enabled>' + sLineBreak +
    '    </TimeTrigger>' + sLineBreak +
    '  </Triggers>' + sLineBreak +
    '  <Principals>' + sLineBreak +
    '    <Principal id="Author">' + sLineBreak +
    '      <LogonType>InteractiveToken</LogonType>' + sLineBreak +
    '      <RunLevel>LeastPrivilege</RunLevel>' + sLineBreak +
    '    </Principal>' + sLineBreak +
    '  </Principals>' + sLineBreak +
    '  <Settings>' + sLineBreak +
    '    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>' + sLineBreak +
    '    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>' + sLineBreak +
    '    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>' + sLineBreak +
    '    <AllowHardTerminate>true</AllowHardTerminate>' + sLineBreak +
    '    <StartWhenAvailable>false</StartWhenAvailable>' + sLineBreak +
    '    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>' + sLineBreak +
    '    <IdleSettings>' + sLineBreak +
    '      <StopOnIdleEnd>true</StopOnIdleEnd>' + sLineBreak +
    '      <RestartOnIdle>false</RestartOnIdle>' + sLineBreak +
    '    </IdleSettings>' + sLineBreak +
    '    <AllowStartOnDemand>true</AllowStartOnDemand>' + sLineBreak +
    '    <Enabled>true</Enabled>' + sLineBreak +
    '    <Hidden>false</Hidden>' + sLineBreak +
    '    <RunOnlyIfIdle>false</RunOnlyIfIdle>' + sLineBreak +
    '    <WakeToRun>false</WakeToRun>' + sLineBreak +
    '    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>' + sLineBreak +
    '    <Priority>7</Priority>' + sLineBreak +
    '  </Settings>' + sLineBreak +
    '  <Actions Context="Author">' + sLineBreak +
    '    <Exec>' + sLineBreak +
    '      <Command>"' + ParamStr(0) + '"</Command>' + sLineBreak +
    '      <Arguments>--runfrom=scheduler</Arguments>' + sLineBreak +
    '    </Exec>' + sLineBreak +
    '  </Actions>' + sLineBreak +
    '</Task>';
end;

function TfrmUpdateCheck.AppDirIsWritable: Boolean;
var
  TestFile: string;
  H: THandle;
begin
  TestFile := IncludeTrailingPathDelimiter(GetAppDir) + 'chk.tmp';
  H := CreateFile(PChar(TestFile), GENERIC_READ or GENERIC_WRITE, 0, nil,
    CREATE_NEW, FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE, 0);
  Result := H <> INVALID_HANDLE_VALUE;
  if Result then
    CloseHandle(H);
  DeleteFile(TestFile);
end;

procedure DeleteRestartTask;
begin
  ShellExec('schtasks', '', '/Delete /TN "'+ValidFilename(ParamStr(0))+'" /F', True);
end;

end.
