import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'constants.dart';

/// Renders the exact FitNepal Heart + Active Person + Green Leaves emblem
/// from the Welcome screen mockup.
class FitNepalHeartLogo extends StatelessWidget {
  final double size;

  const FitNepalHeartLogo({super.key, this.size = 112});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FitNepalHeartLogoPainter(),
      ),
    );
  }
}

class _FitNepalHeartLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Two fresh green leaves at the top center
    final leftLeafPaint = Paint()
      ..color = const Color(0xFF39B54A)
      ..style = PaintingStyle.fill;
    final rightLeafPaint = Paint()
      ..color = const Color(0xFF58C947)
      ..style = PaintingStyle.fill;

    final leftLeaf = Path()
      ..moveTo(w * 0.49, h * 0.22)
      ..quadraticBezierTo(w * 0.34, h * 0.16, w * 0.36, h * 0.04)
      ..quadraticBezierTo(w * 0.48, h * 0.06, w * 0.49, h * 0.22)
      ..close();
    canvas.drawPath(leftLeaf, leftLeafPaint);

    final rightLeaf = Path()
      ..moveTo(w * 0.51, h * 0.22)
      ..quadraticBezierTo(w * 0.53, h * 0.05, w * 0.67, h * 0.03)
      ..quadraticBezierTo(w * 0.66, h * 0.17, w * 0.51, h * 0.22)
      ..close();
    canvas.drawPath(rightLeaf, rightLeafPaint);

    // 2. Berry-red Heart body
    final heartPath = Path()
      ..moveTo(w * 0.50, h * 0.92)
      ..cubicTo(w * 0.14, h * 0.70, w * 0.08, h * 0.40, w * 0.26, h * 0.27)
      ..cubicTo(w * 0.37, h * 0.20, w * 0.46, h * 0.26, w * 0.50, h * 0.34)
      ..cubicTo(w * 0.54, h * 0.26, w * 0.63, h * 0.20, w * 0.74, h * 0.27)
      ..cubicTo(w * 0.92, h * 0.40, w * 0.86, h * 0.70, w * 0.50, h * 0.92)
      ..close();

    final heartPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE62958),
          Color(0xFFC81340),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.2, w, h * 0.75));

    canvas.drawShadow(heartPath, const Color(0x55D91F4D), 12, true);
    canvas.drawPath(heartPath, heartPaint);

    // 3. White celebratory person silhouette inside the heart
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Head circle
    canvas.drawCircle(Offset(w * 0.50, h * 0.46), w * 0.068, whitePaint);

    // Swooping arms + torso V-shape
    final figurePath = Path()
      ..moveTo(w * 0.29, h * 0.39)
      ..quadraticBezierTo(w * 0.42, h * 0.52, w * 0.50, h * 0.56)
      ..quadraticBezierTo(w * 0.58, h * 0.52, w * 0.71, h * 0.39)
      ..quadraticBezierTo(w * 0.62, h * 0.57, w * 0.54, h * 0.68)
      ..lineTo(w * 0.50, h * 0.86)
      ..lineTo(w * 0.46, h * 0.68)
      ..quadraticBezierTo(w * 0.38, h * 0.57, w * 0.29, h * 0.39)
      ..close();
    canvas.drawPath(figurePath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders the Himalayan peaks, mist, birds, and Nepali multi-tiered Pagoda
/// temples from the Welcome screen mockup.
class NepalMountainPagodaArtwork extends StatelessWidget {
  final double height;

  const NepalMountainPagodaArtwork({super.key, this.height = 380});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _NepalMountainPagodaPainter(),
      ),
    );
  }
}

class _NepalMountainPagodaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Distant Himalayan snow peaks (soft rose/blush)
    final farMountain = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.30, h * 0.42)
      ..lineTo(w * 0.52, h * 0.12)
      ..lineTo(w * 0.68, h * 0.34)
      ..lineTo(w * 0.84, h * 0.20)
      ..lineTo(w, h * 0.40)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      farMountain,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF6BACB),
            Color(0xFFFCE2EA),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.1, w, h * 0.6)),
    );

    // Sunlit snow highlights on main peak
    final peakHighlight = Path()
      ..moveTo(w * 0.52, h * 0.12)
      ..lineTo(w * 0.43, h * 0.27)
      ..lineTo(w * 0.48, h * 0.25)
      ..lineTo(w * 0.51, h * 0.31)
      ..lineTo(w * 0.55, h * 0.23)
      ..close();
    canvas.drawPath(
      peakHighlight,
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    // Midground crimson ridge
    final midRidge = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.18, h * 0.44, w * 0.38, h * 0.53)
      ..quadraticBezierTo(w * 0.58, h * 0.40, w * 0.78, h * 0.49)
      ..quadraticBezierTo(w * 0.90, h * 0.44, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      midRidge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE36B89),
            Color(0xFFB51E45),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.4, w, h * 0.6)),
    );

    // Soft valley mist band
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.48, w, h * 0.14),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            const Color(0xFFFFEBF1).withOpacity(0.55),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.48, w, h * 0.14)),
    );

    // Small flying birds in the sky
    final birdPaint = Paint()
      ..color = const Color(0xFFC43A5E).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    _drawBird(canvas, Offset(w * 0.24, h * 0.18), 7, birdPaint);
    _drawBird(canvas, Offset(w * 0.29, h * 0.15), 5, birdPaint);
    _drawBird(canvas, Offset(w * 0.76, h * 0.13), 7, birdPaint);
    _drawBird(canvas, Offset(w * 0.83, h * 0.16), 6, birdPaint);

    // Foreground dark crimson hills & pagoda silhouettes
    final darkSilhouette = const Color(0xFF6B0922);
    final deeperBase = const Color(0xFF4F0518);

    // Left secondary Pagoda temple (smaller, 3 tiers)
    _drawPagoda(
      canvas,
      centerX: w * 0.50,
      baseY: h * 0.64,
      width: w * 0.22,
      tiers: 3,
      color: const Color(0xFF8C1130),
    );

    // Right Hero Pagoda temple (larger, 4 tiers matching mockup right side)
    _drawPagoda(
      canvas,
      centerX: w * 0.78,
      baseY: h * 0.66,
      width: w * 0.36,
      tiers: 4,
      color: darkSilhouette,
    );

    // Bottom deep crimson slope holding the Get Started button
    final foregroundHill = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.28, h * 0.55, w * 0.56, h * 0.63)
      ..quadraticBezierTo(w * 0.80, h * 0.68, w, h * 0.61)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      foregroundHill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            darkSilhouette,
            deeperBase,
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.58, w, h * 0.42)),
    );
  }

  void _drawBird(Canvas canvas, Offset center, double span, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - span, center.dy)
      ..quadraticBezierTo(
          center.dx - span * 0.4, center.dy - span * 0.5, center.dx, center.dy)
      ..quadraticBezierTo(center.dx + span * 0.4, center.dy - span * 0.5,
          center.dx + span, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawPagoda(
    Canvas canvas, {
    required double centerX,
    required double baseY,
    required double width,
    required int tiers,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double currentY = baseY;
    double currentW = width;
    final tierHeight = width * 0.17;

    for (var i = 0; i < tiers; i++) {
      // Inner wall pillar
      final wallW = currentW * 0.58;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerX, currentY - tierHeight * 0.35),
          width: wallW,
          height: tierHeight * 0.7,
        ),
        paint,
      );

      // Sweeping upturned Nepali pagoda roof
      final roofTopY = currentY - tierHeight;
      final roofBottomY = currentY - tierHeight * 0.32;
      final halfW = currentW * 0.5;
      final topHalfW = currentW * 0.28;

      final roofPath = Path()
        ..moveTo(centerX - topHalfW, roofTopY)
        ..lineTo(centerX + topHalfW, roofTopY)
        ..quadraticBezierTo(
          centerX + halfW * 0.85,
          roofBottomY,
          centerX + halfW * 1.08,
          roofBottomY - 4,
        )
        ..lineTo(centerX + halfW * 0.96, roofBottomY + 4)
        ..lineTo(centerX - halfW * 0.96, roofBottomY + 4)
        ..lineTo(centerX - halfW * 1.08, roofBottomY - 4)
        ..quadraticBezierTo(
          centerX - halfW * 0.85,
          roofBottomY,
          centerX - topHalfW,
          roofTopY,
        )
        ..close();

      canvas.drawPath(roofPath, paint);

      currentY -= tierHeight * 0.85;
      currentW *= 0.78;
    }

    // Golden/crimson Gajur spire at top of pagoda
    final spirePath = Path()
      ..moveTo(centerX - 3, currentY)
      ..lineTo(centerX, currentY - width * 0.18)
      ..lineTo(centerX + 3, currentY)
      ..close();
    canvas.drawPath(spirePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders the user's profile avatar (either their custom photo from app-private
/// storage or a realistic vector portrait matching Rahul Shah in the mockup).
class UserAvatarWidget extends StatelessWidget {
  final String? avatarPath;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatarWidget({
    super.key,
    this.avatarPath,
    this.radius = 24,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidFile =
        avatarPath != null && avatarPath!.isNotEmpty && File(avatarPath!).existsSync();

    final avatarContent = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: radius > 35 ? 3.5 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: FitNepalColors.deepPlum.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasValidFile
            ? Image.file(
                File(avatarPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _DefaultRahulPortrait(
                  size: radius * 2,
                ),
              )
            : _DefaultRahulPortrait(size: radius * 2),
      ),
    );

    if (!showEditBadge && onTap == null) return avatarContent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: onTap != null,
        label: 'Profile photo',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatarContent,
            if (showEditBadge)
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: math.max(26, radius * 0.52),
                  height: math.max(26, radius * 0.52),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: FitNepalColors.roseBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: math.max(14, radius * 0.28),
                    color: FitNepalColors.berryRed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DefaultRahulPortrait extends StatelessWidget {
  final double size;

  const _DefaultRahulPortrait({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RahulPortraitPainter(),
    );
  }
}

class _RahulPortraitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft cool studio portrait background matching the mockup
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD5DCE6),
            Color(0xFFB8C3D4),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Shoulders / Collar shirt
    final shirtPath = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(w * 0.22, h * 0.72, w * 0.50, h * 0.72)
      ..quadraticBezierTo(w * 0.78, h * 0.72, w * 0.88, h)
      ..close();
    canvas.drawPath(
      shirtPath,
      Paint()..color = const Color(0xFF28558A),
    );

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.68),
          width: w * 0.22,
          height: h * 0.18,
        ),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = const Color(0xFFD99B72),
    );

    // Head / Face
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.44),
        width: w * 0.42,
        height: h * 0.48,
      ),
      Paint()..color = const Color(0xFFE5A981),
    );

    // Hair (styled dark hair)
    final hairPath = Path()
      ..moveTo(w * 0.28, h * 0.42)
      ..quadraticBezierTo(w * 0.26, h * 0.16, w * 0.50, h * 0.16)
      ..quadraticBezierTo(w * 0.74, h * 0.16, w * 0.72, h * 0.42)
      ..quadraticBezierTo(w * 0.66, h * 0.27, w * 0.50, h * 0.27)
      ..quadraticBezierTo(w * 0.34, h * 0.27, w * 0.28, h * 0.42)
      ..close();
    canvas.drawPath(hairPath, Paint()..color = const Color(0xFF1D181A));

    // Neat beard & mustache matching Rahul Shah in mockup
    final beardPath = Path()
      ..moveTo(w * 0.30, h * 0.46)
      ..quadraticBezierTo(w * 0.32, h * 0.68, w * 0.50, h * 0.69)
      ..quadraticBezierTo(w * 0.68, h * 0.68, w * 0.70, h * 0.46)
      ..quadraticBezierTo(w * 0.64, h * 0.58, w * 0.50, h * 0.58)
      ..quadraticBezierTo(w * 0.36, h * 0.58, w * 0.30, h * 0.46)
      ..close();
    canvas.drawPath(beardPath, Paint()..color = const Color(0xFF231D20));

    // Warm smile
    final smilePath = Path()
      ..moveTo(w * 0.42, h * 0.55)
      ..quadraticBezierTo(w * 0.50, h * 0.61, w * 0.58, h * 0.55)
      ..close();
    canvas.drawPath(smilePath, Paint()..color = Colors.white);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1F191C);
    canvas.drawCircle(Offset(w * 0.41, h * 0.42), w * 0.025, eyePaint);
    canvas.drawCircle(Offset(w * 0.59, h * 0.42), w * 0.025, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Renders rich, colorful circular food illustrations for every starter &
/// Nepali dish in the catalogue, or loads a custom user photo from disk.
class FoodArtworkThumbnail extends StatelessWidget {
  final String? imageAssetPath;
  final String category;
  final double size;

  const FoodArtworkThumbnail({
    super.key,
    required this.imageAssetPath,
    required this.category,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    final key = (imageAssetPath ?? '').trim();
    final isLocalFile = key.startsWith('/') && File(key).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF9EFF3),
        border: Border.all(
          color: FitNepalColors.roseBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: FitNepalColors.deepPlum.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: isLocalFile
            ? Image.file(
                File(key),
                fit: BoxFit.cover,
              )
            : CustomPaint(
                size: Size(size, size),
                painter: _FoodIllustrationPainter(
                  foodKey: key.isEmpty ? category.toLowerCase() : key,
                ),
              ),
      ),
    );
  }
}

class _FoodIllustrationPainter extends CustomPainter {
  final String foodKey;

  _FoodIllustrationPainter({required this.foodKey});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    switch (foodKey) {
      case 'apple':
        // Soft studio backdrop
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = const Color(0xFFF6F6F8),
        );
        // Glossy crimson apple body
        final applePath = Path()
          ..moveTo(w * 0.50, h * 0.84)
          ..cubicTo(w * 0.20, h * 0.84, w * 0.16, h * 0.36, w * 0.38, h * 0.30)
          ..quadraticBezierTo(w * 0.50, h * 0.35, w * 0.62, h * 0.30)
          ..cubicTo(w * 0.84, h * 0.36, w * 0.80, h * 0.84, w * 0.50, h * 0.84)
          ..close();
        canvas.drawPath(
          applePath,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.3, -0.3),
              radius: 0.85,
              colors: [Color(0xFFFF4B5C), Color(0xFFB50E29)],
            ).createShader(Rect.fromLTWH(0, 0, w, h)),
        );
        // Stem & green leaf
        canvas.drawLine(
          Offset(w * 0.50, h * 0.32),
          Offset(w * 0.52, h * 0.18),
          Paint()
            ..color = const Color(0xFF5D3A1A)
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round,
        );
        final leaf = Path()
          ..moveTo(w * 0.51, h * 0.24)
          ..quadraticBezierTo(w * 0.68, h * 0.14, w * 0.72, h * 0.26)
          ..quadraticBezierTo(w * 0.60, h * 0.32, w * 0.51, h * 0.24)
          ..close();
        canvas.drawPath(leaf, Paint()..color = const Color(0xFF4CAF50));
        break;

      case 'banana':
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = const Color(0xFFFFFBF0),
        );
        final bananaPaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFE042), Color(0xFFF4B400)],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
        final b1 = Path()
          ..moveTo(w * 0.22, h * 0.68)
          ..quadraticBezierTo(w * 0.52, h * 0.82, w * 0.80, h * 0.32)
          ..quadraticBezierTo(w * 0.72, h * 0.24, w * 0.68, h * 0.26)
          ..quadraticBezierTo(w * 0.46, h * 0.62, w * 0.20, h * 0.58)
          ..close();
        final b2 = Path()
          ..moveTo(w * 0.18, h * 0.55)
          ..quadraticBezierTo(w * 0.45, h * 0.70, w * 0.72, h * 0.24)
          ..quadraticBezierTo(w * 0.65, h * 0.18, w * 0.60, h * 0.22)
          ..quadraticBezierTo(w * 0.40, h * 0.52, w * 0.18, h * 0.46)
          ..close();
        canvas.drawPath(b2, Paint()..color = const Color(0xFFFBC02D));
        canvas.drawPath(b1, bananaPaint);
        break;

      case 'dal_bhat':
        // Brass/steel Nepali Thali plate
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = const Color(0xFFF3ECE7),
        );
        canvas.drawCircle(
          center,
          w * 0.42,
          Paint()..color = const Color(0xFF8C7A6B),
        );
        canvas.drawCircle(
          center,
          w * 0.38,
          Paint()..color = const Color(0xFFD7CCC8),
        );
        // Fluffy white rice mound
        canvas.drawCircle(
          Offset(w * 0.44, h * 0.54),
          w * 0.19,
          Paint()..color = Colors.white,
        );
        // Golden Dal bowl
        canvas.drawCircle(
          Offset(w * 0.65, h * 0.36),
          w * 0.11,
          Paint()..color = const Color(0xFFE68A00),
        );
        // Green Saag & Tarkari
        canvas.drawCircle(
          Offset(w * 0.34, h * 0.32),
          w * 0.09,
          Paint()..color = const Color(0xFF388E3C),
        );
        canvas.drawCircle(
          Offset(w * 0.66, h * 0.62),
          w * 0.09,
          Paint()..color = const Color(0xFFD84315),
        );
        break;

      case 'chicken_curry':
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = const Color(0xFFFFF3E0),
        );
        // Bowl rim
        canvas.drawCircle(
          center,
          w * 0.42,
          Paint()..color = const Color(0xFFE0E0E0),
        );
        // Rich spiced orange-red curry gravy
        canvas.drawCircle(
          center,
          w * 0.36,
          Paint()
            ..shader = const RadialGradient(
              colors: [Color(0xFFE65100), Color(0xFFB71C1C)],
            ).createShader(Rect.fromCircle(center: center, radius: w * 0.36)),
        );
        // Chicken pieces & coriander garnish
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * 0.42, h * 0.44),
                width: w * 0.18,
                height: h * 0.14),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFFFFCC80),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * 0.60, h * 0.56),
                width: w * 0.17,
                height: h * 0.13),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFFFFB74D),
        );
        canvas.drawCircle(
          Offset(w * 0.50, h * 0.50),
          w * 0.05,
          Paint()..color = const Color(0xFF43A047),
        );
        break;

      case 'veg_salad':
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = const Color(0xFFF1F8E9),
        );
        canvas.drawCircle(center, w * 0.42, Paint()..color = Colors.white);
        canvas.drawCircle(
          center,
          w * 0.35,
          Paint()..color = const Color(0xFF66BB6A),
        );
        // Cherry tomatoes, cucumber, corn
        canvas.drawCircle(
          Offset(w * 0.38, h * 0.42),
          w * 0.08,
          Paint()..color = const Color(0xFFE53935),
        );
        canvas.drawCircle(
          Offset(w * 0.60, h * 0.56),
          w * 0.08,
          Paint()..color = const Color(0xFFE53935),
        );
        canvas.drawCircle(
          Offset(w * 0.58, h * 0.38),
          w * 0.07,
          Paint()..color = const Color(0xFFFFCA28),
        );
        canvas.drawCircle(
          Offset(w * 0.42, h * 0.60),
          w * 0.07,
          Paint()..color = const Color(0xFF2E7D32),
        );
        break;

      default:
        // Warm Nepali platter motif for momo, roti, milk, chiya, etc.
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h),
          Paint()..color = const Color(0xFFFDECEF),
        );
        canvas.drawCircle(
          center,
          w * 0.36,
          Paint()
            ..shader = const LinearGradient(
              colors: [FitNepalColors.berryLight, FitNepalColors.berryRed],
            ).createShader(Rect.fromLTWH(0, 0, w, h)),
        );
        canvas.drawCircle(
          center,
          w * 0.18,
          Paint()..color = Colors.white.withOpacity(0.9),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _FoodIllustrationPainter oldDelegate) =>
      oldDelegate.foodKey != foodKey;
}
