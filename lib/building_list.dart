import 'package:flutter/material.dart';
import 'package:ips_mobile/collect_data.dart';

class BuildingListPage extends StatelessWidget {
  const BuildingListPage({super.key});

  void _onBuildingTap(BuildContext context, String buildingName) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CollectDataPage(buildingName: buildingName)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          duration: const Duration(milliseconds: 1),
          content: Text('Building "$buildingName" tapped. Navigate next...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Building')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _onBuildingTap(context, 'XB1'),
              child: const Text('XB1'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _onBuildingTap(context, 'XB2'),
              child: const Text('XB2'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _onBuildingTap(context, 'XC1'),
              child: const Text('XC1'),
            ),
          ],
        ),
      ),
    );
  }
}
