-- =====================================================================
-- Demo 07 - Chon thuat toan JOIN (Muc 18.4, 19.5.2)
-- Van de: cung mot phep join co 4 thuat toan J1-J4, chenh nhau nhieu lan.
-- Cach giai: uoc tinh chi phi tung thuat toan, chon cai re nhat.
-- Ep tung thuat toan bang tham so enable_* (giong "hint", Muc 19.9.5).
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

CREATE INDEX IF NOT EXISTS idx_employee_dno ON employee (dno);

\echo '>>> [7a] OP6 EMPLOYEE JOIN DEPARTMENT, bo toi uu tu chon'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(e.salary) FROM employee e JOIN department d ON e.dno = d.dnumber;

SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_indexscan = off;
SET enable_bitmapscan = off;
SET enable_indexonlyscan = off;
\echo '>>> [7b] OP6 ep J1 nested-loop join'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(e.salary) FROM employee e JOIN department d ON e.dno = d.dnumber;
RESET enable_indexscan;
RESET enable_bitmapscan;
RESET enable_indexonlyscan;

-- Tat Memoize (PostgreSQL nho ket qua tra chi muc theo Dno): J2 cua sach tra
-- chi muc cho MOI dong cua vong ngoai.
SET enable_memoize = off;
\echo '>>> [7c] OP6 ep J2 index nested-loop join'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(e.salary) FROM employee e JOIN department d ON e.dno = d.dnumber;
RESET enable_memoize;

RESET enable_mergejoin;
SET enable_nestloop = off;
\echo '>>> [7d] OP6 ep J3 sort-merge join'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(e.salary) FROM employee e JOIN department d ON e.dno = d.dnumber;
RESET enable_hashjoin;
RESET enable_nestloop;

\echo '>>> [7e] EMPLOYEE JOIN WORKS_ON (1 trieu dong), bo toi uu tu chon'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(w.hours) FROM employee e JOIN works_on w ON w.essn = e.ssn;

SET enable_hashjoin = off;
SET enable_nestloop = off;
\echo '>>> [7f] EMPLOYEE JOIN WORKS_ON ep J3 sort-merge join'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(w.hours) FROM employee e JOIN works_on w ON w.essn = e.ssn;
RESET enable_hashjoin;
RESET enable_nestloop;

DROP INDEX idx_employee_dno;
