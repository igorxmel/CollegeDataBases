-- ---------------------------------------------------------------------------
-- Практическая работа № 17. Реализация доступа пользователей к базе данных
-- База torgash_Холкин из практической работы № 5, СУБД MySQL 8.0
--
-- Три пользователя: администратор admin (пароль admin), оператор oper (пароль oper)
-- и гость guest (без пароля). Права выдаются GRANT, снимаются REVOKE.
-- Выполнять под root во вкладке SQL. Скрипт перезапускаемый: пользователи
-- сначала удаляются.
-- ---------------------------------------------------------------------------

SET NAMES utf8mb4;

DROP USER IF EXISTS 'admin'@'localhost';
DROP USER IF EXISTS 'oper'@'localhost';
DROP USER IF EXISTS 'guest'@'localhost';

-- Создание пользователей.
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin';
CREATE USER 'oper'@'localhost'  IDENTIFIED BY 'oper';
CREATE USER 'guest'@'localhost';

-- Администратор: все права на все таблицы базы данных.
GRANT ALL PRIVILEGES ON `torgash_Холкин`.* TO 'admin'@'localhost';

-- Гость: только просмотр таблиц «Продавцы», «Заказчики физ.лица»,
-- «Заказчики юр.лица» и «Заказы».
GRANT SELECT ON `torgash_Холкин`.salespeople   TO 'guest'@'localhost';
GRANT SELECT ON `torgash_Холкин`.customers_fiz TO 'guest'@'localhost';
GRANT SELECT ON `torgash_Холкин`.customers_yur TO 'guest'@'localhost';
GRANT SELECT ON `torgash_Холкин`.orders        TO 'guest'@'localhost';

-- Оператор: «Вид собственности» и «Скидки» только просмотр.
GRANT SELECT ON `torgash_Холкин`.vids TO 'oper'@'localhost';
GRANT SELECT ON `torgash_Холкин`.skid TO 'oper'@'localhost';

-- Оператор: «Продавцы», «Заказчики физ.лица», «Заказчики юр.лица» и «Заказы»
-- просмотр и внесение данных, без изменения и удаления.
GRANT SELECT, INSERT ON `torgash_Холкин`.salespeople   TO 'oper'@'localhost';
GRANT SELECT, INSERT ON `torgash_Холкин`.customers_fiz TO 'oper'@'localhost';
GRANT SELECT, INSERT ON `torgash_Холкин`.customers_yur TO 'oper'@'localhost';
GRANT SELECT, INSERT ON `torgash_Холкин`.orders        TO 'oper'@'localhost';

FLUSH PRIVILEGES;

-- Проверка: список пользователей и права каждого.
SELECT `user`, `host` FROM `mysql`.`user` WHERE `user` IN ('admin', 'oper', 'guest');
SHOW GRANTS FOR 'admin'@'localhost';
SHOW GRANTS FOR 'oper'@'localhost';
SHOW GRANTS FOR 'guest'@'localhost';
