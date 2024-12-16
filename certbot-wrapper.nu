#!/run/current-system/sw/bin/nu

export def main [] {
  if ((command_exists "nft") and (command_exists "certbot")) {
    let comment = $"certbot temporary rule (random uuid)";
    let nft_command = get_command "nft";
    
    ^($nft_command) add rule inet nixos-fw input-allow tcp dport 80 accept comment ($"\"($comment)\"");
    ^(get_command "certbot") renew;
    let handle = (^nft -ja list ruleset).nftables.rule? | filter {|entry| $entry.comment? == $comment} | get handle.0;
    ^($nft_command) delete rule inet nixos-fw input-allow handle $handle;
    ^chown -R nginx /etc/letsencrypt;
    ^systemctl reload nginx;
  } else if ((command_exists "iptables") and (command_exists "ip6tables") and (command_exists "certbot")) {
    let iptables_command = get_command "iptables";
    let ip6tables_command = get_command "ip6tables";

    ^($iptables_command) -I nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
    ^($ip6tables_command) -I nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
    ^(get_command "certbot") renew;
    ^($iptables_command) -D nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
    ^($ip6tables_command) -D nixos-fw -p tcp -m tcp --dport 80 -j nixos-fw-accept;
    ^chown -R nginx /etc/letsencrypt;
    ^systemctl reload nginx;
  } else {
    error make {
      msg: "Could not find nftables or iptables",
    };
  }
}

def command_exists [
  command: string
] : string {
  return ((which $command | length) == 1);
}

def get_command [
  command: string
] : string {
  let span = (metadata $command).span;
  let msg = $"Could not find command \"($command)\"";
  let command = which $command;

  if (($command | length) == 1) {
    return $command.path.0;
  } else {
    error make {
      msg: $msg,
      label: {
        text: "command specified here",
        span: $span
      }
    };
  }
}