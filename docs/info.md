## How it works

E07 la bo dao thu tu bit co chot. Khi nap=1 tai suon len cua clk, mach chot mot byte da bien doi vao thanh ghi 8 bit va giu nguyen den lan nap sau.

- che_do=0: dao thu tu bit (b7..b0 thanh b0..b7). Day chi la noi day, khong ton cell logic.
- che_do=1: doi cho hai nibble (0xA5 thanh 0x5A), khong dao bit ben trong nibble.

| Chan | Huong | Do rong | Muc tich cuc | Chuc nang |
|---|---|---|---|---|
| ui_in[7:0] | vao | 8 | - | byte vao |
| uio_in[0] | vao | 1 | cao | nap (chot khi =1) |
| uio_in[1] | vao | 1 | - | che do (0: dao bit, 1: dao nibble) |
| uio_in[7:2] | vao | 6 | - | khong dung |
| uo_out[7:0] | ra | 8 | - | byte ra (gia tri da chot) |
| uio_out, uio_oe | ra | 8+8 | - | luon 0 (uio dung lam chan vao) |
| clk | vao | 1 | suon len | xung nhip |
| rst_n | vao | 1 | thap | reset bat dong bo, xoa ve 0x00 |

## How to test

1. Dat rst_n=0 vai chu ky roi rst_n=1.
2. Dat ui_in=0x01, uio_in=0b01 (nap=1, che do 0), cho mot suon clk: uo_out = 0x80.
3. Dat uio_in=0b11 (nap=1, che do 1) voi ui_in=0xA5: uo_out = 0x5A.
4. Dat nap=0: uo_out giu nguyen du ui_in thay doi.

## External hardware

Khong can phan cung ngoai.
