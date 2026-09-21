-- ---------------------------------------------------------------------------
-- Производственная компания «Мозаика»
-- Подсистема «Склад и материалы»: схема базы данных (СУБД SQLite)
--
-- Схема приведена к третьей нормальной форме:
--   * каждый атрибут атомарен (1НФ);
--   * все неключевые атрибуты зависят от полного первичного ключа (2НФ);
--   * транзитивные зависимости вынесены в справочники unit, material_type,
--     supplier_type, product_type (3НФ).
-- Ссылочная целостность обеспечена внешними ключами; в SQLite их проверку
-- включает PRAGMA foreign_keys.
-- ---------------------------------------------------------------------------

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS material_supplier;
DROP TABLE IF EXISTS material;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS supplier_type;
DROP TABLE IF EXISTS product_type;
DROP TABLE IF EXISTS material_type;
DROP TABLE IF EXISTS unit;

-- Справочник единиц измерения (кг, л, ...)
CREATE TABLE unit (
    unit_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    unit_name TEXT    NOT NULL UNIQUE
);

-- Справочник типов материалов с процентом потери сырья при производстве
CREATE TABLE material_type (
    material_type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    material_type_name TEXT    NOT NULL UNIQUE,
    loss_percent       REAL    NOT NULL CHECK (loss_percent >= 0)
);

-- Справочник типов продукции с коэффициентом типа продукции
CREATE TABLE product_type (
    product_type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    product_type_name TEXT    NOT NULL UNIQUE,
    type_coefficient  REAL    NOT NULL CHECK (type_coefficient > 0)
);

-- Справочник организационно-правовых форм поставщиков (ООО, ЗАО, ОАО, ПАО)
CREATE TABLE supplier_type (
    supplier_type_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_type_name TEXT    NOT NULL UNIQUE
);

-- Поставщики материалов
CREATE TABLE supplier (
    supplier_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_name    TEXT    NOT NULL UNIQUE,
    supplier_type_id INTEGER NOT NULL,
    inn              TEXT    NOT NULL UNIQUE
                             CHECK (length(inn) IN (10, 12)),
    rating           INTEGER NOT NULL CHECK (rating >= 0),
    -- Дата в формате ISO-8601; CHECK не пропустит значение со временем
    work_start_date  TEXT    NOT NULL CHECK (work_start_date = date(work_start_date)),
    CONSTRAINT fk_supplier_supplier_type
        FOREIGN KEY (supplier_type_id) REFERENCES supplier_type (supplier_type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Материалы (сырьё), используемые для производства продукции
CREATE TABLE material (
    material_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    material_name    TEXT    NOT NULL UNIQUE,
    material_type_id INTEGER NOT NULL,
    unit_id          INTEGER NOT NULL,
    unit_price       REAL    NOT NULL CHECK (unit_price >= 0),
    stock_quantity   REAL    NOT NULL CHECK (stock_quantity >= 0),
    min_quantity     REAL    NOT NULL CHECK (min_quantity >= 0),
    package_quantity REAL    NOT NULL CHECK (package_quantity > 0),
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

CREATE INDEX idx_material_material_type ON material (material_type_id);
CREATE INDEX idx_material_unit          ON material (unit_id);
CREATE INDEX idx_supplier_type          ON supplier (supplier_type_id);
CREATE INDEX idx_material_supplier_sup  ON material_supplier (supplier_id);
