import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tresss/game/bloc/game_bloc.dart';
import 'package:tresss/game/bloc/game_event.dart';
import 'package:tresss/game/bloc/game_state.dart';
import 'package:tresss/game/models/game_state.dart' as models;
import 'package:tresss/game/models/player.dart';
import 'package:tresss/game/models/card.dart';
import 'package:tresss/theme/app_theme.dart';
import 'package:tresss/widgets/game_card_widget.dart';
import 'package:tresss/widgets/player_info_widget.dart';
import 'package:tresss/widgets/game_table_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyGameId(String gameId) {
    Clipboard.setData(ClipboardData(text: gameId));
    _showSnackBar('Game ID copied to clipboard');
  }

  void _leaveGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game'),
        content: const Text('Are you sure you want to leave the game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GameBloc>().add(const LeaveGame());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trio Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _leaveGame,
            tooltip: 'Leave Game',
          ),
        ],
      ),
      body: BlocConsumer<GameBloc, GameBlocState>(
        listener: (context, state) {
          if (state is GameError) {
            _showSnackBar(state.message);
          } else if (state is GameFinished) {
            _showGameEndDialog(state);
          }
        },
        builder: (context, state) {
          if (state is GameWaitingForPlayer) {
            return _buildWaitingScreen(state);
          } else if (state is GameInProgress) {
            return _buildGameScreen(state);
          } else if (state is GameFinished) {
            return _buildGameFinishedScreen(state);
          } else if (state is GameLoading) {
            return _buildLoadingScreen(state.message);
          } else {
            return _buildErrorScreen();
          }
        },
      ),
    );
  }

  Widget _buildWaitingScreen(GameWaitingForPlayer state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 64,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Waiting for Players',
                    style: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Need ${state.gameState.minPlayers - state.gameState.players.length} more players to start',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Game ID: ${state.gameState.gameId}',
                        style: AppTheme.labelLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyGameId(state.gameState.gameId),
                        tooltip: 'Copy Game ID',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPlayersList(state.gameState.players),
        ],
      ),
    );
  }

  Widget _buildGameScreen(GameInProgress state) {
    return Column(
      children: [
        // Game header with current turn info
        _buildGameHeader(state),
        
        // Other players
        if (state.gameState.players.length > 1)
          _buildOtherPlayers(state),
        
        // Game table
        Expanded(
          child: GameTableWidget(
            gameState: state.gameState,
            isMyTurn: state.isMyTurn,
            onTableCardTap: (index) {
              if (state.isMyTurn) {
                context.read<GameBloc>().add(MakeMove(row: index ~/ 10, col: index % 10));
              }
            },
          ),
        ),
        
        // Current player's hand
        _buildPlayerHand(state),
      ],
    );
  }

  Widget _buildGameFinishedScreen(GameFinished state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    state.isWinner ? Icons.emoji_events : Icons.sentiment_neutral,
                    size: 64,
                    color: state.isWinner ? AppTheme.successColor : AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.isWinner ? 'Congratulations!' : 'Game Over',
                    style: AppTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (state.winner != null)
                    Text(
                      '${state.winner!.name} wins!',
                      style: AppTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.read<GameBloc>().add(const ResetGame());
                        },
                        child: const Text('Play Again'),
                      ),
                      OutlinedButton(
                        onPressed: _leaveGame,
                        child: const Text('Leave Game'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _leaveGame,
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(GameInProgress state) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Round ${state.gameState.round}',
                    style: AppTheme.labelMedium,
                  ),
                  Text(
                    state.isMyTurn 
                        ? 'Your Turn' 
                        : '${state.gameState.currentPlayer?.name}\'s Turn',
                    style: AppTheme.titleSmall.copyWith(
                      color: state.isMyTurn ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (state.gameState.currentTurn.targetNumber > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Looking for: ${state.gameState.currentTurn.targetNumber}',
                  style: AppTheme.labelMedium.copyWith(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherPlayers(GameInProgress state) {
    final otherPlayers = state.gameState.players
        .where((p) => p.id != state.currentPlayer.id)
        .toList();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: otherPlayers.length,
        itemBuilder: (context, index) {
          return PlayerInfoWidget(
            player: otherPlayers[index],
            isCurrentTurn: state.gameState.currentPlayer?.id == otherPlayers[index].id,
            onHighestCardRequest: state.isMyTurn ? () {
              // TODO: Implement highest card request
            } : null,
            onLowestCardRequest: state.isMyTurn ? () {
              // TODO: Implement lowest card request
            } : null,
          );
        },
      ),
    );
  }

  Widget _buildPlayerHand(GameInProgress state) {
    final currentPlayer = state.gameState.players
        .firstWhere((p) => p.id == state.currentPlayer.id);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            'Your Hand (${currentPlayer.hand.length} cards)',
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currentPlayer.hand.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: GameCardWidget(
                    card: currentPlayer.hand[index],
                    isRevealed: true,
                    size: CardSize.small,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(List<Player> players) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Players (${players.length})', style: AppTheme.titleSmall),
            const SizedBox(height: 12),
            ...players.map((player) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.getPlayerColor(players.indexOf(player)),
                    child: Text(
                      player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player.name,
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                  if (player.isHost)
                    Icon(
                      Icons.star,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                  if (player.isBot)
                    Icon(
                      Icons.smart_toy,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showGameEndDialog(GameFinished state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(state.isWinner ? 'You Win!' : 'Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.isWinner ? Icons.emoji_events : Icons.sentiment_neutral,
              size: 48,
              color: state.isWinner ? AppTheme.successColor : AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            if (state.winner != null)
              Text(
                '${state.winner!.name} wins the game!',
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GameBloc>().add(const ResetGame());
            },
            child: const Text('Play Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGame();
            },
            child: const Text('Leave Game'),
          ),
        ],
      ),
    );
  }
} 