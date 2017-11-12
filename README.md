# DWin32SocketsExample
Translation of the Win32 Socket Example for D

## Use

Build both examples using ldc2

Run winSockServer.exe
Run winSockClient.exe localhost

The client should connect to the server and the two sockets
will exchange 14bytes of data before closing.