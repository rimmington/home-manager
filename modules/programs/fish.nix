{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fish;

  sessionVarsStr =
    let
      vars   = config.home.sessionVariables // cfg.sessionVariables;
      export = n: v: "set -x ${n} ${lib.concatMapStringsSep " " quote (toList v)}";
      toList = v: if builtins.isList v then v else ["${toString v}"];
      quote  = v: if lib.hasPrefix "$" v then v else "\"${v}\"";
    in lib.concatStringsSep "\n" (lib.mapAttrsToList export vars);

in

{
  options = {
    programs.fish = {
      enable = mkEnableOption "Fish shell";

      sessionVariables = mkOption {
        default = {};
        type = types.attrs;
        example = { MAILCHECK = 30; PATH = [ "$PATH" "/opt/bin" ]; };
        description = ''
          Environment variables that will be set for the Fish session.
          Strings beginning with $ will not be quoted, ie. will be interpreted
          by Fish as variables.
        '';
      };

      initExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be run when initializing an
          interactive shell.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."fish/conf.d/zz_home_manager.fish".text = ''
        ${sessionVarsStr}

        if status --is-interactive
            ${cfg.initExtra}
        end
    '';
  };
}