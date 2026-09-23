-- ---------------------------------------------------------------------------
-- Производственная компания «Мозаика»
-- Данные заказчика, подготовленные из файлов с пометкой import.
-- Скрипт выполняется после schema.sql.
-- ---------------------------------------------------------------------------

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- Таблица unit: 2 строк
INSERT INTO unit (unit_id, unit_name) VALUES (1, 'кг');
INSERT INTO unit (unit_id, unit_name) VALUES (2, 'л');

-- Таблица material_type: 5 строк
INSERT INTO material_type (material_type_id, material_type_name, loss_percent) VALUES (1, 'Пластичные материалы', 0.0012);
INSERT INTO material_type (material_type_id, material_type_name, loss_percent) VALUES (2, 'Добавка', 0.002);
INSERT INTO material_type (material_type_id, material_type_name, loss_percent) VALUES (3, 'Электролит', 0.0015);
INSERT INTO material_type (material_type_id, material_type_name, loss_percent) VALUES (4, 'Глазурь', 0.003);
INSERT INTO material_type (material_type_id, material_type_name, loss_percent) VALUES (5, 'Пигмент', 0.0025);

-- Таблица product_type: 4 строк
INSERT INTO product_type (product_type_id, product_type_name, type_coefficient) VALUES (1, 'Тип продукции 1', 1.2);
INSERT INTO product_type (product_type_id, product_type_name, type_coefficient) VALUES (2, 'Тип продукции 2', 8.59);
INSERT INTO product_type (product_type_id, product_type_name, type_coefficient) VALUES (3, 'Тип продукции 3', 3.45);
INSERT INTO product_type (product_type_id, product_type_name, type_coefficient) VALUES (4, 'Тип продукции 4', 5.6);

-- Таблица organization_type: 4 строк
INSERT INTO organization_type (organization_type_id, organization_type_name) VALUES (1, 'ЗАО');
INSERT INTO organization_type (organization_type_id, organization_type_name) VALUES (2, 'ОАО');
INSERT INTO organization_type (organization_type_id, organization_type_name) VALUES (3, 'ООО');
INSERT INTO organization_type (organization_type_id, organization_type_name) VALUES (4, 'ПАО');

-- Таблица job_position: 4 строк
INSERT INTO job_position (job_position_id, job_position_name) VALUES (1, 'Менеджер');
INSERT INTO job_position (job_position_id, job_position_name) VALUES (2, 'Мастер производства');
INSERT INTO job_position (job_position_id, job_position_name) VALUES (3, 'Аналитик');
INSERT INTO job_position (job_position_id, job_position_name) VALUES (4, 'Кладовщик');

-- Таблица request_status: 6 строк
INSERT INTO request_status (request_status_id, request_status_name) VALUES (1, 'Создана');
INSERT INTO request_status (request_status_id, request_status_name) VALUES (2, 'Ожидает предоплаты');
INSERT INTO request_status (request_status_id, request_status_name) VALUES (3, 'В производстве');
INSERT INTO request_status (request_status_id, request_status_name) VALUES (4, 'Готова к отгрузке');
INSERT INTO request_status (request_status_id, request_status_name) VALUES (5, 'Выполнена');
INSERT INTO request_status (request_status_id, request_status_name) VALUES (6, 'Отменена');

-- Таблица supplier: 20 строк
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (1, 'БрянскСтройресурс', 1, '9432455179', 8, '2015-12-20');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (2, 'Стройкомплект', 1, '7803888520', 7, '2017-09-13');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (3, 'Железногорская руда', 3, '8430391035', 7, '2016-12-23');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (4, 'Белая гора', 3, '4318170454', 8, '2019-05-27');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (5, 'Тульский обрабатывающий завод', 3, '7687851800', 7, '2015-06-16');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (6, 'ГорТехРазработка', 4, '6119144874', 9, '2021-12-27');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (7, 'Сапфир', 2, '1122170258', 3, '2022-04-10');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (8, 'ХимБытСервис', 4, '8355114917', 5, '2022-03-13');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (9, 'ВоронежРудоКомбинат', 2, '3532367439', 8, '2023-11-11');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (10, 'Смоленский добывающий комбинат', 2, '2362431140', 3, '2018-11-23');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (11, 'МосКарьер', 4, '4159215346', 2, '2012-07-07');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (12, 'КурскРесурс', 1, '9032455179', 4, '2021-07-23');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (13, 'Нижегородская разработка', 2, '3776671267', 9, '2016-05-23');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (14, 'Речная долина', 2, '7447864518', 8, '2015-06-25');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (15, 'Карелия добыча', 4, '9037040523', 6, '2017-03-09');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (16, 'Московский ХимЗавод', 4, '6221520857', 4, '2015-05-07');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (17, 'Горная компания', 1, '2262431140', 3, '2020-12-22');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (18, 'Минерал Ресурс', 3, '4155215346', 7, '2015-05-22');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (19, 'Арсенал', 1, '3961234561', 5, '2010-11-25');
INSERT INTO supplier (supplier_id, supplier_name, organization_type_id, inn, rating, work_start_date) VALUES (20, 'КамчаткаСтройМинералы', 1, '9600275878', 7, '2016-12-20');

-- Таблица material: 20 строк
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (1, 'Глина', 1, 1, 15.29, 1570, 5500, 30, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (2, 'Каолин', 1, 1, 18.2, 1030, 3500, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (3, 'Гидрослюда', 1, 1, 17.2, 2147, 3500, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (4, 'Монтмориллонит', 1, 1, 17.67, 3000, 3000, 30, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (5, 'Перлит', 2, 2, 13.99, 150, 1000, 50, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (6, 'Стекло', 2, 1, 2.4, 3000, 1500, 500, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (7, 'Дегидратированная глина', 2, 1, 21.95, 3000, 2500, 20, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (8, 'Шамот', 2, 1, 27.5, 2300, 1960, 20, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (9, 'Техническая сода', 3, 1, 54.55, 1200, 1500, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (10, 'Жидкое стекло', 3, 1, 76.59, 500, 1500, 15, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (11, 'Кварц', 4, 1, 375.96, 1500, 2500, 10, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (12, 'Полевой шпат', 4, 1, 15.99, 750, 1500, 100, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (13, 'Краска-раствор', 5, 2, 200.9, 1496, 2500, 5, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (14, 'Порошок цветной', 5, 1, 84.39, 511, 1750, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (15, 'Кварцевый песок', 2, 1, 4.29, 3000, 1600, 50, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (16, 'Жильный кварц', 2, 1, 18.6, 2556, 1600, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (17, 'Барий углекислый', 4, 1, 303.64, 340, 1500, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (18, 'Бура техническая', 4, 1, 125.99, 165, 1300, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (19, 'Углещелочной реагент', 3, 1, 3.45, 450, 1100, 25, NULL, NULL);
INSERT INTO material (material_id, material_name, material_type_id, unit_id, unit_price, stock_quantity, min_quantity, package_quantity, description, image_path) VALUES (20, 'Пирофосфат натрия', 3, 1, 700.99, 356, 1200, 25, NULL, NULL);

-- Таблица material_supplier: 80 строк
INSERT INTO material_supplier (material_id, supplier_id) VALUES (13, 19);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (2, 3);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (2, 9);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (6, 19);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (15, 1);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (5, 6);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (1, 4);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (15, 20);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (7, 9);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (12, 4);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (1, 1);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (14, 19);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (16, 17);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (12, 1);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (3, 9);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (6, 20);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (12, 12);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (4, 9);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (11, 11);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (17, 17);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (10, 12);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (8, 17);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (1, 6);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (11, 15);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (3, 3);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (5, 9);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (8, 19);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (17, 20);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (18, 20);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (9, 18);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (20, 20);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (3, 4);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (16, 15);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (5, 10);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (15, 15);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (4, 4);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (13, 12);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (6, 7);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (14, 12);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (2, 1);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (10, 18);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (18, 7);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (7, 11);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (18, 13);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (4, 3);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (10, 16);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (10, 7);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (14, 16);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (14, 8);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (19, 16);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (11, 14);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (16, 13);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (13, 16);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (11, 13);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (7, 2);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (15, 14);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (17, 7);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (8, 2);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (7, 7);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (3, 5);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (20, 7);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (5, 5);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (9, 7);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (1, 10);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (9, 16);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (4, 10);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (19, 12);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (9, 8);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (18, 2);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (20, 5);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (16, 10);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (6, 2);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (19, 8);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (17, 5);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (20, 8);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (2, 5);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (8, 11);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (19, 5);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (13, 8);
INSERT INTO material_supplier (material_id, supplier_id) VALUES (12, 10);

-- Таблица stock_movement: 0 строк

-- Таблица employee: 0 строк

-- Таблица product: 0 строк

-- Таблица product_material: 0 строк

-- Таблица production_batch: 0 строк

-- Таблица partner: 0 строк

-- Таблица partner_sale: 0 строк

-- Таблица request: 0 строк

-- Таблица request_item: 0 строк

COMMIT;
