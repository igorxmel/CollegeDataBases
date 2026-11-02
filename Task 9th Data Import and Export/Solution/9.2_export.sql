-- ---------------------------------------------------------------------------
-- Практическая работа № 9, экспорт данных (пункты 3 и 4 задания)
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Те же две выгрузки, что в практической работе № 8. Файлы пишутся в каталог
-- secure_file_priv, на хосте это папка exchange. Существующий файл INTO OUTFILE
-- не перезаписывает и падает с ошибкой 1086, поэтому перед повторным запуском
-- старые файлы из exchange нужно удалить.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 3. Таблица «Заказы» в .xlsx: выгрузка в .csv, дальше сохранение из Excel.
SELECT * FROM orders
INTO OUTFILE '/var/lib/mysql-files/zakazy.csv'
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- 4. Таблица «Заказчики юр.лица» в .txt.
SELECT * FROM customers_yur
INTO OUTFILE '/var/lib/mysql-files/zakazchiki_yur.txt'
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
