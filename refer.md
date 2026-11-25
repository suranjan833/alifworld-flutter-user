# Alif World — Refer & Earn (Refer Rank & Multi-Level Referral System)

> **ডকুমেন্ট উদ্দেশ্য:** ব্যবহারকারীর প্রদত্ত স্ক্রিনশট (ওয়েবসাইটের `localhost:3000/account/referrals`) বিশ্লেষণ করে **Alif User Mobile App (`alifuser`)**-এর `Refer and Earn` স্ক্রিনে **Refer Rank**, **Timeline Stepper**, **Registration Bonus/Rates** এবং **Multi-Level Referral** ফিচারগুলো সম্পূর্ণ ইন্টিগ্রেশন করার টেকনিক্যাল স্পেসিফিকেশন ও Use Cases।

---

## ১. স্ক্রিনশটদ্বয়ের ভিজ্যুয়াল অ্যানাটমি (Screenshot Visual Anatomy)

প্রদত্ত স্ক্রিনশটে ওয়েবসাইটের রেফার সেকশনের দুটি প্রধান উপাদান প্রদর্শিত হয়েছে:

```
+-----------------------------------------------------------------------------------+
|  [ STATS ROW ]                                                                    |
|  ┌────────────────────────────────────┐   ┌────────────────────────────────────┐  |
|  │ 📁 Registration referral earnings  │   │ 📁 My registration bonus          │  |
|  │    ৳ 0.00                          │   │    ৳ 1,000.00                      │  |
|  └────────────────────────────────────┘   └────────────────────────────────────┘  |
+-----------------------------------------------------------------------------------+
|  [ 1. REFER RANK HERO CARD (Orange Header: #ff630f) ]                             |
|  ┌─────────────────────────────────────────────────────────────────────────────┐  |
|  │ REFER RANK                                          ┌─────────────────────┐ │  |
|  │ 🏆 0 level-1 referrals                              │ 🏆 Refer rank       │ │  |
|  │                                                     │    Unranked         │ │  |
|  │                                                     └─────────────────────┘ │  |
|  ├─────────────────────────────────────────────────────────────────────────────┤  |
|  │  (•) Unranked ─────── ( ) Bronze ─────── ( ) Silver ─────── ( ) Gold        │  |
|  │  [========= Progress Fill Line (0% to 100%) ===============================]│  |
|  │                                                                             │  |
|  │  ┌───────────────────────────────────────────────────────────────────────┐  │  |
|  │  │ 🏆 |  Invite 10 more friends to reach Bronze                          │  │  |
|  │  └───────────────────────────────────────────────────────────────────────┘  │  |
|  │                                                                             │  |
|  │  Bronze 10 · Silver 50 · Gold 100 level-1 referrals — Ranks celebrate your   │  |
|  │  referrals — top referrers may receive gifts from the Alifworld team.       │  |
|  └─────────────────────────────────────────────────────────────────────────────┘  |
+-----------------------------------------------------------------------------------+
|  [ 2. REGISTRATION REFERRAL RATES CARD ]                                          |
|  ┌─────────────────────────────────────────────────────────────────────────────┐  |
|  │ 👥 Registration referral rates                                              │  |
|  │  ┌───────────────────────────────────────────────────────────────────────┐  │  |
|  │  │ ℹ️ When someone registers with your code, you and your uplines earn a  │  │  |
|  │  │    % of the registration bonus — up to 3 levels.                      │  │  |
|  │  └───────────────────────────────────────────────────────────────────────┘  │  |
|  │                                                                             │  |
|  │  Level 1 · 70%                     0 users                          ৳ 0.00  │  |
|  │  Level 2 · 20%                     0 users                          ৳ 0.00  │  |
|  │  Level 3 · 10%                     0 users                          ৳ 0.00  │  |
|  │                                                                             │  |
|  │  Tap a level to see who joined there.                                       │  |
|  │  ┌───────────────────────────────────────────────────────────────────────┐  │  |
|  │  │ ℹ️ Referral rewards are ongoing — you earn on every order your         │  │  |
|  │  │    referrals place, up to 3 levels.                                   │  │  |
|  │  └───────────────────────────────────────────────────────────────────────┘  │  |
|  └─────────────────────────────────────────────────────────────────────────────┘  |
+-----------------------------------------------------------------------------------+
```

---

## ২. ব্যাকএন্ড এপিআই ও ডেটা আর্কিটেকচার (Backend API Structure)

আমাদের ব্যাকএন্ডে এই সম্পূর্ণ ডেটাটি একটিমাত্র এপিআই কল-এ পরিবেশন করা হয়:
- **এন্ডপয়েন্ট:** `GET /api/v1/referrals`
- **অথেনটিকেশন:** `Bearer <User Token>` (গ্রাহক সেশন)

### এপিআই রেসপন্স পে-লোড (Exact Payload):
```json
{
  "code": "ALIF9821",
  "link": "https://alifworld.com.bd/register?ref=ALIF9821",
  "referredCount": 0,
  "earningsMinor": 0,
  "registrationEarningsMinor": 0,
  "ownRegistrationBonusMinor": 100000,
  "registrationBonus": {
    "amountMinor": 100000,
    "walletKind": "customer_main"
  },
  "registrationMaxLevels": 3,
  "referRank": {
    "rank": "unranked",
    "l1Count": 0,
    "thresholds": {
      "bronze": 10,
      "silver": 50,
      "gold": 100
    },
    "nextRank": "bronze",
    "referralsToNext": 10
  },
  "levels": [
    {
      "level": 1,
      "ratePct": 70,
      "walletKind": "customer_referral",
      "earningsMinor": 0,
      "userCount": 0
    },
    {
      "level": 2,
      "ratePct": 20,
      "walletKind": "customer_referral",
      "earningsMinor": 0,
      "userCount": 0
    },
    {
      "level": 3,
      "ratePct": 10,
      "walletKind": "customer_referral",
      "earningsMinor": 0,
      "userCount": 0
    }
  ],
  "currency": "BDT",
  "currencySymbol": "৳",
  "currencySymbolPlacement": "left"
}
```

### লেভেল হিস্ট্রি এপিআই (Level Joins API):
- **এন্ডপয়েন্ট:** `GET /api/v1/referrals/history?level=1&limit=20&cursor=...`
- কাস্টমার যখন কোনো লেভেলে ট্যাপ করবে, তখন ওই লেভেলে কারা কারা জয়েন করেছে তাদের তালিকা ও তারিখ ফেচ হবে।

---

## ৩. রেফার র‍্যাঙ্ক লজিক ও প্রগ্রেস ক্যালকুলেশন (Refer Rank Math)

### ৩.১ র‍্যাঙ্কের পর্যায়সমূহ (Rank Milestones):
1. **Unranked:** ০ থেকে ৯ জন লেভেল-১ রেফারেল।
2. **Bronze:** ১০ থেকে ৪৯ জন লেভেল-১ রেফারেল।
3. **Silver:** ৫০ থেকে ৯৯ জন লেভেল-১ রেফারেল।
4. **Gold:** ১০০+ লেভেল-১ রেফারেল (শীর্ষ র‍্যাঙ্ক)।

### ৩.২ টাইমলাইন ফিল পারসেন্টেজ সূত্র (Timeline Fill % Formula):
টাইমলাইনটিতে ৩টি সেগমেন্ট থাকে: `Unranked → Bronze`, `Bronze → Silver`, `Silver → Gold`।
```dart
double calculateTimelineFill({
  required int l1Count,
  required int bronzeTh, // 10
  required int silverTh, // 50
  required int goldTh,   // 100
}) {
  if (l1Count >= goldTh) return 1.0; // 100%
  if (l1Count >= silverTh) {
    // Segment 2: Silver to Gold (range: 50 to 100)
    final progress = (l1Count - silverTh) / (goldTh - silverTh);
    return (2 + progress) / 3.0;
  }
  if (l1Count >= bronzeTh) {
    // Segment 1: Bronze to Silver (range: 10 to 50)
    final progress = (l1Count - bronzeTh) / (silverTh - bronzeTh);
    return (1 + progress) / 3.0;
  }
  // Segment 0: Unranked to Bronze (range: 0 to 10)
  final progress = l1Count / bronzeTh;
  return progress / 3.0;
}
```

---

## ৪. ব্যবহারকারী ভিত্তিক Use Cases (Detailed Use Cases)

### UC-01: ইউজার অ্যাপে রেফার র‍্যাঙ্ক ও পরবর্তী টার্গেট দেখা
- **Actor:** সাধারণ ইউজার
- **Flow:**
  1. ইউজার অ্যাপের মেনু বা হোম থেকে `Refer and Earn` স্ক্রিনে প্রবেশ করেন।
  2. ইউজার উপরে কমলা রঙের **REFER RANK** কার্ডে নিজের বর্তমান র‍্যাঙ্ক (`Unranked`) এবং লেভেল-১ রেফারেল সংখ্যা (`0 level-1 referrals`) দেখতে পান।
  3. টাইমলাইনের নিচে একটি হাইলাইট বক্সে স্পষ্ট মেসেজ দেখেন: *"Invite 10 more friends to reach Bronze"*।
  4. নিচে থ্রেশহোল্ড গাইড পড়ে বুঝতে পারেন ১০ জনে ব্রোঞ্জ, ৫০ জনে সিলভার এবং ১০০ জনে গোল্ড ব্যাজ পাওয়া যাবে।
- **Outcome:** ইউজার বন্ধুদের আমন্ত্রণ জানানোর অনুপ্রেরণা পান।

---

### UC-02: রেফারেল কোড দিয়ে বন্ধু রেজিস্ট্রেশন করলে র‍্যাঙ্ক আপডেট
- **Actor:** ইউজার এবং রেফারেল বন্ধু
- **Flow:**
  1. ইউজার তার রেফার কোড/লিংক হোয়াটসঅ্যাপ বা মেসেঞ্জারে বন্ধুকে শেয়ার করেন।
  2. বন্ধু সেই কোড দিয়ে নতুন একাউন্ট খুলে ১,০০০ টাকা রেজিস্ট্রেশন বোনাস পায়।
  3. ইউজারের লেভেল-১ রেফার সংখ্যা ০ থেকে বেড়ে ১ হয়।
  4. কলআউট বক্স স্বয়ংক্রিয়ভাবে আপডেট হয়ে দেখায়: *"Invite 9 more friends to reach Bronze"* এবং টাইমলাইনের প্রগ্রেস বার ১০% এগিয়ে যায়।
- **Outcome:** ইউজার রিয়েল-টাইম প্রগ্রেস পর্যবেক্ষণ করতে পারেন।

---

### UC-03: গোল্ড র‍্যাঙ্কে পৌঁছানো ও বিশেষ স্বীকৃতি
- **Actor:** টপ রেফারার ইউজার
- **Pre-condition:** ইউজার ১০০ জন বন্ধুকে সফলভাবে যুক্ত করেছেন (`l1Count >= 100`).
- **Flow:**
  1. ইউজার `Refer and Earn` স্ক্রিনে প্রবেশ করেন।
  2. র‍্যাঙ্ক ব্যাজ পরিবর্তিত হয়ে ঝলমলে গোল্ড মেডেল ধারণ করে: `Refer rank: Gold`।
  3. টাইমলাইন ১০০% পূর্ণ প্রদর্শিত হয়।
  4. কলআউট বক্সে প্রদর্শিত হয়: *"You have reached Gold, the top rank!"*।
  5. আলিম ওয়ার্ল্ড টিম থেকে টপ রেফারার হিসেবে বিশেষ উপহার/পুরস্কারের জন্য মনোনীত হন।
- **Outcome:** ইউজারের আনুগত্য এবং ব্র্যান্ড অ্যাডভোকেসি বৃদ্ধি।

---

### UC-04: ৩-লেভেল রেজিস্ট্রেশন বোনাস ও উপার্জনের হার পর্যবেক্ষণ
- **Actor:** ইউজার
- **Flow:**
  1. ইউজার নিচের দিকে স্ক্রল করে **Registration referral rates** কার্ডে আসেন।
  2. ইউজার দেখতে পান ৩ স্তরের কমিশন রেট:
     - **Level 1 (70%):** নিজের সরাসরি রেফারেলের জন্য।
     - **Level 2 (20%):** তার রেফার করা বন্ধুদের রেফারেলের জন্য।
     - **Level 3 (10%):** ৩য় স্তরের রেজিস্ট্রেশনের জন্য।
  3. প্রতিটি লেভেলে কতজন ইউজার যুক্ত হয়েছে এবং মোট কত টাকা আয় হয়েছে তা দেখতে পান।
- **Outcome:** রেফারেল নেটওয়ার্কের স্বচ্ছতা নিশ্চিত হয়।

---

### UC-05: নির্দিষ্ট লেভেলের রেফারেল বন্ধুদের তালিকা দেখা
- **Actor:** ইউজার
- **Flow:**
  1. ইউজার `Level 1 · 70%` সারিতে ট্যাপ করেন।
  2. অ্যাপটি `GET /api/v1/referrals/history?level=1` কল করে।
  3. নিচে একটি এক্সপ্যান্ডেবল তালিকা বা পৃথক শিট খোলে যেখানে বন্ধুর নাম এবং যোগদানের তারিখ (যেমন: `24 Nov 2026`) দেখা যায়।
  4. পুনরায় ট্যাপ করলে তালিকাটি বন্ধ হয়ে যায়।
- **Outcome:** ইউজার ট্র্যাক করতে পারেন কারা তার লিংকে যোগ দিয়েছেন।

---

### UC-06: আজীবন অর্ডার কমিশন (Ongoing Order Rewards) সম্পর্কে জানা
- **Actor:** ইউজার
- **Flow:**
  1. কার্ডের নিচে থাকা ব্লু ইনফরমেশন নোটটি পড়েন: *"Referral rewards are ongoing — you earn on every order your referrals place, up to 3 levels."*
  2. ইউজার আশ্বস্ত হন যে শুধুমাত্র রেজিস্ট্রেশনেই শেষ নয়, ভবিষ্যতে তারা যখনই শপিং করবে, সেখান থেকেও আয় হতে থাকবে।
- **Outcome:** দীর্ঘমেয়াদে সক্রিয় রেফারেল তৈরির তাগিদ তৈরি হয়।

---

## ৫. ফ্লাটার অ্যাপে (`alifuser`) কোড বাস্তবায়ন গাইড

### ৫.১ মডেল আপডেট (`referral_model.dart`)
`ReferralInfoModel`-এ `ReferRankModel` যোগ করতে হবে:
```dart
class ReferRankModel {
  final String rank; // unranked, bronze, silver, gold
  final int l1Count;
  final ReferThresholds thresholds;
  final String? nextRank;
  final int? referralsToNext;

  ReferRankModel({
    required this.rank,
    required this.l1Count,
    required this.thresholds,
    this.nextRank,
    this.referralsToNext,
  });

  factory ReferRankModel.fromJson(Map<String, dynamic> json) {
    return ReferRankModel(
      rank: json['rank']?.toString().toLowerCase() ?? 'unranked',
      l1Count: (json['l1Count'] as num?)?.toInt() ?? 0,
      thresholds: ReferThresholds.fromJson(json['thresholds'] ?? {}),
      nextRank: json['nextRank']?.toString().toLowerCase(),
      referralsToNext: (json['referralsToNext'] as num?)?.toInt(),
    );
  }
}

class ReferThresholds {
  final int bronze;
  final int silver;
  final int gold;

  ReferThresholds({this.bronze = 10, this.silver = 50, this.gold = 100});

  factory ReferThresholds.fromJson(Map<String, dynamic> json) {
    return ReferThresholds(
      bronze: (json['bronze'] as num?)?.toInt() ?? 10,
      silver: (json['silver'] as num?)?.toInt() ?? 50,
      gold: (json['gold'] as num?)?.toInt() ?? 100,
    );
  }
}
```

---

### ৫.২ রেফার র‍্যাঙ্ক উইজেট (`refer_rank_card.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../data/models/referral_model.dart';

class ReferRankCard extends StatelessWidget {
  final ReferRankModel rank;
  const ReferRankCard({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    final stops = ['Unranked', 'Bronze', 'Silver', 'Gold'];
    final currentRankStr = rank.rank.capitalizeFirst ?? 'Unranked';

    // Timeline fill calculation
    double fillPct = 0.0;
    if (rank.l1Count >= rank.thresholds.gold) {
      fillPct = 1.0;
    } else if (rank.l1Count >= rank.thresholds.silver) {
      fillPct = (2 + (rank.l1Count - rank.thresholds.silver) / (rank.thresholds.gold - rank.thresholds.silver)) / 3.0;
    } else if (rank.l1Count >= rank.thresholds.bronze) {
      fillPct = (1 + (rank.l1Count - rank.thresholds.bronze) / (rank.thresholds.silver - rank.thresholds.bronze)) / 3.0;
    } else {
      fillPct = (rank.l1Count / rank.thresholds.bronze) / 3.0;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Orange Hero Header
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF6D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFER RANK',
                      style: GoogleFonts.lato(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26.r),
                        SizedBox(width: 8.w),
                        Text(
                          '${rank.l1Count}',
                          style: GoogleFonts.lato(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'level-1 referrals',
                          style: GoogleFonts.lato(fontSize: 13.sp, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                // Rank Pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.military_tech_rounded, color: const Color(0xFFFFD54F), size: 20.r),
                      SizedBox(width: 6.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Refer rank', style: GoogleFonts.lato(fontSize: 10.sp, color: Colors.white70)),
                          Text(currentRankStr, style: GoogleFonts.lato(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Timeline Stepper
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background track
                    Container(height: 4.h, color: const Color(0xFFE0E0E0)),
                    // Active fill
                    FractionallySizedBox(
                      widthFactor: fillPct.clamp(0.0, 1.0),
                      child: Container(height: 4.h, color: const Color(0xFFE65100)),
                    ),
                    // Stops
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: stops.map((stop) {
                        final isReached = _isRankReached(stop, rank.rank);
                        return Column(
                          children: [
                            Container(
                              width: 28.r,
                              height: 28.r,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isReached ? const Color(0xFFE65100) : Colors.white,
                                border: Border.all(
                                  color: isReached ? const Color(0xFFE65100) : const Color(0xFFBDBDBD),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.emoji_events_rounded,
                                size: 14.r,
                                color: isReached ? Colors.white : const Color(0xFF9E9E9E),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              stop,
                              style: GoogleFonts.lato(
                                fontSize: 11.5.sp,
                                fontWeight: isReached ? FontWeight.bold : FontWeight.normal,
                                color: isReached ? const Color(0xFFE65100) : const Color(0xFF757575),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                // Callout Alert Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_outlined, color: const Color(0xFFE65100), size: 20.r),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          rank.nextRank != null && rank.referralsToNext != null
                              ? 'Invite ${rank.referralsToNext} more friends to reach ${rank.nextRank!.capitalizeFirst}'
                              : 'You have reached the top Gold rank!',
                          style: GoogleFonts.lato(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBF360C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Thresholds Subtext
                Text(
                  'Bronze ${rank.thresholds.bronze} · Silver ${rank.thresholds.silver} · Gold ${rank.thresholds.gold} level-1 referrals — Ranks celebrate your referrals — top referrers may receive gifts from the Alifworld team.',
                  style: GoogleFonts.lato(
                    fontSize: 11.sp,
                    color: const Color(0xFF757575),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isRankReached(String stop, String currentRank) {
    const order = ['unranked', 'bronze', 'silver', 'gold'];
    return order.indexOf(currentRank.toLowerCase()) >= order.indexOf(stop.toLowerCase());
  }
}
```

---

## ৬. সারসংক্ষেপ

এই স্পেসিফিকেশন ও ইউআই উইজেট অনুসরণ করে ইউজার অ্যাপে হুবহু ওয়েবসাইটের মতো:
1. **REFER RANK কার্ড** (কমলা রঙের হেডার, রিয়েল-টাইম ট্রফি কাউন্ট ও ব্যাজ)
2. **৪-ধাপের টাইমলাইন স্টেপার** (Unranked → Bronze → Silver → Gold)
3. **টার্গেট কলআউট বক্স** (কতজন বাকি আছে পরবর্তী র‍্যাঙ্কে যেতে)
4. **৩-স্তরের রেজিস্ট্রেশন রেফারেল রেট** (Level 1: 70%, Level 2: 20%, Level 3: 10%)
5. **আজীবন অর্ডার রিওয়ার্ডস নোট**  
সহজেই ইন্টিগ্রেট করা সম্ভব।
