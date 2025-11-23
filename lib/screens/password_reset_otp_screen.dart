import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import 'new_password_screen.dart';

class PasswordResetOtpScreen extends StatefulWidget {
  final String email;

  const PasswordResetOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetOtpScreen> createState() => _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _otpError;
  final OtpService _otpService = OtpService();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _otpError = 'Please enter a valid 6-digit OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    final result = await _otpService.verifyPasswordResetOtp(
      widget.email,
      _otpController.text.trim(),
    );

    if (result['success'] == true) {
      if (mounted) {
        // Navigate to new password screen with reset token
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordScreen(
              email: widget.email,
              resetToken: result['resetToken'] as String,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _otpError = result['message'] as String? ?? 'Invalid OTP. Please try again.';
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    bool sent = await _otpService.sendPasswordResetOtp(widget.email);

    if (sent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new OTP has been sent to your email.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
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
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Enter OTP",
                      style: theme.textTheme.displayMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                    TextSpan(
                      text: "\nA 6-digit code was sent to ${widget.email}",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  hintText: "------",
                  counterText: "",
                  errorText: _otpError,
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
                  onPressed: _isLoading ? null : _verifyOtp,
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
                        "Verify OTP",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _resendOtp,
                  child: Text(
                    "Resend OTP",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
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
