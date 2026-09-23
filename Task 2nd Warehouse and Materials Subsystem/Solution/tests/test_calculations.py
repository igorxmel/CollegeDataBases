"""Тесты расчётов: стоимость партии материала и количество продукции из сырья.

Запуск: python -m unittest discover -s tests
"""

from decimal import Decimal
from pathlib import Path
import sys
import unittest

SOLUTION_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SOLUTION_DIR / "app"))

import calculations  # noqa: E402
import config  # noqa: E402
from product_calculation import calculate_product_quantity  # noqa: E402
from repository import MaterialRepository  # noqa: E402


class FakeRepository:
    """Подменяет базу данных в тестах метода расчёта количества продукции."""

    def __init__(self, product_types, material_types):
        self._product_types = product_types
        self._material_types = material_types

    def get_product_type(self, product_type_id):
        coefficient = self._product_types.get(product_type_id)
        return None if coefficient is None else {"type_coefficient": coefficient}

    def get_material_type(self, material_type_id):
        loss_percent = self._material_types.get(material_type_id)
        return None if loss_percent is None else {"loss_percent": loss_percent}


class BatchCostTests(unittest.TestCase):
    def test_no_purchase_when_stock_is_enough(self):
        cost = calculations.calculate_batch_cost(
            stock_quantity=3000, min_quantity=1500, package_quantity=500, unit_price=2.4
        )
        self.assertEqual(cost, Decimal("0.00"))

    def test_purchase_is_rounded_up_to_whole_packages(self):
        # Не хватает 3930 кг, упаковка 30 кг: 131 упаковка ровно закрывает дефицит.
        quantity = calculations.calculate_purchase_quantity(
            stock_quantity=1570, min_quantity=5500, package_quantity=30
        )
        self.assertEqual(quantity, Decimal("3930"))

    def test_partial_package_increases_purchase_volume(self):
        # Не хватает 2470 кг, упаковка 25 кг: 98,8 упаковки округляется до 99.
        quantity = calculations.calculate_purchase_quantity(
            stock_quantity=1030, min_quantity=3500, package_quantity=25
        )
        self.assertEqual(quantity, Decimal("2475"))

    def test_cost_has_two_decimal_places(self):
        cost = calculations.calculate_batch_cost(
            stock_quantity=1570, min_quantity=5500, package_quantity=30, unit_price=15.29
        )
        self.assertEqual(cost, Decimal("60089.70"))
        self.assertEqual(cost.as_tuple().exponent, -2)

    def test_cost_is_never_negative(self):
        cost = calculations.calculate_batch_cost(
            stock_quantity=10000, min_quantity=1000, package_quantity=10, unit_price=100
        )
        self.assertGreaterEqual(cost, Decimal("0.00"))

    def test_negative_price_is_rejected(self):
        with self.assertRaises(ValueError):
            calculations.calculate_batch_cost(
                stock_quantity=0, min_quantity=100, package_quantity=10, unit_price=-1
            )

    def test_money_is_formatted_with_two_decimals(self):
        self.assertEqual(calculations.format_money(Decimal("60089.7")), "60 089,70 р")
        self.assertEqual(calculations.format_money(0), "0,00 р")

    def test_quantity_is_formatted_without_trailing_zeros(self):
        self.assertEqual(calculations.format_quantity(1000.0), "1000")
        self.assertEqual(calculations.format_quantity(2.5), "2,5")


class ProductQuantityTests(unittest.TestCase):
    def setUp(self):
        self.repository = FakeRepository(
            product_types={1: 1.2, 2: 8.59},
            material_types={1: 0.0012, 2: 0.002},
        )

    def test_calculates_whole_number_of_products(self):
        # Сырьё на единицу: 2 × 3 × 1,2 = 7,2; с потерями 0,12 % — 7,20864.
        # 1000 / 7,20864 = 138,72... — получится 138 единиц продукции.
        result = calculate_product_quantity(1, 1, 1000, 2.0, 3.0, self.repository)
        self.assertEqual(result, 138)

    def test_losses_reduce_the_result(self):
        without_losses = calculate_product_quantity(
            1, 1, 1000, 2.0, 3.0, FakeRepository({1: 1.2}, {1: 0.0})
        )
        with_losses = calculate_product_quantity(1, 1, 1000, 2.0, 3.0, self.repository)
        self.assertLessEqual(with_losses, without_losses)

    def test_returns_zero_when_material_is_not_enough(self):
        self.assertEqual(calculate_product_quantity(1, 1, 1, 2.0, 3.0, self.repository), 0)

    def test_unknown_product_type_returns_minus_one(self):
        self.assertEqual(calculate_product_quantity(99, 1, 1000, 2.0, 3.0, self.repository), -1)

    def test_unknown_material_type_returns_minus_one(self):
        self.assertEqual(calculate_product_quantity(1, 99, 1000, 2.0, 3.0, self.repository), -1)

    def test_non_integer_arguments_return_minus_one(self):
        self.assertEqual(calculate_product_quantity(1.5, 1, 1000, 2.0, 3.0, self.repository), -1)
        self.assertEqual(calculate_product_quantity(1, 1, 10.5, 2.0, 3.0, self.repository), -1)
        self.assertEqual(calculate_product_quantity(1, 1, "1000", 2.0, 3.0, self.repository), -1)

    def test_non_positive_parameters_return_minus_one(self):
        self.assertEqual(calculate_product_quantity(1, 1, 1000, 0.0, 3.0, self.repository), -1)
        self.assertEqual(calculate_product_quantity(1, 1, 1000, 2.0, -3.0, self.repository), -1)

    def test_negative_material_quantity_returns_minus_one(self):
        self.assertEqual(calculate_product_quantity(1, 1, -1000, 2.0, 3.0, self.repository), -1)


@unittest.skipUnless(config.DATABASE_PATH.exists(), "база данных не создана")
class DatabaseIntegrationTests(unittest.TestCase):
    """Проверка расчётов на реальных данных заказчика."""

    @classmethod
    def setUpClass(cls):
        cls.repository = MaterialRepository(config.DATABASE_PATH)

    @classmethod
    def tearDownClass(cls):
        cls.repository.close()

    def test_all_materials_are_loaded(self):
        self.assertEqual(len(self.repository.list_materials()), 20)

    def test_every_material_has_suppliers(self):
        for material in self.repository.list_materials():
            suppliers = self.repository.list_suppliers_for_material(material["material_id"])
            self.assertGreater(len(suppliers), 0, material["material_name"])

    def test_batch_cost_is_not_negative_for_every_material(self):
        for material in self.repository.list_materials():
            cost = calculations.calculate_batch_cost(
                material["stock_quantity"],
                material["min_quantity"],
                material["package_quantity"],
                material["unit_price"],
            )
            self.assertGreaterEqual(cost, Decimal("0.00"), material["material_name"])

    def test_method_works_with_real_reference_data(self):
        result = calculate_product_quantity(1, 1, 1000, 2.0, 3.0, self.repository)
        self.assertGreaterEqual(result, 0)


if __name__ == "__main__":
    unittest.main()
