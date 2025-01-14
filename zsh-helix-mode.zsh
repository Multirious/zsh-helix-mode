autoload -Uz add-zle-hook-widget

# ==============================================================================

# Configurations
# The plugin print these variables after mode changes

# Reset then pastel blue block cursor
export ZHM_CURSOR_NORMAL="${ZHM_CURSOR_NORMAL:-\e[0m\e[2 q\e]12;#B4BEFE\a}"

# Reset then pastel red block cursor
export ZHM_CURSOR_SELECT="${ZHM_CURSOR_SELECT:-\e[0m\e[2 q\e]12;#F2CDCD\a}"

# Reset then white vertical blinking cursor
export ZHM_CURSOR_INSERT="${ZHM_CURSOR_INSERT:-\e[0m\e[5 q\e]12;white\a}"

# Uses the syntax from https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting
export ZHM_STYLE_SELECTION="fg=white,bg=#45475a"

export ZHM_STYLE_OTHER_CURSOR_SELECT="fg=black,bg=#b5a6a8"

export ZHM_STYLE_OTHER_CURSOR="fg=black,bg=#878ec0"

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

# ==============================================================================

export ZHM_MODE=insert
export ZHM_MULTILINE=0

ZHM_PRIMARY_CURSOR_IDX=1
zhm_cursors_pos=(0)
zhm_cursors_selection_left=(0)
zhm_cursors_selection_right=(0)

ZHM_CHANGES_HISTORY_IDX=1
zhm_changes_history_buffer=("")
zhm_changes_history_cursors_idx_starts_pre=(1)
zhm_changes_history_cursors_count_pre=(1)
zhm_changes_history_cursors_pos_pre=(0)
zhm_changes_history_cursors_selection_left_pre=(0)
zhm_changes_history_cursors_selection_right_pre=(0)
zhm_changes_history_primary_cursor_pre=(1)
zhm_changes_history_cursors_idx_starts_post=(1)
zhm_changes_history_cursors_count_post=(1)
zhm_changes_history_cursors_pos_post=(0)
zhm_changes_history_cursors_selection_left_post=(0)
zhm_changes_history_cursors_selection_right_post=(0)
zhm_changes_history_primary_cursor_post=(1)

zhm_cursors_last_moved_x=(0)

declare -A zhm_registers

ZHM_HOOK_IKNOWWHATIMDOING=0

ZHM_LAST_MOTION=""
ZHM_LAST_MOTION_CHAR=""

# ==============================================================================

function __zhm_read_register {
  case "$1" in
    "_")
      ;;
    "#")
      # this should return selection indices but there's always one selection anyway
      print "1"
      ;;
    ".")
      print "$BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]"
      ;;
    "%")
      print "$(pwd)"
      ;;
    "+")
      print "$(eval $ZHM_CLIPBOARD_READ_CONTENT_FROM)"
      ;;
    *)
      local content="$zhm_registers["$1"]"
      print "$content"
      ;;
  esac
}

function __zhm_write_register {
  case "$1" in
    "_"| "#" | "." | "%")
      ;;
    "+")
       print "$2" | eval $ZHM_CLIPBOARD_PIPE_CONTENT_TO
      ;;
    *)
      zhm_registers["$1"]="$2"
      ;;
  esac
}

function __zhm_user_specified_register {
  if [[ $KEYS =~ "^\"(.).*" ]]; then
    print "$match[1]"
    return 0
  else
    return 1
  fi
 }

function __zhm_update_region_highlight {
  region_highlight=(
    ${region_highlight:#*memo=zhm_highlight}
  )
  for i in {1..$#zhm_cursors_pos}; do
    local left=$zhm_cursors_selection_left[$i]
    local right=$(( zhm_cursors_selection_right[i] + 1 ))
    local highlight="$left $right $ZHM_STYLE_SELECTION memo=zhm_highlight"
    region_highlight+=("$highlight")
  done

  for i in {1..$#zhm_cursors_pos}; do
    local cursor="$zhm_cursors_pos[$i]"
    local cursor_right="$((cursor + 1))"
    if [[ $ZHM_MODE != select ]]; then
      region_highlight+=("$cursor $cursor_right $ZHM_STYLE_OTHER_CURSOR memo=zhm_highlight")
    else
      region_highlight+=("$cursor $cursor_right $ZHM_STYLE_OTHER_CURSOR_SELECT memo=zhm_highlight")
    fi
  done
}

function __zhm_update_changes_history_pre {
  if (( ${#zhm_changes_history_buffer} > ZHM_CHANGES_HISTORY_IDX )); then
    local keep=$((ZHM_CHANGES_HISTORY_IDX))
    zhm_changes_history_buffer=("${(@)zhm_changes_history_buffer[1,$keep]}")

    local idx=$((zhm_changes_history_cursors_idx_starts_pre[$((ZHM_CHANGES_HISTORY_IDX + 1))] - 1))
    zhm_changes_history_cursors_pos_pre=($zhm_changes_history_cursors_pos_pre[1,$idx])
    zhm_changes_history_cursors_selection_left_pre=($zhm_changes_history_cursors_selection_left_pre[1,$idx])
    zhm_changes_history_cursors_selection_right_pre=($zhm_changes_history_cursors_selection_right_pre[1,$idx])
    zhm_changes_history_cursors_idx_starts_pre=($zhm_changes_history_cursors_idx_starts_pre[1,$keep])
    zhm_changes_history_cursors_count_pre=($zhm_changes_history_cursors_count_pre[1,$keep])
    zhm_changes_history_primary_cursor_pre=($zhm_changes_history_primary_cursor_post[1,$keep])

    local idx=$((zhm_changes_history_cursors_idx_starts_post[$((ZHM_CHANGES_HISTORY_IDX + 1))] - 1))
    zhm_changes_history_cursors_pos_post=($zhm_changes_history_cursors_pos_post[1,$idx])
    zhm_changes_history_cursors_selection_left_post=($zhm_changes_history_cursors_selection_left_post[1,$idx])
    zhm_changes_history_cursors_selection_right_post=($zhm_changes_history_cursors_selection_right_post[1,$idx])
    zhm_changes_history_cursors_idx_starts_post=($zhm_changes_history_cursors_idx_starts_post[1,$keep])
    zhm_changes_history_cursors_count_post=($zhm_changes_history_cursors_count_post[1,$keep])
    zhm_changes_history_primary_cursor_post=($zhm_changes_history_primary_cursor_post[1,$keep])
  fi
  zhm_changes_history_cursors_idx_starts_pre+=(
    $(( ${#zhm_changes_history_cursors_pos_pre} + 1 ))
  )
  zhm_changes_history_cursors_count_pre+=(
    "${#zhm_cursors_pos}"
  )
  zhm_changes_history_cursors_pos_pre+=(
    "${zhm_cursors_pos[@]}"
  )
  zhm_changes_history_cursors_selection_left_pre+=(
    "${zhm_cursors_selection_left[@]}")
  zhm_changes_history_cursors_selection_right_pre+=(
    "${zhm_cursors_selection_right[@]}"
  )
  zhm_changes_history_primary_cursor_pre+=(
    $ZHM_PRIMARY_CURSOR_IDX
  )
}

function __zhm_update_changes_history_post {
  zhm_changes_history_buffer+=("$BUFFER")
  zhm_changes_history_cursors_idx_starts_post+=(
    $(( ${#zhm_changes_history_cursors_pos_post} + 1 ))
  )
  zhm_changes_history_cursors_count_post+=(
    "${#zhm_cursors_pos}"
  )
  zhm_changes_history_cursors_pos_post+=(
    "${zhm_cursors_pos[@]}"
  )
  zhm_changes_history_cursors_selection_left_post+=(
    "${zhm_cursors_selection_left[@]}"
  )
  zhm_changes_history_cursors_selection_right_post+=(
    "${zhm_cursors_selection_right[@]}"
  )
  zhm_changes_history_primary_cursor_post+=(
    $ZHM_PRIMARY_CURSOR_IDX
  )
  ZHM_CHANGES_HISTORY_IDX=$((ZHM_CHANGES_HISTORY_IDX + 1))
}

function __zhm_mode_normal {
  bindkey -A hxnor main
  ZHM_MODE=normal
  printf "$ZHM_CURSOR_NORMAL"
}

function __zhm_mode_select {
  bindkey -A hxnor main
  ZHM_MODE=select
  printf "$ZHM_CURSOR_SELECT"
}

function __zhm_mode_insert {
  bindkey -A hxins main
  ZHM_MODE=insert
  printf "$ZHM_CURSOR_INSERT"
}

function __zhm_goto {
  local idx=$1
  local cursor=$2
  local left=$zhm_cursors_selection_left[$idx]
  local right=$zhm_cursors_selection_right[$idx]
  local prev_cursor=$zhm_cursors_pos[$idx]

  if (( cursor < 0 )); then
    cursor=0
  fi
  if (( cursor > ${#BUFFER} )); then
    cursor=${#BUFFER}
  fi

  if (( idx == ZHM_PRIMARY_CURSOR_IDX )); then
    CURSOR=$cursor
  fi

  zhm_cursors_pos[$idx]=$cursor

  if [[ $ZHM_MODE != select ]]; then
    zhm_cursors_selection_left[$idx]=$cursor
    zhm_cursors_selection_right[$idx]=$cursor
  elif (( prev_cursor == left )); then
    if (( cursor <= right )); then
      zhm_cursors_selection_left[$idx]=$cursor
    else
      zhm_cursors_selection_left[$idx]=$right
      zhm_cursors_selection_right[$idx]=$cursor
    fi
  elif (( prev_cursor == right )); then
    if (( cursor >= left)); then
      zhm_cursors_selection_right[$idx]=$cursor
    else
      zhm_cursors_selection_right[$idx]=$left
      zhm_cursors_selection_left[$idx]=$cursor
    fi
  fi
}

function __zhm_trailing_goto {
  local idx=$1
  local cursor=$2

  if [[ $ZHM_MODE == select ]]; then
    __zhm_goto $idx $pos

    return
  fi

  if (( cursor < 0 )); then
    cursor=0
  fi
  if (( cursor > ${#BUFFER} )); then
    cursor=${#BUFFER}
  fi

  local skip=$3
  local left=$zhm_cursors_selection_left[$idx]
  local right=$zhm_cursors_selection_right[$idx]
  local prev_cursor=$zhm_cursors_pos[$idx]

  if (( idx == ZHM_PRIMARY_CURSOR_IDX )); then
    CURSOR=$cursor
  fi
  zhm_cursors_pos[$idx]=$cursor

  if (( cursor > prev_cursor )); then
    zhm_cursors_selection_left[$idx]=$((prev_cursor + skip))
    zhm_cursors_selection_right[$idx]=$cursor
  elif (( cursor < prev_cursor)); then
    zhm_cursors_selection_right[$idx]=$((prev_cursor - skip))
    zhm_cursors_selection_left[$idx]=$cursor
  fi
}

function __zhm_update_last_moved {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ $'\n[^\n]*$' ]]; then
      zhm_cursors_last_moved_x[$i]=$((cursor - MBEGIN))
    else
      zhm_cursors_last_moved_x[$i]=$cursor
    fi
  done

}

function zhm_move_right {
  for i in {1..$#zhm_cursors_pos}; do
    __zhm_goto $i $((zhm_cursors_pos[i] + 1))
  done
  __zhm_update_last_moved
  __zhm_update_region_highlight
}

function zhm_move_left {
  for i in {1..$#zhm_cursors_pos}; do
    __zhm_goto $i $((zhm_cursors_pos[i] - 1))
  done
  __zhm_update_last_moved
  __zhm_update_region_highlight
}

function zhm_move_up {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ $'\n[^\n]*$' ]]; then
      __zhm_goto $i $((MBEGIN - 1))
      local cursor=$zhm_cursors_pos[$i]
      local lbuffer="${BUFFER:0:$cursor}"
      local new_x=
      if [[ $lbuffer =~ $'\n[^\n]*$' ]]; then
        new_x=$((cursor - MBEGIN))
      else
        new_x=$cursor
      fi
      local last_moved_x=$zhm_cursors_last_moved_x[$i]
      if (( new_x > last_moved_x )); then
        __zhm_goto $i $((cursor - (new_x - last_moved_x)))
      fi
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_up_or_history_prev {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ $'\n[^\n]*$' ]]; then
      __zhm_goto $i $((MBEGIN - 1))
      local cursor=$zhm_cursors_pos[$i]
      local lbuffer="${BUFFER:0:$cursor}"
      local new_x=
      if [[ $lbuffer =~ $'\n[^\n]*$' ]]; then
        new_x=$((cursor - MBEGIN))
      else
        new_x=$cursor
      fi
      local last_moved_x=$zhm_cursors_last_moved_x[$i]
      if (( new_x > last_moved_x )); then
        __zhm_goto $i $((cursor - (new_x - last_moved_x)))
      fi
    elif (( i == ZHM_PRIMARY_CURSOR_IDX )); then
      zhm_history_prev
      return
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_down {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ $'^[^\n]*?\n' ]]; then
      __zhm_goto $i $((cursor + MEND))
      local cursor=$zhm_cursors_pos[$i]
      local rbuffer="${BUFFER:$cursor}"
      if [[ $rbuffer =~ $'^[^\n]*?\n|^[^\n]*$' ]]; then
        local line_last=$((MEND - 1))
        local last_moved_x=$zhm_cursors_last_moved_x[$i]
        if (( last_moved_x <= line_last )); then
          __zhm_goto $i $((cursor + last_moved_x))
        else
          __zhm_goto $i $((cursor + line_last))
        fi
      fi
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_down_or_history_next {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ $'^[^\n]*?\n' ]]; then
      __zhm_goto $i $((cursor + MEND))
      local cursor=$zhm_cursors_pos[$i]
      local rbuffer="${BUFFER:$cursor}"
      if [[ $rbuffer =~ $'^[^\n]*?\n|^[^\n]*$' ]]; then
        local line_last=$((MEND - 1))
        local last_moved_x=$zhm_cursors_last_moved_x[$i]
        if (( last_moved_x <= line_last )); then
          __zhm_goto $i $((cursor + last_moved_x))
        else
          __zhm_goto $i $((cursor + line_last))
        fi
      fi
    elif (( i == ZHM_PRIMARY_CURSOR_IDX )); then
      zhm_history_prev
      return
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_next_word_start {
  setopt localoptions rematchpcre
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ '^\n*(\w+[^\S\n]*|[^\w\s]+[^\S\n]*|[^\S\n]+)' ]]; then
      local skip=$((mbegin[1] - 1))
      local go=$((cursor + mend[1] - 1))
      if (( ${#match[1]} == 1 )) \
        && [[ ${rbuffer:1} =~ '^\n*(\w+[^\S\n]*|[^\w\s]+[^\S\n]*|[^\S\n]+)' ]]; then
        skip=$((mbegin[1]))
        go=$((cursor + mend[1]))
      fi
      __zhm_trailing_goto $i $go $skip
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_prev_word_start {
  setopt localoptions rematchpcre
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$((cursor + 1))}"
    if [[ $lbuffer =~ '(\w+[^\S\n]*|[^\w\s]+[^\S\n]*|[^\S\n]+)\n*$' ]]; then
      local skip=$((${#lbuffer} - mend[1]))
      local go=$((mbegin - 1))
      if (( ${#match[1]} == 1 )) \
        && [[ ${lbuffer:0:-1} =~ '(\w+[^\S\n]*|[^\w\s]+[^\S\n]*|[^\S\n]+)\n*$' ]]; then
        skip=$((${#lbuffer} - mend[1]))
        go=$((mbegin - 1))
      fi
      __zhm_trailing_goto $i $go $skip
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_next_word_end {
  setopt localoptions rematchpcre
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ '^\n*([^\S\n]*\w+|[^\S\n]*[^\w\s]+|[^\S\n]+)' ]]; then
      local skip=$((mbegin[1] - 1))
      local go=$((cursor + mend[1] - 1))
      if (( ${#match[1]} == 1 )) \
        && [[ ${rbuffer:1} =~ '^\n*([^\S\n]*\w+|[^\S\n]*[^\w\s]+|[^\S\n]+)' ]]; then
        skip=$((mbegin[1]))
        go=$((cursor + mend[1]))
      fi
      __zhm_trailing_goto $i $go $skip
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_next_long_word_start {
  setopt localoptions rematchpcre
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ '^\n*(\S+[^\S\n]*|[^\S\n]+)' ]]; then
      local skip=$((mbegin[1] - 1))
      local go=$((cursor + mend[1] - 1))
      if (( ${#match[1]} == 1 )) \
        && [[ ${rbuffer:1} =~ '^\n*(\S+[^\S\n]*|[^\S\n]+)' ]]; then
        skip=$((mbegin[1]))
        go=$((cursor + mend[1]))
      fi
      __zhm_trailing_goto $i $go $skip
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_prev_long_word_start {
  setopt localoptions rematchpcre
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$((cursor + 1))}"
    if [[ $lbuffer =~ '(\S+[^\S\n]*|[^\S\n]+)\n*$' ]]; then
      local skip=$((${#lbuffer} - mend[1]))
      local go=$((mbegin - 1))
      if (( ${#match[1]} == 1 )) \
        && [[ ${lbuffer:0:-1} =~ '(\S+[^\S\n]*|[^\S\n]+)\n*$' ]]; then
        skip=$((${#lbuffer} - mend[1]))
        go=$((mbegin - 1))
      fi
      __zhm_trailing_goto $i $go $skip
    fi
  done
  __zhm_update_region_highlight
}

function zhm_move_next_long_word_end {
  setopt localoptions rematchpcre
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ '^\n*([^\S\n]*\S+|[^\S\n]+)' ]]; then
      local skip=$((mbegin[1] - 1))
      local go=$((cursor + mend[1] - 1))
      if (( ${#match[1]} == 1 )) \
        && [[ ${rbuffer:1} =~ '^\n*([^\S\n]*\S+|[^\S\n]+)' ]]; then
        skip=$((mbegin[1]))
        go=$((cursor + mend[1]))
      fi
      __zhm_trailing_goto $i $go $skip
    fi
  done
  __zhm_update_region_highlight
}

function zhm_find_till_char {
  local char="${KEYS:1}"
  char="$(printf '%s' "$char" | sed 's/[.[\(*^$+?{|]/\\&/g')"
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ ".?$char?[^$char]*" ]]; then
      __zhm_trailing_goto $i $((cursor + MEND - 1)) 0
    fi
  done
  ZHM_LAST_MOTION="find_till"
  ZHM_LAST_MOTION_CHAR="$char"
  __zhm_update_region_highlight
}

function zhm_find_next_char {
  local char="${KEYS:1}"
  char="$(printf '%s' "$char" | sed 's/[.[\(*^$+?{|]/\\&/g')"
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ "$char?[^$char]*$char" ]]; then
      __zhm_trailing_goto $i $((cursor + MEND - 1)) 0
    fi
  done
  ZHM_LAST_MOTION="find_next"
  ZHM_LAST_MOTION_CHAR="$char"
  __zhm_update_region_highlight
}

function zhm_till_prev_char {
  local char="${KEYS:1}"
  char="$(printf '%s' "$char" | sed 's/[.[\(*^$+?{|]/\\&/g')"
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ "[^$char]*$char?$" ]]; then
      __zhm_trailing_goto $i $((MBEGIN - 1)) 0
    fi
  done
  ZHM_LAST_MOTION="till_prev"
  ZHM_LAST_MOTION_CHAR="$char"
  __zhm_update_region_highlight
}

function zhm_find_prev_char {
  local char="${KEYS:1}"
  char="$(printf '%s' "$char" | sed 's/[.[\(*^$+?{|]/\\&/g')"
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ "${char}[^${char}]*$" ]]; then
      __zhm_trailing_goto $i $((MBEGIN - 1)) 0
    fi
  done
  ZHM_LAST_MOTION="find_prev"
  ZHM_LAST_MOTION_CHAR="$char"
  __zhm_update_region_highlight
}

function zhm_repeat_last_motion {
  local char="$ZHM_LAST_MOTION_CHAR"
  case "$ZHM_LAST_MOTION" in
    "find_till")
      for i in {1..$#zhm_cursors_pos}; do
        local cursor=$zhm_cursors_pos[$i]
        local rbuffer="${BUFFER:$cursor}"
        if [[ $rbuffer =~ ".?$char?[^$char]*" ]]; then
          __zhm_trailing_goto $i $((CURSOR + MEND - 1)) 0
        fi
      done
      ;;
    "find_next")
      for i in {1..$#zhm_cursors_pos}; do
        local cursor=$zhm_cursors_pos[$i]
        local rbuffer="${BUFFER:$cursor}"
        if [[ $rbuffer =~ "$char?[^$char]*$char" ]]; then
          __zhm_trailing_goto $i $((CURSOR + MEND - 1)) 0
        fi
      done
      ;;
    "till_prev")
      for i in {1..$#zhm_cursors_pos}; do
        local cursor=$zhm_cursors_pos[$i]
        local lbuffer="${BUFFER:0:$cursor}"
        if [[ $lbuffer =~ "[^$char]*$char?$" ]]; then
          __zhm_trailing_goto $i $((MBEGIN - 1)) 0
        fi
      done
      ;;
    "find_prev")
      for i in {1..$#zhm_cursors_pos}; do
        local cursor=$zhm_cursors_pos[$i]
        local lbuffer="${BUFFER:0:$cursor}"
        if [[ $lbuffer =~ "${char}[^${char}]*$" ]]; then
          __zhm_trailing_goto $i $((MBEGIN - 1)) 0
        fi
      done
      ;;    
  esac
  __zhm_update_region_highlight
}

function zhm_goto_first_line {
  for i in {1..$#zhm_cursors_pos}; do
    __zhm_goto $i 0
  done
  __zhm_update_region_highlight
}

function zhm_goto_last_line {
  if [[ $BUFFER =~ $'[^\n]*$' ]]; then
    for i in {1..$#zhm_cursors_pos}; do
      __zhm_goto $i $((MBEGIN - 1))
    done
  fi
  __zhm_update_region_highlight
}

function zhm_goto_line_start {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ $'[^\n]*$' ]]; then
      __zhm_goto $i $((MBEGIN - 1))
    fi
  done
  __zhm_update_region_highlight
}

function zhm_goto_line_end {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ $'^[^\n]+' ]]; then
      __zhm_goto $i $((cursor + MEND - 1))
    elif [[ "${BUFFER[$cursor,$((cursor + 1))]}" != $'\n\n' ]]; then
      __zhm_goto $i $((cursor - 1))
    fi
  done
  __zhm_update_region_highlight
}

function zhm_goto_line_first_nonwhitespace {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ $'[^\n]*$' ]]; then
      local line_start=$((MBEGIN - 1))
      local line="${BUFFER:$line_start}"
      if [[ $line =~ '^ *' ]]; then
        __zhm_goto $i $((line_start + MEND))
      fi
    fi
  done
  __zhm_update_region_highlight
}

# not updated
function zhm_surround_add {
  local char="${KEYS:2}"
  local left
  local right
  case $char in
    "(" | ")")
      left="("
      right=")"
      ;;
    "[" | "]")
      left="["
      right="]"
      ;;
    "{" | "}")
      left="{"
      right="}"
      ;;
    "<" | ">")
      left="<"
      right=">"
      ;;
    *)
      left="$char"
      right="$char"
      ;;
  esac

  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  local buffer_left="${BUFFER:0:$ZHM_SELECTION_LEFT}"
  local buffer_right="${BUFFER:$((ZHM_SELECTION_RIGHT + 1))}"
  local buffer_inner="${BUFFER:$ZHM_SELECTION_LEFT:$(($ZHM_SELECTION_RIGHT - $ZHM_SELECTION_LEFT + 1))}"

  BUFFER="$buffer_left$left$buffer_inner$right$buffer_right"
  ZHM_SELECTION_LEFT=${#buffer_left}
  ZHM_SELECTION_RIGHT=$((${#buffer_left} + ${#left} + ${#buffer_inner} + ${#right} - 1))
  if (( prev_cursor == prev_right )); then
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    CURSOR=$ZHM_SELECTION_LEFT
  fi
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_region_highlight
}

# not updated
function zhm_select_word_inner {
  if (( CURSOR == ${#BUFFER} )); then
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  local word_start
  if [[ "${BUFFER:0:$((CURSOR + 1))}" =~ '\w+$' ]]; then
    word_start=$((MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  local word_end
  if [[ "${BUFFER:$word_start}" =~ '^\w+' ]]; then
    word_end=$((word_start + MEND - 1))
    word_start=$((word_start + MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  ZHM_SELECTION_LEFT=$word_start
  ZHM_SELECTION_RIGHT=$word_end
  CURSOR=$ZHM_SELECTION_RIGHT

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_region_highlight
}

# not updated
function zhm_select_word_around {
  if (( CURSOR == ${#BUFFER} )); then
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  local word_start
  if [[ "${BUFFER:0:$((CURSOR + 1))}" =~ ' *\w+$' ]]; then
    word_start=$((MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  local word_end
  if [[ "${BUFFER:$word_start}" =~ '\w+ +' || "${BUFFER:$word_start}" =~ '^ *\w+' ]]; then
    word_end=$((word_start + MEND - 1))
    word_start=$((word_start + MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  ZHM_SELECTION_LEFT=$word_start
  ZHM_SELECTION_RIGHT=$word_end
  CURSOR=$ZHM_SELECTION_RIGHT

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_region_highlight
}

# not updated
function zhm_select_long_word_inner {
  local word_start
  if [[ "${BUFFER:0:$((CURSOR + 1))}" =~ '[^ ]+ ?$' ]]; then
    word_start=$((MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  local word_end
  if [[ "${BUFFER:$word_start}" =~ '[^ ]+' ]]; then
    word_end=$((word_start + MEND - 1))
    word_start=$((word_start + MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  ZHM_SELECTION_LEFT=$word_start
  ZHM_SELECTION_RIGHT=$word_end
  CURSOR=$ZHM_SELECTION_RIGHT

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_region_highlight
}

# not updated
function zhm_select_long_word_around {
  local word_start
  if [[ "${BUFFER:0:$((CURSOR + 1))}" =~ ' *[^ ]+ ?$' ]]; then
    word_start=$((MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  local word_end
  if [[ "${BUFFER:$word_start}" =~ '[^ ]+ +' || "${BUFFER:$word_start}" =~ '^ *[^ ]+' ]]; then
    word_end=$((word_start + MEND - 1))
    word_start=$((word_start + MBEGIN - 1))
  else
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
    __zhm_update_region_highlight
    return
  fi

  ZHM_SELECTION_LEFT=$word_start
  ZHM_SELECTION_RIGHT=$word_end
  CURSOR=$ZHM_SELECTION_RIGHT

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_region_highlight
}

# not updated
function __zhm_find_surround_pair {
  local left_char="$1"
  local right_char="$2"
  local left_count=0
  local right_count=0
  local cursor=$3
  local left_pos=$cursor
  local right_pos=$cursor
  local content=$4

  if [[ "${content[$cursor]}" == "$left_char" ]]; then
    left_count=$((left_count + 1))
  elif [[ "${content[$cursor]}" == "$right_char" ]]; then
    right_count=$((right_count + 1))
  fi

  while true; do
    if (( left_count == 1 && right_count == 1 )); then
      echo $left_pos $right_pos
      return 0
    elif (( left_count > right_count )); then
      right_pos=$((right_pos + 1))

      local char="${content[$right_pos]}"
      if [[ "$char" == "$right_char" ]]; then
        right_count=$((right_count + 1))
      elif [[ "$char" == "$left_char" ]]; then
        right_count=$((right_count - 1))
      fi
    else
      left_pos=$((left_pos - 1))

      local char="${content[$left_pos]}"
      if [[ "$char" == "$left_char" ]]; then
        left_count=$((left_count + 1))
      elif [[ "$char" == "$right_char" ]]; then
        left_count=$((left_count - 1))
      fi
    fi

    if (( left_pos == 0 || right_pos > ${#content} )); then
      return 1
    fi
  done
}

# not updated
function zhm_select_surround_pair_around {
  local char="${KEYS:2}"
  local left
  local right
  case "$char" in
    "(" | ")")
      left="("
      right=")"
      ;;
    "[" | "]")
      left="["
      right="]"
      ;;
    "{" | "}")
      left="{"
      right="}"
      ;;
    "<" | ">")
      left="<"
      right=">"
      ;;
    "'")
      left="'"
      right="'"
      ;;
    "\"")
      left="\""
      right="\""
      ;;
    "\`")
      left="\`"
      right="\`"
    ;;
  esac

  local result
  result=$(__zhm_find_surround_pair "$left" "$right" $((CURSOR + 1)) "$BUFFER")
  if (( $? != 0 )); then
    return
  fi
  local left=${result% *}
  local right=${result#* }
  if (( CURSOR == ZHM_SELECTION_RIGHT )); then
    ZHM_SELECTION_LEFT=$((left - 1))
    ZHM_SELECTION_RIGHT=$((right - 1))
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    ZHM_SELECTION_LEFT=$((left - 1))
    ZHM_SELECTION_RIGHT=$((right - 1))
    CURSOR=$ZHM_SELECTION_LEFT
  fi
  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_region_highlight
}

# not updated
function zhm_select_surround_pair_inner {
  local char="${KEYS:2}"
  local left
  local right
  case "$char" in
    "(" | ")")
      left="("
      right=")"
      ;;
    "[" | "]")
      left="["
      right="]"
      ;;
    "{" | "}")
      left="{"
      right="}"
      ;;
    "<" | ">")
      left="<"
      right=">"
      ;;
    "'")
      left="'"
      right="'"
      ;;
    "\"")
      left="\""
      right="\""
      ;;
    "\`")
      left="\`"
      right="\`"
    ;;
  esac

  local result
  result=$(__zhm_find_surround_pair "$left" "$right" $((CURSOR + 1)) "$BUFFER")
  if (( $? != 0 )); then
    return
  fi
  local left=${result% *}
  local right=${result#* }
  if (( CURSOR == ZHM_SELECTION_RIGHT )); then
    ZHM_SELECTION_LEFT=$((left))
    ZHM_SELECTION_RIGHT=$((right - 2))
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    ZHM_SELECTION_LEFT=$((left))
    ZHM_SELECTION_RIGHT=$((right - 2))
    CURSOR=$ZHM_SELECTION_LEFT
  fi
  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_region_highlight
}

# not updated
function zhm_match_brackets {
  local prev_cursor=$CURSOR
  local char="${BUFFER[$((CURSOR + 1))]}"
  local left
  local right
  case "$char" in
    "(" | ")")
      left="("
      right=")"
      ;;
    "[" | "]")
      left="["
      right="]"
      ;;
    "{" | "}")
      left="{"
      right="}"
      ;;
    "<" | ">")
      left="<"
      right=">"
      ;;
    "'")
      left="'"
      right="'"
      ;;
    "\"")
      left="\""
      right="\""
      ;;
    "\`")
      left="\`"
      right="\`"
      ;;
    *)
      return
      ;;
  esac
  local result=$(__zhm_find_surround_pair "$left" "$right" $((CURSOR + 1)) "$BUFFER")
  if [[ $? != 0 ]]; then
    return
  fi
  local left=${result% *}
  local right=${result#* }
  if (( ($CURSOR + 1) == $left )); then
    CURSOR=$((right - 1))
  elif (( ($CURSOR + 1) == $right )); then
    CURSOR=$((left - 1))
  fi

  __zhm_handle_goto_selection $prev_cursor

  __zhm_update_region_highlight
}

# not updated
function zhm_select_all {
  CURSOR=${#BUFFER}
  zhm_cursors_pos=($CURSOR)
  zhm_cursors_selection_left=(0)
  zhm_cursors_selection_right=($CURSOR)
  __zhm_update_region_highlight
}

# not updated
function zhm_collapse_selection {
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$CURSOR
  __zhm_update_region_highlight
}

# not updated
function zhm_flip_selections {
  if (( CURSOR == ZHM_SELECTION_RIGHT )); then
    CURSOR=$ZHM_SELECTION_LEFT
  else
    CURSOR=$ZHM_SELECTION_RIGHT
  fi
  __zhm_update_last_moved
  __zhm_update_region_highlight
}

# not updated
function zhm_ensure_selections_forward {
  CURSOR=$ZHM_SELECTION_RIGHT
  __zhm_update_last_moved
  __zhm_update_region_highlight
}

# not updated
function zhm_extend_to_line_bounds {
  local prev_cursor=$CURSOR
  local prev_right=$ZHM_SELECTION_RIGHT
  local prev_left=$ZHM_SELECTION_LEFT

  if [[ "${BUFFER:0:$ZHM_SELECTION_LEFT}" =~ $'[^\n]*$' ]]; then
    ZHM_SELECTION_LEFT=$((MBEGIN - 1))
  fi
  if [[ "${BUFFER:$ZHM_SELECTION_RIGHT}" =~ $'^[^\n]*\n|^[^\n]*$' ]]; then
    ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + MEND - 1))
  fi
  if (( prev_cursor == prev_right )); then
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    CURSOR=$ZHM_SELECTION_LEFT
  fi
  __zhm_update_last_moved
  __zhm_update_region_highlight
}

# not updated
function zhm_extend_line_below {
  if [[ "$BUFFER[$((ZHM_SELECTION_LEFT + 1))]" == $'\n' ]]; then
    if [[ "${BUFFER:0:$ZHM_SELECTION_LEFT}" =~ $'[^\n]*$' ]]; then
      ZHM_SELECTION_LEFT=$((MBEGIN - 1))
    fi
  else
    if [[ "${BUFFER:0:$ZHM_SELECTION_LEFT}" =~ $'[^\n]*$' ]]; then
      ZHM_SELECTION_LEFT=$((MBEGIN - 1))
    fi

    local regex
    if [[ "${BUFFER[$((ZHM_SELECTION_RIGHT + 1))]}" == $'\n' ]]; then
      regex=$'^\n[^\n]*\n|^\n[^\n]*$'
    else
      regex=$'^[^\n]*\n|^[^\n]*$'
    fi
    if [[ "${BUFFER:$ZHM_SELECTION_RIGHT}" =~ $regex ]]; then
      ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + MEND - 1))
    fi
  fi
  CURSOR=$ZHM_SELECTION_RIGHT
  __zhm_update_last_moved
  __zhm_update_region_highlight
}

# not updated
function zhm_normal {
  if [[ $ZHM_MODE == insert ]]; then
    for i in {1..$#zhm_cursors_pos}; do
      local cursor=$zhm_cursors_pos[$i]
      if (( cursor > zhm_cursors_selection_right[i] )); then
        zhm_cursors_pos[$i]=$((cursor - 1))
      fi
    done
    CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]

    __zhm_update_changes_history_post
  fi
  __zhm_mode_normal
  __zhm_update_region_highlight
}

# not updated
function zhm_select {
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  else
    __zhm_mode_select
  fi
}

function zhm_insert {
  for i in {1..$#zhm_cursors_pos}; do
    zhm_cursors_pos[$i]=$zhm_cursors_selection_left[$i]
  done
  CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]
  __zhm_update_changes_history_pre
  __zhm_mode_insert
  __zhm_update_region_highlight
}

function zhm_insert_at_line_end {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local rbuffer="${BUFFER:$cursor}"
    if [[ $rbuffer =~ $'^[^\n]+' ]]; then
      zhm_cursors_pos[$i]=$((cursor + MEND))
    elif [[ "${BUFFER[$cursor,$((cursor + 1))]}" != $'\n\n' ]]; then
      zhm_cursors_pos[$i]=$((cursor))
    fi
    zhm_cursors_selection_left[$i]=$zhm_cursors_pos[$i]
    zhm_cursors_selection_right[$i]=$zhm_cursors_pos[$i]
  done
  zhm_insert
}

function zhm_insert_at_line_start {
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local lbuffer="${BUFFER:0:$cursor}"
    if [[ $lbuffer =~ $'[^\n]*$' ]]; then
      zhm_cursors_pos[$i]=$((MBEGIN - 1))
    fi
    zhm_cursors_selection_left[$i]=$zhm_cursors_pos[$i]
    zhm_cursors_selection_right[$i]=$zhm_cursors_pos[$i]
  done
  zhm_insert
}

function zhm_append {
  for i in {1..$#zhm_cursors_pos}; do
    zhm_cursors_pos[$i]=$((zhm_cursors_selection_right[i] + 1))
  done
  CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]
  __zhm_update_changes_history_pre
  __zhm_mode_insert
  __zhm_update_region_highlight
}

# not updated
function zhm_change {
  local register
  register=$(__zhm_user_specified_register)
  if (( $? != 0 )); then
    register="\""
  fi

  __zhm_write_register "$register" "${BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]}"

  BUFFER="${BUFFER:0:$ZHM_SELECTION_LEFT}${BUFFER:$((ZHM_SELECTION_RIGHT + 1))}"
  ZHM_SELECTION_RIGHT=$ZHM_SELECTION_LEFT
  CURSOR=$ZHM_SELECTION_LEFT
  __zhm_mode_insert
  __zhm_update_region_highlight
}

# not updated
function zhm_replace {
  local char="${KEYS:1}"
  local count=$((ZHM_SELECTION_RIGHT - ZHM_SELECTION_LEFT + 1))
  local replace_with=$(printf "$char"'%.0s' {1..$count})
  BUFFER="${BUFFER:0:$ZHM_SELECTION_LEFT}$replace_with${BUFFER:$((ZHM_SELECTION_RIGHT + 1))}"
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi
  __zhm_update_editor_history "$BUFFER" $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
}

# not updated
function zhm_delete {
  # local register
  # register=$(__zhm_user_specified_register)
  # if (( $? != 0 )); then
  #   register="\""
  # fi

  # __zhm_write_register "$register" "${BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]}"
  __zhm_update_changes_history_pre

  local amount_deleted=0
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$((zhm_cursors_pos[i] - amount_deleted))
    local left=$((zhm_cursors_selection_left[$i] - amount_deleted))
    local right=$((zhm_cursors_selection_right[$i] - amount_deleted))

    BUFFER="${BUFFER:0:$left}${BUFFER:$((right + 1))}"

    zhm_cursors_selection_left[$i]=$left
    zhm_cursors_selection_right[$i]=$left
    zhm_cursors_pos[$i]=$left

    amount_deleted=$((amount_deleted + right - left + 1))
  done
  CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]

  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi

  __zhm_update_changes_history_post
  __zhm_update_region_highlight
}

function zhm_undo {
  if (( ZHM_CHANGES_HISTORY_IDX > 1 )); then
    ZHM_CHANGES_HISTORY_IDX=$((ZHM_CHANGES_HISTORY_IDX - 1))
    BUFFER="$zhm_changes_history_buffer[$ZHM_CHANGES_HISTORY_IDX]"
    local idx=$zhm_changes_history_cursors_idx_starts_pre[$((ZHM_CHANGES_HISTORY_IDX + 1))]
    local count=$zhm_changes_history_cursors_count[$((ZHM_CHANGES_HISTORY_IDX + 1))]
    zhm_cursors_pos=(
      $zhm_changes_history_cursors_pos_pre[$idx,$((idx + count))]
    )
    zhm_cursors_selection_left=(
      $zhm_changes_history_cursors_selection_left_pre[$idx,$((idx + count))]
    )
    zhm_cursors_selection_right=(
      $zhm_changes_history_cursors_selection_right_pre[$idx,$((idx + count))]
    )
    zhm_cursors_last_moved_x=("${zhm_cursors_pos[@]}")
    ZHM_PRIMARY_CURSOR_IDX=$zhm_changes_history_primary_cursor_pre[$((ZHM_CHANGES_HISTORY_IDX + 1))]
    CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]
    ZHM_HOOK_IKNOWWHATIMDOING=1
    __zhm_update_region_highlight
  fi
}

function zhm_redo {
  if (( ZHM_CHANGES_HISTORY_IDX < ${#zhm_changes_history_buffer} )); then
    ZHM_CHANGES_HISTORY_IDX=$((ZHM_CHANGES_HISTORY_IDX + 1))
    BUFFER="$zhm_changes_history_buffer[$ZHM_CHANGES_HISTORY_IDX]"
    local idx=$zhm_changes_history_cursors_idx_starts_post[$ZHM_CHANGES_HISTORY_IDX]
    local count=$zhm_changes_history_cursors_count[$ZHM_CHANGES_HISTORY_IDX]
    zhm_cursors_pos=(
      $zhm_changes_history_cursors_pos_post[$idx,$((idx + count))]
    )
    zhm_cursors_selection_left=(
      $zhm_changes_history_cursors_selection_left_post[$idx,$((idx + count))]
    )
    zhm_cursors_selection_right=(
      $zhm_changes_history_cursors_selection_right_post[$idx,$((idx + count))]
    )
    zhm_cursors_last_moved_x=("${zhm_cursors_pos[@]}")
    ZHM_PRIMARY_CURSOR_IDX=$zhm_changes_history_primary_cursor_post[$ZHM_CHANGES_HISTORY_IDX]
    CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]
    ZHM_HOOK_IKNOWWHATIMDOING=1
    __zhm_update_region_highlight
  fi
}

# not updated
function zhm_yank {
  local register
  register=$(__zhm_user_specified_register)
  if (( $? != 0 )); then
    register="\""
  fi
  local content="$BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]"
  __zhm_write_register "$register" "$content"
  if [[ $ZHM_MODE == "select" ]]; then
    __zhm_mode_normal
  fi
}

# not updated
function zhm_paste_after {
  local register
  register=$(__zhm_user_specified_register)
  if (( $? != 0 )); then
    register="\""
  fi
  local content=$(__zhm_read_register "$register")

  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  BUFFER="${BUFFER:0:$(($ZHM_SELECTION_RIGHT + 1))}$content${BUFFER:$((ZHM_SELECTION_RIGHT + 1))}"
  ZHM_SELECTION_LEFT=$((ZHM_SELECTION_RIGHT + 1))
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + ${#content}))
  if (( prev_cursor == prev_right )); then
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    CURSOR=$ZHM_SELECTION_LEFT
  fi
  __zhm_update_last_moved
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_region_highlight
  ZHM_HOOK_IKNOWWHATIMDOING=1
}

# not updated
function zhm_paste_before {
  local register
  register=$(__zhm_user_specified_register)
  if (( $? != 0 )); then
    register="\""
  fi
  local content=$(__zhm_read_register "$register")
  
  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  BUFFER="${BUFFER:0:$(($ZHM_SELECTION_LEFT))}$content${BUFFER:$ZHM_SELECTION_LEFT}"
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + ${#content} - 1))
  if (( prev_cursor == prev_right )); then
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    CURSOR=$ZHM_SELECTION_LEFT
  fi

  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_region_highlight
  __zhm_update_last_moved
  ZHM_HOOK_IKNOWWHATIMDOING=1
}

# not updated
function zhm_clipboard_yank {
  local ZHM_SELECTION_LEFT=$zhm_cursors_selection_left[$ZHM_PRIMARY_CURSOR_IDX]
  local ZHM_SELECTION_RIGHT=$zhm_cursors_selection_right[$ZHM_PRIMARY_CURSOR_IDX]
  print "$BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]" | eval $ZHM_CLIPBOARD_PIPE_CONTENT_TO
  if [[ $ZHM_MODE == "select" ]]; then
    __zhm_mode_normal
  fi
}

# not updated
function zhm_clipboard_paste_after {
  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  local content="$(eval $ZHM_CLIPBOARD_READ_CONTENT_FROM)"
  BUFFER="${BUFFER:0:$(($ZHM_SELECTION_RIGHT + 1))}$content${BUFFER:$((ZHM_SELECTION_RIGHT + 1))}"
  ZHM_SELECTION_LEFT=$((ZHM_SELECTION_RIGHT + 1))
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + ${#content}))
  if (( prev_cursor == prev_right )); then
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    CURSOR=$ZHM_SELECTION_LEFT
  fi

  __zhm_update_last_moved
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_region_highlight
  ZHM_HOOK_IKNOWWHATIMDOING=1
}

# not updated
function zhm_clipboard_paste_before {
  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  local content="$(eval $ZHM_CLIPBOARD_READ_CONTENT_FROM)"
  BUFFER="${BUFFER:0:$(($ZHM_SELECTION_LEFT))}$content${BUFFER:$ZHM_SELECTION_LEFT}"
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + ${#content} - 1))
  if (( prev_cursor == prev_right )); then
    CURSOR=$ZHM_SELECTION_RIGHT
  else
    CURSOR=$ZHM_SELECTION_LEFT
  fi

  __zhm_update_last_moved
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_region_highlight
  ZHM_HOOK_IKNOWWHATIMDOING=1
}

# not updated
function zhm_insert_register {
  local register="${KEYS:1}"
  local content=$(__zhm_read_register "$register")

  local prev_cursor=$CURSOR
  BUFFER="${BUFFER:0:$((CURSOR))}$content${BUFFER:$((CURSOR))}"

  if (( prev_cursor == ZHM_SELECTION_LEFT )); then
    ZHM_SELECTION_LEFT=$((ZHM_SELECTION_LEFT + ${#content}))
  fi
  CURSOR=$((CURSOR + ${#content}))
  __zhm_update_last_moved
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + ${#content}))
}

function zhm_self_insert {
  local char="${KEYS}"
  local inserted_count=0
  for i in {1..$#zhm_cursors_pos}; do
    local prev_cursor=$zhm_cursors_pos[$i]
    local cursor=$((prev_cursor + inserted_count))

    BUFFER="${BUFFER:0:$cursor}${char}${BUFFER:$cursor}"

    zhm_cursors_pos[$i]=$((cursor + 1))
    local left=$zhm_cursors_selection_left[$i]
    if (( prev_cursor == left )); then
      zhm_cursors_selection_left[$i]=$((left + inserted_count + 1))
    else
      zhm_cursors_selection_left[$i]=$((left + inserted_count))
    fi
    zhm_cursors_selection_right[$i]=$((zhm_cursors_selection_right[$i] + inserted_count + 1))

    zhm_cursors_last_moved_x[$i]=$((cursor + 1))
    inserted_count=$((inserted_count + 1))
  done
  CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]
  __zhm_update_region_highlight
}

function zhm_insert_newline {
  local inserted_count=0
  for i in {1..$#zhm_cursors_pos}; do
    local prev_cursor=$zhm_cursors_pos[$i]
    local cursor=$((prev_cursor + inserted_count))

    BUFFER="${BUFFER:0:$cursor}
${BUFFER:$cursor}"

    zhm_cursors_pos[$i]=$((cursor + 1))
    if (( i == ZHM_PRIMARY_CURSOR_IDX )); then
      CURSOR=$((cursor + 1))
    fi
    local left=$zhm_cursors_selection_left[$i]
    if (( prev_cursor == left )); then
      zhm_cursors_selection_left[$i]=$((left + inserted_count + 1))
    fi
    zhm_cursors_selection_right[$i]=$((zhm_cursors_selection_right[$i] + inserted_count + 1))

    zhm_cursors_last_moved_x[$i]=$((cursor + 1))
    inserted_count=$((inserted_count + 1))
  done
  __zhm_update_region_highlight
}

# not updated
function zhm_multiline {
  if (( ZHM_MULTILINE == 0 )); then
    PREDISPLAY="-- MULTILINE --
"
    ZHM_MULTILINE=1
  else
    PREDISPLAY=""
    ZHM_MULTILINE=0
  fi
}

function zhm_delete_char_backward {
  local removed_count=0
  for i in {1..$#zhm_cursors_pos}; do
    local cursor=$zhm_cursors_pos[$i]
    local prev_cursor=$cursor
    cursor=$((cursor - removed_count))

    if ((cursor > 0)); then
      BUFFER="${BUFFER:0:$((cursor - 1))}${BUFFER:$cursor}"

      zhm_cursors_pos[$i]=$((cursor - 1))

      if (( prev_cursor == zhm_cursors_selection_left[i] )); then
        zhm_cursors_selection_left[$i]=$((zhm_cursors_selection_left[i] - 1))
        zhm_cursors_selection_right[$i]=$((zhm_cursors_selection_right[i] - 1))
      else
        zhm_cursors_selection_right[$i]=$((zhm_cursors_selection_right[i] - 1))
        if (( zhm_cursors_selection_right[i] < zhm_cursors_selection_left[i] )); then
          zhm_cursors_selection_left[$i]=$zhm_cursors_selection_right[$i]
        fi
      fi
      removed_count=$((removed_count + 1))
    fi
  done
  CURSOR=$zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]

  __zhm_update_region_highlight
}

# not updated
function zhm_accept {
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0

  zle accept-line
  MARK=
  REGION_ACTIVE=0
}

# not updated
function zhm_accept_or_insert_newline {
  if (( ZHM_MULTILINE == 1 )); then
    zhm_insert_newline
  else
    zhm_accept
  fi
}

# not updated
function zhm_history_prev {
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0
  HISTNO=$((HISTNO - 1))
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
  __zhm_update_region_highlight
}

# not updated
function zhm_history_next {
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0
  HISTNO=$((HISTNO + 1))
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
  __zhm_update_region_highlight
}

# not updated
function zhm_expand_or_complete {
  local cursor_pos_before_expand=$CURSOR
  zle expand-or-complete
  ZHM_SELECTION_LEFT=$cursor_pos_before_expand
  ZHM_SELECTION_RIGHT=$CURSOR
  __zhm_update_region_highlight
}

# ==============================================================================

zle -N zhm_move_left
zle -N zhm_move_right
zle -N zhm_move_up
zle -N zhm_move_down
zle -N zhm_move_up_or_history_prev
zle -N zhm_move_down_or_history_next
zle -N zhm_find_till_char
zle -N zhm_find_next_char
zle -N zhm_till_prev_char
zle -N zhm_find_prev_char
zle -N zhm_repeat_last_motion

zle -N zhm_move_next_word_start
zle -N zhm_move_prev_word_start
zle -N zhm_move_next_word_end
zle -N zhm_move_next_long_word_start
zle -N zhm_move_prev_long_word_start
zle -N zhm_move_next_long_word_end
zle -N zhm_goto_first_line
zle -N zhm_goto_last_line
zle -N zhm_goto_line_start
zle -N zhm_goto_line_end
zle -N zhm_goto_line_first_nonwhitespace

zle -N zhm_match_brackets
zle -N zhm_surround_add
zle -N zhm_select_word_inner
zle -N zhm_select_word_around
zle -N zhm_select_long_word_inner
zle -N zhm_select_long_word_around
zle -N zhm_select_surround_pair_inner
zle -N zhm_select_surround_pair_around

zle -N zhm_select_all
zle -N zhm_collapse_selection
zle -N zhm_flip_selections
zle -N zhm_ensure_selections_forward
zle -N zhm_extend_line_below
zle -N zhm_extend_to_line_bounds

zle -N zhm_normal
zle -N zhm_select
zle -N zhm_insert
zle -N zhm_multiline
zle -N zhm_insert_at_line_end
zle -N zhm_insert_at_line_start
zle -N zhm_append
zle -N zhm_change
zle -N zhm_replace
zle -N zhm_delete
zle -N zhm_undo
zle -N zhm_redo

zle -N zhm_yank
zle -N zhm_paste_after
zle -N zhm_paste_before
zle -N zhm_clipboard_yank
zle -N zhm_clipboard_paste_after
zle -N zhm_clipboard_paste_before

zle -N zhm_insert_register
zle -N zhm_self_insert
zle -N zhm_insert_newline
zle -N zhm_delete_char_backward
zle -N zhm_accept
zle -N zhm_accept_or_insert_newline

zle -N zhm_history_next
zle -N zhm_history_prev
zle -N zhm_expand_or_complete

# ==============================================================================

function zhm_precmd {
  zhm_cursors_pos=(0)
  zhm_cursors_selection_left=(0)
  zhm_cursors_selection_right=(0)
  ZHM_PRIMARY_CURSOR_IDX=1

  ZHM_MULTILINE=0

  ZHM_CHANGES_HISTORY_IDX=1
  zhm_changes_history_buffer=("")
  zhm_changes_history_cursors_idx_starts_pre=(1)
  zhm_changes_history_cursors_count_pre=(1)
  zhm_changes_history_cursors_pos_pre=(0)
  zhm_changes_history_cursors_selection_left_pre=(0)
  zhm_changes_history_cursors_selection_right_pre=(0)
  zhm_changes_history_primary_cursor_pre=(1)
  zhm_changes_history_cursors_idx_starts_post=(1)
  zhm_changes_history_cursors_count_post=(1)
  zhm_changes_history_cursors_pos_post=(0)
  zhm_changes_history_cursors_selection_left_post=(0)
  zhm_changes_history_cursors_selection_right_post=(0)
  zhm_changes_history_primary_cursor_post=(1)

  case $ZHM_MODE in
    insert)
      printf "$ZHM_CURSOR_INSERT"
      __zhm_update_changes_history_pre
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
        for i in {1..$#zhm_cursors_pos}; do
          if (( CURSOR > ZHM_PREV_CURSOR )); then
            zhm_cursors_selection_right[$ZHM_PRIMARY_CURSOR_IDX]=$CURSOR
            zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]=$CURSOR
          elif (( CURSOR < ZHM_PREV_CURSOR )); then
            zhm_cursors_selection_left[$ZHM_PRIMARY_CURSOR_IDX]=$CURSOR
            zhm_cursors_pos[$ZHM_PRIMARY_CURSOR_IDX]=$CURSOR
          fi
        done
        ;;
    esac
  fi

  local buffer_len=$#BUFFER
  for i in {1..$#zhm_cursors_pos}; do
    local pos=$zhm_cursors_pos[$i]
    local left=$zhm_cursors_selection_left[$i]
    local right=$zhm_cursors_selection_right[$i]

    zhm_cursors_pos[$i]=$((pos < buffer_len ? pos : buffer_len))
    local pos=$zhm_cursors_pos[$i]
    zhm_cursors_pos[$i]=$((pos > 0 ? pos: 0))
    zhm_cursors_selection_left[$i]=$((left < buffer_len ? left : buffer_len))
    local left=$zhm_cursors_selection_left[$i]
    zhm_cursors_selection_left[$i]=$((left > 0 ? left : 0))
    zhm_cursors_selection_right[$i]=$((right < buffer_len ? right : buffer_len))
    local right=$zhm_cursors_selection_right[$i]
    zhm_cursors_selection_right[$i]=$((right > 0 ? right: 0))
  done

  __zhm_update_region_highlight

  ZHM_HOOK_IKNOWWHATIMDOING=0
  ZHM_PREV_CURSOR=$CURSOR
  ZHM_PREV_MODE=$ZHM_MODE
}

add-zle-hook-widget zle-line-pre-redraw zhm_zle_line_pre_redraw

printf "$ZHM_CURSOR_INSERT"

# ==============================================================================

bindkey -N hxnor
bindkey -N hxins

bindkey -A hxins main

bindkey -M hxnor h zhm_move_left
bindkey -M hxnor l zhm_move_right
bindkey -M hxnor k zhm_move_up_or_history_prev
bindkey -M hxnor j zhm_move_down_or_history_next

bindkey -M hxnor w zhm_move_next_word_start
bindkey -M hxnor b zhm_move_prev_word_start
bindkey -M hxnor e zhm_move_next_word_end
bindkey -M hxnor W zhm_move_next_long_word_start
bindkey -M hxnor B zhm_move_prev_long_word_start
bindkey -M hxnor E zhm_move_next_long_word_end
for char in {" ".."~"}; do
  bindkey -M hxnor "t$char" zhm_find_till_char
  bindkey -M hxnor "f$char" zhm_find_next_char
  bindkey -M hxnor "T$char" zhm_till_prev_char
  bindkey -M hxnor "F$char" zhm_find_prev_char
done
bindkey -M hxnor "^[." zhm_repeat_last_motion
bindkey -M hxnor gg zhm_goto_first_line
bindkey -M hxnor ge zhm_goto_last_line
bindkey -M hxnor gh zhm_goto_line_start
bindkey -M hxnor gl zhm_goto_line_end
bindkey -M hxnor gs zhm_goto_line_first_nonwhitespace

for char in {" ".."~"}; do; bindkey -M hxnor "ms$char" zhm_surround_add; done

bindkey -M hxnor mm zhm_match_brackets
surround_pairs=("(" ")" "[" "]" "<" ">" "{" "}" "\"" "'" "\`")
for char in $surround_pairs; do
  bindkey -M hxnor "mi$char" zhm_select_surround_pair_inner
  bindkey -M hxnor "ma$char" zhm_select_surround_pair_around
done
bindkey -M hxnor "miw" zhm_select_word_inner
bindkey -M hxnor "maw" zhm_select_word_around
bindkey -M hxnor "miW" zhm_select_long_word_inner
bindkey -M hxnor "maW" zhm_select_long_word_around

bindkey -M hxnor % zhm_select_all
bindkey -M hxnor \; zhm_collapse_selection
bindkey -M hxnor "^[;" zhm_flip_selections
bindkey -M hxnor "^[:" zhm_ensure_selections_forward
bindkey -M hxnor x zhm_extend_line_below
bindkey -M hxnor X zhm_extend_to_line_bounds

# bindkey -M hxins "jk" zhm_normal
bindkey -M hxins "^[" zhm_normal
bindkey -M hxnor "^[^M" zhm_multiline
bindkey -M hxnor "^[^J" zhm_multiline
bindkey -M hxins "^[^M" zhm_multiline
bindkey -M hxins "^[^J" zhm_multiline
bindkey -M hxnor v zhm_select
bindkey -M hxnor i zhm_insert
bindkey -M hxnor I zhm_insert_at_line_start
bindkey -M hxnor A zhm_insert_at_line_end
bindkey -M hxnor a zhm_append
bindkey -M hxnor c zhm_change
for char in {" ".."~"}; do
  bindkey -M hxnor "r$char" zhm_replace
done
bindkey -M hxnor d zhm_delete
bindkey -M hxnor u zhm_undo
bindkey -M hxnor U zhm_redo

bindkey -M hxnor "y" zhm_yank
bindkey -M hxnor "p" zhm_paste_after
bindkey -M hxnor "P" zhm_paste_before
bindkey -M hxnor " y" zhm_clipboard_yank
bindkey -M hxnor " p" zhm_clipboard_paste_after
bindkey -M hxnor " P" zhm_clipboard_paste_before

for char in {" ".."~"}; do
  bindkey -M hxnor "\"${char}p" zhm_paste_after
  bindkey -M hxnor "\"${char}P" zhm_paste_before
  bindkey -M hxnor "\"${char}d" zhm_delete
  bindkey -M hxnor "\"${char}c" zhm_change
  bindkey -M hxnor "\"${char}y" zhm_yank
done

bindkey -M hxnor ^N zhm_history_next
bindkey -M hxnor ^P zhm_history_prev

for char in {" ".."~"}; do
  bindkey -M hxins "^R$char" zhm_insert_register
done
bindkey -M hxins -R " "-"~" zhm_self_insert
bindkey -M hxins "^?" zhm_delete_char_backward
bindkey -M hxnor "^J" zhm_accept
bindkey -M hxnor "^M" zhm_accept
bindkey -M hxins "^J" zhm_accept_or_insert_newline
bindkey -M hxins "^M" zhm_accept_or_insert_newline

bindkey -M hxins "^N" zhm_history_next
bindkey -M hxins "^P" zhm_history_prev
bindkey -M hxins "^I" zhm_expand_or_complete
