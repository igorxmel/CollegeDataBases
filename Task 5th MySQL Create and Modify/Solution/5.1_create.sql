-- ---------------------------------------------------------------------------
-- Практическая работа № 5.1. Создание базы данных torgash_Холкин
-- СУБД MySQL 8.0 (проверено также на совместимость с MariaDB 10.2+)
--
-- Порядок создания таблиц определён внешними ключами: сначала справочники
-- vids и skid, затем продавцы и заказчики, последними заказы.
--
-- Как запускать в phpMyAdmin: вкладка SQL, а не Импорт. Импорт спотыкается о
-- DELIMITER, который нужен для тел триггеров.
--
-- Требуется версия сервера, которая проверяет CHECK: MySQL от 8.0.16 или
-- MariaDB от 10.2.1. Более старый MySQL разбирает CHECK и молча игнорирует,
-- и тогда половина ограничений задания работать не будет. Версия видна на
-- главной странице phpMyAdmin.
-- ---------------------------------------------------------------------------

DROP DATABASE IF EXISTS torgash_Холкин;
CREATE DATABASE torgash_Холкин CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE torgash_Холкин;

-- ------------------------- Таблица 1. Вид собственности --------------------
-- Справочник организационно-правовых форм. Все поля обязательные.

CREATE TABLE vids (
    id_vs INT AUTO_INCREMENT PRIMARY KEY,
    abr   VARCHAR(10)  NOT NULL UNIQUE,
    name  VARCHAR(100) NOT NULL
);

INSERT INTO vids (id_vs, abr, name) VALUES
(1, 'ИП',  'Индивидуальный предприниматель'),
(2, 'ООО', 'Общество с ограниченной ответственностью'),
(3, 'ПАО', 'Публичное акционерное общество'),
(4, 'НАО', 'Непубличное акционерное общество'),
(5, 'ПК',  'Производственный кооператив');

-- ------------------------------ Таблица 6. Скидки --------------------------
-- Справочник скидок. Создаётся раньше заказчиков, потому что расчёт скидки
-- в триггере обращается к этой таблице. Все поля обязательные.

CREATE TABLE skid (
    id_sk   INT AUTO_INCREMENT PRIMARY KEY,
    skid    INT          NOT NULL,
    uslovie VARCHAR(100) NOT NULL,
    summa   DECIMAL(10,2) NOT NULL
);

-- Столбец summa это условие из справочника в числовом виде: по тексту
-- «больше 1500 руб» считать в триггере нельзя, а разбирать строку каждый раз
-- дороже, чем хранить порог рядом.
INSERT INTO skid (id_sk, skid, uslovie, summa) VALUES
(1, 10, 'Общая стоимость заказов больше 1500 руб', 1500.00),
(2, 15, 'Общая стоимость заказов больше 3000 руб', 3000.00),
(3, 20, 'Общая стоимость заказов больше 5000 руб', 5000.00);

-- ----------------------------- Таблица 2. Продавцы -------------------------
-- Форма собственности берётся из справочника vids, в названии продавца она не
-- фигурирует. Все поля кроме comm обязательные. Комиссионные от 0.10 до 0.20.

CREATE TABLE salespeople (
    id_s   INT AUTO_INCREMENT PRIMARY KEY,
    snazv  VARCHAR(100) NOT NULL,
    id_vs  INT          NOT NULL,
    city   VARCHAR(100) NOT NULL,
    tel    VARCHAR(30)  NOT NULL,
    naprav VARCHAR(100) NOT NULL,
    comm   DECIMAL(4,2) NULL,
    CONSTRAINT fk_salespeople_vids FOREIGN KEY (id_vs) REFERENCES vids (id_vs),
    CONSTRAINT salespeople_chk_comm CHECK (comm IS NULL OR comm BETWEEN 0.10 AND 0.20)
);

INSERT INTO salespeople (id_s, snazv, id_vs, city, tel, naprav, comm) VALUES
(1, 'Ветров',     1, 'Казань',           '8-900-375-15-65',  'кондитерские изделия',  0.12),
(2, 'Монтаж',     2, 'Нижний Новгород',  '+7 (831) 224-16-16','трикотажная продукция', 0.13),
(3, 'СтройМаркт', 2, 'Казань',           '+7 (432) 115-66-66','кондитерские изделия',  0.11),
(4, 'Костин',     1, 'Новочеркасск',     '8-938-715-63-28',  'кондитерские изделия',  0.15),
(5, 'Семёнов',    1, 'Ростов-на-Дону',   '8-960-368-58-96',  'строй.материалы',       0.10);

-- Запрет на изменение уже существующих комиссионных.
DELIMITER $$
CREATE TRIGGER salespeople_before_update
BEFORE UPDATE ON salespeople
FOR EACH ROW
BEGIN
    IF NOT (NEW.comm <=> OLD.comm) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Комиссионные изменять нельзя';
    END IF;
END$$
DELIMITER ;

-- ------------------------ Таблица 3. Заказчики физ.лица --------------------
-- Все поля кроме скидки обязательные. Пол только «м» или «ж». Регистрация не
-- младше 18 лет. Скидка по умолчанию 0 и считается автоматически.

CREATE TABLE customers_fiz (
    id_cf  INT AUTO_INCREMENT PRIMARY KEY,
    name   VARCHAR(100) NOT NULL,
    city   VARCHAR(100) NOT NULL,
    pol    CHAR(1)      NOT NULL,
    gr     DATE         NOT NULL,
    skidka INT          NOT NULL DEFAULT 0,
    CONSTRAINT customers_fiz_chk_pol CHECK (pol IN ('м', 'ж'))
);

-- Возраст проверяется триггером, а не ограничением CHECK: в MySQL внутри CHECK
-- нельзя использовать недетерминированные функции вроде CURDATE().
DELIMITER $$
CREATE TRIGGER customers_fiz_before_insert
BEFORE INSERT ON customers_fiz
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.gr, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Регистрация только с 18 лет';
    END IF;
END$$

-- Пол и дату рождения менять нельзя, остальное (город, скидка) можно.
CREATE TRIGGER customers_fiz_before_update
BEFORE UPDATE ON customers_fiz
FOR EACH ROW
BEGIN
    IF NEW.pol <> OLD.pol THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Пол изменять нельзя';
    END IF;
    IF NEW.gr <> OLD.gr THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Дату рождения изменять нельзя';
    END IF;
END$$
DELIMITER ;

INSERT INTO customers_fiz (id_cf, name, city, pol, gr) VALUES
(1, 'Астахов И.И.',   'Казань',          'м', '1997-01-02'),
(2, 'Зверев С.Н.',    'Калуга',          'м', '1987-09-12'),
(3, 'Янкин В.И.',     'Нижний Новгород', 'м', '1997-05-13'),
(4, 'Борн А.В.',      'Брянск',          'м', '1990-04-18'),
(5, 'Гришина П.П.',   'Казань',          'ж', '1991-07-21'),
(6, 'Свиридова А.Г.', 'Нижний Новгород', 'ж', '2004-08-25'),
(7, 'Паршин Р.Р.',    'Калуга',          'м', '1997-08-28');

-- ------------------------ Таблица 4. Заказчики юр.лица ---------------------
-- Форма собственности из справочника, в названии не фигурирует. Все поля
-- обязательные. По умолчанию форма «ООО». Рейтинг от 100 до 500.

CREATE TABLE customers_yur (
    id_cy  INT AUTO_INCREMENT PRIMARY KEY,
    ynazv  VARCHAR(100) NOT NULL,
    id_vs  INT          NOT NULL DEFAULT 2,
    city   VARCHAR(100) NOT NULL,
    rating INT          NOT NULL,
    CONSTRAINT fk_customers_yur_vids FOREIGN KEY (id_vs) REFERENCES vids (id_vs),
    CONSTRAINT customers_yur_chk_rating CHECK (rating BETWEEN 100 AND 500)
);

INSERT INTO customers_yur (id_cy, ynazv, id_vs, city, rating) VALUES
(1, 'Алые паруса', 2, 'Липецк',         100),
(2, 'Южный ветер', 2, 'Ростов-на-Дону', 200),
(3, 'СтройИнвест', 2, 'Самара',         200),
(4, 'Курочка',     3, 'Белгород',       300),
(5, 'Нива',        3, 'Липецк',         100),
(6, 'Атлант',      4, 'Самара',         300),
(7, 'Канцлер',     2, 'Ростов-на-Дону', 100);

-- ------------------------------ Таблица 5. Заказы --------------------------
-- Обязательные: стоимость, доставка, дата и номер продавца. Номера заказчиков
-- могут быть пустыми. При стоимости больше 11000 доставка равна нулю и не
-- подлежит изменению.

CREATE TABLE orders (
    id_z      INT AUTO_INCREMENT PRIMARY KEY,
    amt       DECIMAL(10,2) NOT NULL,
    dostavka  DECIMAL(10,2) NOT NULL DEFAULT 0,
    odate     DATE          NOT NULL,
    id_s      INT           NOT NULL,
    id_cf     INT           NULL,
    id_cy     INT           NULL,
    CONSTRAINT fk_orders_salespeople   FOREIGN KEY (id_s)  REFERENCES salespeople (id_s),
    CONSTRAINT fk_orders_customers_fiz FOREIGN KEY (id_cf) REFERENCES customers_fiz (id_cf),
    CONSTRAINT fk_orders_customers_yur FOREIGN KEY (id_cy) REFERENCES customers_yur (id_cy)
);

DELIMITER $$
-- Бесплатная доставка для заказов дороже 11000 рублей.
CREATE TRIGGER orders_before_insert
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.amt > 11000 THEN
        SET NEW.dostavka = 0;
    END IF;
END$$

-- Тот же ноль нельзя переписать вручную.
CREATE TRIGGER orders_before_update
BEFORE UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.amt > 11000 AND NEW.dostavka <> 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Для заказа дороже 11000 доставка бесплатная';
    END IF;
END$$

-- Пересчёт скидки физического лица по справочнику skid: берётся максимальная
-- скидка, порог которой не превышает сумму всех заказов этого заказчика.
CREATE TRIGGER orders_after_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.id_cf IS NOT NULL THEN
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
DELIMITER ;

INSERT INTO orders (id_z, amt, dostavka, odate, id_s, id_cf, id_cy) VALUES
(1,     18.69,  80, '2023-03-10', 5, 3,    NULL),
(2,    767.19,  50, '2023-03-10', 1, 1,    NULL),
(3,   1900.10, 150, '2023-03-10', 4, 7,    NULL),
(4,   5160.45, 200, '2023-03-10', 2, NULL, 1),
(5,   1098.16, 100, '2023-03-10', 5, 5,    NULL),
(6,   1713.23, 100, '2023-04-10', 3, 2,    NULL),
(7,     75.75,  80, '2023-04-10', 2, 4,    NULL),
(8,   4723.00, 180, '2023-05-10', 1, NULL, 2),
(9,   1309.95, 100, '2023-06-10', 2, 4,    NULL),
(10,  9891.88, 400, '2023-06-10', 1, NULL, 3),
(11, 12135.18,   0, '2023-09-15', 1, NULL, 7),
(12,  3700.00, 150, '2023-10-02', 2, NULL, 4),
(13,   588.58, 100, '2023-10-12', 1, 1,    NULL),
(14,  2750.00, 150, '2023-10-25', 3, 4,    NULL),
(15,  3488.25, 250, '2023-11-01', 2, NULL, 5),
(16,  1960.23, 120, '2023-11-15', 4, 6,    NULL),
(17, 15800.00,   0, '2023-12-20', 5, NULL, 6),
(18, 17250.20,   0, '2024-01-10', 5, NULL, 7),
(19, 23600.50,   0, '2024-01-12', 4, NULL, 2),
(20,  1150.00,  80, '2024-01-15', 3, 6,    NULL),
(21,  2200.00,  80, '2024-01-15', 3, 6,    NULL);

-- ------------------------------- Проверка ----------------------------------
SHOW TABLES;
SELECT id_cf, name, skidka FROM customers_fiz ORDER BY id_cf;
SELECT id_z, amt, dostavka FROM orders WHERE amt > 11000;
