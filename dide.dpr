program dide;

uses
  Forms,
  UFrmMain in 'UFrmMain.pas' {FrmMain},
  UFrmCodeInsight in 'UFrmCodeInsight.pas' {FrmCodeInsight},
  Themes,
  UCircBuf in 'UCircBuf.pas',
  UFrmPoti in 'UFrmPoti.pas' {FrmPoti},
  UHDMD in 'UHDMD.pas';

{$R *.res}

{$WARN DUPLICATE_CTOR_DTOR OFF} //C++ warning ignored

begin
  Application.Initialize;
//  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.CreateForm(TFrmCodeInsight, FrmCodeInsight);
  Application.CreateForm(TFrmPoti, FrmPoti);
  Application.Run;
end.
