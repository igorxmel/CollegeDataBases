"""Доступ к базе данных «Мозаика».

Весь SQL сосредоточен в этом модуле: формы интерфейса работают только с
методами репозитория и не знают о структуре таблиц.
"""

import sqlite3


class DuplicateMaterialError(Exception):
    """Материал с таким наименованием уже есть в базе данных."""


class MaterialRepository:
    def __init__(self, database_path):
        self._connection = sqlite3.connect(database_path)
        self._connection.row_factory = sqlite3.Row
        # Без этой директивы SQLite не проверяет внешние ключи.
        self._connection.execute("PRAGMA foreign_keys = ON")

    def close(self):
        self._connection.close()

    def __enter__(self):
        return self

    def __exit__(self, exception_type, exception_value, traceback):
        self.close()

    # ---------------------------------------------------------------- материалы

    def list_materials(self):
        """Все материалы вместе с типом и единицей измерения, по наименованию."""
        return self._connection.execute(
            """
            SELECT m.material_id,
                   m.material_name,
                   m.unit_price,
                   m.stock_quantity,
                   m.min_quantity,
                   m.package_quantity,
                   mt.material_type_id,
                   mt.material_type_name,
                   u.unit_id,
                   u.unit_name
            FROM material AS m
                 JOIN material_type AS mt ON mt.material_type_id = m.material_type_id
                 JOIN unit AS u ON u.unit_id = m.unit_id
            ORDER BY m.material_name
            """
        ).fetchall()

    def get_material(self, material_id):
        return self._connection.execute(
            """
            SELECT m.material_id,
                   m.material_name,
                   m.unit_price,
                   m.stock_quantity,
                   m.min_quantity,
                   m.package_quantity,
                   mt.material_type_id,
                   mt.material_type_name,
                   u.unit_id,
                   u.unit_name
            FROM material AS m
                 JOIN material_type AS mt ON mt.material_type_id = m.material_type_id
                 JOIN unit AS u ON u.unit_id = m.unit_id
            WHERE m.material_id = ?
            """,
            (material_id,),
        ).fetchone()

    def add_material(self, values):
        unit_id = self._get_or_create_unit(values["unit_name"])
        try:
            cursor = self._connection.execute(
                """
                INSERT INTO material (
                    material_name, material_type_id, unit_id,
                    unit_price, stock_quantity, min_quantity, package_quantity
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    values["material_name"],
                    values["material_type_id"],
                    unit_id,
                    values["unit_price"],
                    values["stock_quantity"],
                    values["min_quantity"],
                    values["package_quantity"],
                ),
            )
        except sqlite3.IntegrityError as error:
            self._connection.rollback()
            raise DuplicateMaterialError(values["material_name"]) from error
        self._connection.commit()
        return cursor.lastrowid

    def update_material(self, material_id, values):
        unit_id = self._get_or_create_unit(values["unit_name"])
        try:
            self._connection.execute(
                """
                UPDATE material
                SET material_name    = ?,
                    material_type_id = ?,
                    unit_id          = ?,
                    unit_price       = ?,
                    stock_quantity   = ?,
                    min_quantity     = ?,
                    package_quantity = ?
                WHERE material_id = ?
                """,
                (
                    values["material_name"],
                    values["material_type_id"],
                    unit_id,
                    values["unit_price"],
                    values["stock_quantity"],
                    values["min_quantity"],
                    values["package_quantity"],
                    material_id,
                ),
            )
        except sqlite3.IntegrityError as error:
            self._connection.rollback()
            raise DuplicateMaterialError(values["material_name"]) from error
        self._connection.commit()

    # -------------------------------------------------------------- справочники

    def list_material_types(self):
        return self._connection.execute(
            "SELECT material_type_id, material_type_name, loss_percent "
            "FROM material_type ORDER BY material_type_name"
        ).fetchall()

    def get_material_type(self, material_type_id):
        return self._connection.execute(
            "SELECT material_type_id, material_type_name, loss_percent "
            "FROM material_type WHERE material_type_id = ?",
            (material_type_id,),
        ).fetchone()

    def get_product_type(self, product_type_id):
        return self._connection.execute(
            "SELECT product_type_id, product_type_name, type_coefficient "
            "FROM product_type WHERE product_type_id = ?",
            (product_type_id,),
        ).fetchone()

    def list_units(self):
        return [row["unit_name"] for row in self._connection.execute(
            "SELECT unit_name FROM unit ORDER BY unit_name"
        )]

    def _get_or_create_unit(self, unit_name):
        """Вернуть идентификатор единицы измерения, добавив её при необходимости."""
        row = self._connection.execute(
            "SELECT unit_id FROM unit WHERE unit_name = ?", (unit_name,)
        ).fetchone()
        if row is not None:
            return row["unit_id"]
        cursor = self._connection.execute(
            "INSERT INTO unit (unit_name) VALUES (?)", (unit_name,)
        )
        return cursor.lastrowid

    # -------------------------------------------------------------- поставщики

    def list_suppliers_for_material(self, material_id):
        """Поставщики конкретного материала, от большего рейтинга к меньшему."""
        return self._connection.execute(
            """
            SELECT s.supplier_id,
                   s.supplier_name,
                   s.rating,
                   s.work_start_date,
                   s.inn,
                   ot.organization_type_name
            FROM material_supplier AS ms
                 JOIN supplier AS s ON s.supplier_id = ms.supplier_id
                 JOIN organization_type AS ot
                      ON ot.organization_type_id = s.organization_type_id
            WHERE ms.material_id = ?
            ORDER BY s.rating DESC, s.supplier_name
            """,
            (material_id,),
        ).fetchall()
