import 'package:flutter/material.dart';
import 'package:xfutebol_flutter_bridge/xfutebol_flutter_bridge.dart';

import 'src/game/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the Rust bridge
  await XfutebolBridge.init();
  
  runApp(const XfutebolApp());
}

class XfutebolApp extends StatelessWidget {
  const XfutebolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xfutebol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Green
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
