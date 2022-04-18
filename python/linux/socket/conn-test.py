import socket

s = socket.socket()

ns = input("Input Remote Host Name: ")
nsp = int(input("Input Remote Host Port: "))

ip = socket.gethostbyname(ns)
print("IP: ", ip)

try:
    s.connect((ns, nsp)) 
    print("Conn OK...")
except Exception as e: 
    print("something's wrong with %s:%d. Exception is %s" % (ns, nsp, e))
finally:
    s.close()
