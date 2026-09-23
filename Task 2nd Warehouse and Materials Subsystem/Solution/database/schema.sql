-- ---------------------------------------------------------------------------
-- Производственная компания «Мозаика»
-- Схема базы данных (СУБД SQLite)
--
-- Охвачены все подсистемы описания предметной области (Приложение 1):
-- продукция, склад и материалы, производство, сотрудники, партнёры.
-- Подсистема «Склад и материалы» (задание модуля № 1) заполнена данными
-- заказчика, остальные подсистемы описаны структурно.
--
-- Схема приведена к третьей нормальной форме:
--   * каждый атрибут атомарен, повторяющихся групп нет (1НФ);
--   * все неключевые атрибуты зависят от полного первичного ключа (2НФ);
--   * транзитивные зависимости вынесены в справочники unit, material_type,
--     product_type, organization_type, job_position, request_status (3НФ).
-- Ссылочная целостность обеспечена внешними ключами; в SQLite их проверку
-- включает PRAGMA foreign_keys.
-- ---------------------------------------------------------------------------

PRAGMA foreign_keys = ON;

-- Удаление идёт от дочерних таблиц к родительским, иначе внешние ключи
-- не дадут удалить таблицу, на которую ещё есть ссылки.
DROP TABLE IF EXISTS request_item;
DROP TABLE IF EXISTS request;
DROP TABLE IF EXISTS request_status;
DROP TABLE IF EXISTS partner_sale;
DROP TABLE IF EXISTS partner;
DROP TABLE IF EXISTS production_batch;
DROP TABLE IF EXISTS product_material;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS job_position;
DROP TABLE IF EXISTS stock_movement;
DROP TABLE IF EXISTS material_supplier;
DROP TABLE IF EXISTS material;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS organization_type;
DROP TABLE IF EXISTS product_type;
DROP TABLE IF EXISTS material_type;
DROP TABLE IF EXISTS unit;

-- ===========================================================================
-- Справочники
-- ===========================================================================

-- Единицы измерения материалов (кг, л, ...)
CREATE TABLE unit (
    unit_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    unit_name TEXT    NOT NULL UNIQUE
);

-- Типы материалов с процентом потери сырья при производстве
CREATE TABLE material_type (
    material_type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    material_type_name TEXT    NOT NULL UNIQUE,
    loss_percent       REAL    NOT NULL CHECK (loss_percent >= 0)
);

-- Типы продукции с коэффициентом типа продукции
CREATE TABLE product_type (
    product_type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    product_type_name TEXT    NOT NULL UNIQUE,
    type_coefficient  REAL    NOT NULL CHECK (type_coefficient > 0)
);

-- Организационно-правовые формы (ООО, ЗАО, ОАО, ПАО). Справочник общий:
-- и поставщики, и партнёры — это одни и те же формы собственности,
-- поэтому дублировать его для каждой стороны не нужно.
CREATE TABLE organization_type (
    organization_type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    organization_type_name TEXT    NOT NULL UNIQUE
);

-- Должности сотрудников (менеджер, мастер производства, аналитик, кладовщик)
CREATE TABLE job_position (
    job_position_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    job_position_name TEXT    NOT NULL UNIQUE
);

-- Статусы заявки по описанию процесса из п.3
CREATE TABLE request_status (
    request_status_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    request_status_name TEXT    NOT NULL UNIQUE
);

-- ===========================================================================
-- Подсистема «Склад и материалы» (Приложение 1, п.7–9)
-- ===========================================================================

-- Поставщики материалов (п.9)
CREATE TABLE supplier (
    supplier_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_name        TEXT    NOT NULL UNIQUE,
    organization_type_id INTEGER NOT NULL,
    inn                  TEXT    NOT NULL UNIQUE
                                 CHECK (length(inn) IN (10, 12)),
    rating               INTEGER NOT NULL CHECK (rating >= 0),
    -- Дата в формате ISO-8601; CHECK не пропустит значение со временем
    work_start_date      TEXT    NOT NULL CHECK (work_start_date = date(work_start_date)),
    CONSTRAINT fk_supplier_organization_type
        FOREIGN KEY (organization_type_id) REFERENCES organization_type (organization_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Материалы (сырьё), используемые для производства продукции (п.7)
CREATE TABLE material (
    material_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    material_name    TEXT    NOT NULL UNIQUE,
    material_type_id INTEGER NOT NULL,
    unit_id          INTEGER NOT NULL,
    unit_price       REAL    NOT NULL CHECK (unit_price >= 0),
    stock_quantity   REAL    NOT NULL CHECK (stock_quantity >= 0),
    min_quantity     REAL    NOT NULL CHECK (min_quantity >= 0),
    package_quantity REAL    NOT NULL CHECK (package_quantity > 0),
    -- Описание и изображение названы в п.7, но в формах задания не участвуют
    -- и данных импорта для них заказчик не предоставил.
    description      TEXT,
    image_path       TEXT,
    CONSTRAINT fk_material_material_type
        FOREIGN KEY (material_type_id) REFERENCES material_type (material_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_material_unit
        FOREIGN KEY (unit_id) REFERENCES unit (unit_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Связь «многие ко многим»: какой поставщик поставляет какой материал
CREATE TABLE material_supplier (
    material_id INTEGER NOT NULL,
    supplier_id INTEGER NOT NULL,
    CONSTRAINT pk_material_supplier PRIMARY KEY (material_id, supplier_id),
    CONSTRAINT fk_material_supplier_material
        FOREIGN KEY (material_id) REFERENCES material (material_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_material_supplier_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier (supplier_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- История движения материала на складе: поступления от поставщика (значение
-- положительное) и списания в производство (значение отрицательное).
-- Покрывает «историю изменений количества материалов на складе» (п.7),
-- «историю поставок материалов» (п.9) и движение ТМЦ по складу (п.8).
CREATE TABLE stock_movement (
    movement_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    material_id     INTEGER NOT NULL,
    supplier_id     INTEGER,
    movement_date   TEXT    NOT NULL CHECK (movement_date = date(movement_date)),
    quantity_change REAL    NOT NULL CHECK (quantity_change != 0),
    note            TEXT,
    CONSTRAINT fk_stock_movement_material
        FOREIGN KEY (material_id) REFERENCES material (material_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_stock_movement_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier (supplier_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ===========================================================================
-- Подсистема «Продукция» и производство (Приложение 1, п.8, п.10)
-- ===========================================================================

CREATE TABLE product (
    product_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    article               TEXT    NOT NULL UNIQUE,
    product_type_id       INTEGER NOT NULL,
    product_name          TEXT    NOT NULL UNIQUE,
    description           TEXT,
    image_path            TEXT,
    min_partner_price     REAL    NOT NULL CHECK (min_partner_price >= 0),
    -- Размер упаковки хранится тремя атомарными полями (требование 1НФ)
    package_length        REAL    CHECK (package_length > 0),
    package_width         REAL    CHECK (package_width > 0),
    package_height        REAL    CHECK (package_height > 0),
    weight_net            REAL    CHECK (weight_net > 0),
    weight_gross          REAL    CHECK (weight_gross > 0),
    certificate_path      TEXT,
    standard_number       TEXT,
    production_time_hours REAL    CHECK (production_time_hours > 0),
    cost_price            REAL    CHECK (cost_price >= 0),
    workshop_number       INTEGER CHECK (workshop_number > 0),
    worker_count          INTEGER CHECK (worker_count > 0),
    stock_quantity        INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    CONSTRAINT fk_product_product_type
        FOREIGN KEY (product_type_id) REFERENCES product_type (product_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Необходимые материалы для производства продукции: связь «многие ко многим»
-- с нормой расхода сырья на единицу продукции (п.10)
CREATE TABLE product_material (
    product_id        INTEGER NOT NULL,
    material_id       INTEGER NOT NULL,
    quantity_per_unit REAL    NOT NULL CHECK (quantity_per_unit > 0),
    CONSTRAINT pk_product_material PRIMARY KEY (product_id, material_id),
    CONSTRAINT fk_product_material_product
        FOREIGN KEY (product_id) REFERENCES product (product_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_product_material_material
        FOREIGN KEY (material_id) REFERENCES material (material_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Партия продукции, запущенная в производство: отсюда берутся списания
-- материалов со склада и приход готовой продукции (п.8)
CREATE TABLE production_batch (
    batch_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id  INTEGER NOT NULL,
    master_id   INTEGER,
    quantity    INTEGER NOT NULL CHECK (quantity > 0),
    start_date  TEXT    NOT NULL CHECK (start_date = date(start_date)),
    finish_date TEXT    CHECK (finish_date IS NULL OR finish_date = date(finish_date)),
    CONSTRAINT fk_production_batch_product
        FOREIGN KEY (product_id) REFERENCES product (product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_production_batch_master
        FOREIGN KEY (master_id) REFERENCES employee (employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ===========================================================================
-- Подсистема «Сотрудники» (Приложение 1, п.4–5)
-- ===========================================================================

CREATE TABLE employee (
    employee_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    last_name       TEXT    NOT NULL,
    first_name      TEXT    NOT NULL,
    middle_name     TEXT,
    birth_date      TEXT    NOT NULL CHECK (birth_date = date(birth_date)),
    passport_series TEXT    NOT NULL CHECK (length(passport_series) = 4),
    passport_number TEXT    NOT NULL CHECK (length(passport_number) = 6),
    bank_account    TEXT    NOT NULL CHECK (length(bank_account) = 20),
    -- Наличие семьи и состояние здоровья названы в п.4
    has_family      INTEGER NOT NULL DEFAULT 0 CHECK (has_family IN (0, 1)),
    health_status   TEXT,
    job_position_id INTEGER NOT NULL,
    hire_date       TEXT    NOT NULL CHECK (hire_date = date(hire_date)),
    CONSTRAINT uq_employee_passport UNIQUE (passport_series, passport_number),
    CONSTRAINT fk_employee_job_position
        FOREIGN KEY (job_position_id) REFERENCES job_position (job_position_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ===========================================================================
-- Подсистема «Партнёры» и заявки (Приложение 1, п.1–3)
-- ===========================================================================

CREATE TABLE partner (
    partner_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    organization_type_id INTEGER NOT NULL,
    partner_name         TEXT    NOT NULL UNIQUE,
    legal_address        TEXT    NOT NULL,
    inn                  TEXT    NOT NULL UNIQUE CHECK (length(inn) IN (10, 12)),
    director_name        TEXT    NOT NULL,
    phone                TEXT,
    email                TEXT,
    logo_path            TEXT,
    -- Рейтинг меняет менеджер; текущее значение хранится здесь (п.1–2)
    rating               INTEGER NOT NULL DEFAULT 0 CHECK (rating >= 0),
    CONSTRAINT fk_partner_organization_type
        FOREIGN KEY (organization_type_id) REFERENCES organization_type (organization_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- История реализации продукции партнёром: на её основе считается скидка,
-- которая зависит от общего объёма продаж партнёра (п.1)
CREATE TABLE partner_sale (
    sale_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    partner_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sale_date  TEXT    NOT NULL CHECK (sale_date = date(sale_date)),
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_partner_sale_partner
        FOREIGN KEY (partner_id) REFERENCES partner (partner_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_partner_sale_product
        FOREIGN KEY (product_id) REFERENCES product (product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE request (
    request_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    partner_id        INTEGER NOT NULL,
    manager_id        INTEGER,
    request_status_id INTEGER NOT NULL,
    -- Способ получения — это домен из двух значений, отдельный справочник
    -- для него не нужен, достаточно ограничения CHECK
    delivery_type     TEXT    CHECK (delivery_type IN ('Доставка', 'Самовывоз')),
    created_date      TEXT    NOT NULL CHECK (created_date = date(created_date)),
    -- Если предоплата не поступает в течение трёх дней, заявка отменяется,
    -- поэтому дата предоплаты хранится отдельно от даты полной оплаты
    prepayment_date   TEXT    CHECK (prepayment_date IS NULL OR prepayment_date = date(prepayment_date)),
    payment_date      TEXT    CHECK (payment_date IS NULL OR payment_date = date(payment_date)),
    completion_date   TEXT    CHECK (completion_date IS NULL OR completion_date = date(completion_date)),
    CONSTRAINT fk_request_partner
        FOREIGN KEY (partner_id) REFERENCES partner (partner_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_request_manager
        FOREIGN KEY (manager_id) REFERENCES employee (employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_request_request_status
        FOREIGN KEY (request_status_id) REFERENCES request_status (request_status_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Позиции заявки: менеджер указывает стоимость и дату производства
-- каждой указанной в заявке единицы продукции (п.3)
CREATE TABLE request_item (
    request_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id      INTEGER NOT NULL,
    product_id      INTEGER NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_cost       REAL    NOT NULL CHECK (unit_cost >= 0),
    production_date TEXT    CHECK (production_date IS NULL OR production_date = date(production_date)),
    CONSTRAINT uq_request_item UNIQUE (request_id, product_id),
    CONSTRAINT fk_request_item_request
        FOREIGN KEY (request_id) REFERENCES request (request_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_request_item_product
        FOREIGN KEY (product_id) REFERENCES product (product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ===========================================================================
-- Индексы по внешним ключам
-- ===========================================================================

CREATE INDEX idx_material_material_type    ON material (material_type_id);
CREATE INDEX idx_material_unit             ON material (unit_id);
CREATE INDEX idx_supplier_organization     ON supplier (organization_type_id);
CREATE INDEX idx_material_supplier_sup     ON material_supplier (supplier_id);
CREATE INDEX idx_stock_movement_material   ON stock_movement (material_id);
CREATE INDEX idx_stock_movement_supplier   ON stock_movement (supplier_id);
CREATE INDEX idx_product_product_type      ON product (product_type_id);
CREATE INDEX idx_product_material_material ON product_material (material_id);
CREATE INDEX idx_production_batch_product  ON production_batch (product_id);
CREATE INDEX idx_employee_job_position     ON employee (job_position_id);
CREATE INDEX idx_partner_organization      ON partner (organization_type_id);
CREATE INDEX idx_partner_sale_partner      ON partner_sale (partner_id);
CREATE INDEX idx_partner_sale_product      ON partner_sale (product_id);
CREATE INDEX idx_request_partner           ON request (partner_id);
CREATE INDEX idx_request_status_fk         ON request (request_status_id);
CREATE INDEX idx_request_item_request      ON request_item (request_id);
CREATE INDEX idx_request_item_product      ON request_item (product_id);
