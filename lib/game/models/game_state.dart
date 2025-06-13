import 'package:equatable/equatable.dart';
import 'package:tresss/game/models/player.dart';
import 'package:tresss/game/models/card.dart';

enum GameStatus {
  waiting,
  playing,
  finished,
  paused,
  disconnected,
}

enum GameResult {
  none,
  playerWon,
  draw,
}

enum RevealAction {
  fromTable,
  highestCard,
  lowestCard,
}

class TurnState extends Equatable {
  final List<GameCard> revealedCards;
  final int targetNumber;
  final int foundCount;
  final bool isComplete;

  const TurnState({
    this.revealedCards = const [],
    this.targetNumber = 0,
    this.foundCount = 0,
    this.isComplete = false,
  });

  TurnState copyWith({
    List<GameCard>? revealedCards,
    int? targetNumber,
    int? foundCount,
    bool? isComplete,
  }) {
    return TurnState(
      revealedCards: revealedCards ?? this.revealedCards,
      targetNumber: targetNumber ?? this.targetNumber,
      foundCount: foundCount ?? this.foundCount,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object?> get props => [revealedCards, targetNumber, foundCount, isComplete];
}

class GameState extends Equatable {
  final String gameId;
  final List<GameCard> tableDeck; // Cards on the table (face down)
  final List<GameCard> revealedTableCards; // Cards revealed on table
  final List<Player> players;
  final Player? currentPlayer;
  final GameStatus status;
  final GameResult result;
  final Player? winner;
  final TurnState currentTurn;
  final int round;
  final DateTime? lastMoveTime;
  final int maxPlayers;
  final int minPlayers;

  const GameState({
    required this.gameId,
    this.tableDeck = const [],
    this.revealedTableCards = const [],
    this.players = const [],
    this.currentPlayer,
    this.status = GameStatus.waiting,
    this.result = GameResult.none,
    this.winner,
    this.currentTurn = const TurnState(),
    this.round = 1,
    this.lastMoveTime,
    this.maxPlayers = 6,
    this.minPlayers = 3,
  });

  // Create a complete deck of 36 cards (3 of each number 1-12)
  static List<GameCard> createDeck() {
    List<GameCard> deck = [];
    for (int number = 1; number <= 12; number++) {
      for (int copy = 1; copy <= 3; copy++) {
        deck.add(GameCard(
          number: number,
          id: '${number}_$copy',
        ));
      }
    }
    return deck;
  }

  bool get isGameFinished => status == GameStatus.finished;
  bool get isWaitingForPlayer => status == GameStatus.waiting;
  bool get isGameActive => status == GameStatus.playing;
  bool get hasWinner => result != GameResult.none && result != GameResult.draw;
  bool get isDraw => result == GameResult.draw;
  bool get canStartGame => players.length >= minPlayers;
  bool get isGameFull => players.length >= maxPlayers;

  GameState copyWith({
    String? gameId,
    List<GameCard>? tableDeck,
    List<GameCard>? revealedTableCards,
    List<Player>? players,
    Player? currentPlayer,
    GameStatus? status,
    GameResult? result,
    Player? winner,
    TurnState? currentTurn,
    int? round,
    DateTime? lastMoveTime,
    int? maxPlayers,
    int? minPlayers,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      tableDeck: tableDeck ?? this.tableDeck,
      revealedTableCards: revealedTableCards ?? this.revealedTableCards,
      players: players ?? this.players,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      status: status ?? this.status,
      result: result ?? this.result,
      winner: winner ?? this.winner,
      currentTurn: currentTurn ?? this.currentTurn,
      round: round ?? this.round,
      lastMoveTime: lastMoveTime ?? this.lastMoveTime,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'tableDeck': tableDeck.map((card) => card.toJson()).toList(),
      'revealedTableCards': revealedTableCards.map((card) => card.toJson()).toList(),
      'players': players.map((player) => player.toJson()).toList(),
      'currentPlayer': currentPlayer?.toJson(),
      'status': status.name,
      'result': result.name,
      'winner': winner?.toJson(),
      'currentTurn': {
        'revealedCards': currentTurn.revealedCards.map((card) => card.toJson()).toList(),
        'targetNumber': currentTurn.targetNumber,
        'foundCount': currentTurn.foundCount,
        'isComplete': currentTurn.isComplete,
      },
      'round': round,
      'lastMoveTime': lastMoveTime?.toIso8601String(),
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final turnData = json['currentTurn'] as Map<String, dynamic>? ?? {};
    
    return GameState(
      gameId: json['gameId'] as String,
      tableDeck: (json['tableDeck'] as List?)
          ?.map((cardJson) => GameCard.fromJson(cardJson))
          .toList() ?? [],
      revealedTableCards: (json['revealedTableCards'] as List?)
          ?.map((cardJson) => GameCard.fromJson(cardJson))
          .toList() ?? [],
      players: (json['players'] as List?)
          ?.map((playerJson) => Player.fromJson(playerJson))
          .toList() ?? [],
      currentPlayer: json['currentPlayer'] != null 
          ? Player.fromJson(json['currentPlayer']) 
          : null,
      status: GameStatus.values.byName(json['status'] as String),
      result: GameResult.values.byName(json['result'] as String),
      winner: json['winner'] != null ? Player.fromJson(json['winner']) : null,
      currentTurn: TurnState(
        revealedCards: (turnData['revealedCards'] as List?)
            ?.map((cardJson) => GameCard.fromJson(cardJson))
            .toList() ?? [],
        targetNumber: turnData['targetNumber'] as int? ?? 0,
        foundCount: turnData['foundCount'] as int? ?? 0,
        isComplete: turnData['isComplete'] as bool? ?? false,
      ),
      round: json['round'] as int? ?? 1,
      lastMoveTime: json['lastMoveTime'] != null 
          ? DateTime.parse(json['lastMoveTime']) 
          : null,
      maxPlayers: json['maxPlayers'] as int? ?? 6,
      minPlayers: json['minPlayers'] as int? ?? 3,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        tableDeck,
        revealedTableCards,
        players,
        currentPlayer,
        status,
        result,
        winner,
        currentTurn,
        round,
        lastMoveTime,
        maxPlayers,
        minPlayers,
      ];
} 