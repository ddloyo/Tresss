import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:tresss/game/models/game_state.dart';
import 'package:tresss/game/models/player.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Server configuration - change this to your server URL
  static const String _serverUrl = 'http://localhost:3000';
  
  // Event names
  static const String _connectEvent = 'connect';
  static const String _disconnectEvent = 'disconnect';
  static const String _joinRoomEvent = 'join_room';
  static const String _leaveRoomEvent = 'leave_room';
  static const String _makeMoveEvent = 'make_move';
  static const String _gameStateEvent = 'game_state';
  static const String _playerJoinedEvent = 'player_joined';
  static const String _playerLeftEvent = 'player_left';
  static const String _gameStartedEvent = 'game_started';
  static const String _gameEndedEvent = 'game_ended';
  static const String _errorEvent = 'error';

  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  // Initialize socket connection
  void connect() {
    if (_socket != null && _isConnected) {
      log('Socket already connected');
      return;
    }

    try {
      _socket = IO.io(_serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();
      _setupEventHandlers();
      
      log('Attempting to connect to server: $_serverUrl');
    } catch (e) {
      log('Error connecting to server: $e');
    }
  }

  // Disconnect from server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      log('Disconnected from server');
    }
  }

  // Setup socket event handlers
  void _setupEventHandlers() {
    _socket!.on(_connectEvent, (data) {
      _isConnected = true;
      log('Connected to server');
    });

    _socket!.on(_disconnectEvent, (data) {
      _isConnected = false;
      log('Disconnected from server');
    });

    _socket!.on(_errorEvent, (data) {
      log('Socket error: $data');
    });
  }

  // Join a game room
  void joinRoom(String roomId, Player player) {
    if (_socket != null && _isConnected) {
      _socket!.emit(_joinRoomEvent, {
        'roomId': roomId,
        'player': player.toJson(),
      });
      log('Joining room: $roomId');
    } else {
      log('Cannot join room: Socket not connected');
    }
  }

  // Leave current room
  void leaveRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit(_leaveRoomEvent, {'roomId': roomId});
      log('Leaving room: $roomId');
    }
  }

  // Make a move in the game
  void makeMove(String roomId, int row, int col, String playerId) {
    if (_socket != null && _isConnected) {
      _socket!.emit(_makeMoveEvent, {
        'roomId': roomId,
        'row': row,
        'col': col,
        'playerId': playerId,
      });
      log('Making move: ($row, $col) in room $roomId');
    }
  }

  // Listen for game state updates
  void onGameStateUpdate(Function(GameState) callback) {
    _socket?.on(_gameStateEvent, (data) {
      try {
        final gameState = GameState.fromJson(data);
        callback(gameState);
        log('Game state updated');
      } catch (e) {
        log('Error parsing game state: $e');
      }
    });
  }

  // Listen for player joined events
  void onPlayerJoined(Function(Player) callback) {
    _socket?.on(_playerJoinedEvent, (data) {
      try {
        final player = Player.fromJson(data);
        callback(player);
        log('Player joined: ${player.name}');
      } catch (e) {
        log('Error parsing player data: $e');
      }
    });
  }

  // Listen for player left events
  void onPlayerLeft(Function(String) callback) {
    _socket?.on(_playerLeftEvent, (data) {
      final playerId = data['playerId'] as String;
      callback(playerId);
      log('Player left: $playerId');
    });
  }

  // Listen for game started events
  void onGameStarted(Function(GameState) callback) {
    _socket?.on(_gameStartedEvent, (data) {
      try {
        final gameState = GameState.fromJson(data);
        callback(gameState);
        log('Game started');
      } catch (e) {
        log('Error parsing game start data: $e');
      }
    });
  }

  // Listen for game ended events
  void onGameEnded(Function(GameState) callback) {
    _socket?.on(_gameEndedEvent, (data) {
      try {
        final gameState = GameState.fromJson(data);
        callback(gameState);
        log('Game ended');
      } catch (e) {
        log('Error parsing game end data: $e');
      }
    });
  }

  // Remove all event listeners
  void removeAllListeners() {
    _socket?.clearListeners();
  }

  // Remove specific event listener
  void removeListener(String event) {
    _socket?.off(event);
  }
} 