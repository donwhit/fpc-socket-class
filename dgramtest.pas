//Test of datagran socket
//Using 127.0.0.1 it will write to itself
{$mode objfpc} 
program socketTest;
{$linklib c}

  
uses cthreads,BaseUnix,UnixType,sockets,
errors,sysutils,classes,ctypes, keyboard,socketdgram;


const
  BUFCNT = 10;
  PORT_TEST = 3335;
  IPADDR = '127.0.0.1';
  CR = #13;
  LF = #10;

Type
 PThreadFunction = ^TThreadFunction;
 TThreadFunction = function (p: pointer): LongInt;   
 TimeOutExcept = Class(Exception); //sysutils

type
  TDGramClass = class(TDataGramSocket)
   private
   // procedure doSomething(Sender: TObject);
   public
    // function EchoThread(p: pointer): PtrUInt;
	 constructor Create(APort: integer; IPAddress: String); 
	 function RecvDGram: String; 
	 function SendDGram(S: String): Integer;
end;	
   
var
  MySocket: TDgramClass;
  SendThreadFunction: TThreadFunction;
  RecvThreadFunction: TThreadFunction;
  RecvThrd, SendThrd: TThreadID;

constructor TDGramClass.Create(APort: integer; IPAddress: String);  
begin
  inherited create(APort, IPAddress);
end;									


function getString(var S: String):integer;
var
  C: char;
  cnt: Integer;
  k: TKeyEvent;
begin
  S := '';
  C := #0;
  cnt := 0;
  While C <> CR do
    begin
	  k := getKeyEvent;
	  K:=TranslateKeyEvent(K);
	  C := getKeyEventChar(k);
	  write(C);
	  if C = 'Q' then
	    begin
		  result := -1;
          S :='q';
		  exit;
		end;
	  S := S + C;
	  inc(cnt);
	end; 
result := cnt; 
	
end;   
   						
function TDGramClass.RecvDGram: String; 
var
  Recvd: Integer;
  S: String;
 begin
   Recvd := 0;
   while (Recvd = 0) do 
    begin
	  Recvd := recvUDP(S);
	  If Recvd > 0 then
	    RecvDGram := S;
	 end;
end;
	 
function TDGramClass.SendDGram(S: String): Integer;
var 
  Sent: Integer;	
begin 
  Sent := 0;
  While (Sent = 0) do
    begin
	  Sent := SendUDP(S);   
	  If Sent <> 0 then
	    SendDGram := Sent;
	end;
end;		


function RecvThread(p: pointer): PtrUInt; 
var
  S: String;
begin
  while (1 <> 2) do
    begin
	  S := MySocket.RecvDGram;
	  write('Received ',S);
	  RecvThread := Length(S);
	end;
end;

function SendThread(p: pointer): PtrUInt;
var
  S: String;
  cnt: integer;
begin
  while (1<>2) do
    begin
     cnt := getString(S);
     if S = 'q' then
	  begin
	   //EndThread(0);
	   //killThread(RecvThrd);
	    SendThrd := 0;
		exit;
	  end; 
     if cnt > 0 then
       cnt := MySocket.SendDGram(S);
     Writeln(S);
	 SendThread := Length(S);
   end;	 
end;
   
begin
  InitKeyboard;
  MySocket := TDGramClass.Create(PORT_TEST, IPADDR);
  RecvThreadFunction :=  TThreadFunction(@RecvThread);
  SendThreadFunction :=  TThreadFunction(@SendThread);
  RecvThrd := BeginThread(RecvThreadFunction,nil);
  SendThrd := BeginThread(SendThreadFunction,nil);
  while (SendThrd<>0) do
    begin
	end;  
  KillThread(RecvThrd);
  donekeyboard; 
  MySocket.Destroy;
end.  
