import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/oposiciones/oposiciones_widget.dart';
import 'presentation/premium/premium_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(OposiworkApp());
}

class OposiworkApp extends StatefulWidget {
  @override
  State<OposiworkApp> createState() => _OposiworkAppState();
}

class _OposiworkAppState extends State<OposiworkApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    OposicionesWidget(),
    PremiumScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oposiwork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_selectedIndex == 0 ? 'Oposiciones' : 'Zona Premium'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _screens[_selectedIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Oposiciones'),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Premium'),
          ],
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
