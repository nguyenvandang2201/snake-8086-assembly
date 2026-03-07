# 🐍 Game Snake - Assembly x86 (Team 22)

Trò chơi Snake cổ điển viết bằng ngôn ngữ Assembly x86 (8086), chạy trên trình giả lập **emu8086**. Người chơi điều khiển con rắn để ăn 4 chữ cái theo đúng thứ tự **N → A → K → E** (tạo thành từ "SNAKE") để chiến thắng.

---

## 📋 Yêu cầu hệ thống

| Thành phần | Yêu cầu |
|---|---|
| Trình giả lập | [emu8086](https://emu8086-microprocessor-emulator.en.softonic.com/) |
| File include | `emu8086.inc` (đi kèm emu8086) |
| Kiến trúc | x86 (8086), chế độ 16-bit real-mode |
| Bộ nhớ video | Text mode 80×25, segment `0B800h` |

---

## 🚀 Cách chạy

1. Mở **emu8086**.
2. Mở file `game_snake.asm`.
3. Nhấn **Compile** (F5) để dịch chương trình.
4. Nhấn **Run** để chạy.
5. Màn hình menu xuất hiện → nhấn bất kỳ phím nào để bắt đầu.

---

## 🎮 Cách chơi

### Mục tiêu
Điều khiển con rắn (ký hiệu `S`) để ăn **4 chữ cái theo đúng thứ tự** sau:

```
'N'  →  'A'  →  'K'  →  'E'
```

Ăn đúng thứ tự → **WIN**. Ăn sai thứ tự hoặc đâm vào tường → **Mất mạng**.

### Điều khiển

| Phím | Hành động |
|------|-----------|
| `W`  | Di chuyển lên |
| `S`  | Di chuyển xuống |
| `A`  | Di chuyển sang trái |
| `D`  | Di chuyển sang phải |
| `Esc`| Thoát (tại màn hình kết thúc) |

### Luật chơi
- Con rắn bắt đầu ở giữa màn hình, biểu diễn bằng ký tự `S`.
- Mỗi chữ cái ăn được sẽ nối thêm vào thân rắn.
- Người chơi có **3 mạng** (hiển thị góc trên bên trái).
- Mất mạng khi:
  - Đâm vào **tường** (viền màn hình).
  - Ăn sai thứ tự (ví dụ ăn `A` trước `N`) → mất mạng và restart.
- Hết 3 mạng → **Game Over**.
- Ăn đủ N, A, K, E đúng thứ tự → **You Win**.

---

## 🗺️ Cấu trúc chương trình

```
game_snake.asm
│
├── .Data          — Khai báo biến, chuỗi, vị trí chữ cái, thông tin rắn
├── .Code
│   ├── start          — Điểm bắt đầu: khởi tạo DS, ES (video segment)
│   ├── screen_menu    — Hiển thị màn hình giới thiệu/menu
│   ├── bild           — Vẽ màn hình chơi: viền, rắn, các chữ cái
│   ├── move_left/right/up/down  — Xử lý di chuyển rắn
│   ├── replace_address — Dịch chuyển mảng địa chỉ rắn (snake_address[])
│   ├── eat            — Kiểm tra va chạm: chữ cái / tường / game over
│   ├── move_snake     — Vẽ lại rắn lên video memory
│   ├── border         — Tạo viền màn hình bằng BIOS int 10h
│   ├── restart        — Reset rắn, chữ cái sau khi mất mạng
│   ├── check_letters  — Kiểm tra thứ tự chữ cái → win hoặc lose mạng
│   ├── win            — Hiển thị màn hình chiến thắng
│   ├── game_over      — Hiển thị màn hình thua cuộc
│   └── clear_all      — Xoá toàn bộ màn hình (BIOS int 10h scroll)
```

---

## 🧠 Chi tiết kỹ thuật

### Bộ nhớ video (Video Memory)
Chương trình ghi trực tiếp vào segment `0B800h` (text mode video buffer):
- Mỗi ký tự chiếm **2 byte**: 1 byte ký tự + 1 byte màu sắc.
- Màn hình 80 cột × 25 dòng → mỗi dòng = **160 byte**.

### Vị trí các chữ cái trên màn hình
| Chữ cái | Địa chỉ offset (es:) |
|---------|----------------------|
| `N`     | `09B4h`              |
| `A`     | `0848h`              |
| `K`     | `06B0h`              |
| `E`     | `01E8h`              |

### Cấu trúc dữ liệu rắn
```asm
snake_address  dw 07D2h, 5 Dup(?)  ; Mảng địa chỉ video từng đốt rắn
snake          db 'S',   5 Dup(?)  ; Mảng ký tự từng đốt rắn
snake_len      db 1                ; Độ dài hiện tại của rắn
```

### Hệ thống mạng sống
```asm
hlth    db 6    ; Mạng sống (mỗi mạng = 2 đơn vị, tổng 3 mạng)
hlths   db "Lives:", 3, 3, 3   ; Hiển thị trên màn hình
```

### Ngắt được sử dụng
| Ngắt | Chức năng |
|------|-----------|
| `INT 10h` (AH=00h) | Thiết lập chế độ video 80×25 text |
| `INT 10h` (AH=06h) | Cuộn/xoá vùng màn hình (tạo viền) |
| `INT 16h` (AH=01h) | Kiểm tra phím đã nhấn (non-blocking) |
| `INT 16h` (AH=00h) | Đọc ký tự từ bàn phím |
| `INT 21h` (AH=09h) | In chuỗi ký tự ra màn hình |
| `INT 21h` (AH=07h) | Đọc ký tự không echo (chờ input) |
| `INT 21h` (AH=4Ch) | Kết thúc chương trình |

---

## 📁 Cấu trúc thư mục

```
Game Snake Assembly/
└── game_snake.asm   — File mã nguồn Assembly duy nhất
```

---

## 👥 Tác giả

**TEAM 22** — Dự án môn học Kiến trúc máy tính / Lập trình Assembly.

---

## 📌 Ghi chú

- Chương trình sử dụng macro `GOTOXY` từ thư viện `emu8086.inc` để định vị con trỏ.
- Hoạt động đúng nhất trên **emu8086 v4.x**.
- Do ghi trực tiếp vào video memory (`0B800h`), chương trình cần chạy trong môi trường DOS hoặc giả lập DOS.
