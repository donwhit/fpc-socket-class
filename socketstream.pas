{ Don Whitbeck 2009 - stream class for socket classes
basically just sets up the data structures for a stream type socket
family = PF_INET, type - SOCK_STREAM, protocol = IPPROTO_TCP 
  (IPPROTO_NONE  would work)}
  
Unit socketstream;
//{$linklib c}
{$mode objfpc}

Interface

Uses BaseUnix, unixtype,initc, errors, sysutils,
classes, strings, sockets, ctypes, socketclass;

Const 
  INVALID_SOCKET = -1;
  ONACCEPTED = 1;
  MAXBUFCNT  = 256;

Type 
  PCharBuffer = ^CharBuffer;
  CharBuffer = array[1..MAXBUFCNT] of char;

Type 
  TMsgInt = Record
    //MsgStr: string[65];
    MSGID: integer;
    Data: pointer;
  End;


Type 

  TStreamSocket = Class(TSocketClass)
    Protected 
      Procedure Init(APort: word);
    Public 
      constructor Create(Const aPort: word; IPAddress: String);
      destructor Destroy;
      override;
  End;


Implementation

constructor TStreamSocket.Create(Const aPort: word; IPAddress: String);
Begin
  inherited create(aPort, IPAddress);
  Init(aPort);
End;

Procedure TStreamSocket.Init(aPort: word);
Begin
  Port :=  aPort;
  Family := PF_INET;
  sType := SOCK_STREAM;
  Protocol := IPPROTO_TCP;
  SocketHandle := fpSocket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
End;

destructor TStreamSocket.Destroy;
Begin
  ClearSocket;
  inherited Destroy;
End;

End.
