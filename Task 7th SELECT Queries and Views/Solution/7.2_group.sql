-- ---------------------------------------------------------------------------
-- Практическая работа № 7.2. Группировка и упорядочивание данных
-- База torgash_Холкин, СУБД MySQL 8.0
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Сколько продавцов в каждом городе.
DROP VIEW IF EXISTS v7_2_01;
CREATE VIEW v7_2_01 AS
SELECT city AS `Город`, COUNT(*) AS `Количество продавцов`
FROM salespeople
GROUP BY city;

-- 2. Самый молодой мужчина и самая молодая женщина среди физических лиц.
DROP VIEW IF EXISTS v7_2_02;
CREATE VIEW v7_2_02 AS
SELECT name AS `ФИО`, pol AS `Пол`, gr AS `Дата рождения`
FROM customers_fiz
WHERE (pol, gr) IN (SELECT pol, MAX(gr) FROM customers_fiz GROUP BY pol);

-- 3. Самый дорогой заказ каждого юридического лица.
DROP VIEW IF EXISTS v7_2_03;
CREATE VIEW v7_2_03 AS
SELECT id_cy AS `Юр.лицо`, MAX(amt) AS `Самый дорогой заказ`
FROM orders
WHERE id_cy IS NOT NULL
GROUP BY id_cy;

-- 4. Количество физических и юридических лиц, оформивших заказы в каждый день.
DROP VIEW IF EXISTS v7_2_04;
CREATE VIEW v7_2_04 AS
SELECT odate AS `Дата`,
       COUNT(id_cf) AS `Количество физ.лиц`,
       COUNT(id_cy) AS `Количество юр.лиц`
FROM orders
GROUP BY odate
ORDER BY `Количество физ.лиц`, `Количество юр.лиц`;

-- 5. Общая стоимость заказов за каждый день.
DROP VIEW IF EXISTS v7_2_05;
CREATE VIEW v7_2_05 AS
SELECT odate AS `Дата`, SUM(amt) AS `Общая стоимость`
FROM orders
GROUP BY odate;

-- 6. Число физических и юридических лиц, оформивших заказы в каждый день,
-- причём несколько заказов одного лица за день считаются один раз.
DROP VIEW IF EXISTS v7_2_06;
CREATE VIEW v7_2_06 AS
SELECT odate AS `Дата`,
       COUNT(DISTINCT id_cf) AS `Число физ.лиц`,
       COUNT(DISTINCT id_cy) AS `Число юр.лиц`
FROM orders
GROUP BY odate
ORDER BY `Число физ.лиц`, `Число юр.лиц`;
