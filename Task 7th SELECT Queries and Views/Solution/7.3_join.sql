-- ---------------------------------------------------------------------------
-- Практическая работа № 7.3. Запрос из нескольких таблиц
-- База torgash_Холкин, СУБД MySQL 8.0
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Сколько юридических лиц по каждому виду статуса.
DROP VIEW IF EXISTS v7_3_01;
CREATE VIEW v7_3_01 AS
SELECT status AS `Статус`, COUNT(*) AS `Количество юр.лиц`
FROM customers_yur
GROUP BY status;

-- 2. Физические лица, у которых скидка ниже средней.
DROP VIEW IF EXISTS v7_3_02;
CREATE VIEW v7_3_02 AS
SELECT * FROM customers_fiz
WHERE skidka < (SELECT AVG(skidka) FROM customers_fiz);

-- 3. Заказы, оформленные самой молодой компанией-продавцом.
DROP VIEW IF EXISTS v7_3_03;
CREATE VIEW v7_3_03 AS
SELECT o.id_z AS `Заказ`, o.amt AS `Стоимость`, o.odate AS `Дата заказа`,
       s.snazv AS `Продавец`, s.data_reg AS `Дата регистрации`
FROM orders o
JOIN salespeople s ON o.id_s = s.id_s
WHERE s.data_reg = (SELECT MAX(data_reg) FROM salespeople);

-- 4. Физическое лицо, продавец и сумма их сделки, если они из одного города.
DROP VIEW IF EXISTS v7_3_04;
CREATE VIEW v7_3_04 AS
SELECT cf.name AS `Физ.лицо`, s.snazv AS `Продавец`,
       o.amt AS `Сумма сделки`, cf.city AS `Город`
FROM orders o
JOIN customers_fiz cf ON o.id_cf = cf.id_cf
JOIN salespeople s ON o.id_s = s.id_s
WHERE cf.city = s.city;

-- 5. Заказы физических лиц, родившихся после 2000 года.
DROP VIEW IF EXISTS v7_3_05;
CREATE VIEW v7_3_05 AS
SELECT o.amt AS `Стоимость`, o.odate AS `Дата заказа`,
       cf.name AS `ФИО`, cf.gr AS `Дата рождения`
FROM orders o
JOIN customers_fiz cf ON o.id_cf = cf.id_cf
WHERE YEAR(cf.gr) > 2000;

-- 6. Заказы продавцов, у которых указан только городской номер телефона.
-- Городской номер отличается кодом в скобках, мобильный записан через дефисы.
DROP VIEW IF EXISTS v7_3_06;
CREATE VIEW v7_3_06 AS
SELECT o.amt AS `Стоимость`, o.odate AS `Дата заказа`,
       s.snazv AS `Продавец`, s.tel AS `Телефон`
FROM orders o
JOIN salespeople s ON o.id_s = s.id_s
WHERE s.tel LIKE '%(%';

-- 7. Заказы юридических лиц, рейтинг которых выше среднего.
DROP VIEW IF EXISTS v7_3_07;
CREATE VIEW v7_3_07 AS
SELECT o.amt AS `Стоимость`, o.odate AS `Дата заказа`,
       cy.ynazv AS `Юр.лицо`, cy.rating AS `Рейтинг`
FROM orders o
JOIN customers_yur cy ON o.id_cy = cy.id_cy
WHERE cy.rating > (SELECT AVG(rating) FROM customers_yur);

-- 8. Общая стоимость всех заказов для каждого физического и юридического лица.
DROP VIEW IF EXISTS v7_3_08;
CREATE VIEW v7_3_08 AS
SELECT cf.name AS `Заказчик`, SUM(o.amt) AS `Общая стоимость заказов`
FROM orders o
JOIN customers_fiz cf ON o.id_cf = cf.id_cf
GROUP BY cf.id_cf, cf.name
UNION ALL
SELECT cy.ynazv, SUM(o.amt)
FROM orders o
JOIN customers_yur cy ON o.id_cy = cy.id_cy
GROUP BY cy.id_cy, cy.ynazv;

-- 9. Самый дорогой заказ для каждого физического и юридического лица.
DROP VIEW IF EXISTS v7_3_09;
CREATE VIEW v7_3_09 AS
SELECT cf.name AS `Заказчик`, MAX(o.amt) AS `Самый дорогой заказ`
FROM orders o
JOIN customers_fiz cf ON o.id_cf = cf.id_cf
GROUP BY cf.id_cf, cf.name
UNION ALL
SELECT cy.ynazv, MAX(o.amt)
FROM orders o
JOIN customers_yur cy ON o.id_cy = cy.id_cy
GROUP BY cy.id_cy, cy.ynazv;

-- 10. Продавцы, которые больше всего участвовали в заказах, с их видом
-- собственности и количеством заказов.
DROP VIEW IF EXISTS v7_3_10;
CREATE VIEW v7_3_10 AS
SELECT s.snazv AS `Продавец`, v.name AS `Вид собственности`,
       COUNT(*) AS `Количество заказов`
FROM orders o
JOIN salespeople s ON o.id_s = s.id_s
JOIN vids v ON s.id_vs = v.id_vs
GROUP BY s.id_s, s.snazv, v.name
HAVING COUNT(*) = (
    SELECT MAX(k) FROM (SELECT COUNT(*) AS k FROM orders GROUP BY id_s) AS t
);

-- 11. Время года, в которое оформляется меньше всего заказов.
DROP VIEW IF EXISTS v7_3_11;
CREATE VIEW v7_3_11 AS
SELECT CASE
           WHEN MONTH(odate) IN (12, 1, 2) THEN 'Зима'
           WHEN MONTH(odate) IN (3, 4, 5)  THEN 'Весна'
           WHEN MONTH(odate) IN (6, 7, 8)  THEN 'Лето'
           ELSE 'Осень'
       END AS `Время года`,
       COUNT(*) AS `Количество заказов`
FROM orders
GROUP BY `Время года`
ORDER BY `Количество заказов`
LIMIT 1;

-- 12. Общая сумма заказов каждого продавца, у которого она больше, чем самый
-- большой заказ в таблице.
DROP VIEW IF EXISTS v7_3_12;
CREATE VIEW v7_3_12 AS
SELECT s.snazv AS `Продавец`, SUM(o.amt) AS `Общая сумма заказов`
FROM orders o
JOIN salespeople s ON o.id_s = s.id_s
GROUP BY s.id_s, s.snazv
HAVING SUM(o.amt) > (SELECT MAX(amt) FROM orders);
