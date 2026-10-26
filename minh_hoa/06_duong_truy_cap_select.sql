-- =====================================================================
-- Demo 06 - Ham chi phi va cach thuc hien phep chon (Muc 18.3, 19.4)
-- Van de: cung mot dieu kien WHERE co nhieu cach tim dong (quet ca bang,
--         dung chi muc nay hay chi muc kia), chenh nhau hang tram lan.
-- Cach giai: uoc tinh chi phi tung cach bang ham chi phi, chon cach re nhat.
-- Dung cac phep toan OP1, OP4, OP4', OP7 cua sach.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

CREATE INDEX IF NOT EXISTS idx_employee_dno    ON employee (dno);
CREATE INDEX IF NOT EXISTS idx_employee_salary ON employee (salary);
CREATE INDEX IF NOT EXISTS idx_employee_sex    ON employee (sex);

\echo '--- Thong so cho ham chi phi (Muc 19.4): b = so khoi cua EMPLOYEE, x = so tang chi muc khoa chinh'
SET client_min_messages = warning;  -- an NOTICE "already exists"
CREATE EXTENSION IF NOT EXISTS pageinspect;
RESET client_min_messages;
SELECT (SELECT relpages FROM pg_class WHERE relname = 'employee') AS b,
       (SELECT level + 1 FROM bt_metap('employee_pkey'))         AS x;

\echo '>>> [6a] OP1 Ssn = 123456789, khong dung chi muc (S1 quet ca bang: CS1 = b khoi)'
SET enable_indexscan = off;
SET enable_bitmapscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM employee WHERE ssn = '123456789';
RESET enable_indexscan;
RESET enable_bitmapscan;

\echo '>>> [6b] OP1, dung chi muc khoa chinh (S6a: CS6a = x + 1 khoi)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM employee WHERE ssn = '123456789';

\echo '>>> [6c] OP4 Dno = 7 AND Salary > 30000 AND Sex = F: chi dung chi muc hep nhat (Dno)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM employee WHERE dno = 7 AND salary > 30000 AND sex = 'F';

\echo '>>> [6d] OP4 voi OR, ca hai dieu kien co chi muc: hop hai tap ket qua'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM employee WHERE dno = 7 OR salary > 450000;

\echo '>>> [6e] OP4 voi OR, Address khong co chi muc: buoc phai quet ca bang'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM employee WHERE dno = 7 OR address LIKE '%Katy%';

\echo '>>> [6f] OP7 dieu kien tren bieu thuc Salary*12, chua co chi muc ham'
EXPLAIN (ANALYZE, BUFFERS)
SELECT fname, lname FROM employee WHERE salary * 12 > 5900000;

CREATE INDEX idx_employee_luong_nam ON employee ((salary * 12));
ANALYZE employee;

\echo '>>> [6g] OP7 sau khi tao chi muc ham tren (Salary*12)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT fname, lname FROM employee WHERE salary * 12 > 5900000;

DROP INDEX idx_employee_luong_nam;
DROP INDEX idx_employee_dno;
DROP INDEX idx_employee_salary;
DROP INDEX idx_employee_sex;
