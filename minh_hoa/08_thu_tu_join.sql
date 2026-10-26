-- =====================================================================
-- Demo 08 - Thu tu JOIN (Muc 19.5.3 - 19.6), truy van Q2 cua Muc 19.6
-- Van de: 3 bang co nhieu thu tu join; thu tu co tich Descartes rat cham.
-- Cach giai: chi xet cay left-deep khong co tich Descartes, chon cay re nhat.
-- Q2: voi moi du an o 'Stafford', lay truong phong cua phong quan ly du an.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

CREATE INDEX IF NOT EXISTS idx_project_plocation ON project (plocation);  -- PROJ_PLOC, Hinh 19.6
ANALYZE project;

\echo '>>> [8a] Bo toi uu tu chon thu tu'
EXPLAIN (ANALYZE, BUFFERS)
SELECT Pnumber, Dnum, Lname, Address, Bdate
FROM PROJECT, DEPARTMENT, EMPLOYEE
WHERE Dnum = Dnumber AND Mgr_ssn = Ssn AND Plocation = 'Stafford';

SET join_collapse_limit = 1;  -- giu dung thu tu JOIN nhu cau lenh viet

\echo '>>> [8b] Thu tu 3 cua sach: (DEPARTMENT JOIN EMPLOYEE) JOIN PROJECT'
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.pnumber, p.dnum, e.lname, e.address, e.bdate
FROM department d
JOIN employee e ON d.mgr_ssn = e.ssn
JOIN project p  ON p.dnum = d.dnumber
WHERE p.plocation = 'Stafford';

\echo '>>> [8c] Thu tu co tich Descartes: (PROJECT x EMPLOYEE) JOIN DEPARTMENT'
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.pnumber, p.dnum, e.lname, e.address, e.bdate
FROM project p
CROSS JOIN employee e
JOIN department d ON p.dnum = d.dnumber AND d.mgr_ssn = e.ssn
WHERE p.plocation = 'Stafford';

RESET join_collapse_limit;
DROP INDEX idx_project_plocation;
