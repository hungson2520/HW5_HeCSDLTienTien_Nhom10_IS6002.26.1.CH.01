-- =====================================================================
-- Demo 02 - Khu long truy van con (Muc 19.2.2), semi-join / anti-join (Muc 18.1.1)
-- Van de: truy van con chay lai cho TUNG dong cua truy van ngoai.
-- Cach giai: viet lai thanh join (semi-join, anti-join) de chay mot lan.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

CREATE INDEX IF NOT EXISTS idx_employee_dno ON employee (dno);

\echo '>>> [2a] Chua toi uu: EXISTS chay lai cho tung nhan vien (OFFSET 0 cam khu long)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT fname, lname, salary
FROM employee e
WHERE EXISTS (SELECT * FROM department d
              WHERE d.dnumber = e.dno AND d.zipcode = 30332
              OFFSET 0);

\echo '>>> [2b] Da khu long: cung cau do, PostgreSQL doi thanh join'
EXPLAIN (ANALYZE, BUFFERS)
SELECT fname, lname, salary
FROM employee e
WHERE EXISTS (SELECT * FROM department d
              WHERE d.dnumber = e.dno AND d.zipcode = 30332);

\echo '>>> [2c] Semi-join: so phong co nguoi luong > 200000 (Q(SJ) Muc 18.1.1)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM department d
WHERE d.dnumber IN (SELECT e.dno FROM employee e WHERE e.salary > 200000);

\echo '--- Vi sao phai la SEMI-join: dung inner join thi dem sai'
SELECT (SELECT count(*) FROM department d
        WHERE d.dnumber IN (SELECT e.dno FROM employee e
                            WHERE e.salary > 200000)) AS semi_join_dung,
       (SELECT count(*) FROM department d
        JOIN employee e ON d.dnumber = e.dno
        WHERE e.salary > 200000)                     AS inner_join_sai;

\echo '>>> [2d] Anti-join: so nhan vien KHONG thuoc phong o zip 30332 (Q(AJ), viet bang NOT EXISTS)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM employee e
WHERE NOT EXISTS (SELECT 1 FROM department d
                  WHERE d.dnumber = e.dno AND d.zipcode = 30332);

\echo '--- Luu y: PostgreSQL khong doi NOT IN thanh anti-join vi NULL'
SELECT 5 NOT IN (1, 2) AS khong_co_null, 5 NOT IN (1, 2, NULL) AS co_null;

\echo '>>> [2e] Chua toi uu: luong cao hon trung binh phong minh (phong 7), AVG tinh lai cho tung nguoi'
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.lname, e.salary
FROM employee e
WHERE e.dno = 7
  AND e.salary > (SELECT avg(e2.salary) FROM employee e2 WHERE e2.dno = e.dno);

\echo '>>> [2f] Tu viet lai (PostgreSQL khong tu lam duoc): tinh AVG moi phong mot lan roi join'
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.lname, e.salary
FROM employee e
JOIN (SELECT dno, avg(salary) AS luong_tb FROM employee GROUP BY dno) t
  ON t.dno = e.dno
WHERE e.dno = 7 AND e.salary > t.luong_tb;

DROP INDEX idx_employee_dno;
