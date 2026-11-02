-- ---------------------------------------------------------------------------
-- Практическая работа № 10. Объединение таблицы с собой
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Результат каждого запроса сохранён в представление. У представления все
-- столбцы должны называться по-разному, а при объединении таблицы с собой имена
-- повторяются, поэтому столбцы переименованы через AS.
-- Запускать во вкладке SQL, а не через Импорт.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Продавцы из одного города. Условие a.snazv < b.snazv убирает пары продавца
-- с ним же и повторы в обратном порядке.
DROP VIEW IF EXISTS v10_01;
CREATE VIEW v10_01 AS
SELECT a.snazv AS `Продавец 1`, b.snazv AS `Продавец 2`, a.city AS `Город`
FROM salespeople a, salespeople b
WHERE a.city = b.city
  AND a.snazv < b.snazv;

-- 2. Заказчики физ.лица, родившиеся в один год.
DROP VIEW IF EXISTS v10_02;
CREATE VIEW v10_02 AS
SELECT a.name AS `Физ.лицо 1`, b.name AS `Физ.лицо 2`, YEAR(a.gr) AS `Год рождения`
FROM customers_fiz a, customers_fiz b
WHERE YEAR(a.gr) = YEAR(b.gr)
  AND a.name < b.name;

-- 3. Год, в который средняя стоимость заказа с доставкой была выше. Здесь
-- сравниваются средние по годам, поэтому вместо соединения подходит ALL.
DROP VIEW IF EXISTS v10_03;
CREATE VIEW v10_03 AS
SELECT YEAR(odate) AS `Год`,
       ROUND(AVG(amt + dostavka), 2) AS `Средняя стоимость заказа с доставкой`
FROM orders
GROUP BY YEAR(odate)
HAVING AVG(amt + dostavka) >= ALL (
    SELECT AVG(amt + dostavka) FROM orders GROUP BY YEAR(odate)
);

-- 4. Заказчики юр.лица с одинаковым рейтингом: названия и города пар.
DROP VIEW IF EXISTS v10_04;
CREATE VIEW v10_04 AS
SELECT a.ynazv AS `Заказчик 1`, a.city AS `Город 1`,
       b.ynazv AS `Заказчик 2`, b.city AS `Город 2`
FROM customers_yur a, customers_yur b
WHERE a.rating = b.rating
  AND a.ynazv < b.ynazv;

-- 5. Заказчики юр.лица с тем же рейтингом, что у ООО Канцлер. Канцлер ищется по
-- номеру (id_cy = 7), а не по значению рейтинга: если рейтинг изменится, запрос
-- останется верным.
DROP VIEW IF EXISTS v10_05;
CREATE VIEW v10_05 AS
SELECT b.ynazv AS `Заказчик`, b.city AS `Город`
FROM customers_yur a, customers_yur b
WHERE a.id_cy = 7
  AND b.rating = a.rating;

-- 6. Пары заказов одного и того же заказчика юр.лица: дата и стоимость каждого.
-- Условие a.id_z < b.id_z убирает пару заказа с ним же и повторы наоборот.
DROP VIEW IF EXISTS v10_06;
CREATE VIEW v10_06 AS
SELECT cy.ynazv AS `Заказчик`,
       a.odate AS `Дата 1`, a.amt AS `Стоимость 1`,
       b.odate AS `Дата 2`, b.amt AS `Стоимость 2`
FROM orders a, orders b, customers_yur cy
WHERE a.id_cy = b.id_cy
  AND a.id_z < b.id_z
  AND cy.id_cy = a.id_cy;

-- 7. Заказчики юр.лица, которые делали заказы у ИП Ветров и ООО Монтаж, с
-- названием продавца.
DROP VIEW IF EXISTS v10_07;
CREATE VIEW v10_07 AS
SELECT DISTINCT cy.ynazv AS `Заказчик`, s.snazv AS `Продавец`
FROM orders o, customers_yur cy, salespeople s
WHERE o.id_cy = cy.id_cy
  AND o.id_s = s.id_s
  AND s.snazv IN ('Ветров', 'Монтаж');
