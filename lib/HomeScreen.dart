import 'dart:io';

import 'package:camera/camera.dart';
import 'package:ds/CardScanner.dart';
import 'package:ds/EnhanceScreen.dart';
import 'package:ds/RecognizerScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ImagePicker imagePicker;
  late final CameraController controller;
  late List<CameraDescription> _cameras;
  bool isInit = false;
  bool scan = false;
  bool recognize = true;
  bool enhance = false;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      controller = CameraController(_cameras[0], ResolutionPreset.max);
      await controller.initialize();
      if (mounted) {
        setState(() => isInit = true);
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  void _setMode(
      {required bool scanMode,
      required bool recognizeMode,
      required bool enhanceMode}) {
    setState(() {
      scan = scanMode;
      recognize = recognizeMode;
      enhance = enhanceMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = MediaQuery.of(context).size.height - 300;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 50, bottom: 15, left: 5, right: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeSelector(),
            _buildCameraPreview(previewHeight),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      color: Colors.blueAccent,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeButton(Icons.scanner, 'Scan', scan, () {
              _setMode(
                  scanMode: true, recognizeMode: false, enhanceMode: false);
            }),
            _buildModeButton(Icons.document_scanner, 'Recognize', recognize,
                () {
              _setMode(
                  scanMode: false, recognizeMode: true, enhanceMode: false);
            }),
            _buildModeButton(Icons.assignment_sharp, 'Enhance', enhance, () {
              _setMode(
                  scanMode: false, recognizeMode: false, enhanceMode: true);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
      IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25, color: isSelected ? Colors.black : Colors.white),
          Text(label,
              style:
                  TextStyle(color: isSelected ? Colors.black : Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(double height) {
    return Card(
      color: Colors.black,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: height,
              child: isInit
                  ? AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: CameraPreview(controller),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Positioned.fill(
            child: Image.asset("images/f1.png", fit: BoxFit.fill),
          ),
          Container(
            color: Colors.white,
            height: 2,
            margin: const EdgeInsets.all(20),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .moveY(begin: 0, end: height - 20, duration: 2000.ms),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Card(
      color: Colors.blueAccent,
      child: SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.rotate_left, size: 35, color: Colors.white),
            InkWell(
              onTap: _captureImage,
              child: const Icon(Icons.camera, size: 50, color: Colors.white),
            ),
            InkWell(
              onTap: _pickFromGallery,
              child: const Icon(Icons.image_outlined,
                  size: 35, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final XFile file = await controller.takePicture();
      processImage(File(file.path));
    } catch (e) {
      debugPrint("Capture Error: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? xfile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      processImage(File(xfile.path));
    }
  }

  Future<void> processImage(File image) async {
    final editedBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageCropper(image: image.readAsBytesSync()),
      ),
    );

    if (editedBytes != null) {
      image.writeAsBytesSync(editedBytes);
      if (recognize) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => RecognizerScreen(image)));
      } else if (scan) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => CardScanner(image)));
      } else if (enhance) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => EnhanceScreen(image)));
      }
    }
  }
}
