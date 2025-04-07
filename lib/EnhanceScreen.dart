import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class EnhanceScreen extends StatefulWidget {
  final File image;
  const EnhanceScreen(this.image, {Key? key}) : super(key: key);

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  late img.Image inputImage;
  double contrast = 150;
  double brightness = 1;

  @override
  void initState() {
    super.initState();
    final decoded = img.decodeImage(widget.image.readAsBytesSync());
    if (decoded != null) {
      inputImage = decoded;
      _enhanceImage();
    } else {
      throw Exception("Failed to decode image.");
    }
  }

  void _enhanceImage() {
    final original = img.decodeImage(widget.image.readAsBytesSync());
    if (original != null) {
      var temp = img.adjustColor(original, brightness: brightness);
      temp = img.contrast(temp, contrast: contrast);
      setState(() {
        inputImage = temp;
      });
    }
  }

  Future<void> _saveImage() async {
    final pngBytes = Uint8List.fromList(img.encodePng(inputImage));
    final result = await ImageGallerySaver.saveImage(pngBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image Saved')),
    );
    print(result);
  }

  Future<void> _applyFilter() async {
    final filtered = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageFilters(
          image: Uint8List.fromList(img.encodePng(inputImage)),
        ),
      ),
    );
    if (filtered != null && filtered is Uint8List) {
      final updated = img.decodeImage(filtered);
      if (updated != null) {
        setState(() {
          inputImage = updated;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = Uint8List.fromList(img.encodeBmp(inputImage));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhance', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.save_alt), onPressed: _saveImage),
          IconButton(icon: const Icon(Icons.filter), onPressed: _applyFilter),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height / 1.5,
                margin: const EdgeInsets.all(15),
                child: Image.memory(displayImage),
              ),
            ),
            _buildSlider(
              label: 'Contrast',
              value: contrast,
              min: 80,
              max: 200,
              icon: Icons.contrast,
              onChanged: (val) {
                contrast = val;
                _enhanceImage();
              },
            ),
            _buildSlider(
              label: 'Brightness',
              value: brightness,
              min: 1,
              max: 10,
              icon: Icons.brightness_5,
              onChanged: (val) {
                brightness = val;
                _enhanceImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.blueAccent),
          Expanded(
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: value.toStringAsFixed(2),
              activeColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
