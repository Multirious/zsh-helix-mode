export ZHM_MODE=insert
ZHM_SELECTION_LEFT=0
ZHM_SELECTION_RIGHT=0
# - buffer
# - cursor position 1
# - selection position left 1
# - selection position right 1
# - cursor position 2
# - selection position left 2
# - selection position right 2
zhm_editor_history=("" 0 0 0 0 0 0)
declare -A zhm_registers
ZHM_EDITOR_HISTORY_IDX=1
ZHM_BEFORE_INSERT_CURSOR=0
ZHM_BEFORE_INSERT_SELECTION_LEFT=0
ZHM_BEFORE_INSERT_SELECTION_RIGHT=0
ZHM_HOOK_IKNOWWHATIMDOING=0

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

function __zhm_update_mark {
  REGION_ACTIVE=1
  if (( (ZHM_SELECTION_RIGHT - ZHM_SELECTION_LEFT) <= 0 )); then
    MARK=$ZHM_SELECTION_LEFT
  elif (( CURSOR == ZHM_SELECTION_RIGHT )); then
    MARK=$ZHM_SELECTION_LEFT
  elif (( CURSOR == ZHM_SELECTION_LEFT )); then
    MARK=$((ZHM_SELECTION_RIGHT + 1))
  fi
}

function __zhm_update_editor_history {
  if [[ "$zhm_editor_history[$((ZHM_EDITOR_HISTORY_IDX * 7 - 6))]" != "$1" ]]; then
    if (( ${#zhm_editor_history} > ($ZHM_EDITOR_HISTORY_IDX * 7) )); then
      local count=$(((${#zhm_editor_history} - ZHM_EDITOR_HISTORY_IDX * 7) - 1))
      for i in {0..$count}; do
        shift -p zhm_editor_history
      done
    fi

    zhm_editor_history+=("$1")
    zhm_editor_history+=($2)
    zhm_editor_history+=($3)
    zhm_editor_history+=($4)
    zhm_editor_history+=($5)
    zhm_editor_history+=($6)
    zhm_editor_history+=($7)
    ZHM_EDITOR_HISTORY_IDX=$((ZHM_EDITOR_HISTORY_IDX + 1))
  fi
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
  local prev_cursor=$CURSOR
  CURSOR=$1
  if [[ $ZHM_MODE != select ]]; then
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$CURSOR
  elif (( prev_cursor == ZHM_SELECTION_LEFT )); then
    if ((CURSOR <= ZHM_SELECTION_RIGHT)); then
      ZHM_SELECTION_LEFT=$CURSOR
    else
      ZHM_SELECTION_LEFT=$ZHM_SELECTION_RIGHT
      ZHM_SELECTION_RIGHT=$CURSOR
    fi
  elif (( prev_cursor == $ZHM_SELECTION_RIGHT )); then
    if ((CURSOR >= ZHM_SELECTION_LEFT)); then
      ZHM_SELECTION_RIGHT=$((CURSOR + 1))
    else
      ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + 1))
      ZHM_SELECTION_LEFT=$CURSOR
    fi
  fi
}

function __zhm_trailing_goto {
  if [[ $ZHM_MODE == select ]]; then
    __zhm_goto $1

    return
  fi

  local prev_cursor=$CURSOR
  CURSOR=$1
  local skip=$2

  if (( CURSOR > prev_cursor )); then
    ZHM_SELECTION_LEFT=$((prev_cursor + skip))
    ZHM_SELECTION_RIGHT=$CURSOR
  elif (( CURSOR < prev_cursor)); then
    ZHM_SELECTION_RIGHT=$((prev_cursor - skip))
    ZHM_SELECTION_LEFT=$CURSOR
  fi
}

function zhm_move_right {
  __zhm_goto $((CURSOR + 1))
  __zhm_update_mark
}

function zhm_move_left {
  __zhm_goto $((CURSOR - 1))
  __zhm_update_mark
}

function zhm_move_up {
  zle up-line
}

function zhm_move_down {
  zle down-line
}

function zhm_move_next_word_start {
  local substring="${BUFFER:$CURSOR}"
  if [[ $substring =~ '[a-zA-Z0-9_]+ *|[^a-zA-Z0-9_ ]+ *' ]]; then
    local skip=0
    local go=$((CURSOR + MEND - 1))

    if (( MBEGIN > 1)); then
      skip=1
    fi

    if (( MEND <= 1)) \
      && [[ "${substring:1}" =~ '[a-zA-Z0-9_]+ *|[^a-zA-Z0-9_ ]+ *' ]]
    then
      go=$((go + MEND))
      skip=1
    fi

    __zhm_trailing_goto $go $skip
    __zhm_update_mark
  fi
}

function zhm_move_prev_word_start {
  local rev_buffer="$(echo "$BUFFER" | rev)"
  local substring="${rev_buffer:$((-CURSOR - 1))}"
  if [[ $substring =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]]; then
    local skip=0

    local go=$CURSOR
    if (( go >= ${#BUFFER} )); then
     go=$((go - 1))
    fi

    go=$((go - MEND + 1))
    if (( MBEGIN > 1)); then
      skip=1
    fi
    if (( MEND <= 1)) \
      && [[ "${substring:1}" =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]];
    then
      go=$((go - MEND))
      skip=1
    fi

    __zhm_trailing_goto $go $skip
    __zhm_update_mark
  fi
}

function zhm_move_next_word_end {
  local substring="${BUFFER:$CURSOR}"
  if [[ $substring =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]]; then
    local skip=0
    local go=$((CURSOR + MEND - 1))
    if (( MBEGIN > 1)); then
      skip=1
    fi
    if (( MEND <= 1)) \
      && [[ "${substring:1}" =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]]
    then
      go=$((go + MEND))
      skip=1
    fi

    __zhm_trailing_goto $go $skip
    __zhm_update_mark
  fi
}

function zhm_goto_line_start {
  __zhm_goto 0
  __zhm_update_mark
}

function zhm_goto_line_end {
  __zhm_goto $((${#BUFFER} - 1))
  __zhm_update_mark
}

function zhm_goto_line_first_nonwhitespace {
  if [[ $BUFFER =~ "\s*" ]]; then
    __zhm_goto $MEND
  else
    __zhm_goto 0
  fi
  __zhm_update_mark
}

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
  __zhm_update_mark
}

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
  __zhm_update_mark
}

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
  __zhm_update_mark
}

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

  __zhm_update_mark
}

function zhm_select_all {
  CURSOR=${#BUFFER}
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=$CURSOR
  __zhm_update_mark
}

function zhm_collapse_selection {
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$CURSOR
  __zhm_update_mark
}

# currently just select the whole buffer at the momment
function zhm_extend_line_below {
  CURSOR=${#BUFFER}
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=$CURSOR
  __zhm_update_mark
}

function zhm_normal {
  if [[ $ZHM_MODE == insert ]]; then
    if (( CURSOR > ZHM_SELECTION_RIGHT )); then
      CURSOR=$((CURSOR - 1))
    fi

    __zhm_update_editor_history "$BUFFER" $ZHM_BEFORE_INSERT_CURSOR $ZHM_BEFORE_INSERT_SELECTION_LEFT $ZHM_BEFORE_INSERT_SELECTION_RIGHT $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  fi
  __zhm_mode_normal
  __zhm_update_mark
}

function zhm_select {
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  else
    __zhm_mode_select
  fi
}

function __zhm_save_state_before_insert {
  ZHM_BEFORE_INSERT_CURSOR=$CURSOR
  ZHM_BEFORE_INSERT_SELECTION_LEFT=$ZHM_SELECTION_LEFT
  ZHM_BEFORE_INSERT_SELECTION_RIGHT=$ZHM_SELECTION_RIGHT
}

function zhm_insert {
  __zhm_save_state_before_insert
  CURSOR=$ZHM_SELECTION_LEFT
  __zhm_mode_insert
  __zhm_update_mark
}

function zhm_insert_at_line_end {
  CURSOR=${#BUFFER}
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$CURSOR
  zhm_insert
}

function zhm_insert_at_line_start {
  CURSOR=0
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0
  zhm_insert
}

function zhm_append {
  __zhm_save_state_before_insert
  CURSOR=$((ZHM_SELECTION_RIGHT + 1))
  __zhm_mode_insert
  __zhm_update_mark
}

function zhm_change {
  local register
  register=$(__zhm_user_specified_register)
  if (( $? != 0 )); then
    register="\""
  fi

  __zhm_write_register "$register" "${BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]}"

  __zhm_save_state_before_insert
  BUFFER="${BUFFER:0:$ZHM_SELECTION_LEFT}${BUFFER:$((ZHM_SELECTION_RIGHT + 1))}"
  ZHM_SELECTION_RIGHT=$ZHM_SELECTION_LEFT
  CURSOR=$ZHM_SELECTION_LEFT
  __zhm_mode_insert
  __zhm_update_mark
}

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

function zhm_delete {
  local register
  register=$(__zhm_user_specified_register)
  if (( $? != 0 )); then
    register="\""
  fi

  __zhm_write_register "$register" "${BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]}"

  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  BUFFER="${BUFFER:0:$ZHM_SELECTION_LEFT}${BUFFER:$((ZHM_SELECTION_RIGHT + 1))}"
  ZHM_SELECTION_RIGHT=$ZHM_SELECTION_LEFT
  CURSOR=$ZHM_SELECTION_LEFT

  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi

  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_mark
}

function zhm_undo {
  if ((ZHM_EDITOR_HISTORY_IDX > 1)); then
    ZHM_EDITOR_HISTORY_IDX=$((ZHM_EDITOR_HISTORY_IDX - 1))
    BUFFER="$zhm_editor_history[$(($ZHM_EDITOR_HISTORY_IDX * 7 - 6))]"
    CURSOR="$zhm_editor_history[$(((ZHM_EDITOR_HISTORY_IDX + 1) * 7 - 5))]"
    ZHM_SELECTION_LEFT="$zhm_editor_history[$(((ZHM_EDITOR_HISTORY_IDX + 1) * 7 - 4))]"
    ZHM_SELECTION_RIGHT="$zhm_editor_history[$(((ZHM_EDITOR_HISTORY_IDX + 1) * 7 - 3))]"
    ZHM_HOOK_IKNOWWHATIMDOING=1
    __zhm_update_mark
  fi
}

function zhm_redo {
  if (((ZHM_EDITOR_HISTORY_IDX * 7) < ${#zhm_editor_history})); then
    ZHM_EDITOR_HISTORY_IDX=$((ZHM_EDITOR_HISTORY_IDX + 1))
    BUFFER="$zhm_editor_history[$(($ZHM_EDITOR_HISTORY_IDX * 7 - 6))]"
    CURSOR="$zhm_editor_history[$((ZHM_EDITOR_HISTORY_IDX * 7 - 2))]"
    ZHM_SELECTION_LEFT="$zhm_editor_history[$((ZHM_EDITOR_HISTORY_IDX * 7 - 1))]"
    ZHM_SELECTION_RIGHT="$zhm_editor_history[$((ZHM_EDITOR_HISTORY_IDX * 7))]"
    ZHM_HOOK_IKNOWWHATIMDOING=1
    __zhm_update_mark
  fi
}

function zhm_yank {
  local register
  register=$(__zhm_user_specified_register)
  if (( $? != 0 )); then
    register="\""
  fi
  local content="$BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]"
  __zhm_write_register "$register" "$content"
}

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

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_mark
}

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

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_mark
}

function zhm_clipboard_yank {
  echo -n "$BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT + 1))]" | eval $ZHM_CLIPBOARD_PIPE_CONTENT_TO
}

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

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_mark
}

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

  ZHM_HOOK_IKNOWWHATIMDOING=1
  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_mark
}

function zhm_self_insert {
  local prev_cursor=$CURSOR

  zle .self-insert

  if (( prev_cursor == ZHM_SELECTION_LEFT )); then
    ZHM_SELECTION_LEFT=$((ZHM_SELECTION_LEFT + 1))
  fi
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + 1))

  __zhm_update_mark
}

function zhm_insert_newline {
  local prev_cursor=$CURSOR
  # newline lol
  BUFFER="${BUFFER}
"
  CURSOR=$((CURSOR + 2))
  if (( prev_cursor == ZHM_SELECTION_LEFT )); then
    ZHM_SELECTION_LEFT=$((ZHM_SELECTION_LEFT + 2))
  fi
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + 2))
  __zhm_update_mark
}

function zhm_delete_char_backward {
  local prev_cursor=$CURSOR
  zle backward-delete-char

  if ((CURSOR > 0)); then
    if (( prev_cursor == ZHM_SELECTION_LEFT )); then
      ZHM_SELECTION_LEFT=$(($ZHM_SELECTION_LEFT - 1))
      ZHM_SELECTION_RIGHT=$(($ZHM_SELECTION_RIGHT - 1))
      ZHM_SELECTION_LEFT=$((ZHM_SELECTION_LEFT > 0 ? ZHM_SELECTION_LEFT : 0))
      ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT > 0 ? ZHM_SELECTION_RIGHT : 0))
    else
      ZHM_SELECTION_RIGHT=$(($ZHM_SELECTION_RIGHT - 1))
      if (( ZHM_SELECTION_RIGHT < ZHM_SELECTION_LEFT )); then
        ZHM_SELECTION_LEFT=$ZHM_SELECTION_RIGHT
      fi
    fi

    __zhm_update_mark
  fi
}

function zhm_accept {
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0

  zle accept-line
  MARK=
  REGION_ACTIVE=0
}

function zhm_history_prev {
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0
  HISTNO=$((HISTNO - 1))
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
  __zhm_update_mark
}

function zhm_history_next {
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=0
  HISTNO=$((HISTNO + 1))
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
  __zhm_update_mark
}

function zhm_expand_or_complete {
  local cursor_pos_before_expand=$CURSOR
  zle expand-or-complete
  ZHM_SELECTION_LEFT=$cursor_pos_before_expand
  ZHM_SELECTION_RIGHT=$CURSOR
  __zhm_update_mark
}

zle -N zhm_move_left
zle -N zhm_move_right
zle -N zhm_move_up
zle -N zhm_move_down

zle -N zhm_move_next_word_start
zle -N zhm_move_prev_word_start
zle -N zhm_move_next_word_end
zle -N zhm_goto_line_start
zle -N zhm_goto_line_end
zle -N zhm_goto_line_first_nonwhitespace

zle -N zhm_match_brackets
zle -N zhm_surround_add
zle -N zhm_select_surround_pair_inner
zle -N zhm_select_surround_pair_around

zle -N zhm_select_all
zle -N zhm_collapse_selection
zle -N zhm_extend_line_below

zle -N zhm_normal
zle -N zhm_select
zle -N zhm_insert
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

zle -N zhm_self_insert
zle -N zhm_insert_newline
zle -N zhm_delete_char_backward
zle -N zhm_accept

zle -N zhm_history_next
zle -N zhm_history_prev
zle -N zhm_expand_or_complete
