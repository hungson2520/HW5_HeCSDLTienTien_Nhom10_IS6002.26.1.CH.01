# Kết quả chạy demo

File này do `chay_demo.py` sinh ra. Thời gian là median của nhiều lần chạy;
kế hoạch, số dòng và số khối lấy từ lần chạy cuối.

- **Kế hoạch**: node gốc, rồi đến node chính (bỏ qua Aggregate/Limit/Result bọc ngoài).
- **Cost ước tính**: cost tổng của node gốc, đơn vị nội bộ của PostgreSQL.
- **Dòng ước tính / thực tế**: của node chính.
- **Số khối**: `shared hit + read` của node gốc, tức số lần truy cập khối dữ liệu
  (đơn vị chi phí mà sách dùng ở Mục 19.4–19.5).

## 01_heuristic_cay_truy_van.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 1a | Cay ban dau (Hinh 19.2a) la tich Descartes 3 bang: bao nhieu dong? |  |  |  |  |  |  |
| 1b | Chua toi uu: JOIN ca 3 bang roi moi loc (MATERIALIZED cam day phep loc xuong) | CTE Scan on j | 65 926.44 | 1 | 347 | 9 015 | 772.46 |
| 1c | Loc truoc nhung thu tu do (Hinh 19.2b): EMPLOYEE JOIN WORKS_ON truoc | Hash Join | 38 857.86 | 350 | 347 | 9 002 | 351.68 |
| 1d | Cau SQL goc cua sach, de PostgreSQL tu toi uu (Hinh 19.2c-e) | Nested Loop | 1 784.89 | 350 | 347 | 2 506 | 2.85 |

## 02_khu_long_truy_van_con.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 2a | Chua toi uu: EXISTS chay lai cho tung nhan vien (OFFSET 0 cam khu long) | Seq Scan on employee e | 354 643.08 | 100 004 | 83 037 | 202 637 | 696.30 |
| 2b | Da khu long: cung cau do, PostgreSQL doi thanh join | Hash Join | 5 200.35 | 40 002 | 83 037 | 2 630 | 29.45 |
| 2c | Semi-join: so phong co nguoi luong > 200000 (Q(SJ) Muc 18.1.1) | Aggregate → Nested Loop Semi Join | 119.78 | 49 | 49 | 503 | 0.91 |
| 2d | Anti-join: so nhan vien KHONG thuoc phong o zip 30332 (Q(AJ), viet bang NOT EXISTS) | Aggregate → Merge Anti Join | 5 005.52 | 160 006 | 116 971 | 175 | 25.95 |
| 2e | Chua toi uu: luong cao hon trung binh phong minh (phong 7), AVG tinh lai cho tung nguoi | Index Scan using idx_employee_dno on employee e | 7 851 971.34 | 916 | 783 | 3 980 666 | 2 433.68 |
| 2f | Tu viet lai (PostgreSQL khong tu lam duoc): tinh AVG moi phong mot lan roi join | Nested Loop | 5 643.36 | 916 | 783 | 3 218 | 2.12 |

## 03_hop_nhat_view.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 3a | Khong hop nhat: tinh ca view (1 trieu dong) roi moi join | Hash Join | 46 816.78 | 200 | 202 | 9 015 | 497.83 |
| 3b | Hop nhat: PostgreSQL gop view vao cau chinh | Nested Loop | 5 805.37 | 200 | 202 | 3 399 | 11.22 |

## 04_view_vat_chat_hoa.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 4a | Tinh tu bang goc moi lan hoi | HashAggregate | 6 701.41 | 50 | 50 | 2 630 | 68.30 |
| 4b | Doc tu view vat chat hoa | Seq Scan on mv_dept_info | 16.40 | 640 | 50 | 1 | 0.01 |
| 4c | REFRESH: tinh lai ca view |  |  |  |  |  | 59.38 |

## 05_thong_ke_histogram.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 5a | Thong ke cot Dno trong catalog: so gia tri khac nhau, gia tri hay gap |  |  |  |  |  |  |
| 5b | Histogram cot Salary (do cao bang nhau, 100 ngan): cac moc cach 10 ngan |  |  |  |  |  |  |
| 5c | Dno = 1: uoc tinh dung 1 dong => dung chi muc | Index Scan using idx_employee_dno on employee | 8.31 | 1 | 1 | 3 | 0.05 |
| 5d | Dno = 5: uoc tinh dung ~60.000 dong => doi ke hoach | Bitmap Heap Scan on employee | 4 060.79 | 60 222 | 59 953 | 2 681 | 10.61 |
| 5e | Thong ke CU: van tuong phong 1 co 1 nguoi | Aggregate → Nested Loop | 23.91 | 4 | 299 758 | 242 981 | 197.87 |
| 5f | Sau ANALYZE: uoc tinh dung, doi ke hoach | Aggregate → Hash Join | 26 132.21 | 299 273 | 299 758 | 7 207 | 168.04 |

## 06_duong_truy_cap_select.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 6a | OP1 Ssn = 123456789, khong dung chi muc (S1 quet ca bang: CS1 = b khoi) | Seq Scan on employee | 5 129.10 | 1 | 1 | 2 629 | 13.41 |
| 6b | OP1, dung chi muc khoa chinh (S6a: CS6a = x + 1 khoi) | Index Scan using employee_pkey on employee | 8.44 | 1 | 1 | 4 | 0.03 |
| 6c | OP4 Dno = 7 AND Salary > 30000 AND Sex = F: chi dung chi muc hep nhat (Dno) | Bitmap Heap Scan on employee | 2 737.63 | 1 176 | 1 223 | 1 609 | 1.48 |
| 6d | OP4 voi OR, ca hai dieu kien co chi muc: hop hai tap ket qua | Bitmap Heap Scan on employee | 2 853.93 | 4 519 | 4 746 | 2 219 | 1.90 |
| 6e | OP4 voi OR, Address khong co chi muc: buoc phai quet ca bang | Seq Scan on employee | 5 629.12 | 30 262 | 27 190 | 2 629 | 22.76 |
| 6f | OP7 dieu kien tren bieu thuc Salary*12, chua co chi muc ham | Seq Scan on employee | 5 629.12 | 66 669 | 411 | 2 629 | 27.84 |
| 6g | OP7 sau khi tao chi muc ham tren (Salary*12) | Bitmap Heap Scan on employee | 1 019.49 | 368 | 411 | 390 | 0.34 |

## 07_thuat_toan_join.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 7a | OP6 EMPLOYEE JOIN DEPARTMENT, bo toi uu tu chon | Aggregate → Hash Join | 6 200.78 | 200 008 | 200 008 | 2 630 | 51.01 |
| 7b | OP6 ep J1 nested-loop join | Aggregate → Nested Loop | 152 754.40 | 200 008 | 200 008 | 2 630 | 294.90 |
| 7c | OP6 ep J2 index nested-loop join | Aggregate → Nested Loop | 17 169.55 | 200 008 | 200 008 | 82 753 | 92.44 |
| 7d | OP6 ep J3 sort-merge join | Aggregate → Merge Join | 17 620.07 | 200 008 | 200 008 | 82 663 | 81.57 |
| 7e | EMPLOYEE JOIN WORKS_ON (1 trieu dong), bo toi uu tu chon | Aggregate → Hash Join | 42 844.53 | 1 000 016 | 1 000 016 | 8 999 | 485.00 |
| 7f | EMPLOYEE JOIN WORKS_ON ep J3 sort-merge join | Aggregate → Merge Join | 72 281.11 | 1 000 016 | 1 000 016 | 19 848 | 327.02 |

## 08_thu_tu_join.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 8a | Bo toi uu tu chon thu tu | Nested Loop | 123.68 | 12 | 12 | 61 | 0.17 |
| 8b | Thu tu 3 cua sach: (DEPARTMENT JOIN EMPLOYEE) JOIN PROJECT | Hash Join | 444.79 | 12 | 12 | 213 | 0.14 |
| 8c | Thu tu co tich Descartes: (PROJECT x EMPLOYEE) JOIN DEPARTMENT | Hash Join | 47 253.33 | 12 | 12 | 2 642 | 414.73 |

## 09_luu_dem_ke_hoach.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 9a | Ke hoach rieng cho phong 1 (1 nguoi) | Aggregate → Nested Loop | 140.48 | 35 | 1 | 7 | 0.11 |
| 9b | Ke hoach chung (dung lai cho moi phong), chay cho phong 1 | Aggregate → Hash Join | 21 994.23 | 20 000 | 1 | 6 373 | 101.78 |

## 10_top_k_pipelining_sap_xep.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 10a | Chua toi uu: sap xep ca bang (khong du bo nho => sap xep ngoai, Muc 18.2) | Sort | 27 527.50 | 200 008 | 200 008 | 2 632 | 130.41 |
| 10b | LIMIT 10, chua co chi muc: chi giu 10 dong tot nhat (top-N heapsort) | Limit → Sort | 8 951.21 | 200 008 | 10 | 2 629 | 44.32 |
| 10c | LIMIT 10, co chi muc tren Salary: doc 10 dong cuoi cua chi muc roi dung | Limit → Index Scan Backward using idx_employee_salary on employee | 1.21 | 200 008 | 10 | 13 | 0.06 |

## 11_toi_uu_ngu_nghia.sql  (chạy 5 lần)

| Bước | Mô tả | Kế hoạch | Cost ước tính | Dòng ước tính | Dòng thực tế | Số khối | Thời gian (ms) |
|---|---|---|---:|---:|---:|---:|---:|
| 11a | Hoi luong am, chua dung rang buoc: van quet ca bang | Aggregate → Seq Scan on employee | 5 129.15 | 16 | 0 | 2 629 | 21.94 |
| 11b | Hoi luong am, dung rang buoc CHECK: biet truoc la rong, khong doc bang | Aggregate → Result | 0.01 |  |  | 12 | 0.01 |
| 11c | Vi du 2 cua sach: join DEPARTMENT nhung khong lay cot nao cua no (PostgreSQL van join) | Hash Join | 5 294.07 | 57 186 | 57 117 | 2 630 | 27.51 |
| 11d | Viet bang LEFT JOIN: PostgreSQL tu bo bang DEPARTMENT (Dnumber la khoa chinh) | Seq Scan on employee e | 5 129.10 | 57 186 | 57 117 | 2 629 | 21.12 |
