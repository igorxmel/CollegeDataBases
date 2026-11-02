-- ---------------------------------------------------------------------------
-- Практическая работа № 8. Экспорт данных базы в документы пользователя
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- SELECT ... INTO OUTFILE пишет файл на стороне сервера и только в каталог
-- secure_file_priv. В Docker это /var/lib/mysql-files, на хосте он виден как
-- папка exchange рядом с docker-compose.yml.
--
-- INTO OUTFILE не перезаписывает существующий файл: при повторном запуске
-- падает с ошибкой 1086, поэтому старые файлы из exchange нужно удалить.
-- Запускать во вкладке SQL, по одному запросу.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;
USE torgash_Холкин;

-- 1. Таблица «Заказы» в .xlsx.
-- INTO OUTFILE пишет текст, а не книгу Excel, поэтому выгрузка идёт в .csv.
-- Файл открывается в Excel и сохраняется как .xlsx.
SELECT * FROM orders
INTO OUTFILE '/var/lib/mysql-files/zakazy.csv'
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';

-- 2. Таблица «Заказчики юр.лица» в .txt.
SELECT * FROM customers_yur
INTO OUTFILE '/var/lib/mysql-files/zakazchiki_yur.txt'
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
