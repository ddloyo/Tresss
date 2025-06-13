import 'package:tresss/game/models/game_state.dart';
import 'package:tresss/game/models/player.dart';
import 'package:tresss/game/models/card.dart';
import 'package:uuid/uuid.dart';

class GameService {
  final Uuid _uuid = const Uuid();

  // Create a new game
  GameState createNewGame(String? gameId) {
    return GameState(
      gameId: gameId ?? _uuid.v4(),
      status: GameStatus.waiting,
    );
  }

  // Add a player to the game
  GameState addPlayer(GameState gameState, Player player) {
    if (gameState.isGameFull) {
      return gameState; // Game is full
    }

    final updatedPlayers = List<Player>.from(gameState.players)..add(player);
    
    // Start game if we have minimum players and this is the first time reaching that threshold
    if (updatedPlayers.length >= gameState.minPlayers && gameState.status == GameStatus.waiting) {
      return _startGame(gameState.copyWith(players: updatedPlayers));
    }

    return gameState.copyWith(players: updatedPlayers);
  }

  // Remove a player from the game
  GameState removePlayer(GameState gameState, String playerId) {
    final updatedPlayers = gameState.players.where((p) => p.id != playerId).toList();
    
    // If the current player left, move to next player
    Player? newCurrentPlayer = gameState.currentPlayer;
    if (gameState.currentPlayer?.id == playerId && updatedPlayers.isNotEmpty) {
      final currentIndex = gameState.players.indexWhere((p) => p.id == playerId);
      final nextIndex = currentIndex % updatedPlayers.length;
      newCurrentPlayer = updatedPlayers[nextIndex];
    }

    final newStatus = updatedPlayers.length < gameState.minPlayers 
        ? GameStatus.waiting 
        : gameState.status;

    return gameState.copyWith(
      players: updatedPlayers,
      currentPlayer: newCurrentPlayer,
      status: newStatus,
    );
  }

  // Start the game - deal cards and set first player
  GameState _startGame(GameState gameState) {
    if (gameState.players.length < gameState.minPlayers) {
      return gameState;
    }

    // Create and shuffle deck
    final deck = List<GameCard>.from(GameState.createDeck());
    deck.shuffle();

    // Deal 5 cards to each player
    final updatedPlayers = <Player>[];
    int cardIndex = 0;

    for (final player in gameState.players) {
      final hand = deck.sublist(cardIndex, cardIndex + 5);
      cardIndex += 5;
      updatedPlayers.add(player.copyWith(hand: hand));
    }

    // Remaining cards go to table deck
    final tableDeck = deck.sublist(cardIndex);

    return gameState.copyWith(
      players: updatedPlayers,
      tableDeck: tableDeck,
      currentPlayer: updatedPlayers.first,
      status: GameStatus.playing,
      lastMoveTime: DateTime.now(),
    );
  }

  // Reveal a card from the table
  GameState revealTableCard(GameState gameState, int cardIndex, String playerId) {
    if (!canPlayerMove(gameState, playerId) || cardIndex >= gameState.tableDeck.length) {
      return gameState;
    }

    final revealedCard = gameState.tableDeck[cardIndex];
    final newTurn = _processRevealedCard(gameState.currentTurn, revealedCard);
    
    // Move card from table deck to revealed cards
    final newTableDeck = List<GameCard>.from(gameState.tableDeck)..removeAt(cardIndex);
    final newRevealedCards = List<GameCard>.from(gameState.revealedTableCards)..add(revealedCard);

    return _processTurnResult(gameState.copyWith(
      tableDeck: newTableDeck,
      revealedTableCards: newRevealedCards,
      currentTurn: newTurn,
      lastMoveTime: DateTime.now(),
    ));
  }

  // Ask a player to reveal their highest or lowest card
  GameState revealPlayerCard(GameState gameState, String targetPlayerId, RevealAction action, String requestingPlayerId) {
    if (!canPlayerMove(gameState, requestingPlayerId)) {
      return gameState;
    }

    final targetPlayer = gameState.players.firstWhere((p) => p.id == targetPlayerId);
    GameCard? cardToReveal;

    if (action == RevealAction.highestCard) {
      cardToReveal = targetPlayer.highestCard;
    } else if (action == RevealAction.lowestCard) {
      cardToReveal = targetPlayer.lowestCard;
    }

    if (cardToReveal == null) {
      return gameState;
    }

    final newTurn = _processRevealedCard(gameState.currentTurn, cardToReveal);
    
    return _processTurnResult(gameState.copyWith(
      currentTurn: newTurn,
      lastMoveTime: DateTime.now(),
    ));
  }

  // Process a revealed card in the current turn
  TurnState _processRevealedCard(TurnState currentTurn, GameCard revealedCard) {
    final newRevealedCards = List<GameCard>.from(currentTurn.revealedCards)..add(revealedCard);

    // If this is the first card, set the target number
    if (currentTurn.revealedCards.isEmpty) {
      return currentTurn.copyWith(
        revealedCards: newRevealedCards,
        targetNumber: revealedCard.number,
        foundCount: 1,
      );
    }

    // Check if the card matches the target number
    if (revealedCard.number == currentTurn.targetNumber) {
      final newFoundCount = currentTurn.foundCount + 1;
      return currentTurn.copyWith(
        revealedCards: newRevealedCards,
        foundCount: newFoundCount,
        isComplete: newFoundCount >= 3, // Trio complete
      );
    } else {
      // Turn failed - player didn't find matching card
      return currentTurn.copyWith(
        revealedCards: newRevealedCards,
        isComplete: true,
      );
    }
  }

  // Process the result of a turn
  GameState _processTurnResult(GameState gameState) {
    if (!gameState.currentTurn.isComplete) {
      return gameState; // Turn is still ongoing
    }

    // Check if player completed a trio
    if (gameState.currentTurn.foundCount >= 3) {
      return _completeTrioTurn(gameState);
    } else {
      return _failedTurn(gameState);
    }
  }

  // Complete a successful trio turn
  GameState _completeTrioTurn(GameState gameState) {
    final currentPlayer = gameState.currentPlayer!;
    final trioCards = gameState.currentTurn.revealedCards.where((card) => 
        card.number == gameState.currentTurn.targetNumber).take(3).toList();
    
    final newTrio = Trio(cards: trioCards, playerId: currentPlayer.id);
    
    // Remove trio cards from wherever they were (hands or table)
    final updatedPlayers = _removeTrioCardsFromHands(gameState.players, trioCards);
    final updatedTableCards = _removeCardsFromList(gameState.revealedTableCards, trioCards);
    
    // Add trio to current player
    final playerIndex = updatedPlayers.indexWhere((p) => p.id == currentPlayer.id);
    final updatedCurrentPlayer = updatedPlayers[playerIndex].copyWith(
      trios: List<Trio>.from(updatedPlayers[playerIndex].trios)..add(newTrio),
    );
    updatedPlayers[playerIndex] = updatedCurrentPlayer;

    // Check for win condition
    final winner = updatedCurrentPlayer.hasWon ? updatedCurrentPlayer : null;
    final gameResult = winner != null ? GameResult.playerWon : GameResult.none;
    final gameStatus = winner != null ? GameStatus.finished : GameStatus.playing;

    // Move to next player if game continues
    final nextPlayer = winner != null ? null : _getNextPlayer(gameState.players, currentPlayer.id);

    return gameState.copyWith(
      players: updatedPlayers,
      revealedTableCards: updatedTableCards,
      currentPlayer: nextPlayer,
      currentTurn: const TurnState(),
      result: gameResult,
      winner: winner,
      status: gameStatus,
    );
  }

  // Handle a failed turn
  GameState _failedTurn(GameState gameState) {
    final nextPlayer = _getNextPlayer(gameState.players, gameState.currentPlayer!.id);
    
    return gameState.copyWith(
      currentPlayer: nextPlayer,
      currentTurn: const TurnState(),
    );
  }

  // Helper method to remove trio cards from player hands
  List<Player> _removeTrioCardsFromHands(List<Player> players, List<GameCard> trioCards) {
    return players.map((player) {
      final newHand = player.hand.where((card) => 
          !trioCards.any((trioCard) => trioCard.id == card.id)).toList();
      return player.copyWith(hand: newHand);
    }).toList();
  }

  // Helper method to remove cards from a list
  List<GameCard> _removeCardsFromList(List<GameCard> cards, List<GameCard> cardsToRemove) {
    return cards.where((card) => 
        !cardsToRemove.any((removeCard) => removeCard.id == card.id)).toList();
  }

  // Get the next player in turn order
  Player _getNextPlayer(List<Player> players, String currentPlayerId) {
    final currentIndex = players.indexWhere((p) => p.id == currentPlayerId);
    final nextIndex = (currentIndex + 1) % players.length;
    return players[nextIndex];
  }

  // Reset the game for a new round
  GameState resetGame(GameState gameState) {
    // Reset all players' hands and trios, but keep stats
    final resetPlayers = gameState.players.map((player) => 
        player.copyWith(hand: [], trios: [])).toList();

    final newGame = GameState(
      gameId: gameState.gameId,
      players: resetPlayers,
      round: gameState.round + 1,
      maxPlayers: gameState.maxPlayers,
      minPlayers: gameState.minPlayers,
    );

    return _startGame(newGame);
  }

  // Update player stats after game ends
  GameState updatePlayerStats(GameState gameState) {
    if (gameState.result == GameResult.none) return gameState;

    final updatedPlayers = gameState.players.map((player) {
      if (gameState.winner?.id == player.id) {
        return player.copyWith(
          wins: player.wins + 1,
          gamesPlayed: player.gamesPlayed + 1,
        );
      } else {
        return player.copyWith(
          losses: player.losses + 1,
          gamesPlayed: player.gamesPlayed + 1,
        );
      }
    }).toList();

    return gameState.copyWith(players: updatedPlayers);
  }

  // Get game winner
  Player? getWinner(GameState gameState) {
    return gameState.winner;
  }

  // Check if player can make a move
  bool canPlayerMove(GameState gameState, String playerId) {
    return gameState.status == GameStatus.playing && 
           gameState.currentPlayer?.id == playerId;
  }

  // Add a bot player to the game
  GameState addBot(GameState gameState, String botName) {
    final botPlayer = Player(
      id: _uuid.v4(),
      name: botName,
      isBot: true,
    );

    return addPlayer(gameState, botPlayer);
  }

  // Get available cards on table (face down)
  List<int> getAvailableTableCardIndices(GameState gameState) {
    return List.generate(gameState.tableDeck.length, (index) => index);
  }

  // Check if a player has a specific card number in their hand
  bool playerHasCardNumber(Player player, int number) {
    return player.hand.any((card) => card.number == number);
  }

  // Get all players except the specified one (for asking for cards)
  List<Player> getOtherPlayers(GameState gameState, String playerId) {
    return gameState.players.where((p) => p.id != playerId).toList();
  }

  // Check if game can continue (enough cards and players)
  bool canGameContinue(GameState gameState) {
    return gameState.players.length >= gameState.minPlayers &&
           (gameState.tableDeck.isNotEmpty || 
            gameState.players.any((p) => p.hand.isNotEmpty));
  }
} 