import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Hotspot3DMapWidget extends StatefulWidget {
  final String highlightedPoint;

  const Hotspot3DMapWidget({super.key, required this.highlightedPoint});

  @override
  State<Hotspot3DMapWidget> createState() => _Hotspot3DMapWidgetState();
}

class _Hotspot3DMapWidgetState extends State<Hotspot3DMapWidget> {
  WebViewController? _modelViewerController;
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Hotspot3DMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedPoint != oldWidget.highlightedPoint) {
      if (_modelViewerController != null) {
        _updateHotspotPosition(widget.highlightedPoint);
      }
    }
  }

  // Parses the 7-digit string to x, y, z coordinates and floor number.
  // Format: {floor:1 digit}{y:2 digit}{x:2 digit}{z:2 digit}
  // Example: '3000852' -> floor=3, y=0.0, x=80.0, z=520.0
  Map<String, double> _parsePointCoordinates(String pointString) {
    if (pointString.length != 7) {
      debugPrint(
          'Flutter: Invalid point string format: $pointString. Expected 7 digits.');
      return {'x': 0.0, 'y': 0.0, 'z': 0.0, 'floor': 0.0};
    }
    double floor = int.parse(pointString.substring(0, 1)).toDouble();
    double y = int.parse(pointString.substring(1, 3))
        .toDouble(); // Y is now directly from string
    double x = int.parse(pointString.substring(3, 5)).toDouble() *
        10; // X multiplied by 10
    double z = int.parse(pointString.substring(5, 7)).toDouble() *
        10; // Z multiplied by 10

    return {'x': x, 'y': y, 'z': z, 'floor': floor};
  }

  // Generates the initial HTML for the hotspot and the floor header.
  String generateInitialHotspotHtml() {
    final coords = _parsePointCoordinates(widget.highlightedPoint);
    final initialX = coords['x']!;
    final initialY = coords['y']!;
    final initialZ = coords['z']!;
    final initialFloor = coords['floor']!.toInt();

    return '''
        <div id="floor-header" class="floor-header">Floor $initialFloor</div>
        <button slot="hotspot-main-dynamic" class="hotspot-label" data-position="${initialX}m ${initialY}m ${initialZ}m" data-normal="0m 1m 0m">
          <div class="label" id="hotspot-main-label">${widget.highlightedPoint}</div>
        </button>
      ''';
  }

  void _updateHotspotPosition(String highlight) {
    if (_modelViewerController == null) {
      debugPrint(
          'Flutter: ERROR! WebViewController is null during _updateHotspotPosition call.');
      return;
    }

    final coords = _parsePointCoordinates(highlight);
    final x = coords['x']!;
    final y = coords['y']!;
    final z = coords['z']!;
    final floor = coords['floor']!.toInt();

    final jsCommand = '''
      (function() {
        const modelViewer = document.querySelector('model-viewer');
        let hotspot = modelViewer ? modelViewer.querySelector('button[slot="hotspot-main-dynamic"]') : null;
        const floorHeader = document.getElementById('floor-header');

        if (!modelViewer) {
          console.error('JS: model-viewer element not found in updateHotspotPosition.');
          return;
        }

        // Update floor header text
        if (floorHeader) {
          floorHeader.textContent = 'Floor $floor';
        } else {
          console.error('JS: Floor header element not found.');
        }

        // AGGRESSIVE UPDATE: Remove and re-create hotspot to force re-evaluation
        if (hotspot) {
          modelViewer.removeChild(hotspot);
        }

        // Create a new hotspot element with updated attributes
        hotspot = document.createElement('button');
        hotspot.setAttribute('slot', 'hotspot-main-dynamic');
        hotspot.classList.add('hotspot-label');
        hotspot.setAttribute('data-position', `\${$x}m \${$y}m \${$z}m`);
        hotspot.setAttribute('data-normal', '0m 1m 0m'); // Reverted to standard normal

        const labelDiv = document.createElement('div');
        labelDiv.classList.add('label');
        labelDiv.id = 'hotspot-main-label';
        labelDiv.textContent = '$highlight';
        hotspot.appendChild(labelDiv);

        modelViewer.appendChild(hotspot);

        // Force model-viewer to re-evaluate (dispatch resize event)
        window.dispatchEvent(new Event('resize'));

      })();
    ''';

    _modelViewerController!.runJavaScript(jsCommand);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400, // Fixed height for the ModelViewer itself
      child: ModelViewer(
        src: 'assets/kdoj.glb',
        alt: "3D map of building",
        ar: false,
        autoRotate: true,
        cameraControls: true,
        backgroundColor: Colors.white,
        innerModelViewerHtml: generateInitialHotspotHtml(),
        onWebViewCreated: (controller) {
          _modelViewerController = controller;

          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _modelViewerController != null) {
              _modelViewerController!.runJavaScript('''
                (function() {
                  const modelViewer = document.querySelector('model-viewer');
                  if (modelViewer) {
                    modelViewer.addEventListener('model-loaded', () => {
                      if (window.ModelViewerChannel && window.ModelViewerChannel.postMessage) {
                        window.ModelViewerChannel.postMessage('model-loaded');
                      } else {
                        console.error('JS: window.ModelViewerChannel or postMessage is undefined. Channel check failed.');
                      }
                    });
                  } else {
                    console.error('JS: model-viewer element NOT found when trying to attach listener (after delay).');
                  }

                  // Send a test message from JS to Flutter after a short delay
                  setTimeout(() => {
                      if (window.ModelViewerChannel && window.ModelViewerChannel.postMessage) {
                          window.ModelViewerChannel.postMessage('JS_TEST_MESSAGE_CHANNEL_ACTIVE');
                      } else {
                          console.error('JS: Could not send JS_TEST_MESSAGE_CHANNEL_ACTIVE. Channel not ready.');
                      }
                  }, 500);

                })();
              ''');
            }
          });

          _modelViewerController!.setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                // Force initial hotspot update using the current highlightedPoint
                if (!_isModelLoaded) {
                  _updateHotspotPosition(widget.highlightedPoint);
                }
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint(
                    'Flutter: WebView error: ${error.description} (Code: ${error.errorCode})');
              },
            ),
          );
        },
        javascriptChannels: {
          JavascriptChannel(
            'ModelViewerChannel',
            onMessageReceived: (message) {
              if (message.message == 'model-loaded') {
                setState(() {
                  _isModelLoaded = true;
                });
                _updateHotspotPosition(widget.highlightedPoint);
              } else if (message.message == 'JS_TEST_MESSAGE_CHANNEL_ACTIVE') {
                // This channel is for debugging communication, can be removed if not needed
              }
            },
          ),
        },
        relatedCss: '''
          .hotspot-label {
            background: transparent;
            border: none;
          }
          .label {
            padding: 2px 4px;
            background: rgba(0, 0, 0, 0.75);
            color: white;
            border-radius: 3px;
            font-size: 6px;
          }
          .label::after {
            content: "";
            position: absolute;
            bottom: -6px;
            left: 50%;
            margin-left: -5px;
            width: 0;
            height: 0;
            border-left: 5px solid transparent;
            border-right: 5px solid transparent;
            border-top: 6px solid rgba(0, 0, 0, 0.75);
          }

          /* --- CSS for Floor Header --- */
          .floor-header {
            position: absolute;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0, 0, 0, 0.7);
            color: white;
            padding: 8px 12px;
            border-radius: 8px;
            font-family: sans-serif;
            font-size: 18px;
            font-weight: bold;
            z-index: 10;
            pointer-events: none;
          }
        ''',
      ),
    );
  }
}
