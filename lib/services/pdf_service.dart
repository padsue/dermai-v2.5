import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/detection_result.dart';
import '../models/user_model.dart';
import '../screens/scan_results_screen.dart';
import '../utils/app_colors.dart';
import '../utils/skin_condition_helper.dart';

class PdfService {
  Future<void> saveResultsAsPdf(
      List<ScanResult> results, UserModel? user) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final mediumFont = await PdfGoogleFonts.poppinsMedium();

    final iconsFont = pw.Font.ttf(await rootBundle
        .load('assets/fonts/MaterialSymbolsOutlined-Regular.ttf'));

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    final primaryColor = PdfColor.fromHex(
        AppColors.primary.value.toRadixString(16).substring(2));
    final secondaryColor = PdfColor.fromHex(
        AppColors.secondary.value.toRadixString(16).substring(2));
    final greyColor = PdfColor.fromHex("#808080");

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        header: (pw.Context context) {
          return _buildPdfDocumentHeader(
              logoImage, boldFont, font, primaryColor, secondaryColor);
        },
        footer: (pw.Context context) {
          return _buildPdfFooter(font, iconsFont, primaryColor);
        },
        build: (pw.Context context) {
          return [
            _buildSummary(
                user, results, font, boldFont, mediumFont, primaryColor),
            pw.SizedBox(height: 20),
            pw.Text(
              'Detailed Results',
              style: pw.TextStyle(
                  font: boldFont, fontSize: 18, color: primaryColor),
            ),
            pw.SizedBox(height: 8),
            ...results.map((result) {
              return _buildPdfResultItem(
                  result, font, boldFont, mediumFont, primaryColor, greyColor);
            }),
            pw.SizedBox(height: 20),
            _buildDisclaimer(font, greyColor),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }

  pw.Widget _buildPdfDocumentHeader(
      pw.ImageProvider logoImage,
      pw.Font boldFont,
      pw.Font regularFont,
      PdfColor primaryColor,
      PdfColor secondaryColor) {
    final brandNameStyle = pw.TextStyle(font: boldFont, fontSize: 24);
    final taglineStyle = pw.TextStyle(font: regularFont, fontSize: 10);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          height: 40,
          width: 40,
          child: pw.Image(logoImage),
        ),
        pw.SizedBox(height: 4),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          pw.Text("Derm", style: brandNameStyle.copyWith(color: primaryColor)),
          pw.Text("AI", style: brandNameStyle.copyWith(color: secondaryColor)),
        ]),
        pw.SizedBox(height: 1),
        pw.Text("Smarter Skin Starts Here", style: taglineStyle),
        pw.Divider(height: 20, thickness: 1, color: primaryColor),
      ],
    );
  }

  pw.Widget _buildPdfFooter(
      pw.Font regularFont, pw.Font iconsFont, PdfColor primaryColor) {
    final contactStyle = pw.TextStyle(font: regularFont, fontSize: 8);
    const iconSize = 9.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(thickness: 1, color: primaryColor),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.Text(String.fromCharCode(0xe0c8),
                  style: pw.TextStyle(
                      font: iconsFont,
                      fontSize: iconSize,
                      color: primaryColor)),
              pw.SizedBox(width: 4),
              pw.Text("Tuguegarao City, Cagayan, PH 3500", style: contactStyle),
            ]),
            pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.Text(String.fromCharCode(0xe0b0),
                  style: pw.TextStyle(
                      font: iconsFont,
                      fontSize: iconSize,
                      color: primaryColor)),
              pw.SizedBox(width: 4),
              pw.Text('(0926) 087 6816', style: contactStyle),
            ]),
            pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.Text(String.fromCharCode(0xe158),
                  style: pw.TextStyle(
                      font: iconsFont,
                      fontSize: iconSize,
                      color: primaryColor)),
              pw.SizedBox(width: 4),
              pw.Text('dermaixxiv@gmail.com', style: contactStyle),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummary(
      UserModel? user,
      List<ScanResult> results,
      pw.Font font,
      pw.Font boldFont,
      pw.Font mediumFont,
      PdfColor primaryColor) {
    String getUniqueItemsAsString(List<String> items) {
      if (items.isEmpty) return 'N/A';
      return items.toSet().toList().join(', ');
    }

    final allDiseases =
        getUniqueItemsAsString(results.map((r) => r.topDiseaseLabel).toList());
    final allSkinTypes =
        getUniqueItemsAsString(results.map((r) => r.topSkinTypeLabel).toList());
    final allClassifications = getUniqueItemsAsString(results
        .map((r) => r.topDiseaseCategory)
        .where((c) => c != null)
        .cast<String>()
        .toList());
    final scanDate = DateFormat('MM/dd/yyyy').format(DateTime.now());

    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(
        'Summary',
        style: pw.TextStyle(font: boldFont, fontSize: 18, color: primaryColor),
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                    'Skin Condition(s):', allDiseases, font, mediumFont),
                _buildSummaryRow(
                    'Skin Type(s):', allSkinTypes, font, mediumFont),
                _buildSummaryRow(
                    'Classification(s):',
                    allClassifications.isEmpty ? 'N/A' : allClassifications,
                    font,
                    mediumFont),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                  style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.Text(scanDate, style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('${results.length} images uploaded',
                  style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
        ],
      ),
    ]);
  }

  pw.Widget _buildSummaryRow(
      String label, String value, pw.Font font, pw.Font mediumFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColor.fromHex("#808080"))),
          pw.Text(value, style: pw.TextStyle(font: mediumFont, fontSize: 12)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfResultItem(
      ScanResult result,
      pw.Font font,
      pw.Font boldFont,
      pw.Font mediumFont,
      PdfColor primaryColor,
      PdfColor greyColor) {
    final image = pw.MemoryImage(result.image.readAsBytesSync());
    final description =
        SkinConditionHelper.getDescription(result.topDiseaseLabel);
    final category = result.topDiseaseCategory;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 80,
                height: 80,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(result.area,
                        style: pw.TextStyle(font: font, color: greyColor)),
                    if (category != null)
                      pw.Text(category.toUpperCase(),
                          style: pw.TextStyle(font: boldFont, fontSize: 10)),
                    pw.Text(result.topDiseaseLabel,
                        style: pw.TextStyle(font: boldFont, fontSize: 16)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${(result.topDiseaseConfidence * 100).toStringAsFixed(1)}% Confidence',
                      style:
                          pw.TextStyle(font: mediumFont, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (description != null) ...[
                pw.Text('Description',
                    style: pw.TextStyle(font: boldFont, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text(description,
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ],
              pw.SizedBox(height: 4),
              _buildPredictionListPdf('Top Disease Predictions',
                  result.diseasePredictions, font, boldFont, primaryColor),
              pw.SizedBox(height: 4),
              _buildPredictionListPdf('Skin Type Predictions',
                  result.skinTypePredictions, font, boldFont, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPredictionListPdf(
      String title,
      List<Map<String, dynamic>> predictions,
      pw.Font font,
      pw.Font boldFont,
      PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 12)),
        pw.SizedBox(height: 8),
        ...predictions.take(3).map((p) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(p['label'],
                    style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Text(
                  '${(p['confidence'] * 100).toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                      font: font, fontSize: 10, color: primaryColor),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildDisclaimer(pw.Font font, PdfColor greyColor) {
    return pw.Center(
      child: pw.Text(
        'Disclaimer: The results from this scan are not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
        style: pw.TextStyle(font: font, fontSize: 8, color: greyColor),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
