import 'package:equatable/equatable.dart';
import 'package:tresss/game/models/player.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class ConnectToServer extends GameEvent {
  const ConnectToServer();
}

class DisconnectFromServer extends GameEvent {
  const DisconnectFromServer();
}

class CreateGame extends GameEvent {
  final Player player;
  
  const CreateGame({required this.player});

  @override
  List<Object?> get props => [player];
}

class JoinGame extends GameEvent {
  final String gameId;
  final Player player;
  
  const JoinGame({required this.gameId, required this.player});

  @override
  List<Object?> get props => [gameId, player];
}

class JoinRandomGame extends GameEvent {
  final Player player;
  
  const JoinRandomGame({required this.player});

  @override
  List<Object?> get props => [player];
}

class LeaveGame extends GameEvent {
  const LeaveGame();
}

class MakeMove extends GameEvent {
  final int row;
  final int col;
  
  const MakeMove({required this.row, required this.col});

  @override
  List<Object?> get props => [row, col];
}

class ResetGame extends GameEvent {
  const ResetGame();
}

class GameStateUpdated extends GameEvent {
  final dynamic gameData;
  
  const GameStateUpdated({required this.gameData});

  @override
  List<Object?> get props => [gameData];
}

class PlayerJoined extends GameEvent {
  final Player player;
  
  const PlayerJoined({required this.player});

  @override
  List<Object?> get props => [player];
}

class PlayerLeft extends GameEvent {
  final String playerId;
  
  const PlayerLeft({required this.playerId});

  @override
  List<Object?> get props => [playerId];
}

class GameStarted extends GameEvent {
  final dynamic gameData;
  
  const GameStarted({required this.gameData});

  @override
  List<Object?> get props => [gameData];
}

class GameEnded extends GameEvent {
  final dynamic gameData;
  
  const GameEnded({required this.gameData});

  @override
  List<Object?> get props => [gameData];
}

class UpdatePlayerName extends GameEvent {
  final String name;
  
  const UpdatePlayerName({required this.name});

  @override
  List<Object?> get props => [name];
} 