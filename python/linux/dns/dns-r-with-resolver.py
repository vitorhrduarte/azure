import dns
import dns.resolver

def dnsQuery (address="microsoft.pt", nameserver="1.1.1.1"):
  dns.resolver.default_resolver = dns.resolver.Resolver(configure=False)
  dns.resolver.default_resolver.nameservers = [ nameserver ]
  dns.resolver.default_resolver.timeout = 5
  dns.resolver.default_resolver.lifetime = 5

  result = dns.resolver.query(address, 'A')

  for ipval in result:
       print('IP', ipval.to_text())

a = input("Input Remote Address: ")
n = input("Input DNS Resolver: ")

dnsQuery(a, n) 
