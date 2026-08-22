# Snake 8086 — Team 22

Trò chơi Snake chạy ở chế độ văn bản 80×25, được viết bằng Assembly x86 16-bit cho **emu8086**. Thay vì ăn mồi thông thường, người chơi phải thu thập lần lượt `N → A → K → E` để hoàn thành từ **SNAKE**.

## Tính năng

- Vòng lặp game theo thời gian thực với điều khiển `W`, `A`, `S`, `D`.
- Kiểm tra đúng thứ tự chữ ngay khi rắn ăn mồi.
- Phát hiện va chạm với tường và thân rắn.
- Chặn đổi hướng 180° khi rắn dài hơn một đốt.
- Ba mạng; trạng thái ván được khởi tạo lại an toàn sau mỗi lần mất mạng.
- Màn hình thắng/thua hỗ trợ chơi lại bằng `R`.
- Có thể thoát bằng `Esc` trong lúc chơi hoặc tại màn hình kết thúc.

## Yêu cầu

| Thành phần | Yêu cầu |
| --- | --- |
| Trình giả lập | emu8086 4.x |
| File include | `emu8086.inc` đi kèm emu8086 |
| Kiến trúc | x86 16-bit real mode |
| Chế độ hiển thị | BIOS text mode 80×25, video segment `B800h` |

> Mã nguồn dùng cú pháp MASM/TASM tương thích emu8086 và macro `GOTOXY` từ `emu8086.inc`.

## Chạy game

1. Cài đặt và mở **emu8086**.
2. Mở file `game_snake.asm`.
3. Chọn **Compile** (`F5`).
4. Chọn **Emulate**, sau đó **Run**.
5. Nhấn phím bất kỳ tại màn hình giới thiệu để bắt đầu.

## Cách chơi

| Phím | Hành động |
| --- | --- |
| `W` | Đi lên |
| `A` | Sang trái |
| `S` | Đi xuống |
| `D` | Sang phải |
| `R` | Chơi lại ở màn hình thắng/thua |
| `Esc` | Thoát game |

Rắn bắt đầu bằng ký tự `S`. Mỗi chữ đúng được nối vào thân rắn. Người chơi thắng khi thu thập đủ:

```text
S + N + A + K + E = SNAKE
```

Người chơi mất một mạng nếu:

- chạm tường;
- chạm thân rắn;
- ăn một chữ không đúng thứ tự.

Sau khi mất mạng, vị trí rắn và bốn chữ được thiết lập lại. Hết ba mạng sẽ kết thúc trò chơi.

## Thiết kế kỹ thuật

Game ghi trực tiếp ký tự vào bộ nhớ video màu tại segment `B800h`. Mỗi ô màn hình dùng hai byte: một byte ký tự và một byte thuộc tính màu. Với 80 cột, mỗi hàng chiếm 160 byte.

Luồng xử lý chính:

```text
Menu
  ↓
Khởi tạo ván → Đọc phím → Chờ khung hình → Di chuyển
                    ↑                         ↓
                    └──── tiếp tục ← Không va chạm
                                              ↓
                            Mất mạng / Thắng / Thoát
```

Các trạng thái quan trọng:

| Biến | Ý nghĩa |
| --- | --- |
| `snake_addresses` | Địa chỉ video của đầu, thân và đuôi cũ |
| `snake_chars` | Các ký tự tạo thành thân rắn |
| `snake_length` | Số đốt đang hiển thị |
| `letter_addresses` | Vị trí các chữ còn hoạt động |
| `letters_left` | Số chữ chưa ăn |
| `lives` | Số mạng còn lại |
| `current_direction` | Hướng di chuyển hiện tại |

Vị trí chữ trong video buffer:

| Chữ | Offset |
| --- | ---: |
| `N` | `09B4h` |
| `A` | `0848h` |
| `K` | `06B0h` |
| `E` | `01E8h` |

## Cấu trúc repository

```text
.
├── game_snake.asm   # Mã nguồn game
├── README.md        # Tài liệu dự án
├── .editorconfig    # Quy ước định dạng file
└── .gitignore       # Bỏ qua file sinh ra bởi emulator/compiler
```

## Kiểm thử thủ công

Sau khi compile, nên xác minh các trường hợp sau:

- Các phím thường và hoa (`w/W`, `a/A`, `s/S`, `d/D`) đều hoạt động.
- Không thể quay đầu trực tiếp khi rắn đã dài hơn một đốt.
- Ăn sai chữ làm mất đúng một mạng và reset ván.
- Chạm tường hoặc thân rắn làm mất đúng một mạng.
- Ăn `N`, `A`, `K`, `E` đúng thứ tự mở màn hình chiến thắng.
- `R` tạo game mới với ba mạng; `Esc` thoát sạch về DOS.

## Tác giả

**Team 22** — Bài tập lớn môn Hệ điều hành / Assembly x86, PTIT.
