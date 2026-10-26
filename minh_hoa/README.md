# Cài đặt minh họa tối ưu hóa truy vấn

Mỗi file demo so sánh một câu hỏi chạy theo hai cách, "chưa tối ưu" và "đã tối ưu", bằng `EXPLAIN (ANALYZE, BUFFERS)`.

| File | Kỹ thuật (mục trong sách) |
|---|---|
| `00_tao_du_lieu.sql` | Tạo CSDL COMPANY đủ lớn (dùng lại file nạp của BT2) |
| `01_heuristic_cay_truy_van.sql` | Tối ưu theo luật (19.1.2) |
| `02_khu_long_truy_van_con.sql` | Khử lồng, semi-join, anti-join (19.2.2, 18.1.1) |
| `03_hop_nhat_view.sql` | Hợp nhất view (19.2.3) |
| `04_view_vat_chat_hoa.sql` | View vật chất hóa (19.2.4) |
| `05_thong_ke_histogram.sql` | Thống kê, histogram (19.3) |
| `06_duong_truy_cap_select.sql` | Hàm chi phí, cách tìm dòng cho phép chọn (18.3, 19.4) |
| `07_thuat_toan_join.sql` | Thuật toán join J1–J4 (18.4, 19.5) |
| `08_thu_tu_join.sql` | Thứ tự join (19.5.3–19.6) |
| `09_luu_dem_ke_hoach.sql` | Lưu đệm kế hoạch (19.7.3) |
| `10_top_k_pipelining_sap_xep.sql` | Top-k, pipelining (19.7.4, 18.7) |
| `11_toi_uu_ngu_nghia.sql` | Tối ưu ngữ nghĩa (19.10) |
| `chay_demo.py` | Chạy các demo 5 lần, lấy thời gian trung vị, ghi `ket_qua.md` và `logs/` |

## Chạy

Cần PostgreSQL 18 (17 cũng được) và Python 3. Mở PowerShell trong thư mục `minh_hoa`, khai báo kết nối:

```bash
$env:PGUSER = "postgres"; $env:PGPASSWORD = "<mat khau>"; $env:PGDATABASE = "company_opt"
```

Tạo CSDL và nạp dữ liệu (khoảng 30 giây):

```bash
createdb company_opt
```

```bash
psql -f 00_tao_du_lieu.sql
```

Chạy một demo và xem kế hoạch:

```bash
psql -f 01_heuristic_cay_truy_van.sql
```

Hoặc chạy tất cả và cập nhật bảng kết quả (khoảng 1 phút). Nếu `psql` không có trong PATH thì đặt biến `PSQL` trỏ tới `psql.exe`:

```bash
python chay_demo.py
```

Mỗi demo tự tạo chỉ mục nó cần và tự xóa khi xong, nên chạy lại nhiều lần vẫn ra cùng kết quả.
