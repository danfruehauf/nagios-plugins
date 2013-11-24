# SSH

This is an example for running a simple openssh VPN installation (on Fedora 19).

## Configuration

Your `/etc/ssh/sshd_config` should include at least those lines:
```
PermitRootLogin yes
PermitTunnel yes
UsePAM yes
```

Make sure you can login to your machine using your root account, after
exchanging your key by placing it at `/root/.ssh/authorized_keys`.

## check_vpn command

The command that should work with the above configuration is:
```
# check_vpn -t ssh -H $VPN_SERVER_SSH -u root -p unused_anyway
```
