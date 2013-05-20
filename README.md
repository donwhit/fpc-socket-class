fpc-socket-class
================

socket class for free pascal / lazarus


socketclass.pas  - Base class for socket classes -implements basic data structure - TINetSockaddr (sockaddr_in)
containing family,  port and internet address (in_addr = s_addr  or s_bytes)
it has fields for protocol(IPPROTO_NONE, IPPROTO_TCP or IPPROTO_UDP)
   Domain(Usually PF_INET)
   Type(SOCK_STREAM, SOCK_DGRAM,  SOCK_RAW)
it has properties to manipulate these fields
it has the socket function and the bind function
it has a state mechanism - needs to be developed further
error mechanisms need to be developed further

socketclient.pas - client class inheriting from stream class
implements the connect function and a receive buffer and a send buffer
A way needs to be developed to specify the buffer size.
For now it is a constant

socketserver.pas -server class inheriting from stream class
implements the listen function and creates threads for listening 
  to multiple clients. The create function has a BufCount parameter
  an array of pointers to records(type tBuffer) of length BufCount
  is created. The tBuffer records have an input and output buffer,
  a socket ID (for client socket), a thread IF and an index to the 
  pointer array.
A way needs to be developed to specify the size of the I/O buffers,
  for now it is just a constant.  
  If a client stops communicating for a time, the thread exits and the
  client's record is available for re-use.
  
  socketstream.pas - stream class for socket classes
basically just sets up the data structures for a stream type socket
family = PF_INET, type - SOCK_STREAM, protocol = IPPROTO_TCP 
  (IPPROTO_NONE  would work)}
  
  socketdgram.pas - client datagram class inheriting from socket class
implements a receive buffer and a send buffer.
A way needs to be developed to specify the buffer sizes.
There are functions to send and receive strings which encapsulate 
   RecvFrom and SendTo.
Strings are broken up based upon buffer lengths. This could be changed
to breaking on a EOS character.   
Error procedures need to be developed

sockettest.pas - Test code : a simple echo server using the TSocketServer class
 With a fixed number of threads (BufCount)
 
 dgramtest.pas - Test code : Test of datagran socket
Using 127.0.0.1 it will write to itself
