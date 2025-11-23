import 'dart:io';
import 'package:dermai/screens/scan_results_screen.dart';
import 'package:dermai/services/tflite_vision.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../screens/scan_drawer.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final PageController _pageController;
  bool isFront = true;
  final Map<String, Map<String, List<File>>> _partImages = {};
  final List<String> _bodyParts = [
    'Head',
    'Body',
    'Left Arm',
    'Right Arm',
    'Left Leg',
    'Right Leg'
  ];
  Classifier? _diseaseClassifier;
  Classifier? _skinTypeClassifier;
  bool _isAnalyzing = false;
  Stream<UserModel?>? _userStream;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadUserStream();
    for (var part in _bodyParts) {
      _partImages[part] = {'Front': [], 'Back': []};
    }
    _loadClassifiers();
  }

  Future<void> _loadClassifiers() async {
    final diseaseClassifier = await Classifier.create(
      modelPath: 'assets/models/SkinDiseaseV3.tflite',
      labelPath: 'assets/models/diseaseLabelsV3.txt',
    );
    final skinTypeClassifier = await Classifier.create(
      modelPath: 'assets/models/SkinType.tflite',
      labelPath: 'assets/models/skinTypeLabels.txt',
    );
    setState(() {
      _diseaseClassifier = diseaseClassifier;
      _skinTypeClassifier = skinTypeClassifier;
    });
  }

  void _loadUserStream() {
    final authService = context.read<AuthService>();
    final userRepository = context.read<UserRepository>();
    final currentUser = authService.currentUser;
    if (currentUser != null) {
      setState(() {
        _userStream = userRepository.getUserStream(currentUser.uid);
      });
    }
  }

  void _clearImages() {
    setState(() {
      for (var part in _bodyParts) {
        _partImages[part] = {'Front': [], 'Back': []};
      }
    });
  }

  Future<void> _analyzeImages(UserModel? user) async {
    if (_diseaseClassifier == null || _skinTypeClassifier == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    final List<ScanResult> results = [];
    for (final part in _partImages.keys) {
      for (final view in _partImages[part]!.keys) {
        for (final image in _partImages[part]![view]!) {
          final diseasePredictions =
              await _diseaseClassifier!.predictFromFile(image);
          final skinTypePredictions =
              await _skinTypeClassifier!.predictFromFile(image);
          results.add(ScanResult(
            image: image,
            diseasePredictions: diseasePredictions,
            skinTypePredictions: skinTypePredictions,
            part: part,
            view: view,
          ));
        }
      }
    }

    if (mounted) {
      final shouldClear = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultsScreen(
            results: results,
            userId: user?.uid,
          ),
        ),
      );

      if (shouldClear == true) {
        _clearImages();
      }
    }

    // Set analyzing to false only after the results screen is closed.
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPartCard(String label, int count) {
    return GestureDetector(
      onTap: () {
        final view = isFront ? 'Front' : 'Back';
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          enableDrag: true,
          builder: (context) => ScanDrawer(
            part: label,
            isFront: isFront,
            initialImages: _partImages[label]![view]!,
            onImagesChanged: (newImages) {
              setState(() {
                _partImages[label]![view] = newImages;
              });
            },
          ),
        );
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.champagne,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$count',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 18)),
                const Icon(Icons.more_vert, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          final isFemale = user?.sex?.toLowerCase() == 'female';
          final frontImage = isFemale
              ? 'assets/images/female-front.png'
              : 'assets/images/male-front.png';
          final backImage = isFemale
              ? 'assets/images/female-back.png'
              : 'assets/images/male-back.png';

          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFront ? 'Frontal Scan' : 'Dorsal Scan',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    'Choose a focus area for scanning',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Transform.translate(
                            offset: isFemale
                                ? const Offset(-90, 0)
                                : const Offset(-110, 0),
                            child: Image.asset(
                              isFront ? frontImage : backImage,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _buildPartCard(
                                        'Head',
                                        _partImages['Head']?[
                                                    isFront ? 'Front' : 'Back']
                                                ?.length ??
                                            0),
                                    const SizedBox(height: 8),
                                    _buildPartCard(
                                        'Body',
                                        _partImages['Body']?[
                                                    isFront ? 'Front' : 'Back']
                                                ?.length ??
                                            0),
                                    const SizedBox(height: 8),
                                    _buildPartCard(
                                        'Left Arm',
                                        _partImages['Left Arm']?[
                                                    isFront ? 'Front' : 'Back']
                                                ?.length ??
                                            0),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _buildPartCard(
                                        'Right Arm',
                                        _partImages['Right Arm']?[
                                                    isFront ? 'Front' : 'Back']
                                                ?.length ??
                                            0),
                                    const SizedBox(height: 8),
                                    _buildPartCard(
                                        'Left Leg',
                                        _partImages['Left Leg']?[
                                                    isFront ? 'Front' : 'Back']
                                                ?.length ??
                                            0),
                                    const SizedBox(height: 8),
                                    _buildPartCard(
                                        'Right Leg',
                                        _partImages['Right Leg']?[
                                                    isFront ? 'Front' : 'Back']
                                                ?.length ??
                                            0),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FloatingActionButton.small(
                                heroTag: "view_switcher_button",
                                elevation: 0,
                                highlightElevation: 0,
                                backgroundColor: theme.colorScheme.secondary,
                                onPressed: () {
                                  setState(() {
                                    isFront = !isFront;
                                  });
                                },
                                shape: const CircleBorder(),
                                child: const Icon(Icons.threesixty),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.extended(
                                heroTag: "analyze_button",
                                elevation: 0,
                                highlightElevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                onPressed: (_diseaseClassifier == null ||
                                        _skinTypeClassifier == null ||
                                        _isAnalyzing)
                                    ? null
                                    : () => _analyzeImages(user),
                                label: Text(_isAnalyzing
                                    ? 'Analyzing...'
                                    : 'View Results'),
                                icon: _isAnalyzing
                                    ? Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(2.0),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.analytics),
                                backgroundColor: AppColors.primary,
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
          );
        });
  }
}
