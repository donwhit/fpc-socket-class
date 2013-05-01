{ Don Whitbeck 2009 - Basic class for socket classes
implements basic data structure - TINetSockaddr (sockaddr_in)
containing family,  port and internet address (in_addr = s_addr  or s_bytes)
it has fields for protocol(IPPROTO_NONE, IPPROTO_TCP or IPPROTO_UDP)
   Domain(Usually PF_INET)
   Type(SOCK_STREAM, SOCK_DGRAM,  SOCK_RAW)
it has properties to manipulate these fields
it has the socket fuction and the bind function
it has a state mechanism - needs to be developed further
error mechanisms need to be developed further}
   
unit socketclass;
//{$linklib c}
{$mode objfpc} 
interface
 uses BaseUnix, unixtype,initc, errors, sysutils, classes, strings, sockets, ctypes;

const 
  INVALID_SOCKET = -1;
  MAXBUFCNT  = 256;
  CR = #13;
  LF = #10;
 
   
Type
   TMsgInt = record
      MSGID: integer;
		Data: pointer;
    end;
Type
     
  TSocketState = (TCP_Dummy,TCP_Established, TCPSyn_Sent, TCPSyn_Recvd, TCPFin_Wait1,
                  TCPFin_Wait2, TCP_TimeWait, TCP_Closed, TCP_Close_Wait,
				  TCP_Last_Ack, TCP_Listen, TCP_Closing, TCP_Max_States); 
				
  SocketClassExcep = Class(Exception);  
  TSocketClass = class;

  TSocketAcceptEvent =      procedure(Sender: TObject) of object;
  TSocketEvent =            procedure(Sender: TObject) of object;
  TSocketStateChangeEvent = procedure(Sender: TSocketClass; 
                                      OldState, NewState: TSocketState) of object;		

  TSocketClass = class(TObject)
  protected
      fAddress       : TInetSockAddr;
	  fSocketLen     : longword;
	  fDomain        : longint;
	  fType          : cint;
	  fProtocol      : cint;
	  fDotAddress    : shortString;        // Ex: 192.168.1.5
	  fSocketHandle  : TSocket;
      fOnError       : TSocketEvent;
      fErrorCode     : Integer;
      fErrorMessage  : String;
	
	  fState         : TSocketState;
      fOnStateChange : TSocketStateChangeEvent;  //Use in sub classes
	
	
	procedure DestroySocketHandle;
	function  GetErrorMessage: String;
	procedure SetState(const State: TSocketState);
   	
	procedure setAddress(dotAddress: String);
	function  getAddress: string;
	procedure SetDomain(const Domain: cint);
	procedure SetProtocol(const Protocol: cint);
	procedure SetType(const sType: cint);
	function  GetType:cint;
	procedure SetFamily(const Family: sa_family_t);
    function  GetFamily: sa_family_t;
	procedure setPort(const LocalPort: word);
	function  getPort:word; 
    function  IsSocketConnected: Boolean; virtual;
	
   public
	 constructor Create(const aPort: word; IPAddress: String);
	 destructor Destroy; override;
	 function  CheckStateClosed(const Operation: String): boolean; 
	 procedure ClearSocket;
   	 procedure TriggerStateChange(const OldState, State: TSocketState); virtual;
     function  GetSocketHandle: TSocket;
     procedure SetSocketHandle(const SocketHandle: TSocket);
	 function  strToArray(S: string; var A: array of char): integer;
	 function  arrayToStr(A: array of char; lng: integer): string;
	 function  BindSocket: LongInt;
	 procedure WriteError(Gen, Op: String);

	 property  ErrorCode: Integer read FErrorCode;
     property  ErrorMessage: String read GetErrorMessage;
	 property  SocketHandle: TSocket read GetSocketHandle write SetSocketHandle;
	 property  Address: string read getAddress write setAddress;
	 property  Family: sa_family_t read GetFamily write SetFamily;
     property  Protocol: cint read fProtocol write SetProtocol;
	 property  Domain: cint read fDomain write SetDomain;
	 property  sType: cint read getType write SetType;
     property  Port: word read GetPort write SetPort;
	 property  State: TSocketState read FState;
	 property  OnStateChange: TSocketStateChangeEvent 
	           read FOnStateChange write FOnStateChange;
end;

  
implementation	
 
 constructor TSocketClass.Create(const aPort:word; IPAddress: String);   
    begin
   	inherited create;
	 fState := TCP_Closed;
     Address := IPAddress;
     fSocketHandle := INVALID_SOCKET;
   end;


procedure TSocketClass.ClearSocket;
begin
  FState := TCP_Closed;
  DestroySocketHandle;
end;

procedure TSOcketClass.WriteError(Gen, Op: String);
begin
  write(Gen);
  writeln(Op);
end;

function TSocketClass.GetErrorMessage: String;
begin
  // no error
  if FErrorCode = 0 then
    Result := ''; 
end;

function TSocketClass.BindSocket: LongInt;
begin
  BindSocket := -1;
  BindSocket := fpbind(fSocketHandle, @fAddress, sizeof(fAddress));
	If BindSocket < 0 then
	  WriteError('Bind socket failed  in class - ','Socketclass');
end;
  
procedure TSocketClass.TriggerStateChange(const OldState, State: TSocketState);
begin
  if Assigned(FOnStateChange) then
    FOnStateChange(self, OldState, State);
end;

procedure TSocketClass.SetState(const State: TSocketState);
var
 OldState : TSocketState;
begin
  if State = FState then
    exit;
  OldState := FState;
  FState := State;
  TriggerStateChange(OldState, State);
end;

function TSocketClass.CheckStateClosed(const Operation: String): boolean;
begin
   result:= true;
  if fState <> TCP_Closed then
    begin
      result := false;
 	  WriteError('Socket handle can not be set on open socket: ',Operation);
    end;		  
end;

procedure TSocketClass.SetSocketHandle(const SocketHandle: TSocket);
begin
  if SocketHandle = fSocketHandle then
    exit;
  if not (FState in [TCP_Closed]) then
    raise SocketClassExcep.create('Socket was open, but handle is being changed.');
  DestroySocketHandle;
  fSocketHandle := SocketHandle;
end;

function TSocketClass.GetSocketHandle: TSocket;
begin
  if fSocketHandle = INVALID_SOCKET then
     begin
	  If (fProtocol = IPPROTO_IP) or (fProtocol = IPPROTO_TCP) then
	     Result := fpSocket(PF_INET, SOCK_STREAM, fProtocol)
	  else if (fProtocol = IPPROTO_UDP) then
  	       Result := fpSocket(PF_INET, SOCK_DGRAM, fProtocol);
	  end
  else
    result := fSocketHandle;  
  If result = INVALID_SOCKET then
    WriteError('Open socket failed - ','in TSocketclass');
end;

procedure TSocketClass.DestroySocketHandle;
var 
  Sock : TSocket;
begin
  Sock := FSocketHandle;
  if Sock = INVALID_SOCKET then
    exit;
  FSocketHandle := INVALID_SOCKET;
  CloseSocket(Sock);
end;

procedure TSocketClass.SetFamily(const Family: sa_family_t);
begin
  if CheckStateClosed('SetFamily') then
     fAddress.sin_family := Family;
end;


function TSocketClass.GetFamily: sa_family_t;
begin
 getFamily := fAddress.sin_family;
end;  
 
function TSocketClass.GetType: cint;
begin
    getType := fType;
end;

procedure TSocketClass.SetDomain(const Domain: cint);
begin
  if CheckStateClosed('SetDomain') then
    fDomain := sType;
end;

procedure TSocketClass.SetType(const sType: cint);
begin
  if CheckStateClosed('SetType') then
    fType := sType;
end;

procedure TSocketClass.SetProtocol(const Protocol: cint);
begin
  if CheckStateClosed('SetProtocol') then
    fProtocol := Protocol;
end;

function TSocketClass.IsSocketConnected: Boolean;
begin
  Result := fState in [TCP_Established];
end;

  function TSocketClass.getPort: word;
   begin
     Result := ntohs(fAddress.sin_port);
   end;

   procedure TSocketClass.setPort(const LocalPort: word);
   begin
     if CheckStateClosed('SetPort') then
       fAddress.sin_port := htons(LocalPort);
   end;
   		
   function TSocketClass.getAddress: string;
   begin
     getAddress:= NetAddrToStr(fAddress.sin_addr);
   end;
    	
   procedure TSocketClass.setAddress(dotAddress:string);
   begin
 	 if CheckStateClosed('SetAddress') then
	   begin
         fDotAddress := dotAddress;
		 If dotAddress = '' then
		   fAddress.sin_addr.s_addr := INADDR_ANY
		 else  
           fAddress.sin_addr := StrToNetAddr(dotAddress);
	end;	 
   end;

function TSocketClass.strToArray(S: string; var A: array of char): integer;
var
  I: Integer;
begin
  I := 0;
  If length(S) < (length(A) + 3) then
    begin
      for I := 1 to length(S) do
	    A[I] := S[I];
	  A[I+1] := LF;
	  A[I+2] := CR;	
	  A[I+3] := #0;
	end;  	
  strToArray := I+3; 
end; 

function TSocketClass.arrayToStr(A: array of char; lng: integer): string;
var
  I: Integer;
  Res: string;
begin
  Res := '';
  for I := 1 to lng do
    begin 
	  Res := Res+ A[I];
	  if A[I] = #0 then break;
	end; 
	arrayToStr:=Res;
end;  

  
 destructor TSocketClass.Destroy;
  begin
  // InitCriticalSection(fCriticalSection); 
	ClearSocket;
	inherited Destroy;
		
	//DoneCriticalSection(fCriticalSection);	
end;



end.
