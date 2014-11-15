# PPTP

This is an example for running the default installation of poptop pptpd (on Fedora 19).

## Configuration

Your `/etc/pptpd.conf` would look like:
```
option /etc/ppp/options.pptpd
logwtmp
```

And `/etc/ppp/options.pptpd`:
```
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
```

Finally, your passwords should be stored in `/etc/ppp/chap-secrets`:
```
username * some_password *
```

## check_vpn command

The command that should work with the above configuration is:
```
# check_vpn -t pptp -H $VPN_SERVER_PPTP -u username -p some_password -- require-mppe-128 refuse-pap refuse-eap refuse-chap refuse-mschap novj novjccomp nobsdcomp
```
