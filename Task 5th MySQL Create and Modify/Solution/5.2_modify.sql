-- ---------------------------------------------------------------------------
-- Практическая работа № 5.2. Модификация базы данных torgash_Холкин
-- Выполняется после 5.1_create.sql
--
-- Триггеры, созданные в 5.1, здесь пересоздаются: в них добавляется новая
-- логика, а заменить тело триггера иначе как пересозданием MySQL не умеет.
-- ---------------------------------------------------------------------------

USE torgash_Холкин;

-- --- 1. Название продавца должно быть уникальным ----------------------------

ALTER TABLE salespeople
    ADD CONSTRAINT salespeople_uq_snazv UNIQUE (snazv);

-- --- 2. Дата регистрации продавца -------------------------------------------
-- Подставляется автоматически текущей датой и не подлежит изменению.

ALTER TABLE salespeople
    ADD COLUMN data_reg DATE NOT NULL DEFAULT (CURRENT_DATE) AFTER naprav;

-- --- 3. Форма собственности продавца по умолчанию «ИП» ----------------------

ALTER TABLE salespeople
    ALTER COLUMN id_vs SET DEFAULT 1;

-- Запрет на изменение комиссионных (из 5.1) и даты регистрации (новое).
DROP TRIGGER IF EXISTS salespeople_before_update;
DELIMITER $$
CREATE TRIGGER salespeople_before_update
BEFORE UPDATE ON salespeople
FOR EACH ROW
BEGIN
    IF NOT (NEW.comm <=> OLD.comm) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Комиссионные изменять нельзя';
    END IF;
    IF NEW.data_reg <> OLD.data_reg THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Дату регистрации изменять нельзя';
    END IF;
END$$
DELIMITER ;

-- --- 4. Возраст заказчика физического лица ----------------------------------

ALTER TABLE customers_fiz
    ADD COLUMN vozrast INT NULL AFTER gr;

-- Заполнение возраста для уже внесённых заказчиков.
UPDATE customers_fiz
SET vozrast = TIMESTAMPDIFF(YEAR, gr, CURDATE());

-- --- 5. Возраст при вставке и сообщение о пенсионном возрасте ---------------
-- SQLSTATE '01000' это предупреждение: строка вставляется, а сообщение
-- показывается через SHOW WARNINGS. Код '45000' прервал бы вставку.

DROP TRIGGER IF EXISTS customers_fiz_before_insert;
DELIMITER $$
CREATE TRIGGER customers_fiz_before_insert
BEFORE INSERT ON customers_fiz
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.gr, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Регистрация только с 18 лет';
    END IF;

    SET NEW.vozrast = TIMESTAMPDIFF(YEAR, NEW.gr, CURDATE());

    IF NEW.vozrast > 65 THEN
        SIGNAL SQLSTATE '01000' SET MESSAGE_TEXT = 'Заказчик пенсионного возраста';
    END IF;
END$$
DELIMITER ;

-- --- 6. Статус юридического лица --------------------------------------------

ALTER TABLE customers_yur
    ADD COLUMN status VARCHAR(10) NOT NULL DEFAULT 'низкий' AFTER rating;

-- --- 7. Автоматический статус по рейтингу -----------------------------------
-- 100-200 низкий, 201-400 средний, 401-500 высокий.

DELIMITER $$
CREATE TRIGGER customers_yur_before_insert
BEFORE INSERT ON customers_yur
FOR EACH ROW
BEGIN
    SET NEW.status = CASE
        WHEN NEW.rating <= 200 THEN 'низкий'
        WHEN NEW.rating <= 400 THEN 'средний'
        ELSE 'высокий'
    END;
END$$

CREATE TRIGGER customers_yur_before_update
BEFORE UPDATE ON customers_yur
FOR EACH ROW
BEGIN
    SET NEW.status = CASE
        WHEN NEW.rating <= 200 THEN 'низкий'
        WHEN NEW.rating <= 400 THEN 'средний'
        ELSE 'высокий'
    END;
END$$
DELIMITER ;

-- Пересчёт статуса для уже внесённых юридических лиц.
UPDATE customers_yur SET rating = rating;

-- ------------------------------- Проверка ----------------------------------

DESCRIBE salespeople;
DESCRIBE customers_fiz;
DESCRIBE customers_yur;

SELECT id_cf, name, gr, vozrast FROM customers_fiz ORDER BY id_cf;
SELECT id_cy, ynazv, rating, status FROM customers_yur ORDER BY id_cy;

-- Проверка сообщения о пенсионном возрасте: строка вставится, предупреждение
-- покажет SHOW WARNINGS.
INSERT INTO customers_fiz (name, city, pol, gr)
VALUES ('Петров А.А.', 'Казань', 'м', '1955-04-11');
SHOW WARNINGS;

SELECT id_cf, name, vozrast FROM customers_fiz WHERE vozrast > 65;
