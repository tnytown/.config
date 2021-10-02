{ lib, pkgs, config, ... }:
let
  agentJar = builtins.fetchurl {
    url = "https://leroy.tny.town/jnlpJars/agent.jar";
    sha256 = "06np8lbvj2gd58y3gk9vdvwbqg01mc0aj3bxzs0b2msk99q0ja9r";
  };
in
{
  services.jenkinsSlave.enable = true;

  sops.secrets.jenkins-secret = {
    owner = config.systemd.services.jenkins-agent.serviceConfig.User;
  };
  systemd.services.jenkins-agent =
    let
      dockerCompat = pkgs.runCommandNoCC "${pkgs.podman.pname}-docker-compat-${pkgs.podman.version}"
        {
          outputs = [ "out" "man" ];
          inherit (pkgs.podman) meta;
        } ''
        mkdir -p $out/bin
        ln -s ${pkgs.podman}/bin/podman $out/bin/docker
        mkdir -p $man/share/man/man1
        for f in ${pkgs.podman.man}/share/man/man1/*; do
          basename=$(basename $f | sed s/podman/docker/g)
          ln -s $f $man/share/man/man1/$basename
        done
      '';
    in
    {
      wantedBy = [ "multi-user.target" ];
      description = "Jenkins Build Agent";

      serviceConfig = {
        type = "simple";
        User = "jenkins";
        Group = "jenkins";
        SupplementaryGroups = [ config.users.groups.keys.name ];
        ExecStart = "${pkgs.adoptopenjdk-hotspot-bin-8}/bin/java -jar -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.LAUNCH_DIAGNOSTICS=true ${agentJar} -jnlpUrl https://leroy.tny.town/computer/navi/jenkins-agent.jnlp -secret @${config.sops.secrets.jenkins-secret.path} -workDir ${"/var/lib/jenkins/"}";
      };

      path = with pkgs; [ bash nixFlakes adoptopenjdk-hotspot-bin-8 git podman dockerCompat ];
    };
}
