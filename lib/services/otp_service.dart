import 'package:cloud_functions/cloud_functions.dart';

class OtpService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<bool> sendOtp(String email) async {
    try {
      final result = await _functions.httpsCallable('sendOtp').call({
        'email': email,
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final result = await _functions.httpsCallable('verifyOtp').call({
        'email': email,
        'otp': otp,
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Password Reset Methods
  Future<bool> sendPasswordResetOtp(String email) async {
    try {
      final result = await _functions.httpsCallable('sendPasswordResetOtp').call({
        'email': email,
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending password reset OTP: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyPasswordResetOtp(String email, String otp) async {
    try {
      final result = await _functions.httpsCallable('verifyPasswordResetOtp').call({
        'email': email,
        'otp': otp,
      });
      return {
        'success': result.data['success'] == true,
        'message': result.data['message'] ?? '',
        'resetToken': result.data['resetToken'] ?? '',
      };
    } catch (e) {
      print('Error verifying password reset OTP: $e');
      return {
        'success': false,
        'message': 'Error verifying OTP. Please try again.',
        'resetToken': '',
      };
    }
  }

  Future<bool> resetPasswordWithOtp(String email, String resetToken, String newPassword) async {
    try {
      final result = await _functions.httpsCallable('resetPasswordWithOtp').call({
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error resetting password with OTP: $e');
      return false;
    }
  }
}