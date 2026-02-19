unit v8napi_x64;

//////////////////////////
// 1CNativeLib          //
// Alexander Solomatin  //
// qxlreport@mail.ru    //
//////////////////////////

//16.12.2015 èìåíà ñâîéñòâ è ìåòîäîâ òåïåðü áåç ó÷åòà ðåãèñòðà áóêâ
//06.10.2015 èñïðàâëåíà îøèáêà. ñîîáùåíèå "íåêîððåêòíàÿ ðàáîòà êîìïîíåíòû ñ ïàìÿòüþ"
//16.10.2012 âíåñåíû íåáîëüøèå èçìåíåíèÿ. äîáàâëåíû ôóíêöèè äëÿ òèïà Uint
//29.09.2012 âíåñåíû íåáîëüøèå èçìåíåíèÿ. òåïåðü ðàáîòàåò íà x64
//04.04.2011 èñïðàâëåíà îøèáêà ñ äàòàìè


interface

uses SysUtils, Windows;

type
  V8TYPEVAR = longword;

  UInt = longword;

const
  VTYPE_EMPTY = $000;
  VTYPE_NULL = $001;
  VTYPE_I2 = $002; //int16_t
  VTYPE_I4 = $003; //int32_t
  VTYPE_R4 = $004; //float
  VTYPE_R8 = $005; //double
  VTYPE_DATE = $006; //DATE (double)
  VTYPE_TM = $007; //struct tm
  VTYPE_PSTR = $008; //struct str    string
  VTYPE_INTERFACE = $009; //struct iface
  VTYPE_ERROR = $00A; //int32_t errCode
  VTYPE_BOOL = $00B; //bool
  VTYPE_VARIANT = $00C; //struct V8Variant *
  VTYPE_I1 = $00D; //int8_t
  VTYPE_UI1 = $00E; //uint8_t
  VTYPE_UI2 = $00F; //uint16_t
  VTYPE_UI4 = $010; //uint32_t
  VTYPE_I8 = $011; //int64_t
  VTYPE_UI8 = $012; //uint64_t
  VTYPE_INT = $013; //int   Depends on architecture
  VTYPE_UINT = $014; //unsigned int  Depends on architecture  20
  VTYPE_HRESULT = $015; //long hRes   21
  VTYPE_PWSTR = $016; //struct wstr      22
  VTYPE_BLOB = $017; //means in struct str binary data contain 23
  VTYPE_CLSID = $018; //UUID                                   24
  VTYPE_STR_BLOB = $0FFF;
  VTYPE_VECTOR = $1000;
  VTYPE_ARRAY = $2000;
  VTYPE_BYREF = $4000; //Only with struct V8Variant *
  VTYPE_RESERVED = $8000;
  VTYPE_ILLEGAL = $FFFF;
  VTYPE_ILLEGALMASKED = $0FFF;
  VTYPE_TYPEMASK = $FFF;

type
  TV8InterfaceVarRec = packed record
    pInterfaceVal: pointer;
    InterfaceID: TGUID;
  end; //*iface*/;

  TV8StringVarRec = packed record
    pstrVal: PAnsiChar;
    strLen: LongWord; //count of bytes
  end; //*str*/;

  TV8WideStringVarRec = packed record
    pwstrVal: PWideChar;
    wstrLen: LongWord; //count of symbol
  end; //*wstr*/

  PV8tm = ^TV8tm;
  TV8tm = record
    tm_sec: Integer; // seconds after the minute (from 0)
    tm_min: Integer; // minutes after the hour (from 0)
    tm_hour: Integer; // hour of the day (from 0)
    tm_mday: Integer; // day of the month (from 1)
    tm_mon: Integer; // month of the year (from 0)
    tm_year: Integer; // years since 1900 (from 0)
    tm_wday: Integer; // days since Sunday (from 0)
    tm_yday: Integer; // day of the year (from 0)
    tm_isdst: Integer; // Daylight Saving Time flag
  end;


  TVarEnum = record
    case byte of
      1: (i8Val: byte);
      2: (shortVal: ShortInt);
      3: (lVal: Integer);
      4: (intVal: Integer);
      5: (uintVal: Uint);
      6: (llVal: int64);
      7: (ui8Val: byte);
      8: (ushortVal: Word);
      9: (ulVal: LongWord);
      10: (ullVal: Int64);
      11: (errCode: Integer);
      12: (hRes: LongWord);
      13: (fltVal: Single);
      14: (dblVal: double);
      15: (bVal: boolean);
      16: (chVal: char);
      17: (wchVal: WideChar);
      18: (date: TDateTime);
      19: (IDVal: TGUID);
      20: (pvarVal: pointer);
      21: (tmVal: TV8tm);
      22: (vtRecInterface: TV8InterfaceVarRec);
      23: (vtRecString: TV8StringVarRec);
      24: (vtRecWideString: TV8WideStringVarRec);
  end;


  PV8Variant = ^V8Variant;
  V8Variant = packed record
    VarEnum: TVarEnum;
    cbElements: LongWord; //Dimension for an one-dimensional array in pvarVal
    vt: V8TYPEVAR;
  end;

type
  TV8MemoryManager = class //IMemoryManager ñì. äîêóìåíòàöèþ îò 1Ñ
  public
    procedure Destroy1; virtual; abstract;
    function AllocMemory(pMemory: PPointer; ulCountByte: longword): boolean; virtual; stdcall; abstract;
    procedure FreeMemory(pMemory: PPointer); virtual; stdcall; abstract;
  end;

type
  TV8AddInDefBase = class //IAddInDefBase ñì. äîêóìåíòàöèþ îò 1Ñ
  public
    procedure Destroy1; virtual; abstract;
    function AddError(wcode: word; const source: PWideChar;
      const descr: PWideChar;
      scode: integer): boolean; virtual; stdcall; abstract;
    function Read(wszPropName: PWideChar;
      pVal: PV8Variant;
      pErrCode: PInteger;
      errDescriptor: PPWideChar): boolean; virtual; stdcall; abstract;
    function Write(wszPropName: PWideChar;
      pVar: PV8Variant): boolean; virtual; stdcall; abstract;
    function RegisterProfileAs(wszProfileName: PWideChar): boolean; virtual; stdcall; abstract;
    function SetEventBufferDepth(lDepth: integer): boolean; virtual; stdcall; abstract;
    function GetEventBufferDepth: integer; virtual; stdcall; abstract;
    function ExternalEvent(wszSource, wszMessage, wszData: PWideChar): boolean; virtual; stdcall; abstract;
    procedure CleanEventBuffer; virtual; stdcall; abstract;
    function SetStatusLine(wszStatusLine: PWideChar): boolean; virtual; stdcall; abstract;
    procedure ResetStatusLine; virtual; stdcall; abstract;
  end;


type
  TV8ParamArray = array[1..255] of V8Variant;
  PV8ParamArray = ^TV8ParamArray;

  TV8CallAsProc = function(Params: PV8ParamArray;
    const ParamCount: integer): boolean;
  TV8CallAsFunc = function(RetValue: PV8Variant; Params: PV8ParamArray;
    const ParamCount: integer): boolean;

  TV8PropertyGetSet = function(propValue: PV8Variant; Get: boolean): boolean;

  PV8CallAsProc = ^TV8CallAsProc;
  PV8CallAsFunc = ^TV8CallAsFunc;
  PV8PropertyGetSet = ^TV8PropertyGetSet;

type
  TDefParamValue = record
    Num: integer;
    Value: V8Variant;
  end;

  TDefParamValueArray = array of TDefParamValue;
  PDefParamValueArray = TDefParamValueArray;

  TDefParamList = class
    ValueCount: integer;
    Values: TDefParamValueArray;
    TempParam: PV8Variant;
    function AddParam(Num: integer): PV8Variant;
    procedure AddInt(V: integer; ParamNum: integer);
    procedure AddUInt(V: Longword; ParamNum: integer);
    procedure AddDouble(V: double; ParamNum: integer);
    procedure AddBool(V: boolean; ParamNum: integer);
    procedure AddWString(const V: PWideChar; ParamNum: integer);
    procedure AddAString(const V: PAnsiChar; ParamNum: integer);
    procedure AddDate(V: TDateTime; ParamNum: integer);
    destructor Destroy; override;
  end;

  TMethReg = class
    MethName: WideString;
    MethNameLoc: WideString;
    IsFunction: boolean;
    ParamCount: integer;
    DefParams: TDefParamList;
    Execute: pointer;
    constructor Create;
    destructor Destroy; override;
  end;

  TPropReg = class
    PropName: WideString;
    PropNameLoc: WideString;
    IsReadable: boolean;
    IsWritable: boolean;
    PropGetSet: pointer;
  end;

  TPropRegArray = array of TPropReg;
  PPropRegArray = ^TPropRegArray;

  TMethRegArray = array of TMethReg;
  PMethRegArray = ^TMethRegArray;

  TClassReg = class
    UserClass: TClass;
    RegisterExtensionAs: WideString;
    NatApiClassName: WideString;
    PropCount: integer;
    MethCount: integer;
    PropList: TPropRegArray;
    MethList: TMethRegArray;

    function AddMethod(MethName, MethNameLoc: WideString; IsFunction: boolean;
      ExecuteProc: pointer; ParamCount: integer = 0): TMethReg;

    function AddProc(MethName, MethNameLoc: WideString;
      ExecuteProc: PV8CallAsProc; ParamCount: integer = 0): TMethReg;

    function AddFunc(MethName, MethNameLoc: WideString;
      ExecuteProc: PV8CallAsFunc; ParamCount: integer = 0): TMethReg;

    procedure AddProp(PropName, PropNameLoc: WideString; IsReadable: boolean;
      IsWritable: boolean; PropGetSet: PV8PropertyGetSet);

    destructor Destroy; override;
  end;

  TClassRegArray = array of TClassReg;
  PClassRegArray = ^TClassRegArray;

  TClassRegList = class
    ClassCount: integer;
    ClassList: TClassRegArray;
    function RegisterClass(UserClass: TClass;
      RegisterExtensionAs, NatApiClassName: WideString): TClassReg;
    destructor Destroy; override;
  end;

  TV8UserObject = class
  public
    ClassReg: TClassReg;
    V8MM: TV8MemoryManager;
    V8: TV8AddInDefBase;
    locale: WideString;

    //Î÷èùàåò ïåðåìåííóþ V8Variant
    //Åñëè ïåðåìåííàÿ V8Variant èìåëà äëèííîå çíà÷åíèå (ñòðîêà èëè blob), òî
    //ïàìÿòü, çàíÿòàÿ ýòîé ïåðåìåííîé îñâîáîæäàåòñÿ ìåíåäæåðîì ïàìÿòè 1Ñ
    procedure V8ClearVar(V: PV8Variant);

    //Êîïèðóåò ïåðåìåííóþ V8Variant
    procedure V8CopyVar(Source: PV8Variant; Dest: PV8Variant);

    //Ôóíêöèè óñòàíàâëèâàþò çíà÷åíèÿ êîðîòêèõ òèïîâ ïåðåìåííîé V8Variant.
    //Ïåðåä óñòàíîâêîé çíà÷åíèÿ ïåðåìåííàÿ V8Variant î÷èùàåòñÿ.
    //Åñëè ïåðåìåííàÿ V8Variant èìåëà äëèííîå çíà÷åíèå (ñòðîêà èëè blob), òî
    //ïàìÿòü, çàíÿòàÿ ýòîé ïåðåìåííîé îñâîáîæäàåòñÿ ìåíåäæåðîì ïàìÿòè 1Ñ.
    procedure V8SetBool(V: PV8Variant; Value: boolean);
    procedure V8SetDate(V: PV8Variant; Value: TDateTime);
    procedure V8SetInt(V: PV8Variant; Value: integer);
    procedure V8SetUInt(V: PV8Variant; Value: longword);
    procedure V8SetDouble(V: PV8Variant; Value: double);

    //Ôóíêöèè ñòàíàâëèâàþò çíà÷åíèå ïåðåìåííîé V8Variant ñòðîêîâîãî òèïà èëè blob
    //Ïåðåä óñòàíîâêîé çíà÷åíèÿ ïåðåìåííàÿ V8Variant î÷èùàåòñÿ.
    //Åñëè ïåðåìåííàÿ V8Variant èìåëà äëèííîå çíà÷åíèå (ñòðîêà èëè blob), òî
    //ïàìÿòü, çàíÿòàÿ ýòîé ïåðåìåííîé, îñâîáîæäàåòñÿ ìåíåäæåðîì ïàìÿòè 1Ñ.
    //Ïàìÿòü ïîä çíà÷åíèå ïåðåìåííîé âûäåëÿåòñÿ ìåíåäæåðîì ïàìÿòè 1Ñ.
    function V8AllocWideString(W: WideString): PWideChar;
    function V8SetWString(V: PV8Variant; Value: WideString): boolean;
    function V8SetString(V: PV8Variant; Value: AnsiString): boolean;
    function V8SetPChar(V: PV8Variant; Value: PAnsiChar): boolean;
    function V8SetBlob(V: PV8Variant; Value: PByte; Length: integer): boolean;

    function Init: boolean; virtual; // ìîæíî override âûçûâàåòñÿ èç v8wrap
    function GetInfo: integer; virtual; // ìîæíî override âûçûâàåòñÿ èç v8wrap
    procedure SetLocale; virtual; // ìîæíî override âûçûâàåòñÿ èç v8wrap
    procedure Done; virtual; // ìîæíî override âûçûâàåòñÿ èç v8wrap
    function SetMemManager: boolean; virtual; //ìîæíî override âûçûâàåòñÿ èç v8wrap

    constructor Create; virtual; // ìîæíî override
    destructor Destroy; override; // ìîæíî override
  end;

  TV8UserClass = class of TV8UserObject;

function GetClassObject(const name: PWideChar; var pIntf: pointer): integer; cdecl;
function GetClassNames: PWideChar; cdecl;
function DestroyObject(var pIntf: pointer): integer; cdecl;
function SetPlatformCapabilities(const capabilities: integer): integer; cdecl;


function _WideSameStr(const S1, S2: WideString): boolean;

function AsInteger(V: PV8Variant): integer;
function AsUInteger(V: PV8Variant): Uint;
function AsDouble(V: PV8Variant): double;

//Ôóíêöèè ãðóïïû V8is ïðîâåðÿþò ïåðåìåííóþ òèïà V8Variant
//íà ñîîòâåòñòâèå îïðåäåëåííîìó òèïó
function V8isEmpty(V: PV8Variant): boolean; //Ïåðåìåííàÿ ïóñòà
function V8isNULL(V: PV8Variant): boolean; //Ïåðåìåííàÿ NULL
function V8isNumber(V: PV8Variant): boolean; //öåëîå èëè âåùåñòâåííîå ÷èñëî, êîä îøèáêè
function V8isString(V: PV8Variant): boolean;
function V8isWString(V: PV8Variant): boolean; //WideString
function V8isAString(V: PV8Variant): boolean; //AnsiString
function V8isBlob(V: PV8Variant): boolean;
function V8isDate(V: PV8Variant): boolean; //ÄàòàÂðåìÿ (VTYPE_DATE èëè VTYPE_TM)
function V8isBool(V: PV8Variant): boolean;

//Âîçâðàùàåò çíà÷åíèå èç V8Variant,
//åñëè çíà÷åíèå íå ñîîòâåòñòâóåò òèïó, âîçâðàùàåò íîëü
function V8AsInt(V: PV8Variant): integer; //òèï Double âîçâðàùàåòñÿ êàê öåëàÿ ÷àñòü
function V8AsUInt(V: PV8Variant): Uint; //òèï Double âîçâðàùàåòñÿ êàê öåëàÿ ÷àñòü
function V8AsDouble(V: PV8Variant): double; //òèï integer âîçâðàùàåòñÿ êàê Double

//Âîçâðàùàåò çíà÷åíèå òèïà ÄàòàÂðåìÿ èç V8Variant òèïà
//  äàòà (VTYPE_DATE,VTYPE_TM) èëè Double
//åñëè çíà÷åíèå íå ñîîòâåòñòâóåò òèïó, âîçâðàùàåò íîëü
function V8AsDate(V: PV8Variant): TDateTime;

//Âîçâðàùàåò çíà÷åíèå òèïà boolean èç V8Variant,
//åñëè çíà÷åíèå íå ñîîòâåòñòâóåò òèïó, âîçâðàùàåò False
function V8AsBool(V: PV8Variant): boolean;

//Âîçâðàùàåò óêàçàòåëè íà çíà÷åíèÿ òèïîâ Blob, AnsiChar, WideChar èç V8Variant,
//åñëè çíà÷åíèå íå ñîîòâåòñòâóåò òèïó, âîçâðàùàåò nil
function V8AsPWideChar(V: PV8Variant): PWideChar;
function V8AsWString(V: PV8Variant): WideString;
function V8AsPChar(V: PV8Variant): PAnsiChar;
function V8AsBlob(V: PV8Variant): PByte;

//Âîçâðàùàåò çíà÷åíèÿ òèïîâ AnsiString è WideString èç V8Variant
//â âèäå ñòðîêè AnsiString
function V8AsAString(V: PV8Variant): AnsiString;

//Äëèíà ïåðåìåííîé äëÿ òèïîâ Blob, AnsiString, WideString
function V8StrLen(V: PV8Variant): integer;

//Âîçâðàùàåò, â âèäå ñòðîêè, òèï çíà÷åíèÿ ïåðåìåííîé V8Variant
function V8VarTypeStr(V: PV8Variant): AnsiString;


var
  ClassRegList: TClassRegList;
  ClassNamesString: WideString;

implementation

type
  PV8ObjectRec = ^TV8ObjectRec;

  TV8ObjectRec = packed record
    I1: pointer;
    I2: pointer;
    I3: pointer;
    I4: pointer;

    RelObj1: TV8UserObject;
    RelObj2: TV8UserObject;
    RelObj3: TV8UserObject;
  end;

type
  _V8CP = function(Obj: TObject; paParams: PV8ParamArray;
    const lSizeArray: integer): boolean;

  _V8CF = function(Obj: TObject; pvarRetValue: PV8Variant;
    paParams: PV8ParamArray; const lSizeArray: integer): boolean;

  _V8PGS = function(Obj: TObject; propValue: PV8Variant; Get: boolean): boolean;

type

  TV8ProcRec = packed record
    Destroy1: pointer;

    Init: pointer;
    setMemManager: pointer;
    GetInfo: pointer;
    Done: pointer;

    Destroy2: pointer;

    RegisterExtensionAs: pointer;
    GetNProps: pointer;
    FindProp: pointer;
    GetPropName: pointer;
    GetPropVal: pointer;
    SetPropVal: pointer;
    IsPropReadable: pointer;
    IsPropWritable: pointer;
    GetNMethods: pointer;
    FindMethod: pointer;
    GetMethodName: pointer;
    GetNParams: pointer;
    GetParamDefValue: pointer;
    HasRetVal: pointer;
    CallAsProc: pointer;
    CallAsFunc: pointer;

    Destroy3: pointer;
    SetLocale: pointer;
  end;

var
  _ProcRec: TV8ProcRec;


function _StrLen(const V: PAnsiChar): integer;
begin
  result := StrLen(V);
end;

//âûçûâàòñÿ èç v8wrap. èñïîëüçóåòñÿ â FindProp è FindMethod

function _WideSameStr(const S1, S2: WideString): boolean;
begin
  result := WideCompareText(S1, S2) = 0;
end;

function _V8String(V8MM: TV8MemoryManager; W: WideString): PWideChar;
var
  SZ: integer;
begin
  result := nil;
  SZ := (Length(W) * sizeof(WideChar)) + sizeof(WideChar);
  if V8MM <> nil then
    if V8MM.AllocMemory(@result, SZ) then
    begin
      Move(W[1], result^, SZ);
    end;
end;

function GetClassObject(const name: PWideChar; var pIntf: pointer): integer;
  cdecl;
var
  i: integer;
  obj: TV8UserObject;
begin
  result := 0;
  obj := nil;
  for i := 0 to ClassRegList.ClassCount - 1 do
  begin
    if ClassRegList.ClassList[i].NatApiClassName = name then
    begin
      try
        obj := TV8UserClass(ClassRegList.ClassList[i].UserClass).Create;
      except
        Break;
      end;
      GetMem(pIntf, sizeof(TV8ObjectRec));
      FillChar(pIntf^, sizeof(TV8ObjectRec), 0);
      PV8ObjectRec(pIntf).I1 := @(_ProcRec.Destroy1);
      PV8ObjectRec(pIntf).I2 := @(_ProcRec.Destroy2);
      PV8ObjectRec(pIntf).I3 := @(_ProcRec.Destroy3);
      PV8ObjectRec(pIntf).I4 := nil;

      PV8ObjectRec(pIntf).RelObj1 := obj;
      PV8ObjectRec(pIntf).RelObj2 := obj;
      PV8ObjectRec(pIntf).RelObj3 := obj;

      PV8ObjectRec(pIntf).RelObj1.ClassReg := ClassRegList.ClassList[i];

      result := 1;
      Break;
    end;
  end;
end;

function GetClassNames: PWideChar; cdecl;
begin
  result := @ClassNamesString[1];
end;

function DestroyObject(var pIntf: pointer): integer; cdecl;
begin
  if pIntf <> nil then
  begin
    try
      PV8ObjectRec(pIntf).RelObj1.Free;
    finally
      FreeMem(pIntf, sizeof(TV8ObjectRec));
    end;
  end;
  PInteger(pIntf)^ := 0;
  result := 0;
end;

function SetPlatformCapabilities(const capabilities: integer): integer; cdecl;
begin
  result := 1;
end;

function _CallAsFunc(Obj: PV8ObjectRec; const lMethodNum: integer;
  pvarRetValue, paParams: PV8Variant; const lSizeArray: integer): boolean;
  stdcall;
begin
  result := _V8CF(Obj.RelObj1.ClassReg.MethList[lMethodNum].Execute)
    (Obj.RelObj1, pvarRetValue, PV8ParamArray(paParams), lSizeArray);
end;

function _CallAsProc(Obj: PV8ObjectRec; const lMethodNum: integer;
  paParams: PV8Variant; const lSizeArray: integer): boolean; stdcall;
begin
  result := _V8CP(Obj.RelObj1.ClassReg.MethList[lMethodNum].Execute)
    (Obj.RelObj1, PV8ParamArray(paParams), lSizeArray);
end;

procedure _Done(Obj: PV8ObjectRec); stdcall;
begin
  Obj.RelObj1.Done;
end;

function _FindMethod(Obj: PV8ObjectRec; const wsMethodName: PWideChar)
  : integer; stdcall;
var
  i: integer;
begin
  result := -1;
  for i := 0 to Obj.RelObj1.ClassReg.MethCount - 1 do
    if (_WideSameStr(Obj.RelObj1.ClassReg.MethList[i].MethNameLoc,
      wsMethodName)) or
      (_WideSameStr(Obj.RelObj1.ClassReg.MethList[i].MethName, wsMethodName))
      then
    begin
      result := i;
      Break;
    end;
end;

function _FindProp(Obj: PV8ObjectRec; const wsPropName: PWideChar): integer;
  stdcall;
var
  i: integer;
begin
  result := -1;
  for i := 0 to Obj.RelObj1.ClassReg.PropCount - 1 do
    if (_WideSameStr(Obj.RelObj1.ClassReg.PropList[i].PropNameLoc, wsPropName))
      or (_WideSameStr(Obj.RelObj1.ClassReg.PropList[i].PropName, wsPropName))
      then
    begin
      result := i;
      Break;
    end;
end;

function _GetInfo(Obj: PV8ObjectRec): integer; stdcall;
begin
  result := Obj.RelObj1.GetInfo;
end;

function _GetMethodName(Obj: PV8ObjectRec; const lMethodNum,
  lMethodAlias: integer): PWideChar; stdcall;
begin
  if lMethodAlias = 0 then
  begin
    result := Obj.RelObj1.V8AllocWideString(Obj.RelObj1.ClassReg.MethList[lMethodNum].MethName);
  end
  else
  begin
    result := Obj.RelObj1.V8AllocWideString(Obj.RelObj1.ClassReg.MethList[lMethodNum].MethNameLoc);
  end;
end;

function _GetNMethods(Obj: PV8ObjectRec): integer; stdcall;
begin
  result := Obj.RelObj1.ClassReg.MethCount;
end;

function _GetNParams(Obj: PV8ObjectRec; const lMethodNum: integer): integer;
  stdcall;
begin
  result := Obj.RelObj1.ClassReg.MethList[lMethodNum].ParamCount;
end;

function _GetNProps(Obj: PV8ObjectRec): integer; stdcall;
begin
  result := Obj.RelObj1.ClassReg.PropCount;
end;

function _GetParamDefValue(Obj: PV8ObjectRec; const lMethodNum,
  lParamNum: integer; pvarParamDefValue: PV8Variant): boolean; stdcall;
var
  i: Integer;
  Defs: TDefParamList;
begin
  // По умолчанию: значения по умолчанию НЕТ
  Result := False;
  if pvarParamDefValue <> nil then
    pvarParamDefValue^.vt := VTYPE_EMPTY;

  Defs := Obj.RelObj1.ClassReg.MethList[lMethodNum].DefParams;
  if Defs = nil then
    Exit;

  // В DefParams.Values лежат пары (Num, Value), Num = номер параметра (как приходит от платформы)
  for i := 0 to High(Defs.Values) do
  begin
    if Defs.Values[i].Num = lParamNum then
    begin
      Obj.RelObj1.V8CopyVar(@Defs.Values[i].Value, pvarParamDefValue);
      Result := True;
      Exit;
    end;
  end;
end;

function _GetPropName(Obj: PV8ObjectRec; lPropNum, lPropAlias: integer)
  : PWideChar; stdcall;
begin
  if lPropAlias = 0 then
    result := Obj.RelObj1.V8AllocWideString(Obj.RelObj1.ClassReg.PropList[lPropNum].PropName)
  else
    result := Obj.RelObj1.V8AllocWideString(Obj.RelObj1.ClassReg.PropList[lPropNum].PropNameLoc);
end;

function _GetPropVal(Obj: PV8ObjectRec; const lPropNum: integer;
  pvarPropVal: PV8Variant): boolean; stdcall;
begin
  result := False;
  pvarPropVal^.vt := VTYPE_EMPTY;
  if @(Obj.RelObj1.ClassReg.PropList[lPropNum].PropGetSet) <> nil then
    result := _V8PGS(Obj.RelObj1.ClassReg.PropList[lPropNum].PropGetSet)
      (Obj.RelObj1, pvarPropVal, True);
end;

function _HasRetVal(Obj: PV8ObjectRec; const lMethodNum: integer): boolean;
  stdcall;
begin
  result := Obj.RelObj1.ClassReg.MethList[lMethodNum].IsFunction;
end;

function _Init(Obj: PV8ObjectRec; disp: pointer): boolean; stdcall;
begin
  Obj.RelObj1.V8 := disp;
  result := Obj.RelObj1.Init;
end;

function _IsPropReadable(Obj: PV8ObjectRec; const lPropNum: integer): boolean;
  stdcall;
begin
  result := Obj.RelObj1.ClassReg.PropList[lPropNum].IsReadable;
end;

function _IsPropWritable(Obj: PV8ObjectRec; const lPropNum: integer): boolean;
  stdcall;
begin
  result := Obj.RelObj1.ClassReg.PropList[lPropNum].IsWritable;
end;

function _RegisterExtensionAs(Obj: PV8ObjectRec;
  wsExtensionName: PPWideChar): boolean; stdcall;
begin
  wsExtensionName^ := Obj.RelObj1.V8AllocWideString(Obj.RelObj1.ClassReg.RegisterExtensionAs);
  result := True;
end;

procedure _SetLocale(Obj: PV8ObjectRec; const loc: PWideChar); stdcall;
begin
  Obj.RelObj1.locale := loc;
  Obj.RelObj1.SetLocale;
end;

function _setMemManager(Obj: PV8ObjectRec; mem: pointer): boolean; stdcall;
begin
  Obj.RelObj1.V8MM := mem;
  result := Obj.RelObj1.SetMemManager;
end;

function _SetPropVal(Obj: PV8ObjectRec; const lPropNum: integer;
  pvarPropVal: PV8Variant): boolean; stdcall;
begin
  result := False;
  if @Obj.RelObj1.ClassReg.PropList[lPropNum].PropGetSet <> nil then
    result := _V8PGS(Obj.RelObj1.ClassReg.PropList[lPropNum].PropGetSet)
      (Obj.RelObj1, pvarPropVal, False);
end;


{ TDefParamList }

function TDefParamList.AddParam(Num: integer): PV8Variant;
var
  L: integer;
begin
  inc(ValueCount);
  L := ValueCount - 1;
  SetLength(Values, ValueCount);
  Values[L].Num := Num - 1;
  result := @(Values[L].Value);
end;

procedure TDefParamList.AddAString(const V: PAnsiChar; ParamNum: integer);
var
  L: integer;
begin
  L := _StrLen(V);
  TempParam := AddParam(ParamNum);
  TempParam.vt := VTYPE_PSTR;
  TempParam.VarEnum.vtRecString.strLen := L;
  TempParam.VarEnum.vtRecString.pstrVal := V;
end;

procedure TDefParamList.AddBool(V: boolean; ParamNum: integer);
begin
  TempParam := AddParam(ParamNum);
  TempParam.vt := VTYPE_BOOL;
  TempParam.VarEnum.bVal := V;
end;

procedure TDefParamList.AddDate(V: TDateTime; ParamNum: integer);
begin
  TempParam := AddParam(ParamNum);
  TempParam.vt := VTYPE_DATE;
  TempParam.VarEnum.date := V;
end;

procedure TDefParamList.AddDouble(V: double; ParamNum: integer);
begin
  TempParam := AddParam(ParamNum);
  TempParam.vt := VTYPE_R8;
  TempParam.VarEnum.dblVal := V;
end;

procedure TDefParamList.AddInt(V, ParamNum: integer);
begin
  TempParam := AddParam(ParamNum);
  TempParam.vt := VTYPE_I4;
  TempParam.VarEnum.intVal := V;
end;

procedure TDefParamList.AddWString(const V: PWideChar; ParamNum: integer);
var
  L: integer;
begin
  L := Length(V);
  TempParam := AddParam(ParamNum);
  TempParam.vt := VTYPE_PWSTR;
  TempParam.VarEnum.vtRecWideString.wstrLen := L;
  TempParam.VarEnum.vtRecWideString.pwstrVal := PWideChar(V);
end;

destructor TDefParamList.Destroy;
begin
  SetLength(Values, 0);
  inherited Destroy;
end;

procedure TDefParamList.AddUInt(V: Longword; ParamNum: integer);
begin
  TempParam := AddParam(ParamNum);
  TempParam.vt := VTYPE_UI4;
  TempParam.VarEnum.uintVal := V;
end;

{ TMethReg }

constructor TMethReg.Create;
begin
  DefParams := TDefParamList.Create;
end;

destructor TMethReg.Destroy;
begin
  DefParams.Free;
  inherited Destroy;
end;

{ TClassReg }

function TClassReg.AddFunc(MethName, MethNameLoc: WideString;
  ExecuteProc: PV8CallAsFunc; ParamCount: integer): TMethReg;
begin
  result := AddMethod(MethName, MethNameLoc, True, ExecuteProc, ParamCount);
end;

function TClassReg.AddProc(MethName, MethNameLoc: WideString;
  ExecuteProc: PV8CallAsProc; ParamCount: integer): TMethReg;
begin
  result := AddMethod(MethName, MethNameLoc, False, pointer(ExecuteProc),
    ParamCount);
end;

function TClassReg.AddMethod(MethName, MethNameLoc: WideString;
  IsFunction: boolean; ExecuteProc: pointer;
  ParamCount: integer = 0): TMethReg;
var
  L: integer;
begin
  inc(MethCount);
  L := MethCount - 1;

  SetLength(MethList, MethCount);

  MethList[L] := TMethReg.Create;
  MethList[L].MethName := MethName;
  MethList[L].MethNameLoc := MethNameLoc;
  MethList[L].IsFunction := IsFunction;
  MethList[L].ParamCount := ParamCount;
  MethList[L].Execute := ExecuteProc;
  result := MethList[L];
end;

procedure TClassReg.AddProp(PropName, PropNameLoc: WideString;
  IsReadable: boolean; IsWritable: boolean; PropGetSet: PV8PropertyGetSet);
var
  L: integer;
begin
  inc(PropCount);
  L := PropCount - 1;

  SetLength(PropList, PropCount);

  PropList[L] := TPropReg.Create;
  PropList[L].PropName := PropName;
  PropList[L].PropNameLoc := PropNameLoc;
  PropList[L].IsReadable := IsReadable;
  PropList[L].IsWritable := IsWritable;
  PropList[L].PropGetSet := pointer(PropGetSet);
end;

destructor TClassReg.Destroy;
var
  i: integer;
begin
  for i := 0 to PropCount - 1 do
  begin
    PropList[i].Free;
    PropList[i] := nil;
  end;

  for i := 0 to MethCount - 1 do
  begin
    MethList[i].Free;
    MethList[i] := nil;
  end;

  SetLength(PropList, 0);
  SetLength(MethList, 0);

  inherited Destroy;
end;

{ TClassRegList }

destructor TClassRegList.Destroy;
var
  i: integer;
begin
  for i := 0 to ClassCount - 1 do
  begin
    ClassList[i].Free;
    ClassList[i] := nil;
  end;
  SetLength(ClassList, 0);
  inherited Destroy;
end;

function TClassRegList.RegisterClass(UserClass: TClass;
  RegisterExtensionAs, NatApiClassName: WideString): TClassReg;
var
  L: integer;
begin
  inc(ClassCount);
  L := ClassCount - 1;

  SetLength(ClassList, ClassCount);

  ClassList[L] := TClassReg.Create;
  ClassList[L].UserClass := UserClass;
  ClassList[L].RegisterExtensionAs := RegisterExtensionAs;
  ClassList[L].NatApiClassName := NatApiClassName;
  result := ClassList[L];

  if Length(ClassNamesString) > 0 then
    ClassNamesString := ClassNamesString + '|';
  ClassNamesString := ClassNamesString + NatApiClassName;
end;

{ TV8UserObject }

constructor TV8UserObject.Create;
begin
    //
end;

destructor TV8UserObject.Destroy;
begin
  inherited Destroy;
end;

procedure TV8UserObject.Done;
begin
    //
end;

function TV8UserObject.GetInfo: integer;
begin
  result := 2000;
end;

function TV8UserObject.Init: boolean;
begin
  result := True;
end;

procedure TV8UserObject.SetLocale;
begin

end;

function TV8UserObject.SetMemManager: boolean;
begin
  result := True;
end;

function TV8UserObject.V8SetString(V: PV8Variant; Value: AnsiString): boolean;
begin
  result := V8SetPChar(V, PAnsiChar(Value));
end;

function TV8UserObject.V8AllocWideString(W: WideString): PWideChar;
begin
  result := _V8String(V8MM, W);
end;

function TV8UserObject.V8SetWString(V: PV8Variant;
  Value: WideString): boolean;
var
  L, SZ: longword;
begin
  result := (PWideChar(Value) = nil);
  if result then
    Exit;

  V8ClearVar(V);
  V.vt := VTYPE_PWSTR;
  L := Length(Value);
  SZ := (L * sizeof(WideChar)) + sizeof(WideChar);
  result := V8MM.AllocMemory(@(V.VarEnum.vtRecWideString.pwstrVal), SZ);
  if result then
  begin
    Move(Value[1], V.VarEnum.vtRecWideString.pwstrVal^, SZ);
    V.VarEnum.vtRecWideString.wstrLen := L;
  end;
end;

function TV8UserObject.V8SetPChar(V: PV8Variant; Value: PAnsiChar): boolean;
var
  L: longword;
begin
  result := (Value = nil);
  if result then
    Exit;

  V8ClearVar(V);
  V.vt := VTYPE_PSTR;
  L := _StrLen(Value);
  result := V8MM.AllocMemory(@(V.VarEnum.vtRecString.pstrVal), L + 1);
  if result then
  begin
    Move(Value^, V.VarEnum.vtRecString.pstrVal^, L + 1);
    V.VarEnum.vtRecString.strLen := L;
  end;
end;

procedure TV8UserObject.V8ClearVar(V: PV8Variant);
begin
  if (V.vt and VTYPE_TYPEMASK) in [VTYPE_BLOB, VTYPE_PSTR, VTYPE_PWSTR,
    VTYPE_INTERFACE] then
  begin
    case (V.vt and VTYPE_TYPEMASK) of
      VTYPE_BLOB:
        if V.VarEnum.vtRecString.pstrVal <> nil then
          V8MM.FreeMemory(@(V.VarEnum.vtRecString.pstrVal));
      VTYPE_PSTR:
        if V.VarEnum.vtRecString.pstrVal <> nil then
          V8MM.FreeMemory(@(V.VarEnum.vtRecString.pstrVal));
      VTYPE_PWSTR:
        if V.VarEnum.vtRecWideString.pwstrVal <> nil then
          V8MM.FreeMemory(@(V.VarEnum.vtRecWideString.pwstrVal));
      VTYPE_INTERFACE:
        IInterface(V.VarEnum.vtRecInterface.pInterfaceVal) := nil;
    end;
  end;
  FillChar(V^, sizeof(V8Variant), 0);
end;

procedure TV8UserObject.V8CopyVar(Source, Dest: PV8Variant);
var
  P: pointer;
  L: integer;
begin
  Dest^ := Source^;
  if (Dest.vt and VTYPE_TYPEMASK) in [VTYPE_BLOB, VTYPE_PSTR, VTYPE_PWSTR] then
  begin
    case (Dest.vt and VTYPE_TYPEMASK) of
      VTYPE_BLOB:
        if Dest.VarEnum.vtRecString.pstrVal <> nil then
          V8SetBlob(Dest, PByte(Dest.VarEnum.vtRecString.pstrVal), Dest.VarEnum.vtRecString.strLen);
      VTYPE_PSTR:
        if Dest.VarEnum.vtRecString.pstrVal <> nil then
        begin
          P := Dest.VarEnum.vtRecString.pstrVal;
          L := Dest.VarEnum.vtRecString.strLen + 1;
          V8MM.AllocMemory(@Dest.VarEnum.vtRecString.pstrVal, L);
          Move(P^, Dest.VarEnum.vtRecString.pstrVal^, L);
        end;
      VTYPE_PWSTR:
        if Dest^.VarEnum.vtRecWideString.pwstrVal <> nil then
        begin
          P := Dest.VarEnum.vtRecWideString.pwstrVal;
          L := (Dest.VarEnum.vtRecWideString.wstrLen * sizeof(widechar)) + sizeof(widechar);
          V8MM.AllocMemory(@Dest.VarEnum.vtRecWideString.pwstrVal, L);
          Move(P^, Dest.VarEnum.vtRecWideString.pwstrVal^, L);
        end;
    end;
  end;
end;


function TV8UserObject.V8SetBlob(V: PV8Variant; Value: PByte;
  Length: integer): boolean;
begin
  result := (Value = nil);
  if result then
    Exit;

  V8ClearVar(V);

  V.vt := VTYPE_BLOB;
  result := V8MM.AllocMemory(@(V.VarEnum.vtRecString.pstrVal), Length);
  if result then
  begin
    Move(Value^, V.VarEnum.vtRecString.pstrVal^, Length);
    V.VarEnum.vtRecString.strLen := Length;
  end;
end;

procedure TV8UserObject.V8SetDouble(V: PV8Variant; Value: double);
begin
  V8ClearVar(V);
  V.vt := VTYPE_R8;
  V.VarEnum.dblVal := Value;
end;

procedure TV8UserObject.V8SetInt(V: PV8Variant; Value: integer);
begin
  V8ClearVar(V);
  V.vt := VTYPE_I4;
  V.VarEnum.intVal := Value;
end;

procedure TV8UserObject.V8SetDate(V: PV8Variant; Value: TDateTime);
begin
  V8ClearVar(V);
  V.vt := VTYPE_DATE;
  V.VarEnum.date := Value;
end;

procedure TV8UserObject.V8SetBool(V: PV8Variant; Value: boolean);
begin
  V8ClearVar(V);
  V.vt := VTYPE_BOOL;
  V.VarEnum.bVal := Value;
end;


function V8AsBool(V: PV8Variant): boolean;
begin
  if (V.vt and VTYPE_TYPEMASK) = VTYPE_BOOL then
  begin
    result := V.VarEnum.bVal;
    Exit;
  end;
  if AsInteger(V) <> 0 then
    result := True
  else
    result := False;
end;

function V8EncodeDate(UT: PV8tm): TDateTime;
begin
  result := EncodeDate(UT.tm_year + 1900, UT.tm_mon + 1, UT.tm_mday) + EncodeTime
    (UT.tm_hour, UT.tm_min, UT.tm_sec, 0);
end;

function V8AsDate(V: PV8Variant): TDateTime;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_TM:
      result := V8EncodeDate(@(V.VarEnum.tmVal));
    VTYPE_DATE:
      result := V.VarEnum.date;
    VTYPE_R8:
      result := V.VarEnum.dblVal;
  else
    result := 0;
  end;
end;

function AsDouble(V: PV8Variant): double;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_I2:
      result := V.VarEnum.shortVal; // int16_t
    VTYPE_I4:
      result := V.VarEnum.intVal; // int32_t
    VTYPE_R4:
      result := V.VarEnum.fltVal; // float
    VTYPE_DATE:
      result := V.VarEnum.date; // DATE (double)
    VTYPE_UI1:
      result := V.VarEnum.ui8Val; // uint8_t
    VTYPE_ERROR:
      result := V.VarEnum.errCode; // int32_t
    VTYPE_PWSTR:
      begin
        try
          result := StrToFloat
            (WideCharToString(V.VarEnum.vtRecWideString.pwstrVal));
        except
          result := 0;
        end;
      end;
  else
    result := 0;
  end;
end;

function AsInteger(V: PV8Variant): integer;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_I4:
      result := V.VarEnum.intVal; // int32_t
    VTYPE_I2:
      result := V.VarEnum.shortVal; // int16_t
    VTYPE_R4:
      result := Trunc(V.VarEnum.fltVal); // float
    VTYPE_DATE:
      result := Trunc(V.VarEnum.date); // DATE (double)
    VTYPE_R8:
      result := Trunc(V.VarEnum.dblVal);
    VTYPE_UI1:
      result := V.VarEnum.ui8Val; // uint8_t
    VTYPE_ERROR:
      result := V.VarEnum.errCode;
    VTYPE_PWSTR:
      begin
        try
          result := StrToInt
            (WideCharToString(V.VarEnum.vtRecWideString.pwstrVal));
        except
          result := 0;
        end;
      end;
  else
    result := 0;
  end;
end;

function AsUInteger(V: PV8Variant): UInt;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_I4:
      result := V.VarEnum.intVal; // int32_t
    VTYPE_I2:
      result := V.VarEnum.shortVal; // int16_t
    VTYPE_R4:
      result := Trunc(V.VarEnum.fltVal); // float
    VTYPE_DATE:
      result := Trunc(V.VarEnum.date); // DATE (double)
    VTYPE_R8:
      result := Trunc(V.VarEnum.dblVal);
    VTYPE_UI1:
      result := V.VarEnum.ui8Val; // uint8_t
    VTYPE_UI4:
      result := V.VarEnum.uintVal;
    VTYPE_UI2:
      result := V.VarEnum.uintVal;
    VTYPE_ERROR:
      result := V.VarEnum.errCode;
    VTYPE_PWSTR:
      begin
        try
          result := StrToInt
            (WideCharToString(V.VarEnum.vtRecWideString.pwstrVal));
        except
          result := 0;
        end;
      end;
  else
    result := 0;
  end;
end;

function V8AsDouble(V: PV8Variant): double;
begin
  if (V.vt and VTYPE_TYPEMASK) = VTYPE_R8 then
    result := V.VarEnum.dblVal
  else
    result := AsDouble(V);
end;

function V8AsInt(V: PV8Variant): integer;
begin
  if (V.vt and VTYPE_TYPEMASK) = VTYPE_I4 then
    result := V.VarEnum.intVal
  else
    result := AsInteger(V);
end;

function V8AsPWideChar(V: PV8Variant): PWideChar;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_PWSTR:
      result := V.VarEnum.vtRecWideString.pwstrVal;
  else
    result := nil;
  end;
end;

function V8AsWString(V: PV8Variant): WideString;
begin
  result := V8AsPWideChar(V);
end;

function V8AsBlob(V: PV8Variant): PByte;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_BLOB:
      result := PByte(V.VarEnum.vtRecString.pstrVal);
  else
    result := nil;
  end;
end;

function V8AsPChar(V: PV8Variant): PAnsiChar;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_PSTR:
      result := V.VarEnum.vtRecString.pstrVal;
  else
    result := nil;
  end;
end;

function V8AsAString(V: PV8Variant): AnsiString;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_PSTR:
      result := V.VarEnum.vtRecString.pstrVal;
    VTYPE_PWSTR:
      begin
        WideCharLenToStrVar(V.VarEnum.vtRecWideString.pwstrVal,
          V.VarEnum.vtRecWideString.wstrLen, result);
      end;
  else
    result := '';
  end;
end;

function V8StrLen(V: PV8Variant): integer;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_PSTR, VTYPE_BLOB:
      result := V.VarEnum.vtRecString.strLen;
    VTYPE_PWSTR:
      result := V.VarEnum.vtRecWideString.wstrLen;
  else
    result := 0;
  end;
end;

function V8isEmpty(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) = VTYPE_EMPTY);
end;

function V8isNULL(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) = VTYPE_NULL);
end;

function V8isNumber(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) in [VTYPE_I4, VTYPE_I2, VTYPE_R4,
    VTYPE_R8, VTYPE_UI1, VTYPE_ERROR]);
end;

function V8isString(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) in [VTYPE_PWSTR, VTYPE_PSTR]);
end;

function V8isWString(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) = VTYPE_PWSTR);
end;

function V8isAString(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) = VTYPE_PSTR);
end;

function V8isBlob(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) = VTYPE_BLOB);
end;

function V8isDate(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) in [VTYPE_DATE, VTYPE_TM]);
end;

function V8isBool(V: PV8Variant): boolean;
begin
  result := ((V.vt and VTYPE_TYPEMASK) = VTYPE_BOOL);
end;

function V8VarTypeStr(V: PV8Variant): AnsiString;
begin
  case (V.vt and VTYPE_TYPEMASK) of
    VTYPE_EMPTY:
      result := 'VTYPE_EMPTY';
    VTYPE_NULL:
      result := 'VTYPE_NULL';
    VTYPE_I2:
      result := 'VTYPE_I2'; // int16_t
    VTYPE_I4:
      result := 'VTYPE_I4'; // int32_t
    VTYPE_R4:
      result := 'VTYPE_R4'; // float
    VTYPE_R8:
      result := 'VTYPE_R8'; // double
    VTYPE_DATE:
      result := 'VTYPE_DATE'; // DATE (double)
    VTYPE_TM:
      result := 'VTYPE_TM'; // struct tm
    VTYPE_PSTR:
      result := 'VTYPE_PSTR'; // struct str    string
    VTYPE_INTERFACE:
      result := 'VTYPE_INTERFACE'; // struct iface
    VTYPE_ERROR:
      result := 'VTYPE_ERROR'; // int32_t errCode
    VTYPE_BOOL:
      result := 'VTYPE_BOOL'; // bool
    VTYPE_VARIANT:
      result := 'VTYPE_VARIANT'; // struct V8Variant *
    VTYPE_I1:
      result := 'VTYPE_I1'; // int8_t
    VTYPE_UI1:
      result := 'VTYPE_UI1'; // uint8_t
    VTYPE_UI2:
      result := 'VTYPE_UI2'; // uint16_t
    VTYPE_UI4:
      result := 'VTYPE_UI4'; // uint32_t
    VTYPE_I8:
      result := 'VTYPE_I8'; // int64_t
    VTYPE_UI8:
      result := 'VTYPE_UI8'; // uint64_t
    VTYPE_INT:
      result := 'VTYPE_INT'; // int   Depends on architecture
    VTYPE_UINT:
      result := 'VTYPE_UINT'; // unsigned int  Depends on architecture  20
    VTYPE_HRESULT:
      result := 'VTYPE_HRESULT'; // long hRes   21
    VTYPE_PWSTR:
      result := 'VTYPE_PWSTR'; // struct wstr      22
    VTYPE_BLOB:
      result := 'VTYPE_BLOB'; // means in struct str binary data contain 23
    VTYPE_CLSID:
      result := 'VTYPE_CLSID'; // UUID                                   24
    VTYPE_STR_BLOB:
      result := 'VTYPE_STR_BLOB';
    VTYPE_ILLEGAL:
      result := 'VTYPE_ILLEGAL';
  else
    result := 'unknown type';
    Exit;
  end;

  if (V.vt and VTYPE_BYREF) = VTYPE_BYREF then
  begin
    result := result + ' by ref';
    Exit;
  end;
  if (V.vt and VTYPE_ARRAY) = VTYPE_ARRAY then
  begin
    result := result + ' array';
    Exit;
  end;
  if (V.vt and VTYPE_VECTOR) = VTYPE_VECTOR then
  begin
    result := result + ' vector';
    Exit;
  end;
end;

procedure TV8UserObject.V8SetUInt(V: PV8Variant; Value: Uint);
begin
  V8ClearVar(V);
  V.vt := VTYPE_UINT;
  V.VarEnum.uintVal := Value;
end;

function V8AsUInt(V: PV8Variant): Uint;
begin
  if (V.vt and VTYPE_TYPEMASK) = VTYPE_UINT then
    result := V.VarEnum.uintVal
  else
    result := AsUInteger(V);
end;

exports DestroyObject, GetClassNames, GetClassObject, SetPlatformCapabilities;


initialization

  _ProcRec.Init := @_Init;
  _ProcRec.setMemManager := @_setMemManager;
  _ProcRec.GetInfo := @_GetInfo;
  _ProcRec.SetLocale := @_SetLocale;
  _ProcRec.Done := @_Done;
  _ProcRec.RegisterExtensionAs := @_RegisterExtensionAs;
  _ProcRec.GetNProps := @_GetNProps;
  _ProcRec.FindProp := @_FindProp;
  _ProcRec.GetPropName := @_GetPropName;
  _ProcRec.GetPropVal := @_GetPropVal;
  _ProcRec.SetPropVal := @_SetPropVal;
  _ProcRec.IsPropReadable := @_IsPropReadable;
  _ProcRec.IsPropWritable := @_IsPropWritable;
  _ProcRec.GetNMethods := @_GetNMethods;
  _ProcRec.FindMethod := @_FindMethod;
  _ProcRec.GetMethodName := @_GetMethodName;
  _ProcRec.GetNParams := @_GetNParams;
  _ProcRec.GetParamDefValue := @_GetParamDefValue;
  _ProcRec.HasRetVal := @_HasRetVal;
  _ProcRec.CallAsProc := @_CallAsProc;
  _ProcRec.CallAsFunc := @_CallAsFunc;

  ClassRegList := TClassRegList.Create;

finalization

  ClassRegList.Free;

end.

