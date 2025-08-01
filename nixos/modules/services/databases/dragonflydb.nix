{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.dragonflydb;
  dragonflydb = pkgs.dragonflydb;

  settings = {
    port = cfg.port;
    dir = "/var/lib/dragonflydb";
    keys_output_limit = cfg.keysOutputLimit;
  }
  // (lib.optionalAttrs (cfg.bind != null) { bind = cfg.bind; })
  // (lib.optionalAttrs (cfg.requirePass != null) { requirepass = cfg.requirePass; })
  // (lib.optionalAttrs (cfg.maxMemory != null) { maxmemory = cfg.maxMemory; })
  // (lib.optionalAttrs (cfg.memcachePort != null) { memcache_port = cfg.memcachePort; })
  // (lib.optionalAttrs (cfg.dbNum != null) { dbnum = cfg.dbNum; })
  // (lib.optionalAttrs (cfg.cacheMode != null) { cache_mode = cfg.cacheMode; });
in
{

  ###### interface

  options = {
    services.dragonflydb = {
      enable = lib.mkEnableOption "DragonflyDB";

      user = lib.mkOption {
        type = lib.types.str;
        default = "dragonfly";
        description = "The user to run DragonflyDB as";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 6379;
        description = "The TCP port to accept connections.";
      };

      bind = lib.mkOption {
        type = with lib.types; nullOr str;
        default = "127.0.0.1";
        description = ''
          The IP interface to bind to.
          `null` means "all interfaces".
        '';
      };

      requirePass = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Password for database";
        example = "letmein!";
      };

      maxMemory = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        description = ''
          The maximum amount of memory to use for storage (in bytes).
          `null` means this will be automatically set.
        '';
      };

      memcachePort = lib.mkOption {
        type = with lib.types; nullOr port;
        default = null;
        description = ''
          To enable memcached compatible API on this port.
          `null` means disabled.
        '';
      };

      keysOutputLimit = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 8192;
        description = ''
          Maximum number of returned keys in keys command.
          `keys` is a dangerous command.
          We truncate its result to avoid blowup in memory when fetching too many keys.
        '';
      };

      dbNum = lib.mkOption {
        type = with lib.types; nullOr ints.unsigned;
        default = null;
        description = "Maximum number of supported databases for `select`";
      };

      cacheMode = lib.mkOption {
        type = with lib.types; nullOr bool;
        default = null;
        description = ''
          Once this mode is on, Dragonfly will evict items least likely to be stumbled
          upon in the future but only when it is near maxmemory limit.
        '';
      };
    };
  };

  ###### implementation

  config = lib.mkIf config.services.dragonflydb.enable {

    users.users = lib.optionalAttrs (cfg.user == "dragonfly") {
      dragonfly.description = "DragonflyDB server user";
      dragonfly.isSystemUser = true;
      dragonfly.group = "dragonfly";
    };
    users.groups = lib.optionalAttrs (cfg.user == "dragonfly") { dragonfly = { }; };

    environment.systemPackages = [ dragonflydb ];

    systemd.services.dragonflydb = {
      description = "DragonflyDB server";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${dragonflydb}/bin/dragonfly --alsologtostderr ${
          lib.concatStringsSep " " (lib.mapAttrsToList (n: v: "--${n} ${lib.escapeShellArg v}") settings)
        }";

        User = cfg.user;

        # Filesystem access
        ReadWritePaths = [ settings.dir ];
        StateDirectory = "dragonflydb";
        StateDirectoryMode = "0700";
        # Process Properties
        LimitMEMLOCK = "infinity";
        # Caps
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        # Sandboxing
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictRealtime = true;
        PrivateMounts = true;
        MemoryDenyWriteExecute = true;
      };
    };
  };
}
