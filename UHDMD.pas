unit UHDMD;
interface

uses sysutils, types, het.utils;

//deprecated. ezt mar csak D-ben.

type
  TErrorLine=record
//    typ:TErrorType;
    fileName:ansistring;
    pos:TPoint; //0based
    msg:ansistring;
  end;


implementation

end.
