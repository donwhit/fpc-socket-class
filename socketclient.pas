{ Don Whitbeck 2009 - client class inheriting from stream class
implements the connect function and a receive buffer and a send buffer
A way needs to be developed to specify the buffer size.
For now it is a constant.}

Unit socketclient;
//{$linklib c}
{$mode objfpc}

Interface

Uses BaseUnix, unixtype,initc, errors, sysutils,
classes, strings, sockets, ctypes, socketstream;

Const 
  ONCONNECTED = 2;

Type 
  TSocketConnectEvent = Procedure (Sender: TObject) Of object;

  TClientSocket = Class(TStreamSocket)
    Protected 
      fServerSocket        : TSocket;
      fServerAddress       : TInetSockAddr;
      fpRecvBuf            : PCharBuffer;
      fpSendBuf            : PCharBuffer;
      fDotServerAddress    : shortString;
      // Ex: 192.168.1.5
      fOnConnect           : TSocketConnectEvent;

      Procedure setServerAddress(dotAddress: String);
      Function  getServerAddress: string;
      Procedure ConnectHandler(Var Msg: TMsgInt);
      Message  ONCONNECTED;
      //just a test
      Function  ConnectSocket: Integer;
    Public 
      constructor Create(APort: integer; IPAddress, IPServerAddress: String);
      Procedure Init(APort: word);
      property  ServerAddress: string read getServerAddress write setServerAddress;
      Procedure TriggerConnect;
      destructor Destroy;
      override;
      property  ServerSocket: TSocket read fServerSocket write fServerSocket;
      property  OnConnect: TSocketConnectEvent read FOnConnect write  FOnConnect;
      property  RecvBuf: PCharBuffer read  fpRecvBuf;
      property  SendBuf: PCharBuffer read  fpSendBuf;
  End;


Implementation



Procedure TClientSocket.ConnectHandler(Var Msg:TMsgInt);

Var 
  SockDesc: TSocket;

Begin
  SockDesc := Integer(Msg.Data^);
End;

constructor TClientSocket.Create(APort: integer;
                                 IPAddress, IPServerAddress: String);
Begin
  inherited create(APort, IPAddress);
  Init(Aport);
  fDotServerAddress := IPServerAddress;
  new(fpRecvBuf);
  new(fpSendBuf);
End;

Procedure TClientSocket.Init(aPort: word);
Begin
  //inherited Init(aPort);
  fSocketHandle := SocketHandle;
  //connectSocket;
  If fDotServerAddress = '' Then
    ServerAddress := fDotServerAddress;
  fServerAddress.sin_port := fAddress.sin_port;
  fServerAddress.sin_family := fAddress.sin_family;
  ServerSocket := ConnectSocket;
  If ServerSocket < 0 Then
    Perror('Connect Error ',ConnectSocket);
  //make an error here

End;

Function TClientSocket.ConnectSocket: cint;
Begin
  ConnectSocket := fpConnect(SocketHandle,@fServerAddress,Sizeof(SockAddr_in));
  If ConnectSocket < 0 then
    WriteError('Client failed to connect in - ','Class ClientSocket');
End;

Function TClientSocket.getServerAddress: string;
Begin
  getServerAddress := NetAddrToStr(fServerAddress.sin_addr);
End;

Procedure TClientSocket.setServerAddress(dotAddress:String);
Begin
  If CheckStateClosed('SetAddress') Then
    Begin
      fDotServerAddress := dotAddress;
      fServerAddress.sin_addr := StrToNetAddr(dotAddress);
    End;
End;


Procedure TClientSocket.TriggerConnect;
Begin
  If Assigned(FOnConnect) Then
    FOnConnect(self);
End;

destructor TClientSocket.Destroy;
Begin
  dispose(fpRecvBuf);
  dispose(fpSendBuf);
  inherited Destroy;
End;
End.
