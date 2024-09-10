import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late XFile _image;
  late List _output;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model_unquant.tflite',
      labels: 'assets/labels.txt',
    );
  }

  Future<void> _getImageAndDetectObjects() async {
    var image = await ImagePicker.platform.getImageFromSource(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _loading = true;
      _image = image;
    });

    classifyImage(image as File);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 3,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _loading = false;
      _output = output!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('SnapScan Lite'),
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _image == null ? Container() : Image.file(_image as File),
            SizedBox(height: 20),
            _output != null
                ? Text(
              "${_output[0]['label']}",
              style: TextStyle(fontSize: 20),
            )
                : Container(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getImageAndDetectObjects,
              child: Text('Select Image'),
            ),
          ],
        ),
      ),
    );
  }
}
