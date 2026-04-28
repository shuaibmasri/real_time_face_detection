import 'dart:core';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'face_detection_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required String title}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,   // Detects smiling probability, eyes open
      enableLandmarks: true,        // Nose, mouth, eyes, etc.
      enableContours: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate, // Or .accurate
    ),
  );


  bool _isDetecting = false;
  List<Face> _faces = [];
  List<CameraDescription> cameras = [];
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeCameer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (kDebugMode) {
        print("Permissions Denied");
      }
    }
  }

  Future<void> _initializeCameer() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (kDebugMode) {
          print("Not Available Camera");
        }
        return;
      }

      _selectedCameraIndex = cameras.indexWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front);
      _selectedCameraIndex == -1 ? 0 : _selectedCameraIndex;

      await _initializeCamera(cameras[_selectedCameraIndex]);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _controller = controller;
    _initializeControllerFuture = controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _startFaceDetection();
      });
    }).catchError((error) {
      if (kDebugMode) {
        print(error);
      }
    });
  }

  void _toggleCamera() async {
    if (cameras.isEmpty || cameras.length < 2) {
      if (kDebugMode) {
        print("can't toggle came , or not available camera");
      }
      return;
    }
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;

    setState(() {
      _faces = [];
    });

    await _initializeCamera(cameras[_selectedCameraIndex]);
  }

  void _startFaceDetection() {
    if (_controller == null || !_controller!.value.isInitialized) {
      if (kDebugMode) {
        print("camera Is not isInitialized");
      }
      return;
    }
    _controller!.startImageStream((CameraImage image) async {
      if (_isDetecting) {
        if (kDebugMode) {
          print("Is Detecting");
        }
        return;
      }
      _isDetecting = true;

      if (kDebugMode) {
        final formatRaw = image.format.raw;
        print("Image format raw: $formatRaw");
        print("Image size: ${image.width} x ${image.height}");
        print("Planes: ${image.planes.length}, Format: ${image.format.raw}");
      }

      final inputImage = _convertCameraInputToInputImage(image);
      if (inputImage == null) {
        if (kDebugMode) {
          print("InputImage Is Null");
        }
        _isDetecting = false;
        return;
      }
      else{
        if (kDebugMode) {
          print("InputImage Is not Null");
        }
      }

      try {
        if (kDebugMode) {
          print("Processing frame...");
          print(inputImage);
        }
        await Future.delayed(const Duration(milliseconds: 500));

        final faces = await _faceDetector.processImage(inputImage);
        if (kDebugMode) {
          print("Faces detected: ${faces.length}");
        }
        if (mounted) {
          if (kDebugMode) {
            print("There Is Faces");
          }
          setState(() {
            _faces = faces;
            if (kDebugMode) {
              print("Faces length is ${faces.length}");
            }
          });
        }
        else{
          if (kDebugMode) {
            print("There Is no Faces");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("exception with image");
          print(e);
        }
      } finally {
        _isDetecting = false;
      }
    });
  }

  InputImage? _convertCameraInputToInputImage(CameraImage image) {
    if (_controller == null) return null;
    try {
      final format =
      Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.nv21;
      final inputImageMetadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.values.firstWhere(
                  (element) =>
              element.rawValue ==
                  _controller!.description.sensorOrientation,
              orElse: () => InputImageRotation.rotation0deg),
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow);
      final bytes = _concatenatePlanes(image.planes);
      return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Detection"), actions: [
        if (cameras.length > 1)
          IconButton(
              onPressed: _toggleCamera,
              icon: const Icon(CupertinoIcons.switch_camera_solid),
              color: Colors.blueAccent)
      ]),
      body: _initializeControllerFuture == null
          ? const Center(child: Text("No Camera Available"))
          : FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (BuildContext context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null &&
              _controller!.value.isInitialized) {
            return Stack(
              fit: StackFit.expand,
              children: [
              Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(
                _controller!.description.lensDirection == CameraLensDirection.front
                    ? math.pi
                    : 0,
              ),
              child: CameraPreview(_controller!),
            ),
                CustomPaint(
                    painter: FaceDetectionPainter(
                      faces: _faces,
                      imageSize: Size(
                        _controller!.value.previewSize!.height,
                        _controller!.value.previewSize!.width,
                      ),
                      cameraLensDirection:
                      _controller!.description.lensDirection,
                    )),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text("Face Detected:${_faces.length}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)))),
                )
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          } else {
            return const Center(
                child:
                CircularProgressIndicator(color: Colors.blueAccent));
          }
        },
      ),
    );
  }
}
