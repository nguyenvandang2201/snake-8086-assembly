include "emu8086.inc"
.Model small 

.Stack 100H   

.Data
    ;main screen
    screen1  db "Game Team 22$"
    screen2  db "In this game you must eat 4 letters by sequence:$"
    screen3  db "First eat 'N' then 'A' then 'K' then 'E'$"
    screen4  db "Move the snake by pressing the keys w,a,s,d$"
    screen5  db "w: move up$"
    screen6  db "s: move down$"
    screen7  db "d: move right$"
    screen8  db "a: move left$"
    screen9  db "The snake head is the 'S' in the middle of the screen$"
    screen10 db "Press any key to start...$"
    about db "This game is done by: TEAM 22$"   
    
    ;bild
    hlths  db "Lives:",3,3,3    
    
    ;pos
    posN EQU 09b4h
    posA EQU 0848h
    posK EQU 06b0h
    posE EQU 01E8h
    
    ;ingame
    letters_address  dw 09b4h,0848h,06b0h,01e8h,4 Dup(?)
    dletters_address dw 09b4h,0848h,06b0h,01e8h,4 Dup(?)
    letters_num  db 4
    letters_num_check  db 4
    hlth db 6   
    
    ;snake infomation
    snake_address dw 07d2h,5 Dup(?)
    snake db 'S',5 Dup(?)
    snake_len db 1
    
    ;end
    gmwin  db "You Win$"
    gmov   db "Game Over$"
    endtxt db "Press Esc to exit$"

.Code      
 
start:
    mov ax, @data    
    mov ds, ax ;tro thanh ghi ds ve dau doan data
    
    mov ax, 0b800h ; 0B800h là vùng nho video trong che do van ban (text mode) 80x25
    mov es, ax    
    
    cld ; DF = 0 
    
    
    print_screen_menu:
        call screen_menu ;print main screen: screen1 -> screen10      
    
    startag: ;start again
    
    call bild ;function display alphabet and border in game
    
    read: ;read cac cach di chuyen
        mov ah, 1
        int 16h       ;check xem co phim nao duoc nhan chua
        jz right      ;neu khong co thi jump den right
        
        mov ah, 0     ;doc ki tu dem tu ban phim (lay ki tu vua nhan)
        int 16h    
        sub al, 20h   ;convert chu thuong -> chu hoa
        mov dl, al
        jmp right
    
    right:    
        cmp dl, 'D'    ;di chuyen sang phai
        jne left
        call move_right
        jmp read       ;nhay sang read cach di chuyen tiep theo
    
    left: 
        cmp dl, 'A'
        jne up
        call move_left 
        jmp read 
    
    up: 
        cmp dl, 'W'
        jne down
        call move_up
        jmp read 
    
    down: 
        cmp dl, 'S'
        jne read
        call move_down
        jmp read  
    
    exit:
        call clear_all
    ;return 0
    mov ax, 4ch ; exit to operating system.
    int 21h
ends 

screen_menu proc    ;ham in khung hinh tu screen1 den screen10
    call border   
    
    ;in "Game Team 2"
    GOTOXY 35, 2
    lea dx, screen1 
    mov ah,9
    int 21h 
    
    GOTOXY 16, 6
    lea dx, screen2 
    mov ah,9
    int 21h 
    
    GOTOXY 16, 7
    lea dx, screen3 
    mov ah,9
    int 21h 
    
    GOTOXY 16, 8
    lea dx, screen4 
    mov ah,9
    int 21h 
    
    GOTOXY 31, 10
    lea dx, screen5 
    mov ah,9
    int 21h 
    
    GOTOXY 31, 11
    lea dx, screen6 
    mov ah,9
    int 21h 
    
    GOTOXY 31, 12
    lea dx, screen7 
    mov ah,9
    int 21h 
    
    GOTOXY 31, 13
    lea dx, screen8 
    mov ah,9
    int 21h 
    
    GOTOXY 16, 15
    lea dx, about 
    mov ah,9
    int 21h 
    
    GOTOXY 16, 16
    lea dx, screen9 
    mov ah,9
    int 21h 
    
    GOTOXY 16, 19
    lea dx, screen10 
    mov ah,9
    int 21h 
    
    ;Press any key to start
    mov ah, 7     
    int 21h
    
    ;xoa man hinh hien tai
    call clear_all   
    ret
screen_menu endp

; Game screen
bild proc           ;function display alphabet and border in game
    call border     ;ham tao vien 
    
    ;display hlths: lives
    lea si, hlths
    mov di, 0
    mov cx, 9  
    lap1:   
        movsb
        inc di
    loop lap1
    
    ;in "Game Team 2"
    GOTOXY 68, 0
    lea dx, screen1 
    mov ah,9
    int 21h 
    
    ;display snake and alphabet
    xor dx, dx   
    mov di, snake_address[0]    ; dia chi bat dau ran
    mov dl, snake[0]            ; ki tu dai dien ran: 'S'
    ;es: extra segment (es: 0b800h)
    es: mov [di], dl          ; vi tri snake init
    es: mov [posN], 'N'     ; vi tri cac chu cai tren screen
    es: mov [posA], 'A'   
    es: mov [posK], 'K'
    es: mov [posE], 'E'
    ret
bild endp

; snake move:
move_left proc
    push dx
    call replace_address    ;ham thay doi dia chi snake in screen
    sub snake_address[0], 2
    call eat           
    call move_snake    
    pop dx
    ret
move_left endp

move_right proc
    push dx
    call replace_address 
    add snake_address[0], 2
    call eat         
    call move_snake   
    pop dx
    ret
move_right endp

move_up proc
    push dx
    call replace_address   
    sub snake_address[0], 160      
    call eat          
    call move_snake   
    pop dx
    ret
move_up endp

move_down proc
    push dx
    call replace_address 
    add snake_address[0], 160		 
    call eat         
    call move_snake  
    pop dx
    ret
move_down endp

replace_address proc  
    push ax
    xor ch, ch
    xor bh, bh
    mov cl, snake_len  ;cl: do dai cua ran hien tai     
    inc cl
    mov al, 2          ;moi phan tu chiem 2 byte
    mul cl             ;ax = al * cl = 2 * snake_len
    mov bl, al         ;vi tri cuoi cung trong snake_address             
    xor dx, dx         ;bien temp  
    
    ;dich phan tu trong snake_address sang ben phai
    shiftsnake:
        mov dx, snake_address[bx-2] ;lay phan tu o vi tri (i - 1)
        mov snake_address[bx], dx   ;gan vao vi tri i
        sub bx, 2
    loop shiftsnake:
    pop ax
    ret
replace_address endp

eat proc 
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, snake_address[0]
    ;neu khong co gi
    es: cmp [di], 0
    je no 
    
    ;neu co wall
    es: cmp [di], 20h     ;so sanh voi space(wall)
    je wall
    
    ;neu co letters
    xor ch, ch
    mov cl, letters_num   ;cl: so luong chu cai con lai (letters_num)
    xor si, si            ;si = 0 (de duyet letters_address[])
    lop:
        cmp di, letters_address[si] ;so sanh di voi vi tri chu cai thu si
        je eat_letters    ; neu trung thi jmp den eat_letters 
        ;neu khong thi tiep tuc cmp voi cac phan tu con lai trong letters_address
        add si, 2   ;si += 2 (moi phan tu la word)
    loop lop    
    jmp wall
    
    eat_letters:
        mov letters_address[si], 0        
                
        ; Luu ký tu vào snake[]
        xor bh, bh
        mov bl, snake_len ;do dai hien tai cua ran
        es: mov dl, [di]  ;[di]: ky tu an duoc
        mov snake[bx], dl ;luu ky tu vao snake[]

        es: mov [di], 0
        
        ; tang do dai ran, giam so letters con lai    
        add snake_len, 1
        sub letters_num_check, 1
    
        cmp letters_num_check, 0  ;kiem tra xem con moi khong
        je check_letters
        jmp no    
    wall:        
        ;kiem tra cham bien tren, duoi
        cmp di, 320    ;bien tren
        jle die
        cmp di, 3840   ;bien duoi
        jge die
        
        ;kiem tra cham bien trai, phai
        mov ax, di
        mov bl, 160 ;160 byte/dong (80 cot * 2 byte)   
        div bl      ;ax/bl -> ah = so du (vi tri cot: ah / 2)   
        cmp ah, 0   ;bien trai
        je die
        
        mov ax, di
        mov bl, 160
        div bl    
        cmp ah, 158 ;bien phai
        je die    
        jmp no    
    die:
        ;giam mang song
        xor bh, bh
        mov bl, hlth
        es: mov [bx+10], 0 ;xoa phan tu cuoi trong hlths tren man hinh
        mov hlths[bx+2], 0 ;loai bo phan tu cuoi trong mang hlths
        sub hlth, 2        ;giam mang song di 1 (moi mang = 2 byte)
        cmp hlth, 0        ;kiem tra con mang khong
        jne rest           ;neu con -> restart
    
        ; Neu khong con thi game over
        pop ax
        pop bx
        pop cx
        pop dx
        pop si
        pop di
        call game_over    
    rest:
        pop ax
        pop bx
        pop cx
        pop dx
        pop si
        pop di
        call restart    
    no:
        pop ax
        pop bx
        pop cx
        pop dx
        pop si
        pop di
    ret
eat endp

move_snake proc 
    xor ch, ch
    xor si, si
    xor dl, dl
    xor bx, bx
    mov cl, snake_len
    loopp:
        mov di, snake_address[si] ;di: vi tri doan ran thu si (tu mang snake_address)
        mov dl, snake[bx]         ;dl: ky tu doan ran thu bx (tu mang snake)
        es: mov [di], dl          ;ghi ki tu len man hinh tai vi tri di
        add si, 2
        inc bx
    loop loopp 
    ;xoa phan tu cuoi cua ran tren man hinh
    mov di, snake_address[si]
    es: mov [di],0
    ret
move_snake endp

border proc ; ham xác dinh gioi han duong di cua snake
    mov ah, 0    ; Chuc nang "Set Video Mode" (Thiet lap che do man hinh)
    mov al, 3    ; Che do 3: 80x25 text mode voi 16 mau
    int 10h             
    
    mov ah, 6      ; Chuc nang cuon màn hình lên (Scroll Up Window)
    mov al, 0      ; So dòng cuon (0 = xóa toàn bo vùng chon)
    mov bh, 0FFh   ; Màu nen (0FFh = mau trang)  
    
    ; Vien tren
    mov ch, 1      ; Dòng bat dau (y1 = 1)
    mov cl, 0      ; Cot bat dau (x1 = 0)
    mov dh, 1      ; Dòng ket thúc (y2 = 1)
    mov dl, 80     ; Cot ket thúc (x2 = 80)     
    int 10h    
    
    ; Vien duoi
    mov ch, 24
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 10h     
    
    ; Vien trai
    mov ch, 1
    mov cl, 0
    mov dh, 24
    mov dl, 0
    int 10h    
    
    ; Vien phai
    mov ch, 1
    mov cl, 79
    mov dh, 24
    mov dl, 79
    int 10h 
    ret
border endp      

restart proc ;ham khoi dong lai game sau khi mat 1 mang
    ;delete snake in screen
    xor ch, ch
    xor si, si
    mov cl, snake_len
    inc cl
    delete:
        mov di, snake_address[si]
        es:mov [di], 0
        add si, 2
    loop delete
    
    mov letters_num_check, 4
    
    ;reset snake_address[], snake[]
    mov snake_address, 07D2h
    mov cl, snake_len
    inc cl
    xor si, si
    inc si
    xor di, di
    add di, 2
    empty:
        mov snake[si], 0
        mov snake_address[di], 0
        add di, 2
        inc si
    loop empty
    
    ;reset letters_address[]
    xor ch, ch
    mov cl, letters_num
    xor si, si
    reset_leters:
        mov bx, dletters_address[si]
        mov letters_address[si], bx
        add si, 2
    loop reset_leters
    
    ;reset snake_len, head snake
    mov snake_len, 1
    xor si, si
    mov snake[si], 'S'
    
    jmp startag 
    ret    
restart endp

check_letters proc 
    call move_snake ;cap nhat vi tri ran tren man hinh
    
    ;ktra xem co dung thu tu SNAKE khong
    cmp snake[1],'N'
    jne endtest1   
    cmp snake[2],'A'
    jne endtest1
    cmp snake[3],'K'
    jne endtest1
    cmp snake[4],'E'
    jne endtest1
    call win  
    
    endtest1:
        ;giam mang song
        xor bh, bh
        mov bl, hlth
        es: mov [bx+10], 0
        mov hlths[bx+2], 0
        sub hlth, 2
        cmp hlth, 0
        jne restc
        call game_over           
    restc:
        call restart 
    ret
check_letters endp

win proc 
    call clear_all 
    call border 
    
    ;in ra: "You Win"
    GOTOXY 38, 13
    lea dx, gmwin
    mov ah,9
    int 21h 
    
    ;in ra: "Press Esc to exit"
    GOTOXY 34, 14
    lea dx, endtxt
    mov ah,9
    int 21h 
    
    quit_win:
        mov ah, 7   ;nhap 1 ki tu khong echo
        int 21h
        cmp al, 1bh ; cmp al, esc
        je exit
        jmp quit_win   
    ret
win endp   

game_over proc 
    call clear_all 
    call border
    
    ;in "Game Over"
    GOTOXY 37, 13
    lea dx, gmov 
    mov ah,9
    int 21h 
    
    ;in "Press Esc to exit"
    GOTOXY 34, 14
    lea dx, endtxt   
    mov ah,9
    int 21h 
    
    quit_lose:
        mov ah, 7
        int 21h
        cmp al, 1bh 
        je exit
        jmp quit_lose
    ret
game_over endp

clear_all proc ;ham xoa noi dung man hinh van ban 
    xor cx, cx   ;row start = 0, col start = 0
    mov dh, 24   ;row end = 24
    mov dl, 79   ;col end = 79
    mov bh, 7    ;white(text) on black(background)
    mov ax, 700h ;ah = 07h (scroll), al = 00h (clear)
    int 10h    
    ret
clear_all endp 

end start 