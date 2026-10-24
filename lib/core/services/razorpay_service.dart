import 'package:razorpay_flutter/razorpay_flutter.dart';
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

    final options = {
      'key': keyId,
      'amount': amountPaise,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        if (email != null && email.isNotEmpty) 'email': email,
      },
      'theme': {
        'color': '#E50914', // AYO Brand Red
      },
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe']
      }
    };

    LoggerService.info('Opening Razorpay Checkout for Order $orderId (Amount: ₹${amountPaise / 100})');
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
