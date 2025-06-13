import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:tresss/game/bloc/game_event.dart';
import 'package:tresss/game/bloc/game_state.dart';
import 'package:tresss/game/models/game_state.dart' as models;
import 'package:tresss/game/models/player.dart';
import 'package:tresss/game/services/socket_service.dart';
import 'package:tresss/game/services/game_service.dart';

class GameBloc extends Bloc<GameEvent, GameBlocState> {
  final SocketService _socketService;
  final GameService _gameService;
  final Uuid _uuid = const Uuid();
  
  Player? _currentPlayer;
  models.GameState? _gameState;
  
  GameBloc({
    required SocketService socketService,
    required GameService gameService,
  }) : _socketService = socketService,
       _gameService = gameService,
       super(const GameInitial()) {
    
    // Register event handlers
    on<ConnectToServer>(_onConnectToServer);
    on<DisconnectFromServer>(_onDisconnectFromServer);
    on<CreateGame>(_onCreateGame);
    on<JoinGame>(_onJoinGame);
    on<JoinRandomGame>(_onJoinRandomGame);
    on<LeaveGame>(_onLeaveGame);
    on<MakeMove>(_onMakeMove);
    on<ResetGame>(_onResetGame);
    on<GameStateUpdated>(_onGameStateUpdated);
    on<PlayerJoined>(_onPlayerJoined);
    on<PlayerLeft>(_onPlayerLeft);
    on<GameStarted>(_onGameStarted);
    on<GameEnded>(_onGameEnded);
    on<UpdatePlayerName>(_onUpdatePlayerName);

    // Initialize socket listeners
    _setupSocketListeners();
    
    // Load saved player data
    _loadPlayerData();
  }

  void _setupSocketListeners() {
    _socketService.onGameStateUpdate((gameState) {
      add(GameStateUpdated(gameData: gameState));
    });

    _socketService.onPlayerJoined((player) {
      add(PlayerJoined(player: player));
    });

    _socketService.onPlayerLeft((playerId) {
      add(PlayerLeft(playerId: playerId));
    });

    _socketService.onGameStarted((gameState) {
      add(GameStarted(gameData: gameState));
    });

    _socketService.onGameEnded((gameState) {
      add(GameEnded(gameData: gameState));
    });
  }

  Future<void> _loadPlayerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playerName = prefs.getString('player_name') ?? 'Player';
      final playerId = prefs.getString('player_id') ?? _uuid.v4();
      
      if (!prefs.containsKey('player_id')) {
        await prefs.setString('player_id', playerId);
      }
      
      _currentPlayer = Player(
        id: playerId,
        name: playerName,
      );
    } catch (e) {
      log('Error loading player data: $e');
      _currentPlayer = Player(
        id: _uuid.v4(),
        name: 'Player',
      );
    }
  }

  Future<void> _savePlayerData() async {
    if (_currentPlayer == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('player_name', _currentPlayer!.name);
      await prefs.setString('player_id', _currentPlayer!.id);
    } catch (e) {
      log('Error saving player data: $e');
    }
  }

  Future<void> _onConnectToServer(ConnectToServer event, Emitter<GameBlocState> emit) async {
    emit(const GameConnecting());
    
    try {
      _socketService.connect();
      
      // Wait a bit for connection to establish
      await Future.delayed(const Duration(seconds: 1));
      
      if (_socketService.isConnected) {
        emit(const GameConnected());
      } else {
        emit(const GameDisconnected(reason: 'Failed to connect to server'));
      }
    } catch (e) {
      emit(GameDisconnected(reason: 'Connection error: $e'));
    }
  }

  Future<void> _onDisconnectFromServer(DisconnectFromServer event, Emitter<GameBlocState> emit) async {
    _socketService.disconnect();
    _gameState = null;
    emit(const GameDisconnected());
  }

  Future<void> _onCreateGame(CreateGame event, Emitter<GameBlocState> emit) async {
    if (!_socketService.isConnected) {
      emit(const GameError(message: 'Not connected to server'));
      return;
    }

    emit(const GameLoading(message: 'Creating game...'));
    
    try {
      _currentPlayer = event.player;
      await _savePlayerData();
      
      final gameState = _gameService.createNewGame(null);
      final updatedGameState = _gameService.addPlayer(gameState, event.player);
      
      _gameState = updatedGameState;
      _socketService.joinRoom(updatedGameState.gameId, event.player);
      
      emit(GameWaitingForPlayer(
        gameState: updatedGameState,
        currentPlayer: event.player,
      ));
    } catch (e) {
      emit(GameError(message: 'Failed to create game: $e'));
    }
  }

  Future<void> _onJoinGame(JoinGame event, Emitter<GameBlocState> emit) async {
    if (!_socketService.isConnected) {
      emit(const GameError(message: 'Not connected to server'));
      return;
    }

    emit(const GameLoading(message: 'Joining game...'));
    
    try {
      _currentPlayer = event.player;
      await _savePlayerData();
      
      _socketService.joinRoom(event.gameId, event.player);
      
      // Wait for server response
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      emit(GameError(message: 'Failed to join game: $e'));
    }
  }

  Future<void> _onJoinRandomGame(JoinRandomGame event, Emitter<GameBlocState> emit) async {
    if (!_socketService.isConnected) {
      emit(const GameError(message: 'Not connected to server'));
      return;
    }

    emit(const GameLoading(message: 'Finding game...'));
    
    try {
      _currentPlayer = event.player;
      await _savePlayerData();
      
      // For now, create a new game if no random game is available
      // In a real implementation, this would search for available games
      add(CreateGame(player: event.player));
      
    } catch (e) {
      emit(GameError(message: 'Failed to find game: $e'));
    }
  }

  Future<void> _onLeaveGame(LeaveGame event, Emitter<GameBlocState> emit) async {
    if (_gameState != null) {
      _socketService.leaveRoom(_gameState!.gameId);
    }
    
    _gameState = null;
    
    if (_socketService.isConnected) {
      emit(const GameConnected());
    } else {
      emit(const GameDisconnected());
    }
  }

  Future<void> _onMakeMove(MakeMove event, Emitter<GameBlocState> emit) async {
    if (_gameState == null || _currentPlayer == null) {
      return;
    }

    // This is a placeholder - in the real game, you'd have different types of moves
    // For now, we'll assume it's revealing a table card
    if (event.row >= 0 && event.col >= 0) {
      final cardIndex = event.row * 10 + event.col; // Convert coordinates to index
      _socketService.makeMove(_gameState!.gameId, event.row, event.col, _currentPlayer!.id);
    }
  }

  Future<void> _onResetGame(ResetGame event, Emitter<GameBlocState> emit) async {
    if (_gameState == null) return;
    
    try {
      final newGameState = _gameService.resetGame(_gameState!);
      _gameState = newGameState;
      
      if (newGameState.isGameActive && _currentPlayer != null) {
        final isMyTurn = newGameState.currentPlayer?.id == _currentPlayer!.id;
        emit(GameInProgress(
          gameState: newGameState,
          currentPlayer: _currentPlayer!,
          isMyTurn: isMyTurn,
        ));
      }
    } catch (e) {
      emit(GameError(message: 'Failed to reset game: $e'));
    }
  }

  Future<void> _onGameStateUpdated(GameStateUpdated event, Emitter<GameBlocState> emit) async {
    try {
      final gameState = event.gameData is models.GameState 
          ? event.gameData as models.GameState
          : models.GameState.fromJson(event.gameData);
      
      _gameState = gameState;
      
      if (_currentPlayer == null) return;
      
      _emitGameState(gameState, emit);
    } catch (e) {
      emit(GameError(message: 'Failed to update game state: $e'));
    }
  }

  Future<void> _onPlayerJoined(PlayerJoined event, Emitter<GameBlocState> emit) async {
    if (_gameState == null) return;
    
    try {
      final updatedGameState = _gameService.addPlayer(_gameState!, event.player);
      _gameState = updatedGameState;
      
      if (_currentPlayer != null) {
        _emitGameState(updatedGameState, emit);
      }
    } catch (e) {
      emit(GameError(message: 'Failed to add player: $e'));
    }
  }

  Future<void> _onPlayerLeft(PlayerLeft event, Emitter<GameBlocState> emit) async {
    if (_gameState == null) return;
    
    try {
      final updatedGameState = _gameService.removePlayer(_gameState!, event.playerId);
      _gameState = updatedGameState;
      
      if (_currentPlayer != null) {
        _emitGameState(updatedGameState, emit);
      }
    } catch (e) {
      emit(GameError(message: 'Failed to remove player: $e'));
    }
  }

  Future<void> _onGameStarted(GameStarted event, Emitter<GameBlocState> emit) async {
    try {
      final gameState = event.gameData is models.GameState 
          ? event.gameData as models.GameState
          : models.GameState.fromJson(event.gameData);
      
      _gameState = gameState;
      
      if (_currentPlayer != null) {
        _emitGameState(gameState, emit);
      }
    } catch (e) {
      emit(GameError(message: 'Failed to start game: $e'));
    }
  }

  Future<void> _onGameEnded(GameEnded event, Emitter<GameBlocState> emit) async {
    try {
      final gameState = event.gameData is models.GameState 
          ? event.gameData as models.GameState
          : models.GameState.fromJson(event.gameData);
      
      _gameState = gameState;
      
      if (_currentPlayer != null) {
        _emitGameState(gameState, emit);
      }
    } catch (e) {
      emit(GameError(message: 'Failed to end game: $e'));
    }
  }

  Future<void> _onUpdatePlayerName(UpdatePlayerName event, Emitter<GameBlocState> emit) async {
    if (_currentPlayer == null) return;
    
    _currentPlayer = _currentPlayer!.copyWith(name: event.name);
    await _savePlayerData();
  }

  void _emitGameState(models.GameState gameState, Emitter<GameBlocState> emit) {
    if (_currentPlayer == null) return;
    
    if (gameState.isWaitingForPlayer) {
      emit(GameWaitingForPlayer(
        gameState: gameState,
        currentPlayer: _currentPlayer!,
      ));
    } else if (gameState.isGameActive) {
      final isMyTurn = gameState.currentPlayer?.id == _currentPlayer!.id;
      emit(GameInProgress(
        gameState: gameState,
        currentPlayer: _currentPlayer!,
        isMyTurn: isMyTurn,
      ));
    } else if (gameState.isGameFinished) {
      final winner = _gameService.getWinner(gameState);
      final isWinner = winner?.id == _currentPlayer!.id;
      emit(GameFinished(
        gameState: gameState,
        currentPlayer: _currentPlayer!,
        winner: winner,
        isWinner: isWinner,
      ));
    }
  }

  @override
  Future<void> close() {
    _socketService.removeAllListeners();
    _socketService.disconnect();
    return super.close();
  }
} 