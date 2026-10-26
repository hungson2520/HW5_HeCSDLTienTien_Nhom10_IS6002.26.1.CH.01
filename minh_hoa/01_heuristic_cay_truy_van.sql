-- =====================================================================
-- Demo 01 - Toi uu heuristic (Muc 19.1.2, Hinh 19.2)
-- Van de: JOIN truoc roi moi loc thi phai xu ly hang trieu dong.
-- Cach giai: loc truoc, bang loc hep nhat (PROJECT 'Aquarius') di truoc.
-- Truy van Q cua sach: ho cua nhan vien sinh sau 1957 lam du an 'Aquarius'.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;  -- tat chay song song cho ke hoach de doc
SET jit = off;

CREATE INDEX IF NOT EXISTS idx_works_on_pno ON works_on (pno);

\echo '>>> [1a] Cay ban dau (Hinh 19.2a) la tich Descartes 3 bang: bao nhieu dong?'
SELECT to_char((SELECT count(*) FROM employee)::numeric
             * (SELECT count(*) FROM works_on)
             * (SELECT count(*) FROM project), 'FM999G999G999G999G999G999')
       AS so_dong_tich_descartes;

\echo '>>> [1b] Chua toi uu: JOIN ca 3 bang roi moi loc (MATERIALIZED cam day phep loc xuong)'
EXPLAIN (ANALYZE, BUFFERS)
WITH j AS MATERIALIZED (
    SELECT e.lname, e.bdate, p.pname
    FROM employee e
    JOIN works_on w ON e.ssn = w.essn
    JOIN project p  ON p.pnumber = w.pno
)
SELECT lname FROM j
WHERE pname = 'Aquarius' AND bdate > DATE '1957-12-31';

SET join_collapse_limit = 1;  -- giu dung thu tu JOIN nhu cau lenh viet

\echo '>>> [1c] Loc truoc nhung thu tu do (Hinh 19.2b): EMPLOYEE JOIN WORKS_ON truoc'
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.lname
FROM employee e
JOIN works_on w ON e.ssn = w.essn
JOIN project p  ON p.pnumber = w.pno
WHERE p.pname = 'Aquarius' AND e.bdate > DATE '1957-12-31';

RESET join_collapse_limit;

\echo '>>> [1d] Cau SQL goc cua sach, de PostgreSQL tu toi uu (Hinh 19.2c-e)'
EXPLAIN (ANALYZE, BUFFERS)
SELECT E.Lname
FROM EMPLOYEE E, WORKS_ON W, PROJECT P
WHERE P.Pname = 'Aquarius' AND P.Pnumber = W.Pno AND E.Ssn = W.Essn
  AND E.Bdate > '1957-12-31';

DROP INDEX idx_works_on_pno;
