import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import 'logger_service.dart';
import 'toast_service.dart';

/// Production Razorpay Service for AYO Platform
class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  Razorpay? _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    dispose(); // Clear previous instance if any
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onWallet = onWallet;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    LoggerService.info('Razorpay initialized successfully');
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    LoggerService.info('Razorpay Payment Success: ${response.paymentId} for Order: ${response.orderId}');
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    LoggerService.error('Razorpay Payment Error: [${response.code}] ${response.message}');
    ToastService.showError(response.message ?? 'Payment failed or cancelled');
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    LoggerService.info('Razorpay External Wallet: ${response.walletName}');
    _onWallet?.call(response);
  }

  void openCheckout({
    required String keyId,
    required int amountPaise,
    required String orderId,
    required String name,
    required String description,
    String? contact,
    String? email,
  }) {
    if (_razorpay == null) {
      LoggerService.error('Razorpay not initialized. Call initialize() first.');
      return;
    }

    // Normalize amount: Razorpay strictly expects paise (1 INR = 100 paise).
    int finalAmountPaise = amountPaise;
    if (finalAmountPaise > 0 && finalAmountPaise < 1000) {
      finalAmountPaise = finalAmountPaise * 100;
    }

    final trimmedKey = keyId.trim().isNotEmpty ? keyId.trim() : ApiConfig.defaultRazorpayKey;
    if (trimmedKey.isEmpty) {
      LoggerService.error('Razorpay keyId is missing. Backend did not supply a valid Razorpay key.');
      ToastService.showError('Payment gateway key is not configured on the server.');
      return;
    }
    final trimmedOrderId = orderId.trim();
    // Razorpay native Android SDK strictly requires order_id to start with 'order_'.
    final isValidOrderId = trimmedOrderId.startsWith('order_');

    // Razorpay Android requires a clean 10-digit phone number without '+' or country codes
    String? cleanContact;
    if (contact != null && contact.trim().isNotEmpty) {
      final digits = contact.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 10) {
        cleanContact = digits;
      } else if (digits.length > 10 && digits.startsWith('91')) {
        cleanContact = digits.substring(digits.length - 10);
      } else if (digits.isNotEmpty) {
        cleanContact = digits;
      }
    }

    final options = <String, dynamic>{
      'key': trimmedKey,
      'amount': finalAmountPaise,
      'currency': 'INR',
      'name': name,
      'description': description,
      'timeout': 180,
      if (isValidOrderId) 'order_id': trimmedOrderId,
      'prefill': {
        if (cleanContact != null && cleanContact.isNotEmpty) 'contact': cleanContact,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
      'theme': {
        'color': '#E50914', // AYO Brand Red
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    LoggerService.info(
      'Opening Razorpay Checkout: Key=$trimmedKey, Amount=₹${finalAmountPaise / 100}, OrderId=${isValidOrderId ? trimmedOrderId : "[standard mode]"}',
    );
    _razorpay!.open(options);
  }

  void dispose() {
    try {
      _razorpay?.clear();
      _razorpay = null;
      _onSuccess = null;
      _onFailure = null;
      _onWallet = null;
    } catch (_) {}
  }
}
