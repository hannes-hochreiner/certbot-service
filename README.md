# certbot-service
Flake to run certbot as a systemd service using the DNS-01 challenge via [acme-dns-client](https://github.com/hannes-hochreiner/acme-dns-client).

Port 53 is opened temporarily during renewal and closed again afterwards — the same pattern as the previous HTTP-01 approach used for port 80.

## Prerequisites

- An [acme-dns](https://github.com/acme-dns/acme-dns) server running and reachable on the host
- Credentials registered via `acme-dns-client register` and stored at `/etc/acmedns/clientstorage.json`
- A CNAME record in public DNS delegating `_acme-challenge.<domain>` to the acme-dns server

## Initial certificate issuance

Run once manually to issue the certificate and save the authenticator in the renewal config:

```shell
certbot certonly --manual --preferred-challenges dns \
  --manual-auth-hook "acme-dns-client" \
  -d '*.your.domain'
```

Subsequent renewals are handled automatically by the systemd service.

## NixOS module

```nix
hochreiner.services.certbot.enable = true;
```

The module installs `certbot` and `acme-dns-client` as system packages and runs `certbot renew` weekly via a oneshot systemd service.
