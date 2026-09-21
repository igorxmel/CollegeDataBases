"""Расчёт стоимости минимально необходимой партии материала (модуль № 2).

Расчёты выполняются в Decimal: денежные суммы и объёмы закупки не должны
накапливать погрешность двоичной плавающей точки.
"""

from decimal import Decimal, ROUND_CEILING, ROUND_HALF_UP

MONEY_PRECISION = Decimal("0.01")


def to_decimal(value):
    """Перевести число из базы данных в Decimal без потери точности записи."""
    return Decimal(str(value))


def calculate_purchase_quantity(stock_quantity, min_quantity, package_quantity):
    """Минимальный объём закупки, кратный количеству материала в упаковке.

    Если на складе материала не меньше минимально допустимого количества,
    закупка не требуется и объём равен нулю.
    """
    package_quantity = to_decimal(package_quantity)
    if package_quantity <= 0:
        raise ValueError("Количество материала в упаковке должно быть больше нуля")

    deficit = to_decimal(min_quantity) - to_decimal(stock_quantity)
    if deficit <= 0:
        return Decimal("0")

    packages = (deficit / package_quantity).to_integral_value(rounding=ROUND_CEILING)
    return packages * package_quantity


def calculate_batch_cost(stock_quantity, min_quantity, package_quantity, unit_price):
    """Стоимость минимально необходимой партии материала с точностью до копеек."""
    unit_price = to_decimal(unit_price)
    if unit_price < 0:
        raise ValueError("Цена единицы материала не может быть отрицательной")

    purchase_quantity = calculate_purchase_quantity(
        stock_quantity, min_quantity, package_quantity
    )
    cost = purchase_quantity * unit_price
    return cost.quantize(MONEY_PRECISION, rounding=ROUND_HALF_UP)


def format_money(value):
    """Денежная сумма в виде «1 234,56 р» — два знака после запятой."""
    amount = to_decimal(value).quantize(MONEY_PRECISION, rounding=ROUND_HALF_UP)
    return f"{amount:,.2f}".replace(",", " ").replace(".", ",") + " р"


def format_quantity(value):
    """Количество без лишних нулей: 1000 вместо 1000.0, 2,5 вместо 2.5."""
    amount = to_decimal(value).normalize()
    if amount == amount.to_integral_value():
        return str(int(amount))
    return f"{amount}".replace(".", ",")
