SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Импорт из .xlsx (через CSV). Таблица поставок на склад.
DROP TABLE IF EXISTS postavki;
CREATE TABLE postavki (
    id_p              INT AUTO_INCREMENT PRIMARY KEY,
    data_postavki     DATE          NOT NULL,
    postavshik        VARCHAR(100)  NOT NULL,
    kategoriya        VARCHAR(50)   NOT NULL,
    kolichestvo       INT           NOT NULL,
    zakupochnaya_cena DECIMAL(10,2) NOT NULL
);

LOAD DATA INFILE 'c:/ospanel/userdata/temp/upload/postavki.csv'
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

-- 2. Импорт из .txt. Таблица возвратов.
DROP TABLE IF EXISTS vozvraty;
CREATE TABLE vozvraty (
    id_v           INT AUTO_INCREMENT PRIMARY KEY,
    data_vozvrata  DATE          NOT NULL,
    magazin        VARCHAR(100)  NOT NULL,
    prichina       VARCHAR(100)  NOT NULL,
    kolichestvo    INT           NOT NULL,
    summa_vozvrata DECIMAL(10,2) NOT NULL
);

LOAD DATA INFILE 'c:/ospanel/userdata/temp/upload/vozvraty.txt'
INTO TABLE vozvraty
CHARACTER SET cp1251
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@data, magazin, prichina, kolichestvo, @summa)
SET data_vozvrata  = STR_TO_DATE(@data, '%d.%m.%Y'),
    summa_vozvrata = REPLACE(@summa, ',', '.');

SELECT * FROM vozvraty;

