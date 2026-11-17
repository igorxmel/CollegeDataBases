-- ---------------------------------------------------------------------------
-- Практическая работа № 14. Генераторы и их использование
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Генераторы из методички (CREATE GENERATOR, GEN_ID) есть в Firebird и InterBase, в
-- MySQL их нет. Здесь они сделаны так же по смыслу: таблица generators хранит
-- счётчики, а функция gen_id(имя, шаг) прибавляет шаг к счётчику и возвращает новое
-- значение. Шаг 0 возвращает текущее значение, как в методичке.
--
-- Таблица создана с движком MyISAM, у него нет транзакций. Это нужно ради главного
-- свойства генератора: значение не откатывается вместе с транзакцией. В InnoDB
-- счётчик вернулся бы назад при ROLLBACK.
--
-- Запускать во вкладке SQL, а не через Импорт: в скрипте DELIMITER. Скрипт
-- перезапускаемый, генераторы создаются заново.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- Если на сервере включён бинарный журнал (в MySQL 8 он включён по умолчанию), он не
-- разрешает создавать функции, которые меняют данные, ошибкой 1418. Эта настройка
-- снимает ограничение. Без бинарного журнала она ничего не меняет. Нужны права root.
SET GLOBAL log_bin_trust_function_creators = 1;

-- Хранилище генераторов: имя и текущее значение.
DROP TABLE IF EXISTS generators;
CREATE TABLE generators (
    name  VARCHAR(31) NOT NULL PRIMARY KEY,
    value BIGINT      NOT NULL DEFAULT 0
) ENGINE = MyISAM;

DELIMITER $$

-- GEN_ID(имя, шаг): прибавляет шаг и возвращает новое значение. LAST_INSERT_ID(выражение)
-- запоминает значение для текущего соединения, поэтому два пользователя не получат
-- одно и то же число.
DROP FUNCTION IF EXISTS gen_id$$
CREATE FUNCTION gen_id(gen_name VARCHAR(31), inc INT) RETURNS BIGINT
NOT DETERMINISTIC
MODIFIES SQL DATA
BEGIN
    IF NOT EXISTS (SELECT 1 FROM generators WHERE name = gen_name) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Генератор не найден';
    END IF;
    UPDATE generators SET value = LAST_INSERT_ID(value + inc) WHERE name = gen_name;
    RETURN LAST_INSERT_ID();
END$$

-- SET GENERATOR имя TO значение.
DROP PROCEDURE IF EXISTS set_generator$$
CREATE PROCEDURE set_generator(IN gen_name VARCHAR(31), IN new_value BIGINT)
BEGIN
    UPDATE generators SET value = new_value WHERE name = gen_name;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------------
-- Генератор 1. GEN_ORDERS: номера заказов. Продолжает нумерацию в таблице orders,
-- то есть стартует с наибольшего номера заказа, шаг 1.
-- CREATE GENERATOR GEN_ORDERS; SET GENERATOR GEN_ORDERS TO <максимум id_z>;
-- ---------------------------------------------------------------------------
INSERT INTO generators (name, value)
SELECT 'GEN_ORDERS', IFNULL(MAX(id_z), 0) FROM orders;

-- ---------------------------------------------------------------------------
-- Генератор 2. GEN_CUSTOMERS_FIZ: номера заказчиков физ.лиц, стартует с наибольшего
-- номера в таблице customers_fiz, шаг 1.
-- ---------------------------------------------------------------------------
INSERT INTO generators (name, value)
SELECT 'GEN_CUSTOMERS_FIZ', IFNULL(MAX(id_cf), 0) FROM customers_fiz;

-- ---------------------------------------------------------------------------
-- Генератор 3. GEN_DOC_NO: номера отгрузочных документов, начиная с 1000, шаг 10.
-- Шаг передаётся в gen_id, поэтому один и тот же механизм годится для любой
-- нумерации.
-- ---------------------------------------------------------------------------
INSERT INTO generators (name, value) VALUES ('GEN_DOC_NO', 1000);

-- ---------------------------------------------------------------------------
-- Демонстрация
-- ---------------------------------------------------------------------------

-- Текущие значения всех генераторов (шаг 0 ничего не меняет).
SELECT gen_id('GEN_ORDERS', 0)        AS `GEN_ORDERS`,
       gen_id('GEN_CUSTOMERS_FIZ', 0) AS `GEN_CUSTOMERS_FIZ`,
       gen_id('GEN_DOC_NO', 0)        AS `GEN_DOC_NO`;

-- Следующие значения: заказ, заказчик и документ.
SELECT gen_id('GEN_ORDERS', 1)        AS `Следующий заказ`,
       gen_id('GEN_CUSTOMERS_FIZ', 1) AS `Следующий заказчик`,
       gen_id('GEN_DOC_NO', 10)       AS `Следующий документ`;

-- Генератор не откатывается вместе с транзакцией: заказ не сохранится, а номер
-- останется использованным.
SELECT gen_id('GEN_ORDERS', 0) AS `Перед транзакцией`;

START TRANSACTION;
INSERT INTO orders (id_z, amt, dostavka, odate, id_s, id_cy)
VALUES (gen_id('GEN_ORDERS', 1), 500.00, 50.00, CURDATE(), 1, 1);
ROLLBACK;

SELECT gen_id('GEN_ORDERS', 0) AS `После отката транзакции`;
SELECT COUNT(*) AS `Заказов в таблице` FROM orders;

-- Переустановка значения: SET GENERATOR GEN_DOC_NO TO 1000.
CALL set_generator('GEN_DOC_NO', 1000);
SELECT gen_id('GEN_DOC_NO', 0) AS `GEN_DOC_NO после переустановки`;

SELECT * FROM generators ORDER BY name;
