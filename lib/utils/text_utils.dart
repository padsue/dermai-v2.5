import 'package:dermai/utils/app_colors.dart';
import 'package:flutter/material.dart';

TextSpan buildRichText(String text, {TextStyle? baseStyle}) {
  List<TextSpan> spans = [];
  List<String> lines = text.split('\n');
  for (String line in lines) {
    if (line.trim().startsWith(RegExp(r'^\d+\.\s'))) {
      spans.add(TextSpan(
        text: line,
        style: TextStyle(
          fontSize: baseStyle?.fontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: baseStyle?.fontFamily,
          height: baseStyle?.height,
        ),
      ));
    } else {
      spans.add(buildInlineRichText(line, baseStyle: baseStyle));
    }
    spans.add(TextSpan(text: '\n', style: baseStyle));
  }
  return TextSpan(children: spans);
}

TextSpan buildInlineRichText(String text, {TextStyle? baseStyle}) {
  final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
  final RegExp italicRegex = RegExp(r'\*(.*?)\*');

  List<TextSpan> spans = [];
  int currentIndex = 0;

  while (currentIndex < text.length) {
    final boldMatch = boldRegex.matchAsPrefix(text, currentIndex) ??
        boldRegex.firstMatch(text.substring(currentIndex));
    final italicMatch = italicRegex.matchAsPrefix(text, currentIndex) ??
        italicRegex.firstMatch(text.substring(currentIndex));

    int boldStart = boldMatch != null
        ? (boldMatch.start == 0 ? currentIndex : currentIndex + boldMatch.start)
        : -1;
    int boldEnd = boldMatch != null
        ? (boldMatch.start == 0
            ? boldMatch.end + currentIndex
            : boldMatch.end + currentIndex)
        : -1;
    int italicStart = italicMatch != null
        ? (italicMatch.start == 0
            ? currentIndex
            : currentIndex + italicMatch.start)
        : -1;
    int italicEnd = italicMatch != null
        ? (italicMatch.start == 0
            ? italicMatch.end + currentIndex
            : italicMatch.end + currentIndex)
        : -1;

    if (boldMatch != null &&
        (italicMatch == null || boldStart <= italicStart)) {
      if (boldStart > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, boldStart),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: boldMatch.group(1),
        style: baseStyle?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold),
      ));
      currentIndex = boldEnd;
    } else if (italicMatch != null) {
      if (italicStart > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, italicStart),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: italicMatch.group(1),
        style: baseStyle?.copyWith(fontStyle: FontStyle.italic) ??
            const TextStyle(fontStyle: FontStyle.italic),
      ));
      currentIndex = italicEnd;
    } else {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: baseStyle,
      ));
      break;
    }
  }

  return TextSpan(children: spans);
}

class _Match {
  final int start;
  final int end;
  final bool isBold;
  final bool isItalic;
  final String content;

  _Match(this.start, this.end, this.isBold, this.content) : isItalic = !isBold;
}
