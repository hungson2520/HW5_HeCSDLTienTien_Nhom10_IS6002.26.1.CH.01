-- =====================================================================
-- Demo 05 - Thong ke va histogram (Muc 18.3.4, 19.3.2, 19.3.3)
-- Van de: bo toi uu chon ke hoach theo so dong no UOC TINH. Uoc tinh sai
--         (gia dinh phan phoi deu, hoac thong ke cu) thi chon sai ke hoach.
-- Cach giai: luu thong ke + histogram trong catalog, cap nhat bang ANALYZE.
-- Du lieu lech: phong 1 co 1 nguoi, phong 5 co 59.953 nguoi.
-- Neu gia dinh phan phoi deu (1/NDV) thi phong nao cung ~4.000 nguoi.
-- =====================================================================

\set ON_ERROR_STOP on
SET max_parallel_workers_per_gather = 0;
SET jit = off;

\echo '>>> [5a] Thong ke cot Dno trong catalog: so gia tri khac nhau, gia tri hay gap'
SELECT n_distinct,
       (most_common_vals::text::int[])[1:3] AS gia_tri_hay_gap,
       most_common_freqs[1:3]               AS ty_le
FROM pg_stats
WHERE tablename = 'employee' AND attname = 'dno';

\echo '>>> [5b] Histogram cot Salary (do cao bang nhau, 100 ngan): cac moc cach 10 ngan'
SELECT ARRAY(SELECT (histogram_bounds::text::numeric[])[i]
             FROM generate_series(1, 101, 10) AS i) AS moc
FROM pg_stats
WHERE tablename = 'employee' AND attname = 'salary';

CREATE INDEX IF NOT EXISTS idx_employee_dno ON employee (dno);

\echo '>>> [5c] Dno = 1: uoc tinh dung 1 dong => dung chi muc'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM employee WHERE dno = 1;

\echo '>>> [5d] Dno = 5: uoc tinh dung ~60.000 dong => doi ke hoach'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM employee WHERE dno = 5;

BEGIN;
UPDATE employee SET dno = 1 WHERE dno = 5;   -- chuyen 59.953 nguoi sang phong 1

\echo '>>> [5e] Thong ke CU: van tuong phong 1 co 1 nguoi'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(w.hours)
FROM employee e JOIN works_on w ON w.essn = e.ssn
WHERE e.dno = 1;

ANALYZE employee;

\echo '>>> [5f] Sau ANALYZE: uoc tinh dung, doi ke hoach'
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(w.hours)
FROM employee e JOIN works_on w ON w.essn = e.ssn
WHERE e.dno = 1;

ROLLBACK;

DROP INDEX idx_employee_dno;
VACUUM ANALYZE employee;   -- tra thong ke ve nhu cu
