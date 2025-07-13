#!/bin/bash
set -e

source /opt/gow/bash-lib/utils.sh

function launcher() {
  export GAMESCOPE_WIDTH=${GAMESCOPE_WIDTH:-1920}
  export GAMESCOPE_HEIGHT=${GAMESCOPE_HEIGHT:-1080}
  export GAMESCOPE_REFRESH=${GAMESCOPE_REFRESH:-60}

  if [ -n "$RUN_GAMESCOPE" ]; then
    gow_log "[Gamescope] - Starting: \`$@\`"

    GAMESCOPE_MODE=${GAMESCOPE_MODE:-"-b"}
    /usr/games/gamescope "${GAMESCOPE_MODE}" -W "${GAMESCOPE_WIDTH}" -H "${GAMESCOPE_HEIGHT}" -r "${GAMESCOPE_REFRESH}" -- "$@"
  elif [ -n "$RUN_SWAY" ]; then
    gow_log "[Sway] - Starting: \`$@\`"

    export SWAYSOCK=${XDG_RUNTIME_DIR}/sway.socket  # Enables the sway socket
    export SWAY_STOP_ON_APP_EXIT=${SWAY_STOP_ON_APP_EXIT:-"yes"}
    export XDG_CURRENT_DESKTOP=sway # xdg-desktop-portal
    export XDG_SESSION_DESKTOP=sway # systemd
    export XDG_SESSION_TYPE=wayland # xdg/systemd

    # Only copy waybar default config if it doesn't exist
    mkdir -p $HOME/.config/waybar
    cp -u /cfg/waybar/* $HOME/.config/waybar/

    # Sway needs to be overridden since we are going to change the resolution and app start
    mkdir -p $HOME/.config/sway/
    cp /cfg/sway/config $HOME/.config/sway/config
    # Modify the config file for res and to launch the app at the end
    echo "output * resolution ${GAMESCOPE_WIDTH}x${GAMESCOPE_HEIGHT} position 0,0" >> $HOME/.config/sway/config
    echo -n "workspace main; exec $@" >> $HOME/.config/sway/config

    # if SWAY_STOP_ON_APP_EXIT == "yes" then kill sway when the app exits
    if [ "$SWAY_STOP_ON_APP_EXIT" == "yes" ]; then
      echo -n " && killall sway" >> $HOME/.config/sway/config
    fi

    # Start sway
    dbus-run-session -- sway --unsupported-gpu
  elif [ -n "$RUN_NIRI" ]; then
    gow_log "[Niri] - Starting: \`$@\`"
    export NIRI_SOCKET=${XDG_RUNTIME_DIR}/niri.socket
    export NIRI_STOP_ON_APP_EXIT=${NIRI_STOP_ON_APP_EXIT:-"yes"}
    export XDG_CURRENT_DESKTOP=niri
    export XDG_SESSION_DESKTOP=niri
    export XDG_SESSION_TYPE=wayland
    # Only copy waybar default config if it doesn't exist
    mkdir -p $HOME/.config/waybar
    cp -u /cfg/waybar/* $HOME/.config/waybar/
    mkdir -p $HOME/.config/niri/
    cp /cfg/niri/config.kdl $HOME/.config/niri/config.kdl
    # replace GAMESCOPE_* vars
    sed -i -e "s/\$GAMESCOPE_WIDTH/${GAMESCOPE_WIDTH}/g" \
           -e "s/\$GAMESCOPE_HEIGHT/${GAMESCOPE_HEIGHT}/g" \
           -e "s/\$GAMESCOPE_REFRESH/${GAMESCOPE_REFRESH}/g" $HOME/.config/niri/config.kdl
    # Modify the config file to launch the app at the end
    CMD="$*"
    # if NIRI_STOP_ON_APP_EXIT == "yes" then kill niri when the app exits
    if [ "$NIRI_STOP_ON_APP_EXIT" == "yes" ]; then
        CMD="$CMD && killall niri"
    fi
    echo "spawn-at-startup \"sh\" \"-c\" \"$CMD\"" >> "$HOME/.config/niri/config.kdl"
    # Start Niri
    dbus-run-session -- niri
  else
    gow_log "[exec] Starting: $@"

    exec $@
  fi
}
