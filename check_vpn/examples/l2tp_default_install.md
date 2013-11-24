# L2TP

This is an example for running the default installation of xl2tpd (on Fedora 19).

## Configuration

Your `/etc/xl2tpd/xl2tpd.conf` would look like:
```
[global]
[lns default]
ip range = 192.168.1.128-192.168.1.254
local ip = 192.168.1.99
refuse pap = yes
require authentication = yes
name = LinuxVPNserver
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
```

And `/etc/ppp/options.xl2tpd`:
```
ipcp-accept-local
ipcp-accept-remote
ms-dns  8.8.8.8
noccp
auth
crtscts
idle 1800
mtu 1410
mru 1410
nodefaultroute
debug
lock
proxyarp
connect-delay 5000
```

Finally, your passwords should be stored in `/etc/ppp/chap-secrets`:
```
username * some_password *
```

## check_vpn command

The command that should work with the above configuration is:
```
# check_vpn -t l2tp -H $VPN_SERVER_L2TP -u username -p some_password -- noccp
```
