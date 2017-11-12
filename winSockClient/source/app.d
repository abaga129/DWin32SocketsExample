import std.stdio;
import core.sys.windows.windows;
import core.sys.windows.winsock2;
import core.stdc.stdlib;
import core.stdc.stdio;
import core.stdc.string;

static const int DEFAULT_BUFLEN = 512;
static const(char*) DEFAULT_PORT = "27015";

void main(string[] args)
{
    WSADATA wsaData;
    SOCKET ConnectSocket = INVALID_SOCKET;
    addrinfo* result = null;
    addrinfo* ptr = null;
    addrinfo hints;
    const(char)* sendbuf = "this is a test";
    char[DEFAULT_BUFLEN] recvbuf;
    int iResult;
    int recvbuflen = DEFAULT_BUFLEN;
    
    // Validate the parameters
    if (args.length != 2) {
        printf("usage: %s server-name\n", cast(char*)args[0]);
        return;
    }

    // Initialize Winsock
    iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
    if (iResult != 0) {
        printf("WSAStartup failed with error: %d\n", iResult);
        return;
    }

    memset(cast(void*)&hints, 0, hints.sizeof);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;

    // Resolve the server address and port
    iResult = getaddrinfo("localhost", DEFAULT_PORT, &hints, &result);
    if ( iResult != 0 ) {
        printf("getaddrinfo failed with error: %d\n", iResult);
        WSACleanup();
        return;
    }

    // Attempt to connect to an address until one succeeds
    for(ptr=result; ptr != null ;ptr=ptr.ai_next) {

        // Create a SOCKET for connecting to server
        ConnectSocket = socket(ptr.ai_family, ptr.ai_socktype, 
            ptr.ai_protocol);
        if (ConnectSocket == INVALID_SOCKET) {
            printf("socket failed with error: %ld\n", WSAGetLastError());
            WSACleanup();
            return;
        }

        // Connect to server.
        iResult = connect( ConnectSocket, ptr.ai_addr, cast(int)ptr.ai_addrlen);
        if (iResult == SOCKET_ERROR) {
            closesocket(ConnectSocket);
            ConnectSocket = INVALID_SOCKET;
            continue;
        }
        break;
    }

    freeaddrinfo(result);

    if (ConnectSocket == INVALID_SOCKET) {
        printf("Unable to connect to server!\n");
        WSACleanup();
        return;
    }

    // Send an initial buffer
    iResult = send( ConnectSocket, sendbuf, cast(int)strlen(sendbuf), 0 );
    if (iResult == SOCKET_ERROR) {
        printf("send failed with error: %d\n", WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return;
    }

    printf("Bytes Sent: %ld\n", iResult);

    // shutdown the connection since no more data will be sent
    iResult = shutdown(ConnectSocket, SD_SEND);
    if (iResult == SOCKET_ERROR) {
        printf("shutdown failed with error: %d\n", WSAGetLastError());
        closesocket(ConnectSocket);
        WSACleanup();
        return;
    }

    // Receive until the peer closes the connection
    do {

        iResult = recv(ConnectSocket, cast(void*)recvbuf, recvbuflen, 0);
        if ( iResult > 0 )
            printf("Bytes received: %d\n", iResult);
        else if ( iResult == 0 )
            printf("Connection closed\n");
        else
            printf("recv failed with error: %d\n", WSAGetLastError());

    } while( iResult > 0 );

    // cleanup
    closesocket(ConnectSocket);
    WSACleanup();

    return;
}