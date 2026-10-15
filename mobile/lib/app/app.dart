import 'package:flutter/material.dart';

import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKFC POS',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('KKFC POS')),
      ),
    );
  }
}