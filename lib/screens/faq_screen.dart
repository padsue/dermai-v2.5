import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/text_utils.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({Key? key}) : super(key: key);

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
              'FAQ & Support',
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
1. What is DermAI?
DermAI is an AI-powered telehealth platform developed for Skin Gold Clinic, designed to provide remote dermatological consultation, diagnosis, and treatment recommendations. It integrates AI-based skin image analysis with teleconsultation services to make dermatological care more accessible, affordable, and efficient.

2. How does DermAI work?
•   Patients upload a photo of their skin condition using the DermAI Mobile App.
•   The system’s AI model analyzes the image to identify possible skin types and skin disorders.
•   Patients can then book an online consultation or in-clinic appointment through the app.
•   They can also print a PDF copy of their scan results.

3. What types of skin conditions can DermAI detect?
DermAI can identify and classify a wide range of dermatological conditions, including but not limited to: Acne, Eczema, Psoriasis, Melasma, Fungal Infections, and Pigmentation Disorders.
*(Note: All AI-generated results are subject to dermatologist verification.)*

4. Is DermAI safe and accurate?
Yes. DermAI uses a highly accurate image classification algorithm. However, while it achieves high accuracy in recognizing common skin disorders, final medical assessments and prescriptions are always performed by certified dermatologists to ensure patient safety and clinical reliability.

5. Who can use DermAI?
DermAI is designed for:
•   Patients seeking affordable and remote dermatological consultation.
•   Individuals from rural or underserved areas.
•   Dermatologists from Skin Gold Clinic using the DermAI Web Portal for patient management.

6. How is patient data protected?
DermAI follows strict data privacy and confidentiality protocols, consistent with the Data Privacy Act of 2012 (RA 10173). All patient images and medical information are encrypted, stored securely, and accessible only to authorized dermatologists.

7. What if the AI result is incorrect or unclear?
In such cases, patients are encouraged to schedule a teleconsultation for a manual review. DermAI’s diagnostic results are intended as decision-support tools, not as replacements for professional medical evaluation.

8. How much does a consultation cost?
Consultation fees vary depending on the dermatologist’s specialization. The app automatically displays the consultation fee before booking confirmation.

9. What are the benefits of using DermAI?
•   Fast and AI-assisted skin evaluation.
•   Affordable and accessible teleconsultations.
•   Reduced need for travel or clinic visits.
•   Verified treatment recommendations.
•   Data-driven patient insights for dermatologists.

Technical Support & Contact
For assistance, please contact DermAI Support Team at Skin Gold Clinic:
•   **Email:** support@skingoldclinic.com
•   **Hotline:** +63 912 345 6789
•   **Website:** www.skingoldclinic.com/dermAI
•   **Support Hours:** Monday to Saturday, 9:00 AM – 6:00 PM.
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
