import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveMapPage extends StatefulWidget {
  final String buildingName;

  const LiveMapPage({super.key, required this.buildingName});

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  int currentPoint = -1; // Placeholder for current detected position

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _fetchLocation();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!mounted) return; //  Safe check before using context
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required.')),
      );
    }
  }

  Future<void> _fetchLocation() async {
    // TODO: Replace with WiFi RSSI fetching & server call
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      currentPoint = 42; // Simulated result from API
    });
    if (!mounted) return; //  Safe check before using context
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User located at point $currentPoint')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Map - ${widget.buildingName}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Interactive 3D Map (placeholder)'),
            const SizedBox(height: 20),
            const Icon(Icons.map_outlined, size: 100, color: Colors.blueGrey),
            const SizedBox(height: 20),
            Text(
              currentPoint == -1
                  ? 'Locating user...'
                  : 'Current Position Point: $currentPoint',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
