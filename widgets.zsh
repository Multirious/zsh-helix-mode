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
ZHM_EDITOR_HISTORY=("" 0 0 0 0 0 0)
ZHM_EDITOR_HISTORY_IDX=1
ZHM_BEFORE_INSERT_CURSOR=0
ZHM_BEFORE_INSERT_SELECTION_LEFT=0
ZHM_BEFORE_INSERT_SELECTION_RIGHT=0
ZHM_HOOK_IKNOWWHATIMDOING=0

function __zhm_update_mark {
  REGION_ACTIVE=1
  if (( (ZHM_SELECTION_RIGHT - ZHM_SELECTION_LEFT) <= 1 )); then
    MARK=$ZHM_SELECTION_LEFT
  elif (( (CURSOR + 1) == ZHM_SELECTION_RIGHT )); then
    MARK=$ZHM_SELECTION_LEFT
  elif (( CURSOR == ZHM_SELECTION_LEFT )); then
    MARK=$ZHM_SELECTION_RIGHT
  fi
}

function __zhm_update_editor_history {
  if [[ "$ZHM_EDITOR_HISTORY[$((ZHM_EDITOR_HISTORY_IDX * 7 - 6))]" != "$1" ]]; then
    if (( ${#ZHM_EDITOR_HISTORY} > ($ZHM_EDITOR_HISTORY_IDX * 7) )); then
      local count=$(((${#ZHM_EDITOR_HISTORY} - ZHM_EDITOR_HISTORY_IDX * 7) - 1))
      for i in {0..$count}; do
        shift -p ZHM_EDITOR_HISTORY
      done
    fi

    ZHM_EDITOR_HISTORY+=("$1")
    ZHM_EDITOR_HISTORY+=($2)
    ZHM_EDITOR_HISTORY+=($3)
    ZHM_EDITOR_HISTORY+=($4)
    ZHM_EDITOR_HISTORY+=($5)
    ZHM_EDITOR_HISTORY+=($6)
    ZHM_EDITOR_HISTORY+=($7)
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

function zhm_move_right {
  local prev_cursor=$CURSOR
  CURSOR=$((CURSOR + 1))
  if (( (prev_cursor + 1) >= ZHM_SELECTION_RIGHT )); then
    if [[ $ZHM_MODE != select ]]; then
      ZHM_SELECTION_LEFT=$ZHM_SELECTION_RIGHT
    fi
    ZHM_SELECTION_RIGHT=$((CURSOR + 1))
  elif (( prev_cursor <= ZHM_SELECTION_LEFT )); then
    ZHM_SELECTION_LEFT=$CURSOR
    if [[ $ZHM_MODE != select ]]; then
      ZHM_SELECTION_RIGHT=$((CURSOR + 1))
    fi
  fi

  __zhm_update_mark
}

function zhm_move_left {
  local prev_cursor=$CURSOR
  CURSOR=$((CURSOR - 1))
  if (( prev_cursor <= ZHM_SELECTION_LEFT )); then
    if [[ $ZHM_MODE != select ]]; then
      ZHM_SELECTION_RIGHT=$ZHM_SELECTION_LEFT
    fi
    ZHM_SELECTION_LEFT=$CURSOR
  elif (( (prev_cursor + 1) >= ZHM_SELECTION_RIGHT )); then
    ZHM_SELECTION_RIGHT=$((CURSOR + 1))
    if [[ $ZHM_MODE != select ]]; then
      ZHM_SELECTION_LEFT=$CURSOR
    fi
  fi

  __zhm_update_mark
}

function zhm_move_up {
  zle up-line
}

function zhm_move_down {
  zle down-line
}

function zhm_move_next_word_start {
  local prev_cursor=$CURSOR
  local substring="${BUFFER:$CURSOR}"
  if [[ $substring =~ '[a-zA-Z0-9_]+ *|[^a-zA-Z0-9_ ]+ *' ]]; then
    local skip=0
    CURSOR=$((CURSOR + MEND - 1))
    if (( MBEGIN > 1)); then
      skip=1
    fi
    if (( MEND <= 1)); then
      if [[ "${substring:1}" =~ '[a-zA-Z0-9_]+ *|[^a-zA-Z0-9_ ]+ *' ]]
      then
        CURSOR=$((CURSOR + MEND))
        skip=1
      fi
    fi

    if (( prev_cursor == ZHM_SELECTION_LEFT )); then
      if [[ $ZHM_MODE != select ]]; then
        ZHM_SELECTION_LEFT=$((prev_cursor + skip))
        ZHM_SELECTION_RIGHT=$((CURSOR + 1))
      else
        if (( CURSOR >= ZHM_SELECTION_RIGHT )); then
          ZHM_SELECTION_LEFT=$((ZHM_SELECTION_RIGHT - 1))
          ZHM_SELECTION_RIGHT=$((CURSOR + 1))
        else
          ZHM_SELECTION_LEFT=$CURSOR
        fi
      fi
    elif (( (prev_cursor + 1) == ZHM_SELECTION_RIGHT )); then
      if [[ $ZHM_MODE != select ]]; then
        ZHM_SELECTION_RIGHT=$((CURSOR + 1))
        ZHM_SELECTION_LEFT=$((prev_cursor + skip))
      else
        ZHM_SELECTION_RIGHT=$((CURSOR + 1))
      fi
    fi
  fi

  __zhm_update_mark
}

function zhm_move_prev_word_start {
  local prev_cursor=$CURSOR
  local rev_buffer="$(echo "$BUFFER" | rev)"
  local substring="${rev_buffer:$((-CURSOR - 1))}"
  if [[ $substring =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]]; then
    local skip=0
    if (( CURSOR == ${#BUFFER} )); then
     CURSOR=$((CURSOR - 1))
    fi
    CURSOR=$((CURSOR - MEND + 1))
    if (( MBEGIN > 1)); then
      skip=1
    fi
    if (( MEND <= 1)); then
      if [[ "${substring:1}" =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]]
      then
        CURSOR=$((CURSOR - MEND))
        skip=1
      fi
    fi

    if (( (prev_cursor + 1) == ZHM_SELECTION_RIGHT )); then
      if [[ $ZHM_MODE != select ]]; then
        ZHM_SELECTION_RIGHT=$((prev_cursor - skip + 1))
        ZHM_SELECTION_LEFT=$CURSOR
      else
        if (( CURSOR < ZHM_SELECTION_LEFT )); then
          ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + 1))
          ZHM_SELECTION_LEFT=$CURSOR
        else
          ZHM_SELECTION_RIGHT=$((CURSOR + 1))
        fi
      fi
    elif (( prev_cursor == ZHM_SELECTION_LEFT )); then
      ZHM_SELECTION_LEFT=$CURSOR
      if [[ $ZHM_MODE != select ]]; then
        ZHM_SELECTION_RIGHT=$((prev_cursor))
      fi
    fi
  fi

  __zhm_update_mark
}

function zhm_move_next_word_end {
  local prev_cursor=$CURSOR
  local substring="${BUFFER:$CURSOR}"
  if [[ $substring =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]]; then
    local skip=0
    CURSOR=$((CURSOR + MEND - 1))
    if (( MBEGIN > 1)); then
      skip=1
    fi
    if (( MEND <= 1)); then
      if [[ "${substring:1}" =~ ' *[a-zA-Z0-9_]+| *[^a-zA-Z0-9_ ]+| *' ]]
      then
        CURSOR=$((CURSOR + MEND))
        skip=1
      fi
    fi

    if (( prev_cursor == ZHM_SELECTION_LEFT )); then
      if [[ $ZHM_MODE != select ]]; then
        ZHM_SELECTION_LEFT=$((prev_cursor + skip))
        ZHM_SELECTION_RIGHT=$((CURSOR + 1))
      else
        if (( CURSOR >= ZHM_SELECTION_RIGHT )); then
          ZHM_SELECTION_LEFT=$((ZHM_SELECTION_RIGHT - 1))
          ZHM_SELECTION_RIGHT=$((CURSOR + 1))
        else
          ZHM_SELECTION_LEFT=$CURSOR
        fi
      fi
    elif (( (prev_cursor + 1) == ZHM_SELECTION_RIGHT )); then
      if [[ $ZHM_MODE != select ]]; then
        ZHM_SELECTION_RIGHT=$((CURSOR + 1))
        ZHM_SELECTION_LEFT=$((prev_cursor + skip))
      else
        ZHM_SELECTION_RIGHT=$((CURSOR + 1))
      fi
    fi
  fi

  __zhm_update_mark
}

function __zhm_handle_goto_selection {
  local prev_cursor=$1
  if [[ $ZHM_MODE != select ]]; then
    ZHM_SELECTION_LEFT=$CURSOR
    ZHM_SELECTION_RIGHT=$((CURSOR + 1))
  else
    if (( prev_cursor == ZHM_SELECTION_LEFT )); then
      if ((CURSOR < (ZHM_SELECTION_RIGHT - 1))); then
        ZHM_SELECTION_LEFT=$CURSOR
      else
        ZHM_SELECTION_LEFT=$((ZHM_SELECTION_RIGHT - 1))
        ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
      fi
    elif (( (prev_cursor + 1) == $ZHM_SELECTION_RIGHT )); then
      if ((CURSOR >= ZHM_SELECTION_LEFT)); then
        ZHM_SELECTION_RIGHT=$((CURSOR + 1))
      else
        ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + 1))
        ZHM_SELECTION_LEFT=$CURSOR
      fi
    fi
  fi
}

function zhm_goto_line_start {
  local prev_cursor=$CURSOR
  CURSOR=0

  __zhm_handle_goto_selection $prev_cursor

  __zhm_update_mark
}

function zhm_goto_line_end {
  local prev_cursor=$CURSOR
  CURSOR=$((${#BUFFER} - 1))

  __zhm_handle_goto_selection $prev_cursor

  __zhm_update_mark
}

function zhm_goto_line_first_nonwhitespace {
  local prev_cursor=$CURSOR
  if [[ $BUFFER =~ "\s*" ]]; then
    CURSOR=$MEND
  else
    CURSOR=0
  fi

  __zhm_handle_goto_selection $prev_cursor

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
  local buffer_right="${BUFFER:$ZHM_SELECTION_RIGHT}"
  local buffer_inner="${BUFFER:$ZHM_SELECTION_LEFT:$(($ZHM_SELECTION_RIGHT - $ZHM_SELECTION_LEFT))}"

  BUFFER="$buffer_left$left$buffer_inner$right$buffer_right"
  ZHM_SELECTION_LEFT=${#buffer_left}
  ZHM_SELECTION_RIGHT=$((${#buffer_left} + ${#left} + ${#buffer_inner} + ${#right}))
  if (( (prev_cursor + 1) == prev_right )); then
    CURSOR=$((ZHM_SELECTION_RIGHT - 1))
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

  local result=$(__zhm_find_surround_pair "$left" "$right" $((CURSOR + 1)) "$BUFFER")
  if [[ $? != 0 ]]; then
    return
  fi
  local left=${result% *}
  local right=${result#* }
  if (( (CURSOR + 1) == ZHM_SELECTION_RIGHT )); then
    ZHM_SELECTION_LEFT=$((left - 1))
    ZHM_SELECTION_RIGHT=$right
    CURSOR=$((ZHM_SELECTION_RIGHT - 1))
  else
    ZHM_SELECTION_LEFT=$((left - 1))
    ZHM_SELECTION_RIGHT=$right
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

  local result=$(__zhm_find_surround_pair "$left" "$right" $((CURSOR + 1)) "$BUFFER")
  if [[ $? != 0 ]]; then
    return
  fi
  local left=${result% *}
  local right=${result#* }
  if (( (CURSOR + 1) == ZHM_SELECTION_RIGHT )); then
    ZHM_SELECTION_LEFT=$left
    ZHM_SELECTION_RIGHT=$((right - 1))
    CURSOR=$((ZHM_SELECTION_RIGHT - 1))
  else
    ZHM_SELECTION_LEFT=$left
    ZHM_SELECTION_RIGHT=$((right - 1))
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
  ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
  __zhm_update_mark
}

function zhm_collapse_selection {
  ZHM_SELECTION_LEFT=$CURSOR
  ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
  __zhm_update_mark
}

# currently just select the whole buffer at the momment
function zhm_extend_line_below {
  CURSOR=${#BUFFER}
  ZHM_SELECTION_LEFT=0
  ZHM_SELECTION_RIGHT=$(($CURSOR + 1))
  __zhm_update_mark
}

function zhm_normal {
  if [[ $ZHM_MODE == insert ]]; then
    if [[ $CURSOR == $ZHM_SELECTION_RIGHT ]]; then
      if (( ZHM_SELECTION_LEFT < ZHM_SELECTION_RIGHT  )); then
        CURSOR=$((CURSOR - 1))
      else
        ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + 1))
      fi
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
  __zhm_update_mark
}

function zhm_insert {
  ZHM_BEFORE_INSERT_CURSOR=$CURSOR
  ZHM_BEFORE_INSERT_SELECTION_LEFT=$ZHM_SELECTION_LEFT
  ZHM_BEFORE_INSERT_SELECTION_RIGHT=$ZHM_SELECTION_RIGHT

  CURSOR=$ZHM_SELECTION_LEFT
  if ((ZHM_SELECTION_LEFT + 1 == ZHM_SELECTION_RIGHT)); then
    ZHM_SELECTION_RIGHT=$ZHM_SELECTION_LEFT
  fi

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
  ZHM_BEFORE_INSERT_CURSOR=$CURSOR
  ZHM_BEFORE_INSERT_SELECTION_LEFT=$ZHM_SELECTION_LEFT
  ZHM_BEFORE_INSERT_SELECTION_RIGHT=$ZHM_SELECTION_RIGHT
  CURSOR=$ZHM_SELECTION_RIGHT
  CURSOR=$((CURSOR - 1))
  __zhm_update_mark
  CURSOR=$((CURSOR + 1))

  __zhm_mode_insert
}

function zhm_change {
  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  ZHM_BEFORE_INSERT_CURSOR=$CURSOR
  ZHM_BEFORE_INSERT_SELECTION_LEFT=$ZHM_SELECTION_LEFT
  ZHM_BEFORE_INSERT_SELECTION_RIGHT=$ZHM_SELECTION_RIGHT

  BUFFER="${BUFFER:0:$ZHM_SELECTION_LEFT}${BUFFER:$ZHM_SELECTION_RIGHT}"
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + 1))
  CURSOR=$ZHM_SELECTION_LEFT

  __zhm_mode_insert

  __zhm_update_mark
}

function zhm_replace {
  local char="${KEYS:1}"
  local count=$((ZHM_SELECTION_RIGHT - ZHM_SELECTION_LEFT))
  local replace_with=$(printf "$char"'%.0s' {1..$count})
  BUFFER="${BUFFER:0:$ZHM_SELECTION_LEFT}$replace_with${BUFFER:$ZHM_SELECTION_RIGHT}"
  if [[ $ZHM_MODE == select ]]; then
    __zhm_mode_normal
  fi
  __zhm_update_editor_history "$BUFFER" $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
}

function zhm_delete {
  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  BUFFER="${BUFFER:0:$ZHM_SELECTION_LEFT}${BUFFER:$ZHM_SELECTION_RIGHT}"
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + 1))
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
    BUFFER="$ZHM_EDITOR_HISTORY[$(($ZHM_EDITOR_HISTORY_IDX * 7 - 6))]"
    CURSOR="$ZHM_EDITOR_HISTORY[$(((ZHM_EDITOR_HISTORY_IDX + 1) * 7 - 5))]"
    ZHM_SELECTION_LEFT="$ZHM_EDITOR_HISTORY[$(((ZHM_EDITOR_HISTORY_IDX + 1) * 7 - 4))]"
    ZHM_SELECTION_RIGHT="$ZHM_EDITOR_HISTORY[$(((ZHM_EDITOR_HISTORY_IDX + 1) * 7 - 3))]"
    __zhm_update_mark
  fi
}

function zhm_redo {
  if (((ZHM_EDITOR_HISTORY_IDX * 7) < ${#ZHM_EDITOR_HISTORY})); then
    ZHM_EDITOR_HISTORY_IDX=$((ZHM_EDITOR_HISTORY_IDX + 1))
    BUFFER="$ZHM_EDITOR_HISTORY[$(($ZHM_EDITOR_HISTORY_IDX * 7 - 6))]"
    CURSOR="$ZHM_EDITOR_HISTORY[$((ZHM_EDITOR_HISTORY_IDX * 7 - 2))]"
    ZHM_SELECTION_LEFT="$ZHM_EDITOR_HISTORY[$((ZHM_EDITOR_HISTORY_IDX * 7 - 1))]"
    ZHM_SELECTION_RIGHT="$ZHM_EDITOR_HISTORY[$((ZHM_EDITOR_HISTORY_IDX * 7))]"
    __zhm_update_mark
  fi
}

function zhm_clipboard_yank {
  echo -n "$BUFFER[$((ZHM_SELECTION_LEFT + 1)),$((ZHM_SELECTION_RIGHT))]" | eval $ZHM_CLIPBOARD_PIPE_CONTENT_TO
}

function zhm_clipboard_paste_after {
  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  local content="$(eval $ZHM_CLIPBOARD_READ_CONTENT_FROM)"
  BUFFER="${BUFFER:0:$(($ZHM_SELECTION_RIGHT))}$content${BUFFER:$ZHM_SELECTION_RIGHT}"
  ZHM_SELECTION_LEFT=$((ZHM_SELECTION_RIGHT))
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_RIGHT + ${#content}))
  if (( (prev_left + 1) == prev_right )); then
    CURSOR=$((ZHM_SELECTION_RIGHT - 1))
  elif (( prev_cursor == prev_left )); then
    CURSOR=$ZHM_SELECTION_LEFT
  else
    CURSOR=$((ZHM_SELECTION_RIGHT - 1))
  fi

  __zhm_update_editor_history "$BUFFER" $prev_cursor $prev_left $prev_right $CURSOR $ZHM_SELECTION_LEFT $ZHM_SELECTION_RIGHT
  __zhm_update_mark
}

function zhm_clipboard_paste_before {
  local prev_cursor=$CURSOR
  local prev_left=$ZHM_SELECTION_LEFT
  local prev_right=$ZHM_SELECTION_RIGHT

  local content="$(eval $ZHM_CLIPBOARD_READ_CONTENT_FROM)"
  BUFFER="${BUFFER:0:$(($ZHM_SELECTION_LEFT))}$content${BUFFER:$ZHM_SELECTION_LEFT}"
  ZHM_SELECTION_RIGHT=$((ZHM_SELECTION_LEFT + ${#content}))
  if (( (prev_left + 1) == prev_right )); then
    CURSOR=$((ZHM_SELECTION_LEFT))
  elif (( prev_cursor == prev_left )); then
    CURSOR=$ZHM_SELECTION_LEFT
  else
    CURSOR=$((ZHM_SELECTION_RIGHT - 1))
  fi

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
  fi

  __zhm_update_mark
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
  local curr_cursor_pos=$CURSOR
  zle expand-or-complete
  ZHM_SELECTION_LEFT=$curr_cursor_pos
  ZHM_SELECTION_RIGHT=$((CURSOR + 1))
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
