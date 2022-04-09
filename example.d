const null alias asm assert int __FILE__

module tokenizer;
import std.stdio, std.format, std.variant, std.datetime, std.traits, utils, keywords;

const CompilerVersion = 100;

//refactor to anonym -> ebben elvileg a delphi jobb.
enum TokenKind {Unknown, Comment, Identifier, Keyword, Special, Operator, LiteralString, LiteralChar, LiteralInt, LiteralFloat};

struct Token{
  TokenKind kind;
  int pos=0, length=0, line, posInLine;
  Variant data;
  int id; //emuns: operator, keyword
  string sourceText;
}

struct Tokenizer{
public:
  string fileName;
  string text;
  int pos, line, posInLine;
  char ch; //actual character
  Token[] res;   //should rename to tokens

  void error(string s){
    throw new Exception(format("%s(%d:%d): Tokenizer error: %s", fileName, line, posInLine, s));
  }

  void fetch(){
    pos++; posInLine++;
    if(pos>=text.length){
      ch=0;  //eof is ch
    }else{
      ch = text[pos];
    }
  }

  void fetch(int n){ for(int i=0; i<n; ++i) fetch; }

  char peek(int n=1){
    if(pos+n>=text.length) return 0;
                      else return text[pos+n];
  }

  static bool isEOF      (char ch) { return ch==0 || ch=='\x1A'; }
  static bool isNewLine  (char ch) { return ch=='\r' || ch=='\n'; }
  static bool isLetter   (char ch) { return ch>='a' && ch<='z' || ch>='A' && ch<='Z' || ch=='_'; }
  static bool isDigit    (char ch) { return ch>='0' && ch<='9'; }
  static bool isOctDigit (char ch) { return ch>='0' && ch<='7'; }
  static bool isHexDigit (char ch) { return ch>='0' && ch<='9' || ch>='a' && ch<='f' || ch>='A' && ch<='F'; }
  int  expectHexDigit(char ch) { if(isDigit(ch)) return ch-'0'; if(ch>='a' && ch<='f') return ch-'a'; if(ch>='A' && ch<='F') return ch-'A'; error(`Hex digit expected instead of "`~ch~`".`); return -1; }
  int  expectOctDigit(char ch) { if(isOctDigit(ch)) return ch-'0'; error(`Octal digit expected instead of "`~ch~`".`); return -1; }

  bool isKeyword(string s) {
    return kwLookup(s)>=0;
  }

  void skipLineComment()
  {
    fetch;
    while(1){
      fetch;
      if(isEOF(ch) || isNewLine(ch)) break; //EOF of NL
    }
  }

  void skipBlockComment()
  {
    fetch;
    while(1){
      fetch;
      if(isEOF(ch)) return;//error("BlockComment is not closed properly."); //EOF
      if(ch=='*' && peek=='/'){
        fetch; fetch;
        break;
      }
    }
  }

  void skipNestedComment()
  {
    fetch;
    int cnt = 1;
    while(1){
      fetch;
      if(isEOF(ch)) return;//error("NestedComment is not closed properly."); //EOF
      if(ch=='/' && peek=='+'){
        fetch; cnt++;
      }else if(ch=='+' && peek=='/'){
        fetch; cnt--;
        if(cnt<=0) { fetch; break; }
      }
    }
  }

  void skipNewLine()
  {
         if(ch=='\r'){ fetch; if(ch=='\n') fetch; }
    else if(ch=='\n'){ fetch; if(ch=='\r') fetch; }
  }

  void skipSpaces()
  {
    while(1){
      switch(ch){
        default: return;
        case ' ': case '\x09': case '\x0B': case '\x0C': { fetch; continue; }
      }
    }
  }

  bool skipWhiteSpaceAndComments() //returns true if eof
  {
    while(1){
      switch(ch){
        default:{
          return false;
        }
        case '\x00': case '\x1A':{ //EOF
          return true;
        }
        case ' ': case '\x09': case '\x0B': case '\x0C':{ //whitespace
          fetch;
          break;
        }
        case '\r':{ //NewLine1
          fetch;
          if(ch=='\n') fetch;
          line++;  posInLine = 0;
          break;
        }
        case '\n':{ //NewLine2
          fetch;
          if(ch=='\r') fetch;
          line++;  posInLine = 0;
          break;
        }
        case '/':{ //comment
          switch(peek){
            default: return false;
            case '/': newToken(TokenKind.Comment); skipLineComment  ; finalizeToken; break;
            case '*': newToken(TokenKind.Comment); skipBlockComment ; finalizeToken; break;
            case '+': newToken(TokenKind.Comment); skipNestedComment; finalizeToken; break;
          }
          break;
        }
      }
    }
  }

  void newToken(TokenKind kind)
  {
    Token tk;
    tk.kind = kind;
    tk.pos = pos;
    tk.line = line;
    tk.posInLine = posInLine;
    res ~= tk;
  }

  void finalizeToken()
  {
    Token *t = &res[$-1];
    t.length = pos-t.pos;
    t.sourceText = text[t.pos..pos];
  }

  ref Token lastToken() { return res[$-1]; }

  void removeLastToken() { res.length--; }

  void seekToEOF() { pos = text.length; ch = 0; }

  string fetchIdentifier() {
    string s;
    if(isLetter(ch)){
      s ~= ch; fetch;
      while(isLetter(ch) || isDigit(ch)){ s ~= ch; fetch; }
    }
    return s;
  }

  string peekIdentifier(int pos) {
    string s;
    char ch = peek(pos++);
    if(!isLetter(ch)) return s;
    s ~= ch;
    while(1){
      ch = peek(pos++);
      if(!isLetter(ch) && !isDigit(ch)) break;
      s ~= ch;
    }
    return s;
  }

  string getCurrentDateStr() { with(Clock.currTime) return "%3s %2d %4d".format(month, day, year); }
  string getCurrentTimeStr() { with(Clock.currTime) return "%2d:%.2d:%.2d".format(hour, minute, second); }
  string getCurrentTimeStampStr() { with(Clock.currTime) return "%3s %3s %2d %2d:%.2d:%.2d %4d".format(dayOfWeek, month, day, hour, minute, second, year); }
  string getCurrentDateTimeStr() { with(Clock.currTime) return "%4d.%.2d.%.2d %2d:%.2d:%.2d".format(year, to!int(month), day, hour, minute, second); }

  void revealSpecialTokens(){
    with(lastToken){
      if(kwIsSpecialKeyword(id)){
        switch(id){
          default                     :{ error("Unhandled keyword specialtoken: "~sourceText); break; }
          case kw__EOF__              :{ seekToEOF; removeLastToken; break; }
          case kw__TIMESTAMP__        :{ kind = TokenKind.LiteralString; data = getCurrentTimeStampStr; break; }
          case kw__DATE__             :{ kind = TokenKind.LiteralString; data = getCurrentDateStr; break; }
          case kw__TIME__             :{ kind = TokenKind.LiteralString; data = getCurrentTimeStr; break; }
          case kw__VENDOR__           :{ kind = TokenKind.LiteralString; data = "realhet"; break; }
          case kw__VERSION__          :{ kind = TokenKind.LiteralInt   ; data = CompilerVersion;break; }
          case kw__DATETIME__         :{ kind = TokenKind.LiteralString; data = getCurrentDateTimeStr; break; } //EXTRA: A more readeable timestamp...
          case kw__FILE__             :{ import std.path; kind = TokenKind.LiteralString; data = baseName(fileName); break; }
          case kw__FILE_FULL_PATH__   :{ kind = TokenKind.LiteralString; data = fileName; break; }
          case kw__LINE__             :{ kind = TokenKind.LiteralInt   ; data = line+1; break; }
          case kw__MODULE__           :{ kind = TokenKind.LiteralString; data = "module"; break; } //TODO
          case kw__FUNCTION__         :{ kind = TokenKind.LiteralString; data = "function"; break; } //TODO
          case kw__PRETTY_FUNCTION__  :{ kind = TokenKind.LiteralString; data = "pretty_function"; break; } //TODO
        }
      }else if(kwIsOperator(id)){
        switch(id){
          default: { error("Unhandled keyword operator: "~sourceText); break; }
          case kwin: case kwis: case kwnew: case kwdelete:{
            kind = TokenKind.Operator;
            id = opParse(sourceText);
            if(!id) error("Cannot lookup keyword operator.");
          break; }
        }
      }
    }
  }

  void parseIdentifier() {
    newToken(TokenKind.Identifier);

    fetch;
    while(isLetter(ch) || isDigit(ch)) fetch;

    finalizeToken();

    with(lastToken){ //set tokenkind kind

      //is it a keyword?
      int kw = kwLookup(sourceText);
      if(kw){
        kind = TokenKind.Keyword;
        id = kw;
        revealSpecialTokens; //is it a special keyword of operator?
      }
    }
  }

  string parseEscapeChar()
  {
    fetch;
    switch(ch){
      default: {
        //named character entries
        error(format(`Invalid char in escape sequence "%s" hex:%d`, ch, ch)); return "";
      }
      case '\'': case '\"': case '?': case '\\': { auto res = to!string(ch); fetch; return res; }
      case 'a': { fetch; return "\x07"; }
      case 'b': { fetch; return "\x08"; }
      case 'f': { fetch; return "\x0C"; }
      case 'n': { fetch; return "\x0A"; }
      case 'r': { fetch; return "\x0D"; }
      case 't': { fetch; return "\x09"; }
      case 'v': { fetch; return "\x0B"; }
      case 'x': { fetch;
        int x = expectHexDigit(ch); fetch;
        x = (x<<4) + expectHexDigit(ch); fetch;
        return to!string(cast(char)x);
      }
      case '0':..case '7': {
        int o;
        o = expectOctDigit(ch); fetch;
        if(isOctDigit(ch)) {
          o = (o<<3) + expectOctDigit(ch); fetch;
          if(isOctDigit(ch)) {
            o = (o<<3) + expectOctDigit(ch); fetch;
          }
        }
        return to!string(cast(char)o);
      }
      case 'u': case 'U':{
        int cnt = ch=='u' ? 4 : 8;
        fetch;
        int u;  for(int i=0; i<cnt; ++i){ u = (u<<4)+expectHexDigit(ch); fetch; }
        return to!string(cast(dchar)u);
      }
      case '&':{
        fetch;
        auto s = fetchIdentifier;
        if(ch!=';') error(`NamedCharacterEntry must be closed with ";".`);
        fetch;

        auto u = nceLookup(s);
        if(!u) error(`Unknown NamedCharacterEntry "`~s~`".`);

        return to!string(u);
      }
    }
  }

  void parseStringPosFix() {
    if(ch=='c' || ch=='w' || ch=='d') fetch;
  }

  void parseWysiwygString(bool handleEscapes=false, bool onlyOneChar=false){
    newToken(TokenKind.LiteralString);
    char ending;
    if(ch=='r'){ ending = '"'; fetch; fetch; }
          else { ending = ch; fetch; }
    string s;
    int cnt;
    while(1){
      cnt++;
      if(isEOF(ch)) error("Unexpected EOF in a WysiwygString.");
      if(ch==ending) { fetch; break; }
      if(isNewLine(ch)) { s ~= '\n'; skipNewLine; continue; }
      if(handleEscapes && ch=='\\'){ s ~= parseEscapeChar; continue; }
      s ~= ch;  fetch;
    }
    parseStringPosFix;
    finalizeToken;
    lastToken.data = s;

    if(onlyOneChar && cnt!=2) error("Character constant must contain exactly one character.");
  }

  void parseDoubleQuotedString(){ parseWysiwygString(true); }
  void parseLiteralChar(){ parseWysiwygString(true, true); }

  void parseHexString(){
    newToken(TokenKind.LiteralString);
    fetch; fetch;
    bool phase;  string s;  int act;
    while(1){
      //EXTRA: Comments can be placed into hex strings.
      if(skipWhiteSpaceAndComments) error("Unexpected EOF in a HexString.");
      if(ch=='"') { fetch; break; }
      if(isHexDigit(ch)){
        int d = expectHexDigit(ch); fetch;
        if(!phase){
          act = d<<4;
        }else{
          act |= d;
          s ~= cast(char)act;
        }
        phase = !phase;
      }
    }
    if(phase) error("HexString must contain an even number of digits.");
    parseStringPosFix;
    finalizeToken;
    lastToken.data = s;
  }

  void parseDelimitedString(){
    newToken(TokenKind.LiteralString);
    fetch; fetch; //q"..."

    string s;
    if(isLetter(ch)){ //identifier ending
      string ending = fetchIdentifier;
      if(!isNewLine(ch)) error("Delimited string: there must be a NewLine right after the identifier.");
      skipNewLine;

      while(1){
        if(isEOF(ch)) error("Unexpected EOF in a DelimitedString.");
        if(isNewLine(ch)){
          skipNewLine;

          bool found = true;  foreach(idx, c; ending) if(peek(idx)!=c){ found = false; break; }
          if(found){
            fetch(ending.length);
            break;
          }

          s ~= '\n';
          continue;
        }
        s ~= ch;  fetch;
      }
    }else{ //single char ending
      char ending;
           if(ch=='[') ending = ']';
      else if(ch=='<') ending = '>';
      else if(ch=='(') ending = ')';
      else if(ch=='{') ending = '}';
      else if(ch>=' ' || ch<='~') ending = ch;
      else error(`Invalid char "`~ch~`" used as delimiter in a delimited string`);
      fetch;

      while(1){
        if(isEOF(ch)) error("Unexpected EOF in a DelimitedString.");
        if(ch==ending && peek=='"') { fetch; break; }
        if(isNewLine(ch)) { s ~= '\n'; skipNewLine;  continue; }
        s ~= ch;  fetch;
      }
    }

    if(ch!='"') error(`Expecting an " at the end of a DelimitedString instead of "`~ch~`".`);
    fetch;

    parseStringPosFix;
    finalizeToken;
    lastToken.data = s;
  }

  string parseInteger(int base)
  {
    string s;
    if(base==10){
      while(1){
        if(isDigit(ch)) { s ~= ch; fetch; continue; }
        if(ch=='_') { fetch; continue; }
        break;
      }
    }else if(base==2){
      while(1){
        if(ch=='0' || ch=='1') { s ~= ch; fetch; continue; }
        if(ch=='_') { fetch; continue; }
        break;
      }
    }else if(base==16){
      while(1){
        if(isHexDigit(ch)) { s ~= ch; fetch; continue; }
        if(ch=='_') { fetch; continue; }
        break;
      }
    }

    return s;
  }

  string expectInteger(int base)
  {
    auto s = parseInteger(base);
    if(s is null) error("A number was expected (in base:%d).".format(base));
    return s;
  }


  void parseNumber()
  {

    ulong toULong(string s, int base)
    {
      ulong a;
      if(base ==  2) foreach(ch; s) { a <<=  1;  a += ch-'0'; } else
      if(base == 10) foreach(ch; s) { a *=  10;  a += ch-'0'; } else
      if(base == 16) foreach(ch; s) { a <<=  4;  a += ch>='a' ? ch-'a'+10 :
                                                      ch>='A' ? ch-'A'+10 : ch-'0'; }
      return a;
    }

    newToken(TokenKind.LiteralInt);

    bool isFloat = false;
    int base = 10; //get base
    string whole, fractional, exponent;
    int expSign = 1;

    //parse float header
    if(ch=='0'){
      char ch1 = peek;
      if(ch1=='x' || ch1=='X') base = 16; else
      if(ch1=='b' || ch1=='B') base = 2;
      if(base!=10) fetch(2);//skip the header
    }

    //parse fractional part
    bool exponentDisabled;
    if(ch=='.' && peek!='.' && !isLetter(peek)){ //the number starts with a point
      whole = "0";
      isFloat = true;  fetch;  fractional = expectInteger(base);
    }else{ //the number continues with a point
      whole = expectInteger(base);
      if(ch=='.'){
        bool isNextDigit = isDigit(peek);
        if(base==16) isNextDigit |= isHexDigit(peek);
        if(isNextDigit){
          isFloat = true; fetch;  fractional = parseInteger(base); //number is optional.
          if(fractional is null) exponentDisabled = true;
        }
      }
    }

    //parse optional exponent
    if(!exponentDisabled)
    if((base<=10 && (ch=='e' || ch=='E'))
     ||(base<=16 && (ch=='p' || ch=='P'))) {
      isFloat = true;
      fetch;
      if(ch=='-') { fetch; expSign = -1; } else if(ch=='+') fetch; //fetch expsign
      exponent = expectInteger(10);
    }

    if(isFloat){ //assemble float
      //process float postfixes
      int size = 8;
      if(ch=='f' || ch=='F') { fetch; size =  4; }
            else if(ch=='L') { fetch; size = 10; }

      bool isImag;
      if(ch=='i')            { fetch; isImag = true; }

      //put it together
      real rbase = base;
      real num = toULong(whole, base);
      if(fractional !is null) num += toULong(fractional, base)*(rbase^^(-cast(int)fractional.length));
      if(exponent !is null) num *= to!real(base==10?10:2)^^(expSign*to!int(toULong(exponent, 10)));

      //place it into the correct type
      Variant v;
      if(isImag){
        if(size== 4) v = 1.0i * cast(float )num; else
        if(size== 8) v = 1.0i * cast(double)num; else
                     v = 1.0i * cast(real  )num;
      }else{
        if(size== 4) v = cast(float ) num; else
        if(size== 8) v = cast(double) num; else
                     v = cast(real  ) num;
      }

      finalizeToken;  lastToken.data = v;
    }else{ //assemble integer
      ulong num = toULong(whole, base);

      //fetch posfixes
      bool isLong, isUnsigned;
      if(ch=='L') { fetch; isLong = true; }
      if(ch=='u' || ch=='U') { fetch; isUnsigned = true; }
      if(!isLong && ch=='L') { fetch; isLong = true; }

      Variant v;
      if(!isLong && !isUnsigned){ //no postfixes
        if(num<=          0x7FFF_FFFF            ) v = cast(int)num; else
        if(num<=          0xFFFF_FFFF && base!=10) v = cast(uint)num; else //hex/bin can be unsigned too to use the smallest size as possible
        if(num<=0x7FFF_FFFF_FFFF_FFFF            ) v = cast(long)num;
                                              else v = num;
      }else if(isLong && isUnsigned){ //UL
        v = num;
      }else if(isLong){ //L
        if(num<=0x7FFF_FFFF_FFFF_FFFF) v = cast(long)num;
                                  else v = num;
      }else/*if(isUnsigned)*/{ //U
        if(num<=          0xFFFF_FFFF) v = cast(uint)num;
                                  else v = num;
      }

      finalizeToken;  lastToken.data = v;
    }
  }

  bool tryParseOperator()
  {
    int len;
    auto opId = opParse(text[pos..$], len);
    if(!opId) return false;

    newToken(TokenKind.Operator);
    fetch(len);
    finalizeToken;
    lastToken.id = opId;

    return true;
  }

  string parseFilespec() //used in #line specialSequence
  {
    parseWysiwygString;
    auto res = to!string(lastToken.data);
    removeLastToken;
    return res;
  }

public:
  Token[] tokenize(const string fileName, const ref string text){
    this.fileName = fileName;
    this.text = text;
    line = 0;
    pos = posInLine = -1; fetch; //fetch the first char
    res = null;

    while(1){
      if(skipWhiteSpaceAndComments) break; //eof reached
      switch(ch){
        default:{
          if(tryParseOperator) continue;
          //cannot identify it at all
          error(format("Invalid character [%s] hex:%x", ch, ch)); break;
        }
        case 'a':..case 'z': case 'A':..case 'Z': case '_':{
          char nc = peek;
          if(nc=='"'){
            if(ch=='r'){ parseWysiwygString; break; }
            if(ch=='q'){ parseDelimitedString; break; }
            if(ch=='x'){ parseHexString; break; }
          }else if(nc=='{'){
            if(ch=='q'){ tryParseOperator; break; }
          }
          parseIdentifier;
          break;
        }
        case '"':{ parseDoubleQuotedString; break; }
        case '`':{ parseWysiwygString; break; }
        case '\'':{ parseLiteralChar; break; }
        case '0':..case '9':{ parseNumber; break; }
        case '.':{
          if(isDigit(peek)){ parseNumber; break; }
          goto default; //operator
        }
        case '#':{ //Special token sequences
          auto s = peekIdentifier(1);
          if(s=="line"){ //lineNumber/fileName override
            fetch(1+line.sizeof);  skipSpaces;
            this.line = to!int(expectInteger(10))-2;  skipSpaces;
            if(ch=='"'){ this.fileName = parseFilespec;  skipSpaces;  }
            if(!isNewLine(ch)) error("NewLine character expected after #line SpecialTokenSequence.");

            break;
          }
          goto default; //operator
        }
      }
    }

    return res;
  }
}//struct Tokenizer

Token[] tokenize(const string fileName, const string text)
{
  Tokenizer t;
  return t.tokenize(fileName, text);
}

////////////////////////////////////////////////////////////////////////////////



/+
void main(string[] args)
{

  string s = q"END
    __LINE__ __FILE__
    a = b+c;

    /+/+nested comment+/+//*block comment*///line comment
    identifier case __FILE__

    r"wysiwygString1"c`wysiwygString2`w"doubleQuotedString"d //strings with optional posfixes
    x"40 /*hello*/ 41" //hex string with a comment
    '\u0040' '\u0177' "\U00000177\u03C0\x1fa\'a\b\b" //unicode chars
    "\&gt;\&amp;" //named character entries

    __DATE__ __TIME__ __TIMESTAMP__ __VENDOR__ __VERSION__ __FILE__ __LINE__ __DATETIME__

    0 1 12
    0.1 .1 1.
    0.12 .12 12.
    1e10 1e-10
    1.e30f
    11.5i
    0b11.1e1L
    0xff.0p-1

    //usual decimal notation (int, long, long ulong)
    2_147_483_647
    4_294_967_295
    9_223_372_036_854_775_807
    18_446_744_073_709_551_615
    //decimal with suffixes (long ulong uint ulong ulong
    9_223_372_036_854_775_807L
    18_446_744_073_709_551_615L
    4_294_967_295U
    9_223_372_036_854_775_807U
    4Lu
    //hex without suffix (int uint long, ulong)
    0x7FFF_FFFF
    0x8000_0000
    0x7FFF_FFFF_FFFF_FFFF
    0x8000_0000_0000_0000

    __LINE__
    __LINE__
    #line 6
    __LINE__
    __LINE__
    #line 66 "c:\override.d"
    __LINE__
    __LINE__ __FILE__

    //__EOF__

    q{tokenstring}
    q"{delimited{string}}"
END";



  s ~= `q"AHH
another delimited string
AHH"
`;//Note: it bugs in DMD: restarts the string from this string and adds another newline at the end.

  Tokenizer t;
  auto tokens = t.tokenize("testFileName.d", s);

  foreach(tk; tokens)writeln(format("%-14s %-32s %-20s %s", tk.kind, tk.sourceText, to!string(tk.data.type), to!string(tk.data)));
  writeln("done");

//writeln(s);

//todo: optional string postfixes
}
+/