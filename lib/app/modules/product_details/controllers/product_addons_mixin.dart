import 'package:get/get.dart';

import '../models/product_variant_model.dart';

mixin ProductAddonsMixin {
  final addonSelections = <String, dynamic>{}.obs;

  ProductVariantModel? get selectedVariant;
  int get activePriceMinor;

  int get totalAddonPriceMinor {
    int total = 0;
    final currentVariant = selectedVariant;
    if (currentVariant == null) return 0;

    for (final addon in currentVariant.addons) {
      final selection = addonSelections[addon.id];
      if (selection == null) continue;

      if (addon.type == 'checkbox' && selection == true) {
        total += addon.priceMinor;
      } else if ((addon.type == 'dropdown' || addon.type == 'radio') &&
          selection is String &&
          selection.isNotEmpty) {
        final opt =
            addon.options.firstWhereOrNull((o) => o.label == selection);
        if (opt != null) total += opt.priceMinor;
      } else if (addon.type == 'multi_select' && selection is List) {
        for (final label in selection) {
          final opt = addon.options.firstWhereOrNull((o) => o.label == label);
          if (opt != null) total += opt.priceMinor;
        }
      }
    }
    return total;
  }

  double get totalLivePrice {
    final baseMinor = activePriceMinor;
    return (baseMinor + totalAddonPriceMinor) / 100.0;
  }

  List<Map<String, dynamic>> buildAddonsPayload() {
    final List<Map<String, dynamic>> payload = [];
    final currentVariant = selectedVariant;
    if (currentVariant == null) return payload;

    for (final addon in currentVariant.addons) {
      final val = addonSelections[addon.id];
      if (val == null) continue;

      if (addon.type == 'checkbox' && val == true) {
        payload.add({'addonId': addon.id, 'checked': true});
      } else if ((addon.type == 'dropdown' || addon.type == 'radio') &&
          val is String &&
          val.isNotEmpty) {
        payload.add({'addonId': addon.id, 'optionLabel': val});
      } else if (addon.type == 'multi_select' &&
          val is List &&
          val.isNotEmpty) {
        payload.add({
          'addonId': addon.id,
          'optionLabels': List<String>.from(val),
        });
      }
    }
    return payload;
  }

  String buildAddonsSummary() {
    final currentVariant = selectedVariant;
    if (currentVariant == null) return '';

    final parts = <String>[];
    for (final addon in currentVariant.addons) {
      final val = addonSelections[addon.id];
      if (val == null) continue;

      if (addon.type == 'checkbox' && val == true) {
        final suffix = addon.priceMinor > 0
            ? ' + ৳${(addon.priceMinor / 100.0).toStringAsFixed(addon.priceMinor % 100 == 0 ? 0 : 2)}'
            : '';
        parts.add('${addon.name}$suffix');
      } else if ((addon.type == 'dropdown' || addon.type == 'radio') &&
          val is String &&
          val.isNotEmpty) {
        final opt = addon.options.firstWhereOrNull((o) => o.label == val);
        final optMinor = opt?.priceMinor ?? 0;
        final suffix = optMinor > 0
            ? ' + ৳${(optMinor / 100.0).toStringAsFixed(optMinor % 100 == 0 ? 0 : 2)}'
            : '';
        parts.add('${addon.name}: $val$suffix');
      } else if (addon.type == 'multi_select' && val is List && val.isNotEmpty) {
        int multiTotal = 0;
        for (final label in val) {
          final opt = addon.options.firstWhereOrNull((o) => o.label == label);
          if (opt != null) multiTotal += opt.priceMinor;
        }
        final suffix = multiTotal > 0
            ? ' + ৳${(multiTotal / 100.0).toStringAsFixed(multiTotal % 100 == 0 ? 0 : 2)}'
            : '';
        parts.add('${addon.name}: ${val.join(', ')}$suffix');
      }
    }
    return parts.join(' • ');
  }

  void resetAddons() {
    addonSelections.clear();
  }
}
