unit UCircBuf;
interface
uses sysutils, het.utils;

//circular buffer reader ised in pair with utils.d:CircBuf

function CircBuf_getLog(var tail, head:cardinal; const cap:cardinal; buf:pointer):ansistring;


implementation

function CircBuf_getLog(var tail, head:cardinal; const cap:cardinal; buf:pointer):ansistring; //reads a packet from the circbuff

  function capacity:cardinal; begin result:=cap; end;
  function length:cardinal; begin result:=head-tail; end;
  function canGet:cardinal; begin result:=length; end;

  function truncate(x: cardinal):cardinal;
  begin
    result := x mod cap;
  end;

  function get(dst:pointer; dstLen:cardinal):boolean;
  var i, o, fullLen:cardinal;
  begin
    if dstLen>canGet then exit(false);

    o := truncate(tail);
    fullLen := dstLen;
    if(o+dstLen>=capacity)then begin //multipart
      i := capacity-o;
      Move(PByteArray(buf)[o], dst^, i);
      o := 0;
      pinc(dst, i);
      dec(dstLen, i);
    end;
    if(dstLen>0)then begin
      Move(PByteArray(buf)[o], dst^, dstLen);
    end;

    //advance in one step
    inc(tail, fullLen); //no atomic needed as one writes and the other reads

    result:=true;
  end;

  procedure flush;
  begin
    inc(tail, canGet)
  end;

var siz:cardinal;
    t0:double;
begin
  if not get(@siz, 4) then exit('');
  setlength(result, siz);
  t0:=qps;
  while not get(pointer(result), siz) do begin
    sleep(1); //probably an error+deadlock...
    if qps-t0>0.1 then begin
      flush;
      exit('');
    end;
  end;
end;

end.
