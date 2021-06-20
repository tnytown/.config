{ lib, config, ... }: {
  # TODO(tny): is the group setting necessary?
  sops.secrets.initrd-sshkey-rsa = {
    mode = "0440";
    group = "nixbld";
  };
  sops.secrets.initrd-sshkey-ed25519 = {
    mode = "0440";
    group = "nixbld";
  };
  users.users.root.openssh.authorizedKeys.keys =
    let ssh-keys-for = (import ../keys/ssh-keys.nix { inherit lib; });
    in ssh-keys-for config.networking.hostName;

  # Include Ethernet driver. Maybe iwlwifi will be needed in the future?
  boot.initrd.kernelModules = [ "igb" ];

  boot.initrd.network = let
    disk = config.boot.initrd.luks.devices.${config.networking.hostName}.device;
  in {
    enable = true;
    ssh = {
      enable = true;

      # XX: copying the raw path (/run/secrets/...) does not work. Unsure why, potentially related
      # to partition layout on initrd.
      hostKeys = [
        "/var${config.sops.secrets.initrd-sshkey-ed25519.path}"
        "/var${config.sops.secrets.initrd-sshkey-rsa.path}"
      ];
    };

    # Set up .profile for decryption.
    # Loosely inspired by https://mth.st/blog/nixos-initrd-ssh/ (predates builtin LUKS module?)
    postCommands = let bypass = true;
    in ''
      cat <<'EOF' >>/root/.profile
      echo "welcome to initrd ($(uname -r)) on $(hostname)"

      stty -echo
      read -p "Passphrase for ${disk}: " pass
      echo
      stty echo

      ${if bypass then ''
      test -z "$pass" && (echo "spawning shell"; exec sh)
      '' else ""}

      if echo "$pass" | cryptsetup open ${disk} root --type luks --test-passphrase; then
          echo -n "$pass" >/crypt-ramfs/passphrase
          echo "success"
      else
          echo "failure"
      fi

      exit
      EOF
    '';
  };
}
