# OpenVPN

This is an example for running the default installation of openvpn (on Fedora 19).

## Configuration

Your `/etc/openvpn/server.conf`:
```
port 1194
proto tcp
dev tun
comp-lzo
cipher AES-256-CBC
dh dh1024.pem
server 10.1.0.0 255.255.255.0
persist-key
persist-tun
status /etc/openvpn/openvpn-status.log 1
status-version 1
verb 1
client-cert-not-required
username-as-common-name
duplicate-cn
cert server.crt
ca ca.crt
key server.key
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
```

Copy default keys from the openvpn installation:
```
# cp -a /usr/share/doc/openvpn-2.3.2/sample-keys/{ca.crt,dh1024.pem,server.crt,server.key} /etc/openvpn/
```

**Finally**, make sure you choose some sort of authentication mechanism. Sorry, but
I can't help you with that :)

For the sake of this example we'll assume that `username/some_password` is a
valid combination to login to this OpenVPN configuration.

## check_vpn command

The command that should work with the above configuration is:
```
# check_vpn -t openvpn -H $VPN_SERVER_OPENVPN -u username -p some_password -d tun -- --ca openvpn_default_server_crt --proto tcp --cipher AES-256-CBC --comp-lzo
```
