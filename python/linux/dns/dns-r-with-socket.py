#!/user/bin/env python3
import socket

####################
## 
## Functions - Start
##
####################
def getIP(d):
    try:
        data = socket.gethostbyname(d)
        ip = repr(data)
        return ip
    except Exception:
        return False

def getIPx(d):
    try:
        data = socket.gethostbyname_ex(d)
        ipx = repr(data[2])
        return ipx
    except Exception:
        return False

def getHost(ip):
    try:
        data = socket.gethostbyaddr(ip)
        host = repr(data[0])
        return host
    except Exception:
        return False

def getAlias(d):
    try:
        data = socket.gethostbyname_ex(d)
        alias = repr(data[1])
        #print repr(data)
        return alias
    except Exception:
        return False
####################
## 
## Functions - End
##
####################


## Get input from stdin
inputhost = input("Input Domain name or IP address: ")

## Run the functions with the input
hostip = getIP(inputhost)
extendedhostip = getIPx(inputhost)
hostaddr = getHost(inputhost)
hostalias = getAlias(inputhost)

## Print the output
print("")
print("Host IP: ", hostip)
print("Host IP with Extended Information: ", extendedhostip)
print("Host Address: ", hostaddr)
print("Host Alias: ", hostalias)
