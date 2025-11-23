import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/otp_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../services/notification_service.dart';
import 'email_otp_verification_screen.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  final OtpService _otpService = OtpService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    bool sent = await _otpService.sendOtp(_emailController.text.trim());

    if (sent) {
      if (mounted) {
        final notificationService = context.read<NotificationService>();
        await notificationService.showNotification(
          title: 'OTP Sent',
          body: 'Check your email for the OTP.',
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailOtpVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        ).then((verified) {
          if (verified == true) {
            // Handle successful verification, perhaps navigate to main screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    } else {
      setState(() {
        _emailError = 'Failed to send OTP. Please try again.';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonExt = Theme.of(context).extension<ButtonStyleExtension>();

    return Scaffold(
      appBar: CustomAppBar(showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sign in with OTP",
                style: theme.textTheme.displayMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your email to receive a one-time password.",
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 30),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: buttonExt?.gradientColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: buttonExt?.gradientButtonStyle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: SizedBox(
                            height: theme.textTheme.titleLarge?.fontSize,
                            width: theme.textTheme.titleLarge?.fontSize,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      Text(
                        "Send OTP",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
