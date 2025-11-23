import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/text_utils.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'About DermAI',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.cherryBlossom,
                borderRadius: BorderRadius.circular(20),
              ),
              child: RichText(
                text: buildRichText(
                  '''
Welcome to **DermAI**, your personal skin health companion designed to empower you with insights and connect you with professional care.

**What is DermAI?**
DermAI leverages cutting-edge **artificial intelligence** to provide you with a preliminary analysis of your skin. Our goal is to make skin health assessment more accessible and to bridge the gap between you and professional dermatological care.

**Core Features:**
•   **AI-Powered Skin Analysis:** Simply take photos of your skin, and our AI model will provide insights into potential skin conditions and identify your skin type.
•   **Detailed Scan History:** Keep a comprehensive record of all your scans. Track changes over time and review your results whenever you need them.
•   **Consult with Professionals:** Browse a directory of licensed dermatologists, view their profiles, and book an appointment directly through the app.

**Our Mission**
Our mission is to provide an accessible, user-friendly tool that helps you stay informed about your skin's health and facilitates a seamless connection to professional medical advice.

**Disclaimer**
DermAI is an informational tool and is **not a substitute for professional medical diagnosis or treatment**. Always consult a qualified healthcare provider for any medical concerns. The results provided by DermAI are for *informational purposes only*.
                  ''',
                  baseStyle: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
