import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CardScanner extends StatefulWidget {
  final File image;
  const CardScanner(this.image, {Key? key}) : super(key: key);

  @override
  State<CardScanner> createState() => _CardScannerState();
}

class _CardScannerState extends State<CardScanner> {
  late final TextRecognizer textRecognizer;
  late final EntityExtractor entityExtractor;
  List<EntityDM> entitiesList = [];

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);
    _doTextRecognition();
  }

  Future<void> _doTextRecognition() async {
    final inputImage = InputImage.fromFile(widget.image);
    final recognizedText = await textRecognizer.processImage(inputImage);
    final annotations = await entityExtractor.annotateText(recognizedText.text);

    final List<EntityDM> extractedEntities = [];

    for (final annotation in annotations) {
      for (final entity in annotation.entities) {
        extractedEntities.add(EntityDM(entity.type.name, annotation.text));
      }
    }

    setState(() {
      entitiesList = extractedEntities;
    });
  }

  @override
  void dispose() {
    textRecognizer.close();
    entityExtractor.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(widget.image),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entitiesList.length,
              itemBuilder: (context, index) {
                final entity = entitiesList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  color: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(entity.iconData, color: Colors.white),
                    title: Text(
                      entity.value,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: entity.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Copied")),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EntityDM {
  final String name;
  final String value;
  final IconData iconData;

  EntityDM(this.name, this.value)
      : iconData = _iconMap[name] ?? Icons.ac_unit_outlined;

  static const Map<String, IconData> _iconMap = {
    'phone': Icons.phone,
    'address': Icons.location_on,
    'email': Icons.mail,
    'url': Icons.web,
  };
}
