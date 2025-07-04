import 'package:flutter/material.dart';
import 'package:ips_mobile/collecting_data.dart';

class CollectDataPage extends StatelessWidget {
  final String buildingName;

  const CollectDataPage({super.key, required this.buildingName});

  void _startCollecting(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectingDataPage(buildingName: buildingName),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          duration: Duration(milliseconds: 1),
          content: Text('Navigating to CollectingData page...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Collect Data - $buildingName')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No Data Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _startCollecting(context),
              child: const Text('Start Collecting Now'),
            ),
          ],
        ),
      ),
    );
  }
}
