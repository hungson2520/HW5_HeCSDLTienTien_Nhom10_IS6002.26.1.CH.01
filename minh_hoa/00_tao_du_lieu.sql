-- =====================================================================
-- BT5 - Tao CSDL COMPANY du lon de thay khac biet giua cac ke hoach.
-- Lay luoc do + 8 nhan vien goc cua BT2, roi sinh them:
--   EMPLOYEE 200.008, WORKS_ON 1.000.016, PROJECT 2.000, DEPARTMENT 50,
--   DEPENDENT 100.006 dong.
-- Du lieu co chu y lech: phong 5 co ~30% nhan vien, phong 1 chi 1 nguoi;
-- luong chia theo ty le Hinh 19.4. Co du an 'Aquarius' (Hinh 19.2) va
-- ~10 du an o 'Stafford' (Muc 19.6). DEPARTMENT them cot Zipcode (Muc 18.1.1).
-- Chay:  createdb company_opt
--        psql -d company_opt -f 00_tao_du_lieu.sql     (khoang 30 giay)
-- =====================================================================

\set ON_ERROR_STOP on

-- Luoc do + 8 nhan vien goc cua BT2 (file nay tu DROP va tao lai bang)
\ir ../../BT2_PostgreSQL/outputs/01_company_postgresql_load.sql

BEGIN;

-- Muc 18.1.1 / 19.2.2: "DEPARTMENT (Dnumber, Dname, Mgr_ssn, Mgr_start_date, Zipcode)"
ALTER TABLE department ADD COLUMN zipcode INTEGER;
UPDATE department SET zipcode = CASE WHEN dnumber % 5 = 0 THEN 30332 ELSE 77001 END;

-- So ngau nhien lap lai duoc: chay lai script cho ra dung du lieu cu
SELECT setseed(0.42);

-- 47 phong moi: 2, 3, 6..50. Truong phong phong n la nhan vien moi so n.
INSERT INTO department (dname, dnumber, mgr_ssn, mgr_start_date, zipcode)
SELECT 'Dept_' || lpad(n::text, 2, '0'),
       n,
       (100000000 + n)::text,
       DATE '2000-01-01' + n,
       CASE WHEN n % 5 = 0 THEN 30332 ELSE 77001 + n % 4 END
FROM generate_series(2, 50) AS n
WHERE n NOT IN (4, 5);

INSERT INTO dept_locations (dnumber, dlocation)
SELECT dnumber, 'City_' || lpad(dnumber::text, 3, '0')
FROM department
WHERE dnumber NOT IN (1, 4, 5);

-- 200.000 nhan vien moi, Ssn = 100000001 .. 100200000
INSERT INTO employee (fname, minit, lname, ssn, bdate, address, sex, salary, super_ssn, dno)
WITH phong_khac AS (
    SELECT array_agg(n ORDER BY n) AS ds
    FROM generate_series(2, 50) AS n
    WHERE n NOT IN (4, 5)
),
nv AS (
    SELECT i, random() AS u_luong, random() AS u_phong, random() AS u_ngay
    FROM generate_series(1, 200000) AS i
),
nv_phong AS (
    SELECT nv.*,
           CASE
               WHEN i IN (2, 3) OR i BETWEEN 6 AND 50 THEN i      -- truong phong
               WHEN u_phong < 0.30 THEN 5
               WHEN u_phong < 0.40 THEN 4
               ELSE pk.ds[1 + floor((u_phong - 0.40) / 0.60 * 47)::int]
           END AS dno
    FROM nv CROSS JOIN phong_khac AS pk
)
SELECT (ARRAY['John','Franklin','Alicia','Jennifer','Ramesh','Joyce','Ahmad',
              'James','Mary','Linda','David','Susan','Robert','Karen','Thomas',
              'Nancy','Daniel','Lisa','Paul','Emma'])[1 + i % 20],
       chr(65 + i % 26),
       CASE WHEN i % 5000 = 0 THEN 'Smith'
            ELSE 'Ln' || lpad(((i * 7919) % 4999)::text, 4, '0') END,
       (100000000 + i)::text,
       DATE '1940-01-01' + floor(u_ngay * 21900)::int,
       (100 + i % 9000)::text || ' Main,'
           || (ARRAY['Houston','Bellaire','Sugarland','Stafford','Humble',
                     'Spring','Katy','Dallas'])[1 + i % 8] || ',TX',
       CASE WHEN i % 2 = 0 THEN 'F' ELSE 'M' END,
       round(CASE
           WHEN u_luong < 0.22 THEN  30000 + (u_luong       ) / 0.22 *  10000
           WHEN u_luong < 0.59 THEN  40000 + (u_luong - 0.22) / 0.37 *  30000
           WHEN u_luong < 0.80 THEN  70000 + (u_luong - 0.59) / 0.21 *  50000
           WHEN u_luong < 0.93 THEN 120000 + (u_luong - 0.80) / 0.13 *  80000
           ELSE                     200000 + (u_luong - 0.93) / 0.07 * 300000
       END::numeric, -2),
       CASE
           WHEN i IN (2, 3) OR i BETWEEN 6 AND 50 THEN '888665555'
           WHEN dno = 5 THEN '333445555'
           WHEN dno = 4 THEN '987654321'
           ELSE (100000000 + dno)::text
       END,
       dno
FROM nv_phong;

-- 1.994 du an moi (Pnumber 31..2024), tong cong 2.000 du an.
-- Plocation co 200 gia tri; moi gia tri ~10 du an.
INSERT INTO project (pname, pnumber, plocation, dnum)
SELECT CASE WHEN p = 1000 THEN 'Aquarius' ELSE 'Project_' || p END,
       p,
       CASE (p * 37) % 200
           WHEN 0 THEN 'Bellaire'
           WHEN 1 THEN 'Sugarland'
           WHEN 2 THEN 'Houston'
           WHEN 3 THEN 'Stafford'
           ELSE 'City_' || lpad(((p * 37) % 200 + 1)::text, 3, '0')
       END,
       1 + floor(random() * 50)::int
FROM generate_series(31, 2024) AS p;

-- Moi nhan vien moi lam 5 du an khac nhau: 1.000.000 dong.
-- (397 * k) mod 2000 khac nhau voi k = 1..5 nen 5 du an cua mot nguoi khong trung.
INSERT INTO works_on (essn, pno, hours)
WITH ds AS (SELECT array_agg(pnumber ORDER BY pnumber) AS p FROM project)
SELECT (100000000 + i)::text,
       ds.p[1 + (i * 7919 + k * 397) % 2000],
       round((5 + random() * 35)::numeric * 2) / 2
FROM generate_series(1, 200000) AS i
CROSS JOIN generate_series(1, 5) AS k
CROSS JOIN ds;

-- Nguoi phu thuoc: 1/3 nhan vien moi co 1 nguoi, 1/6 co 2 nguoi (~100.000 dong)
INSERT INTO dependent (essn, dependent_name, sex, bdate, relationship)
SELECT (100000000 + i)::text,
       'Child_' || j,
       CASE WHEN (i + j) % 2 = 0 THEN 'F' ELSE 'M' END,
       DATE '1990-01-01' + (i * 13 + j) % 9000,
       CASE WHEN j = 1 THEN 'Son' ELSE 'Daughter' END
FROM generate_series(3, 200000, 3) AS i
CROSS JOIN generate_series(1, 2) AS j
WHERE j = 1 OR i % 6 = 0;

COMMIT;

-- Tat autovacuum de thong ke chi doi khi minh chay ANALYZE (can cho Demo 06).
ALTER TABLE employee       SET (autovacuum_enabled = false);
ALTER TABLE department     SET (autovacuum_enabled = false);
ALTER TABLE dept_locations SET (autovacuum_enabled = false);
ALTER TABLE project        SET (autovacuum_enabled = false);
ALTER TABLE works_on       SET (autovacuum_enabled = false);
ALTER TABLE dependent      SET (autovacuum_enabled = false);

-- VACUUM de bat visibility map (cho Index Only Scan), ANALYZE de co thong ke
VACUUM ANALYZE;

-- Kiem tra nhanh
SELECT 'department' AS bang, count(*) AS so_dong FROM department
UNION ALL SELECT 'employee',  count(*) FROM employee
UNION ALL SELECT 'project',   count(*) FROM project
UNION ALL SELECT 'works_on',  count(*) FROM works_on
UNION ALL SELECT 'dependent', count(*) FROM dependent;

SELECT dno, count(*) AS so_nv
FROM employee
WHERE dno IN (1, 4, 5, 7)
GROUP BY dno
ORDER BY dno;

SELECT count(*) FILTER (WHERE pname = 'Aquarius')     AS so_du_an_aquarius,
       count(*) FILTER (WHERE plocation = 'Stafford') AS so_du_an_stafford
FROM project;
