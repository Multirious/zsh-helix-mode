bindkey -N hnor
bindkey -N hins

bindkey -A hins main

bindkey -M hnor h zhm_move_left
bindkey -M hnor l zhm_move_right
bindkey -M hnor k zhm_move_up
bindkey -M hnor j zhm_move_down

bindkey -M hnor w zhm_move_next_word_start
bindkey -M hnor b zhm_move_prev_word_start
bindkey -M hnor e zhm_move_next_word_end
bindkey -M hnor gh zhm_goto_line_start
bindkey -M hnor gl zhm_goto_line_end
bindkey -M hnor gs zhm_goto_line_first_nonwhitespace
bindkey -M hnor % zhm_select_all
bindkey -M hnor \; zhm_collapse_selection
bindkey -M hnor x zhm_extend_line_below

# bindkey -M hins "jk" zhm_normal
bindkey -M hins "^[" zhm_normal
bindkey -M hnor v zhm_select
bindkey -M hnor i zhm_insert
bindkey -M hnor I zhm_insert_at_line_start
bindkey -M hnor A zhm_insert_at_line_end
bindkey -M hnor a zhm_append
bindkey -M hnor c zhm_change
for char in {" ".."~"}; do; bindkey -M hnor "r$char" zhm_replace; done
bindkey -M hnor d zhm_delete
bindkey -M hnor u zhm_undo
bindkey -M hnor U zhm_redo

bindkey -M hnor y zhm_clipboard_yank
bindkey -M hnor p zhm_clipboard_paste_after
bindkey -M hnor P zhm_clipboard_paste_before

bindkey -M hnor ^N zhm_history_next
bindkey -M hnor ^P zhm_history_prev
bindkey -M hnor "^J" zhm_accept
bindkey -M hnor "^M" zhm_accept

bindkey -M hins -R " "-"~" zhm_self_insert
bindkey -M hins "^?" zhm_delete_char_backward
bindkey -M hins "^J" zhm_accept
bindkey -M hins "^M" zhm_accept

bindkey -M hins "^N" zhm_history_next
bindkey -M hins "^P" zhm_history_prev
bindkey -M hins "^I" zhm_expand_or_complete
