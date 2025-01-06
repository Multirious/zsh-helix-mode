bindkey -N hxnor
bindkey -N hxins

bindkey -A hxins main

bindkey -M hxnor h zhm_move_left
bindkey -M hxnor l zhm_move_right
bindkey -M hxnor k zhm_move_up
bindkey -M hxnor j zhm_move_down

bindkey -M hxnor w zhm_move_next_word_start
bindkey -M hxnor b zhm_move_prev_word_start
bindkey -M hxnor e zhm_move_next_word_end
bindkey -M hxnor gh zhm_goto_line_start
bindkey -M hxnor gl zhm_goto_line_end
bindkey -M hxnor gs zhm_goto_line_first_nonwhitespace

for char in {" ".."~"}; do; bindkey -M hxnor "ms$char" zhm_surround_add; done

bindkey -M hxnor mm zhm_match_brackets
surround_pairs=("(" ")" "[" "]" "<" ">" "{" "}" "\"" "'" "\`")
for char in $surround_pairs; do
  bindkey -M hxnor "mi$char" zhm_select_surround_pair_inner
done
for char in $surround_pairs; do
  bindkey -M hxnor "ma$char" zhm_select_surround_pair_around
done

bindkey -M hxnor % zhm_select_all
bindkey -M hxnor \; zhm_collapse_selection
bindkey -M hxnor x zhm_extend_line_below

# bindkey -M hxins "jk" zhm_normal
bindkey -M hxins "^[" zhm_normal
bindkey -M hxnor v zhm_select
bindkey -M hxnor i zhm_insert
bindkey -M hxnor I zhm_insert_at_line_start
bindkey -M hxnor A zhm_insert_at_line_end
bindkey -M hxnor a zhm_append
bindkey -M hxnor c zhm_change
for char in {" ".."~"}; do; bindkey -M hxnor "r$char" zhm_replace; done
bindkey -M hxnor d zhm_delete
bindkey -M hxnor u zhm_undo
bindkey -M hxnor U zhm_redo

bindkey -M hxnor " y" zhm_clipboard_yank
bindkey -M hxnor " p" zhm_clipboard_paste_after
bindkey -M hxnor " P" zhm_clipboard_paste_before

bindkey -M hxnor ^N zhm_history_next
bindkey -M hxnor ^P zhm_history_prev
bindkey -M hxnor "^J" zhm_accept
bindkey -M hxnor "^M" zhm_accept

bindkey -M hxins -R " "-"~" zhm_self_insert
bindkey -M hxins "^?" zhm_delete_char_backward
bindkey -M hxins "^J" zhm_accept
bindkey -M hxins "^M" zhm_accept

bindkey -M hxins "^N" zhm_history_next
bindkey -M hxins "^P" zhm_history_prev
bindkey -M hxins "^I" zhm_expand_or_complete
