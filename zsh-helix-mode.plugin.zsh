autoload -Uz add-zle-hook-widget

0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# Configurations
# The plugin print these variables after mode changes

# Reset then pastel blue block cursor
export ZHM_CURSOR_NORMAL="${ZHM_CURSOR_NORMAL:-\e[0m\e[2 q\e]12;#B4BEFE\a}"

# Reset then pastel red block cursor
export ZHM_CURSOR_SELECT="${ZHM_CURSOR_SELECT:-\e[0m\e[2 q\e]12;#F2CDCD\a}"

# Reset then white vertical blinking cursor
export ZHM_CURSOR_INSERT="${ZHM_CURSOR_INSERT:-\e[0m\e[5 q\e]12;white\a}"

# This config is provided by zle. The plugin uses this as the style for selection.
if (( ! ${+zle_highlight} )); then
  zle_highlight=(region:fg=white,bg=#45475A)
fi

# Clipboard commands
if [[ -n $DISPLAY ]]; then
  export ZHM_CLIPBOARD_PIPE_CONTENT_TO="${ZHM_CLIPBOARD_PIPE_CONTENT_TO:-xclip -sel clip}"
  export ZHM_CLIPBOARD_READ_CONTENT_FROM="${ZHM_CLIPBOARD_READ_CONTENT_FROM:-xclip -o -sel clip}"
elif [[ -n $WAYLAND_DISPLAY ]]; then
  export ZHM_CLIPBOARD_PIPE_CONTENT_TO="${ZHM_CLIPBOARD_PIPE_CONTENT_TO:-wl-copy}"
  export ZHM_CLIPBOARD_READ_CONTENT_FROM="${ZHM_CLIPBOARD_READ_CONTENT_FROM:-wl-paste --no-newline}"
else
  export ZHM_CLIPBOARD_PIPE_CONTENT_TO="${ZHM_CLIPBOARD_PIPE_CONTENT_TO:-}"
  export ZHM_CLIPBOARD_READ_CONTENT_FROM="${ZHM_CLIPBOARD_READ_CONTENT_FROM:-}"
fi

source "${0:h}/widgets.zsh"
source "${0:h}/bindkeys.zsh"

function zhm_precmd {
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0
  MARK=0
  REGION_ACTIVE=1
  ZHM_EDITOR_HISTORY=("" 0 0 0 0 0 0)
  ZHM_EDITOR_HISTORY_IDX=1
  case $ZHM_MODE in
    insert)
      printf "$ZHM_CURSOR_INSERT"
      ;;
    normal)
      printf "$ZHM_CURSOR_NORMAL"
      ;;
  esac
  zhm_registers["%"]="$(pwd)"
}

function zhm_preexec {
  printf "$ZHM_CURSOR_NORMAL"
  REGION_ACTIVE=0
  # Forcing zle to append current command as the latest command
  # If this isn't used, zle would just append the line after current history index
  # (not the latest command) which is quite unintuitive
  # Not sure if there are better way instead of this
  HISTNO=999999
}

precmd_functions+=(zhm_precmd)
preexec_functions+=(zhm_preexec)

function zhm_zle_line_pre_redraw {
  # Keeps selection range in check

  if (( ZHM_HOOK_IKNOWWHATIMDOING == 0 )); then
    case "$ZHM_PREV_MODE $ZHM_MODE" in
      "normal normal")
        if (( CURSOR > ZHM_PREV_CURSOR )); then
          ZHM_SELECTION_RIGHT=$CURSOR
        elif (( CURSOR < ZHM_PREV_CURSOR )); then
          ZHM_SELECTION_LEFT=$CURSOR
        fi
        ;;
    esac
  fi

  local buffer_len=${#BUFFER}
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT < buffer_len ? ZHM_SELECTION_RIGHT : buffer_len))
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT > 0 ? ZHM_SELECTION_RIGHT: 0))
  ZHM_SELECTION_LEFT=$((ZHM_SELECTION_LEFT < buffer_len ? ZHM_SELECTION_LEFT : buffer_len))
  ZHM_SELECTION_LEFT=$((ZHM_SELECTION_LEFT > 0 ? ZHM_SELECTION_LEFT : 0))
  
  local region_prev_active=$REGION_ACTIVE
  __zhm_update_mark
  REGION_ACTIVE=$region_prev_active

  ZHM_HOOK_IKNOWWHATIMDOING=0
  ZHM_PREV_CURSOR=$CURSOR
  ZHM_PREV_MODE=$ZHM_MODE
}

add-zle-hook-widget zle-line-pre-redraw zhm_zle_line_pre_redraw

printf "$ZHM_CURSOR_INSERT"
