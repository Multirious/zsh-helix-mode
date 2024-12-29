0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

ZHM_CURSOR_NORMAL='\e[2 q\e]12;#B4BEFE\a'
ZHM_CURSOR_SELECT='\e[2 q\e]12;#F2CDCD\a'
ZHM_CURSOR_INSERT='\e[5 q\e]12;white\a'
zle_highlight=(region:fg=white,bg=#45475A)

source "${0:h}/widgets.zsh"
source "${0:h}/bindkeys.zsh"

function zhm_precmd {
  ZHM_EXTENDING=0
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0
  MARK=0
  REGION_ACTIVE=1
  ZHM_EDITOR_HISTORY=("" 0 0 0 0 0 0)
  ZHM_EDITOR_HISTORY_IDX=1
  case $ZHM_MODE in
    insert)
      printf "\e[0m$ZHM_CURSOR_INSERT"
      ;;
    normal)
      printf "\e[0m$ZHM_CURSOR_NORMAL"
      ;;
  esac
}

function zhm_preexec {
  printf "\e[0m$ZHM_CURSOR_NORMAL"
  REGION_ACTIVE=0
  # Forcing zle to append current command as the latest command
  # If this isn't used, zle would just append the line after current history index
  # (not the latest command) which is quite unintuitive
  # Not sure if there are better way instead of this
  HISTNO=999999
}

precmd_functions+=(zhm_precmd)
preexec_functions+=(zhm_preexec)

printf "\e[0m$ZHM_CURSOR_INSERT"
