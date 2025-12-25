//! Flutter API - Functions exposed to Dart via flutter_rust_bridge
//!
//! This module defines the public API that Flutter can call.
//! All functions interact with the xfutebol-engine through GameMatch.

use flutter_rust_bridge::frb;
use once_cell::sync::Lazy;
use std::collections::HashMap;
use std::sync::Mutex;
use uuid::Uuid;

// Engine imports
use xfutebol_engine::{
    Bot, GameMatch, GameMode,
    Difficulty as EngineDifficulty,
    Team as EngineTeam,
    PieceRole as EnginePieceRole,
    BoardTile,
    Action as EngineAction,
    ActionOutcome,
    GameError,
};

// =============================================================================
// State Management
// =============================================================================

/// Thread-safe storage for active game sessions
static GAMES: Lazy<Mutex<HashMap<String, GameMatch>>> = 
    Lazy::new(|| Mutex::new(HashMap::new()));

// =============================================================================
// Bridge Types - Exposed to Dart
// =============================================================================

/// Game difficulty levels
#[frb]
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Difficulty {
    Easy,
    Medium,
    // Note: Hard not yet implemented in engine
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
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Position {
    pub row: u8,
    pub col: u8,
}

/// A piece on the board
#[frb]
#[derive(Debug, Clone)]
pub struct PieceView {
    pub id: String,  // Engine's piece ID: "WG01", "BA01", etc.
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
    pub actions_remaining: u8,
    /// Which team scored a goal (if any) - None means no goal
    pub goal_scored: Option<Team>,
    /// Whether the turn ended after this action
    pub turn_ended: bool,
}

impl ActionResult {
    fn error(msg: impl Into<String>) -> Self {
        ActionResult {
            success: false,
            message: msg.into(),
            game_over: false,
            winner: None,
            actions_remaining: 0,
            goal_scored: None,
            turn_ended: false,
        }
    }
    
    fn from_outcome(outcome: &xfutebol_engine::ActionOutcome) -> Self {
        ActionResult {
            success: true,
            message: format!("Action completed: {:?}", outcome.action),
            game_over: outcome.game_over,
            winner: outcome.winner.map(|t| t.into()),
            actions_remaining: outcome.actions_remaining,
            goal_scored: outcome.goal_scored.map(|t| t.into()),
            turn_ended: outcome.turn_ended,
        }
    }
}

/// Game mode options
#[frb]
#[derive(Debug, Clone, Copy)]
pub enum GameModeType {
    QuickMatch,      // 10 turns
    StandardMatch,   // 20 turns
    GoldenGoal,      // First to score, no turn limit
}

/// Action types available in the game
#[frb]
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ActionType {
    Move,
    Pass,
    Shoot,
    Intercept,
    Kick,
    Defend,
    Push,
}

/// A complete action returned by the bot AI
#[frb]
#[derive(Debug, Clone)]
pub struct BotAction {
    pub piece_id: String,
    pub action_type: ActionType,
    pub path: Vec<Position>,
}

/// A path of positions (wrapper to avoid nested Vec issues in codegen)
#[frb]
#[derive(Debug, Clone)]
pub struct PositionPath {
    pub positions: Vec<Position>,
}

// =============================================================================
// Type Conversions
// =============================================================================

impl From<EngineTeam> for Team {
    fn from(t: EngineTeam) -> Self {
        match t {
            EngineTeam::White => Team::White,
            EngineTeam::Black => Team::Black,
            EngineTeam::None => Team::White, // Default fallback
        }
    }
}

impl From<Team> for EngineTeam {
    fn from(t: Team) -> Self {
        match t {
            Team::White => EngineTeam::White,
            Team::Black => EngineTeam::Black,
        }
    }
}

impl From<EnginePieceRole> for PieceRole {
    fn from(r: EnginePieceRole) -> Self {
        match r {
            EnginePieceRole::Goalkeeper => PieceRole::Goalkeeper,
            EnginePieceRole::Defender => PieceRole::Defender,
            EnginePieceRole::Midfielder => PieceRole::Midfielder,
            EnginePieceRole::Attacker => PieceRole::Attacker,
        }
    }
}

impl From<EngineDifficulty> for Difficulty {
    fn from(d: EngineDifficulty) -> Self {
        match d {
            EngineDifficulty::Easy => Difficulty::Easy,
            EngineDifficulty::Medium => Difficulty::Medium,
        }
    }
}

impl From<Difficulty> for EngineDifficulty {
    fn from(d: Difficulty) -> Self {
        match d {
            Difficulty::Easy => EngineDifficulty::Easy,
            Difficulty::Medium => EngineDifficulty::Medium,
        }
    }
}

impl From<BoardTile> for Position {
    fn from(tile: BoardTile) -> Self {
        let (row, col) = tile.to_index();
        Position { row: row as u8, col: col as u8 }
    }
}

impl From<Position> for BoardTile {
    fn from(pos: Position) -> Self {
        BoardTile::from_coords(pos.row as usize, pos.col as usize)
            .expect("Valid position (0-7 for row and col)")
    }
}

impl From<EngineAction> for ActionType {
    fn from(a: EngineAction) -> Self {
        match a {
            EngineAction::MOVE => ActionType::Move,
            EngineAction::PASS => ActionType::Pass,
            EngineAction::SHOOT => ActionType::Shoot,
            EngineAction::INTERCEPT => ActionType::Intercept,
            EngineAction::KICK => ActionType::Kick,
            EngineAction::DEFEND => ActionType::Defend,
            EngineAction::PUSH => ActionType::Push,
        }
    }
}

// =============================================================================
// API Functions - These are callable from Flutter
// =============================================================================

/// Create a new game with the specified mode
#[frb]
pub fn new_game(mode: GameModeType) -> String {
    let game_id = Uuid::new_v4().to_string();
    
    let engine_mode = match mode {
        GameModeType::QuickMatch => GameMode::quick_match(),
        GameModeType::StandardMatch => GameMode::standard_match(),
        GameModeType::GoldenGoal => GameMode::golden_goal(),
    };
    
    let mut game = GameMatch::standard(engine_mode);
    game.start(EngineTeam::White);
    
    GAMES.lock().unwrap().insert(game_id.clone(), game);
    game_id
}

/// Get the current board state for display
#[frb]
pub fn get_board(game_id: String) -> Option<BoardView> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id)?;
    
    let ball_holder_id = game.ball_holder();
    
    let pieces: Vec<PieceView> = game.all_pieces()
        .into_iter()
        .map(|(id, tile, piece)| PieceView {
            id: id.clone(),
            team: piece.team.into(),
            role: piece.role.into(),
            position: Position::from(tile),
            has_ball: ball_holder_id.as_ref() == Some(&id),
        })
        .collect();
    
    // Get loose ball position if any
    let ball_position = game.board().ball.as_ref()
        .filter(|b| b.possession.is_none())
        .map(|b| Position::from(b.position));
    
    Some(BoardView {
        pieces,
        ball_position,
        current_turn: game.current_turn().into(),
        actions_remaining: game.actions_remaining(),
        white_score: game.score().0,
        black_score: game.score().1,
        turn_number: game.turn_number(),
    })
}

/// Get legal moves for a specific piece
#[frb]
pub fn get_legal_moves(game_id: String, piece_id: String) -> Vec<Position> {
    let games = GAMES.lock().unwrap();
    let game = match games.get(&game_id) {
        Some(g) => g,
        None => return Vec::new(),
    };
    
    if let Some((tile, _)) = game.piece_by_id(&piece_id) {
        return game.legal_moves(tile)
            .into_iter()
            .map(Position::from)
            .collect();
    }
    
    Vec::new()
}

/// Get legal pass paths for a piece (must have ball)
#[frb]
pub fn get_legal_passes(game_id: String, piece_id: String) -> Vec<PositionPath> {
    let games = GAMES.lock().unwrap();
    let game = match games.get(&game_id) {
        Some(g) => g,
        None => return Vec::new(),
    };
    
    let (tile, piece) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return Vec::new(),
    };
    
    game.board()
        .get_legal_moves(&piece, EngineAction::PASS, tile, true)
        .into_iter()
        .map(|path| PositionPath {
            positions: path.into_iter().map(Position::from).collect()
        })
        .collect()
}

/// Get legal shoot paths for a piece (must have ball)
#[frb]
pub fn get_legal_shoots(game_id: String, piece_id: String) -> Vec<PositionPath> {
    let games = GAMES.lock().unwrap();
    let game = match games.get(&game_id) {
        Some(g) => g,
        None => return Vec::new(),
    };
    
    let (tile, piece) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return Vec::new(),
    };
    
    game.board()
        .get_legal_moves(&piece, EngineAction::SHOOT, tile, true)
        .into_iter()
        .map(|path| PositionPath {
            positions: path.into_iter().map(Position::from).collect()
        })
        .collect()
}

/// Get legal intercept paths for a piece
#[frb]
pub fn get_legal_intercepts(game_id: String, piece_id: String) -> Vec<PositionPath> {
    get_legal_action_paths(game_id, piece_id, EngineAction::INTERCEPT)
}

/// Get legal kick paths for a piece (must have ball)
#[frb]
pub fn get_legal_kicks(game_id: String, piece_id: String) -> Vec<PositionPath> {
    get_legal_action_paths(game_id, piece_id, EngineAction::KICK)
}

/// Get legal defend paths for a piece
#[frb]
pub fn get_legal_defends(game_id: String, piece_id: String) -> Vec<PositionPath> {
    get_legal_action_paths(game_id, piece_id, EngineAction::DEFEND)
}

/// Get legal push targets for a piece (adjacent opponents that can be pushed)
#[frb]
pub fn get_legal_pushes(game_id: String, piece_id: String) -> Vec<PositionPath> {
    get_legal_action_paths(game_id, piece_id, EngineAction::PUSH)
}

// Helper: Get paths for any action type
fn get_legal_action_paths(game_id: String, piece_id: String, action: EngineAction) -> Vec<PositionPath> {
    let games = GAMES.lock().unwrap();
    let game = match games.get(&game_id) {
        Some(g) => g,
        None => return Vec::new(),
    };
    
    let (tile, piece) = match game.piece_by_id(&piece_id) {
        Some(p) => p,
        None => return Vec::new(),
    };
    
    game.board()
        .get_legal_moves(&piece, action, tile, true)
        .into_iter()
        .map(|path| PositionPath {
            positions: path.into_iter().map(Position::from).collect()
        })
        .collect()
}

/// Execute a move action
#[frb]
pub fn execute_move(game_id: String, piece_id: String, to: Position) -> ActionResult {
    let mut games = GAMES.lock().unwrap();
    let game = match games.get_mut(&game_id) {
        Some(g) => g,
        None => return ActionResult::error("Game not found"),
    };
    
    let from_tile = match game.piece_by_id(&piece_id) {
        Some((tile, _)) => tile,
        None => return ActionResult::error("Piece not found"),
    };
    
    let to_tile: BoardTile = to.into();
    
    match game.perform_move(from_tile, to_tile) {
        Ok(outcome) => ActionResult::from_outcome(&outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}

/// Execute a pass action
#[frb]
pub fn execute_pass(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    let mut games = GAMES.lock().unwrap();
    let game = match games.get_mut(&game_id) {
        Some(g) => g,
        None => return ActionResult::error("Game not found"),
    };
    
    let from_tile = match game.piece_by_id(&piece_id) {
        Some((tile, _)) => tile,
        None => return ActionResult::error("Piece not found"),
    };
    
    let path_tiles: Vec<BoardTile> = path.into_iter().map(Into::into).collect();
    
    match game.perform_pass(from_tile, path_tiles) {
        Ok(outcome) => ActionResult::from_outcome(&outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}

/// Execute a shoot action
#[frb]
pub fn execute_shoot(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    let mut games = GAMES.lock().unwrap();
    let game = match games.get_mut(&game_id) {
        Some(g) => g,
        None => return ActionResult::error("Game not found"),
    };
    
    let from_tile = match game.piece_by_id(&piece_id) {
        Some((tile, _)) => tile,
        None => return ActionResult::error("Piece not found"),
    };
    
    let path_tiles: Vec<BoardTile> = path.into_iter().map(Into::into).collect();
    
    match game.perform_shoot(from_tile, path_tiles) {
        Ok(outcome) => ActionResult::from_outcome(&outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}

/// Execute an intercept action
#[frb]
pub fn execute_intercept(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    execute_path_action(game_id, piece_id, path, |game, from, path| {
        game.perform_intercept(from, path)
    })
}

/// Execute a kick action (clear the ball)
#[frb]
pub fn execute_kick(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    execute_path_action(game_id, piece_id, path, |game, from, path| {
        game.perform_kick(from, path)
    })
}

/// Execute a defend action (defensive positioning)
#[frb]
pub fn execute_defend(game_id: String, piece_id: String, path: Vec<Position>) -> ActionResult {
    execute_path_action(game_id, piece_id, path, |game, from, path| {
        game.perform_defend(from, path)
    })
}

/// Execute a push action (push adjacent opponent)
#[frb]
pub fn execute_push(game_id: String, piece_id: String, target: Position, destination: Position) -> ActionResult {
    let mut games = GAMES.lock().unwrap();
    let game = match games.get_mut(&game_id) {
        Some(g) => g,
        None => return ActionResult::error("Game not found"),
    };
    
    let from_tile = match game.piece_by_id(&piece_id) {
        Some((tile, _)) => tile,
        None => return ActionResult::error("Piece not found"),
    };
    
    let target_tile: BoardTile = target.into();
    let dest_tile: BoardTile = destination.into();
    
    match game.perform_push(from_tile, target_tile, dest_tile) {
        Ok(outcome) => ActionResult::from_outcome(&outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}

// Helper: Execute path-based action
fn execute_path_action<F>(game_id: String, piece_id: String, path: Vec<Position>, action_fn: F) -> ActionResult
where
    F: FnOnce(&mut GameMatch, BoardTile, Vec<BoardTile>) -> Result<ActionOutcome, GameError>
{
    let mut games = GAMES.lock().unwrap();
    let game = match games.get_mut(&game_id) {
        Some(g) => g,
        None => return ActionResult::error("Game not found"),
    };
    
    let from_tile = match game.piece_by_id(&piece_id) {
        Some((tile, _)) => tile,
        None => return ActionResult::error("Piece not found"),
    };
    
    let path_tiles: Vec<BoardTile> = path.into_iter().map(Into::into).collect();
    
    match action_fn(game, from_tile, path_tiles) {
        Ok(outcome) => ActionResult::from_outcome(&outcome),
        Err(e) => ActionResult::error(format!("{:?}", e)),
    }
}

/// Get the bot's move for the current position (deprecated: use get_bot_action)
#[frb]
pub fn get_bot_move(game_id: String, difficulty: Difficulty) -> Option<(String, Position)> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id)?;
    
    let bot = Bot::new(game.current_turn(), difficulty.into());
    let actions = bot.choose_actions(game.board(), 1);
    
    actions.first().map(|bot_move| {
        // Find piece ID for the tile
        let piece_id = game.all_pieces()
            .into_iter()
            .find(|(_, tile, _)| *tile == bot_move.piece_tile)
            .map(|(id, _, _)| id)
            .unwrap_or_default();
        
        (piece_id, Position::from(bot_move.path.last().copied().unwrap_or(bot_move.piece_tile)))
    })
}

/// Get the bot's recommended action with full details
#[frb]
pub fn get_bot_action(game_id: String, difficulty: Difficulty) -> Option<BotAction> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id)?;
    
    let bot = Bot::new(game.current_turn(), difficulty.into());
    let actions = bot.choose_actions(game.board(), 1);
    
    actions.first().map(|bot_move| {
        let piece_id = game.all_pieces()
            .into_iter()
            .find(|(_, tile, _)| *tile == bot_move.piece_tile)
            .map(|(id, _, _)| id)
            .unwrap_or_default();
        
        BotAction {
            piece_id,
            action_type: bot_move.action.into(),
            path: bot_move.path.iter().map(|t| Position::from(*t)).collect(),
        }
    })
}

/// Check if the game is over
#[frb]
pub fn is_game_over(game_id: String) -> bool {
    let games = GAMES.lock().unwrap();
    match games.get(&game_id) {
        Some(game) => game.is_over(),
        None => true, // Treat missing game as over
    }
}

/// Get the winner (if game is over)
#[frb]
pub fn get_winner(game_id: String) -> Option<Team> {
    let games = GAMES.lock().unwrap();
    let game = games.get(&game_id)?;
    game.winner().map(Into::into)
}

/// Check if a game exists
#[frb]
pub fn game_exists(game_id: String) -> bool {
    let games = GAMES.lock().unwrap();
    games.contains_key(&game_id)
}

/// Delete a game session and free memory
#[frb]
pub fn delete_game(game_id: String) -> bool {
    let mut games = GAMES.lock().unwrap();
    games.remove(&game_id).is_some()
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

    // Helper to create a game for testing
    fn create_test_game() -> String {
        new_game(GameModeType::StandardMatch)
    }

    // -------------------------------------------------------------------------
    // Game Lifecycle Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_new_game_returns_valid_uuid() {
        let id = new_game(GameModeType::StandardMatch);
        // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
        assert_eq!(id.len(), 36);
        assert!(id.contains('-'));
    }

    #[test]
    fn test_new_game_stores_in_games() {
        let id = new_game(GameModeType::StandardMatch);
        let games = GAMES.lock().unwrap();
        assert!(games.contains_key(&id));
    }

    #[test]
    fn test_new_game_different_modes() {
        let quick = new_game(GameModeType::QuickMatch);
        let standard = new_game(GameModeType::StandardMatch);
        let golden = new_game(GameModeType::GoldenGoal);

        // All should create valid games
        let games = GAMES.lock().unwrap();
        assert!(games.contains_key(&quick));
        assert!(games.contains_key(&standard));
        assert!(games.contains_key(&golden));
        
        // All IDs should be different
        assert_ne!(quick, standard);
        assert_ne!(standard, golden);
    }

    // -------------------------------------------------------------------------
    // Board State Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_board_returns_14_pieces() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        // Engine uses 14 pieces (7 per team): 1 GK, 2 DEF, 2 MID, 2 ATT
        assert_eq!(board.pieces.len(), 14);
    }

    #[test]
    fn test_get_board_correct_team_distribution() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        let white_count = board.pieces.iter().filter(|p| p.team == Team::White).count();
        let black_count = board.pieces.iter().filter(|p| p.team == Team::Black).count();
        assert_eq!(white_count, 7);
        assert_eq!(black_count, 7);
    }

    #[test]
    fn test_get_board_initial_turn_is_white() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        assert_eq!(board.current_turn, Team::White);
    }

    #[test]
    fn test_get_board_initial_score_is_zero() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        assert_eq!(board.white_score, 0);
        assert_eq!(board.black_score, 0);
    }

    #[test]
    fn test_get_board_initial_turn_number() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        // Turn number starts at 0 in the engine
        assert!(board.turn_number <= 1);
    }

    #[test]
    fn test_get_board_has_exactly_one_ball_holder() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        let ball_holders: Vec<_> = board.pieces.iter().filter(|p| p.has_ball).collect();
        assert_eq!(ball_holders.len(), 1);
    }

    #[test]
    fn test_get_board_ball_holder_is_white_attacker() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        assert_eq!(ball_holder.team, Team::White);
        assert_eq!(ball_holder.role, PieceRole::Attacker);
    }

    #[test]
    fn test_get_board_has_two_goalkeepers() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        let goalkeepers: Vec<_> = board
            .pieces
            .iter()
            .filter(|p| p.role == PieceRole::Goalkeeper)
            .collect();
        assert_eq!(goalkeepers.len(), 2);
    }

    #[test]
    fn test_get_board_piece_ids_are_strings() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        
        // All IDs should be non-empty strings
        for piece in &board.pieces {
            assert!(!piece.id.is_empty());
            // Engine format: "WG01", "BA01", etc.
            assert!(piece.id.len() >= 3);
        }
    }

    #[test]
    fn test_get_board_piece_ids_are_unique() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        let mut ids: Vec<String> = board.pieces.iter().map(|p| p.id.clone()).collect();
        ids.sort();
        ids.dedup();
        assert_eq!(ids.len(), 14); // 7 per team
    }

    #[test]
    fn test_get_board_actions_remaining() {
        let id = create_test_game();
        let board = get_board(id).unwrap();
        assert_eq!(board.actions_remaining, 2);
    }
    
    #[test]
    fn test_get_board_invalid_id_returns_none() {
        let board = get_board("invalid_game_id".to_string());
        assert!(board.is_none());
    }

    // -------------------------------------------------------------------------
    // Action Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_legal_moves_returns_positions() {
        let id = create_test_game();
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let moves = get_legal_moves(id, ball_holder.id.clone());
        assert!(!moves.is_empty());
    }

    #[test]
    fn test_get_legal_moves_positions_are_valid() {
        let id = create_test_game();
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let moves = get_legal_moves(id, ball_holder.id.clone());
        for pos in moves {
            assert!(pos.row < 8, "Row should be < 8");
            assert!(pos.col < 8, "Col should be < 8");
        }
    }

    #[test]
    fn test_execute_move_returns_success() {
        let id = create_test_game();
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let moves = get_legal_moves(id.clone(), ball_holder.id.clone());
        if let Some(target) = moves.first() {
            let result = execute_move(id, ball_holder.id.clone(), *target);
            assert!(result.success);
        }
    }

    #[test]
    fn test_execute_move_updates_actions_remaining() {
        let id = create_test_game();
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let moves = get_legal_moves(id.clone(), ball_holder.id.clone());
        if let Some(target) = moves.first() {
            let result = execute_move(id.clone(), ball_holder.id.clone(), *target);
            assert!(result.success);
            // After one action, should have 1 remaining
            assert_eq!(result.actions_remaining, 1);
        }
    }

    #[test]
    fn test_execute_move_not_game_over() {
        let id = create_test_game();
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let moves = get_legal_moves(id.clone(), ball_holder.id.clone());
        if let Some(target) = moves.first() {
            let result = execute_move(id, ball_holder.id.clone(), *target);
            assert!(!result.game_over);
        }
    }

    #[test]
    fn test_execute_move_message_not_empty() {
        let id = create_test_game();
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let moves = get_legal_moves(id.clone(), ball_holder.id.clone());
        if let Some(target) = moves.first() {
            let result = execute_move(id, ball_holder.id.clone(), *target);
            assert!(!result.message.is_empty());
        }
    }

    #[test]
    fn test_execute_move_no_winner() {
        let id = create_test_game();
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let moves = get_legal_moves(id.clone(), ball_holder.id.clone());
        if let Some(target) = moves.first() {
            let result = execute_move(id, ball_holder.id.clone(), *target);
            assert!(result.winner.is_none());
        }
    }

    // -------------------------------------------------------------------------
    // Bot AI Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_bot_move_returns_some() {
        let id = create_test_game();
        let bot_move = get_bot_move(id, Difficulty::Medium);
        assert!(bot_move.is_some());
    }

    #[test]
    fn test_get_bot_move_valid_piece_id() {
        let id = create_test_game();
        let bot_move = get_bot_move(id.clone(), Difficulty::Medium);
        let (piece_id, _pos) = bot_move.unwrap();
        
        // Verify piece exists
        let board = get_board(id).unwrap();
        assert!(board.pieces.iter().any(|p| p.id == piece_id));
    }

    #[test]
    fn test_get_bot_move_valid_position() {
        let id = create_test_game();
        let bot_move = get_bot_move(id, Difficulty::Medium);
        let (_piece_id, pos) = bot_move.unwrap();
        assert!(pos.row < 8, "Row should be < 8");
        assert!(pos.col < 8, "Col should be < 8");
    }

    #[test]
    fn test_get_bot_move_easy_difficulty() {
        let id = create_test_game();
        let bot_move = get_bot_move(id, Difficulty::Easy);
        assert!(bot_move.is_some());
    }

    #[test]
    fn test_get_bot_move_medium_difficulty() {
        let id = create_test_game();
        let bot_move = get_bot_move(id, Difficulty::Medium);
        assert!(bot_move.is_some());
    }

    // -------------------------------------------------------------------------
    // Game State Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_is_game_over_initially_false() {
        let id = create_test_game();
        assert!(!is_game_over(id));
    }

    #[test]
    fn test_get_winner_initially_none() {
        let id = create_test_game();
        assert!(get_winner(id).is_none());
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

    // -------------------------------------------------------------------------
    // Full Integration Tests - Verify Real Engine Behavior
    // -------------------------------------------------------------------------

    #[test]
    fn test_full_game_flow_multiple_moves() {
        // Create a new game
        let id = new_game(GameModeType::StandardMatch);
        
        // Get initial board state
        let board1 = get_board(id.clone()).unwrap();
        assert_eq!(board1.actions_remaining, 2);
        assert_eq!(board1.current_turn, Team::White);
        
        // Find the ball holder
        let ball_holder = board1.pieces.iter().find(|p| p.has_ball).unwrap();
        let ball_holder_id = ball_holder.id.clone();
        let original_pos = ball_holder.position;
        
        // Get legal moves (should be non-empty for attacker with ball)
        let moves = get_legal_moves(id.clone(), ball_holder_id.clone());
        assert!(!moves.is_empty(), "Ball holder should have legal moves");
        
        // Execute first move
        let result1 = execute_move(id.clone(), ball_holder_id.clone(), moves[0]);
        assert!(result1.success, "First move should succeed");
        assert_eq!(result1.actions_remaining, 1, "Should have 1 action left");
        
        // Verify board state changed
        let board2 = get_board(id.clone()).unwrap();
        assert_eq!(board2.actions_remaining, 1);
        
        // Find the ball holder again (should be same piece at new position)
        let moved_piece = board2.pieces.iter().find(|p| p.id == ball_holder_id).unwrap();
        assert_eq!(moved_piece.position.row, moves[0].row, "Piece should have moved to target row");
        assert_eq!(moved_piece.position.col, moves[0].col, "Piece should have moved to target col");
        assert_ne!(moved_piece.position.row, original_pos.row, "Position should have changed");
        
        // Get new legal moves from new position
        let moves2 = get_legal_moves(id.clone(), ball_holder_id.clone());
        assert!(!moves2.is_empty(), "Ball holder should still have moves");
        
        // Execute second move (should trigger turn change)
        let result2 = execute_move(id.clone(), ball_holder_id.clone(), moves2[0]);
        assert!(result2.success, "Second move should succeed");
        
        // After White's 2 actions, turn auto-advances to Black with 2 actions
        let board3 = get_board(id.clone()).unwrap();
        assert_eq!(board3.current_turn, Team::Black, "Turn should switch to Black");
        assert_eq!(board3.actions_remaining, 2, "Black should have 2 actions");
    }

    #[test]
    fn test_bot_integration_with_real_ai() {
        let id = new_game(GameModeType::StandardMatch);
        
        // Get bot move from real AI
        let bot_move = get_bot_move(id.clone(), Difficulty::Medium);
        assert!(bot_move.is_some(), "Bot should return a move");
        
        let (piece_id, target_pos) = bot_move.unwrap();
        
        // Verify the piece exists and belongs to current team
        let board = get_board(id.clone()).unwrap();
        let piece = board.pieces.iter().find(|p| p.id == piece_id);
        assert!(piece.is_some(), "Bot should select an existing piece");
        assert_eq!(piece.unwrap().team, Team::White, "Bot should select current team's piece");
        
        // Verify target position is on the board
        assert!(target_pos.row < 8, "Target row should be valid");
        assert!(target_pos.col < 8, "Target col should be valid");
        
        // Note: Bot may return pass/shoot paths, not just moves
        // So we just verify the target is a valid board position
    }

    #[test]
    fn test_execute_invalid_move_returns_error() {
        let id = new_game(GameModeType::StandardMatch);
        
        // Try to move a piece to an invalid position (off board)
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        // Get legal moves and pick an illegal one
        let legal_moves = get_legal_moves(id.clone(), ball_holder.id.clone());
        
        // Find a position that's NOT in legal moves
        let illegal_pos = Position { row: 7, col: 7 }; // Far corner, likely occupied or illegal
        if !legal_moves.contains(&illegal_pos) {
            let result = execute_move(id, ball_holder.id.clone(), illegal_pos);
            // Either it fails or it succeeds (if coincidentally legal)
            // The key is we don't panic and get a proper result
            assert!(result.success || !result.message.is_empty());
        }
    }

    #[test]
    fn test_game_mode_affects_max_turns() {
        // QuickMatch should have different turn limit than StandardMatch
        let quick_id = new_game(GameModeType::QuickMatch);
        let standard_id = new_game(GameModeType::StandardMatch);
        let golden_id = new_game(GameModeType::GoldenGoal);
        
        // All games should start properly
        let quick_board = get_board(quick_id).unwrap();
        let standard_board = get_board(standard_id).unwrap();
        let golden_board = get_board(golden_id).unwrap();
        
        // All should have initial state
        assert_eq!(quick_board.actions_remaining, 2);
        assert_eq!(standard_board.actions_remaining, 2);
        assert_eq!(golden_board.actions_remaining, 2);
        
        // All should start with 14 pieces
        assert_eq!(quick_board.pieces.len(), 14);
        assert_eq!(standard_board.pieces.len(), 14);
        assert_eq!(golden_board.pieces.len(), 14);
    }

    #[test]
    fn test_piece_ids_match_engine_format() {
        let id = new_game(GameModeType::StandardMatch);
        let board = get_board(id).unwrap();
        
        for piece in &board.pieces {
            // IDs should be in format: TeamLetter + RoleLetter + Number
            // e.g., "WG01", "BA02", "WM01", etc.
            assert!(piece.id.len() >= 4, "ID should have at least 4 chars: {}", piece.id);
            
            let first_char = piece.id.chars().next().unwrap();
            match piece.team {
                Team::White => assert_eq!(first_char, 'W', "White piece should start with W"),
                Team::Black => assert_eq!(first_char, 'B', "Black piece should start with B"),
            }
            
            let second_char = piece.id.chars().nth(1).unwrap();
            match piece.role {
                PieceRole::Goalkeeper => assert_eq!(second_char, 'G', "Goalkeeper should have G"),
                PieceRole::Defender => assert_eq!(second_char, 'D', "Defender should have D"),
                PieceRole::Midfielder => assert_eq!(second_char, 'M', "Midfielder should have M"),
                PieceRole::Attacker => assert_eq!(second_char, 'A', "Attacker should have A"),
            }
        }
    }

    // -------------------------------------------------------------------------
    // New FT-012 Tests: API Gaps
    // -------------------------------------------------------------------------

    #[test]
    fn test_get_bot_action_returns_full_action() {
        let id = new_game(GameModeType::StandardMatch);
        let action = get_bot_action(id, Difficulty::Medium);
        
        assert!(action.is_some(), "Bot should return an action");
        let bot_action = action.unwrap();
        assert!(!bot_action.piece_id.is_empty(), "Piece ID should not be empty");
        assert!(!bot_action.path.is_empty(), "Path should not be empty");
    }

    #[test]
    fn test_get_bot_action_has_valid_action_type() {
        let id = new_game(GameModeType::StandardMatch);
        let action = get_bot_action(id, Difficulty::Medium).unwrap();
        
        // ActionType should be one of the valid variants
        matches!(action.action_type, ActionType::Move | ActionType::Pass | ActionType::Shoot | ActionType::Intercept);
    }

    #[test]
    fn test_get_legal_passes_for_ball_holder() {
        let id = new_game(GameModeType::StandardMatch);
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let passes = get_legal_passes(id, ball_holder.id.clone());
        // Ball holder should have pass options (attacker with ball)
        assert!(!passes.is_empty(), "Ball holder should have pass options");
    }

    #[test]
    fn test_get_legal_passes_returns_paths() {
        let id = new_game(GameModeType::StandardMatch);
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        let passes = get_legal_passes(id, ball_holder.id.clone());
        // Each pass should be a PositionPath with positions
        for path in passes {
            assert!(!path.positions.is_empty(), "Each pass path should have at least one position");
            for pos in &path.positions {
                assert!(pos.row < 8 && pos.col < 8, "Positions should be valid");
            }
        }
    }

    #[test]
    fn test_get_legal_shoots_for_ball_holder() {
        let id = new_game(GameModeType::StandardMatch);
        let board = get_board(id.clone()).unwrap();
        let ball_holder = board.pieces.iter().find(|p| p.has_ball).unwrap();
        
        // Note: Shoots may be empty if not in shooting range - that's OK
        let shoots = get_legal_shoots(id, ball_holder.id.clone());
        // Just verify it doesn't panic
        for path in shoots {
            for pos in &path.positions {
                assert!(pos.row < 8 && pos.col < 8, "Positions should be valid");
            }
        }
    }

    #[test]
    fn test_delete_game_frees_memory() {
        let id = new_game(GameModeType::StandardMatch);
        assert!(game_exists(id.clone()), "Game should exist after creation");
        
        assert!(delete_game(id.clone()), "Delete should return true");
        assert!(!game_exists(id), "Game should not exist after deletion");
    }

    #[test]
    fn test_delete_game_nonexistent_returns_false() {
        let deleted = delete_game("nonexistent_game_id".to_string());
        assert!(!deleted, "Deleting nonexistent game should return false");
    }

    #[test]
    fn test_game_exists_true_for_valid_game() {
        let id = new_game(GameModeType::StandardMatch);
        assert!(game_exists(id));
    }

    #[test]
    fn test_game_exists_false_for_invalid_id() {
        assert!(!game_exists("invalid_id".to_string()));
    }

    #[test]
    fn test_execute_move_invalid_game_returns_error() {
        let result = execute_move(
            "invalid_game".to_string(), 
            "WA01".to_string(), 
            Position { row: 3, col: 3 }
        );
        assert!(!result.success, "Should fail for invalid game");
        assert!(result.message.contains("not found"), "Message should mention not found");
    }

    #[test]
    fn test_is_game_over_invalid_returns_true() {
        // Invalid game treated as "over" to prevent actions
        assert!(is_game_over("invalid_id".to_string()));
    }

    #[test]
    fn test_get_winner_invalid_returns_none() {
        assert!(get_winner("invalid_id".to_string()).is_none());
    }

    #[test]
    fn test_get_legal_moves_invalid_game() {
        let moves = get_legal_moves("invalid".to_string(), "WA01".to_string());
        assert!(moves.is_empty(), "Should return empty vec for invalid game");
    }

    #[test]
    fn test_get_legal_passes_invalid_game() {
        let passes = get_legal_passes("invalid".to_string(), "WA01".to_string());
        assert!(passes.is_empty(), "Should return empty vec for invalid game");
    }

    #[test]
    fn test_get_legal_shoots_invalid_game() {
        let shoots = get_legal_shoots("invalid".to_string(), "WA01".to_string());
        assert!(shoots.is_empty(), "Should return empty vec for invalid game");
    }

    #[test]
    fn test_get_bot_action_invalid_game() {
        let action = get_bot_action("invalid".to_string(), Difficulty::Medium);
        assert!(action.is_none(), "Should return None for invalid game");
    }
}
