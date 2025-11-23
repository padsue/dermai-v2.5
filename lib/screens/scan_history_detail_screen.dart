import 'package:dermai/models/detection_result.dart';
import 'package:dermai/models/user_model.dart';
import 'package:dermai/repositories/user_repository.dart';
import 'package:dermai/screens/scan_results_screen.dart';
import 'package:dermai/services/auth_service.dart';
import 'package:dermai/services/pdf_service.dart';
import 'package:dermai/utils/app_colors.dart';
import 'package:dermai/utils/skin_condition_helper.dart';
import 'package:dermai/utils/severity_helper.dart';
import 'package:dermai/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

class ScanHistoryDetailScreen extends StatefulWidget {
  final DetectionResultModel record;

  const ScanHistoryDetailScreen({Key? key, required this.record})
      : super(key: key);

  @override
  State<ScanHistoryDetailScreen> createState() =>
      _ScanHistoryDetailScreenState();
}

class _ScanHistoryDetailScreenState extends State<ScanHistoryDetailScreen> {
  late Future<UserModel?> _userFuture;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUserData();
  }

  Future<UserModel?> _loadUserData() async {
    if (!mounted) return null;
    return context.read<UserRepository>().getUser(widget.record.userId);
  }

  Future<void> _generatePdf(UserModel? user) async {
    if (_isGeneratingPdf) return;
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Convert ImageResultModel to ScanResult by getting images from cache
      final List<ScanResult> scanResults = [];

      for (var imageResult in widget.record.imageResults) {
        final file =
            await DefaultCacheManager().getSingleFile(imageResult.imageUrl);

        scanResults.add(ScanResult(
          image: file,
          diseasePredictions: imageResult.diseasePredictions,
          skinTypePredictions: imageResult.skinTypePredictions,
          part: imageResult.part,
          view: imageResult.view,
        ));
      }

      final pdfService = PdfService();
      await pdfService.saveResultsAsPdf(scanResults, user);
    } catch (e) {
      // Handle error if needed
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'Scan Details',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        showBackButton: true,
      ),
      floatingActionButton: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, userSnapshot) {
          return FloatingActionButton(
            onPressed: () => _generatePdf(userSnapshot.data),
            backgroundColor: AppColors.primary,
            elevation: 0,
            highlightElevation: 0,
            shape: const CircleBorder(),
            child: _isGeneratingPdf
                ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.print, color: Colors.white),
          );
        },
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonLoader();
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Summary',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                _buildSummaryCard(context, userSnapshot.data),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Detailed Results',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: widget.record.imageResults.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final result = widget.record.imageResults[index];
                    final topDisease = result.diseasePredictions.isNotEmpty
                        ? result.diseasePredictions.first
                        : {'label': 'N/A', 'confidence': 0.0};

                    // Parse severity from the top disease label
                    final severityInfo =
                        SeverityHelper.parseDiseaseLabel(topDisease['label']);
                    final description = SkinConditionHelper.getDescription(
                        severityInfo.diseaseName);
                    final category = SkinConditionHelper.getCategory(
                        severityInfo.diseaseName);

                    return Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        title: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: result.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Center(
                                        child: CircularProgressIndicator())),
                                errorWidget: (context, url, error) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${result.view} ${result.part}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  if (category != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4, bottom: 2),
                                      child: Text(
                                        category.toUpperCase(),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    severityInfo.diseaseName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getSeverityColor(
                                              severityInfo.severity),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          severityInfo.severityText,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(topDisease['confidence'] * 100).toStringAsFixed(1)}%',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        _getSeverityColor(severityInfo.severity)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getSeverityColor(
                                          severityInfo.severity),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getSeverityIcon(severityInfo.severity),
                                        color: _getSeverityColor(
                                            severityInfo.severity),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          SeverityHelper.getSeverityDescription(
                                              severityInfo.severity),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 24),
                                if (description != null) ...[
                                  Text(
                                    'Description',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(description,
                                      style: theme.textTheme.bodyMedium),
                                  const Divider(height: 24),
                                ],
                                _buildPredictionList(
                                  context,
                                  'Top Disease Predictions',
                                  result.diseasePredictions,
                                ),
                                const Divider(height: 24),
                                _buildPredictionList(
                                  context,
                                  'Skin Type Predictions',
                                  result.skinTypePredictions,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Disclaimer: The results from this scan are not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.harmless:
        return Colors.green;
      case SeverityLevel.mild:
        return Colors.blue;
      case SeverityLevel.moderate:
        return Colors.orange;
      case SeverityLevel.severe:
        return Colors.red;
      case SeverityLevel.unknown:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.harmless:
        return Icons.check_circle;
      case SeverityLevel.mild:
        return Icons.info;
      case SeverityLevel.moderate:
        return Icons.warning;
      case SeverityLevel.severe:
        return Icons.error;
      case SeverityLevel.unknown:
        return Icons.help;
    }
  }

  Widget _buildSummaryCard(BuildContext context, UserModel? user) {
    final theme = Theme.of(context);
    final scanDate = DateFormat('MM/dd/yyyy').format(widget.record.scanDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(context, 'Skin Condition(s):',
                    widget.record.summary['skinConditions'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Severity Level(s):',
                    widget.record.summary['severities'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Skin Type(s):',
                    widget.record.summary['skinTypes'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Classification(s):',
                    widget.record.summary['classifications'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(scanDate, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('${widget.record.imageResults.length} images scanned',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        Text(value, style: theme.textTheme.titleMedium, softWrap: true),
      ],
    );
  }

  Widget _buildPredictionList(BuildContext context, String title,
      List<Map<String, dynamic>> predictions) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...predictions.take(3).map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p['label'], style: theme.textTheme.bodyMedium),
                Text(
                  '${(p['confidence'] * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Summary card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 120,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 90,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Detailed results title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Result items
            ...List.generate(
              2,
              (index) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
