import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const DeepFakeDetectionApp());
}

class DeepFakeDetectionApp extends StatelessWidget {
  const DeepFakeDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DeepFakeDetectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DeepFakeDetectionPage extends StatefulWidget {
  const DeepFakeDetectionPage({super.key});

  @override
  _DeepFakeDetectionPageState createState() => _DeepFakeDetectionPageState();
}

class _DeepFakeDetectionPageState extends State<DeepFakeDetectionPage> {
  bool _isLoading = false;
  String _videoPrediction = '';
  String _audioPrediction = '';
  String _errorMessage = '';
  List<String> _frameImages = [];
  List<String> _framePredictions = [];
  List<String> _spectrogramImages = [];
  List<String> _audioPredictions = [];

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      PlatformFile platformFile = result.files.first;

      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:5000/predict'),
        );

        if (platformFile.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'video',
            platformFile.bytes!,
            filename: platformFile.name,
          ));

          var response = await request.send();

          if (response.statusCode == 200) {
            var responseData = await response.stream.bytesToString();
            var jsonResponse = json.decode(responseData);

            setState(() {
              _frameImages = List<String>.from(jsonResponse['frame_images']);
              _framePredictions =
                  List<String>.from(jsonResponse['frame_predictions']);
              _spectrogramImages =
                  List<String>.from(jsonResponse['spectrogram_images']);
              _audioPredictions =
                  List<String>.from(jsonResponse['audio_predictions']);
              _videoPrediction = jsonResponse['Video'];
              _audioPrediction = jsonResponse['Audio'];
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Error: ${response.reasonPhrase}';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Error: File is not available';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'File picking was canceled';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // Center the title
        title: const Text(
          'Deep Fake Detection',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'background_image.jpg'), // Add your background image here
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black
                    .withOpacity(0.4), // Adjust the opacity as needed
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Add some space below the app bar
                ElevatedButton(
                  onPressed: _isLoading ? null : _uploadFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 241, 240, 240),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 30.0,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Upload Video'),
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (_frameImages.isNotEmpty)
                                ..._frameImages.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  String base64Image = entry.value;
                                  Uint8List bytes = base64Decode(base64Image);
                                  return Card(
                                    elevation: 2.0,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.memory(bytes),
                                          const SizedBox(height: 10),
                                          Text(
                                            _framePredictions[index],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              if (_spectrogramImages.isNotEmpty)
                                ..._spectrogramImages
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key;
                                  String base64Image = entry.value;
                                  Uint8List bytes = base64Decode(base64Image);
                                  return Card(
                                    elevation: 2.0,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.memory(bytes),
                                          const SizedBox(height: 10),
                                          Text(
                                            _audioPredictions[index],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            if (_videoPrediction.isNotEmpty)
                              Card(
                                elevation: 2.0,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Video Prediction',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _videoPrediction,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_audioPrediction.isNotEmpty)
                              Card(
                                elevation: 2.0,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Audio Prediction',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _audioPrediction,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
