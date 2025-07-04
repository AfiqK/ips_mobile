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

  // Define each floor adds this much height in meters
  // Adjust this value based on your model's actual scale for vertical separation
  //static const double _floorHeight = 3.0;

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

  // Parses the 7-digit string to x, y, and z coordinates (multiplied by 10 for x/z)
  // Example: '3000852' -> floor=3, y=00, x=80, z=520
  Map<String, double> _parsePointCoordinates(String pointString) {
    if (pointString.length != 7) {
      // Keep error logs for invalid input formats
      debugPrint(
          'Flutter: Invalid point string format: $pointString. Expected 7 digits.');
      return {'x': 0.0, 'y': 0.0, 'z': 0.0};
    }
    //int floor = int.parse(pointString.substring(0, 1));
    double y = int.parse(pointString.substring(1, 3)).toDouble();
    double x = int.parse(pointString.substring(3, 5)).toDouble() * 10;
    double z = int.parse(pointString.substring(5, 7)).toDouble() * 10;
    // Assuming floor 1 is y=0, floor 2 is y=_floorHeight, etc.

    return {'x': x, 'y': y, 'z': z};
  }

  // Generates the initial HTML for the hotspot.
  // This will be based on the 'highlightedPoint' passed during the first build.
  String generateInitialHotspotHtml() {
    final coords = _parsePointCoordinates(widget.highlightedPoint);
    final initialX = coords['x']!;
    final initialY = coords['y']!;
    final initialZ = coords['z']!;

    return '''
        <button slot="hotspot-main-dynamic" class="hotspot-label" data-position="${initialX}m ${initialY}m ${initialZ}m" data-normal="1m 1m 1m">
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

    final jsCommand = '''
      (function() {
        const modelViewer = document.querySelector('model-viewer');
        let hotspot = modelViewer ? modelViewer.querySelector('button[slot="hotspot-main-dynamic"]') : null;

        if (!modelViewer) {
          console.error('JS: model-viewer element not found in updateHotspotPosition.');
          return;
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
        hotspot.setAttribute('data-normal', '1m 1m 1m');

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
        ''',
      ),
    );
  }
}


// gemini v3
// import 'package:flutter/material.dart';
// import 'package:model_viewer_plus/model_viewer_plus.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class Hotspot3DMapWidget extends StatefulWidget {
//   final String highlightedPoint; // This is the only dynamic input needed

//   const Hotspot3DMapWidget({super.key, required this.highlightedPoint});

//   @override
//   State<Hotspot3DMapWidget> createState() => _Hotspot3DMapWidgetState();
// }

// class _Hotspot3DMapWidgetState extends State<Hotspot3DMapWidget> {
//   WebViewController? _modelViewerController;
//   bool _isModelLoaded = false;

//   // Define each floor adds this much height in meters
//   // Adjust this value based on your model's actual scale for vertical separation
//   static const double _floorHeight = 3.0;

//   @override
//   void initState() {
//     super.initState();
//     // No need to manage _currentPointIndex or _allPoints here anymore.
//     // The initial hotspot will be set based on widget.highlightedPoint
//     // when the WebView is created and loaded.
//   }

//   @override
//   void didUpdateWidget(covariant Hotspot3DMapWidget oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // This method is called when the parent (CollectingDataPage) rebuilds
//     // with a new 'highlightedPoint'.
//     if (_modelViewerController != null) {
//       _updateHotspotPosition(widget.highlightedPoint);
//     }
//     // if (widget.highlightedPoint != oldWidget.highlightedPoint) {
//     //   print(
//     //       'Flutter: Hotspot3DMapWidget received new highlightedPoint: ${widget.highlightedPoint}');
//     //   // Only attempt to update if the model viewer controller is ready.
//     //   // The initial update is handled by onPageFinished/model-loaded.
//     //   if (_modelViewerController != null) {
//     //     _updateHotspotPosition(widget.highlightedPoint);
//     //   } else {
//     //     print(
//     //         'Flutter: Controller not ready yet for didUpdateWidget update. Will update when ready.');
//     //   }
//     // }
//   }

//   // Parses the 5-digit string to x, y, and z coordinates (multiplied by 10 for x/z)
//   // Example: '30852' -> floor=3, x=80, z=520
//   // Y coordinate is calculated based on floor number and _floorHeight
//   Map<String, double> _parsePointCoordinates(String pointString) {
//     if (pointString.length != 5) {
//       // print(
//       //     'Flutter: Invalid point string format: $pointString. Expected 5 digits.');
//       return {'x': 0.0, 'y': 0.0, 'z': 0.0};
//     }
//     int floor = int.parse(pointString.substring(0, 1));
//     double x = int.parse(pointString.substring(1, 3)).toDouble() * 10;
//     double z = int.parse(pointString.substring(3, 5)).toDouble() * 10;
//     // Assuming floor 1 is y=0, floor 2 is y=_floorHeight, etc.
//     // Adjust (floor - 1) if your model's origin for floor 1 is not 0.
//     double y = (floor - 1).toDouble() * _floorHeight;

//     return {'x': x, 'y': y, 'z': z};
//   }

//   // Generates the initial HTML for the hotspot.
//   // This will be based on the 'highlightedPoint' passed during the first build.
//   String generateInitialHotspotHtml() {
//     final coords = _parsePointCoordinates(widget.highlightedPoint);
//     final initialX = coords['x']!;
//     final initialY = coords['y']!;
//     final initialZ = coords['z']!;

//     return '''
//         <button slot="hotspot-main-dynamic" class="hotspot-label" data-position="${initialX}m ${initialY}m ${initialZ}m" data-normal="0m 1m 0m">
//           <div class="label" id="hotspot-main-label">${widget.highlightedPoint}</div>
//         </button>
//       ''';
//   }

//   void _updateHotspotPosition(String highlight) {
//     if (_modelViewerController == null) {
//       // print(
//       //     'Flutter: ERROR! WebViewController is null during _updateHotspotPosition call.');
//       return;
//     }

//     final coords = _parsePointCoordinates(highlight);
//     final x = coords['x']!;
//     final y = coords['y']!;
//     final z = coords['z']!;

//     final jsCommand = '''
//       (function() {
//         console.log('JS: Executing _updateHotspotPosition for: $highlight');
//         const modelViewer = document.querySelector('model-viewer');
//         let hotspot = modelViewer ? modelViewer.querySelector('button[slot="hotspot-main-dynamic"]') : null;

//         if (!modelViewer) {
//         //  console.error('JS: model-viewer element not found in updateHotspotPosition.');
//           return;
//         }

//         // --- AGGRESSIVE UPDATE: Remove and re-create hotspot ---
//         // This forces model-viewer to re-evaluate the hotspot's position.
//         if (hotspot) {
//           modelViewer.removeChild(hotspot);
//         //  console.log('JS: Existing hotspot removed from DOM.');
//         }

//         // Create a new hotspot element with updated attributes
//         hotspot = document.createElement('button');
//         hotspot.setAttribute('slot', 'hotspot-main-dynamic');
//         hotspot.classList.add('hotspot-label');
//         hotspot.setAttribute('data-position', `\${$x}m \${$y}m \${$z}m`); // Use calculated X, Y, Z
//         hotspot.setAttribute('data-normal', '0m 1m 0m'); // Keep default normal

//         const labelDiv = document.createElement('div');
//         labelDiv.classList.add('label');
//         labelDiv.id = 'hotspot-main-label'; // Keep ID for potential future direct access
//         labelDiv.textContent = '$highlight';
//         hotspot.appendChild(labelDiv);

//         modelViewer.appendChild(hotspot);
//         // console.log('JS: New hotspot appended to DOM with position: \${$x}m \${$y}m \${$z}m and label: $highlight.');

//         // --- FORCE RE-EVALUATION (Still good practice, even with re-append) ---
//         // Dispatching a resize event can sometimes help trigger internal layout updates
//         window.dispatchEvent(new Event('resize'));
//         // console.log('JS: Forced model-viewer update/resize event.');

//       })();
//     ''';

//     _modelViewerController!.runJavaScript(jsCommand);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 400, // Fixed height for the ModelViewer itself
//       child: ModelViewer(
//         src: 'assets/kdoj.glb',
//         alt: "3D map of building",
//         ar: false,
//         autoRotate: true,
//         cameraControls: true,
//         backgroundColor: Colors.white,
//         innerModelViewerHtml: generateInitialHotspotHtml(),
//         onWebViewCreated: (controller) {
//           _modelViewerController = controller;
//           // print(
//           //     'Flutter: onWebViewCreated callback fired. WebViewController obtained: $_modelViewerController');

//           // Inject JS to post a message when the model is loaded.
//           // This must happen AFTER the WebView (and thus model-viewer) is ready.
//           Future.delayed(const Duration(milliseconds: 200), () {
//             if (mounted && _modelViewerController != null) {
//               _modelViewerController!.runJavaScript('''
//                 (function() {
//                   // console.log('JS: Attempting to attach model-loaded listener after delay.');
//                   const modelViewer = document.querySelector('model-viewer');
//                   if (modelViewer) {
//                     console.log('JS: model-viewer element found. Attaching event listener.');
//                     modelViewer.addEventListener('model-loaded', () => {
//                       console.log('JS: *** model-loaded event FIRED! ***');
//                       if (window.ModelViewerChannel && window.ModelViewerChannel.postMessage) {
//                         window.ModelViewerChannel.postMessage('model-loaded');
//                         // console.log('JS: Message "model-loaded" posted to Flutter.');
//                       } else {
//                         // console.error('JS: window.ModelViewerChannel or postMessage is undefined. Channel check failed.');
//                       }
//                     });
//                   } else {
//                     // console.error('JS: model-viewer element NOT found when trying to attach listener (after delay).');
//                   }

//                   // Send a test message from JS to Flutter after a short delay
//                   setTimeout(() => {
//                       if (window.ModelViewerChannel && window.ModelViewerChannel.postMessage) {
//                           window.ModelViewerChannel.postMessage('JS_TEST_MESSAGE_CHANNEL_ACTIVE');
//                           // console.log('JS: Sent JS_TEST_MESSAGE_CHANNEL_ACTIVE to Flutter.');
//                       } else {
//                           // console.error('JS: Could not send JS_TEST_MESSAGE_CHANNEL_ACTIVE. Channel not ready.');
//                       }
//                   }, 500);

//                 })();
//               ''');
//             }
//           });

//           _modelViewerController!.setNavigationDelegate(
//             NavigationDelegate(
//               onPageFinished: (String url) {
//                 // print('Flutter: WebView finished loading page: $url');
//                 // Force initial hotspot update using the current highlightedPoint
//                 if (!_isModelLoaded) {
//                   // print(
//                   //     'Flutter: Page finished, model not flagged as loaded. Forcing initial hotspot update.');
//                   _updateHotspotPosition(widget.highlightedPoint);
//                   // Optionally, if you're confident the model is visually loaded here,
//                   // you could set _isModelLoaded = true; as a final fallback.
//                 }
//               },
//               onWebResourceError: (WebResourceError error) {
//                 // print(
//                 //     'Flutter: WebView error: ${error.description} (Code: ${error.errorCode})');
//               },
//             ),
//           );
//         },
//         javascriptChannels: {
//           JavascriptChannel(
//             'ModelViewerChannel',
//             onMessageReceived: (message) {
//               // print(
//               //     'Flutter: >>> MESSAGE RECEIVED from JS: ${message.message} <<<');
//               if (message.message == 'model-loaded') {
//                 setState(() {
//                   _isModelLoaded = true;
//                 });
//                 // print(
//                 //     'Flutter: Model loaded flag set to true. Executing initial hotspot position.');
//                 _updateHotspotPosition(
//                     widget.highlightedPoint); // Use widget.highlightedPoint
//               } else if (message.message == 'JS_TEST_MESSAGE_CHANNEL_ACTIVE') {
//                 // print(
//                 //     'Flutter: Confirmed JS_TEST_MESSAGE_CHANNEL_ACTIVE from JS. Channel is working!');
//               }
//             },
//           ),
//         },
//         relatedCss: '''
//           .hotspot-label {
//             background: transparent;
//             border: none;
//           }
//           .label {
//             padding: 2px 4px;
//             background: rgba(0, 0, 0, 0.75);
//             color: white;
//             border-radius: 3px;
//             font-size: 6px;
//           }
//           .label::after {
//             content: "";
//             position: absolute;
//             bottom: -6px;
//             left: 50%;
//             margin-left: -5px;
//             width: 0;
//             height: 0;
//             border-left: 5px solid transparent;
//             border-right: 5px solid transparent;
//             border-top: 6px solid rgba(0, 0, 0, 0.75);
//           }
//         ''',
//       ),
//     );
//   }
// }
