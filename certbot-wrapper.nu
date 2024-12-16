#!/run/current-system/sw/bin/nu

export def main [] {
  alias nft = /run/current-system/sw/bin/nft;
  alias certbot = /run/current-system/sw/bin/certbot;
  alias chown = /run/current-system/sw/bin/chown;
  alias systemctl = /run/current-system/sw/bin/systemctl;
  
  if (try { nft -v; true } catch { false }) {
    let comment = $"certbot temporary rule (random uuid)";
    let comment_quot = $"\'\"($comment)\"\'";
    
    nft add rule inet nixos-fw input-allow tcp dport 80 accept comment $comment_quot;
    try { certbot renew };
    let handle = (nft -ja list ruleset | from json).nftables.rule? | filter {|entry| $entry.comment? == $comment} | get handle.0;
    nft delete rule inet nixos-fw input-allow handle $handle;
    chown -R nginx /etc/letsencrypt;
    systemctl reload nginx;
  # } else if ((command_exists "iptables") and (command_exists "ip6tables") and (command_exists "certbot")) {
  #   let iptables_command = get_command "iptables";
  #   let ip6tables_command = get_command "ip6tables";

  #   ^($iptables_command) -I nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
  #   ^($ip6tables_command) -I nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
  #   try { ^(get_command "certbot") renew };
  #   ^($iptables_command) -D nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
  #   ^($ip6tables_command) -D nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
  #   ^chown -R nginx /etc/letsencrypt;
  #   ^systemctl reload nginx;
  } else {
    error make {
      msg: "Could not find nftables",
    };
  }
}
