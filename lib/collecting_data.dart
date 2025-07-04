import 'package:flutter/material.dart';
import 'package:ips_mobile/building_map.dart';
import 'package:ips_mobile/live_map.dart';
import 'package:ips_mobile/point_position.dart';
import 'package:permission_handler/permission_handler.dart';

class CollectingDataPage extends StatefulWidget {
  final String buildingName;

  const CollectingDataPage({super.key, required this.buildingName});

  @override
  State<CollectingDataPage> createState() => _CollectingDataPageState();
}

class _CollectingDataPageState extends State<CollectingDataPage> {
  final List<String> pointPositions = listPoint;
  //listPoint; // List of point positions (145 total)
  int currentIndex = 0;
  int repeatCycle = 0;
  final int repeatCount = 2;

  double get progress =>
      (repeatCycle * pointPositions.length + currentIndex) /
      (pointPositions.length * repeatCount);

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    _requestLocationPermission();
    //});
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();

    if (!mounted) return; //  Safe check before using context

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(milliseconds: 1),
            content: Text('Location permission is required.')),
      );
    }
  }

  void _collectData() {
    setState(() {
      if (currentIndex < pointPositions.length - 1) {
        currentIndex++;
      } else {
        if (repeatCycle < repeatCount) {
          repeatCycle++;
          currentIndex = 0;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          duration: const Duration(milliseconds: 1),
          content: Text(
              'Collected ${repeatCycle * pointPositions.length + currentIndex} / ${pointPositions.length * repeatCount}')),
    );
  }

  void _onFinish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          duration: Duration(milliseconds: 1),
          content: Text('Collection complete. Proceeding to LiveMap...')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveMapPage(buildingName: widget.buildingName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = repeatCycle >= repeatCount && currentIndex == 0;
    final currentPoint = pointPositions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Collecting Data - ${widget.buildingName}')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Progress: ${(progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          Text(isComplete ? 'Well Done' : 'Current Point: $currentPoint',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Hotspot3DMapWidget(highlightedPoint: currentPoint),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isComplete ? _onFinish : _collectData,
            child: Text(isComplete ? 'Finish' : 'Collect'),
          ),
        ],
      ),
    );
  }
}
