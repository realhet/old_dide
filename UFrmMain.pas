unit UFrmMain;//het.glviewer   opengl1x het.midi het.cl
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, StdCtrls, math, clipbrd, ImgList, ComCtrls,
  het.utils, het.Objects, het.Variants, het.arrays, het.Parser, het.codeeditor,
  unsSystem, shellapi, het.gfx, UHetPaintBox, Types, UHDMD;

type
  TEditorSheet=class(TTabSheet)
  public
    Editor:TCodeEditor;
    errorCount:integer;
    destructor Destroy;override;
    function Changed:boolean;
    function IsNewAndUnchanged:boolean;
    procedure UpdateUI;
  end;

  TDebugLogServer = class
  private
    type
      TBreakRec=packed record
        locationHash,
        state:integer;
      end;
      TData=packed record
        ping:cardinal;

        breakTable:array[0..63]of TBreakRec;

        //circular buffer
        tail,head:cardinal;
        circBuf:array[0..$FFFF]of byte;

        //poti
        poti: array[0..7]of single;
        force_exit:integer;
        exe_waiting:integer; //ha ez true, akkor a continue button aktiv lesz. (F9) Megnyomasakor dide_ack = 1 jelzi, hogy mehet tovabb
        dide_ack:integer; //ha EXCEPTION log jott, akkor ezt 1-re irja akkor, amikor tovabbmehet.
        dide_hwnd, exe_hwnd:integer; //to call setForegroundWindow from exe
      end;
      PData = ^TData;
    const
      dataFileName:pchar = 'Global\DIDE_DebugFileMappingObject';
  private
    dataFile:THandle;
    dataSize:integer;
    data:PData;

    pingState:array[0..7]of byte;

    procedure updatePing;
    procedure drawPing(canvas:TCanvas; x, y, h:integer);
  private
    logEvents:TArray<ansistring>;
    procedure updateLog;
    procedure processLogMessage(s:ansistring);
  public
    constructor create;
    function update:boolean;
    procedure draw(canvas:TCanvas; r:trect);

    procedure clearLog;
    function getLogCount:integer;
    function getLogStr(idx:integer):ansistring;
    var logChanged:boolean; //signal to redraw log list

    procedure setPotiValue(idx:integer; val:single);

    procedure clearExit;
    procedure forceExit;

    procedure resetBeforeRun;
  end;

  TFrmMain = class(TForm)
    pLeft: TPanel;
    pcEditor: TPageControl;
    tUpdateUI: TTimer;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ilIcons: TImageList;
    StatusBar: TStatusBar;
    pFindReplace: TPanel;
    cbFind: TComboBoxEx;
    chWholeWords: TCheckBox;
    chBackwards: TCheckBox;
    bFindNext: TButton;
    cbReplace: TComboBoxEx;
    bReplace: TButton;
    bReplaceAll: TButton;
    chPromptOnReplace: TCheckBox;
    bFindClose: TButton;
    MainMenu1: TMainMenu;
    mFile: TMenuItem;
    mFileNew: TMenuItem;
    mFileOpen: TMenuItem;
    mFileReopen: TMenuItem;
    N1: TMenuItem;
    mFileSave: TMenuItem;
    mFileSaveAs: TMenuItem;
    mFileSaveAll: TMenuItem;
    mFileClose: TMenuItem;
    mFileCloseAll: TMenuItem;
    N2: TMenuItem;
    mFileExit: TMenuItem;
    mEdit: TMenuItem;
    mEditUndo: TMenuItem;
    mEditRedo: TMenuItem;
    N3: TMenuItem;
    mEditCut: TMenuItem;
    mEditCopy: TMenuItem;
    mEditPaste: TMenuItem;
    mEditDelete: TMenuItem;
    mEditSelectAll: TMenuItem;
    mSearch: TMenuItem;
    mCompile: TMenuItem;
    mHelp: TMenuItem;
    mSearchFind: TMenuItem;
    mSearchReplace: TMenuItem;
    mSearchSearchAgain: TMenuItem;
    mSearchGotoLineNumber: TMenuItem;
    mCompileCompile: TMenuItem;
    mRunRun: TMenuItem;
    mHelpHelpatCursor: TMenuItem;
    mFileReopenClear: TMenuItem;
    N4: TMenuItem;
    chCaseSensitive: TCheckBox;
    N6: TMenuItem;
    mEditCopyHtml: TMenuItem;
    HetPaintBox1: THetPaintBox;
    pbDebugLeds: THetPaintBox;
    Splitter1: TSplitter;
    mDebug: TMenuItem;
    mDebugModeToggle: TMenuItem;
    mRemoveAllMarkers: TMenuItem;
    pcRight: TPageControl;
    tsDebug: TTabSheet;
    tsCompile: TTabSheet;
    lbLog: TListBox;
    lbCompileOutput: TListBox;
    TogglePoti: TMenuItem;
    mCompileBuild: TMenuItem;
    Run1: TMenuItem;
    mRunProgramReset: TMenuItem;
    procedure mFileNewClick(Sender: TObject);
    procedure tUpdateUITimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mFileExitClick(Sender: TObject);
    procedure mFileSaveClick(Sender: TObject);
    procedure mFileOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mFileSaveAsClick(Sender: TObject);
    procedure mFileSaveAllClick(Sender: TObject);
    procedure mFileCloseClick(Sender: TObject);
    procedure mFileCloseAllClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure mFileReopenClearClick(Sender: TObject);
    procedure mEditUndoClick(Sender: TObject);
    procedure mEditRedoClick(Sender: TObject);
    procedure mEditCutClick(Sender: TObject);
    procedure mEditCopyClick(Sender: TObject);
    procedure mEditPasteClick(Sender: TObject);
    procedure mEditDeleteClick(Sender: TObject);
    procedure mEditSelectAllClick(Sender: TObject);
    procedure mSearchFindClick(Sender: TObject);
    procedure mSearchReplaceClick(Sender: TObject);
    procedure cbFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bFindNextClick(Sender: TObject);
    procedure cFindCloseClick(Sender: TObject);
    procedure bReplaceClick(Sender: TObject);
    procedure bReplaceAllClick(Sender: TObject);
    procedure mSearchSearchAgainClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mRunRunClick(Sender: TObject);
    procedure mEditCopyHtmlClick(Sender: TObject);
    procedure StatusBarDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
      const Rect: TRect);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure pbDebugLedsPaint(Sender: TObject);
    procedure pcEditorDrawTab(Control: TCustomTabControl; TabIndex: Integer;
      const Rect: TRect; Active: Boolean);
    procedure lbLogData(Control: TWinControl; Index: Integer; var Data: string);
    procedure mDebugModeToggleClick(Sender: TObject);
    procedure mRemoveAllMarkersClick(Sender: TObject);
    procedure mSearchGotoLineNumberClick(Sender: TObject);
    procedure mCompileCompileClick(Sender: TObject);
    procedure lbCompileOutputDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure lbCompileOutputDblClick(Sender: TObject);
    procedure TogglePotiClick(Sender: TObject);
    procedure mCompileBuildClick(Sender: TObject);
    procedure mRunProgramResetClick(Sender: TObject);
    procedure lbCompileOutputClick(Sender: TObject);
    procedure lbCompileOutputKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
    running:boolean;
    serverLaunchCnt:integer; //launches dcd-server a bit later
    OriginalCaption:string;
    procedure mFileReopenItemClick(Sender: TObject);
    procedure WMEraseBkGnd(var Message:TMessage); message WM_ERASEBKGND;
  private
  type
    TFindOperation=(opNone,opFind,opReplace,opReplaceAll);
    TFindCommand=record
      Operation:TFindOperation;
      FindText,ReplaceWith:ansistring;
      CaseSensitive,WholeWords,Backwards,PromptOnReplace:boolean;
    end;
  private
    LastFindCommand:TFindCommand;
    procedure FindCommandPrepareFromUi(var fc:TFindCommand;const op:TFindOperation);
    procedure FindCommandExecute(const fc:TFindCommand);
    function isMainSource(const code: ansistring): boolean;
  public
    { Public declarations }
    function EditorCount:integer;
    function GetEditor(const n:variant):TEditorSheet;
    property Editor[const n:Variant]:TEditorSheet read GetEditor;
    function GetActEditor:TEditorSheet;
    function ActCodeEditor:TCodeEditor;
    procedure SetActEditor(const Value:TEditorSheet);
    property ActEditor:TEditorSheet read GetActEditor write SetActEditor;

    function NewEditor: TEditorSheet;
    procedure NewFile;
    procedure OpenFile(const fn: AnsiString);
    procedure HandleDropFiles(files:TArray<string>);

    function GetOpenedFiles:string;procedure SetOpenedFiles(const Value:string);

    function GetReopenHistory:string;procedure SetReopenHistory(const Value:string);
    procedure AddReopenHistory(const fn:string);

    function GetDesktopConfig:AnsiString;
    procedure SetDesktopConfig(const Value:ansistring);
    property DesktopConfig:ansistring read GetDesktopConfig write SetDesktopConfig;

    function GetFindWindowState:integer;procedure SetFindWindowState(const Value:integer);
    property FindWindowState:integer{0..2} read GetFindWindowState write SetFindWindowState;

    procedure UpdateMenuItems;
    procedure UpdateStatusbar;

    function GetStatus:ansistring;
    procedure SetStatus(const Value:ansistring);
    property Status:ansistring read GetStatus write SetStatus;

    procedure ClearErrorLine;
    procedure SetErrorLine(fn:string; line:integer; errortype:TErrorType);
  private
    procedure SetWindowPlacement2(const Value: ansistring);
    function GetWindowPlacement2: ansistring;
  private
    function GetBookmarkConfig: string;
    procedure SetBookmarkConfig(const Value: string);
    function GetEditorPositionConfig: string;
    procedure SetEditorPositionConfig(const Value: string);
  published //streamed properties
    property WindowPlacement2:ansistring read GetWindowPlacement2 write SetWindowPlacement2;
    {!!!! property WindowPlacement; !!!Ez XE-n F2084 Internal Error-t dob, ha van debugInfo
     !!!! tilos ClassHelper propertyt published-e tenni
     !!!! megoldas: manualisan rakotni a propertyt a Get/Set WindowPlacement helper finctokra}

    property OpenedFiles:string read GetOpenedFiles write SetOpenedFiles;
    property ReopenHistory:string read GetReopenHistory write SetReopenHistory;
    property BookmarkConfig:string read GetBookmarkConfig write SetBookmarkConfig;
    property EditorPositionConfig:string read GetEditorPositionConfig write SetEditorPositionConfig;
  public
    function OnGetFileExt:ansistring;virtual;
    //Syntax highight support
    procedure OnSyntax(const Sender:TCodeEditor;const ASrc:ansistring;var ASyntaxHighlight, ATokenHighlight:ansistring; bigComments:PAnsiChar; bigCommentsLen:integer; const AFrom:integer=1;const ATo:integer=$7fffffff);virtual;


    //Code insight
    function OnGetWordList(const Editor:TCodeEditor):TArray<ansistring>;virtual;
    //compile/run
  var
    MainFileName:string;
    procedure SetEditorCursor(hourglass:boolean);

    function DCDQuery(cmd, path:string):ansistring; //Code completion query
    procedure JumpToDeclaration;


  private
    FDebugMode:boolean;
    procedure SetDebugMode(b:boolean);
    procedure GotoError(msg: ansistring);

  private //bookmarks
    Bookmarks:array[0..9]of record fileName:string; scrollPos, cursorPos:TPoint; end;

    procedure BookmarkRecall(n: integer);
    procedure BookmarkSave(n: integer);
    procedure UpdateBookmarks;

    procedure CompileAndRun(doRun, doRebuild:boolean);
    function processErrorMessages(src: ansistring): ansistring;
    procedure markErronousFiles(hdmdErr:ansistring);
    procedure HighLightDMDLine(Canvas: TCanvas; rect: TRect; s: ansistring);
    function exeIsWaiting: boolean;
  public //debugLog
    DebugLogServer:TDebugLogServer;
    property DebugMode:boolean read FDebugMode write SetDebugMode;
  end;

var FrmMain: TFrmMain; //inherited form!!!

implementation

uses UFrmCodeInsight, het.FileSys, UCircBuf, UFrmPoti;

{$R *.dfm}


////////////////////////////////////////////////////////////////////////////////
/// TEditorSheet                                                             ///
////////////////////////////////////////////////////////////////////////////////

function TEditorSheet.Changed:boolean;
begin
  result:=Editor.FileOps.ischanged;
end;

function TEditorSheet.IsNewAndUnchanged:boolean;
begin
  Result:=Editor.FileOps.IsNew and not Changed;
end;

procedure TEditorSheet.UpdateUI;
var s:string;
begin
  //if not Editor.CanUndo then Editor.FileOps.isChanged:=false;full undonal nincs chg -> faszsag, kiiktatva

  s:=ExtractFileName(Editor.FileOps.FileName);
  if  Changed then s:='*'+s;
  Caption:=s;
end;

destructor TEditorSheet.Destroy;
begin
  if not Editor.FileOps.IsNew then
    TFrmMain(Owner).AddReopenHistory(Editor.FileOps.FileName);

  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
/// TFrmMain

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  OpenDialog1.Filter:=OnGetFileExt+' files|*.'+OnGetFileExt+';*.inc';
  SaveDialog1.Filter:=OpenDialog1.Filter;
  SaveDialog1.DefaultExt:=OnGetFileExt;

  DebugLogServer:=TDebugLogServer.create;
end;

procedure TFrmMain.FormShow(Sender: TObject);
var fn:string;
begin
  if CheckAndSet(running)then begin//STARTUP
    DesktopConfig:=TFile(ChangeFileExt(ParamStr(0),'.ini'));

    fn:=ParamStr(1);
    if(fn<>'')then OpenFile(fn);
  end;
end;

procedure TFrmMain.mFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  freeAndNil(DebugLogServer);

  TFile(ChangeFileExt(ParamStr(0),'.ini')).Write(DesktopConfig);

  ShellExecute(handle,'open','dcd-client.exe', '--shutdown','',SW_HIDE);
end;

function TFrmMain.EditorCount: integer;
begin
  result:=pcEditor.PageCount;
end;

function TFrmMain.GetEditor(const n: variant): TEditorSheet;
var i:integer;
begin
  if VarIsOrdinal(n) then
    result:=TEditorSheet(pcEditor.Pages[n])
  else begin
    for i:=0 to EditorCount-1 do begin
      result:=Editor[i];
      if IsWild2(Result.Editor.FileOps.FileName,n) then exit;
    end;
    result:=nil;
  end;
end;

function TFrmMain.GetActEditor:TEditorSheet;
begin
  result:=TEditorSheet(pcEditor.ActivePage);
end;

function TFrmMain.ActCodeEditor: TCodeEditor;
begin
  result:=nil;
  if(ActiveControl<>nil)and(ActiveControl is TCodeEditor)then
    result:=TCodeEditor(ActiveControl);
  if(result=nil)and(GetActEditor<>nil)then
    result:=GetActEditor.Editor;
end;

procedure TFrmMain.SetActEditor(const Value:TEditorSheet);
begin
  if(Value=nil)then exit;
  pcEditor.ActivePage:=Value;
  Value.Editor.SetFocus;
end;

function TFrmMain.GetOpenedFiles:string;var i:integer;
begin
  result:='';for i:=0 to EditorCount-1 do result:=result+
    switch(result='','','|')+switch(pcEditor.ActivePage=Editor[i],'*','')+Editor[i].Editor.FileOps.FileName;
end;

procedure TFrmMain.SetOpenedFiles(const Value:string);var i:integer;
var s,fn:AnsiString;
    isact:boolean;
    act:TEditorSheet;
begin
  for i:=EditorCount-1 downto 0 do Editor[i].Free;

  act:=nil;
  for s in ListSplit(Value,'|')do begin
    isact:=charn(s,1)='*';
    if isact then fn:=Copy(s,2)else fn:=s;
    OpenFile(fn);
    if isact then act:=ActEditor;
  end;

  ActEditor:=act;
end;

function TFrmMain.GetReopenHistory:string;
var i:integer;
    Items:TMenuItem;
begin
  result:='';
  Items:=mFileReopen;
  for i:=0 to Items.Count-3 do result:=result+
    switch(i=0,'','|')+copy(Items[i].Caption,4);
end;

procedure TFrmMain.SetReopenHistory(const Value:string);
const maxcnt=24;
var Items:TMenuItem;s:ansistring;i:integer;mi:TMenuItem;
begin
  Items:=mFileReopen;
  while Items.Count<maxCnt+2 do begin
    mi:=TMenuItem.Create(self);
    Items.Insert(0,mi);
    mi.OnClick:=mFileReopenItemClick;
    mi.Visible:=false;
  end;

  for i:=0 to maxCnt-1 do with Items[i]do begin
    s:=ListItem(Value,i,'|');
    Visible:=s<>'';
    Caption:='&'+ansichar(ord('A')+i)+' '+s;//delphis takolas, de ha naluk is jo....
  end;
end;

procedure TFrmMain.mFileReopenItemClick(Sender:TObject);
begin
  OpenFile(copy(TMenuItem(Sender).Caption,4));
end;

procedure TFrmMain.AddReopenHistory(const fn:string);
var h:ansistring;
    n:integer;
begin
  h:=GetReopenHistory;
  n:=ListFind(h,fn,'|');if n>0 then DelListItem(h,n,'|');
  ReopenHistory:=fn+'|'+h;
end;

function TFrmMain.GetDesktopConfig:ansistring;
begin
  result:='{HetIDE Desktop Config}'#13#10+
    DumpProperties(self,'WindowPlacement2,OpenedFiles,ReopenHistory,BookmarkConfig,EditorPositionConfig'); //pcRight.Height
end;

procedure TFrmMain.SetDebugMode(b: boolean);
var i:integer;
begin
  if FDebugMode=b then exit;
  FDebugMode:=b;
  for i:=0 to EditorCount-1 do Editor[i].Editor.DebugMode:=DebugMode;
end;

procedure TFrmMain.SetDesktopConfig(const Value: ansistring);
begin
  try
    Eval(Value,self);
  except end;
end;

function TFrmMain.exeIsWaiting:boolean;
begin
  result:=DebugLogServer.data.exe_waiting<>0;
end;

procedure TFrmMain.tUpdateUITimer(Sender: TObject);var i:integer;
var s:string;
    e:TCodeEditor;
//    cp, ss, se:integer;
begin
  if ActEditor=nil then e:=nil else e:=ActEditor.editor;
{  if e<>nil then begin
    cp:=e.xy2pos(e.CursorPos, false);
    ss:=e.xy2pos(e.SelStart, false);
    se:=e.xy2pos(e.SelEnd, false);
    if ss=se then begin
      ss:=cp; se:=cp;
    end;
  end else begin se:=0; ss:=0; cp:=0; end; //nowarn}

  DragAcceptFiles(Handle, true);

  for i:=0 to EditorCount-1 do Editor[i].UpdateUI;

  if OriginalCaption='' then OriginalCaption:=Caption;

  if e=nil then s:='' else s:=' ['+ExtractFileName(e.FileOps.FileName)+']';

  Caption:=OriginalCaption+s+
    switch(exeIsWaiting and (frac(QPS*2)<0.5), ' ***BREAK*** ', '')+
    switch(DebugMode and (frac(QPS)<0.5),
    ' ###>>> DEBUG <<<###',
     '');

  UpdateMenuItems;
  UpdateStatusBar;

  if checkAndClear(FrmCodeInsight.ShowDotCompletionAgain)then
    FrmCodeInsight.StartInsight(ActCodeEditor);

  if ActEditor<>nil then if CheckAndClear(ActEditor.Editor.CtrlLMBClicked)then
    JumpToDeclaration;

  //start the dcd server a bit later
  inc(serverLaunchCnt);
  if serverLaunchCnt=15 then begin
    ShellExecute(handle,'open','dcd-server.exe', '','',SW_HIDE);
  end;

  //debug
  if DebugLogServer.update then begin
    pbDebugLeds.Invalidate;

    if CheckAndClear(DebugLogServer.logChanged) then begin
      lbLog.Count:=DebugLogServer.getLogCount;
      lbLog.ItemIndex:=lbLog.Count-1; //focus on last item
      lbLog.Invalidate;
    end;
  end;

  mDebugModeToggle.Checked:=DebugMode;

  //Bookmarks
  UpdateBookmarks;
end;

procedure TFrmMain.UpdateBookmarks;
var n:integer;
begin
  if ActEditor=nil then exit; //A recallnak enelkul is kene mennie, csak akkor nem egy letezo editorbol kene eszlelni a shortcutot...

  if BookmarkSaveRequest  >=0 then begin n:=BookmarkSaveRequest  ; BookmarkSaveRequest  :=-1; BookmarkSave  (n);end;
  if BookmarkRecallRequest>=0 then begin n:=BookmarkRecallRequest; BookmarkRecallRequest:=-1; BookmarkRecall(n);end;
end;

procedure TFrmMain.BookmarkSave(n:integer);
var e:TCodeEditor;
begin
  if ActEditor=nil then exit;
  e:=ActEditor.Editor;
  if not inRange(n, low(Bookmarks), high(Bookmarks))then exit;

  with Bookmarks[n]do begin
    fileName:=e.FileOps.FileName;
    cursorPos:=e.CursorPos;
    scrollPos:=e.ScrollPos;
  end;
end;

procedure TFrmMain.BookmarkRecall(n:integer);
var e:TCodeEditor;
begin
  if not inRange(n, low(Bookmarks), high(Bookmarks))then exit;

  with Bookmarks[n]do begin
    OpenFile(fileName);
    if ActEditor=nil then exit;
    e:=ActEditor.Editor;
    e.CursorPos:=cursorPos;
    e.ScrollPos:=scrollPos;
  end;
end;

function TFrmMain.GetBookmarkConfig: string;
var i:integer;
    s,t:string;
begin
  s:='';
  for i:=low(Bookmarks) to high(Bookmarks)do with Bookmarks[i]do begin
    t:=fileName+'|'+
       ToStr(cursorPos.x)+'|'+
       ToStr(cursorPos.y)+'|'+
       ToStr(scrollPos.x)+'|'+
       ToStr(scrollPos.y);
    s:=s+t+'>';
  end;
  result:=s;
end;

procedure TFrmMain.SetBookmarkConfig(const Value: string);
var i:integer;
    s,t:ansistring;
begin
  s:=Value;
  for i:=low(Bookmarks) to high(Bookmarks)do with Bookmarks[i]do begin
    t:=ListItem(s, i, '>');
    fileName:=ListItem(t, 0, '|');
    cursorPos.x:=StrToIntDef(ListItem(t, 1, '|'), 0);
    cursorPos.y:=StrToIntDef(ListItem(t, 2, '|'), 0);
    scrollPos.x:=StrToIntDef(ListItem(t, 3, '|'), 0);
    scrollPos.y:=StrToIntDef(ListItem(t, 4, '|'), 0);
  end;
end;

function TFrmMain.GetEditorPositionConfig: string;
var i:integer;
    s,t:string;
begin
  s:='';
  for i:=0 to EditorCount-1 do with Editor[i].editor do begin
    t:=fileOps.fileName+'|'+
       ToStr(cursorPos.x)+'|'+
       ToStr(cursorPos.y)+'|'+
       ToStr(scrollPos.x)+'|'+
       ToStr(scrollPos.y)+'|'+
       ToStr(selStart.x)+'|'+
       ToStr(selStart.y)+'|'+
       ToStr(selEnd.x)+'|'+
       ToStr(selEnd.y);
    s:=s+t+'>';
  end;
  result:=s;
end;

procedure TFrmMain.SetEditorPositionConfig(const Value: string);
var i:integer;
    s,t:ansistring;
begin
  s:=Value;
  for i:=0 to EditorCount-1 do with Editor[i].editor do begin
    t:=ListItem(s, i, '>');
    if ListItem(t, 0, '|')=fileOps.fileName then begin
      cursorPos:=Point(StrToIntDef(ListItem(t, 1, '|'), 0),
                       StrToIntDef(ListItem(t, 2, '|'), 0));
      scrollPos:=Point(StrToIntDef(ListItem(t, 3, '|'), 0),
                       StrToIntDef(ListItem(t, 4, '|'), 0));
      selStart :=Point(StrToIntDef(ListItem(t, 5, '|'), 0),
                       StrToIntDef(ListItem(t, 6, '|'), 0));
      selEnd   :=Point(StrToIntDef(ListItem(t, 7, '|'), 0),
                       StrToIntDef(ListItem(t, 8, '|'), 0));
    end;
  end;
end;

procedure TFrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);var i:integer;
begin
  for i:=0 to EditorCount-1 do Editor[i].Editor.FileOps.CloseQuery(CanClose);
end;

procedure TFrmMain.UpdateMenuItems;

  function ClipboardCanPasted:boolean;
  begin
    try
      result:=Clipboard.HasFormat(CF_TEXT);
    except
      result:=false;
    end;
  end;

  function AnyEditorChanged:boolean;var i:integer;
  begin
    for i:=0 to EditorCount-1 do if Editor[i].Editor.FileOps.ischanged then exit(true);
    result:=false;
  end;

var e,ec:boolean;
begin
  e:=ActEditor<>nil;
  ec:=ActCodeEditor<>nil;
  with ActEditor do begin

    mFileSave.Enabled:=e and Editor.FileOps.ischanged;
    mFileSaveAs.Enabled:=e;
    mFileSaveAll.Enabled:=e and AnyEditorChanged;
    mFileReopenClear.Enabled:=mFileReopen.Count>2;

    mFileClose.Enabled:=e;
    mFileCloseAll.Enabled:=EditorCount>0;

    mEditUndo.Enabled:=ec and ActCodeEditor.CanUndo;
    mEditRedo.Enabled:=ec and ActCodeEditor.CanRedo;

    mEditCut.Enabled:=ec and ActCodeEditor.HasSelection;
    mEditCopy.Enabled:=ec and ActCodeEditor.HasSelection;
    mEditCopyHtml.Enabled:=ec and ActCodeEditor.HasSelection;
    mEditPaste.Enabled:=ec and ClipboardCanPasted;
    mEditDelete.Enabled:=ec and not ActCodeEditor.ConsoleMode and ActCodeEditor.HasSelection;
    mEditSelectAll.Enabled:=ec;

    mSearchFind.Enabled:=e;
    mSearchReplace.Enabled:=e;
    mSearchSearchAgain.Enabled:=e and(LastFindCommand.Operation<>opNone); //based on lastsearch
    mSearchGoToLineNumber.Enabled:=e;

    bFindNext.Enabled:=e and(cbFind.Text<>'');
    bReplace.Enabled:=bFindNext.Enabled;
    bReplaceAll.Enabled:=bFindNext.Enabled;

    mCompileCompile.Enabled:=e;
    mRunRun.Enabled:=e;

    mHelpHelpAtCursor.Enabled:=e and
      ((ActiveControl is TCodeEditor)or(ActiveControl is TRichEdit));
  end;
end;

const
  sbInsOvr=0;
  sbLineCol=1;
  sbStatus=2;

procedure TFrmMain.UpdateStatusbar;
begin
  if ActEditor=nil then begin
    StatusBar.Panels[sbLineCol].Text:='';
    StatusBar.Panels[sbInsOvr].Text:='';
  end else with ActEditor.Editor do begin
    with CursorPos do StatusBar.Panels[sbLineCol].Text:=format('%d:%d',[Y+1,X+1]);
    StatusBar.Panels[sbInsOvr].Text:=switch(Overwrite,'Ovr','Ins');
  end;
end;

procedure TFrmMain.WMEraseBkGnd(var Message: TMessage);
begin
  Message.Result:=1;
end;

function TFrmMain.GetStatus: ansistring;
begin
  result:=StatusBar.Panels[sbStatus].Text;
end;

function TFrmMain.GetWindowPlacement2: ansistring;
begin
  result:=GetWindowPlacement;
end;

procedure TFrmMain.SetStatus(const Value: ansistring);
begin
  StatusBar.Panels[sbStatus].Style:=psOwnerDraw;
  StatusBar.Panels[sbStatus].Text:=Value;
end;

procedure HighlightText(canvas:TCanvas; Rect:TRect; text, word:ansistring; clFont, clBrush:TColor);
var errPos:integer;
    r:trect;
begin with Canvas do begin
  errPos:=pos(word, text);
  if errPos>0 then begin
    Font.Color:=clFont;
    Brush.Style:=bsSolid;
    Brush.Color:=clBrush;

    r:=Rect;
    inc(r.Left, TextWidth(copy(text, 1, errPos-1)));
    r.Right:=r.Left+TextWidth(word);

    TextRect(r, r.Left, r.Top, word);
  end;
end;end;

procedure TFrmMain.StatusBarDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
var s:ansistring;
begin with StatusBar.Canvas do begin
  s:=ListItem(Panel.Text, 0, #10);
  if s<>trimf(Panel.Text) then s:=s+' ...';

  Font.Color:=clBlack;
  Brush.Style:=bsClear;
  TextRect(Rect, rect.Left, rect.Top, s);

  HighLightDMDLine(StatusBar.Canvas, Rect, s);
end;end;

procedure TFrmMain.ClearErrorLine;
var i:integer;
begin
  for i:=0 to EditorCount-1 do Editor[i].Editor.ClearErrorLine;
end;

procedure TFrmMain.SetErrorLine(fn:string; line:integer; errortype:TErrorType);
var ed:TEditorSheet;
begin
  ClearErrorLine;

  ed:=GetEditor(fn);
  if ed=nil then begin //try to open it. TODO: searchpaths
    if FileExists(fn)then OpenFile(fn);
    ed:=GetEditor(fn);
  end;

  if ed<>nil then begin
    ActEditor:=ed;
    ed.Editor.SetErrorLine(line,0,errorType, 8);
  end;
end;

procedure TFrmMain.SetWindowPlacement2(const Value: ansistring);
begin
  SetWindowPlacement(Value);
end;

function TFrmMain.NewEditor:TEditorSheet;
var ts:TEditorSheet;
    ed:TCodeEditor;
begin
  ts:=TEditorSheet.Create(Self);result:=ts;
  ts.PageControl:=pcEditor;
  ed:=TCodeEditor.Create(ts);
  ed.SyntaxEnabled:=true;
  ts.Editor:=ed;
  ed.Parent:=ts;
  ed.Align:=alClient;

  ed.OnSyntax:=OnSyntax;

  ts.Editor.FileOps.ExternalOpenDialog:=OpenDialog1;
  ts.Editor.FileOps.ExternalSaveDialog:=SaveDialog1;

  ed.OnFileDrop:=HandleDropFiles;
end;

procedure TFrmMain.NewFile;
  function NewName:string;
  var i,n:integer;
  begin
    n:=-1;
    for i:=0 to EditorCount-1 do if iswild2('noname??.'+OnGetFileExt,Editor[i].Editor.FileOps.FileName)then
      n:=max(n,strtointdef(copy(Editor[i].Editor.FileOps.FileName,7,2),-1));
    inc(n);
    result:=format('noname%.2d.'+OnGetFileExt,[n]);
  end;
begin
  ActEditor:=NewEditor;
  ActEditor.Editor.FileOps.New(NewName);
end;

procedure TFrmMain.TogglePotiClick(Sender: TObject);
begin
  FrmPoti.visible:=not FrmPoti.visible;
end;

procedure TFrmMain.mFileNewClick(Sender: TObject);
begin
  NewFile;
end;

procedure TFrmMain.OpenFile(const fn:AnsiString);//fn='' -> noname
var ed:TEditorSheet;
begin
  if not FileExists(fn) then exit;

  //already open?
  ed:=Editor[fn];

  //unchanged noname
  if ed=nil then begin
    if(ActEditor<>nil)and(ActEditor.IsNewAndUnchanged)then ed:=ActEditor else ed:=NewEditor;
    ed.Editor.FileOps.DoOpen(fn);
  end;

  ActEditor:=ed;
end;

procedure TFrmMain.HandleDropFiles(files:TArray<string>);
var fn:string;
begin
  for fn in files do OpenFile(fn);
end;

procedure TFrmMain.pbDebugLedsPaint(Sender: TObject);
begin with pbDebugLeds, canvas do begin
  SetBrush(bsSolid, clBtnFace*0);
  fillrect(ClientRect);
  DebugLogServer.draw(Canvas, ClientRect);
end;end;

procedure TFrmMain.pcEditorDrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const Rect: TRect; Active: Boolean);
var s:string;
    e:TEditorSheet;
begin
  with (Control as TPageControl).Canvas do begin
    if Active then begin
      Brush.Color:= clHighlight;
      Font.Color:=clHighlightText;
    end else begin
      Brush.Color:= clBtnFace;
      Font.Color:=clBtnText;
    end;

    e:=Editor[TabIndex];
    if isMainSource(e.Editor.code) then begin
      Font.Style:=[fsUnderline];
    end else begin
      Font.Style:=[];
    end;

    Font.Color:=switch(e.errorCount>0, clRed, clBtnText);

    with Editor[TabIndex].Editor.FileOps do begin
      s:=extractFileName(FileName);
      if(isChanged) then s:='*'+s;
    end;
    TextRect(Rect, (Rect.Left+Rect.Right-textWidth(s))div 2, (Rect.Top+Rect.Bottom-TexTheight(s))div 2+1, s);
  end;
end;

procedure TFrmMain.mFileOpenClick(Sender: TObject);
var fn:string;
begin
  OpenDialog1.Options:=OpenDialog1.Options+[ofAllowMultiSelect];
  if OpenDialog1.Execute then
    for fn in OpenDialog1.Files do
      OpenFile(fn);
end;

procedure TFrmMain.mFileReopenClearClick(Sender: TObject);
begin
  ReopenHistory:='';
end;

procedure TFrmMain.mFileSaveClick(Sender: TObject);
begin
  ActEditor.Editor.FileOps.Save;
end;

procedure TFrmMain.mFileSaveAsClick(Sender: TObject);
begin
  ActEditor.Editor.FileOps.SaveAs;
end;

procedure TFrmMain.mFileSaveAllClick(Sender: TObject);
var i:integer;
begin
  for i:=0 to EditorCount-1 do with Editor[i].Editor.FileOps do
    if ischanged and not Save then break;
end;

procedure TFrmMain.mFileCloseClick(Sender: TObject);
begin
  ActEditor.Free;
end;

procedure TFrmMain.mFileCloseAllClick(Sender: TObject);
var i:integer;
begin
  for i:=EditorCount-1 downto 0 do with Editor[i] do begin
    with Editor.FileOps do if ischanged and not Save then break;
    Free;
  end;
end;

procedure TFrmMain.mEditUndoClick(Sender: TObject);
begin
  ActCodeEditor.Undo;
end;

procedure TFrmMain.mEditRedoClick(Sender: TObject);
begin
  ActCodeEditor.Redo;
end;

procedure TFrmMain.mEditCutClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecCut);
end;

procedure TFrmMain.mEditCopyClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecCopy);
end;

procedure TFrmMain.mEditCopyHtmlClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecCopyHtml);
end;

procedure TFrmMain.mEditPasteClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecPaste);
end;

procedure TFrmMain.mEditDeleteClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecDelete);
end;

procedure TFrmMain.mEditSelectAllClick(Sender: TObject);
begin
  ActCodeEditor.ExecuteCommand(ecSelectAll);
end;

procedure TFrmMain.mRemoveAllMarkersClick(Sender: TObject);
var i:integer;
begin
  for i:=0 to EditorCount-1 do
    Editor[i].Editor.removeAllDebugMarkers;
end;

////////////////////////////////////////////////////////////////////////////////
/// Find/Replace                                                             ///
////////////////////////////////////////////////////////////////////////////////

function TFrmMain.GetFindWindowState: integer;
begin
  if pFindReplace.Visible then
    if cbReplace.Visible then result:=2
                         else result:=1
  else result:=0;
end;

procedure TFrmMain.SetFindWindowState(const Value: integer);
var v:integer;
    cb:TComboBoxEx;
    b:Boolean;
begin
  v:=EnsureRange(Value,0,2);
  if v=FindWindowState then exit;

  case v of
    1:cb:=cbFind;
    2:cb:=cbReplace;
  else cb:=nil end;

  if cb<>nil then with cb do pFindReplace.Height:=cb.Top+cb.Height+3;

  b:=v=2; //hide replace stuff
  cbReplace.Visible:=b;
  bReplace.Visible:=b;
  bReplaceAll.Visible:=b;
  chPromptOnReplace.Visible:=b;

  pFindReplace.Visible:=cb<>nil;
end;

procedure TFrmMain.mSearchFindClick(Sender: TObject);
begin
  FindWindowState:=1;cbFind.SetFocus;
end;

procedure TFrmMain.mSearchGotoLineNumberClick(Sender: TObject);
var e:TCodeEditor;
    s:string;
    cp:TPoint;
begin
  if ActCodeEditor=nil then exit;
  e:=ActEditor.Editor;

  cp:=e.CursorPos;
  s:=toStr(cp.y+1);
  if not InputQuery('Goto Line', 'Enter Line Number', s)then exit;
  cp.Y:=StrToIntDef(s, 0)-1;
  if cp.y<0 then exit;

  cp.Y:=EnsureRange(cp.Y, 0, e.LineCount);
  e.ShowLine(cp.y, cp.x, 8);
end;

procedure TFrmMain.mSearchReplaceClick(Sender: TObject);
begin
  FindWindowState:=2;cbFind.SetFocus;
end;

procedure TFrmMain.cbFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if(Key=VK_ESCAPE)and(Shift=[])then begin Key:=0;bFindClose.Click;exit end;
  if(Key=VK_RETURN)and(Shift=[])then begin
    if(Sender=cbFind)or(Sender=chCaseSensitive)or(Sender=chWholeWords)or(Sender=chBackwards)then begin
      Key:=0;bFindNext.Click;
    end else if(Sender=cbReplace)or(Sender=chPromptOnReplace)then begin
      Key:=0;bReplace.Click;
    end;
  end;
end;

procedure TFrmMain.cFindCloseClick(Sender: TObject);
begin
  FindWindowState:=0;
  if ActEditor<>nil then begin
    ActEditor.Editor.ResetFoundText;
    ActEditor.Editor.SetFocus;
  end;
end;

procedure TFrmMain.FindCommandPrepareFromUi(var fc: TFindCommand;const op: TFindOperation);
begin with fc do begin
  Operation:=op;
  FindText:=cbFind.Text;
  ReplaceWith:=cbReplace.Text;
  CaseSensitive:=chCaseSensitive.Checked;
  WholeWords:=chWholeWords.Checked;
  Backwards:=chBackwards.Checked;
  PromptOnReplace:=chPromptOnReplace.Checked;
end;end;

procedure TFrmMain.FindCommandExecute(const fc: TFindCommand);
var e:TCodeEditor;

  procedure setCursorPos(p:TPoint);
  begin
    e.ShowLine(p.Y, p.X, 8);
  end;

  function GoNext:boolean;//moves cursor if can

    function GoForwards:boolean;
    var i,cr:integer;
    begin
      cr:=e.xy2pos(e.CursorPos,false);
      for i:=0 to length(e.FFoundTextPositions)-1 do
        if cr<=e.FFoundTextPositions[i]-1 then begin
          setCursorPos(e.pos2xy(e.FFoundTextPositions[i]+e.FFoundTextLen-1));
          exit(true);
        end;
      result:=false;
    end;

    function GoBackwards:boolean;
    var i,cr:integer;
    begin
      cr:=e.xy2pos(e.CursorPos,false);
      for i:=length(e.FFoundTextPositions)-1 downto 0 do
        if cr>=e.FFoundTextPositions[i]+e.FFoundTextLen-1 then begin
          setCursorPos(e.pos2xy(e.FFoundTextPositions[i]-1));
          exit(true);
        end;
      result:=false;
    end;

  begin
    if fc.Backwards then result:=GoBackwards
                    else result:=GoForwards;
  end;


  function FindOccurences:boolean;//talalt-e valamit
  var st,en,i:integer;
      Options:TPosOptions;
      tmp:TArray<integer>;
      r:trect;
  begin
    Options:=[];
    if not fc.CaseSensitive then Options:=Options+[poIgnoreCase];
    if fc.WholeWords then Options:=Options+[poWholeWords];

    if e.HasSelection then begin
      st:=e.xy2pos(e.SelStart,true)+1;    //1 based
      en:=e.xy2pos(e.SelEnd,true);        //1 based, inclusive
    end else begin
      st:=1;
      en:=Length(e.Code);
    end;

    e.FFoundTextPositions:=PosMulti(fc.FindText,e.Code,Options,st,en);
    e.FFoundTextLen:=length(fc.FindText);
    e.FFoundTextBackwards:=fc.Backwards;
    e.Invalidate;

    //restrict selection if blockselect
    if e.HasSelection and e.BlockSelect then begin
      r:=e.BlockSelectionRect;r.Right:=r.Right-e.FFoundTextLen+2;
      for i:=0 to length(e.FFoundTextPositions)-1 do
        if PtInRect(r,e.pos2xy(e.FFoundTextPositions[i]-1))then begin
          SetLength(tmp,length(tmp)+1);
          tmp[length(tmp)-1]:=e.FFoundTextPositions[i];
        end;
      e.FFoundTextPositions:=tmp;
    end;

    result:=e.FFoundTextPositions<>nil;
    if not result then e.ResetFoundText;
  end;

  function DoWarpedFind(const AllowWarp:boolean=false):Boolean;
  begin
    result:=GoNext;
    if not result and(AllowWarp or(MessageBox('Restart search from the '+switch(fc.Backwards,'end','begining')+' of '+switch(e.HasSelection,'selection','file')+'?','Search match not found',MB_ICONQUESTION+MB_YESNO)=IDYES))then begin
      setCursorPos(e.pos2xy(switch(fc.Backwards,length(e.Code),0)));
      result:=GoNext;
    end;
  end;

  function DoReplace(const AskQuestions:boolean=false):boolean;//kurzor pozicio alapjan
  var cr,diff,i,j:Integer;
      ignoreThis:boolean;
  begin
    cr:=e.xy2pos(e.CursorPos,false);
    diff:=length(fc.ReplaceWith)-e.FFoundTextLen;

    ignoreThis:=false;
    if AskQuestions then begin
      case MessageBox('Replace this occurrence of '''+fc.FindText+'''?','Confirm',MB_YESNOCANCEL+MB_ICONQUESTION)of
        ID_NO:ignoreThis:=true;
        IDCANCEL:exit(false);
      end;
    end;

    if not ignoreThis then begin
      if not fc.Backwards then cr:=cr-e.FFoundTextLen;//kurzor az elejere

      e.ModifyCode(cr,e.FFoundTextLen,fc.ReplaceWith);//replace text

//      TODO: XY messagebox pozicionalas, find/replace comboboxok historyja+config
      //adjust FFoundTextPositions buffer
      i:=0;while i<length(e.FFoundTextPositions)do case cmp(e.FFoundTextPositions[i],cr+1)of
        0:{del}begin for j:=i to length(e.FFoundTextPositions)-2 do e.FFoundTextPositions[j]:=e.FFoundTextPositions[j+1];setlength(e.FFoundTextPositions,length(e.FFoundTextPositions)-1) end;
        1:{diff}begin inc(e.FFoundTextPositions[i],diff);inc(i);end;
      else inc(i);end;

      if not fc.Backwards then cr:=cr+length(fc.ReplaceWith);//kurzor a vegere

      setCursorPos(e.pos2xy(cr));
    end;

    result:=true;
  end;

begin
  if fc.FindText='' then exit;
  if ActEditor=nil then exit;
  e:=ActEditor.Editor;if e=nil then exit;
  if fc.Operation=opNone then exit;

  if not FindOccurences then begin
    MessageBox('Search string '''+String(fc.FindText)+''' not found.','Information',MB_ICONINFORMATION+MB_OK);
    exit;
  end;

  case fc.Operation of
    opFind:DoWarpedFind;
    opReplace:begin
      if DoWarpedFind then
        DoReplace;
    end;
    opReplaceAll:begin
      while(e.FFoundTextPositions<>nil)and DoWarpedFind(not fc.PromptOnReplace)and DoReplace(fc.PromptOnReplace) do;
    end;
  end;
end;

procedure TFrmMain.bFindNextClick(Sender: TObject);
begin
  if(ActEditor=nil)or(cbFind.Text='')then exit;
  FindCommandPrepareFromUi(LastFindCommand,opFind);
  FindCommandExecute(LastFindCommand);
end;

procedure TFrmMain.bReplaceClick(Sender: TObject);
begin
  FindCommandPrepareFromUi(LastFindCommand,opReplace);
  FindCommandExecute(LastFindCommand);
end;

procedure TFrmMain.bReplaceAllClick(Sender: TObject);
begin
  FindCommandPrepareFromUi(LastFindCommand,opReplaceAll);
  FindCommandExecute(LastFindCommand);
end;

procedure TFrmMain.mSearchSearchAgainClick(Sender: TObject);
begin
  FindCommandExecute(LastFindCommand);
end;


////////////////////////////////////////////////////////////////////////////////
/// Syntax/CodeInsight                                                       ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmMain.JumpToDeclaration;
var fn:string;
    s,ActWord:AnsiString;
    e,e2:TCodeEditor;
    ofs:integer;
    p:TPoint;
begin
  if ActEditor=nil then exit;
  e:=ActEditor.Editor;

  ActWord:=e.LineAtCursor;  //sor
  ActWord:=WordAt(ActWord, e.CursorPos.X+1);

  fn:=ExtractFilePath(e.FileOps.FileName)+Replacef('.','\',ActWord,[roAll])+'.d';
  if FileExists(fn)then begin //navigate to module
    OpenFile(fn);
  end else begin //try to search the declaration
    ofs:=e.xy2pos(e.CursorPos, false);
    s:=DCDQuery('-l -c'+toStr(ofs)+' "'+e.FileOps.FileName+'"', ExtractFilePath(e.FileOps.FileName));

    fn:=ListItem(s,0,#9);
    if fn='stdin' then fn:=e.FileOps.FileName; //this is the current file

    ofs:=StrToIntDef(ListItem(s,1,#9),0);
    if FileExists(fn)then begin
      OpenFile(fn);
      e2:=ActEditor.Editor;
      p:=e2.pos2xy(ofs);
      if e2=e then begin
        ActiveControl:=nil;
        e2.SetFocus;
      end;
      e2.CursorPos:=p;               //no conflict because
    end;
  end;
end;

procedure TFrmMain.lbCompileOutputClick(Sender: TObject);
begin
//
end;

procedure TFrmMain.lbCompileOutputDblClick(Sender: TObject);
begin
  with lbCompileOutput do if ItemIndex>=0 then
    GotoError(Items[ItemIndex]);
end;

type
  TErrorInfo=record
    valid:boolean;
    typ:TErrorType;
    filename:ansistring;
    line, column:integer;
    error:ansistring;
    msg:ansistring;
  end;


function decodeErrorMsg(msg:ansistring):TErrorInfo;
var et:TErrorType;
var sLine, sColumn:ansistring;
begin
  msg:=listitem(msg, 0, #10); //first line only
  for et:=low(TErrorType) to high(TErrorType)do begin
    if IsWild2('*(*,*): '+ErrorTitle[et]+':*', msg, result.fileName, sLine, sColumn, result.msg)then begin
      result.typ:=et;
      result.line  :=StrToIntDef(sLine,   -1);
      result.column:=StrToIntDef(sColumn, -1);
      result.valid:=fileExists(result.filename);
      exit;
    end;
    if IsWild2('*(*,*):   *', msg, result.fileName, sLine, sColumn, result.msg)then begin
      result.typ:=etError;
      result.line  :=StrToIntDef(sLine,   -1);
      result.column:=StrToIntDef(sColumn, -1);
      result.msg := TrimLeft(result.msg);
      result.valid:=fileExists(result.filename);
      exit;
    end;
  end;
  result.valid:=false;
end;

procedure TfrmMain.HighLightDMDLine(Canvas:TCanvas; rect:TRect; s:ansistring);
begin
  with decodeErrorMsg(s)do begin
    if valid then
      HighlightText(Canvas, Rect, s, errorTitle[typ], clErrorFont[typ], clErrorBk[typ]);
  end;
end;

procedure TFrmMain.lbCompileOutputDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var s:string;

  function isTodoOpt:boolean;
  begin
    result:=isWild2('*(*): Todo:*', s)
         or isWild2('*(*): Opt:*', s);
  end;

begin with TListBox(Control), Canvas do begin
  s:=Items[Index];

  //ne irja ki a full path-ot! -> update: ez nem jo, noveli a felreerthetoseget!
  //path:=extractFilePath(MainFileName);
  //if BeginsWith(s, path, false)then delete(s, 1, length(path));

  Font.Color:=switch(isTodoOpt, $686868, clBlack);
  Brush.Style:=bsSolid;
  TextRect(Rect, rect.Left+2, rect.Top+2, s);

  HighLightDMDLine(Canvas, Rect, s);
end;end;

procedure TFrmMain.lbCompileOutputKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var s:ansistring;
begin with lbCompileOutput do begin
  if(Shift=[ssCtrl])and((Key=ord('C'))or(Key=VK_Insert))then begin //put error onto clipboard
    if inRange(ItemIndex, 0, Items.count)then begin
      s:=Items[ItemIndex];
      with decodeErrorMsg(s) do if valid then Clipboard.AsText:=error
                                         else Clipboard.AsText:=s;
    end;
  end;
end;end;

procedure TFrmMain.lbLogData(Control: TWinControl; Index: Integer; var Data:string);
begin
  Data:=DebugLogServer.getLogStr(Index);
end;


{procedure testMarkAllTokens(e:TCodeEditor);
var i,ss:integer;
//    sk:TSyntaxKind;
    th:TTokenHighlight;

begin with e do begin
  e.markers:=nil;
  ss:=0;
  for i:=0 to length(Code)-1 do begin
//    sk:=getSyntaxAt(i);
    th:=getTokenHighlightAt(i);
    if th.isTokenBegin then ss:=i;
    if th.isTokenEnd   then begin
      addMarker(ss, i+1, th.nestingLevel, 'test', false);
    end;

  end;
  invalidate;

end;end;}

procedure TFrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var e:TCodeEditor;
begin
  if(ActEditor<>nil)and(ActiveControl=ActEditor.Editor)then begin
    e:=ActEditor.Editor;

    if(Key=VK_SPACE)and(Shift=[ssCtrl])then begin //start codeInsight
      Key:=0;
      FrmCodeInsight.StartInsight(e);
    end;

    if(Key=VK_RETURN)and(Shift=[ssCtrl])then begin //goto file
      Key:=0;
      JumpToDeclaration;
    end;

    if(Shift=[ssCtrl])and(Key=ord('W'))then begin
{      ss:=e.xy2pos(e.selStart, true);
      se:=e.xy2pos(e.SelEnd, true);
      if ss=se then begin ss:=e.xy2pos(e.CursorPos, true); se:=ss; end;

      m.selStart:=ss;
      m.selEnd  :=se;
      e.addMarker(m);}

//      testMarkAllTokens(e);

      e.Invalidate;
    end;

  end;
end;

procedure TFrmMain.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key='.' then if(ActiveControl<>nil)and(ActiveControl is TCodeEditor)then
    FrmCodeInsight.ShowDotCompletionAgain:=true;
end;

////////////////////////////////////////////////////////////////////////////////
/// Compile/Run                                                              ///
////////////////////////////////////////////////////////////////////////////////

procedure TFrmMain.markErronousFiles(hdmdErr:ansistring);
var s, fn:ansistring;
    i:integer;
    e:TEditorSheet;
begin
  for i:=0 to EditorCount-1 do Editor[i].errorCount:=0;
  for s in listSplit(hdmdErr, #10)do with decodeErrorMsg(s)do begin
    if valid and (typ in [etError, etWarning, etDeprecation])then begin
      e:=Editor[fn];
      if e<>nil then inc(e.errorCount);
    end;
  end;
  pcEditor.Invalidate;
end;

function TFrmMain.processErrorMessages(src:ansistring):ansistring;
begin
  //everything is done by HDMD
  result:=src;
end;

procedure TFrmMain.SetEditorCursor(hourglass:boolean);
var cr:TCursor;
    i:integer;
begin
  if hourglass then cr:=crHourGlass
               else cr:=crIBeam;
  for i:=0 to EditorCount-1 do Editor[i].Editor.Cursor:=cr;
end;

var hdmdOut, hdmdErr:ansistring; //ganyolas
procedure hdmd(fileName:string; doRun, doRebuild:boolean); forward;

procedure TFrmMain.CompileAndRun(doRun, doRebuild:boolean);

  procedure DoCompile;
  begin
    if isMainSource(ActEditor.Editor.code) then
      mainFileName:=ActCodeEditor.FileOps.FileName;

  end;

  function SearchForAProject:string;
  var i:integer;
  begin
    result:='';
    if actEditor=nil then exit;
    //search back
    for i:=actEditor.TabIndex-1 downto 0 do if isMainSource(editor[i].Editor.code)then
      exit(editor[i].Editor.fileOps.FileName);
    //search fwd
    if MainFileName='' then for i:=actEditor.TabIndex+1 to EditorCount-1 do if isMainSource(editor[i].Editor.code)then
      exit(editor[i].Editor.fileOps.FileName);
  end;

var dt:TDeltaTime;
    i,j:integer;
    s:string;
    ignoreLastException:boolean;
begin
  ignoreLastException := false;
  try
    //todo: check if it runs at all
    ShellExecute(Handle, 'open', Pchar('C:\Windows\System32\schtasks.exe'), PChar('/RUN /TN "My\hldc"'), '', SW_HIDE);
  finally
  end;

  try
    GotoError(''); //clear error display
    Status:='...'; StatusBar.Repaint;
    SetEditorCursor(true);
    dt.Start;
    pcRight.ActivePage:=tsCompile; //todo: immediate feedback
    lbCompileOutput.Clear;
    lbCompileOutput.Items.Add('Compiling...');
    lbCompileOutput.repaint;
    try

      //select project by ActiveEditor
      if isMainSource(ActEditor.Editor.code) then
        MainFileName:=ActCodeEditor.FileOps.FileName;

      //searc a project on the tabs
      if(MainFileName='')then
        MainFileName:=searchForAProject;

      mFileSaveAllClick(nil); //Save All

      //compile/run
      if fileExists(MainFileName)then begin
        DebugLogServer.resetBeforeRun;
        hdmd(MainFileName, doRun, doRebuild);
      end else begin
        hdmdOut:='';
        hdmdErr:=ActCodeEditor.FileOps.FileName+'(1,1): Error: Can''t compile project. It has no project header. ( //@exe or //@dll )'#13#10;
      end;

    finally
      dt.Update;
      SetEditorCursor(false);
      lbCompileOutput.Items.Text:=hdmdOut+#13#10+processErrorMessages(hdmdErr);

      markErronousFiles(hdmdErr);

      //jump to the first error
      i:=listCount(hdmdOut, #10);
      if hdmdOut='' then inc(i);

      //220412: only jump on "Error:" lines
      for j := i to lbCompileOutput.Items.Count-1 do begin
        s := lbCompileOutput.Items.Strings[j];
        if (pos('Error:', s, [poIgnoreCase])>0) and (s<>'Error: Process has been killed.') then begin
          i := j;
          break;
        end;
      end;

      if lbCompileOutput.Items.Count>0 then lbCompileOutput.ItemIndex:=lbCompileOutput.Items.Count-1;
      if lbCompileOutput.Items.Count>0 then lbCompileOutput.ItemIndex:=i;

      //goto error if can
      if(i>=0)and(i<lbCompileOutput.items.Count)then begin
        s := lbCompileOutput.Items.Strings[i];
        GotoError(s);
        ignoreLastException := true;
      end;
    end;
    Status:='Compiled in: '+dt.SecStr+' seconds';
  except
    on e:exception do begin
      if not ignoreLastException then GotoError(e.Message);
    end;
  end;
end;

procedure TFrmMain.mCompileBuildClick(Sender: TObject);begin CompileAndRun(false, true);end;
procedure TFrmMain.mCompileCompileClick(Sender: TObject);begin CompileAndRun(false, false);end;
procedure TFrmMain.mRunRunClick(Sender: TObject);begin
  if exeIsWaiting then begin
    DebugLogServer.data.dide_ack:=1;
    SetForegroundWindow(DebugLogServer.data.exe_hwnd);
  end else begin
    CompileAndRun(true, false);
  end;
end;

procedure TFrmMain.mRunProgramResetClick(Sender: TObject);
begin
  DebugLogServer.data.dide_ack:=-1;
  DebugLogServer.data.force_exit:=1;
  DebugLogServer.data.exe_waiting:=0; //220429: This is needed when the exe is dead. It resets the IDE *break* state.
end;

procedure TFrmMain.mDebugModeToggleClick(Sender: TObject);
begin
  DebugMode:=not DebugMode;
end;

////////////////////////////////////////////////////////////////////////////////
/// DIDE specific functions                                                  ///
////////////////////////////////////////////////////////////////////////////////

function TFrmMain.OnGetFileExt: ansistring;
begin
  result:='d';
end;

function TFrmMain.DCDQuery(cmd, path:string):ansistring;
var oldDir:string;
const fnRes='$dcd.res';
      fnBat='$dcd.bat';
begin
  oldDir:=GetCurrentDir;
  SetCurrentDir(path);

  DeleteFile(fnRes);
  TFile(fnBat).Write('dcd-client.exe '+ansistring(cmd)+' >'+fnRes);
  exec(fnBat, '', true);
  result:=TFile(fnRes);
  DeleteFile(fnRes); DeleteFile(fnBat);

  SetCurrentDir(oldDir);
end;

function TFrmMain.OnGetWordList(const Editor: TCodeEditor): TArray<ansistring>;
var fn,path:string;
    s,line:AnsiString;
    i,ofs:integer;
    a:TArray<ansistring>;
    cp:TPoint;

begin
  setlength(result,0);

  if Editor.FileOps.isChanged then Editor.FileOps.Save;

  path:=ExtractFilePath(Editor.FileOps.FileName);
  fn  :=extractFileName(Editor.FileOps.FileName);

  //adjust cpos: go back to the start of the word (on letter or a point)
  cp:=Editor.CursorPos;
  line:=Editor.Line[cp.y];
  while(cp.X>1)and(CharN(line, cp.X  )in['0'..'9','a'..'z','A'..'Z','_'    ])
               and(CharN(line, cp.X-1)in['0'..'9','a'..'z','A'..'Z','_','.'])do dec(cp.X);
  ofs:=Editor.xy2pos(cp, false);

  s:=DCDQuery('-I'+path+' -c'+toStr(ofs)+' "'+fn+'"', path);

  a:=ListSplit(s,#10);
  if a<>nil then begin
    if a[0]='identifiers' then begin
      for i:=1 to high(a)do begin
        setlength(result, length(result)+1);
        result[high(result)]:=listitem(a[i],0,#9);
      end;
    end;
  end;
end;

procedure HighLightCompilerDirective(const ASrc:ansistring;var ADst:ansistring); //todo: in D
var st:integer;
begin
  st:=1;
  while true do begin
    st:=pos('//@', ASrc, [], st);
    if st<=0 then break;
    if(st>1)and not(ASrc[st-1]in[#10, #13])then begin inc(st); Continue; end; //only a beginning of line
    repeat
      ADst[st]:=#10;
      inc(st);
    until ASrc[st]in [#10, #13, #0];
  end;
end;

procedure HighLightBinaryLiteral1(const ASrc:ansistring;var ADst:ansistring); //todo: in D
var st:integer;
begin
  st:=1;
  while true do begin
    st:=pos('0b', ASrc, [], st);
    if st<=0 then break;

    inc(st);
    while ADst[st]=#5 do begin //skNumbers only
      if ASrc[st]='1' then ADst[st]:=#21; //skBinary1
      inc(st);
    end;
  end;
end;


procedure dlang_syntaxHighLight(text, res:PAnsiChar; hierarchy:PWord; bigComments:PAnsiChar; bigCommentsLen:integer); stdcall; external 'dsyntax.dll' name '_syntaxHighLight@20';

function call_hdmd(argv:PPAnsiChar; argc:integer; sOut:PAnsiChar; sOutLen:integer; sErr:PAnsiChar; sErrLen:integer):integer; stdcall; external 'dsyntax.dll' name '_callHDMD@24';

function call_hldc(cmd:array of ansistring; out sOut, sErr:ansistring):integer;
var cmdPath, cmdLine, s:ansistring;
    cmdFile, outFile, errFile: TFile;
    i:integer;
begin
  cmdPath := 'z:\temp\';
  cmdFile := TFile(cmdPath+'hldc_cmd.txt');
  outFile := TFile(cmdPath+'hldc_out.txt');
  errFile := TFile(cmdPath+'hldc_err.txt');

  cmdLine := '';
  for i:=0 to high(cmd) do begin
    s := cmd[i];
    if pos(' ', s)>0 then s := '"'+s+'"';
    listAppend(cmdLine, cmd[i], ' ');
  end;

  cmdFile.Write(cmdLine);
  while true do begin
    Sleep(50);
    if not FileExists(cmdFile.FullName) then break;
    if GetKeyState(VK_ESCAPE)<0 then beep;
  end;

  sOut := outFile.read;
  sErr := errFile.read;
  result:=switch(sErr='', 0, 1);
end;

procedure hdmd(fileName:string; doRun, doRebuild:boolean);
var cmd:array of ansistring;
    sOut, sErr:ansistring;
    code:integer;

  procedure addOpt(s:ansiString); begin if(s<>'') then begin setlength(cmd, length(cmd)+1); cmd[high(cmd)]:=s; end;end;

  function stripEscapes(s:ansistring):ansistring;
  var ch:ansichar;
      block:bool;
  begin
    result:=''; block:=false;
    for ch in s do begin
      if block then begin
        block:=false;
      end else begin
        if ch=#27 then block:=true
                  else result:=result+ch;
      end;
    end;
  end;

var mainDir, oldDir:string;
begin
  mainDir:=ExtractFileDir(FileName);
  oldDir:=getCurrentDir;
  chDir(mainDir);
  try
    addopt('HLDC');
    addopt(fileName);
//  addopt('--o=-w'); //treat warnings as errors
    addopt('--todo');
    addopt('--map');
    addopt('--kill');
    if not doRun then addopt('-c');
    if doRebuild then addopt('-r');

(*    setlength(sOut, $20000); sOut[1]:=#0;
    setlength(sErr, $10000); sErr[1]:=#0;
    code:=call_hdmd(PPAnsiChar(cmd), length(cmd), PAnsiChar(sOut), length(sOut),
                                                  PAnsiChar(sErr), length(sErr));
    sOut:=stripEscapes(PAnsiChar(sOut));
    sErr:=stripEscapes(PAnsiChar(sErr)); *)

    code:=call_hldc(cmd, sOut, sErr);

    hdmdOut:=sOut; hdmdErr:=sErr;

    if code<>0 then begin
//      MessageBox(sOut+sErr, 'HDMD Error', MB_ICONERROR + MB_OK);
      raise Exception.Create(sErr); //sends the error to the IDE
    end else begin
      //MessageBox(sOut, 'HDMD Success', MB_ICONINFORMATION + MB_OK);
    end;
  finally
    chDir(oldDir);
  end;
end;

procedure TFrmMain.GotoError(msg:ansistring);
var e:TEditorSheet;
    i:integer;
begin
  Status:=msg;

  with decodeErrorMsg(msg)do if valid then begin
    OpenFile(fileName);
    e:=Editor[fileName];
    if e=nil then exit;
    ActEditor:=e;

    e.Editor.SetErrorLine(line-1   , column-1, typ, 8);
  end else begin
    for i:=0 to EditorCount-1 do
      Editor[i].Editor.ClearErrorLine;
  end;
end;

procedure TFrmMain.OnSyntax;
begin
  SetLength(ASyntaxHighlight, length(ASrc));
  SetLength(ATokenHighlight, length(ASrc)*2);

//  perfStart('syntax');
  dlang_syntaxHighLight(pointer(ASrc), pointer(ASyntaxHighlight), pointer(ATokenHighlight), bigComments, bigCommentsLen);
//  caption:=perfReport;

  //extras
  HighLightCompilerDirective(ASrc, ASyntaxHighlight);
  HighLightBinaryLiteral1(Asrc, ASyntaxHighlight);
end;


function TFrmMain.isMainSource(const code:ansistring):boolean;
const prefixes:array[0..1]of ansistring = ('exe', 'dll');
var s, p:ansistring;
    i:integer;
begin
  s:=copy(code, 1, 1000);
  for p in prefixes do begin
    i:=pos('//@'+p, s, [poIgnoreCase, poWholeWords]);
    if(i=1)or(i>1)and(s[i-1]in[#10,#13]) then exit(true);
  end;
  result:=false;
end;


////////////////////////////////////////////////////////////////////////////////
/// Debug stuff                                                              ///
////////////////////////////////////////////////////////////////////////////////

constructor TDebugLogServer.create;
begin
  dataSize:=$11000;
  dataFile:=CreateFileMapping(
                 INVALID_HANDLE_VALUE,    // use paging file
                 nil,                     // default security
                 PAGE_READWRITE,          // read/write access
                 0,                       // maximum object size (high-order DWORD)
                 dataSize,                // maximum object size (low-order DWORD)
                 dataFileName);           // name of mapping object

  data:=MapViewOfFile(dataFile,             // handle to map object
                        FILE_MAP_ALL_ACCESS,   // read/write permission
                        0,
                        0,
                        dataSize);

  if(dataFile=0)or(data=nil)then raise Exception.Create('Could not map create debug fileMapping. Run this as Admin!');
end;

procedure TDebugLogServer.updatePing;
var i,st:integer;
begin
  st:=data.ping;  data.ping:=0; //latch

  for i:=0 to high(pingState) do begin
    if(st and (1 shl i))<>0 then pingState[i]:=255
                            else pingState[i]:=pingState[i]*7 shr 3;
  end;
end;

procedure TDebugLogServer.drawPing(canvas:TCanvas; x, y, h:integer);
var i,j,k,w:integer;

const pal:array[0..7]of integer=($ffffff, $00FF00, $00FFe0, $2020FF, $FF2020, $00b0FF, $b000FF, $FFFF00);

begin with canvas do begin
  w:=h*8;
  for i:=0 to high(pingState) do begin
    setPen(psSolid, clGray);
    setBrush(bsSolid, rgblerp(0, pal[i], pingState[i]));
    j:=0;//switch(i<4, h div 2, 0);
    k:=i;
    Ellipse(j+w*k div 8+1, 1, j+w*(k+1)div 8-2, h-2);
  end;
end;end;

procedure TDebugLogServer.clearExit;
begin
  data.force_exit:=0;
end;

procedure TDebugLogServer.forceExit;
begin
  data.force_exit:=1;
end;

procedure TDebugLogServer.clearLog;
begin
  logEvents:=nil;
  logChanged:=true;
end;

procedure TDebugLogServer.processLogMessage(s:ansistring);
  procedure focusDebugLog; begin FrmMain.pcRight.ActivePage:=FrmMain.tsDebug; end;
  procedure focusCompileLog; begin FrmMain.pcRight.ActivePage:=FrmMain.tsCompile; end;

var cmd, content: ansistring;
    i: integer;
begin
  if(isWild2('*:*', s, cmd, content))then begin
    if cmd='START' then begin
      clearLog;
    end else if cmd='LOG' then begin
      focusDebugLog;
      setlength(logEvents, length(logevents)+1);
      logEvents[high(logEvents)]:=s;
      logChanged:=true;
    end else if cmd = 'EXCEPTION' then begin
      focusCompileLog;
      beep;
      with FrmMain.lbCompileOutput do begin
        i:=Items.Count;
        Items.BeginUpdate;
        for s in listSplit(content, #10)do begin
          Items.Add(s);
        end;
        Items.EndUpdate;
        ItemIndex:=Items.Count-1;
        ItemIndex:=i;
      end;
      FrmMain.GotoError(content);
    end;
  end;
end;

procedure TDebugLogServer.resetBeforeRun;
begin
  with data^ do begin
    dide_hwnd:=FrmMain.Handle;
    exe_hwnd:=0;
    force_exit:=0;
    dide_ack:=0;
    exe_waiting:=0;
  end;
end;

procedure TDebugLogServer.setPotiValue(idx: integer; val: single);
begin
  if(idx>=0)and(idx<=high(data.poti))then begin
    data.poti[idx]:=val;
  end;
end;

procedure TDebugLogServer.updateLog;
var s:ansistring;
label re;
begin
  while true do begin
    s:=CircBuf_getLog(data.tail, data.head, sizeof(data.circBuf), @data.circBuf);
    if s='' then break;
    processLogMessage(s);
  end;
end;

function TDebugLogServer.getLogCount: integer;
begin
  result:=length(logEvents);
end;

function TDebugLogServer.getLogStr(idx: integer): ansistring;
begin
  if inRange(idx, 0, getLogCount-1) then result:=logEvents[idx]
                                    else result:='';
end;

function TDebugLogServer.update:boolean;
begin
  if data=nil then exit(false);
  updatePing;
  updateLog;
  result:=true; //todo: only when chg...
end;

procedure TDebugLogServer.draw;
var x, y (*w, h*):integer;
begin
  with r do begin
    x:=left; y:=top;
//    w:=right-x; h:=bottom-y;
  end;
  drawPing(canvas, x, y, 16);
end;

end.






