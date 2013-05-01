
{ Don Whitbeck 2009 - client class datagram inheriting from socket class
implements a receive buffer and a send buffer.
A way needs to be developed to specify the buffer sizes.
There are functions to send and receive strings which encapsulate 
   RecvFrom and SendTo.
Strings are broken up based upon buffer lengths. This could be changed
to breaking on a EOS character.   
Error procedures need to be developed.}
   

Unit socketdgram;
//{$linklib c}
{$mode objfpc}

Interface

Uses BaseUnix, unixtype,initc, errors, sysutils, keyboard,
classes, strings, sockets, ctypes, socketclass;

Type 
  PCharBuffer = ^CharBuffer;
  CharBuffer = array[1..MAXBUFCNT] of char;

Const 
  MAXSTRLEN = 1024;

Type 
  TDataGramSocket = Class(TSocketClass)
    Private 
      pRecvBuf: PCharBuffer;
      pSendBuf: PCharBuffer;
      fsockLen: LongWord;
    Public 
      constructor Create(Const aPort: word; IPAddress: String);
      destructor  Destroy;
      override;
      Procedure   init(Aport: word);
      Function    SendUDP(str: String): integer;
      Function    RecvUDP(Var str: String): Integer;
  End;


Implementation

constructor TDatagramSocket.Create(Const aPort: word; IPAddress: String);
Begin
  inherited create(aPort, IPAddress);
  fProtocol := IPPROTO_UDP;
  Init(aPort);
  new(pRecvBuf);
  new(pSendBuf);
End;

Procedure TDatagramSocket.Init(aPort: word);
Begin
  Port :=  aPort;
  sType := SOCK_DGRAM;
  Protocol := IPPROTO_UDP;
  fSocketHandle := SocketHandle;
  if BindSocket < 0 then
    begin
    donekeyboard;
      halt;
	end; 
  fSockLen := sizeOf(SockAddr);
end;

Function TDataGramSocket.SendUDP(str: String): integer;

Var 
  SB : CharBuffer;
  LS, RS: String;
  SCnt, Sck, sent, total: Integer;
Begin

  If (pSendBuf = Nil) Or (fSocketHandle <= 0) Then
    Begin
      //make an error
    End;
  SB := pSendBuf^;
  SCnt := length(str);
  RS := str;
  total := 0;
  While (SCnt > 0) Do
    Begin
      LS := Copy(RS,1,MAXBUFCNT-3);
      Sck := StrToArray(LS,SB);
      If Sck <= 0 Then
        break;
      sent := fpSendTo(fSocketHandle,@SB,Sck,0,@fAddress,sizeof(fAddress));
      total := sent + total;
      SCnt := SCnt - (sent-3);
      RS := copy(RS,SCnt+1,MAXSTRLEN);
    End;
  result := total;
End;

Function TDataGramSocket.RecvUDP(Var str: String): Integer;

Var 
  CBuff : CharBuffer;
  recv,Ln: Integer;
  SAddrFrom: Sockaddr;
Begin

  Ln := sizeof(SockAddr);

  CBuff := pSendBuf^;
  If (pSendBuf = Nil) Or (fSocketHandle <= 0) Then
    Begin
      //make an error
    End;
  recv := fpRecvFrom(fSocketHandle,@CBuff,MAXBUFCNT,0,@SAddrFrom,@Ln);
  str := ArrayToStr(CBuff,Recv);
  result := recv;
End;


destructor TDataGramSocket.Destroy;
Begin
  dispose(pRecvBuf);
  dispose(pSendBuf);
  ClearSocket;
  inherited Destroy;

End;



End.
