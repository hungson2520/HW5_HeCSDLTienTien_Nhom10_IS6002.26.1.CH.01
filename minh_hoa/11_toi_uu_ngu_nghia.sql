-- =====================================================================
-- Demo 11 - Toi uu ngu nghia (Muc 19.10)
-- Van de: co cau hoi ma rang buoc da cho biet truoc ket qua, hoac co bang
--         du thua, nhung DBMS van doc du lieu.
-- Cach giai: dung rang buoc (CHECK, khoa chinh, khoa ngoai) de rut gon truy van.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

-- EMPLOYEE co rang buoc CHECK (salary >= 0)

\echo '>>> [11a] Hoi luong am, chua dung rang buoc: van quet ca bang'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM employee WHERE salary < 0;

SET constraint_exclusion = on;  -- mac dinh chi dung CHECK cho bang phan vung

\echo '>>> [11b] Hoi luong am, dung rang buoc CHECK: biet truoc la rong, khong doc bang'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM employee WHERE salary < 0;

RESET constraint_exclusion;

\echo '>>> [11c] Vi du 2 cua sach: join DEPARTMENT nhung khong lay cot nao cua no (PostgreSQL van join)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT Lname, Salary
FROM EMPLOYEE, DEPARTMENT
WHERE EMPLOYEE.Dno = DEPARTMENT.Dnumber AND EMPLOYEE.Salary > 100000;

\echo '>>> [11d] Viet bang LEFT JOIN: PostgreSQL tu bo bang DEPARTMENT (Dnumber la khoa chinh)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.lname, e.salary
FROM employee e LEFT JOIN department d ON e.dno = d.dnumber
WHERE e.salary > 100000;
