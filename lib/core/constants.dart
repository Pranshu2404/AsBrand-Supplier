class ApiConstants {
  // ---------------------------------------------------------------------------
  // NETWORK CONFIGURATION
  // ---------------------------------------------------------------------------
  static const String baseUrl = 'http://52.70.7.244:3000';

  // ---------------------------------------------------------------------------
  // AUTH ENDPOINTS
  // ---------------------------------------------------------------------------
  static const String login = '$baseUrl/users/login';
  static const String register = '$baseUrl/users/register';
  static const String profile = '$baseUrl/users/profile';
  static const String sendOtp = '$baseUrl/users/send-otp';
  static const String verifyOtp = '$baseUrl/users/verify-otp';
  static const String users = '$baseUrl/users';

  // ---------------------------------------------------------------------------
  // PRODUCT ENDPOINTS
  // ---------------------------------------------------------------------------
  static const String products = '$baseUrl/products';
  static const String categories = '$baseUrl/categories';
  static const String subCategories = '$baseUrl/subCategories';
  static const String subSubCategories = '$baseUrl/subSubCategories';
  static const String brands = '$baseUrl/brands';
  static const String variants = '$baseUrl/variants';
  static const String variantTypes = '$baseUrl/variantTypes';

  // ---------------------------------------------------------------------------
  // ORDER & CART ENDPOINTS
  // ---------------------------------------------------------------------------
  static const String orders = '$baseUrl/orders';
  static const String cart = '$baseUrl/cart';
  static const String wishlist = '$baseUrl/wishlist';
  static const String address = '$baseUrl/address';
  static const String coupons = '$baseUrl/couponCodes';

  // ---------------------------------------------------------------------------
  // EMI & KYC ENDPOINTS
  // ---------------------------------------------------------------------------
  static const String emiPlans = '$baseUrl/emi/plans';
  static const String emiApply = '$baseUrl/emi/apply';
  static const String emiApplications = '$baseUrl/emi/my-emis';
  static const String kyc = '$baseUrl/kyc';
  static const String kycSubmit = '$baseUrl/kyc/submit';
  static const String kycStatus = '$baseUrl/kyc/status';

  // ---------------------------------------------------------------------------
  // OTHER ENDPOINTS
  // ---------------------------------------------------------------------------
  static const String posters = '$baseUrl/posters';
  static const String notifications = '$baseUrl/notification';
  static const String payment = '$baseUrl/payment';
  static const String shipping = '$baseUrl/shipping';
  static const String reviews = '$baseUrl/reviews';
  static const String setting = '$baseUrl/setting';

  // ---------------------------------------------------------------------------
  // SUPPLIER ENDPOINTS
  // ---------------------------------------------------------------------------
  static const String supplierRegister = '$baseUrl/supplier/register';
  static const String supplierVerifyGst = '$baseUrl/supplier/verify-gst';
  static const String supplierVerifyUdyam = '$baseUrl/supplier/verify-udyam';
  static const String supplierProfile = '$baseUrl/supplier/profile';
  static const String supplierDashboard = '$baseUrl/supplier/dashboard';
  static const String supplierProducts = '$baseUrl/supplier/products';
  static const String supplierOrders = '$baseUrl/supplier/orders';

  // Payment
  static const String initiateOrder = '$payment/initiate';
  static const String verifyPayment = '$payment/verify';
  static const String cod = '$payment/cod';
}
