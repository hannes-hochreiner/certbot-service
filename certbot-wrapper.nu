#!/run/current-system/sw/bin/nu

export def main [] {
  alias nft = /run/current-system/sw/bin/nft;
  alias certbot = /run/current-system/sw/bin/certbot;
  alias chown = /run/current-system/sw/bin/chown;
  alias systemctl = /run/current-system/sw/bin/systemctl;

  if (try { nft -v; true } catch { false }) {
    let comment = $"certbot temporary rule (random uuid)";
    let comment_quot = $"\"($comment)\"";

    nft add rule inet nixos-fw input-allow udp dport 53 accept comment $comment_quot;
    nft add rule inet nixos-fw input-allow tcp dport 53 accept comment $comment_quot;
    try { certbot renew };
    let handles = (nft -ja list ruleset | from json).nftables.rule?
      | where comment? == $comment
      | get handle;
    for handle in $handles {
      nft delete rule inet nixos-fw input-allow handle $handle;
    };
    chown -R nginx /etc/letsencrypt;
    systemctl reload nginx;
  } else {
    error make {
      msg: "Could not find nftables",
    };
  }
}
