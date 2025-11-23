import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_colors.dart';

class ScanDrawer extends StatefulWidget {
  final String part;
  final bool isFront;
  final List<File> initialImages;
  final Function(List<File>) onImagesChanged;

  const ScanDrawer(
      {Key? key,
      required this.part,
      required this.isFront,
      required this.initialImages,
      required this.onImagesChanged})
      : super(key: key);

  @override
  _ScanDrawerState createState() => _ScanDrawerState();
}

class _ScanDrawerState extends State<ScanDrawer> {
  final int maxPhotos = 6;
  List<File> _images = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (_images.length < maxPhotos) {
          _images.add(File(pickedFile.path));
          widget.onImagesChanged(_images);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      widget.onImagesChanged(_images);
    });
  }

  Widget _buildImageFrame(int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              _images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFrame() {
    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        dashPattern: [10, 5],
        strokeWidth: 1.5,
        radius: Radius.circular(16),
        color: AppColors.primary,
        padding: EdgeInsets.zero,
      ),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _pickImage(ImageSource.gallery),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount =
        _images.length < maxPhotos ? _images.length + 1 : maxPhotos;

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload photos for ${widget.isFront ? 'Front' : 'Back'} ${widget.part}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Photos must be well defined.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3 / 2,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index < _images.length) {
                      return _buildImageFrame(index);
                    } else {
                      return _buildAddFrame();
                    }
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () => _pickImage(ImageSource.camera),
                      child: const Icon(Icons.camera_alt),
                      backgroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                      elevation: 0,
                    ),
                  ),
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () => _pickImage(ImageSource.gallery),
                      child: const Icon(Icons.photo),
                      backgroundColor: AppColors.primary,
                      shape: const CircleBorder(),
                      elevation: 0,
                    ),
                  ),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Icon(_isExpanded ? Icons.close : Icons.add),
                  backgroundColor: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
