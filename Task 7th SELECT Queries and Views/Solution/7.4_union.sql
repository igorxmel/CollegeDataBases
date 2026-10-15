-- ---------------------------------------------------------------------------
-- Практическая работа № 7.4. UNION, ANY и ALL
-- База torgash_Холкин, СУБД MySQL 8.0
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Стоимость и дата заказа с указанием времени года, отсортированные по
-- временам года.
DROP VIEW IF EXISTS v7_4_01;
CREATE VIEW v7_4_01 AS
SELECT amt AS `Стоимость`, odate AS `Дата заказа`,
       CASE
           WHEN MONTH(odate) IN (12, 1, 2) THEN 'Зима'
           WHEN MONTH(odate) IN (3, 4, 5)  THEN 'Весна'
           WHEN MONTH(odate) IN (6, 7, 8)  THEN 'Лето'
           ELSE 'Осень'
       END AS `Время года`
FROM orders
ORDER BY CASE
             WHEN MONTH(odate) IN (12, 1, 2) THEN 1
             WHEN MONTH(odate) IN (3, 4, 5)  THEN 2
             WHEN MONTH(odate) IN (6, 7, 8)  THEN 3
             ELSE 4
         END;

-- 2. Физические и юридические лица, оформившие больше одного заказа,
-- в алфавитном порядке.
DROP VIEW IF EXISTS v7_4_02;
CREATE VIEW v7_4_02 AS
SELECT cf.name AS `Заказчик`, COUNT(*) AS `Количество заказов`
FROM orders o
JOIN customers_fiz cf ON o.id_cf = cf.id_cf
GROUP BY cf.id_cf, cf.name
HAVING COUNT(*) > 1
UNION
SELECT cy.ynazv, COUNT(*)
FROM orders o
JOIN customers_yur cy ON o.id_cy = cy.id_cy
GROUP BY cy.id_cy, cy.ynazv
HAVING COUNT(*) > 1
ORDER BY `Заказчик`;

-- 3. Продавцы, у которых комиссионные выше, чем у продавцов из Казани.
DROP VIEW IF EXISTS v7_4_03;
CREATE VIEW v7_4_03 AS
SELECT * FROM salespeople
WHERE comm > ALL (SELECT comm FROM salespeople WHERE city = 'Казань');

-- 4. Заказы, которые дороже общей стоимости заказов за 10.03.2023.
DROP VIEW IF EXISTS v7_4_04;
CREATE VIEW v7_4_04 AS
SELECT id_z AS `Заказ`, amt AS `Стоимость`
FROM orders
WHERE amt > (SELECT SUM(amt) FROM orders WHERE odate = '2023-03-10');

-- 5. Город юридических лиц с самым большим суммарным рейтингом.
DROP VIEW IF EXISTS v7_4_05;
CREATE VIEW v7_4_05 AS
SELECT city AS `Город`, SUM(rating) AS `Суммарный рейтинг`
FROM customers_yur
GROUP BY city
HAVING SUM(rating) >= ALL (SELECT SUM(rating) FROM customers_yur GROUP BY city);

-- 6. Заказы юридических лиц из города с максимальным суммарным рейтингом.
DROP VIEW IF EXISTS v7_4_06;
CREATE VIEW v7_4_06 AS
SELECT o.id_z AS `Заказ`, o.amt AS `Стоимость`
FROM orders o
JOIN customers_yur cy ON o.id_cy = cy.id_cy
WHERE cy.city = (
    SELECT city FROM customers_yur
    GROUP BY city
    ORDER BY SUM(rating) DESC
    LIMIT 1
);

-- 7. Юридические лица из города с максимальным суммарным рейтингом и общая
-- стоимость их заказов.
DROP VIEW IF EXISTS v7_4_07;
CREATE VIEW v7_4_07 AS
SELECT cy.ynazv AS `Юр.лицо`, SUM(o.amt) AS `Общая стоимость заказов`
FROM orders o
JOIN customers_yur cy ON o.id_cy = cy.id_cy
WHERE cy.city = (
    SELECT city FROM customers_yur
    GROUP BY city
    ORDER BY SUM(rating) DESC
    LIMIT 1
)
GROUP BY cy.id_cy, cy.ynazv;

-- 8. Продавец с самой большой суммарной стоимостью заказов.
DROP VIEW IF EXISTS v7_4_08;
CREATE VIEW v7_4_08 AS
SELECT s.snazv AS `Продавец`, SUM(o.amt) AS `Общая сумма покупок`
FROM orders o
JOIN salespeople s ON o.id_s = s.id_s
GROUP BY s.id_s, s.snazv
HAVING SUM(o.amt) >= ALL (SELECT SUM(amt) FROM orders GROUP BY id_s);

-- 9. Общая стоимость заказов в каждом городе физических лиц, если она выше
-- средней стоимости всех заказов.
DROP VIEW IF EXISTS v7_4_09;
CREATE VIEW v7_4_09 AS
SELECT cf.city AS `Город`, SUM(o.amt) AS `Общая стоимость заказов`
FROM orders o
JOIN customers_fiz cf ON o.id_cf = cf.id_cf
GROUP BY cf.city
HAVING SUM(o.amt) > (SELECT AVG(amt) FROM orders);
