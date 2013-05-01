//Create a test class - send input from keyboard to echo server
{$mode objfpc} 
program clientTest;
{$linklib c}

  
uses cthreads,BaseUnix,UnixType,sockets,strings,
socket,errors,sysutils,classes,ctypes,socketstream,socketclient;


const
  BUFCNT = 10;
  PORT_TEST = 3335;
  IPADDR = '127.0.0.1';
  CR = #13;
  LF = #10;
  


type
  TClientClass = class(TClientSocket)
   private
       // procedure doSomething(Sender: TObject);
   public
    // function EchoThread(p: pointer): PtrUInt;
   constructor Create(APort: integer; IPAddress, IPServerAddress: String); 
	 procedure init;
end;	
   
  var
  CStr, OutStr: String;
  CLen: Integer;  
  ASocket: TSocket;
  Sent, Received, Bytes: Integer;
  myClient: TClientClass;
  MySendBuf, MyRecvBuf: PCharBuffer;
    
constructor TClientClass.Create(APort: integer; IPAddress, IPServerAddress: String);  
begin
  inherited create(APort, IPAddress, IPServerAddress);
  init;
end;									

procedure TClientClass.init;
begin
  ASocket := SocketHandle;
end;

function compareBye( buf: cBuffer; len:integer): integer;
 var
   I: Integer;
begin
  compareBye := 0; 

  for I := 1 to Len do
    begin
	  if (buf[I] = 'b') and ((I + 3) < len) then
	    if ((buf[I+1] = 'y') and (buf[I+2] = 'e' )) and 
		   ((buf[I+3] = CR) or (buf[I+3] = LF)) then
		      begin
		        compareBye := I;
				exit;//break;
			  end;	
	end;	
end; 


begin
 
   MyClient := TClientClass.Create(PORT_TEST, IPADDR, IPADDR);
   MySendBuf := MyClient.SendBuf;
   MyRecvBuf := MyClient.RecvBuf;
   Sent := 1;
 while(Sent > 0) do
   begin
       readln(CStr);
	   OutStr:='';
	 //CStr := 'This is a string. ';
     //Sleep(250);

    CStr:=CStr+#13+#10;
	CLen:=Length(CStr)+1;
	StrPCopy(PChar(MySendBuf),CStr);
    sent :=fpsend(ASocket, MySendBuf, CLen, 0); 
	received := 0;
            while (received < CLen) do
			  begin
                bytes := fprecv(ASocket, MyRecvbuf, BUFCNT, 0); 
			    if (bytes < 0) then
                  Writeln('Failed to receive bytes from server');
				OutStr := OutStr + strpas(PChar(MyRecvBuf));  
                received := received + bytes;
			  end;
			  writeln('Returned ',OutStr);
              //writeln('Returned ',OutStr,' ',trunc(random*100));
			  
	if (sent > 0) and (compareBye(MySendBuf^,sent) > 0) then
		    sent := 0;
	end;		
end.
