import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/text_utils.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

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
              'Privacy Policy',
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
Welcome to DermAI! This **Privacy Policy** explains how we collect, use, disclose, and safeguard your information when you use our mobile application (“App”). By using DermAI, you agree to the collection and use of information in accordance with this policy.

1. Information We Collect
We may collect personal information such as your name, email address, contact details, and profile information. We also collect usage data, including device information and app interactions.

2. How We Use Your Information
We use the collected information to provide and improve our services, communicate with you, ensure security, and comply with legal obligations.

3. Sharing Your Information
We do not sell or rent your personal information to third parties. We may share information with service providers, for legal reasons, or with your consent.

4. Data Security
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. Your Rights
You have the right to access, update, or delete your personal information. Contact us to exercise these rights.

6. Changes to This Policy
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page.

7. Contact Us
If you have any questions about this Privacy Policy, please contact us at [Your Contact Information].
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
