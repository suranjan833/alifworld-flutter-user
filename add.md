# Alif World — Product Variant Add-ons Specification

> **ডকুমেন্ট উদ্দেশ্য:** ব্যবহারকারীর প্রদত্ত স্ক্রিনশট (`Power Strip - Multi Plug Extension Board` পণ্যের Add-ons সেকশন) বিশ্লেষণ করে **Per-Variant Add-ons (অতিরিক্ত সেবা বা অনুষঙ্গ)** সিস্টেম কীভাবে কাজ করে, এর ব্যাকএন্ড আর্কিটেকচার এবং **Alif User Mobile App (`alifuser`)**-এ কীভাবে এটি সম্পূর্ণ কানেক্ট ও ইন্টিগ্রেট করতে হবে তার বিস্তারিত টেকনিক্যাল স্পেসিফিকেশন ও Use Cases।

---

## ১. স্ক্রিনশটদ্বয়ের ভিজ্যুয়াল অ্যানাটমি (Visual Anatomy Breakdown)

প্রদত্ত স্ক্রিনশটে প্রোডাক্ট ডিটেইলস পেজে প্রোডাক্টের দাম (৳ ১,১৯৯.০০) ও স্টকের ঠিক নিচে **Add-ons** সেকশনটি দেখানো হয়েছে:

```
+-----------------------------------------------------------------------------------+
|  [ PRODUCT DETAILS ]                                                              |
|  Power Strip - Multi Plug Extension Board                                         |
|  ★ 5.0 (2)  •  🪙 100.00 points                                                  |
|  ৳ 1,199.00                                                                      |
|  In stock · 94 available                                                          |
+-----------------------------------------------------------------------------------+
|  Add-ons                                                                          |
|                                                                                   |
|  1. DROPDOWN (Installation)                                                       |
|  Installation                                                                     |
|  ┌─────────────────────────────────────────────────────────────────────────────┐  |
|  │ None                                                                      ▼ │  |
|  └─────────────────────────────────────────────────────────────────────────────┘  |
|                                                                                   |
|  2. CHECKBOX (Flat Fee Add-on)                                                    |
|  [ ] Warrenty — ৳ 500.00                                                          |
|                                                                                   |
|  3. RADIO GROUP (Single Selection with "None")                                    |
|  ┌─ Waterproof ────────────────────────────────────────────────────────────────┐  |
|  │ (•) None                                                                    │  |
|  │ ( ) IP64 — ৳ 500.00                                                         │  |
|  │ ( ) IP69 — ৳ 1,000.00                                                       │  |
|  └─────────────────────────────────────────────────────────────────────────────┘  |
|                                                                                   |
|  4. MULTI-SELECT CHECKBOXES (Multiple Selection)                                  |
|  ┌─ Extra Screws ──────────────────────────────────────────────────────────────┐  |
|  │ [ ] 5 Pcs — ৳ 500.00                                                        │  |
|  │ [ ] 10 Pcs — ৳ 1,000.00                                                      │  |
|  │ [ ] 15 Pcs — ৳ 1,500.00                                                      │  |
|  └─────────────────────────────────────────────────────────────────────────────┘  |
+-----------------------------------------------------------------------------------+
|  Quantity: [-] 1 [+]                                                              |
|  [ ADD TO CART BUTTON (Updated Total Price = Base Price + Selected Add-ons) ]     |
+-----------------------------------------------------------------------------------+
```

---

## ২. Add-ons সিস্টেমের কোর বিজনেস রুলস (Core Business Rules)

1. **৪টি ইনপুট টাইপ (4 Input Types):**
   - **`dropdown`**: ড্রপডাউন সিলেক্টর (ডিফল্ট: `"None"` + অতিরিক্ত চার্জসহ অপশনসমূহ)।
   - **`checkbox`**: সিঙ্গেল অন/অফ টগল (সিঙ্গেল ফ্ল্যাট চার্জ, যেমন: ওয়ারেন্টি ৳ ৫০০)।
   - **`radio`**: একাধিক অপশনের মধ্যে যেকোনো একটি পছন্দ করা (ডিফল্ট: `"None"` রেডিও বাটন থাকে)।
   - **`multi_select`**: একাধিক অপশন একসাথে টিক দেওয়ার সুবিধা (প্রতিটি অপশনের নিজস্ব দাম থাকে)।
2. **ভ্যারিয়েন্ট-ভিত্তিক (Per-Variant Scoped):**
   - প্রতিটি Add-on নির্দিষ্ট একটি ভ্যারিয়েন্টের সাথে যুক্ত থাকে। ইউজার যখন প্রোডাক্টের ভ্যারিয়েন্ট পরিবর্তন করে, তখন Add-on সিলেকশন রিসেট হয়ে নতুন ভ্যারিয়েন্টের Add-on লিস্ট লোড হয়।
3. **প্রতি ইউনিটে মূল্য হিসাব (Priced Per Unit):**
   - Add-on চার্জ প্রতি ইউনিটে যোগ হয়। অর্থাৎ যদি কাস্টমার ২টি কোয়ান্টিটি কিনে, তবে Add-on চার্জও ২ দিয়ে গুণ হবে:  
     $$\text{Line Total} = \text{Quantity} \times (\text{Variant Base Price} + \sum \text{Selected Add-on Charges})$$
4. **কোনো পয়েন্ট যোগ হয় না (No Points on Add-ons):**
   - Add-on বাবদ যে অতিরিক্ত টাকা যোগ হয়, তাতে কোনো রিওয়ার্ড পয়েন্ট বা পয়েন্ট ডিসকাউন্ট গণনা হয় না। পয়েন্ট শুধুমাত্র ভ্যারিয়েন্টের মূল দামের ওপর থাকে।
5. **v1-এ সব Add-on ঐচ্ছিক (Optional Only):**
   - কোনো Add-on বাধ্যতামূলক নয়। কাস্টমার চাইলে কোনো Add-on না নিয়েই শুধু মূল প্রোডাক্ট কিনতে পারেন।
6. **কার্ট মার্জিং ও হ্যাশ কি (`addonsKey`):**
   - একই ভ্যারিয়েন্ট একই Add-on সিলেকশনসহ আবার কার্টে যোগ করলে তা একটি লাইনে মার্জ হয়ে কোয়ান্টিটি বাড়ে।
   - কিন্তু যদি ভিন্ন Add-on পছন্দ করা হয় (যেমন: একজন ওয়ারেন্টি ছাড়া নিল, আরেকবার ওয়ারেন্টিসহ নিল), তবে কার্টে এগুলো **দুটি আলাদা আইটেম** হিসেবে জমা হয়।

---

## ৩. ব্যাকএন্ড এপিআই স্পেসিফিকেশন (Backend API Specs)

### ৩.১ প্রোডাক্ট ডিটেইলস এপিআই (`GET /api/v1/catalog/products/:slug`)
প্রতিটি ভ্যারিয়েন্টের ভেতরে `addons` অ্যারে রিটার্ন করে:
```json
{
  "product": {
    "name": "Power Strip - Multi Plug Extension Board",
    "variants": [
      {
        "id": "var_123",
        "sku": "PS-5S-BLK",
        "priceMinor": 119900,
        "addons": [
          {
            "id": "add_01",
            "name": "Installation",
            "type": "dropdown",
            "priceMinor": 0,
            "options": [
              { "label": "Basic Setup", "priceMinor": 30000 },
              { "label": "Full Wall Mount", "priceMinor": 50000 }
            ],
            "required": false,
            "sortOrder": 0
          },
          {
            "id": "add_02",
            "name": "Warrenty",
            "type": "checkbox",
            "priceMinor": 50000,
            "options": [],
            "required": false,
            "sortOrder": 1
          },
          {
            "id": "add_03",
            "name": "Waterproof",
            "type": "radio",
            "priceMinor": 0,
            "options": [
              { "label": "IP64", "priceMinor": 50000 },
              { "label": "IP69", "priceMinor": 100000 }
            ],
            "required": false,
            "sortOrder": 2
          },
          {
            "id": "add_04",
            "name": "Extra Screws",
            "type": "multi_select",
            "priceMinor": 0,
            "options": [
              { "label": "5 Pcs", "priceMinor": 50000 },
              { "label": "10 Pcs", "priceMinor": 100000 },
              { "label": "15 Pcs", "priceMinor": 150000 }
            ],
            "required": false,
            "sortOrder": 3
          }
        ]
      }
    ]
  }
}
```

---

### ৩.২ কার্ট এপিআই (`POST /api/v1/cart`)
কার্টে যোগ করার সময় কাস্টমারের নির্বাচিত Add-ons পাঠাতে হবে:
```json
{
  "variantId": "var_123",
  "qty": 1,
  "addons": [
    {
      "addonId": "add_01",
      "optionLabel": "Full Wall Mount"
    },
    {
      "addonId": "add_02",
      "checked": true
    },
    {
      "addonId": "add_03",
      "optionLabel": "IP64"
    },
    {
      "addonId": "add_04",
      "optionLabels": ["5 Pcs", "10 Pcs"]
    }
  ]
}
```
> **নিরাপত্তা নোট:** ক্লায়েন্ট থেকে পাঠানো দাম সার্ভার কখনোই বিশ্বাস করে না। সার্ভার ডাটাবেসের `VariantAddon` টেবিল থেকে লাইভ দাম পুনরায় গণনা করে কার্টে যুক্ত করে।

---

## ৪. ইউজার অ্যাপে (`alifuser`) কানেক্ট করার পূর্ণাঙ্গ গাইড

ইউজার অ্যাপে বর্তমানে Add-ons সম্পূর্ণ অনুপস্থিত। এটিকে অ্যাপে কানেক্ট করতে নিচের ৪টি ধাপে কোড যোগ করতে হবে:

### ধাপ ১: ডার্ট মডেল তৈরি (`variant_addon_model.dart`)
`lib/app/modules/product_details/models/` ফোল্ডারে নতুন মডেল:
```dart
class VariantAddonModel {
  final String id;
  final String name;
  final String type; // dropdown | checkbox | radio | multi_select
  final int priceMinor;
  final List<VariantAddonOptionModel> options;
  final bool required;
  final int sortOrder;

  VariantAddonModel({
    required this.id,
    required this.name,
    required this.type,
    this.priceMinor = 0,
    this.options = const [],
    this.required = false,
    this.sortOrder = 0,
  });

  double get priceMajor => priceMinor / 100.0;

  factory VariantAddonModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'];
    List<VariantAddonOptionModel> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions
          .whereType<Map<String, dynamic>>()
          .map((e) => VariantAddonOptionModel.fromJson(e))
          .toList();
    }

    return VariantAddonModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'checkbox',
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
      options: parsedOptions,
      required: json['required'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class VariantAddonOptionModel {
  final String label;
  final int priceMinor;

  VariantAddonOptionModel({required this.label, required this.priceMinor});

  double get priceMajor => priceMinor / 100.0;

  factory VariantAddonOptionModel.fromJson(Map<String, dynamic> json) {
    return VariantAddonOptionModel(
      label: json['label']?.toString() ?? '',
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
    );
  }
}
```

---

### ধাপ ২: প্রোডাক্ট ভ্যারিয়েন্ট মডেলে Addons অন্তর্ভুক্ত করা
`product_variant_model.dart`-এ:
```dart
final List<VariantAddonModel> addons;

// Constructor-এ:
this.addons = const [],

// fromJson-এ:
List<VariantAddonModel> parsedAddons = [];
if (json['addons'] is List) {
  parsedAddons = (json['addons'] as List)
      .whereType<Map<String, dynamic>>()
      .map((e) => VariantAddonModel.fromJson(e))
      .toList();
}
```

---

### ধাপ ৩: কন্ট্রোলারে সিলেকশন স্টেট ও ডাইনামিক প্রাইস ক্যালকুলেশন
`product_details_controller.dart`-এ:
```dart
// নির্বাচিত Add-ons এর স্টেট
final addonSelections = <String, dynamic>{}.obs;

// ভ্যারিয়েন্ট পরিবর্তনের সাথে সাথে সিলেকশন রিসেট
void onVariantChanged(int index) {
  selectedVariantIndex.value = index;
  addonSelections.clear();
}

// Add-ons থেকে আসা মোট অতিরিক্ত চার্জ (in Minor / Paisa)
int get totalAddonPriceMinor {
  int total = 0;
  final currentVariant = selectedVariant;
  if (currentVariant == null) return 0;

  for (var addon in currentVariant.addons) {
    final selection = addonSelections[addon.id];
    if (selection == null) continue;

    if (addon.type == 'checkbox' && selection == true) {
      total += addon.priceMinor;
    } else if ((addon.type == 'dropdown' || addon.type == 'radio') && selection is String) {
      final opt = addon.options.firstWhereOrNull((o) => o.label == selection);
      if (opt != null) total += opt.priceMinor;
    } else if (addon.type == 'multi_select' && selection is List) {
      for (var label in selection) {
        final opt = addon.options.firstWhereOrNull((o) => o.label == label);
        if (opt != null) total += opt.priceMinor;
      }
    }
  }
  return total;
}

// ইউআই-তে লাইভ প্রাইস আপডেট (Base Price + Addons)
double get totalLivePrice {
  final base = activePrice; // ভ্যারিয়েন্টের মূল বা অফার মূল্য
  return base + (totalAddonPriceMinor / 100.0);
}

// Add to Cart পেলোড তৈরি
List<Map<String, dynamic>> buildAddonsPayload() {
  final List<Map<String, dynamic>> payload = [];
  final currentVariant = selectedVariant;
  if (currentVariant == null) return payload;

  for (var addon in currentVariant.addons) {
    final val = addonSelections[addon.id];
    if (val == null) continue;

    if (addon.type == 'checkbox' && val == true) {
      payload.add({'addonId': addon.id, 'checked': true});
    } else if ((addon.type == 'dropdown' || addon.type == 'radio') && val is String && val.isNotEmpty) {
      payload.add({'addonId': addon.id, 'optionLabel': val});
    } else if (addon.type == 'multi_select' && val is List && val.isNotEmpty) {
      payload.add({'addonId': addon.id, 'optionLabels': List<String>.from(val)});
    }
  }
  return payload;
}
```

---

### ধাপ ৪: ফ্লাটার ইউআই উইজেট (`_buildAddonSelectors()`)
`product_details_view.dart`-এ ডেসক্রিপশনের উপরে বসানোর উপযোগী উইজেট:
```dart
Widget _buildAddonSelectors() {
  return Obx(() {
    final variant = controller.selectedVariant;
    if (variant == null || variant.addons.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      margin: EdgeInsets.only(top: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add-ons',
            style: GoogleFonts.lato(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),

          ...variant.addons.map((addon) {
            final currentVal = controller.addonSelections[addon.id];

            // 1. Dropdown
            if (addon.type == 'dropdown') {
              return Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addon.name, style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: currentVal as String?,
                          hint: const Text('None'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None')),
                            ...addon.options.map((o) => DropdownMenuItem(
                              value: o.label,
                              child: Text('${o.label} — ৳${o.priceMajor.toStringAsFixed(0)}'),
                            )),
                          ],
                          onChanged: (val) {
                            if (val == null) controller.addonSelections.remove(addon.id);
                            else controller.addonSelections[addon.id] = val;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 2. Checkbox
            if (addon.type == 'checkbox') {
              final isChecked = currentVal == true;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    '${addon.name} — ৳${addon.priceMajor.toStringAsFixed(0)}',
                    style: GoogleFonts.lato(fontSize: 13.5.sp),
                  ),
                  value: isChecked,
                  activeColor: AppColor.primary,
                  onChanged: (val) {
                    if (val == true) controller.addonSelections[addon.id] = true;
                    else controller.addonSelections.remove(addon.id);
                  },
                ),
              );
            }

            // 3. Radio Group
            if (addon.type == 'radio') {
              final selectedOpt = currentVal as String?;
              return Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addon.name, style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    RadioListTile<String?>(
                      title: const Text('None'),
                      value: null,
                      groupValue: selectedOpt,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColor.primary,
                      onChanged: (val) => controller.addonSelections.remove(addon.id),
                    ),
                    ...addon.options.map((o) => RadioListTile<String?>(
                      title: Text('${o.label} — ৳${o.priceMajor.toStringAsFixed(0)}'),
                      value: o.label,
                      groupValue: selectedOpt,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColor.primary,
                      onChanged: (val) => controller.addonSelections[addon.id] = val,
                    )),
                  ],
                ),
              );
            }

            // 4. Multi-Select Checkboxes
            if (addon.type == 'multi_select') {
              final chosen = (currentVal is List) ? List<String>.from(currentVal) : <String>[];
              return Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addon.name, style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                    ...addon.options.map((o) {
                      final isSelected = chosen.contains(o.label);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text('${o.label} — ৳${o.priceMajor.toStringAsFixed(0)}'),
                        value: isSelected,
                        activeColor: AppColor.primary,
                        onChanged: (val) {
                          if (val == true) chosen.add(o.label);
                          else chosen.remove(o.label);

                          if (chosen.isEmpty) controller.addonSelections.remove(addon.id);
                          else controller.addonSelections[addon.id] = List<String>.from(chosen);
                        },
                      );
                    }),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  });
}
```

---

## ৫. এন্ড-টু-এন্ড ফ্লো: কার্ট থেকে চেকআউট পর্যন্ত ইন্টিগ্রেশন (Cart → Checkout → Order)

Add-ons শুধুমাত্র প্রোডাক্ট পেজে সিলেক্ট করলেই হবে না — **Add to Cart / Buy Now → Bag (Cart) → Checkout Page → Order Placement** পর্যন্ত পুরো চেইনে এটি সঠিকভাবে প্রবাহিত হতে হবে:

```
[1. Product Details] ──(addToBag / buyNow)──▶ [2. Bag / Cart] ──(Proceed)──▶ [3. Checkout Page] ──(Place Order)──▶ [4. Order Created]
 • Select Add-ons                              • Show addonsSummary          • Show addonsSummary                  • DB: OrderItem.addons
 • Live Price Update                           • Send addons to /cart        • Backend Quote / Re-price            • DB: addonsTotalMinor
 • Build addons payload                        • Merge by addonsKey          • Final Total = Base + Addons
```

### ৫.১ প্রোডাক্ট পেজ থেকে কার্টে পাঠানো (`product_details_controller.dart`)
`addToBag()` এবং `buyNow()` উভয় ফাংশনে `itemPayload`-এর মধ্যে `addons`, `addonsPerUnitMinor`, এবং `addonsSummary` পাঠাতে হবে:
```dart
final addonsPayload = buildAddonsPayload();
final addonsSummary = buildAddonsSummary(); // যেমন: "Installation: Full Wall Mount • Warrenty"
final unitWithAddonsMinor = (selectedVariant?.effectivePriceMinor ?? 0) + totalAddonPriceMinor;

final itemPayload = {
  'productId': product.value!.id,
  'variantId': selectedVariant?.id,
  'title': product.value!.name,
  'price': unitWithAddonsMinor / 100.0,
  'unitPriceMinor': selectedVariant?.effectivePriceMinor ?? 0,
  'addonsPerUnitMinor': totalAddonPriceMinor,
  'quantity': qty.value,
  if (addonsPayload.isNotEmpty) 'addons': addonsPayload,
  if (addonsSummary.isNotEmpty) 'addonsSummary': addonsSummary,
};
```
> **নোট:** `buyNow()` দিয়ে সরাসরি চেকআউটে গেলেও একই `itemPayload` আর্গুমেন্ট হিসেবে পাস করতে হবে যাতে চেকআউট পেজে Add-ons ও সঠিক দাম দেখা যায়।

---

### ৫.২ ব্যাগ / কার্ট স্ক্রিনে যা করতে হবে (`bag_controller.dart`, `cart_model.dart`, `bag_view.dart`)
* **যা ইতিমধ্যে `alifuser`-এ রেডি আছে:**
  * `CartItemModel` (`cart_model.dart`)-এ `addons`, `addonsSummary`, `addonsKey` ফিল্ড যুক্ত আছে।
  * `BagController` ইতিমধ্যে `POST /api/v1/cart` কলে `postData['addons'] = item['addons']` পাঠায় এবং `addonsKey` দিয়ে আলাদা কার্ট লাইন ম্যানেজ করে।
  * `BagView` (`bag_view.dart`)-এ আইটেমের নিচে `+ ${item.addonsSummary!}` অলরেডি রেন্ডার হয়।
* **যে ২টি জরুরি ফিক্স করতে হবে (`cart_model.dart`):**
  1. **দামের সাথে `addonsPerUnitMinor` যোগ করা:** `GET /api/v1/cart` এপিআই `unitPriceMinor` (শুধু বেস প্রাইস) এবং `addonsPerUnitMinor` আলাদা পাঠায় (যেখানে `lineTotalMinor = (unitPriceMinor + addonsPerUnitMinor) * qty`)। তাই `CartItemModel.fromJson`-এ:
     ```dart
     final rawAddonsMinor = json['addonsPerUnitMinor'];
     final int addonsMinor = rawAddonsMinor is num ? rawAddonsMinor.toInt() : 0;
     // extractedPrice হিসাবের সময়:
     extractedPrice = (extractedUnitPriceMinor + addonsMinor) / 100.0;
     ```
  2. **ব্যাকএন্ড স্ন্যাপশট থেকে `addonsSummary` পার্স করা:** ব্যাকএন্ড `GET /api/v1/cart`-এ `addons` অ্যারের ভেতরে `options: [{ label, priceMinor }]` পাঠায়। তাই `cart_model.dart`-এ `a['options']` লিস্টও পার্স করতে হবে:
     ```dart
     if (a['options'] is List && (a['options'] as List).isNotEmpty) {
       opt = (a['options'] as List)
           .whereType<Map>()
           .map((o) => o['label']?.toString() ?? '')
           .where((s) => s.isNotEmpty)
           .join(', ');
     }
     ```

---

### ৫.৩ চেকআউট পেজে ইন্টিগ্রেশন (`checkout_controller.dart` & `checkout_view.dart`)
* **ব্যাকএন্ড চেকআউট (`src/lib/orders/checkout.ts`):**
  * ব্যাকএন্ড ইতিমধ্যে ১০০% রেডি। কাস্টমার যখন `Proceed to Checkout` করে এবং অর্ডার প্লেস করে, তখন ব্যাকএন্ড ডাটাবেসের কার্ট লাইন থেকে `addons` পড়ে লাইভ প্রাইস রি-ক্যালকুলেট করে এবং `OrderItem.addons` ও `OrderItem.addonsTotalMinor` সেভ করে।
* **চেকআউট পেজ ইউআই (`checkout_view.dart`):**
  * বর্তমানে `checkout_view.dart`-এ (লাইন ৩৯০-৪৬৫) প্রতিটি আইটেমের শুধু `title`, `Qty` এবং `price` দেখানো হয়, কিন্তু `addonsSummary` দেখানো হয় না।
  * এখানে `Qty: $qty • ৳${price.toStringAsFixed(2)}` এর নিচে `item['addonsSummary']` প্রদর্শন করতে হবে:
    ```dart
    if (item['addonsSummary'] != null &&
        item['addonsSummary'].toString().isNotEmpty) ...[
      SizedBox(height: 3.h),
      Text(
        '+ ${item['addonsSummary']}',
        style: GoogleFonts.lato(
          fontSize: 11.sp,
          color: AppColor.primaryDark,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
    ```
  * লাইন টোটাল ও সাবটোটাল হিসাব করার সময় নিশ্চিত করতে হবে `price` (অথবা `lineTotalMinor / 100`) যেন Add-on চার্জসহ হয়, যাতে `checkout_quote` থেকে আসা সার্ভারের মোট বিলের সাথে ইউআইয়ের দাম হুবহু মিলে যায়।

---

## ৬. বিস্তারিত Use Cases (ব্যবহারকারী ভিত্তিক ব্যবহারের দৃশ্যপট)

### UC-01: মূল পণ্যের সাথে ওয়ারেন্টি এবং ওয়াটারপ্রুফিং সিলেক্ট করা
- **Actor:** ক্রেতা
- **Flow:**
  1. ক্রেতা `Power Strip` প্রোডাক্টের পেজে আসেন (মূল দাম: ৳ ১,১৯৯)।
  2. Add-ons সেকশনে `Warrenty` চেকবক্সে টিক দেন (+৳ ৫০০)।
  3. `Waterproof` সেকশনে `IP64` রেডিও বাটনে চাপ দেন (+৳ ৫০০)।
  4. নিচের "Add to Cart" বাটনের লাইভ প্রাইস স্বয়ংক্রিয়ভাবে পরিবর্তিত হয়ে ৳ ২,১৯৯ হয়।
  5. কার্টে যোগ করলে এই ভ্যারিয়েন্টের সাথে উভয় Add-on সেভ হয়।
- **Outcome:** ক্রেতা তার পছন্দমতো কাস্টমাইজ করে অর্ডার করতে পারেন।

---

### UC-02: একই ভ্যারিয়েন্ট ভিন্ন Add-on সহ একাধিকবার কার্টে যোগ করা
- **Actor:** ক্রেতা
- **Flow:**
  1. ক্রেতা একবার `Installation: None` দিয়ে ১টি পাওয়ার স্ট্রিপ কার্টে যোগ করেন।
  2. এরপর আবার একই পেজে এসে `Installation: Full Wall Mount (+৳ ৫০০)` নির্বাচন করে কার্টে যোগ করেন।
  3. কার্ট স্ক্রিনে গিয়ে দেখতে পান দুটি আলাদা আইটেম সারি হয়েছে:
     - সারি ১: Power Strip (Installation: None) — ৳ ১,১৯৯
     - সারি ২: Power Strip (Installation: Full Wall Mount) — ৳ ১,৬৯৯
- **Outcome:** সিস্টেমে `addonsKey` এর মাধ্যমে কার্টের নিখুঁত বিভাজন নিশ্চিত হয়।

---

### UC-03: ভ্যারিয়েন্ট পরিবর্তন করলে Add-ons অটো-রিসেট হওয়া
- **Actor:** ক্রেতা
- **Flow:**
  1. ক্রেতা 'Black' কালারের জন্য Add-ons সিলেক্ট করেন।
  2. এরপর কালার পরিবর্তন করে 'White' সিলেক্ট করেন।
  3. অ্যাপ স্বয়ংক্রিয়ভাবে পূর্বের Add-on সিলেকশন রিসেট করে দেয় এবং 'White' ভ্যারিয়েন্টের জন্য নির্ধারিত Add-ons রেন্ডার করে।
- **Outcome:** অমিল বা ভুল অপশন কার্টে চলে যাওয়া প্রতিরোধ হয়।

---

### UC-04: অর্ডার ডিটেইলস ও চালানে Add-ons এর বিবরণ দেখা
- **Actor:** ক্রেতা ও সেলার
- **Flow:**
  1. অর্ডার সম্পন্ন হওয়ার পর কাস্টমার অর্ডার হিস্ট্রি (`My Orders`) বা ইনভয়েসে প্রবেশ করেন।
  2. আইটেমের নামের নিচে দেখতে পান:  
     `Installation: Full Wall Mount (৳ 500) • Warrenty (৳ 500)`
  3. মোট বিলে মূল পণ্যের সাথে Add-on চার্জ যোগ হয়ে সঠিক টোটাল প্রদর্শিত হয়।
- **Outcome:** স্বচ্ছ হিসাব এবং সেলারের ডেলিভারি দেওয়ার সুবিধা।
