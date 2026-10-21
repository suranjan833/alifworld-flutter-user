import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A lightweight, dependency-free shimmer skeleton box.
///
/// Place any number of [SkeletonBox] widgets in a [Stack] under a single
/// [SkeletonShimmer] wrapper (or inside a screen-level [Stack] with a
/// [SkeletonShimmer] on top) to get the moving highlight effect.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: circle ? null : height,
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius.r),
      ),
    );
  }
}

/// Paints a moving diagonal light band over its child to create the shimmer.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final dx = bounds.width;
            final dy = bounds.height;
            // Sweep the highlight from bottom-left to top-right.
            final rect = Rect.fromLTWH(
              -dx + (dx * 2 + dy) * _controller.value,
              -dy,
              dx + dy,
              dx + dy,
            );
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmering skeleton list of rows: [leading] circle + two text bars.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 6, this.padding});

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (_, _) => _SkeletonTile(),
      ),
    );
  }
}

/// A single skeleton row: circle avatar + two text lines.
class _SkeletonTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, circle: true),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140.w, height: 13.h, radius: 6),
                SizedBox(height: 8.h),
                SkeletonBox(width: double.infinity, height: 10.h, radius: 5),
                SizedBox(height: 6.h),
                SkeletonBox(width: 90.w, height: 10.h, radius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering skeleton 2-column grid of product-style cards.
class SkeletonCardGrid extends StatelessWidget {
  const SkeletonCardGrid({
    super.key,
    this.itemCount = 6,
    this.aspectRatio = 0.62,
    this.padding,
  });

  final int itemCount;
  final double aspectRatio;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => _SkeletonCard(),
      ),
    );
  }
}

/// A single skeleton product card: image block + title + price lines.
/// Pass [width] when placing it inside a horizontal (unbounded-width) list.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(color: const Color(0xFFECEFF3)),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 12.h, radius: 6),
                  SizedBox(height: 6.h),
                  SkeletonBox(width: 70.w, height: 10.h, radius: 5),
                  const Spacer(),
                  SkeletonBox(width: 56.w, height: 14.h, radius: 7),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering skeleton for detail screens: hero block + text lines + tiles.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key, this.showActions = false});

  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        children: [
          // Hero block
          Container(
            width: double.infinity,
            height: 220.h,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(18.r),
            ),
          ),
          SizedBox(height: 16.h),
          SkeletonBox(width: 200.w, height: 20.h, radius: 8),
          SizedBox(height: 10.h),
          SkeletonBox(width: 120.w, height: 14.h, radius: 6),
          SizedBox(height: 16.h),
          SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
          SizedBox(height: 8.h),
          SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
          SizedBox(height: 8.h),
          SkeletonBox(width: 220.w, height: 12.h, radius: 5),
          SizedBox(height: 20.h),
          // Two stat tiles
          Row(
            children: [
              Expanded(child: _SkeletonStatTile()),
              SizedBox(width: 12.w),
              Expanded(child: _SkeletonStatTile()),
            ],
          ),
          SizedBox(height: 20.h),
          SkeletonBox(width: double.infinity, height: 48.h, radius: 14),
          if (showActions) ...[
            SizedBox(height: 12.h),
            SkeletonBox(width: double.infinity, height: 48.h, radius: 14),
          ],
        ],
      ),
    );
  }
}

class _SkeletonStatTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 28, height: 28, circle: true),
          SizedBox(height: 10.h),
          SkeletonBox(width: 90.w, height: 16.h, radius: 7),
          SizedBox(height: 6.h),
          SkeletonBox(width: 60.w, height: 10.h, radius: 5),
        ],
      ),
    );
  }
}

/// Shimmering skeleton for profile screens: avatar + name lines + menu rows.
class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        children: [
          // Avatar + name block
          Center(
            child: Column(
              children: [
                const SkeletonBox(width: 84, height: 84, circle: true),
                SizedBox(height: 12.h),
                SkeletonBox(width: 150.w, height: 16.h, radius: 8),
                SizedBox(height: 8.h),
                SkeletonBox(width: 110.w, height: 11.h, radius: 5),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          ...List.generate(
            itemCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _SkeletonTile(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering skeleton for cart screens: big item rows + summary panel.
class SkeletonCart extends StatelessWidget {
  const SkeletonCart({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: itemCount,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (_, _) => _SkeletonCartItem(),
            ),
          ),
          // Summary panel
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              children: [
                SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
                SizedBox(height: 10.h),
                SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
                SizedBox(height: 10.h),
                SkeletonBox(width: double.infinity, height: 12.h, radius: 5),
                SizedBox(height: 14.h),
                SkeletonBox(width: double.infinity, height: 46.h, radius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCartItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFF1F3F7), width: 1.r),
      ),
      child: Row(
        children: [
          // Product image block
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120.w, height: 13.h, radius: 6),
                SizedBox(height: 8.h),
                SkeletonBox(width: double.infinity, height: 10.h, radius: 5),
                SizedBox(height: 8.h),
                SkeletonBox(width: 80.w, height: 14.h, radius: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmering skeleton for chat/support screens: alternating message bubbles.
class SkeletonChat extends StatelessWidget {
  const SkeletonChat({super.key, this.bubbleCount = 8});

  final int bubbleCount;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        itemCount: bubbleCount,
        separatorBuilder: (_, _) => SizedBox(height: 10.h),
        itemBuilder: (context, index) {
          final isMe = index.isOdd;
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.72,
              height: 36.h,
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shimmering skeleton for the Home tab: top app bar, mobile header banner,
/// category navigation tabs bar, and product rail.
class SkeletonHome extends StatelessWidget {
  const SkeletonHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 8.h, bottom: 20.h),
        children: [
          // Top Header Card (Logo, Icons, Search)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: const Color(0xFFECEFF3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 80.w, height: 26.h, radius: 6),
                    const Spacer(),
                    const SkeletonBox(width: 24, height: 24, circle: true),
                    SizedBox(width: 12.w),
                    const SkeletonBox(width: 24, height: 24, circle: true),
                    SizedBox(width: 12.w),
                    SkeletonBox(width: 38.w, height: 22.h, radius: 8),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F8),
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Category Mobile Header Banner Shimmer Block
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            height: 220.h,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),

          SizedBox(height: 12.h),

          // Category Navigation Bar Shimmer Block
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFECEFF3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                5,
                (index) => Column(
                  children: [
                    const SkeletonBox(width: 44, height: 44, circle: true),
                    SizedBox(height: 6.h),
                    SkeletonBox(width: 42.w, height: 9.h, radius: 4),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Section header 1
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 170.w, height: 16.h, radius: 7),
                SkeletonBox(width: 48.w, height: 12.h, radius: 5),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Product rail 1
          SizedBox(
            height: 240.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: 3,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (_, _) => _SkeletonCard(width: 160.w),
            ),
          ),

          SizedBox(height: 22.h),

          // Section header 2
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 150.w, height: 16.h, radius: 7),
                SkeletonBox(width: 48.w, height: 12.h, radius: 5),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Product rail 2
          SizedBox(
            height: 240.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: 3,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (_, _) => _SkeletonCard(width: 160.w),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard skeleton layout for the Categories grid screen:
/// header row + 2-column grid of tinted category cards.
class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          // Header: title block + circular search chip
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 130.w, height: 22.h, radius: 6),
                      SizedBox(height: 8.h),
                      SkeletonBox(width: 170.w, height: 12.h, radius: 6),
                    ],
                  ),
                ),
                const SkeletonBox(width: 40, height: 40, circle: true),
              ],
            ),
          ),
          // Grid of cards
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.32,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF3),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 90.w, height: 14.h, radius: 6),
                      SizedBox(height: 8.h),
                      SkeletonBox(width: 60.w, height: 14.h, radius: 6),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonBox(width: 56.w, height: 18.h, radius: 9),
                          const SkeletonBox(
                            width: 24,
                            height: 24,
                            circle: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard skeleton layout for the Category Products screen:
/// sidebar list + filter pills + 2-column product grid.
class CategoryProductsSkeleton extends StatelessWidget {
  const CategoryProductsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar placeholders
          Container(
            width: 84.w,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Color(0xFFF1F5F9), width: 1),
              ),
            ),
            child: Column(
              children: List.generate(6, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                  child: Column(
                    children: [
                      const SkeletonBox(width: 38, height: 38, circle: true),
                      SizedBox(height: 6.h),
                      SkeletonBox(width: 52.w, height: 9.h, radius: 4),
                    ],
                  ),
                );
              }),
            ),
          ),
          // Main area: pills + product grid
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
                  child: Row(
                    children: [
                      SkeletonBox(width: 84.w, height: 32.h, radius: 12),
                      SizedBox(width: 8.w),
                      SkeletonBox(width: 76.w, height: 32.h, radius: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 20.h),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                        ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF3),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.all(10.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(
                              width: double.infinity,
                              height: 90.h,
                              radius: 12,
                            ),
                            SizedBox(height: 10.h),
                            SkeletonBox(width: 70.w, height: 12.h, radius: 6),
                            SizedBox(height: 6.h),
                            SkeletonBox(width: 48.w, height: 10.h, radius: 5),
                            const Spacer(),
                            SkeletonBox(width: 64.w, height: 14.h, radius: 7),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
