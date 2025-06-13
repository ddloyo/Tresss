import 'package:equatable/equatable.dart';
import 'package:tresss/game/models/game_state.dart' as models;
import 'package:tresss/game/models/player.dart';

abstract class GameBlocState extends Equatable {
  const GameBlocState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameBlocState {
  const GameInitial();
}

class GameConnecting extends GameBlocState {
  const GameConnecting();
}

class GameConnected extends GameBlocState {
  const GameConnected();
}

class GameDisconnected extends GameBlocState {
  final String? reason;
  
  const GameDisconnected({this.reason});

  @override
  List<Object?> get props => [reason];
}

class GameLoading extends GameBlocState {
  final String message;
  
  const GameLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];
}

class GameWaitingForPlayer extends GameBlocState {
  final models.GameState gameState;
  final Player currentPlayer;
  
  const GameWaitingForPlayer({
    required this.gameState,
    required this.currentPlayer,
  });

  @override
  List<Object?> get props => [gameState, currentPlayer];
}

class GameInProgress extends GameBlocState {
  final models.GameState gameState;
  final Player currentPlayer;
  final bool isMyTurn;
  
  const GameInProgress({
    required this.gameState,
    required this.currentPlayer,
    required this.isMyTurn,
  });

  @override
  List<Object?> get props => [gameState, currentPlayer, isMyTurn];
}

class GameFinished extends GameBlocState {
  final models.GameState gameState;
  final Player currentPlayer;
  final Player? winner;
  final bool isWinner;
  
  const GameFinished({
    required this.gameState,
    required this.currentPlayer,
    this.winner,
    required this.isWinner,
  });

  @override
  List<Object?> get props => [gameState, currentPlayer, winner, isWinner];
}

class GameError extends GameBlocState {
  final String message;
  final String? details;
  
  const GameError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

class GamePaused extends GameBlocState {
  final models.GameState gameState;
  final Player currentPlayer;
  final String reason;
  
  const GamePaused({
    required this.gameState,
    required this.currentPlayer,
    required this.reason,
  });

  @override
  List<Object?> get props => [gameState, currentPlayer, reason];
} 