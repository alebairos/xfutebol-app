import 'package:flutter/widgets.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

/// Unique identifier for a piece type (team + role combination)
/// Similar to Lichess PieceKind but for soccer
enum PieceKind {
  whiteGoalkeeper,
  whiteDefender,
  whiteMidfielder,
  whiteAttacker,
  blackGoalkeeper,
  blackDefender,
  blackMidfielder,
  blackAttacker,
}

extension PieceKindExtension on PieceKind {
  Team get team {
    switch (this) {
      case PieceKind.whiteGoalkeeper:
      case PieceKind.whiteDefender:
      case PieceKind.whiteMidfielder:
      case PieceKind.whiteAttacker:
        return Team.white;
      case PieceKind.blackGoalkeeper:
      case PieceKind.blackDefender:
      case PieceKind.blackMidfielder:
      case PieceKind.blackAttacker:
        return Team.black;
    }
  }

  PieceRole get role {
    switch (this) {
      case PieceKind.whiteGoalkeeper:
      case PieceKind.blackGoalkeeper:
        return PieceRole.goalkeeper;
      case PieceKind.whiteDefender:
      case PieceKind.blackDefender:
        return PieceRole.defender;
      case PieceKind.whiteMidfielder:
      case PieceKind.blackMidfielder:
        return PieceRole.midfielder;
      case PieceKind.whiteAttacker:
      case PieceKind.blackAttacker:
        return PieceRole.attacker;
    }
  }

  static PieceKind from(Team team, PieceRole role) {
    switch (team) {
      case Team.white:
        switch (role) {
          case PieceRole.goalkeeper:
            return PieceKind.whiteGoalkeeper;
          case PieceRole.defender:
            return PieceKind.whiteDefender;
          case PieceRole.midfielder:
            return PieceKind.whiteMidfielder;
          case PieceRole.attacker:
            return PieceKind.whiteAttacker;
        }
      case Team.black:
        switch (role) {
          case PieceRole.goalkeeper:
            return PieceKind.blackGoalkeeper;
          case PieceRole.defender:
            return PieceKind.blackDefender;
          case PieceRole.midfielder:
            return PieceKind.blackMidfielder;
          case PieceRole.attacker:
            return PieceKind.blackAttacker;
        }
    }
  }
}

/// Map of piece assets for a complete piece set
/// Similar to Lichess PieceAssets
typedef PieceAssets = Map<PieceKind, AssetImage>;

/// A piece set with a label and its assets
/// Similar to Lichess PieceSet enum
enum PieceSet {
  /// Simple circles with role text - no images needed
  simple('Simple', null),

  /// Placeholder for future Clash Royale-style sprites
  // clashStyle('Clash Style', PieceSet.clashAssets),
  ;

  const PieceSet(this.label, this.assets);

  final String label;
  final PieceAssets? assets;

  /// Returns true if this set uses image assets
  bool get usesAssets => assets != null;

  // Future: Add asset maps here when images are available
  // static const PieceAssets clashAssets = {
  //   PieceKind.whiteGoalkeeper: AssetImage('assets/pieces/clash/wGK.png'),
  //   PieceKind.whiteDefender: AssetImage('assets/pieces/clash/wDF.png'),
  //   ...
  // };
}

/// Asset path helper for future image-based piece sets
const String _pieceSetsPath = 'assets/pieces';

/// Generate asset path for a piece
String pieceAssetPath(String setName, PieceKind kind) {
  final teamPrefix = kind.team == Team.white ? 'w' : 'b';
  final roleCode = switch (kind.role) {
    PieceRole.goalkeeper => 'GK',
    PieceRole.defender => 'DF',
    PieceRole.midfielder => 'MF',
    PieceRole.attacker => 'FW',
  };
  return '$_pieceSetsPath/$setName/$teamPrefix$roleCode.png';
}

