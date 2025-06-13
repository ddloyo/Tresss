import 'package:flutter/material.dart';
import 'package:tresss/game/models/player.dart';
import 'package:tresss/theme/app_theme.dart';

class PlayerInfoWidget extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final VoidCallback? onHighestCardRequest;
  final VoidCallback? onLowestCardRequest;
  final bool showStats;
  final bool isCompact;

  const PlayerInfoWidget({
    super.key,
    required this.player,
    this.isCurrentTurn = false,
    this.onHighestCardRequest,
    this.onLowestCardRequest,
    this.showStats = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      color: isCurrentTurn ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: Container(
        width: isCompact ? 120 : 180,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player avatar and name
            _buildPlayerHeader(),
            
            if (!isCompact) ...[
              const SizedBox(height: 8),
              
              // Player stats
              if (showStats) _buildPlayerStats(),
              
              const SizedBox(height: 8),
              
              // Action buttons
              if (onHighestCardRequest != null || onLowestCardRequest != null)
                _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Column(
      children: [
        // Avatar with status indicator
        Stack(
          children: [
            CircleAvatar(
              radius: isCompact ? 20 : 24,
              backgroundColor: _getPlayerAvatarColor(),
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 16 : 18,
                ),
              ),
            ),
            
            // Current turn indicator
            if (isCurrentTurn)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            
            // Bot indicator
            if (player.isBot)
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: isCompact ? 8 : 10,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Player name
        Text(
          player.name,
          style: AppTheme.labelLarge.copyWith(
            fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.normal,
            color: isCurrentTurn ? AppTheme.primaryColor : null,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Host indicator
        if (player.isHost)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: AppTheme.accentColor,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                'Host',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPlayerStats() {
    return Column(
      children: [
        // Hand and trios info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              icon: Icons.style,
              label: 'Hand',
              value: player.handSize.toString(),
            ),
            _buildStatItem(
              icon: Icons.casino,
              label: 'Trios',
              value: player.trioCount.toString(),
              color: player.trioCount > 0 ? AppTheme.successColor : null,
            ),
          ],
        ),
        
        if (player.gamesPlayed > 0) ...[
          const SizedBox(height: 4),
          
          // Win/Loss record
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'Wins',
                value: player.wins.toString(),
                color: AppTheme.successColor,
              ),
              _buildStatItem(
                icon: Icons.close,
                label: 'Losses',
                value: player.losses.toString(),
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey[600],
        ),
        Text(
          value,
          style: AppTheme.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canRequestCards = onHighestCardRequest != null || onLowestCardRequest != null;
    
    if (!canRequestCards || player.hand.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        if (onHighestCardRequest != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onHighestCardRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: const Size(0, 0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Highest',
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        if (onHighestCardRequest != null && onLowestCardRequest != null)
          const SizedBox(height: 4),
        
        if (onLowestCardRequest != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onLowestCardRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: const Size(0, 0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Lowest',
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getPlayerAvatarColor() {
    // Generate a consistent color based on player name hash
    final hash = player.name.hashCode;
    final colors = AppTheme.playerColors;
    return colors[hash.abs() % colors.length];
  }
} 