unit About;

// -------------------------------------
// About-box
// -------------------------------------

interface

uses
  Winapi.Windows, System.Classes, Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, System.SysUtils, Vcl.ComCtrls, Vcl.Imaging.pngimage, gnugettext,
  Vcl.Dialogs, SynRegExpr, Vcl.Menus, Vcl.ClipBrd, extra_controls, generic_types, System.StrUtils;

type
  TAboutBox = class(TExtForm)
    btnClose: TButton;
    lblAppName: TLabel;
    lblAppVersion: TLabel;
    lblAppCompiled: TLabel;
    lnklblWebpage: TLinkLabel;
    btnUpdateCheck: TButton;
    ImageHeidisql: TImage;
    lnklblCredits: TLinkLabel;
    popupLabels: TPopupMenu;
    menuCopyLabel: TMenuItem;
    lblEnvironment: TLabel;
    lnklblCompiler: TLinkLabel;
    procedure OpenURL(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lnklblWebpageLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure lnklblCreditsLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure menuCopyLabelClick(Sender: TObject);
  private
    function GetDelphiVersion: String;
  public
  end;

implementation

uses
  main, apphelpers;

{$R *.DFM}


procedure TAboutBox.OpenURL(Sender: TObject);
begin
  ShellExec( TControl(Sender).Hint );
end;


procedure TAboutBox.menuCopyLabelClick(Sender: TObject);
var
  LabelComp: TComponent;
begin
  LabelComp := PopupComponent(Sender);
  if LabelComp is TLabel then begin
    Clipboard.TryAsText := TLabel(LabelComp).Caption;
  end;
end;

procedure TAboutBox.FormShow(Sender: TObject);
var
  OsMajor, OsMinor, OsBuild: Integer;
begin
  Screen.Cursor := crHourGlass;

  lblAppName.Font.Size := Round(lblAppName.Font.Size * 1.5);
  lblAppName.Font.Style := [fsBold];

  Caption := f_('About %s', [APPNAME]);
  lblAppName.Caption := APPNAME;
  lblAppVersion.Caption := _('Version') + ' ' + Mainform.AppVersion + ' (' + IntToStr(GetExecutableBits) + ' Bit)';
  lblAppCompiled.Caption := _('Compiled on:') + ' ' + DateTimeToStr(GetImageLinkTimeStamp(Application.ExeName)) + ' with';
  lnklblCompiler.Top := lblAppCompiled.Top;
  lnklblCompiler.Left := lblAppCompiled.Left + lblAppCompiled.Width + Canvas.TextWidth(' ');
  lnklblCompiler.Caption := '<a href="https://www.embarcadero.com/products/delphi?utm_source='+APPNAME+'">'+GetDelphiVersion+'</a>';
  lnklblWebpage.Caption := '<a href="'+APPDOMAIN+'">'+APPDOMAIN+'</a>';
  lnklblCredits.Caption := '<a href="">'+lnklblCredits.Caption+'</a>';
  ImageHeidisql.Hint := APPDOMAIN;
  lblEnvironment.Caption := _('Environment:');
  if IsWine then begin
    lblEnvironment.Caption := lblEnvironment.Caption +
      ' Linux/Wine';
  end else begin
    OsMajor := Win32MajorVersion;
    OsMinor := Win32MinorVersion;
    OsBuild := Win32BuildNumber;
    if (OsMajor = 10) and (OsBuild >= 22000) then
      OsMajor := 11;
    lblEnvironment.Caption := lblEnvironment.Caption +
      ' Windows ' +
      IntToStr(OsMajor) +
      IfThen(OsMinor > 0, '.'+IntToStr(OsMinor), '') +
      ' Build '+IntToStr(OsBuild);
  end;

  Screen.Cursor := crDefault;
  btnClose.TrySetFocus;
end;


procedure TAboutBox.lnklblCreditsLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  Help(Sender, 'credits');
end;

procedure TAboutBox.lnklblWebpageLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  ShellExec(Link);
end;

function TAboutBox.GetDelphiVersion: string;
begin
  {$IF Defined(VER360)}
    Result := '12';
  {$ELSEIF Defined(VER350)}
    Result := '11';
  {$ELSEIF Defined(VER340)}
    Result := '10.4';
  {$ELSE}
    Result := '10.3 or older';
  {$ENDIF}

  Result := 'Delphi ' + Result;
end;

end.
