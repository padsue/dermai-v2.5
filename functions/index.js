const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();
const db = admin.firestore();

// SMTP Configuration
// TODO: Use environment variables for production!
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "dermaixxiv@gmail.com",
    pass: "kayaidweitgrcwdo",
  },
});

exports.sendOtp = onCall(async (request) => {
  const email = request.data.email;
  if (!email) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with an email."
    );
  }

  // Generate 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000); // 10 mins

  try {
    // Save to Firestore
    await db.collection("otps").doc(email).set({
      otp: otp,
      expiresAt: expiresAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send Email
    const mailOptions = {
      from: '"DermAI" <dermaixxiv@gmail.com>',
      to: email,
      subject: "Your OTP Code",
      text: `Hello,\n\nYour one-time password (OTP) for DermAI is: ${otp}\n\nThis code will expire in 10 minutes. Please do not share this code with anyone.\n\nBest regards,\nDermAI Team`,
    };

    await transporter.sendMail(mailOptions);
    return { success: true, message: "OTP sent successfully" };
  } catch (error) {
    console.error("Error sending OTP:", error);
    throw new HttpsError("internal", "Failed to send OTP.");
  }
});

exports.verifyOtp = onCall(async (request) => {
  const email = request.data.email;
  const userOtp = request.data.otp;

  if (!email || !userOtp) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with email and otp."
    );
  }

  try {
    const docRef = db.collection("otps").doc(email);
    const doc = await docRef.get();

    if (!doc.exists) {
      return { success: false, message: "No OTP found for this email." };
    }

    const data = doc.data();
    const now = admin.firestore.Timestamp.now();

    if (now > data.expiresAt) {
      return { success: false, message: "OTP has expired." };
    }

    if (data.otp === userOtp) {
      // Valid OTP
      await docRef.delete(); // Prevent reuse
      return { success: true, message: "OTP verified successfully." };
    } else {
      return { success: false, message: "Invalid OTP." };
    }
  } catch (error) {
    console.error("Error verifying OTP:", error);
    throw new HttpsError("internal", "Failed to verify OTP.");
  }
});

// Password Reset with OTP Functions
exports.sendPasswordResetOtp = onCall(async (request) => {
  const email = request.data.email;
  if (!email) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with an email."
    );
  }

  try {
    // Verify email exists in Firebase Auth
    try {
      await admin.auth().getUserByEmail(email);
    } catch (authError) {
      // Don't reveal if user exists or not for security
      return { success: true, message: "If the email exists, an OTP has been sent." };
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 10 * 60 * 1000); // 10 mins

    // Save to Firestore with password_reset type
    await db.collection("password_reset_otps").doc(email).set({
      otp: otp,
      expiresAt: expiresAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      verified: false,
    });

    // Send Email
    const mailOptions = {
      from: '"DermAI" <dermaixxiv@gmail.com>',
      to: email,
      subject: "Password Reset OTP - DermAI",
      text: `Hello,\n\nYou requested to reset your password for DermAI.\n\nYour one-time password (OTP) is: ${otp}\n\nThis code will expire in 10 minutes. Please do not share this code with anyone.\n\nIf you did not request this password reset, please ignore this email.\n\nBest regards,\nDermAI Team`,
    };

    await transporter.sendMail(mailOptions);
    return { success: true, message: "Password reset OTP sent successfully" };
  } catch (error) {
    console.error("Error sending password reset OTP:", error);
    throw new HttpsError("internal", "Failed to send password reset OTP.");
  }
});

exports.verifyPasswordResetOtp = onCall(async (request) => {
  const email = request.data.email;
  const userOtp = request.data.otp;

  if (!email || !userOtp) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with email and otp."
    );
  }

  try {
    const docRef = db.collection("password_reset_otps").doc(email);
    const doc = await docRef.get();

    if (!doc.exists) {
      return { success: false, message: "No OTP found for this email." };
    }

    const data = doc.data();
    const now = admin.firestore.Timestamp.now();

    if (now > data.expiresAt) {
      return { success: false, message: "OTP has expired." };
    }

    if (data.otp === userOtp) {
      // Generate temporary reset token
      const resetToken = Math.random().toString(36).substring(2) + Date.now().toString(36);
      const tokenExpiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + 5 * 60 * 1000); // 5 mins

      // Store reset token
      await db.collection("password_reset_tokens").doc(email).set({
        token: resetToken,
        expiresAt: tokenExpiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark OTP as verified
      await docRef.update({ verified: true });

      return {
        success: true,
        message: "OTP verified successfully.",
        resetToken: resetToken
      };
    } else {
      return { success: false, message: "Invalid OTP." };
    }
  } catch (error) {
    console.error("Error verifying password reset OTP:", error);
    throw new HttpsError("internal", "Failed to verify password reset OTP.");
  }
});

exports.resetPasswordWithOtp = onCall(async (request) => {
  const email = request.data.email;
  const resetToken = request.data.resetToken;
  const newPassword = request.data.newPassword;

  if (!email || !resetToken || !newPassword) {
    throw new HttpsError(
      "invalid-argument",
      "The function must be called with email, resetToken, and newPassword."
    );
  }

  // Validate password length
  if (newPassword.length < 6) {
    return { success: false, message: "Password must be at least 6 characters long." };
  }

  try {
    // Verify reset token
    const tokenDocRef = db.collection("password_reset_tokens").doc(email);
    const tokenDoc = await tokenDocRef.get();

    if (!tokenDoc.exists) {
      return { success: false, message: "Invalid or expired reset token." };
    }

    const tokenData = tokenDoc.data();
    const now = admin.firestore.Timestamp.now();

    if (now > tokenData.expiresAt) {
      await tokenDocRef.delete();
      return { success: false, message: "Reset token has expired." };
    }

    if (tokenData.token !== resetToken) {
      return { success: false, message: "Invalid reset token." };
    }

    // Get user by email
    const userRecord = await admin.auth().getUserByEmail(email);

    // Update password using Admin SDK
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    // Clean up: delete token and OTP
    await tokenDocRef.delete();
    await db.collection("password_reset_otps").doc(email).delete();

    return { success: true, message: "Password reset successfully." };
  } catch (error) {
    console.error("Error resetting password with OTP:", error);
    throw new HttpsError("internal", "Failed to reset password.");
  }
});
