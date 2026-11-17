-- ---------------------------------------------------------------------------
-- Практическая работа № 12. Создание хранимых процедур
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Тела процедур содержат «;», поэтому разделитель на время создания меняется на $$.
-- Запускать во вкладке SQL, а не через Импорт. Скрипт перезапускаемый: перед
-- созданием каждая процедура удаляется.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

DELIMITER $$

-- 1. Pr1 с характеристиками из задания, выводит надпись.
DROP PROCEDURE IF EXISTS Pr1$$
CREATE PROCEDURE Pr1()
LANGUAGE sql
DETERMINISTIC
SQL SECURITY DEFINER
COMMENT 'First'
BEGIN
    SELECT 'Моя первая процедура' AS `Надпись`;
END$$

-- 2. show_all по очереди выводит содержимое всех таблиц базы. Список таблиц берётся из
-- information_schema, поэтому процедура не ломается, если в базе есть таблицы других
-- работ (postavki, vozvraty) или какой-то из них нет. Курсор идёт по именам таблиц,
-- а запрос собирается строкой и выполняется через PREPARE.
DROP PROCEDURE IF EXISTS show_all$$
CREATE PROCEDURE show_all()
BEGIN
    DECLARE t VARCHAR(64);
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
        ORDER BY table_name;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO t;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SET @sql = CONCAT('SELECT * FROM `', t, '`');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    CLOSE cur;
END$$

-- 3. Pr2 считает заказы заказчиков физ.лиц из Казани мужского пола.
DROP PROCEDURE IF EXISTS Pr2$$
CREATE PROCEDURE Pr2()
BEGIN
    SELECT COUNT(*) AS `Нужные заказы`
    FROM orders o
    JOIN customers_fiz f ON f.id_cf = o.id_cf
    WHERE f.city = 'Казань' AND f.pol = 'м';
END$$

-- 4. Pr3: на вход целое num1, на выход вещественное num2, равное экспоненте num1.
DROP PROCEDURE IF EXISTS Pr3$$
CREATE PROCEDURE Pr3(IN num1 INT, OUT num2 DOUBLE)
BEGIN
    SET num2 = EXP(num1);
END$$

-- 5. Pr4: принимает строку и создаёт целочисленную переменную X, равную 1 для «North»
-- и 0 для остальных строк, затем выводит её.
DROP PROCEDURE IF EXISTS Pr4$$
CREATE PROCEDURE Pr4(IN str VARCHAR(50))
BEGIN
    DECLARE X INT;
    IF str = 'North' THEN
        SET X = 1;
    ELSE
        SET X = 0;
    END IF;
    SELECT X;
END$$

-- 6. Pr5: числа от 1 до n, кратные 2 либо 3, по одному в строке результата.
DROP PROCEDURE IF EXISTS Pr5$$
CREATE PROCEDURE Pr5(IN n INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= n DO
        IF i MOD 2 = 0 OR i MOD 3 = 0 THEN
            SELECT i;
        END IF;
        SET i = i + 1;
    END WHILE;
END$$

-- 7. Pr6: курсор проходит по суммам заказов больше 999 и копит их в sum_amt.
DROP PROCEDURE IF EXISTS Pr6$$
CREATE PROCEDURE Pr6(OUT sum_amt DECIMAL(12,2))
BEGIN
    DECLARE a DECIMAL(10,2);
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR SELECT amt FROM orders WHERE amt > 999;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET sum_amt = 0;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO a;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SET sum_amt = sum_amt + a;
    END LOOP;
    CLOSE cur;
END$$

DELIMITER ;

-- Запрос из Pr2 сохранён в представление.
DROP VIEW IF EXISTS v12_pr2;
CREATE VIEW v12_pr2 AS
SELECT COUNT(*) AS `Нужные заказы`
FROM orders o
JOIN customers_fiz f ON f.id_cf = o.id_cf
WHERE f.city = 'Казань' AND f.pol = 'м';

-- Демонстрация
CALL Pr1();
CALL show_all();
CALL Pr2();
SELECT * FROM v12_pr2;
CALL Pr3(2, @num2);
SELECT @num2 AS `Экспонента числа 2`;
CALL Pr4('North');
CALL Pr4('South');
CALL Pr5(10);
CALL Pr6(@sum_amt);
SELECT @sum_amt AS `Сумма заказов больше 999`;
