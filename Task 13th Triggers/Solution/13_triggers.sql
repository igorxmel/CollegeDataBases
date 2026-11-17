-- ---------------------------------------------------------------------------
-- Практическая работа № 13. Создание триггеров для таблицы в MySQL
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Выполняется после 5.1 и 5.2 на той же базе. Запускать во вкладке SQL, а не через
-- Импорт: в скрипте DELIMITER. Демонстрация в конце меняет данные, поэтому заказ
-- 22 получится только на базе, где заказов до него было 21.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- ---------------------------------------------------------------------------
-- 1. Связи продавцы - заказы, заказчики физ.лица - заказы и заказчики юр.лица -
-- заказы: каскадное удаление и обновление. Внешние ключи пересоздаются.
-- ---------------------------------------------------------------------------

ALTER TABLE orders
    DROP FOREIGN KEY fk_orders_salespeople,
    DROP FOREIGN KEY fk_orders_customers_fiz,
    DROP FOREIGN KEY fk_orders_customers_yur;

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_salespeople FOREIGN KEY (id_s) REFERENCES salespeople (id_s)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_orders_customers_fiz FOREIGN KEY (id_cf) REFERENCES customers_fiz (id_cf)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_orders_customers_yur FOREIGN KEY (id_cy) REFERENCES customers_yur (id_cy)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- 2. Конечная стоимость заказа. Первоначальная стоимость amt не меняется, а в новом
-- столбце amt_itog лежит стоимость плюс комиссия продавца. Столбца в таблице не
-- было, поэтому он добавляется и заполняется для существующих заказов.
-- ---------------------------------------------------------------------------

ALTER TABLE orders
    ADD COLUMN amt_itog DECIMAL(12,2) NULL AFTER amt;

UPDATE orders o
JOIN salespeople s ON s.id_s = o.id_s
SET o.amt_itog = o.amt + o.amt * IFNULL(s.comm, 0);

DELIMITER $$

-- В новом заказе конечная стоимость считается при вставке. Триггер BEFORE INSERT на
-- orders уже есть, второй такой же создать нельзя, поэтому он пересоздаётся с тем же
-- правилом про бесплатную доставку и новым расчётом.
DROP TRIGGER IF EXISTS orders_before_insert$$
CREATE TRIGGER orders_before_insert
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.amt > 11000 THEN
        SET NEW.dostavka = 0;
    END IF;
    SET NEW.amt_itog = NEW.amt + NEW.amt * IFNULL(
        (SELECT comm FROM salespeople WHERE id_s = NEW.id_s), 0);
END$$

-- Скидка физ.лица пересчитывается после вставки заказа. Если заказ создаёт триггер
-- на заказчике (пункт 3), UPDATE customers_fiz внутри него даёт ошибку 1442, потому
-- что таблица уже занята вызвавшей командой. Признак @auto_order отключает пересчёт
-- на время такого заказа.
DROP TRIGGER IF EXISTS orders_after_insert$$
CREATE TRIGGER orders_after_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.id_cf IS NOT NULL AND IFNULL(@auto_order, 0) = 0 THEN
        UPDATE customers_fiz
        SET skidka = IFNULL((
                SELECT MAX(s.skid)
                FROM skid s
                WHERE s.summa <= (
                    SELECT SUM(o.amt) FROM orders o WHERE o.id_cf = NEW.id_cf
                )
            ), 0)
        WHERE id_cf = NEW.id_cf;
    END IF;
END$$

-- Запрет на смену комиссионных из ПР 5.2 снят, иначе пересчёт ниже никогда не
-- сработает. Запрет на смену даты регистрации остаётся.
DROP TRIGGER IF EXISTS salespeople_before_update$$
CREATE TRIGGER salespeople_before_update
BEFORE UPDATE ON salespeople
FOR EACH ROW
BEGIN
    IF NEW.data_reg <> OLD.data_reg THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Дату регистрации изменять нельзя';
    END IF;
END$$

-- 2.1. Триггер на изменение комиссионных: пересчитывает конечную стоимость заказов
-- этого продавца. Столбец amt не трогается.
DROP TRIGGER IF EXISTS salespeople_after_update$$
CREATE TRIGGER salespeople_after_update
AFTER UPDATE ON salespeople
FOR EACH ROW
BEGIN
    IF NOT (NEW.comm <=> OLD.comm) THEN
        UPDATE orders
        SET amt_itog = amt + amt * IFNULL(NEW.comm, 0)
        WHERE id_s = NEW.id_s;
    END IF;
END$$

-- ---------------------------------------------------------------------------
-- 3. Триггер на внесение нового заказчика физ.лица: ему автоматически создаётся заказ
-- на 1200 рублей с доставкой 100, который обслуживает ИП Ветров. Сумма взята ниже
-- первого порога скидки (1500), поэтому скидка заказчика остаётся нулевой.
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS customers_fiz_after_insert$$
CREATE TRIGGER customers_fiz_after_insert
AFTER INSERT ON customers_fiz
FOR EACH ROW
BEGIN
    SET @auto_order = 1;
    INSERT INTO orders (amt, dostavka, odate, id_s, id_cf)
    VALUES (1200.00, 100.00, CURDATE(),
            (SELECT id_s FROM salespeople WHERE snazv = 'Ветров'), NEW.id_cf);
    SET @auto_order = 0;
END$$

-- ---------------------------------------------------------------------------
-- 4. Триггер на удаление продавца: перед удалением его заказы переписываются на
-- ИП Семёнов, вместе с заказом пересчитывается конечная стоимость по комиссии нового
-- продавца. Без него каскад из пункта 1 удалил бы заказы вместе с продавцом.
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS salespeople_before_delete$$
CREATE TRIGGER salespeople_before_delete
BEFORE DELETE ON salespeople
FOR EACH ROW
BEGIN
    DECLARE heir INT;
    DECLARE heir_comm DECIMAL(4,2);

    SELECT id_s, comm INTO heir, heir_comm
    FROM salespeople
    WHERE snazv = 'Семёнов';

    IF OLD.id_s <> heir THEN
        UPDATE orders
        SET id_s = heir,
            amt_itog = amt + amt * IFNULL(heir_comm, 0)
        WHERE id_s = OLD.id_s;
    END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------------
-- Демонстрация удаления продавца. Добавляется ИП Петров, на него оформляется заказ
-- на 4022 рубля с Борн А.В. (он получает номер 22), затем Петров удаляется, и в
-- заказе 22 вместо него должен появиться Семёнов (id_s = 5).
-- ---------------------------------------------------------------------------
INSERT INTO salespeople (snazv, id_vs, city, tel, naprav, comm)
VALUES ('Петров', 1, 'Азов', '8-900-600-60-60', 'строй.материалы', 0.10);

-- Номера заказчика и продавца берутся заранее в переменные: если читать customers_fiz
-- подзапросом прямо в INSERT, триггер orders_after_insert не сможет её обновить
-- (ошибка 1442).
SET @petrov = (SELECT id_s FROM salespeople WHERE snazv = 'Петров');
SET @born = (SELECT id_cf FROM customers_fiz WHERE name = 'Борн А.В.');
INSERT INTO orders (amt, dostavka, odate, id_s, id_cf)
VALUES (4022.00, 100.00, CURDATE(), @petrov, @born);

SELECT id_z, amt, amt_itog, id_s, id_cf FROM orders WHERE id_z = 22;

DELETE FROM salespeople WHERE snazv = 'Петров';

SELECT id_z, amt, amt_itog, id_s, id_cf FROM orders WHERE id_z = 22;

-- ---------------------------------------------------------------------------
-- Демонстрация триггера на нового заказчика: добавляется физ.лицо, и ему сразу
-- появляется заказ у Ветрова.
-- ---------------------------------------------------------------------------
INSERT INTO customers_fiz (name, city, pol, gr)
VALUES ('Ковалёв Д.С.', 'Ростов-на-Дону', 'м', '1995-05-05');

SELECT o.id_z, o.amt, o.amt_itog, s.snazv, f.name, f.skidka
FROM orders o
JOIN salespeople s ON s.id_s = o.id_s
JOIN customers_fiz f ON f.id_cf = o.id_cf
WHERE f.name = 'Ковалёв Д.С.';

-- ---------------------------------------------------------------------------
-- Демонстрация пересчёта: у Ветрова комиссионные 0.12, меняем на 0.15. Конечная
-- стоимость его заказов должна измениться, первоначальная нет.
-- ---------------------------------------------------------------------------
SELECT id_z, amt, amt_itog FROM orders WHERE id_s = 1 ORDER BY id_z;

UPDATE salespeople SET comm = 0.15 WHERE snazv = 'Ветров';

SELECT id_z, amt, amt_itog FROM orders WHERE id_s = 1 ORDER BY id_z;

-- Возвращаем комиссионные обратно.
UPDATE salespeople SET comm = 0.12 WHERE snazv = 'Ветров';
