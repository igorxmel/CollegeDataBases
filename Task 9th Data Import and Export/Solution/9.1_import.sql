-- ---------------------------------------------------------------------------
-- Практическая работа № 9, импорт данных (пункты 1 и 2 задания)
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Исходные файлы лежат в папке exchange рядом с docker-compose.yml. Сервер видит
-- её как /var/lib/mysql-files, это каталог secure_file_priv.
--   postavki.xlsx -> postavki.csv   «Сохранить как» CSV из Excel
--   vozvraty.txt                    «Сохранить как» текст с табуляцией из Excel
--
-- Русский Excel пишет файлы в cp1251, даты как ДД.ММ.ГГГГ и десятичные дроби
-- через запятую. MySQL так не читает: дата падает с ошибкой 1292, дробь с ошибкой
-- 1366. Поэтому значения принимаются в переменные и приводятся в разделе SET.
--
-- Скрипт можно запускать повторно: таблицы пересоздаются.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Импорт из .xlsx. Таблица поставок на склад, 6 столбцов: ключ, дата,
-- два символьных, целое и дробное. Ключ в файле отсутствует, его проставляет
-- AUTO_INCREMENT.
DROP TABLE IF EXISTS postavki;
CREATE TABLE postavki (
    id_p              INT AUTO_INCREMENT PRIMARY KEY,
    data_postavki     DATE          NOT NULL,
    postavshik        VARCHAR(100)  NOT NULL,
    kategoriya        VARCHAR(50)   NOT NULL,
    kolichestvo       INT           NOT NULL,
    zakupochnaya_cena DECIMAL(10,2) NOT NULL
);

LOAD DATA INFILE '/var/lib/mysql-files/postavki.csv'
INTO TABLE postavki
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@data, postavshik, kategoriya, kolichestvo, @cena)
SET data_postavki     = STR_TO_DATE(@data, '%d.%m.%Y'),
    zakupochnaya_cena = REPLACE(@cena, ',', '.');

SELECT * FROM postavki;

-- 2. Импорт из .txt. Таблица возвратов, 6 столбцов того же состава.
DROP TABLE IF EXISTS vozvraty;
CREATE TABLE vozvraty (
    id_v           INT AUTO_INCREMENT PRIMARY KEY,
    data_vozvrata  DATE          NOT NULL,
    magazin        VARCHAR(100)  NOT NULL,
    prichina       VARCHAR(100)  NOT NULL,
    kolichestvo    INT           NOT NULL,
    summa_vozvrata DECIMAL(10,2) NOT NULL
);

LOAD DATA INFILE '/var/lib/mysql-files/vozvraty.txt'
INTO TABLE vozvraty
CHARACTER SET cp1251
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@data, magazin, prichina, kolichestvo, @summa)
SET data_vozvrata  = STR_TO_DATE(@data, '%d.%m.%Y'),
    summa_vozvrata = REPLACE(@summa, ',', '.');

SELECT * FROM vozvraty;
