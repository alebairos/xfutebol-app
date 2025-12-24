//! Flutter API - Functions exposed to Dart via flutter_rust_bridge
//!
//! This module defines the public API that Flutter can call.
//! Keep this minimal and focused on what the UI needs.

use flutter_rust_bridge::frb;

// Re-export types that Flutter needs to know about
// These will be auto-generated as Dart classes

/// Game difficulty levels
#[frb]
#[derive(Debug, Clone, Copy)]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
}

/// Team colors
#[frb]
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Team {
    White,
    Black,
}

/// Piece roles
#[frb]
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum PieceRole {
    Goalkeeper,
    Defender,
    Midfielder,
    Attacker,
}

/// A position on the board (0-7 for row and col)
#[frb]
#[derive(Debug, Clone, Copy)]
pub struct Position {
    pub row: u8,
    pub col: u8,
}

/// A piece on the board
#[frb]
#[derive(Debug, Clone)]
pub struct PieceView {
    pub id: u8,
    pub team: Team,
    pub role: PieceRole,
    pub position: Position,
    pub has_ball: bool,
}

/// Current state of the board for display
#[frb]
#[derive(Debug, Clone)]
pub struct BoardView {
    pub pieces: Vec<PieceView>,
    pub ball_position: Option<Position>,  // If ball is loose (not held by piece)
    pub current_turn: Team,
    pub actions_remaining: u8,
    pub white_score: u8,
    pub black_score: u8,
    pub turn_number: u32,
}

/// Result of an action
#[frb]
#[derive(Debug, Clone)]
pub struct ActionResult {
    pub success: bool,
    pub message: String,
    pub game_over: bool,
    pub winner: Option<Team>,
}

/// Game mode options
#[frb]
#[derive(Debug, Clone, Copy)]
pub enum GameModeType {
    QuickMatch,      // First to score
    StandardMatch,   // 20 turns
    GoldenGoal,      // First to score, no turn limit
}

// =============================================================================
// API Functions - These are callable from Flutter
// =============================================================================

/// Create a new game with the specified mode
#[frb]
pub fn new_game(mode: GameModeType) -> String {
    // Returns a game ID (for now just a placeholder)
    // In real implementation, this would create game state
    format!("game_{:?}", mode)
}

/// Get the current board state for display
#[frb]
pub fn get_board(game_id: String) -> BoardView {
    // Placeholder - return initial board state
    let _ = game_id;
    
    // Create a sample board for testing
    let mut pieces = Vec::new();
    
    // White pieces (bottom)
    pieces.push(PieceView {
        id: 0,
        team: Team::White,
        role: PieceRole::Goalkeeper,
        position: Position { row: 0, col: 3 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 1,
        team: Team::White,
        role: PieceRole::Defender,
        position: Position { row: 1, col: 1 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 2,
        team: Team::White,
        role: PieceRole::Defender,
        position: Position { row: 1, col: 5 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 3,
        team: Team::White,
        role: PieceRole::Midfielder,
        position: Position { row: 2, col: 2 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 4,
        team: Team::White,
        role: PieceRole::Midfielder,
        position: Position { row: 2, col: 5 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 5,
        team: Team::White,
        role: PieceRole::Attacker,
        position: Position { row: 3, col: 3 },
        has_ball: true,  // Ball holder
    });
    
    // Black pieces (top)
    pieces.push(PieceView {
        id: 6,
        team: Team::Black,
        role: PieceRole::Goalkeeper,
        position: Position { row: 7, col: 4 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 7,
        team: Team::Black,
        role: PieceRole::Defender,
        position: Position { row: 6, col: 2 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 8,
        team: Team::Black,
        role: PieceRole::Defender,
        position: Position { row: 6, col: 5 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 9,
        team: Team::Black,
        role: PieceRole::Midfielder,
        position: Position { row: 5, col: 2 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 10,
        team: Team::Black,
        role: PieceRole::Midfielder,
        position: Position { row: 5, col: 5 },
        has_ball: false,
    });
    pieces.push(PieceView {
        id: 11,
        team: Team::Black,
        role: PieceRole::Attacker,
        position: Position { row: 4, col: 4 },
        has_ball: false,
    });
    
    BoardView {
        pieces,
        ball_position: None,  // Ball is held by piece id 5
        current_turn: Team::White,
        actions_remaining: 2,
        white_score: 0,
        black_score: 0,
        turn_number: 1,
    }
}

/// Get legal moves for a specific piece
#[frb]
pub fn get_legal_moves(game_id: String, piece_id: u8) -> Vec<Position> {
    // Placeholder - return some valid positions
    let _ = game_id;
    let _ = piece_id;
    
    // Return a few sample positions
    vec![
        Position { row: 3, col: 4 },
        Position { row: 4, col: 3 },
        Position { row: 4, col: 4 },
    ]
}

/// Execute a move action
#[frb]
pub fn execute_move(game_id: String, piece_id: u8, to: Position) -> ActionResult {
    let _ = game_id;
    let _ = piece_id;
    let _ = to;
    
    ActionResult {
        success: true,
        message: "Move executed".to_string(),
        game_over: false,
        winner: None,
    }
}

/// Get the bot's move for the current position
#[frb]
pub fn get_bot_move(game_id: String, difficulty: Difficulty) -> Option<(u8, Position)> {
    let _ = game_id;
    let _ = difficulty;
    
    // Return a sample bot move (piece_id, destination)
    Some((7, Position { row: 5, col: 2 }))
}

/// Check if the game is over
#[frb]
pub fn is_game_over(game_id: String) -> bool {
    let _ = game_id;
    false
}

/// Get the winner (if game is over)
#[frb]
pub fn get_winner(game_id: String) -> Option<Team> {
    let _ = game_id;
    None
}

/// Simple test function to verify bridge works
#[frb]
pub fn greet(name: String) -> String {
    format!("Hello, {}! Welcome to Xfutebol!", name)
}

// =============================================================================
// Tests
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    // -------------------------------------------------------------------------
    // Game Lifecycle Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_new_game_returns_valid_id() {
        let id = new_game(GameModeType::StandardMatch);
        assert!(id.starts_with("game_"));
        assert!(id.contains("StandardMatch"));
    }

    #[test]
    fn test_new_game_different_modes_produce_different_ids() {
        let quick = new_game(GameModeType::QuickMatch);
        let standard = new_game(GameModeType::StandardMatch);
        let golden = new_game(GameModeType::GoldenGoal);

        assert!(quick.contains("QuickMatch"));
        assert!(standard.contains("StandardMatch"));
        assert!(golden.contains("GoldenGoal"));
        assert_ne!(quick, standard);
        assert_ne!(standard, golden);
    }

    // -------------------------------------------------------------------------
    // Board State Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_board_returns_12_pieces() {
        let board = get_board("test_game".to_string());
        assert_eq!(board.pieces.len(), 12);
    }

    #[test]
    fn test_get_board_correct_team_distribution() {
        let board = get_board("test_game".to_string());
        let white_count = board.pieces.iter().filter(|p| p.team == Team::White).count();
        let black_count = board.pieces.iter().filter(|p| p.team == Team::Black).count();
        assert_eq!(white_count, 6);
        assert_eq!(black_count, 6);
    }

    #[test]
    fn test_get_board_initial_turn_is_white() {
        let board = get_board("test_game".to_string());
        assert_eq!(board.current_turn, Team::White);
    }

    #[test]
    fn test_get_board_initial_score_is_zero() {
        let board = get_board("test_game".to_string());
        assert_eq!(board.white_score, 0);
        assert_eq!(board.black_score, 0);
    }

    #[test]
    fn test_get_board_initial_turn_number_is_one() {
        let board = get_board("test_game".to_string());
        assert_eq!(board.turn_number, 1);
    }

    #[test]
    fn test_get_board_has_exactly_one_ball_holder() {
        let board = get_board("test_game".to_string());
        let ball_holders: Vec<_> = board.pieces.iter().filter(|p| p.has_ball).collect();
        assert_eq!(ball_holders.len(), 1);
    }

    #[test]
    fn test_get_board_ball_holder_is_white_attacker() {
        let board = get_board("test_game".to_string());
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        assert_eq!(ball_holder.team, Team::White);
        assert_eq!(ball_holder.role, PieceRole::Attacker);
    }

    #[test]
    fn test_get_board_has_two_goalkeepers() {
        let board = get_board("test_game".to_string());
        let goalkeepers: Vec<_> = board
            .pieces
            .iter()
            .filter(|p| p.role == PieceRole::Goalkeeper)
            .collect();
        assert_eq!(goalkeepers.len(), 2);
    }

    #[test]
    fn test_get_board_goalkeeper_positions() {
        let board = get_board("test_game".to_string());
        let white_gk = board
            .pieces
            .iter()
            .find(|p| p.team == Team::White && p.role == PieceRole::Goalkeeper)
            .unwrap();
        let black_gk = board
            .pieces
            .iter()
            .find(|p| p.team == Team::Black && p.role == PieceRole::Goalkeeper)
            .unwrap();

        // White goalkeeper at row 0, Black goalkeeper at row 7
        assert_eq!(white_gk.position.row, 0);
        assert_eq!(black_gk.position.row, 7);
    }

    #[test]
    fn test_get_board_piece_ids_are_unique() {
        let board = get_board("test_game".to_string());
        let mut ids: Vec<u8> = board.pieces.iter().map(|p| p.id).collect();
        ids.sort();
        ids.dedup();
        assert_eq!(ids.len(), 12);
    }

    #[test]
    fn test_get_board_actions_remaining() {
        let board = get_board("test_game".to_string());
        assert_eq!(board.actions_remaining, 2);
    }

    // -------------------------------------------------------------------------
    // Action Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_legal_moves_returns_positions() {
        let moves = get_legal_moves("test_game".to_string(), 5);
        assert!(!moves.is_empty());
    }

    #[test]
    fn test_get_legal_moves_positions_are_valid() {
        let moves = get_legal_moves("test_game".to_string(), 5);
        for pos in moves {
            assert!(pos.row < 8, "Row should be < 8");
            assert!(pos.col < 8, "Col should be < 8");
        }
    }

    #[test]
    fn test_execute_move_returns_success() {
        let result = execute_move(
            "test_game".to_string(),
            5,
            Position { row: 4, col: 3 },
        );
        assert!(result.success);
    }

    #[test]
    fn test_execute_move_not_game_over() {
        let result = execute_move(
            "test_game".to_string(),
            5,
            Position { row: 4, col: 3 },
        );
        assert!(!result.game_over);
    }

    #[test]
    fn test_execute_move_message_not_empty() {
        let result = execute_move(
            "test_game".to_string(),
            5,
            Position { row: 4, col: 3 },
        );
        assert!(!result.message.is_empty());
    }

    #[test]
    fn test_execute_move_no_winner() {
        let result = execute_move(
            "test_game".to_string(),
            5,
            Position { row: 4, col: 3 },
        );
        assert!(result.winner.is_none());
    }

    // -------------------------------------------------------------------------
    // Bot AI Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_bot_move_returns_some() {
        let bot_move = get_bot_move("test_game".to_string(), Difficulty::Medium);
        assert!(bot_move.is_some());
    }

    #[test]
    fn test_get_bot_move_valid_piece_id() {
        let bot_move = get_bot_move("test_game".to_string(), Difficulty::Medium);
        let (piece_id, _pos) = bot_move.unwrap();
        assert!(piece_id < 12, "Piece ID should be < 12");
    }

    #[test]
    fn test_get_bot_move_valid_position() {
        let bot_move = get_bot_move("test_game".to_string(), Difficulty::Medium);
        let (_piece_id, pos) = bot_move.unwrap();
        assert!(pos.row < 8, "Row should be < 8");
        assert!(pos.col < 8, "Col should be < 8");
    }

    #[test]
    fn test_get_bot_move_easy_difficulty() {
        let bot_move = get_bot_move("test_game".to_string(), Difficulty::Easy);
        assert!(bot_move.is_some());
    }

    #[test]
    fn test_get_bot_move_hard_difficulty() {
        let bot_move = get_bot_move("test_game".to_string(), Difficulty::Hard);
        assert!(bot_move.is_some());
    }

    // -------------------------------------------------------------------------
    // Game State Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_is_game_over_initially_false() {
        assert!(!is_game_over("test_game".to_string()));
    }

    #[test]
    fn test_get_winner_initially_none() {
        assert!(get_winner("test_game".to_string()).is_none());
    }

    // -------------------------------------------------------------------------
    // Utility Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_greet_includes_name() {
        let greeting = greet("Alice".to_string());
        assert!(greeting.contains("Alice"));
    }

    #[test]
    fn test_greet_includes_xfutebol() {
        let greeting = greet("Bob".to_string());
        assert!(greeting.contains("Xfutebol"));
    }

    #[test]
    fn test_greet_format() {
        let greeting = greet("Test".to_string());
        assert_eq!(greeting, "Hello, Test! Welcome to Xfutebol!");
    }
}

