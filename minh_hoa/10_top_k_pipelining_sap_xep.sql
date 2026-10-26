-- =====================================================================
-- Demo 10 - Top-k (Muc 19.7.4), pipelining (Muc 18.7)
-- Van de: chi can 10 dong dau nhung lai sap xep ca 200.008 dong.
-- Cach giai: chi giu 10 dong tot nhat; co chi muc thi doc theo thu tu va
--            dung sau 10 dong (pipelining: node tren keo tung dong tu node duoi).
-- Cau hoi: 10 nhan vien luong cao nhat.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

\echo '>>> [10a] Chua toi uu: sap xep ca bang (khong du bo nho => sap xep ngoai, Muc 18.2)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT ssn, fname, lname, salary FROM employee ORDER BY salary DESC;

\echo '>>> [10b] LIMIT 10, chua co chi muc: chi giu 10 dong tot nhat (top-N heapsort)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT ssn, fname, lname, salary FROM employee ORDER BY salary DESC LIMIT 10;

CREATE INDEX IF NOT EXISTS idx_employee_salary ON employee (salary);

\echo '>>> [10c] LIMIT 10, co chi muc tren Salary: doc 10 dong cuoi cua chi muc roi dung'
EXPLAIN (ANALYZE, BUFFERS)
SELECT ssn, fname, lname, salary FROM employee ORDER BY salary DESC LIMIT 10;

DROP INDEX idx_employee_salary;
