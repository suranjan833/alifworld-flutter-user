# User App — Product-Specific Rating & Review Specification

> **লক্ষ্য:** Alif User Mobile App (`alifuser`) এবং ইউজার ইন্টারফেসে শুধুমাত্র নির্দিষ্ট প্রোডাক্টের (Product-Specific) রেটিং এবং রিভিউ প্রদর্শন করার পূর্ণাঙ্গ আর্কিটেকচার, এপিআই গাইড, ডার্ট মডেল, ইউআই ডিজাইন এবং Use Cases।

---

## ১. ওভারভিউ ও আর্কিটেকচার (System Overview)

ইউজার অ্যাপে প্রোডাক্ট ডিটেইলস পেজে প্রোডাক্ট-নির্দিষ্ট রেটিং ও রিভিউ দেখানোর জন্য ব্যাকএন্ডে ইতিমধ্যে পূর্ণাঙ্গ API প্রস্তুত রয়েছে।

```
+-------------------------------------------------------------------------+
|                          ALIF USER MOBILE APP                           |
|                                                                         |
|  [Product Details Screen]                                               |
|  ├── 1. Top Info Card: Rating Pill (★ 4.5 • 12 reviews)                 |
|  │                                                                      |
|  └── 2. Product Reviews Section                                         |
|      ├── Rating Summary (4.5 / 5.0 ★★★★★)                               |
|      ├── Star Distribution Progress Bars (5★, 4★, 3★, 2★, 1★)             |
|      └── Customer Review Cards (Rating, Date, Title, Body, Seller Reply)|
+-------------------------------------------------------------------------+
                                    ▲
                                    │ dioGet('catalog/products/{slug}/reviews')
                                    │
+-------------------------------------------------------------------------+
|                             BACKEND API                                 |
|  GET /api/v1/catalog/products/{slug}/reviews                            |
|  (Returns approved reviews, rating breakdown distribution & count)       |
+-------------------------------------------------------------------------+
```

---

## ২. ব্যাকএন্ড এপিআই কাঠামো (Backend API Specifications)

### ২.১ প্রোডাক্ট ওভারভিউ এপিআই (Product Summary)
- **এন্ডপয়েন্ট:** `GET /api/v1/catalog/products/:slug`
- **ব্যবহার:** প্রোডাক্টের বেসিক রেটিং ও কাউন্ট পেতে।
- **রেসপন্স ফিল্ড:**
```json
{
  "product": {
    "id": "cuid_xyz",
    "name": "Wireless Bluetooth Headphone",
    "slug": "wireless-bluetooth-headphone",
    "ratingAvg": 4.5,
    "ratingCount": 12
  }
}
```

### ২.২ প্রোডাক্ট রিভিউ ও স্টার ডিস্ট্রিবিউশন এপিআই (Detailed Reviews & Breakdown)
- **এন্ডপয়েন্ট:** `GET /api/v1/catalog/products/:slug/reviews?cursor=:nextCursor`
- **পাবলিক অ্যাক্সেস:** কোনো অথেন্টিকেশন (Token) ছাড়াই ওপেন।
- **ফিল্টারিং:** ব্যাকএন্ডে স্বয়ংক্রিয়ভাবে শুধুমাত্র অনুমোদিত (`status = "approved"`) রিভিউ পাঠানো হয়।
- **রেসপন্স স্ট্রাকচার:**
```json
{
  "data": {
    "summary": {
      "average": 4.5,
      "count": 12,
      "distribution": {
        "5": 7,
        "4": 3,
        "3": 1,
        "2": 1,
        "1": 0
      }
    },
    "reviews": [
      {
        "id": "rev_01",
        "rating": 5,
        "title": "দারুণ কোয়ালিটি!",
        "body": "সাউন্ড কোয়ালিটি এবং ব্যাটারি ব্যাকআপ অসাধারণ। ডেলিভারিও দ্রুত পেয়েছি।",
        "reply": "ধন্যবাদ আমাদের সাথে থাকার জন্য!",
        "createdAt": "2026-11-20T10:15:30.000Z"
      },
      {
        "id": "rev_02",
        "rating": 4,
        "title": "Good product",
        "body": "Everything is fine, bass could be slightly better.",
        "reply": null,
        "createdAt": "2026-11-18T14:22:00.000Z"
      }
    ],
    "nextCursor": null
  }
}
```

---

## ৩. ইউজার অ্যাপে কীভাবে সাজাতে হবে (User App UI Design)

### ৩.১ টপ প্রোডাক্ট ইনফো কার্ড (Top Rating Pill)
- প্রোডাক্ট টাইটেলের ঠিক নিচে:
  - স্টার আইকন + রেটিং স্কোর: `4.5 ★`
  - ব্র্যাকেটে রিভিউর সংখ্যা: `(12 reviews)`
  - ইউজার এই পিল-এ ক্লিক করলে পেজটি স্বয়ংক্রিয়ভাবে স্ক্রল করে নিচের রিভিউ সেকশনে চলে যাবে।

### ৩.২ রেটিং সামারি ও স্টার ডিস্ট্রিবিউশন বার (Summary & Breakdown)
```
+-------------------------------------------------------------+
| Ratings & Reviews (12)                                      |
|                                                             |
|   4.5  ★★★★★            5 ★ [====================] (7)      |
|   12 Ratings            4 ★ [==========]           (3)      |
|                         3 ★ [====]                 (1)      |
|                         2 ★ [====]                 (1)      |
|                         1 ★ [ ]                    (0)      |
+-------------------------------------------------------------+
```

### ৩.৩ কাস্টমার রিভিউ কার্ড (Individual Review Item)
- **স্টার রেটিং:** ১ থেকে ৫টি গোল্ডেন স্টার।
- **তারিখ:** যেমন: `20 Nov 2026`।
- **রিভিউ শিরোনাম ও বক্তব্য:** কাস্টমারের মন্তব্য।
- **সেলার রিপ্লাই বক্স (যদি থাকে):**
  - হালকা ব্যাকগ্রাউন্ড কালার এবং বামে ব্র্যান্ড বর্ডার দিয়ে হাইলাইট করা:
  - 💬 **Seller Response:** "ধন্যবাদ আপনার মূল্যবান মতামতের জন্য!"

### ৩.৪ এম্পটি স্টেট (No Reviews Yet)
- কোনো রিভিউ না থাকলে:
  - `No reviews yet for this product.`
  - `Be the first to review after purchase!`

---

## ৪. ফ্লাটার অ্যাপ কোড ইমপ্লিমেন্টেশন (`alifuser`)

### ৪.১ ডার্ট মডেল (`review_model.dart`)
```dart
class ProductReviewsResponse {
  final ReviewSummary summary;
  final List<ProductReviewItem> reviews;
  final String? nextCursor;

  ProductReviewsResponse({
    required this.summary,
    required this.reviews,
    this.nextCursor,
  });

  factory ProductReviewsResponse.fromJson(Map<String, dynamic> json) {
    return ProductReviewsResponse(
      summary: ReviewSummary.fromJson(json['summary'] ?? {}),
      reviews: (json['reviews'] as List? ?? [])
          .map((r) => ProductReviewItem.fromJson(r))
          .toList(),
      nextCursor: json['nextCursor'],
    );
  }
}

class ReviewSummary {
  final double average;
  final int count;
  final Map<String, int> distribution;

  ReviewSummary({
    required this.average,
    required this.count,
    required this.distribution,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final dist = <String, int>{};
    if (json['distribution'] is Map) {
      json['distribution'].forEach((k, v) {
        dist[k.toString()] = (v is num) ? v.toInt() : 0;
      });
    }
    return ReviewSummary(
      average: (json['average'] is num) ? (json['average'] as num).toDouble() : 0.0,
      count: json['count'] ?? 0,
      distribution: dist,
    );
  }
}

class ProductReviewItem {
  final String id;
  final int rating;
  final String? title;
  final String? body;
  final String? reply;
  final DateTime createdAt;

  ProductReviewItem({
    required this.id,
    required this.rating,
    this.title,
    this.body,
    this.reply,
    required this.createdAt,
  });

  factory ProductReviewItem.fromJson(Map<String, dynamic> json) {
    return ProductReviewItem(
      id: json['id'] ?? '',
      rating: json['rating'] ?? 0,
      title: json['title'],
      body: json['body'],
      reply: json['reply'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
```

### ৪.২ কন্ট্রোলারে ফেচ মেথড (`product_details_controller.dart`)
```dart
final reviewsData = Rxn<ProductReviewsResponse>();
final isLoadingReviews = false.obs;

Future<void> fetchProductReviews(String slug) async {
  try {
    isLoadingReviews.value = true;
    final res = await dioGet('catalog/products/$slug/reviews');
    if (res.statusCode == 200 && res.data != null) {
      final payload = res.data['data'] ?? res.data;
      reviewsData.value = ProductReviewsResponse.fromJson(payload);
    }
  } catch (e) {
    // Silent fail or show retry
  } finally {
    isLoadingReviews.value = false;
  }
}
```

### ৪.৩ ইউআই উইজেট (`_buildProductReviewsCard()`)
```dart
Widget _buildProductReviewsCard() {
  return Obx(() {
    if (controller.isLoadingReviews.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = controller.reviewsData.value;
    if (data == null || data.summary.count == 0) {
      return Container(
        padding: EdgeInsets.all(16.r),
        color: Colors.white,
        child: const Text('No reviews yet. Be the first to review this product!'),
      );
    }

    final summary = data.summary;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Reviews (${summary.count})',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),

          // Average & Distribution Bars
          Row(
            children: [
              Column(
                children: [
                  Text(
                    summary.average.toStringAsFixed(1),
                    style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        color: i < summary.average.round() ? Colors.amber : Colors.grey[300],
                        size: 16.r,
                      ),
                    ),
                  ),
                  Text('${summary.count} Ratings', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                ],
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final cnt = summary.distribution[star.toString()] ?? 0;
                    final pct = summary.count > 0 ? cnt / summary.count : 0.0;
                    return Row(
                      children: [
                        Text('$star', style: TextStyle(fontSize: 11.sp)),
                        Icon(Icons.star, size: 10.r, color: Colors.amber),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: Colors.grey[200],
                              color: Colors.amber,
                              minHeight: 6.h,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text('$cnt', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Reviews List
          ...data.reviews.map((r) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 14.r,
                          color: i < r.rating ? Colors.amber : Colors.grey[300],
                        ),
                      ),
                    ),
                    Text(
                      '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
                if (r.title != null && r.title!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(r.title!, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                ],
                if (r.body != null && r.body!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(r.body!, style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
                ],
                if (r.reply != null && r.reply!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(6.r),
                      border: const Border(left: BorderSide(color: Colors.deepOrange, width: 3)),
                    ),
                    child: Text('Seller: ${r.reply}', style: TextStyle(fontSize: 11.sp, color: Colors.black87)),
                  ),
                ],
              ],
            ),
          )),
        ],
      ),
    );
  });
}
```

---

## ৫. বিস্তারিত Use Cases (Product-Specific)

### UC-01: প্রোডাক্টের রেটিং স্ন্যাপশট দেখা (Header Rating Snapshot)
- **Actor:** সাধারণ কাস্টমার
- **Event:** কাস্টমার ইউজার অ্যাপে কোনো প্রোডাক্ট কার্ডে ট্যাপ করে প্রোডাক্ট ডিটেইলস স্ক্রিনে প্রবেশ করে।
- **System Action:** অ্যাপ `ProductDetailsModel` থেকে `ratingAvg` এবং `ratingCount` পড়ে এবং প্রোডাক্টের টাইটেলের নিচে একটি রেটিং ব্যাজ (যেমন `4.5 ★ (12 reviews)`) প্রদর্শন করে।
- **Result:** কাস্টমার ৩ সেকেন্ডের মধ্যে বুঝতে পারে প্রোডাক্টটি ভালো মানের কি না।

### UC-02: বিস্তারিত কাস্টমার রিভিউ ও স্টার ব্রেকডাউন পড়া (Read Reviews)
- **Actor:** কাস্টমার
- **Event:** কাস্টমার নিচে স্ক্রল করে অথবা রেটিং ব্যাজে ট্যাপ করে `Ratings & Reviews` সেকশনে আসে।
- **System Action:** অ্যাপ `catalog/products/:slug/reviews` থেকে অনুমোদিত রিভিউর তালিকা এবং স্টার ডিস্ট্রিবিউশন বার (৫ স্টার কতজন, ১ স্টার কতজন) প্রদর্শন করে।
- **Result:** কাস্টমার অন্যান্য ক্রেতাদের বাস্তব অভিজ্ঞতা ও মন্তব্য পড়ে আশ্বস্ত হয়।

### UC-03: সেলারের রিপ্লাই দেখা (View Seller Clarification)
- **Actor:** কাস্টমার
- **Event:** কাস্টমার রিভিউ পড়ার সময় কোনো সমালোচনামূলক রিভিউর নিচে সেলারের উত্তর লক্ষ্য করে।
- **System Action:** সিস্টেম সেলারের দেওয়া অফিসিয়াল `reply` একটি হাইলাইটেড বক্সে প্রদর্শন করে।
- **Result:** কাস্টমার বুঝতে পারে বিক্রেতা দায়বদ্ধ এবং সমস্যা সমাধান করতে তৎপর।

### UC-04: নতুন প্রোডাক্টে এম্পটি স্টেট হ্যান্ডলিং (No Reviews Fallback)
- **Actor:** কাস্টমার
- **Event:** কাস্টমার একটি নতুন লঞ্চ হওয়া প্রোডাক্ট দেখতে আসে যাতে কোনো রিভিউ নেই (`count == 0` বা `ratingAvg == null`)।
- **System Action:** অ্যাপ কোনো ভাঙা ভিউ বা নাল ক্র্যাশ ছাড়াই সুন্দর এম্পটি স্টেট দেখায়: *"No reviews yet for this product."*।
- **Result:** অ্যাপ ক্র্যাশ বা মিসলিডিং তথ্য ছাড়া স্মুথ ইউজার এক্সপেরিয়েন্স প্রদান করে।








# User App — Product-Specific Rating & Review Specification

> **লক্ষ্য:** Alif User Mobile App (`alifuser`) এবং ইউজার ইন্টারফেসে নির্দিষ্ট প্রোডাক্টের (Product-Specific) **রেটিং ও রিভিউ প্রদর্শন** এবং **অর্ডার ডেলিভারির পর রিভিউ সাবমিট করার সম্পূর্ণ সিস্টেম** — আর্কিটেকচার, ব্যাকএন্ড এপিআই, ডার্ট মডেল, ইউআই ডিজাইন এবং Use Cases।

---

## ১. ওভারভিউ ও আর্কিটেকচার (System Overview)

Alif World-এ প্রোডাক্ট রিভিউ সিস্টেমটি ২টি মূল অংশে বিভক্ত:
1. **প্রোডাক্ট পেজে রেটিং ও রিভিউ প্রদর্শন (Viewing):** যে কেউ (লগইন ছাড়া বা লগইন অবস্থায়) প্রোডাক্টের গড় স্টার, ৫ থেকে ১ স্টারের ব্রেকডাউন এবং অনুমোদিত রিভিউগুলো দেখতে পারে।
2. **ডেলিভারির পর রিভিউ প্রদান (Submission after Delivery):** শুধুমাত্র ভেরিফায়েড ক্রেতারা অর্ডার ডেলিভারি হওয়ার পর (`order.status = "delivered"`) ফটোসহ রিভিউ জমা দিতে পারেন।

```
                                  [CUSTOMER USER APP]
                                     │            │
             1. View Reviews on PDP  │            │  2. Submit Review after Delivery
             (Public / No Token)     │            │  (Auth Protected / Verified Delivery)
                                     ▼            ▼
                   GET /catalog/products/      POST /account/reviews
                   {slug}/reviews              (Rating, Title, Body, Photos)
                                     │            │
                                     │            ▼
                                     │         [DB: ProductReview status='pending']
                                     │            │
                                     │            ▼
                                     │         [Admin Moderation /admin/reviews]
                                     │            │ (Approve)
                                     │            ▼
                                     └─────────[DB: ProductReview status='approved']
```

---

## ২. ব্যাকএন্ড এপিআই কাঠামো (Backend API Specifications)

আমাদের ব্যাকএন্ডে ডেলিভারি যাচাই, ফটো আপলোড এবং রিভিউ সাবমিশনের সব এপিআই ইতিমধ্যে **১০০% প্রস্তুত এবং কার্যকর** আছে।

### ২.১ অর্ডার ডেলিভারির পর রিভিউ সাবমিশন এপিআই (Review Submission API)
- **এন্ডপয়েন্ট:** `POST /api/v1/account/reviews`
- **অথেনটিকেশন:** `Bearer <User Token>` অথবা সেশন কুকি আবশ্যক (`guardCustomer`)।
- **রেট লিমিট:** রাইট টিয়ার প্রোটেক্টেড।
- **রিকোয়েস্ট বডি (JSON):**
```json
{
  "productId": "cuid_product_id",
  "rating": 5,
  "title": "দারুণ পণ্য!",
  "body": "সাউন্ড কোয়ালিটি এবং বিল্ড কোয়ালিটি খুবই ভালো। সময়মতো ডেলিভারি পেয়েছি।",
  "photos": [
    "https://storage.alifworld.com/uploads/review_img1.jpg",
    "https://storage.alifworld.com/uploads/review_img2.jpg"
  ]
}
```
- **ব্যাকএন্ড ভ্যালিডেশন ও সিকিউরিটি চেক (ইতিমধ্যে কোডে সক্রিয়):**
  1. **ডেলিভারি ভেরিফিকেশন (`REVIEW_NOT_ELIGIBLE` - 403):** ব্যাকএন্ড চেক করে এই ব্যবহারকারীর এমন কোনো অর্ডার আছে কি না যাতে এই প্রোডাক্টটি রয়েছে এবং সেই অর্ডারের স্ট্যাটাস অবশ্যই `status = "delivered"`। পণ্য ডেলিভারি না হলে বা অর্ডার ক্যান্সেল হলে সার্ভার সরাসরি ৪০৩ রিটার্ন করে।
  2. **ডুপ্লিকেট রিভিউ প্রতিরোধ (`REVIEW_ALREADY_EXISTS` - 409):** একজন ক্রেতা একটি প্রোডাক্টে কেবল একবারই রিভিউ দিতে পারেন (`@@unique([productId, userId])`)। দ্বিতীয়বার চেষ্টা করলে সার্ভার ৪০৯ কনফ্লিক্ট ফেরত দেয়।
  3. **স্টার লিমিট:** রেটিং অবশ্যই ১ থেকে ৫ এর মধ্যে পূর্ণসংখ্যা (`1 <= rating <= 5`) হতে হবে।
  4. **ইনিশিয়াল স্ট্যাটাস:** সাবমিট হওয়া মাত্র রিভিউটি `pending` স্ট্যাটাসে ডেটাবেসে যায়, যা অ্যাডমিন মডারেশনের পর পাবলিক হয়।

### ২.২ রিভিউয়ের ছবি আপলোড এপিআই (Photo Upload API)
- **এন্ডপয়েন্ট:** `POST /api/v1/account/uploads`
- **টাইপ:** `multipart/form-data`
- **প্যারামিটার:**
  - `file`: ইমেজ ফাইল (JPEG, PNG, WebP, AVIF, GIF - সর্বোচ্চ ২ মেগাবাইট)
  - `kind`: `"review"`
- **রেসপন্স:**
```json
{
  "url": "https://storage.alifworld.com/uploads/reviews/xyz.jpg"
}
```
*(কাস্টমার সর্বোচ্চ ৫টি ছবি রিভিউয়ের সাথে যুক্ত করতে পারেন)*।

---

### ২.৩ প্রোডাক্ট রিভিউ ও স্টার ডিস্ট্রিবিউশন এপিআই (Public Viewing API)
- **এন্ডপয়েন্ট:** `GET /api/v1/catalog/products/:slug/reviews?cursor=:nextCursor`
- **পাবলিক অ্যাক্সেস:** কোনো টোকেন ছাড়াই কল করা যায়।
- **ফিল্টারিং:** ব্যাকএন্ডে স্বয়ংক্রিয়ভাবে শুধুমাত্র অনুমোদিত (`status = "approved"`) রিভিউ পাঠানো হয়।
- **রেসপন্স স্ট্রাকচার:**
```json
{
  "data": {
    "summary": {
      "average": 4.5,
      "count": 12,
      "distribution": {
        "5": 7,
        "4": 3,
        "3": 1,
        "2": 1,
        "1": 0
      }
    },
    "reviews": [
      {
        "id": "rev_01",
        "rating": 5,
        "title": "দারুণ কোয়ালিটি!",
        "body": "সাউন্ড কোয়ালিটি এবং ব্যাটারি ব্যাকআপ অসাধারণ। ডেলিভারিও দ্রুত পেয়েছি।",
        "reply": "ধন্যবাদ আমাদের সাথে থাকার জন্য!",
        "createdAt": "2026-11-20T10:15:30.000Z"
      }
    ],
    "nextCursor": null
  }
}
```

---

## ৩. ইউজার অ্যাপে কীভাবে সাজাতে হবে (User App UI Design)

### ৩.১ প্রোডাক্ট ডিটেইলস পেজে (PDP Viewing Flow)
1. **টপ রেটিং ব্যাজ:** টাইটেলের নিচে `★ 4.5 • (12 reviews)`। এতে ট্যাপ করলে স্ক্রল করে সোজা রিভিউ সেকশনে নিয়ে যাবে।
2. **রেটিং সামারি ও স্টার ডিস্ট্রিবিউশন:**
   - বড় গড় রেটিং স্কোর (যেমন: `4.5 / 5.0`)।
   - ৫★ থেকে ১★ পর্যন্ত প্রগ্রেস বার (Progress Bars)।
3. **কাস্টমার রিভিউ তালিকা:**
   - কাস্টমারের রেটিং (স্টার আইকন), তারিখ, টাইটেল, মন্তব্য।
   - ক্রেতার আপলোড করা ছবির থাম্বনেইল।
   - সেলার রিপ্লাই (যদি থাকে): হাইলাইটেড বক্সে `Seller Reply: ...`।
4. **এম্পটি স্টেট:** কোনো রিভিউ না থাকলে: *"No reviews yet for this product. Be the first to review after purchase!"*।

---

### ৩.২ মাই অর্ডারস / অর্ডার ডিটেইলস স্ক্রিনে (After-Delivery Submission Flow)
কাস্টমারের অর্ডার হিস্ট্রি স্ক্রিনে (`/account/orders/:id`):
1. **অর্ডার স্ট্যাটাস চেক:** যদি `order.status == 'delivered'` হয়:
   - ডেলিভার্ড হওয়া প্রতিটি প্রোডাক্ট আইটেমের নিচে একটি অ্যাকশন বাটন দেখাবে:
     - ✍️ **"Write a Review"** (যদি পূর্বে রিভিউ না দেওয়া থাকে)।
   - কাস্টমার যদি ইতোমধ্যে রিভিউ দিয়ে থাকেন:
     - ⭐ **"Already Reviewed"** অথবা **"Pending Moderation"** ব্যাজ দেখাবে।
2. **রিভিউ ডায়ালগ / বটম শীট (Review BottomSheet):**
   - **ইন্টারেক্টিভ স্টার পিকার:** ১ থেকে ৫ স্টারে ট্যাপ করার অপশন।
   - **টাইটেল ফিল্ড:** "Headline / Summary of your review" (ঐচ্ছিক)।
   - **ডিটেইলড রিভিউ বক্স:** "What did you like or dislike about this product?"
   - **ফটো পিকার:** গ্যালারি/ক্যামেরা থেকে ছবি যোগ করার অপশন (সর্বোচ্চ ৫টি)।
   - **সাবমিট বাটন:** "Submit Review"।
3. **সাবমিট পরবর্তী প্রতিক্রিয়া:** সাবমিট হওয়ার সাথে সাথে স্নাকবার দেখাবে: *"Thank you! Your review has been submitted for moderation."* এবং বাটনটি আপডেট হয়ে *"Reviewed"* দেখাবে।

---

## ৪. ফ্লাটার অ্যাপ কোড স্নিপেট (`alifuser`)

### ৪.১ রিভিউ সাবমিট কন্ট্রোলার মেথড (`order_details_controller.dart`)
```dart
Future<bool> submitProductReview({
  required String productId,
  required int rating,
  String? title,
  String? body,
  List<String> photoUrls = const [],
}) async {
  try {
    final payload = {
      'productId': productId,
      'rating': rating,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      if (photoUrls.isNotEmpty) 'photos': photoUrls,
    };

    final response = await dioPost('account/reviews', payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      Get.snackbar(
        'Success',
        'Thank you! Your review has been submitted for approval.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to submit review. Please try again.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
  return false;
}
```

---

## ৫. বিস্তারিত Use Cases (ব্যবহারকারী ভিত্তিক ব্যবহারের দৃশ্যপট)

### UC-01: পণ্য ডেলিভারির পর অর্ডারে রিভিউ বাটন সক্রিয় হওয়া
- **Actor:** ক্রেতা (Customer)
- **Pre-condition:** ক্রেতার অর্ডারটি কুরিয়ার/রাইডার কর্তৃক সফলভাবে ডেলিভারি হয়েছে (`order.status = "delivered"`).
- **Flow:**
  1. ক্রেতা অ্যাপে `My Orders` -> `Order Details`-এ প্রবেশ করেন।
  2. সিস্টেম চেক করে যে অর্ডারটি ডেলিভার্ড এবং আইটেমটিতে এখনও রিভিউ দেওয়া হয়নি।
  3. আইটেম কার্ডের নিচে **"Write a Review"** বাটন দৃশ্যমান হয়।
- **Outcome:** ক্রেতা সহজে বুঝতে পারেন যে তিনি এখন এই পণ্যটির রিভিউ দিতে প্রস্তুত।

---

### UC-02: আনডেলিভার্ড বা ক্যান্সেল হওয়া পণ্যে রিভিউ বাটন ব্লক থাকা
- **Actor:** ক্রেতা / অননুমোদিত ইউজার
- **Pre-condition:** অর্ডারের স্ট্যাটাস `placed`, `shipped`, `processing` অথবা `cancelled` অবস্থায় আছে।
- **Flow:**
  1. ক্রেতা অর্ডার পেজে প্রবেশ করেন।
  2. ডেলিভারি সম্পন্ন না হওয়া পর্যন্ত কোনো রিভিউ বাটন প্রদর্শিত হয় না।
  3. কোনোভাবে সরাসরি এপিআই কল করা হলেও ব্যাকএন্ড `403 REVIEW_NOT_ELIGIBLE` ফেরত দেয়।
- **Outcome:** প্ল্যাটফর্মে ভুয়া রিভিউ দেওয়া সম্পূর্ণ প্রতিরোধ হয়।

---

### UC-03: ফটোসহ স্টার রেটিং ও বিস্তারিত মন্তব্য সাবমিশন
- **Actor:** ক্রেতা
- **Flow:**
  1. ক্রেতা "Write a Review" বাটনে ট্যাপ করেন।
  2. একটি বটম শীট ওপেন হয়। ক্রেতা ৫ স্টার সিলেক্ট করেন।
  3. আনবক্সিং করা পণ্যের ২টি ছবি যুক্ত করেন (যা `/api/v1/account/uploads` দিয়ে আপলোড হয়)।
  4. পণ্যের স্থায়িত্ব ও পারফরম্যান্স নিয়ে মন্তব্য লিখে "Submit Review" বাটনে ট্যাপ করেন।
  5. সিস্টেম রিভিউটি ডেটাবেসে `status: "pending"` হিসেবে সংরক্ষণ করে।
- **Outcome:** রিভিউটি অ্যাডমিন মডারেশন কিউতে জমা পড়ে এবং কাস্টমারকে সফলতার বার্তা দেখানো হয়।

---

### UC-04: প্রোডাক্ট ডিটেইলস পেজে কাস্টমারদের রিভিউ পড়া
- **Actor:** সাধারণ ক্রেতা (Visitor / App User)
- **Flow:**
  1. ক্রেতা প্রোডাক্ট ডিটেইলস স্ক্রিনে প্রবেশ করেন।
  2. টাইটেলের নিচে রেটিং স্ন্যাপশট (`4.5 ★ • 12 reviews`) দেখেন।
  3. নিচে স্ক্রল করে অন্যান্য ক্রেতাদের মন্তব্য, ছবি এবং সেলারের রিপ্লাই পর্যবেক্ষণ করেন।
- **Outcome:** ক্রেতার কেনার আত্মবিশ্বাস বৃদ্ধি পায়।
