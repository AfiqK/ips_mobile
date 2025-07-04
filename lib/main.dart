import 'package:flutter/material.dart';
import 'building_list.dart';

void main() => runApp(const IndoorPositioningApp());

class IndoorPositioningApp extends StatelessWidget {
  const IndoorPositioningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Indoor Positioning App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indoor Positioning App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Indoor Positioning App',
                style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BuildingListPage()),
                );
              },
              child: const Text('Locate Now'),
            ),
          ],
        ),
      ),
    );
  }
}
