import 'package:flutter/material.dart';
import 'package:tresss/game/models/card.dart';
import 'package:tresss/theme/app_theme.dart';

enum CardSize { small, medium, large }

class GameCardWidget extends StatelessWidget {
  final GameCard card;
  final bool isRevealed;
  final CardSize size;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool isWinningCard;

  const GameCardWidget({
    super.key,
    required this.card,
    this.isRevealed = true,
    this.size = CardSize.medium,
    this.onTap,
    this.isHighlighted = false,
    this.isWinningCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimensions = _getCardDimensions();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: dimensions.width,
        height: dimensions.height,
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: _getBorderColor(),
            width: isHighlighted ? 3.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(8.0),
          color: _getBackgroundColor(),
          child: isRevealed ? _buildRevealedCard() : _buildHiddenCard(),
        ),
      ),
    );
  }

  CardDimensions _getCardDimensions() {
    switch (size) {
      case CardSize.small:
        return const CardDimensions(width: 50, height: 70);
      case CardSize.medium:
        return const CardDimensions(width: 70, height: 100);
      case CardSize.large:
        return const CardDimensions(width: 90, height: 130);
    }
  }

  Color _getBorderColor() {
    if (isWinningCard) return AppTheme.successColor;
    if (isHighlighted) return AppTheme.primaryColor;
    return AppTheme.cardBorder;
  }

  Color _getBackgroundColor() {
    if (isWinningCard) return AppTheme.successColor.withOpacity(0.1);
    if (isHighlighted) return AppTheme.primaryColor.withOpacity(0.1);
    return AppTheme.cardBackground;
  }

  Widget _buildRevealedCard() {
    final fontSize = _getFontSize();
    final numberColor = _getNumberColor();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Card number in center
          Center(
            child: Text(
              card.number.toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: numberColor,
              ),
            ),
          ),
          
          // Small number in top-left corner
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              card.number.toString(),
              style: TextStyle(
                fontSize: fontSize * 0.4,
                fontWeight: FontWeight.bold,
                color: numberColor.withOpacity(0.7),
              ),
            ),
          ),
          
          // Small number in bottom-right corner (rotated)
          Positioned(
            bottom: 4,
            right: 4,
            child: Transform.rotate(
              angle: 3.14159, // 180 degrees
              child: Text(
                card.number.toString(),
                style: TextStyle(
                  fontSize: fontSize * 0.4,
                  fontWeight: FontWeight.bold,
                  color: numberColor.withOpacity(0.7),
                ),
              ),
            ),
          ),
          
          // Special effects for certain numbers
          if (card.number == 7) _buildSevenEffect(),
          if (card.number == 1) _buildAceEffect(),
          if (card.number == 12) _buildKingEffect(),
        ],
      ),
    );
  }

  Widget _buildHiddenCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.casino,
          color: Colors.white.withOpacity(0.7),
          size: _getFontSize() * 0.8,
        ),
      ),
    );
  }

  Widget _buildSevenEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: AppTheme.accentColor,
            width: 2.0,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.star,
            color: AppTheme.accentColor.withOpacity(0.3),
            size: _getFontSize() * 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAceEffect() {
    return Positioned.fill(
      child: Center(
        child: Icon(
          Icons.diamond,
          color: AppTheme.primaryColor.withOpacity(0.2),
          size: _getFontSize() * 0.6,
        ),
      ),
    );
  }

  Widget _buildKingEffect() {
    return Positioned.fill(
      child: Center(
        child: Icon(
          Icons.crown,
          color: AppTheme.accentColor.withOpacity(0.2),
          size: _getFontSize() * 0.6,
        ),
      ),
    );
  }

  double _getFontSize() {
    switch (size) {
      case CardSize.small:
        return 16.0;
      case CardSize.medium:
        return 24.0;
      case CardSize.large:
        return 32.0;
    }
  }

  Color _getNumberColor() {
    // Different colors for different number ranges
    if (card.number <= 4) {
      return AppTheme.primaryColor;
    } else if (card.number <= 8) {
      return AppTheme.successColor;
    } else {
      return AppTheme.errorColor;
    }
  }
}

class CardDimensions {
  final double width;
  final double height;

  const CardDimensions({
    required this.width,
    required this.height,
  });
} 