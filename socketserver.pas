{ Don Whitbeck 2009 - server class inheriting from stream class
implements the listen function and creates threads for listening 
  to multiple clients. The create function has a BufCount parameter
  an array of pointers to records(type tBuffer) of length BufCount
  is created. The tBuffer records have an input and output buffer,
  a socket ID (for client socket), a thread IF and an index to the 
  pointer array.
A way needs to be developed to specify the size of the I/O buffers,
  for now it is just a constant.  
  If a client stops communicating for a time, the thread exits and the
  client's record is available for re-use.}
  
Unit socketserver;
//{$linklib c}
{$mode objfpc}

Interface

uses BaseUnix, unixtype,initc, errors, sysutils,
classes, strings, sockets, ctypes, socketstream;

const
    ONACCEPTED = 1;
  MAXBUFCNT  = 256;
	
Type
   TMsgInt = record
        //MsgStr: string[65];
	    MSGID: integer;
		Data: pointer;
    end;
		
Type 
  pThreadDesc = ^TThreadDesc;
  TThreadDesc = array Of integer;
  PThreadFunction = ^TThreadFunction;
  TThreadFunction = Function (p: pointer): LongInt;
  pcBuffer = ^cBuffer;
  cBuffer = array[1..256] Of char;

Type 
  pBuffer = ^tBuffer;
  tBuffer = Record
    recvBuf: pcBuffer;  //array of char;
    sendBuf: pcBuffer;  //array of char;
    SockNo: TSocket;
    ThreadID: Integer;
    BufIndex: integer;
  End;

Type 
  pBufferArray = array of pBuffer;
  TSocketAcceptEvent = Procedure (Sender: TObject) of object;

  TServerSocket = Class(TStreamSocket)
    Protected 
      fbufCnt: integer;
      fThreadCnt: integer;
      fCriticalSection : TRTLCriticalSection;
      fThreadFunction: TThreadFunction;
      fClientCount: integer;
      fPbufferArray: pBufferArray;
      fPThreadArray:  pThreadDesc;
      fOnAccept       : TSocketAcceptEvent;
	 
      Procedure AcceptHandler(Var Msg: TMsgInt);
      Message  ONACCEPTED;

    Public 
      constructor Create(Const BufCount, APort: integer; IPAddress: String);
      Procedure Init(APort: word);
      Procedure TriggerAccept;
      destructor Destroy;
      override;
      Procedure setClientCount(Const Cnt: Integer);
      Function  ListenSocket: LongInt;
      property ClientCount: integer read fClientCount write setClientCount;
      property ThreadCnt: integer read fThreadCnt;
      property bufCnt: integer read fbufCnt;
      property ThreadFunction: TThreadFunction read fThreadFunction write fThreadFunction;


      property  OnAccept: TSocketAcceptEvent read FOnAccept write  FOnAccept;
  End;

Implementation

constructor TServerSocket. Create(Const BufCount, APort: integer;
                                  IPAddress: String);

Var 
  I: Integer;
Begin
  inherited create(APort, IPAddress);
  fbufCnt := BufCount;
  fThreadCnt := BufCount;
  setlength(fPBufferArray,BufCount);
  new(fPThreadArray);
  setLength(fPThreadArray^,BufCount);

  For I := 1 To BufCount Do
    //Create BufCount Recv and Send buffers
    Begin
      new(fpBufferArray[I]);
      new(fpBufferArray[I]^.recvBuf);
      new(fpBufferArray[I]^.sendBuf);
      fpBufferArray[I]^.bufIndex := I;
    End;
  init(APort);
End;

Procedure TServerSocket.Init(aPort: word);
Begin
  SetClientCount(0);
  //number of clients, bufcnt MAX
  fSocketHandle := SocketHandle;
  BindSocket;
  ListenSocket;
End;


Function TServerSocket.ListenSocket: LongInt;
Begin
  ListenSocket := fplisten(SocketHandle,fBufCnt);
  If ListenSocket < 0 Then
    Perror('Couldnt listen to socket ',SocketHandle);
End;


Procedure TServerSocket.TriggerAccept;
Begin
  If Assigned(FOnAccept) Then
    FOnAccept(self);
End;

Procedure TServerSocket.AcceptHandler(Var Msg:TMsgInt);

Var 
  I: Integer;
  J: DWord;
  SockDesc: TSocket;
Begin
  If ClientCount >= BufCnt Then exit;
  SockDesc := Integer(Msg.Data^);

  For I := 1 To fBufCnt Do
    If fPBufferArray[I]^.SockNo <= 0 Then
      Begin
        fpBufferArray[I]^.SockNo := SockDesc;
        fpBufferArray[I]^.BufIndex := I;
        ClientCount := ClientCount + 1;
        J := BeginThread(ThreadFunction,fpBufferArray[I]);

        fpBufferArray[I]^.ThreadID := J;
        exit;
      End;
End;

Procedure TServerSocket.setClientCount(Const Cnt: Integer);
Begin
  If (Cnt > 0) And (Cnt <= fBufCnt) Then
    fClientCount := Cnt;
End;

destructor TServerSocket.Destroy;

Var 
  I: integer;
Begin
  For I := 1 To fbufCnt Do
    Begin
      writeln('Destroyed');
      dispose(fpBufferArray[I]);
      dispose(fpBufferArray[I]^.recvBuf);
      dispose(fpBufferArray[I]^.sendBuf);
    End;
  dispose(fpThreadArray);
  //ClearSocket;
  inherited Destroy;
End;



End.
