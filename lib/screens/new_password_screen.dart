import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/otp_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/keyboard_utils.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/notification_service.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _passwordError;
  String? _confirmPasswordError;
  final OtpService _otpService = OtpService();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_clearErrors);
    _confirmPasswordController.addListener(_clearErrors);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_clearErrors);
    _confirmPasswordController.removeListener(_clearErrors);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_passwordError != null || _confirmPasswordError != null) {
      setState(() {
        _passwordError = null;
        _confirmPasswordError = null;
      });
    }
  }

  Future<void> _resetPassword() async {
    KeyboardUtils.dismissKeyboard(context);
    if (_formKey.currentState!.validate()) {
      // Check if passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _confirmPasswordError = 'Passwords do not match';
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        bool success = await _otpService.resetPasswordWithOtp(
          widget.email,
          widget.resetToken,
          _passwordController.text.trim(),
        );

        if (success && mounted) {
          // Play sound and show notification
          final player = AudioPlayer();
          player.play(AssetSource('sounds/chime.mp3'));

          final notificationService = context.read<NotificationService>();
          await notificationService.showNotification(
            title: 'Password Reset Successful',
            body: 'Your password has been reset. Please sign in with your new password.',
          );

          // Navigate back to sign in (pop all password reset screens)
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (mounted) {
          setState(() {
            _passwordError = 'Failed to reset password. Token may have expired.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _passwordError = 'An error occurred. Please try again.';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Create New Password",
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: "\nEnter your new password",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "New Password",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: "Password",
                    errorText: _passwordError,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  "Confirm Password",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    errorText: _confirmPasswordError,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
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
                    onPressed: _isLoading ? null : _resetPassword,
                    style: buttonExt?.gradientButtonStyle?.copyWith(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
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
                          "Reset Password",
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
      ),
    );
  }
}
