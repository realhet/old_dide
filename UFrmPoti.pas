unit UFrmPoti;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, UHetSlider, het.utils, het.objects, het.parser,
  ExtCtrls;

type
  TFrmPoti = class(TForm)
    Slider1: TSlider;
    Slider2: TSlider;
    Slider3: TSlider;
    Slider4: TSlider;
    Slider5: TSlider;
    Slider6: TSlider;
    Slider7: TSlider;
    Slider8: TSlider;
    tUpdate: TTimer;
    procedure FormDestroy(Sender: TObject);
    procedure tUpdateTimer(Sender: TObject);
  private
    { Private declarations }
    running:boolean;
    FLastVisible:boolean;
    procedure SetWindowPlacement2(const Value: ansistring);
    function GetWindowPlacement2: ansistring;
    function GetDesktopConfig: ansistring;
    procedure setDesktopConfig(Value: ansistring);
    function getPotiValues: ansistring;
    procedure setPotiValues(const Value: ansistring);
    procedure setLastVisible(v:boolean);
  public
    { Public declarations }
    const PotiCount = 8;
  published
    property WindowPlacement2:ansistring read GetWindowPlacement2 write SetWindowPlacement2;
    property DesktopConfig:ansistring read GetDesktopConfig write SetDesktopConfig;
    property PotiValues:ansistring read getPotiValues write setPotiValues;
    property LastVisible:boolean read FLastVisible write SetLastVisible;
  protected
    procedure CreateParams(var Params: TCreateParams); override;

  end;

var
  FrmPoti: TFrmPoti;

implementation

{$R *.dfm}

uses UFrmMain;

function TFrmPoti.GetWindowPlacement2: ansistring;
begin
  result:=GetWindowPlacement;
end;

procedure TFrmPoti.SetWindowPlacement2(const Value: ansistring);
begin
  SetWindowPlacement(Value);
end;

procedure TFrmPoti.tUpdateTimer(Sender: TObject);
var i:integer;
begin
  if CheckAndSet(running)then begin//STARTUP
    DesktopConfig:=TFile(ChangeFileExt(ParamStr(0),'_sl.ini'));
  end;

  for i:=0 to PotiCount-1 do begin
    FrmMain.DebugLogServer.SetPotiValue(i, TSlider(FindComponent('Slider'+toStr(i+1))).value);
  end;

  FLastVisible:=Visible;
  if visible then SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE or SWP_NOACTIVATE);
end;

procedure TFrmPoti.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.WndParent:=0;
end;

procedure TFrmPoti.FormDestroy(Sender: TObject);
begin
  TFile(ChangeFileExt(ParamStr(0),'_sl.ini')).Write(DesktopConfig);
end;

function TFrmPoti.GetDesktopConfig:ansistring;
begin
  result:='{HetIDE Desktop Config}'#13#10+
    DumpProperties(self,'PotiValues,Left,Top,LastVisible');
end;

function TFrmPoti.getPotiValues: ansistring;
var i:integer;
begin
  result:='';
  for i:=0 to PotiCount-1 do result:=result+toStr(TSlider(FindComponent('Slider'+toStr(i+1))).value)+';';
end;

procedure TFrmPoti.setDesktopConfig(Value:ansistring);
begin
  try
    Eval(Value,self);
  except end;
end;

procedure TFrmPoti.setLastVisible(v: boolean);
begin
  Visible:=v;
end;

procedure TFrmPoti.setPotiValues(const Value: ansistring);
var i:integer;
    sl:TSlider;
    s:ansistring;
begin
  i:=0;
  for s in listSplit(value, ';')do begin
    sl:=TSlider(FindComponent('Slider'+toStr(i+1)));
    if sl<>nil then sl.Value:=StrToFloatDef(s, 0);
    inc(i);
  end;
end;

end.
