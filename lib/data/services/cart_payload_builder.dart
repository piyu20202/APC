import '../models/product_detail_response.dart';
import '../models/product_details_model.dart';
import '../../services/storage_service.dart';

/// Helper utility to translate the current kit configuration into
/// the payload expected by the cart API.
class CartPayloadBuilder {
  CartPayloadBuilder({
    required this.product,
    required this.qtyUpgradeProducts,
    required this.upgradeProducts,
    required this.addonProducts,
    required this.kitQuantity,
    required this.selectedQtyForCustomise,
    required this.selectedUpgradeIndex,
    required this.selectedSubProductIndex,
    required this.addOnSelections,
    required this.addOnQuantities,
  });

  final ProductDetailsModel product;
  final List<QtyUpgradeProduct> qtyUpgradeProducts;
  final List<UpgradeProduct> upgradeProducts;
  final List<AddonProduct> addonProducts;
  final int kitQuantity;
  final Map<int, int> selectedQtyForCustomise;
  final int selectedUpgradeIndex;
  final Map<int, int> selectedSubProductIndex;
  final List<bool> addOnSelections;
  final List<int> addOnQuantities;

  List<Map<String, dynamic>> getCustomiseKitData() {
    return qtyUpgradeProducts.map((item) {
      final selectedQty =
          selectedQtyForCustomise[item.id] ?? item.productBaseQuantity;
      final extraCost = _calculateExtraCost(item, selectedQty);
      final totalPrice = item.price + extraCost;

      return {'id': item.id, 'qty': selectedQty, 'price': totalPrice};
    }).toList();
  }

  Map<String, dynamic>? getSelectedUpgradeData() {
    if (selectedUpgradeIndex < 0 ||
        selectedUpgradeIndex >= upgradeProducts.length) {
      return null;
    }

    final upgradeProduct = upgradeProducts[selectedUpgradeIndex];
    final selectedSubIndex = selectedSubProductIndex[upgradeProduct.id] ?? -1;

    if (selectedSubIndex >= 0 &&
        selectedSubIndex < upgradeProduct.subProducts.length) {
      final subProduct = upgradeProduct.subProducts[selectedSubIndex];
      return {
        'id': subProduct.id,
        'qty': subProduct.productBaseQuantity,
        'price': subProduct.price,
        'isUpgrade': true,
      };
    }

    return {
      'id': upgradeProduct.id,
      'qty': upgradeProduct.productBaseQuantity,
      'price': upgradeProduct.price,
      'isUpgrade': false,
    };
  }

  List<Map<String, dynamic>> getSelectedAddOnData() {
    final List<Map<String, dynamic>> selectedAddOns = [];

    for (int i = 0; i < addonProducts.length; i++) {
      if (i < addOnSelections.length && addOnSelections[i]) {
        final item = addonProducts[i];
        final qty = i < addOnQuantities.length ? addOnQuantities[i] : 1;

        selectedAddOns.add({
          'id': item.id,
          'qty': qty,
          'price': item.unitPrice,
        });
      }
    }

    return selectedAddOns;
  }

  double calculateCustomiseKitTotal() {
    double total = 0.0;
    for (final item in qtyUpgradeProducts) {
      final selectedQty =
          selectedQtyForCustomise[item.id] ?? item.productBaseQuantity;
      final extraCost = _calculateExtraCost(item, selectedQty);
      total += extraCost;
    }
    return total;
  }

  double calculateUpgradePrice() {
    final upgradeData = getSelectedUpgradeData();
    if (upgradeData == null) {
      return 0.0;
    }
    final isUpgrade = (upgradeData['isUpgrade'] as bool?) ?? false;
    if (!isUpgrade) {
      return 0.0;
    }

    return (upgradeData['price'] as num?)?.toDouble() ?? 0.0;
  }

  double calculateAddOnTotal() {
    double total = 0.0;
    for (int i = 0; i < addonProducts.length; i++) {
      if (i < addOnSelections.length && addOnSelections[i]) {
        final item = addonProducts[i];
        final qty = i < addOnQuantities.length ? addOnQuantities[i] : 1;
        total += qty * item.unitPrice;
      }
    }
    return total;
  }

  double calculateFinalPrice() {
    final kitPrice = product.price.toDouble();
    final basicKitPrice = kitPrice * kitQuantity;
    final customiseTotal = calculateCustomiseKitTotal();
    final upgradePrice = calculateUpgradePrice();
    final addOnTotal = calculateAddOnTotal();
    return basicKitPrice + customiseTotal + upgradePrice + addOnTotal;
  }

  Future<Map<String, dynamic>> buildPayload() async {
    final customiseData = getCustomiseKitData();
    final customItemsIds = customiseData
        .map((item) => item['id'])
        .toList(growable: false);
    final customItemsQty = customiseData
        .map((item) => item['qty'])
        .toList(growable: false);

    final upgradeData = getSelectedUpgradeData();
    final List<int> upgradeItemsId = [];
    final List<String> upgradeItemsType = [];
    if (upgradeData != null) {
      upgradeItemsId.add(upgradeData['id'] as int);
      upgradeItemsType.add(
        (upgradeData['isUpgrade'] as bool?) == true ? 'upgrade' : 'base',
      );
    }

    final addOnData = getSelectedAddOnData();
    final addonItemsIds = addOnData
        .map((item) => item['id'])
        .toList(growable: false);
    final addonItemsQty = addOnData
        .map((item) => item['qty'])
        .toList(growable: false);

    final addonPrice = calculateAddOnTotal();
    final finalPrice = calculateFinalPrice();

    final storedCartResponse = await StorageService.getCartData();
    dynamic oldCartPayload = '';
    if (storedCartResponse != null) {
      final cartEntries = storedCartResponse['cart'];
      if (cartEntries is Map<String, dynamic>) {
        oldCartPayload = cartEntries;
      }
    }

    final kitPrice = product.price.toDouble();

    return {
      'id': product.id,
      'qty': kitQuantity,
      'price': kitPrice,
      'isKit': product.isKIT ?? '',
      'unit_price': kitPrice.toStringAsFixed(2),
      'final_price': finalPrice.toStringAsFixed(2),
      'addon_price': addonPrice.toStringAsFixed(2),
      'custom_items_id': customItemsIds,
      'custom_items_qty': customItemsQty,
      'upgrade_items_id': upgradeItemsId,
      'upgrade_items_type': upgradeItemsType,
      'upgrade_items_price': '',
      'addon_items_id': addonItemsIds,
      'addon_items_qty': addonItemsQty,
      'addon_items_price': '',
      'old_cart': oldCartPayload,
    };
  }

  double _calculateExtraCost(QtyUpgradeProduct item, int quantity) {
    final baseQuantity = item.productBaseQuantity;
    final additionalUnits = (quantity - baseQuantity).clamp(0, quantity);
    return additionalUnits * item.extraUnitPrice;
  }
}
