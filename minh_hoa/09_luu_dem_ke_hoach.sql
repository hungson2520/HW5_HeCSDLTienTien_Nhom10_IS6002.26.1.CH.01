-- =====================================================================
-- Demo 09 - Luu dem ke hoach (Muc 19.7.3)
-- Loi ich: cau lenh co tham so chi lap ke hoach mot lan, dung lai nhieu lan.
-- Van de: mot ke hoach chung khong hop voi moi gia tri tham so khi du lieu lech.
-- Cau hoi: tong so gio lam du an cua nhan vien mot phong ($1).
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

CREATE INDEX IF NOT EXISTS idx_employee_dno ON employee (dno);

PREPARE gio_phong(int) AS
    SELECT count(*), sum(w.hours)
    FROM employee e JOIN works_on w ON w.essn = e.ssn
    WHERE e.dno = $1;

SET plan_cache_mode = force_custom_plan;
\echo '>>> [9a] Ke hoach rieng cho phong 1 (1 nguoi)'
EXPLAIN (ANALYZE, BUFFERS) EXECUTE gio_phong(1);

SET plan_cache_mode = force_generic_plan;
\echo '>>> [9b] Ke hoach chung (dung lai cho moi phong), chay cho phong 1'
EXPLAIN (ANALYZE, BUFFERS) EXECUTE gio_phong(1);

RESET plan_cache_mode;
DEALLOCATE gio_phong;
DROP INDEX idx_employee_dno;
