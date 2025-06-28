import 'package:flutter/material.dart';
import 'package:tresss/game/models/game_state.dart';
import 'package:tresss/theme/app_theme.dart';
import 'package:tresss/widgets/game_card_widget.dart';

class GameTableWidget extends StatelessWidget {
  final GameState gameState;
  final bool isMyTurn;
  final Function(int)? onTableCardTap;

  const GameTableWidget({
    super.key,
    required this.gameState,
    required this.isMyTurn,
    this.onTableCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.tableGreen,
            AppTheme.tableGreen.withOpacity(0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Turn status and revealed cards section
            _buildTurnSection(),
            
            const SizedBox(height: 20),
            
            // Table cards grid
            Expanded(
              child: _buildTableCardsGrid(),
            ),
            
            // Table info
            _buildTableInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnSection() {
    if (gameState.currentTurn.revealedCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.touch_app,
              color: isMyTurn ? AppTheme.successColor : AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isMyTurn 
                    ? 'Tap a card to reveal it'
                    : 'Waiting for ${gameState.currentPlayer?.name ?? "player"} to make a move',
                style: AppTheme.bodyMedium.copyWith(
                  color: isMyTurn ? AppTheme.successColor : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Turn - Looking for: ${gameState.currentTurn.targetNumber}',
            style: AppTheme.titleSmall.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Found: ${gameState.currentTurn.foundCount}/3 cards',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          
          // Revealed cards in this turn
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: gameState.currentTurn.revealedCards.map((card) {
                final isMatching = card.number == gameState.currentTurn.targetNumber;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GameCardWidget(
                    card: card,
                    isRevealed: true,
                    size: CardSize.small,
                    isHighlighted: isMatching,
                    isWinningCard: isMatching,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCardsGrid() {
    final cardsPerRow = _calculateCardsPerRow();
    final totalCards = gameState.tableDeck.length;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cardsPerRow,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7, // Card aspect ratio
      ),
      itemCount: totalCards,
      itemBuilder: (context, index) {
        return GameCardWidget(
          card: gameState.tableDeck[index],
          isRevealed: false,
          size: CardSize.medium,
          onTap: isMyTurn ? () => onTableCardTap?.call(index) : null,
          isHighlighted: isMyTurn,
        );
      },
    );
  }

  Widget _buildTableInfo() {
    final revealedCount = gameState.revealedTableCards.length;
    final totalTableCards = gameState.tableDeck.length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.visibility_off,
                label: 'Hidden Cards',
                value: totalTableCards.toString(),
                color: AppTheme.primaryColor,
              ),
              _buildInfoItem(
                icon: Icons.visibility,
                label: 'Revealed Cards',
                value: revealedCount.toString(),
                color: AppTheme.successColor,
              ),
              _buildInfoItem(
                icon: Icons.people,
                label: 'Players',
                value: gameState.players.length.toString(),
                color: AppTheme.accentColor,
              ),
            ],
          ),
          
          if (gameState.revealedTableCards.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Revealed Table Cards',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: gameState.revealedTableCards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: GameCardWidget(
                      card: card,
                      isRevealed: true,
                      size: CardSize.small,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int _calculateCardsPerRow() {
    final totalCards = gameState.tableDeck.length;
    
    // Adjust grid based on number of cards for better layout
    if (totalCards <= 6) return 3;
    if (totalCards <= 12) return 4;
    if (totalCards <= 20) return 5;
    return 6;
  }
} 