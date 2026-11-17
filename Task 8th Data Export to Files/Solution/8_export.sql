SET NAMES utf8mb4;
USE torgash_Холкин;

-- 3. Таблица «Заказы» (zakazy.csv)
SELECT 'id_z', 'amt', 'dostavka', 'odate', 'id_s', 'id_cf', 'id_cy'
UNION ALL
SELECT 
    id_z, 
    REPLACE(amt, '.', ','), 
    REPLACE(dostavka, '.', ','), 
    odate, 
    id_s, 
    IFNULL(id_cf, ''), 
    IFNULL(id_cy, '')
FROM orders
INTO OUTFILE 'c:/ospanel/userdata/temp/upload/zakazy.csv'
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n';

-- 4. Таблица «Заказчики юр.лица» (zakazchiki_yur.txt)
SELECT 'id_cy', 'ynazv', 'id_vs', 'city', 'rating', 'status'
UNION ALL
SELECT 
    id_cy, 
    ynazv, 
    id_vs, 
    city, 
    rating, 
    status
FROM customers_yur
INTO OUTFILE 'c:/ospanel/userdata/temp/upload/zakazchiki_yur.txt'
CHARACTER SET cp1251
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n';
