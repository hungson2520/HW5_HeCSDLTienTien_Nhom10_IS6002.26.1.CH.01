-- =====================================================================
-- Demo 03 - Hop nhat view (Muc 19.2.3)
-- Van de: tinh xong ca view roi moi join thi khong loc truoc, khong dung
--         duoc chi muc cua cac bang ben trong view.
-- Cach giai: gop cac bang cua view vao cau truy van chinh.
-- View: WORKS_ON JOIN PROJECT. Truy van ngoai: nhan vien ho 'Smith' (41 nguoi).
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

CREATE OR REPLACE VIEW v_works_project AS
SELECT w.essn, p.pname, w.hours
FROM works_on w JOIN project p ON p.pnumber = w.pno;

\echo '>>> [3a] Khong hop nhat: tinh ca view (1 trieu dong) roi moi join'
EXPLAIN (ANALYZE, BUFFERS)
WITH v AS MATERIALIZED (SELECT * FROM v_works_project)
SELECT e.fname, e.lname, v.pname, v.hours
FROM employee e JOIN v ON v.essn = e.ssn
WHERE e.lname = 'Smith';

\echo '>>> [3b] Hop nhat: PostgreSQL gop view vao cau chinh'
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.fname, e.lname, v.pname, v.hours
FROM employee e JOIN v_works_project v ON v.essn = e.ssn
WHERE e.lname = 'Smith';

DROP VIEW v_works_project;
