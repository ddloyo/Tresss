# Tresss - Multiplayer Card Game

A Flutter-based multiplayer card game implementation of "Trio" that supports 3-6 players with real-time networking capabilities.

## Game Description

Tresss is a card game where players compete to collect trios (sets of three matching cards) using cards numbered 1-12. Each number has 3 copies, making a total of 36 cards in the deck.

### Game Rules

- **Objective**: Be the first to collect 3 trios OR collect the trio of 7s to win instantly
- **Setup**: Each player receives 5 cards, remaining cards are placed face-down on the table
- **Gameplay**: 
  - Players take turns trying to form trios by revealing cards
  - On your turn, you can:
    - Reveal a card from the table (flip face-down card)
    - Ask any player (including yourself) to show their highest or lowest card
  - If you find a card matching your first revealed card, you can continue searching for the third
  - Your turn ends when you either complete a trio or fail to find a matching card
  - When you complete a trio, you keep it and your turn ends

### Features

- **Multiplayer Support**: 3-6 players per game
- **Real-time Networking**: Socket.io based multiplayer with remote connections
- **Cross-platform**: Android and iOS support via Flutter
- **Bot Players**: AI players can fill empty slots (planned feature)
- **Modern UI**: Beautiful card-based interface with animations
- **Game State Management**: Robust state management using BLoC pattern

## Technical Architecture

### Core Technologies
- **Flutter**: Cross-platform mobile app development
- **Dart**: Programming language
- **Socket.io**: Real-time bidirectional communication
- **BLoC**: State management pattern
- **Provider**: Dependency injection

### Project Structure

```
lib/
├── main.dart                      # App entry point
├── game/
│   ├── models/                    # Game data models
│   │   ├── card.dart             # Card and Trio models
│   │   ├── player.dart           # Player model
│   │   └── game_state.dart       # Game state model
│   ├── services/                  # Business logic services
│   │   ├── socket_service.dart   # Network communication
│   │   └── game_service.dart     # Game logic and rules
│   └── bloc/                      # State management
│       ├── game_bloc.dart        # Main game BLoC
│       ├── game_event.dart       # Game events
│       └── game_state.dart       # UI state definitions
├── screens/                       # UI screens
│   ├── home_screen.dart          # Main menu and game setup
│   └── game_screen.dart          # Active game interface
├── widgets/                       # Reusable UI components
│   ├── game_card_widget.dart     # Card display widget
│   ├── player_info_widget.dart   # Player information display
│   └── game_table_widget.dart    # Game table with cards
└── theme/
    └── app_theme.dart            # App styling and colors
```

### Key Components

1. **Game Models**:
   - `GameCard`: Represents individual cards (1-12)
   - `Trio`: Represents a completed set of three matching cards
   - `Player`: Player information, hand, collected trios, stats
   - `GameState`: Complete game state including players, table, current turn

2. **Services**:
   - `SocketService`: Handles real-time multiplayer communication
   - `GameService`: Implements game rules, validation, and logic

3. **UI Components**:
   - `GameCardWidget`: Displays cards with different states and sizes
   - `PlayerInfoWidget`: Shows player stats and interaction buttons
   - `GameTableWidget`: Main game table with card grid

## Getting Started

### Prerequisites

- Flutter SDK (3.1.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development
- A Trio game server (Socket.io based) - *not included in this repository*

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Tresss-1
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Configuration

Update the server URL in `lib/game/services/socket_service.dart`:
```dart
static const String _serverUrl = 'http://your-server-url:3000';
```

## Multiplayer Server

This client requires a Socket.io server that implements the Trio game protocol. The server should handle:

- Room management (create/join/leave)
- Game state synchronization
- Turn management
- Move validation
- Player connections/disconnections

### Socket Events

**Client to Server:**
- `join_room`: Join a game room
- `leave_room`: Leave current room  
- `make_move`: Make a game move

**Server to Client:**
- `game_state`: Updated game state
- `player_joined`: New player joined
- `player_left`: Player disconnected
- `game_started`: Game began
- `game_ended`: Game finished

## Development Status

### Completed Features
- ✅ Complete game logic and rules implementation
- ✅ Beautiful card-based UI with animations
- ✅ Multiplayer networking foundation
- ✅ Game state management with BLoC
- ✅ Player management and statistics
- ✅ Cross-platform Flutter architecture

### Planned Features
- 🔄 Bot/AI players
- 🔄 Game server implementation
- 🔄 Sound effects and animations
- 🔄 Tournament mode
- 🔄 Spectator mode
- 🔄 Game replay system

## Contributing

This project is set up for multiplayer Trio card game development. Contributions are welcome for:

- Game server implementation
- UI/UX improvements
- Bot player AI
- Additional game features
- Bug fixes and optimizations

## License

[Add your chosen license here]