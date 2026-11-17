-- ---------------------------------------------------------------------------
-- Практическая работа № 11. Оконные функции в SQL
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Оконные функции есть в MySQL с версии 8.0 (и в MariaDB с 10.2), в более старых
-- версиях запросы не заработают. Результат каждого запроса сохранён в представление.
-- Запускать во вкладке SQL, а не через Импорт.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Максимальные комиссионные в каждом городе рядом с исходными данными продавца.
-- MAX(...) OVER (PARTITION BY city) считает максимум по городу и не схлопывает строки.
-- Номер уникальности даёт ROW_NUMBER, он стоит перед столбцом с максимумом.
DROP VIEW IF EXISTS v11_01;
CREATE VIEW v11_01 AS
SELECT snazv AS `Имя продавца`,
       comm  AS `Комиссионные`,
       city  AS `Город`,
       ROW_NUMBER() OVER (ORDER BY id_s) AS `Номер уникальности`,
       MAX(comm) OVER (PARTITION BY city) AS `Максимальная комиссия в каждом городе`
FROM salespeople;

-- 2. Накопительный итог стоимости заказов для каждого продавца. Окно делится по
-- продавцу и упорядочено по дате, номер заказа разводит заказы одного дня, иначе
-- итог для них посчитался бы одним значением.
DROP VIEW IF EXISTS v11_02;
CREATE VIEW v11_02 AS
SELECT o.odate AS `Дата оформления заказа`,
       o.amt   AS `Стоимость заказа`,
       s.snazv AS `Имя продавца`,
       SUM(o.amt) OVER (PARTITION BY o.id_s ORDER BY o.odate, o.id_z)
           AS `Накопительная сумма стоимости заказов`
FROM orders o
JOIN salespeople s ON s.id_s = o.id_s;

-- 3. Максимальная стоимость заказа каждого заказчика физ.лица и стоимость заказа,
-- которая шла перед ней. Заказы заказчика нумеруются по убыванию стоимости, второй
-- по номеру и есть предшествующий максимальному. Результат берётся оконной
-- функцией по заказчику и повторяется в каждой его строке. Имя последнего столбца
-- короче, чем в задании: MySQL ограничивает имя столбца 64 символами.
DROP VIEW IF EXISTS v11_03;
CREATE VIEW v11_03 AS
WITH t AS (
    SELECT f.name AS name,
           o.amt  AS amt,
           f.id_cf AS id_cf,
           MAX(o.amt) OVER (PARTITION BY o.id_cf) AS max_amt,
           ROW_NUMBER() OVER (PARTITION BY o.id_cf ORDER BY o.amt DESC) AS rn
    FROM orders o
    JOIN customers_fiz f ON f.id_cf = o.id_cf
)
SELECT name AS `Имя заказчика физ.лица`,
       amt  AS `Стоимость заказа`,
       max_amt AS `Максимальная стоимость заказа для каждого заказчика физ.лица`,
       MAX(CASE WHEN rn = 2 THEN amt END) OVER (PARTITION BY id_cf)
           AS `Стоимость заказа, предшествующая максимальной`
FROM t;

-- 4. Номер юр.лица с максимальной суммарной стоимостью заказов. Сначала по каждому
-- юр.лицу считается сумма, потом RANK ставит места, и выбирается первое.
DROP VIEW IF EXISTS v11_04;
CREATE VIEW v11_04 AS
WITH sums AS (
    SELECT id_cy, SUM(amt) AS total
    FROM orders
    WHERE id_cy IS NOT NULL
    GROUP BY id_cy
), ranked AS (
    SELECT id_cy, total, RANK() OVER (ORDER BY total DESC) AS place
    FROM sums
)
SELECT id_cy AS `Номер юр.лица`
FROM ranked
WHERE place = 1;

-- 4.1. Имя этого юр.лица и сама максимальная суммарная стоимость.
DROP VIEW IF EXISTS v11_04_1;
CREATE VIEW v11_04_1 AS
WITH sums AS (
    SELECT id_cy, SUM(amt) AS total
    FROM orders
    WHERE id_cy IS NOT NULL
    GROUP BY id_cy
), ranked AS (
    SELECT id_cy, total, RANK() OVER (ORDER BY total DESC) AS place
    FROM sums
)
SELECT y.ynazv AS `Имя юр.лица`,
       r.total AS `Максимальная суммарная стоимость заказов`
FROM ranked r
JOIN customers_yur y ON y.id_cy = r.id_cy
WHERE r.place = 1;

-- 4.2. К лидеру добавлено второе место: условие place <= 2 и номер места в выводе.
DROP VIEW IF EXISTS v11_04_2;
CREATE VIEW v11_04_2 AS
WITH sums AS (
    SELECT id_cy, SUM(amt) AS total
    FROM orders
    WHERE id_cy IS NOT NULL
    GROUP BY id_cy
), ranked AS (
    SELECT id_cy, total, RANK() OVER (ORDER BY total DESC) AS place
    FROM sums
)
SELECT r.place AS `Место`,
       y.ynazv AS `Имя юр.лица`,
       r.total AS `Суммарная стоимость заказов`
FROM ranked r
JOIN customers_yur y ON y.id_cy = r.id_cy
WHERE r.place <= 2;

-- Проверка
SELECT * FROM v11_01 ORDER BY `Номер уникальности`;
SELECT * FROM v11_02 ORDER BY `Имя продавца`, `Накопительная сумма стоимости заказов`;
SELECT * FROM v11_03 ORDER BY `Имя заказчика физ.лица`, `Стоимость заказа`;
SELECT * FROM v11_04;
SELECT * FROM v11_04_1;
SELECT * FROM v11_04_2 ORDER BY `Место`;
