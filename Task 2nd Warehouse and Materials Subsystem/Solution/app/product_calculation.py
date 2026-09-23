"""Метод расчёта количества продукции из заданного количества сырья (модуль № 4).

Метод вынесен в отдельный модуль: по условию задания его исходный код
загружается в отдельный репозиторий системы контроля версий.

Правило расчёта:
    сырьё на единицу продукции = параметр 1 × параметр 2 × коэффициент типа продукции;
    это значение увеличивается на процент потери сырья, зависящий от типа материала;
    результат — целое количество продукции, которое получится из имеющегося сырья.

При недопустимых входных данных метод возвращает -1.
"""

import math

INVALID_RESULT = -1


def _is_valid_identifier(value):
    """Идентификатор — целое положительное число (логический тип не подходит)."""
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def _is_valid_material_quantity(value):
    """Количество сырья — целое неотрицательное число."""
    return isinstance(value, int) and not isinstance(value, bool) and value >= 0


def _is_valid_parameter(value):
    """Параметр продукции — положительное вещественное число."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return False
    return math.isfinite(value) and value > 0


def calculate_product_quantity(
    product_type_id,
    material_type_id,
    material_quantity,
    first_parameter,
    second_parameter,
    repository,
):
    """Вернуть целое количество продукции либо -1 при неподходящих данных.

    :param product_type_id: идентификатор типа продукции, целое число
    :param material_type_id: идентификатор типа материала, целое число
    :param material_quantity: количество используемого сырья, целое число
    :param first_parameter: первый параметр продукции, вещественное число > 0
    :param second_parameter: второй параметр продукции, вещественное число > 0
    :param repository: источник справочников типов продукции и материалов
    """
    if not _is_valid_identifier(product_type_id):
        return INVALID_RESULT
    if not _is_valid_identifier(material_type_id):
        return INVALID_RESULT
    if not _is_valid_material_quantity(material_quantity):
        return INVALID_RESULT
    if not _is_valid_parameter(first_parameter) or not _is_valid_parameter(second_parameter):
        return INVALID_RESULT

    product_type = repository.get_product_type(product_type_id)
    material_type = repository.get_material_type(material_type_id)
    if product_type is None or material_type is None:
        return INVALID_RESULT

    type_coefficient = float(product_type["type_coefficient"])
    loss_percent = float(material_type["loss_percent"])
    if type_coefficient <= 0 or loss_percent < 0:
        return INVALID_RESULT

    material_per_product = first_parameter * second_parameter * type_coefficient
    material_per_product_with_loss = material_per_product * (1 + loss_percent)
    if material_per_product_with_loss <= 0:
        return INVALID_RESULT

    return math.floor(material_quantity / material_per_product_with_loss)
