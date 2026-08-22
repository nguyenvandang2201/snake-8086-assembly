include "emu8086.inc"

.MODEL small
.STACK 100h

VIDEO_SEGMENT      EQU 0B800h
ROW_SIZE_BYTES     EQU 160
TOP_PLAY_OFFSET    EQU 320
BOTTOM_WALL_OFFSET EQU 3840
START_POSITION     EQU 07D2h
MAX_SNAKE_LENGTH   EQU 5
LETTER_COUNT       EQU 4

.DATA
    ; Menu and status text
    title_text       db "SNAKE - TEAM 22$"
    objective_text   db "Collect the letters in this order: N -> A -> K -> E$"
    controls_text    db "Move: W A S D    Exit: Esc$"
    rules_text       db "A wrong letter, a wall, or your own body costs one life.$"
    start_text       db "Press any key to start...$"
    lives_text       db "Lives: $"
    progress_text    db "Target: SNAKE$"

    win_text         db "YOU WIN!$"
    game_over_text   db "GAME OVER$"
    end_text         db "Press R to play again or Esc to exit.$"

    ; Fixed letter positions in the 80x25 text buffer
    default_letter_addresses dw 09B4h, 0848h, 06B0h, 01E8h
    letter_addresses         dw LETTER_COUNT Dup(0)
    expected_letters         db "NAKE"

    ; Six address slots are required: five visible segments plus the old tail.
    snake_addresses dw (MAX_SNAKE_LENGTH + 1) Dup(0)
    snake_chars     db (MAX_SNAKE_LENGTH + 1) Dup(0)
    snake_length    db 1
    letters_left    db LETTER_COUNT
    lives           db 3
    current_direction db 'D'
    quit_requested  db 0

.CODE

start:
    mov ax, @data
    mov ds, ax
    cld

    call show_menu

new_game:
    mov lives, 3
    mov quit_requested, 0
    call reset_round
    call draw_game

game_loop:
    call read_input
    cmp quit_requested, 1
    je exit_game

    call wait_frame
    call step_snake

    cmp al, 1
    je lose_life
    cmp al, 2
    je player_won
    jmp game_loop

lose_life:
    dec lives
    cmp lives, 0
    je player_lost

    call reset_round
    call draw_game
    jmp game_loop

player_won:
    call show_win_screen
    cmp al, 1
    je new_game
    jmp exit_game

player_lost:
    call show_game_over_screen
    cmp al, 1
    je new_game

exit_game:
    call clear_screen
    mov ax, 4C00h
    int 21h

; -----------------------------------------------------------------------------
; Screens
; -----------------------------------------------------------------------------

show_menu proc
    call clear_screen
    call draw_border

    GOTOXY 31, 3
    lea dx, title_text
    call print_string

    GOTOXY 13, 8
    lea dx, objective_text
    call print_string

    GOTOXY 23, 11
    lea dx, controls_text
    call print_string

    GOTOXY 10, 14
    lea dx, rules_text
    call print_string

    GOTOXY 27, 19
    lea dx, start_text
    call print_string

    mov ah, 07h
    int 21h
    ret
show_menu endp

draw_game proc
    call clear_screen
    call draw_border

    GOTOXY 2, 0
    lea dx, lives_text
    call print_string
    mov dl, lives
    add dl, '0'
    mov ah, 02h
    int 21h

    GOTOXY 33, 0
    lea dx, progress_text
    call print_string

    GOTOXY 63, 0
    lea dx, title_text
    call print_string

    call draw_letters
    call draw_snake
    ret
draw_game endp

show_win_screen proc
    call clear_screen
    call draw_border

    GOTOXY 35, 11
    lea dx, win_text
    call print_string

    GOTOXY 21, 14
    lea dx, end_text
    call print_string

    call wait_for_replay
    ret
show_win_screen endp

show_game_over_screen proc
    call clear_screen
    call draw_border

    GOTOXY 34, 11
    lea dx, game_over_text
    call print_string

    GOTOXY 21, 14
    lea dx, end_text
    call print_string

    call wait_for_replay
    ret
show_game_over_screen endp

wait_for_replay proc
wait_for_replay_key:
    mov ah, 07h
    int 21h

    cmp al, 1Bh
    je replay_no
    cmp al, 'r'
    je replay_yes
    cmp al, 'R'
    je replay_yes
    jmp wait_for_replay_key

replay_yes:
    mov al, 1
    ret

replay_no:
    xor al, al
    ret
wait_for_replay endp

; -----------------------------------------------------------------------------
; Input and timing
; -----------------------------------------------------------------------------

read_input proc
    push ax

    mov ah, 01h
    int 16h
    jnz input_available
    jmp input_done

input_available:
    mov ah, 00h
    int 16h

    cmp al, 1Bh
    jne input_not_escape
    mov quit_requested, 1
    jmp input_done

input_not_escape:
    cmp al, 'a'
    jb input_is_uppercase
    cmp al, 'z'
    ja input_is_uppercase
    sub al, 20h

input_is_uppercase:
    cmp al, 'W'
    je input_up
    cmp al, 'S'
    je input_down
    cmp al, 'A'
    je input_left
    cmp al, 'D'
    je input_right
    jmp input_done

input_up:
    cmp snake_length, 1
    jbe set_up
    cmp current_direction, 'S'
    je input_done
set_up:
    mov current_direction, 'W'
    jmp input_done

input_down:
    cmp snake_length, 1
    jbe set_down
    cmp current_direction, 'W'
    je input_done
set_down:
    mov current_direction, 'S'
    jmp input_done

input_left:
    cmp snake_length, 1
    jbe set_left
    cmp current_direction, 'D'
    je input_done
set_left:
    mov current_direction, 'A'
    jmp input_done

input_right:
    cmp snake_length, 1
    jbe set_right
    cmp current_direction, 'A'
    je input_done
set_right:
    mov current_direction, 'D'
    jmp input_done

input_done:
    pop ax
    ret
read_input endp

wait_frame proc
    push ax
    push cx
    push dx

    ; BIOS wait: 120,000 microseconds (0001:D4C0h).
    mov ah, 86h
    mov cx, 0001h
    mov dx, 0D4C0h
    int 15h
    jnc frame_done

    ; Small fallback for BIOS implementations without INT 15h/AH=86h.
    mov cx, 0FFFFh
frame_fallback:
    loop frame_fallback

frame_done:
    pop dx
    pop cx
    pop ax
    ret
wait_frame endp

; -----------------------------------------------------------------------------
; Game state
; -----------------------------------------------------------------------------

reset_round proc
    push ax
    push bx
    push cx
    push si

    mov snake_length, 1
    mov letters_left, LETTER_COUNT
    mov current_direction, 'D'

    xor si, si
    xor bx, bx
    mov cx, MAX_SNAKE_LENGTH + 1
clear_snake_state:
    mov word ptr snake_addresses[si], 0
    mov byte ptr snake_chars[bx], 0
    add si, 2
    inc bx
    loop clear_snake_state

    mov word ptr snake_addresses[0], START_POSITION
    mov byte ptr snake_chars[0], 'S'

    xor si, si
    mov cx, LETTER_COUNT
restore_letters:
    mov bx, default_letter_addresses[si]
    mov letter_addresses[si], bx
    add si, 2
    loop restore_letters

    pop si
    pop cx
    pop bx
    pop ax
    ret
reset_round endp

step_snake proc
    push bx
    push cx
    push dx
    push si
    push di

    call shift_snake_addresses

    mov al, current_direction
    cmp al, 'A'
    je step_left
    cmp al, 'W'
    je step_up
    cmp al, 'S'
    je step_down

step_right:
    add word ptr snake_addresses[0], 2
    jmp step_check

step_left:
    sub word ptr snake_addresses[0], 2
    jmp step_check

step_up:
    sub word ptr snake_addresses[0], ROW_SIZE_BYTES
    jmp step_check

step_down:
    add word ptr snake_addresses[0], ROW_SIZE_BYTES

step_check:
    call check_collision
    cmp al, 1
    je step_done

    push ax
    call draw_snake
    pop ax

step_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
step_snake endp

shift_snake_addresses proc
    push ax
    push bx
    push cx
    push dx

    xor ch, ch
    mov cl, snake_length
    xor bx, bx
    mov bl, snake_length
    shl bx, 1

shift_address_loop:
    mov dx, snake_addresses[bx-2]
    mov snake_addresses[bx], dx
    sub bx, 2
    loop shift_address_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
shift_snake_addresses endp

; Return AL = 0 for a normal move, 1 for a lost life, 2 for a win.
check_collision proc
    push bx
    push cx
    push dx
    push si
    push di

    mov di, snake_addresses[0]

    ; Top/bottom boundaries. Row 2 is the first playable row.
    cmp di, TOP_PLAY_OFFSET
    jae collision_check_bottom
    jmp collision_bad

collision_check_bottom:
    cmp di, BOTTOM_WALL_OFFSET
    jb collision_check_columns
    jmp collision_bad

    ; Left/right boundaries (byte offsets 0 and 158 on each 160-byte row).
collision_check_columns:
    mov ax, di
    mov bl, ROW_SIZE_BYTES
    div bl
    cmp ah, 0
    jne collision_check_right
    jmp collision_bad

collision_check_right:
    cmp ah, 158
    jne collision_check_self
    jmp collision_bad

    ; Self collision: compare the new head with every previous segment.
collision_check_self:
    xor ch, ch
    mov cl, snake_length
    mov si, 2
self_collision_loop:
    cmp di, snake_addresses[si]
    jne self_collision_next
    jmp collision_bad

self_collision_next:
    add si, 2
    loop self_collision_loop

    ; Check whether the head reached one of the active letters.
    xor si, si
    mov cx, LETTER_COUNT
letter_collision_loop:
    cmp di, letter_addresses[si]
    je collision_letter
    add si, 2
    loop letter_collision_loop

    xor al, al
    jmp collision_done

collision_letter:
    mov ax, VIDEO_SEGMENT
    mov es, ax
    mov dl, es:[di]

    xor bx, bx
    mov bl, snake_length
    dec bx
    cmp dl, expected_letters[bx]
    jne collision_bad

    inc bx
    mov snake_chars[bx], dl
    mov word ptr letter_addresses[si], 0
    inc snake_length
    dec letters_left

    cmp letters_left, 0
    je collision_win

    xor al, al
    jmp collision_done

collision_win:
    mov al, 2
    jmp collision_done

collision_bad:
    mov al, 1

collision_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
check_collision endp

; -----------------------------------------------------------------------------
; Rendering
; -----------------------------------------------------------------------------

draw_letters proc
    push ax
    push bx
    push cx
    push di
    push si

    mov ax, VIDEO_SEGMENT
    mov es, ax
    xor si, si
    xor bx, bx
    mov cx, LETTER_COUNT

draw_letter_loop:
    mov di, letter_addresses[si]
    cmp di, 0
    je skip_letter
    mov al, expected_letters[bx]
    mov es:[di], al

skip_letter:
    add si, 2
    inc bx
    loop draw_letter_loop

    pop si
    pop di
    pop cx
    pop bx
    pop ax
    ret
draw_letters endp

draw_snake proc
    push ax
    push bx
    push cx
    push di
    push si

    mov ax, VIDEO_SEGMENT
    mov es, ax

    ; Erase the old tail stored immediately after the visible segments.
    xor bx, bx
    mov bl, snake_length
    shl bx, 1
    mov di, snake_addresses[bx]
    cmp di, 0
    je draw_visible_snake
    mov byte ptr es:[di], 0

draw_visible_snake:
    xor ch, ch
    mov cl, snake_length
    xor si, si
    xor bx, bx

draw_snake_loop:
    mov di, snake_addresses[si]
    mov al, snake_chars[bx]
    mov es:[di], al
    add si, 2
    inc bx
    loop draw_snake_loop

    pop si
    pop di
    pop cx
    pop bx
    pop ax
    ret
draw_snake endp

draw_border proc
    push ax
    push cx
    push di

    mov ax, VIDEO_SEGMENT
    mov es, ax
    mov ax, 0B23h                 ; cyan '#' on black

    mov di, ROW_SIZE_BYTES       ; row 1
    mov cx, 80
    rep stosw

    mov di, BOTTOM_WALL_OFFSET   ; row 24
    mov cx, 80
    rep stosw

    mov di, TOP_PLAY_OFFSET      ; rows 2 through 23
    mov cx, 22
draw_vertical_borders:
    mov es:[di], ax
    mov es:[di+158], ax
    add di, ROW_SIZE_BYTES
    loop draw_vertical_borders

    pop di
    pop cx
    pop ax
    ret
draw_border endp

print_string proc
    mov ah, 09h
    int 21h
    ret
print_string endp

clear_screen proc
    push ax
    mov ax, 0003h
    int 10h
    pop ax
    ret
clear_screen endp

END start
