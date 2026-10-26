-- =====================================================================
-- Demo 04 - View vat chat hoa (Muc 19.2.4)
-- Van de: bao cao hoi thuong xuyen ma lan nao cung join + gom nhom ca bang.
-- Cach giai: luu san ket qua (view V2 cua Muc 7.3).
-- Gia phai tra: du lieu goc doi thi view cu, phai REFRESH.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;
SET client_min_messages = warning;

DROP MATERIALIZED VIEW IF EXISTS mv_dept_info;
CREATE MATERIALIZED VIEW mv_dept_info AS
SELECT d.dname AS dept_name, count(*) AS no_of_emps, sum(e.salary) AS total_sal
FROM department d JOIN employee e ON e.dno = d.dnumber
GROUP BY d.dname;

\echo '>>> [4a] Tinh tu bang goc moi lan hoi'
EXPLAIN (ANALYZE, BUFFERS)
SELECT d.dname AS dept_name, count(*) AS no_of_emps, sum(e.salary) AS total_sal
FROM department d JOIN employee e ON e.dno = d.dnumber
GROUP BY d.dname;

\echo '>>> [4b] Doc tu view vat chat hoa'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM mv_dept_info;

BEGIN;
UPDATE employee SET salary = salary + 1000 WHERE ssn = '888665555';  -- James Borg, phong 1

\echo '--- Tang luong 1 nguoi: view van giu so cu'
SELECT (SELECT total_sal FROM mv_dept_info WHERE dept_name = 'Headquarters') AS trong_view,
       (SELECT sum(salary) FROM employee WHERE dno = 1)                       AS trong_bang_goc;

\timing on
\echo '>>> [4c] REFRESH: tinh lai ca view'
REFRESH MATERIALIZED VIEW mv_dept_info;
\timing off
ROLLBACK;

DROP MATERIALIZED VIEW mv_dept_info;
