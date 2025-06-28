import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tresss/game/bloc/game_bloc.dart';
import 'package:tresss/game/bloc/game_event.dart';
import 'package:tresss/game/bloc/game_state.dart';
import 'package:tresss/game/models/player.dart';
import 'package:tresss/screens/game_screen.dart';
import 'package:tresss/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gameIdController = TextEditingController();
  final Uuid _uuid = const Uuid();
  
  Player? _currentPlayer;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Player';
    
    // Connect to server on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameBloc>().add(const ConnectToServer());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameIdController.dispose();
    super.dispose();
  }

  void _updatePlayerName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      context.read<GameBloc>().add(UpdatePlayerName(name: name));
      _currentPlayer = Player(
        id: _currentPlayer?.id ?? _uuid.v4(),
        name: name,
      );
    }
  }

  void _createGame() {
    _updatePlayerName();
    if (_currentPlayer != null) {
      context.read<GameBloc>().add(CreateGame(player: _currentPlayer!));
    }
  }

  void _joinGame() {
    _updatePlayerName();
    final gameId = _gameIdController.text.trim();
    if (gameId.isNotEmpty && _currentPlayer != null) {
      context.read<GameBloc>().add(JoinGame(
        gameId: gameId,
        player: _currentPlayer!,
      ));
    } else {
      _showSnackBar('Please enter a valid game ID');
    }
  }

  void _joinRandomGame() {
    _updatePlayerName();
    if (_currentPlayer != null) {
      context.read<GameBloc>().add(JoinRandomGame(player: _currentPlayer!));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trio - Multiplayer Card Game'),
        elevation: 0,
      ),
      body: BlocConsumer<GameBloc, GameBlocState>(
        listener: (context, state) {
          if (state is GameError) {
            _showSnackBar(state.message);
          } else if (state is GameWaitingForPlayer ||
                     state is GameInProgress ||
                     state is GameFinished) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const GameScreen(),
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status
                _buildConnectionStatus(state),
                
                const SizedBox(height: 24),
                
                // Game Rules Card
                _buildGameRulesCard(),
                
                const SizedBox(height: 24),
                
                // Player Setup
                _buildPlayerSetup(),
                
                const SizedBox(height: 24),
                
                // Game Actions
                if (state is GameConnected) _buildGameActions(),
                
                const Spacer(),
                
                // App Info
                _buildAppInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(GameBlocState state) {
    IconData icon;
    String text;
    Color color;

    if (state is GameConnecting) {
      icon = Icons.wifi_find;
      text = 'Connecting to server...';
      color = AppTheme.warningColor;
    } else if (state is GameConnected) {
      icon = Icons.wifi;
      text = 'Connected to server';
      color = AppTheme.successColor;
    } else if (state is GameLoading) {
      icon = Icons.hourglass_empty;
      text = state.message;
      color = AppTheme.warningColor;
    } else {
      icon = Icons.wifi_off;
      text = 'Disconnected from server';
      color = AppTheme.errorColor;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTheme.bodyMedium.copyWith(color: color),
              ),
            ),
            if (state is GameConnecting || state is GameLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameRulesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Game Rules', style: AppTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Cards numbered 1-12 (3 of each = 36 total)\n'
              '• Win by collecting 3 trios OR the trio of 7s\n'
              '• Each player starts with 5 cards\n'
              '• Take turns revealing cards to find trios\n'
              '• Reveal table cards or ask for highest/lowest from players\n'
              '• Turn ends when you fail to find a matching card',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSetup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Player Setup', style: AppTheme.titleSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your player name',
                prefixIcon: Icon(Icons.person),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _updatePlayerName(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Game Actions', style: AppTheme.titleSmall),
        const SizedBox(height: 16),
        
        // Create Game
        ElevatedButton.icon(
          onPressed: _createGame,
          icon: const Icon(Icons.add_circle),
          label: const Text('Create New Game'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Join Specific Game
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _gameIdController,
                decoration: const InputDecoration(
                  labelText: 'Game ID',
                  hintText: 'Enter game ID to join',
                  prefixIcon: Icon(Icons.tag),
                ),
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _joinGame(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _joinGame,
              child: const Text('Join'),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Join Random Game
        OutlinedButton.icon(
          onPressed: _joinRandomGame,
          icon: const Icon(Icons.casino),
          label: const Text('Join Random Game'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Trio v1.0.0',
                  style: AppTheme.labelMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Multiplayer card game for 3-6 players',
              style: AppTheme.labelMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 