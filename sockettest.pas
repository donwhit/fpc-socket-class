// build a simple echo server using the TSocketServer class
// With a fixed number of threads (BufCount)
{$mode objfpc} 
program socketTest;
{$linklib c}

  
uses cthreads,BaseUnix,UnixType,sockets,
errors,sysutils,classes,ctypes, socketserver;


const
  BUFCNT = 10;
  PORT_TEST = 3335;
  IPADDR = '127.0.0.1';
  CR = #13;
  LF = #10;
Type TimeOutExcept = Class(Exception); //sysutils

type
  TAcceptClass = class(TServerSocket)
   private
   // procedure doSomething(Sender: TObject);
   public
     //create a class inheriting from TServerSocket 
   //With Bufcount buffers and threads, using port as integer and IP as string
	 constructor Create(const BufCount, APort: integer; IPAddress: String); 
end;	
   
var
  MySocket: TAcceptClass;
  MySockDesc, clientSock: TSocket;
  MyAddr:TInetSockAddr;
  MyLen: Integer;
  MyMsg: TMsgInt;
  
function compareBye( buf: cBuffer; len:integer): integer;
// Hang up on the word 'bye'
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

constructor TAcceptClass. Create(const BufCount, APort: integer;
                                    IPAddress: String);  
begin
  inherited create(Bufcount, APort, IPAddress);
end;									

 Procedure DoSig(sig : cint);cdecl;
begin
    writeln('Alarm timed out ', sig);
end;
									
function EchoThread(p: pointer): PtrUInt; 
var
  Received, Sent:LongInt;
  Tmp,Errnum: Integer;
  TID: TTHreadID;
  tr, ts: timeval;
  
 begin
 tr.tv_sec := 12;
 tr.tv_usec := 0;
 ts.tv_sec := 2;
 ts.tv_usec := 0;
 
  //Set up time outs - shut off a client if it is idle too long
  fpsetsockopt(tBuffer(p^).SockNo,SOL_SOCKET,SO_RCVTIMEO, @tr, sizeof(timeval));
  fpsetsockopt(tBuffer(p^).SockNo,SOL_SOCKET,SO_SNDTIMEO, @ts, sizeof(timeval));
  TID := GetCurrentThreadID;
  sent := 1;
  while (sent > 0) do
    begin
	  received := fprecv(tBuffer(p^).SockNo, @(tBuffer(p^).recvBuf^),MAXBUFCNT,0);
	  Errnum:= fpGetErrNo;
	  if Errnum <>0 then
        writeln(sys_errlist[Errnum],' - error');
	  Tmp:=Received;
	  Sent := 0;		
	  while (Tmp > 0) do
	    begin
		  //echo what is recieved
	      Sent := fpsend(tBuffer(p^).SockNo,@(tBuffer(p^).recvBuf^), Received,0);
 	      Errnum := fpGetErrNo;
		  if ERrnum <> 0 then
		    writeln('fpGetErrNo = ',Errnum);
			
          if (sent <= 0) then
		    perror('Recv error - ',SocketError);	
          Tmp := Tmp - sent;
	    end; //while	  
	   
      if (sent > 0) and (compareBye((tBuffer(p^).recvBuf^),Received) > 0) then
		    sent := 0;
		  
   end; //while
   
    
  tBuffer(p^).SockNo := 0; //Free up this buffer
  tBuffer(p^).bufIndex := 0;
  tBuffer(p^).ThreadID := 0;
  EchoThread := PtrUInt(TID);
  EndThread(TID);

end; 
  
begin
  MySocket := TAcceptClass.Create(BUFCNT, PORT_TEST, IPADDR);
  MySockDesc:=MySocket.sockethandle;
  MySocket.ThreadFunction := TThreadFunction(@EchoThread);
 
 // for testing
   MyAddr.sin_family :=AF_INET ;
   MyAddr.sin_port := htons(3335); 
   MyAddr.sin_addr.s_Addr:=LongInt(StrToHostAddr('127.0.0.1'));
   MyLen := sizeOf(TInetSockAddr);
 while 1 <> 2 do
   begin
   clientSock := fpaccept(MySockDesc,@MyAddr,@MyLen); 
   If clientSock > 0 then
     begin 
	   MyMsg.MSGID := ONACCEPTED;
       MyMsg.Data := @clientSock;
	   	  writeln('Dispatch');
	  MySocket.dispatch(MyMsg);

	end; 
 end;	

 // MySocket.OnAccept:=@MySocket.Testwrite;
 // MySocket.TriggerAccept;
  Writeln('ToDestroy');
  MySocket.Destroy;
end.  
