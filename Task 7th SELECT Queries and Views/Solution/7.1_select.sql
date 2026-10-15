-- ---------------------------------------------------------------------------
-- Практическая работа № 7.1. Условные операторы и агрегатные функции
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Результат каждого запроса сохранён в представление, как требует задание.
-- Запускать во вкладке SQL, а не через Импорт.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Из каких городов физические лица.
DROP VIEW IF EXISTS v7_1_01;
CREATE VIEW v7_1_01 AS
SELECT DISTINCT city FROM customers_fiz;

-- 2. Юридические лица, зарегистрированные в Липецке.
DROP VIEW IF EXISTS v7_1_02;
CREATE VIEW v7_1_02 AS
SELECT * FROM customers_yur WHERE city = 'Липецк';

-- 3. Физические лица не старше 30 лет.
DROP VIEW IF EXISTS v7_1_03;
CREATE VIEW v7_1_03 AS
SELECT * FROM customers_fiz WHERE vozrast <= 30;

-- 4. Юридические лица с рейтингом 100 и 200.
DROP VIEW IF EXISTS v7_1_04;
CREATE VIEW v7_1_04 AS
SELECT * FROM customers_yur WHERE rating IN (100, 200);

-- 5. Заказы, оформленные осенью, со стоимостью больше 3000.
DROP VIEW IF EXISTS v7_1_05;
CREATE VIEW v7_1_05 AS
SELECT * FROM orders
WHERE MONTH(odate) IN (9, 10, 11) AND amt > 3000;

-- 6. Физические лица с фамилиями из первой половины алфавита (А-Н).
DROP VIEW IF EXISTS v7_1_06;
CREATE VIEW v7_1_06 AS
SELECT * FROM customers_fiz
WHERE LEFT(name, 1) BETWEEN 'А' AND 'Н';

-- 7. Виды собственности, в полном названии которых есть слово «общество».
DROP VIEW IF EXISTS v7_1_07;
CREATE VIEW v7_1_07 AS
SELECT * FROM vids WHERE name LIKE '%общество%';

-- 8. Заказы с бесплатной доставкой.
DROP VIEW IF EXISTS v7_1_08;
CREATE VIEW v7_1_08 AS
SELECT * FROM orders WHERE dostavka = 0;

-- 9. Количество юридических лиц из Ростова-на-Дону.
DROP VIEW IF EXISTS v7_1_09;
CREATE VIEW v7_1_09 AS
SELECT COUNT(*) AS `Количество` FROM customers_yur
WHERE city = 'Ростов-на-Дону';

-- 10. Сумма, на которую оформлены все заказы зимой.
DROP VIEW IF EXISTS v7_1_10;
CREATE VIEW v7_1_10 AS
SELECT SUM(amt) AS `Сумма заказов` FROM orders
WHERE MONTH(odate) IN (12, 1, 2);

-- 11. Средняя стоимость доставки летом.
DROP VIEW IF EXISTS v7_1_11;
CREATE VIEW v7_1_11 AS
SELECT AVG(dostavka) AS `Средняя доставка` FROM orders
WHERE MONTH(odate) IN (6, 7, 8);

-- 12. Самый молодой заказчик физическое лицо из Казани.
DROP VIEW IF EXISTS v7_1_12;
CREATE VIEW v7_1_12 AS
SELECT * FROM customers_fiz
WHERE city = 'Казань'
ORDER BY gr DESC
LIMIT 1;

-- 13. Итоговая стоимость заказа с учётом доставки весной со скидкой 5%.
DROP VIEW IF EXISTS v7_1_13;
CREATE VIEW v7_1_13 AS
SELECT (amt + dostavka) * 0.95 AS `Итоговая стоимость заказа`
FROM orders
WHERE MONTH(odate) IN (3, 4, 5);

-- 14. Стоимость заказа при скидке 10% на заказы свыше 20000.
DROP VIEW IF EXISTS v7_1_14;
CREATE VIEW v7_1_14 AS
SELECT amt * 0.9 AS `Стоимость заказа с 10% скидкой`
FROM orders
WHERE amt > 20000;

-- 15. Сколько видов собственности, в полном названии которых есть слово
-- «общество».
DROP VIEW IF EXISTS v7_1_15;
CREATE VIEW v7_1_15 AS
SELECT COUNT(*) AS `Количество` FROM vids
WHERE name LIKE '%общество%';
