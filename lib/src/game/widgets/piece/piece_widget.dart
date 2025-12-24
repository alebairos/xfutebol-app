import 'package:flutter/material.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';
import 'piece_set.dart';

/// Renders a single game piece.
/// 
/// Supports two rendering modes:
/// 1. Simple mode (default): Painted circles with role abbreviation
/// 2. Asset mode: Uses images from PieceAssets (for Clash Royale-style later)
/// 
/// Inspired by Lichess PieceWidget pattern.
class PieceWidget extends StatelessWidget {
  const PieceWidget({
    super.key,
    required this.piece,
    required this.size,
    this.pieceAssets,
    this.opacity,
    this.showBallIndicator = true,
  });

  /// The piece data to display
  final PieceView piece;

  /// Size of the piece widget (square)
  final double size;

  /// Optional piece assets for image-based rendering
  /// If null, uses simple painted rendering
  final PieceAssets? pieceAssets;

  /// Optional opacity animation for fade effects
  final Animation<double>? opacity;

  /// Whether to show the ball indicator on this piece
  final bool showBallIndicator;

  @override
  Widget build(BuildContext context) {
    final kind = PieceKindExtension.from(piece.team, piece.role);

    Widget pieceWidget;

    // Choose rendering mode based on whether assets are provided
    if (pieceAssets != null && pieceAssets!.containsKey(kind)) {
      // Asset-based rendering (future Clash Royale style)
      pieceWidget = _AssetPiece(
        asset: pieceAssets![kind]!,
        size: size,
      );
    } else {
      // Simple painted rendering (current)
      pieceWidget = _SimplePiece(
        team: piece.team,
        role: piece.role,
        size: size,
      );
    }

    // Add ball indicator if piece has ball
    if (showBallIndicator && piece.hasBall) {
      pieceWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          pieceWidget,
          Positioned(
            right: -size * 0.05,
            bottom: -size * 0.05,
            child: _BallIndicator(size: size * 0.4),
          ),
        ],
      );
    }

    // Apply opacity animation if provided
    if (opacity != null) {
      return AnimatedBuilder(
        animation: opacity!,
        builder: (context, child) => Opacity(
          opacity: opacity!.value,
          child: child,
        ),
        child: SizedBox.square(dimension: size, child: pieceWidget),
      );
    }

    return SizedBox.square(dimension: size, child: pieceWidget);
  }
}

/// Simple painted piece - circles with role text
/// Used for quick prototyping without image assets
class _SimplePiece extends StatelessWidget {
  const _SimplePiece({
    required this.team,
    required this.role,
    required this.size,
  });

  final Team team;
  final PieceRole role;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isWhite = team == Team.white;

    return Container(
      width: size * 0.85,
      height: size * 0.85,
      margin: EdgeInsets.all(size * 0.075),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : const Color(0xFF2D2D2D),
        shape: BoxShape.circle,
        border: Border.all(
          color: isWhite ? Colors.grey.shade400 : Colors.grey.shade700,
          width: size * 0.04,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77), // 0.3 * 255 ≈ 77
            blurRadius: size * 0.1,
            offset: Offset(size * 0.03, size * 0.05),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _roleAbbreviation,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.bold,
            color: isWhite ? Colors.grey.shade800 : Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  String get _roleAbbreviation {
    switch (role) {
      case PieceRole.goalkeeper:
        return 'GK';
      case PieceRole.defender:
        return 'DF';
      case PieceRole.midfielder:
        return 'MF';
      case PieceRole.attacker:
        return 'FW';
    }
  }
}

/// Asset-based piece rendering
/// For future Clash Royale-style character sprites
class _AssetPiece extends StatelessWidget {
  const _AssetPiece({
    required this.asset,
    required this.size,
  });

  final AssetImage asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Preload for smooth rendering (like Lichess)
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Fallback to simple rendering if asset fails to load
        return _SimplePiece(
          team: Team.white, // Default, will be overridden in actual use
          role: PieceRole.midfielder,
          size: size,
        );
      },
    );
  }
}

/// Ball indicator overlay
class _BallIndicator extends StatelessWidget {
  const _BallIndicator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Soccer ball look: white with black pentagon pattern (simplified)
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black87,
          width: size * 0.08,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(102), // 0.4 * 255 ≈ 102
            blurRadius: size * 0.2,
            offset: Offset(size * 0.05, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SoccerBallPainter(),
      ),
    );
  }
}

/// Simple soccer ball pattern painter
class _SoccerBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.2;

    // Simple pentagon in center (simplified soccer ball look)
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

