import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tresss/game/bloc/game_bloc.dart';
import 'package:tresss/game/services/socket_service.dart';
import 'package:tresss/game/services/game_service.dart';
import 'package:tresss/screens/home_screen.dart';
import 'package:tresss/theme/app_theme.dart';

void main() {
  runApp(const TresssApp());
}

class TresssApp extends StatelessWidget {
  const TresssApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SocketService>(create: (_) => SocketService()),
        Provider<GameService>(create: (_) => GameService()),
      ],
      child: BlocProvider(
        create: (context) => GameBloc(
          socketService: context.read<SocketService>(),
          gameService: context.read<GameService>(),
        ),
        child: MaterialApp(
          title: 'Tresss - Multiplayer Tic Tac Toe',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
} 