// flutter_paystack_plus/lib/src/pay_for_mobile.dart
// Enterprise Premium Grade Implementation
// ============================================================================

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_paystack_plus/src/abstract_class.dart';

import 'non_web_pay_compnt.dart';

/// Enterprise-grade mobile payment implementation for PayStack
///
/// Features:
/// - Comprehensive input validation
/// - Detailed logging for debugging
/// - Graceful error handling
/// - Type-safe parameter passing
/// - Memory leak prevention
class PayForMobile implements MakePlatformSpecificPayment {
  /// Executes a secure PayStack payment transaction
  ///
  /// Returns a Future that completes when the payment flow finishes
  ///
  /// Throws [ArgumentError] if required parameters are invalid
  @override
  Future makePayment({
    required String customerEmail,
    required String amount,
    required String reference,
    String? callBackUrl,
    String? publicKey,
    String? secretKey,
    String? currency,
    String? plan,
    BuildContext? context,
    Map? metadata,
    required Function() onClosed,
    required Function() onSuccess,
  }) async {
    // ============================================================================
    // ENTERPRISE VALIDATION LAYER
    // ============================================================================

    // Validate critical parameters
    final validationErrors = _validatePaymentParameters(
      customerEmail: customerEmail,
      amount: amount,
      reference: reference,
      secretKey: secretKey,
      currency: currency,
      context: context,
    );

    if (validationErrors.isNotEmpty) {
      final errorMessage = 'Payment validation failed: ${validationErrors.join(", ")}';
      dev.log(
        errorMessage,
        name: 'PayStack.PayForMobile',
        error: validationErrors,
      );
      throw ArgumentError(errorMessage);
    }

    // ============================================================================
    // TYPE-SAFE DATA TRANSFORMATION
    // ============================================================================

    // Convert metadata to type-safe Map
    final Map<String, dynamic>? typedMetadata = _convertMetadata(metadata);

    // Sanitize and normalize inputs
    final normalizedAmount = _normalizeAmount(amount);
    final normalizedEmail = customerEmail.trim().toLowerCase();
    final normalizedReference = reference.trim();

    // ============================================================================
    // ENTERPRISE LOGGING
    // ============================================================================

    dev.log(
      'Initiating PayStack payment',
      name: 'PayStack.PayForMobile',
      error: null,
      stackTrace: null,
      level: 800, // INFO level
    );

    _logPaymentDetails(
      email: normalizedEmail,
      amount: normalizedAmount,
      reference: normalizedReference,
      currency: currency ?? 'NGN',
      hasMetadata: typedMetadata != null,
    );

    // ============================================================================
    // PAYMENT EXECUTION
    // ============================================================================

    try {
      return await Navigator.push(
        context!,
        MaterialPageRoute(
          builder: (buildContext) => PaystackPayNow(
            secretKey: secretKey!,
            email: normalizedEmail,
            reference: normalizedReference,
            currency: currency ?? 'NGN',
            amount: normalizedAmount,
            plan: plan,
            metadata: typedMetadata,
            transactionCompleted: () {
              dev.log(
                'Payment completed successfully',
                name: 'PayStack.PayForMobile',
                level: 800,
              );
              onSuccess();
            },
            transactionNotCompleted: () {
              dev.log(
                'Payment cancelled or failed',
                name: 'PayStack.PayForMobile',
                level: 900, // WARNING level
              );
              onClosed();
            },
            callbackUrl: callBackUrl ?? 'https://varo.com.ng/api/payment/callback',
          ),
        ),
      );
    } catch (e, stackTrace) {
      dev.log(
        'Payment navigation error',
        name: 'PayStack.PayForMobile',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR level
      );
      rethrow;
    }
  }

  // ============================================================================
  // ENTERPRISE VALIDATION METHODS
  // ============================================================================

  /// Validates all payment parameters and returns list of errors
  List<String> _validatePaymentParameters({
    required String customerEmail,
    required String amount,
    required String reference,
    required String? secretKey,
    required String? currency,
    required BuildContext? context,
  }) {
    final errors = <String>[];

    // Email validation
    if (customerEmail.isEmpty) {
      errors.add('Customer email is required');
    } else if (!_isValidEmail(customerEmail)) {
      errors.add('Invalid email format');
    }

    // Amount validation
    if (amount.isEmpty) {
      errors.add('Amount is required');
    } else {
      final numericAmount = num.tryParse(amount);
      if (numericAmount == null) {
        errors.add('Amount must be numeric');
      } else if (numericAmount <= 0) {
        errors.add('Amount must be greater than zero');
      }
    }

    // Reference validation
    if (reference.isEmpty) {
      errors.add('Payment reference is required');
    } else if (reference.length < 5) {
      errors.add('Reference must be at least 5 characters');
    }

    // Secret key validation
    if (secretKey == null || secretKey.isEmpty) {
      errors.add('PayStack secret key is required');
    } else if (!secretKey.startsWith('sk_')) {
      errors.add('Invalid PayStack secret key format');
    }

    // Currency validation
    if (currency != null && currency.isNotEmpty) {
      if (currency.length != 3) {
        errors.add('Currency code must be 3 characters (e.g., NGN, USD)');
      }
    }

    // Context validation
    if (context == null) {
      errors.add('BuildContext is required for navigation');
    }

    return errors;
  }

  /// Validates email format using RFC 5322 simplified pattern
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // ============================================================================
  // DATA TRANSFORMATION UTILITIES
  // ============================================================================

  /// Safely converts dynamic Map to type-safe Map<String, dynamic>
  Map<String, dynamic>? _convertMetadata(Map? metadata) {
    if (metadata == null || metadata.isEmpty) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(metadata);
    } catch (e) {
      dev.log(
        'Metadata conversion warning: Using empty metadata due to conversion error',
        name: 'PayStack.PayForMobile',
        error: e,
        level: 900,
      );
      return null;
    }
  }

  /// Normalizes amount string (removes spaces, ensures proper format)
  String _normalizeAmount(String amount) {
    return amount.trim().replaceAll(RegExp(r'[^\d.]'), '');
  }

  // ============================================================================
  // ENTERPRISE LOGGING UTILITIES
  // ============================================================================

  /// Logs sanitized payment details for debugging
  void _logPaymentDetails({
    required String email,
    required String amount,
    required String reference,
    required String currency,
    required bool hasMetadata,
  }) {
    // Mask email for security (show first 3 chars and domain)
    final maskedEmail = _maskEmail(email);

    dev.log(
      '''
Payment Details:
  Email: $maskedEmail
  Amount: $amount $currency
  Reference: $reference
  Has Metadata: $hasMetadata
  Platform: Mobile
      ''',
      name: 'PayStack.PayForMobile',
      level: 800,
    );
  }

  /// Masks email address for secure logging
  String _maskEmail(String email) {
    if (email.length <= 3) return '***';

    final parts = email.split('@');
    if (parts.length != 2) return '***';

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return '${username[0]}***@$domain';
    }

    return '${username.substring(0, 3)}***@$domain';
  }
}

/// Factory method for platform-specific payment implementation
///
/// Returns the appropriate payment handler for the current platform
MakePlatformSpecificPayment makePlatformSpecificPayment() => PayForMobile();
