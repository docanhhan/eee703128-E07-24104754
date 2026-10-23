# E07 – Bộ đảo thứ tự bit có chốt: Đặc tả và kiến trúc

## 1. Đặc tả và giao diện (§2 báo cáo)

**Chức năng.** Nạp một byte từ `ui_in`, chốt vào thanh ghi 8 bit, rồi xuất ra `uo_out` ở dạng đảo thứ tự bit (chế độ 0) hoặc đảo nibble (chế độ 1). Giá trị giữ nguyên đến lần nạp sau.

| Tín hiệu | Chiều | Độ rộng | Mức tích cực | Ý nghĩa | Giả định |
|---|---|---|---|---|---|
| `ui_in[7:0]` | vào | 8 | cao | Byte dữ liệu (`d0`…`d7`) | Không dấu (unsigned). Ổn định quanh cạnh lên của clock khi `nap = 1` |
| `uio_in[0]` (`nap`) | vào | 1 | cao | Cho phép nạp byte vào thanh ghi | Ổn định quanh cạnh clock |
| `uio_in[1]` (`che_do`) | vào | 1 | 0 = đảo bit, 1 = đảo nibble | Chọn phép hoán vị | **Chỉ được chốt cùng lúc nạp.** Đổi `che_do` khi `nap = 0` thì `uo_out` không đổi |
| `uio_in[7:2]` | vào | 6 | – | Không dùng | Bỏ qua |
| `clk` | vào | 1 | cạnh lên | Đồng hồ | Phân tích với chu kỳ giả định 20 ns (`CLOCK_PERIOD`); `info.yaml` ghi 10 MHz |
| `rst_n` | vào | 1 | mức thấp | Xóa `q` về `0x00` | **Reset bất đồng bộ** khi đặt (`negedge rst_n`); reset thắng nạp. Việc nhả reset được kiểm bằng recovery check |
| `ena` | vào | 1 | cao | Tín hiệu của Tiny Tapeout | Không dùng |
| `uo_out[7:0]` | ra | 8 | – | Byte đã hoán vị, lấy trực tiếp từ `q` | **Latency 1 chu kỳ** sau cạnh clock nạp |
| `uio_out[7:0]` | ra | 8 | – | Cố định 0 | Không dùng |
| `uio_oe[7:0]` | ra | 8 | – | Cố định 0 | Mọi chân `uio` là chân vào |

**Ngân sách chân:** 10 bit vào (8 `ui_in` + `nap` + `che_do`) + 8 bit ra (`uo_out`) = 18 trên 24 chân. Không vượt ngân sách.

**Ánh xạ Tiny Tapeout:** `ui_in[i]` = `d_i`, `uo_out[i]` = `q_i`, `uio[0]` = `nap`, `uio[1]` = `che_do` (khớp `info.yaml`).

**Hành vi.** Chế độ 0: `uo_out[i] = ui_in[7-i]`. Chế độ 1: `uo_out = {ui_in[3:0], ui_in[7:4]}`. Cả hai chỉ có hiệu lực ở cạnh clock mà `nap = 1`.

**Trường hợp biên đã liệt kê**

- `0x00`, `0xFF`, `0xA5` là điểm bất động của phép đảo bit. Mạch viết sai thứ tự vẫn qua các giá trị này, nên cần ca `0x01 → 0x80`.
- `0x01 ↔ 0x80` ở chế độ 0; `0x12 ↔ 0x21` ở chế độ 1.
- `nap = 0` thì `q` giữ nguyên dù `ui_in` và `che_do` đổi.
- `rst_n` xuống thấp giữa chừng, không cần cạnh clock, thì `q = 0x00` ngay.
- `rst_n` thấp đồng thời `nap = 1`: reset thắng.

## 2. Thiết kế RTL (§3 báo cáo)

**Sơ đồ khối:** chèn ảnh `so_do_khoi_E07.png`. Hai khối đảo là nối dây (0 ô); mỗi bit có hai `mux2_1` nối tiếp (chọn chế độ, rồi chọn nạp/giữ) trước một `dfrtp_2`. Không có FSM nên không vẽ sơ đồ trạng thái.

**Mã then chốt** (`src/project.v`):

```verilog
reg [7:0] q;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)    q <= 8'h00;
    else if (nap)  q <= mode ? dao_nibble : dao_bit;
end
assign uo_out = q;
```

**Khối `always` tạo ra phần cứng gì.** Duy nhất một khối tuần tự, tạo 8 flip-flop có reset bất đồng bộ; thanh ghi `q` chỉ được ghi bởi khối này (một process sở hữu). Không có `always_comb` nên không có nguy cơ latch. `dao_bit` và `dao_nibble` là `wire` (nối dây).

**Vì sao chọn kiến trúc này.** Chốt `che_do` cùng lúc nạp thì `uo_out` ổn định cả chu kỳ và không có đường tổ hợp từ `che_do` ra cổng ra. Reset bất đồng bộ dùng `dfrtp` nên không tốn logic trên đường D.

### Các kiến trúc thay thế (đo bằng Yosys)

Cả năm phương án chạy cùng một kịch bản Yosys 0.33 với thư viện `sky130_fd_sc_hd__tt_025C_1v80`. Kịch bản được hiệu chỉnh để phương án A tái tạo đúng 40 ô và 450,432 µm² của flow CI. Điều kiện: thư viện lấy từ gói `open_pdks.sky130a 1.0.471`, **không phải** bản PDK ciel `8afc8346…` của CI, và đây không phải flow LibreLane đầy đủ. Vì vậy chỉ dùng để so sánh tương đối, không thay thế số của CI. Script và kết quả nằm trong thư mục `yosys_variants`.

| | Phương án | Số ô | Diện tích (µm²) | So với A |
|---|---|---|---|---|
| A | Bài nộp: chế độ chọn **trước** thanh ghi, reset bất đồng bộ | 40 | 450,432 | – |
| B | Chế độ chọn **sau** thanh ghi, reset bất đồng bộ | 40 | 450,432 | 0 % |
| C | Như A nhưng reset **đồng bộ** | 48 | 460,442 | +2,2 % |
| D | Chỉ đảo bit, bỏ chế độ | 32 | 360,346 | −20,0 % |
| E | Tổ hợp thuần, không thanh ghi | 24 | 150,144 | −66,7 % |

Nhận xét: mọi phương án đều có 16 ô `conb_1` (60,0576 µm²) do wrapper.

- **B** cùng diện tích với A nhưng khác hành vi: `uo_out` đổi ngay khi `che_do` đổi (có đường tổ hợp `che_do` → `uo_out`, dễ có glitch). Em chọn A để đầu ra ổn định.
- **C** tốn thêm logic trên đường D (dù dùng flip-flop `dfxtp_1` nhỏ hơn). Ưu điểm là bỏ ràng buộc recovery/removal của reset bất đồng bộ.
- **D** cho câu trả lời "hai chế độ khác nhau bao nhiêu ô": quyền chọn chế độ tốn 8 `mux2_1` = 90,0864 µm² (8 ô, 20,0 %).
- **E** vi phạm tên đề "có chốt".
