import Foundation

// MARK: - Dominoes Game Models
struct DominoTile: Codable, Equatable {
    let left: Int
    let right: Int

    var isDouble: Bool {
        return left == right
    }

    var value: Int {
        return left + right
    }

    func canConnect(to value: Int) -> Bool {
        return left == value || right == value
    }

    func flipped() -> DominoTile {
        return DominoTile(left: right, right: left)
    }
}

struct DominoGameState: Codable {
    let playerHands: [UUID: [DominoTile]]
    let board: [DominoTile]
    let boneYard: [DominoTile]
    let currentTurn: UUID
    let player1Id: UUID
    let player2Id: UUID
    let gameEnded: Bool
    let winner: UUID?

    enum CodingKeys: String, CodingKey {
        case playerHands = "player_hands"
        case board
        case boneYard = "bone_yard"
        case currentTurn = "current_turn"
        case player1Id = "player1_id"
        case player2Id = "player2_id"
        case gameEnded = "game_ended"
        case winner
    }

    func getPlayerHand(for playerId: UUID) -> [DominoTile] {
        return playerHands[playerId] ?? []
    }

    var boardLeftValue: Int? {
        return board.first?.left
    }

    var boardRightValue: Int? {
        return board.last?.right
    }
}

struct DominoMove: Codable {
    let tile: DominoTile
    let side: String // "left" or "right"
    let pass: Bool

    init(tile: DominoTile, side: String) {
        self.tile = tile
        self.side = side
        self.pass = false
    }

    init(pass: Bool) {
        self.tile = DominoTile(left: 0, right: 0)
        self.side = ""
        self.pass = pass
    }
}

// MARK: - Chess Game Models
struct ChessPiece: Codable, Equatable {
    let type: ChessPieceType
    let color: ChessColor

    var symbol: String {
        switch (color, type) {
        case (.white, .king): return "♔"
        case (.white, .queen): return "♕"
        case (.white, .rook): return "♖"
        case (.white, .bishop): return "♗"
        case (.white, .knight): return "♘"
        case (.white, .pawn): return "♙"
        case (.black, .king): return "♚"
        case (.black, .queen): return "♛"
        case (.black, .rook): return "♜"
        case (.black, .bishop): return "♝"
        case (.black, .knight): return "♞"
        case (.black, .pawn): return "♟"
        }
    }
}

enum ChessPieceType: String, Codable {
    case pawn, rook, knight, bishop, queen, king
}

enum ChessColor: String, Codable {
    case white, black

    var opposite: ChessColor {
        return self == .white ? .black : .white
    }
}

struct ChessPosition: Codable, Equatable {
    let row: Int
    let col: Int

    var isValid: Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }

    func notation() -> String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let ranks = ["1", "2", "3", "4", "5", "6", "7", "8"]
        guard col < files.count && row < ranks.count else { return "" }
        return files[col] + ranks[row]
    }
}

struct ChessGameState: Codable {
    let board: [[ChessPiece?]]
    let currentTurn: ChessColor
    let player1Id: UUID
    let player2Id: UUID
    let whitePlayer: UUID
    let blackPlayer: UUID
    let gameEnded: Bool
    let winner: UUID?
    let check: Bool
    let checkmate: Bool
    let stalemate: Bool
    let whiteKingSideCastle: Bool
    let whiteQueenSideCastle: Bool
    let blackKingSideCastle: Bool
    let blackQueenSideCastle: Bool
    let enPassantTarget: ChessPosition?
    let moveCount: Int

    enum CodingKeys: String, CodingKey {
        case board
        case currentTurn = "current_turn"
        case player1Id = "player1_id"
        case player2Id = "player2_id"
        case whitePlayer = "white_player"
        case blackPlayer = "black_player"
        case gameEnded = "game_ended"
        case winner
        case check
        case checkmate
        case stalemate
        case whiteKingSideCastle = "white_king_side_castle"
        case whiteQueenSideCastle = "white_queen_side_castle"
        case blackKingSideCastle = "black_king_side_castle"
        case blackQueenSideCastle = "black_queen_side_castle"
        case enPassantTarget = "en_passant_target"
        case moveCount = "move_count"
    }

    func getPiece(at position: ChessPosition) -> ChessPiece? {
        guard position.isValid else { return nil }
        return board[position.row][position.col]
    }

    func getPlayerColor(for playerId: UUID) -> ChessColor? {
        if playerId == whitePlayer {
            return .white
        } else if playerId == blackPlayer {
            return .black
        }
        return nil
    }
}

struct ChessMove: Codable {
    let from: ChessPosition
    let to: ChessPosition
    let promotion: ChessPieceType?
    let castling: String?

    init(from: ChessPosition, to: ChessPosition, promotion: ChessPieceType? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
        self.castling = nil
    }

    init(castling: String) {
        self.from = ChessPosition(row: 0, col: 0)
        self.to = ChessPosition(row: 0, col: 0)
        self.promotion = nil
        self.castling = castling
    }
}