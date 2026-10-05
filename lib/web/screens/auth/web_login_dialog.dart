import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/core/services/google_auth_service.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/auth/models/request/user_payload.dart';
import 'package:masti_adda_app/features/auth/models/response/user_model.dart';
import 'package:masti_adda_app/features/auth/repositories/auth_datasource.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';

class WebLoginDialog extends StatefulWidget {
  final String? customMessage;

  const WebLoginDialog({super.key, this.customMessage});

  @override
  State<WebLoginDialog> createState() => _WebLoginDialogState();
}

class _WebLoginDialogState extends State<WebLoginDialog> {
  final AuthDatasource _authDatasource = AuthDatasource();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isOtpSent = false;
  bool _isCompletingProfile = false;
  bool _isLoading = false;
  String _errorMessage = '';
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 30);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(
        () => _errorMessage = 'Please enter a valid 10-digit mobile number',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final success = await _authDatasource.sendOtp(phone: phone);
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isOtpSent = true);
      _startCountdown();
    } else {
      setState(() => _errorMessage = 'Failed to send OTP. Please try again.');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) {
      setState(() => _errorMessage = 'Please enter the 4-digit OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await _authDatasource.verifyOtp(
      phone: _phoneController.text.trim(),
      otp: otp,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      final user = result.user;
      final rawName = user?.name.trim() ?? '';
      final isGenericName =
          rawName.isEmpty ||
          rawName.toLowerCase() == 'user' ||
          rawName.toLowerCase() == 'new user' ||
          rawName.toLowerCase() == 'mastiadda user' ||
          rawName == user?.phone.trim() ||
          rawName == _phoneController.text.trim();

      final bool needsRegistration =
          !result.profileComplete || result.isNewUser || isGenericName;

      if (needsRegistration) {
        // Unregistered new account: prompt user to complete profile/registration
        setState(() {
          _isCompletingProfile = true;
          _errorMessage = '';
          if (!isGenericName && rawName.isNotEmpty) {
            _nameController.text = rawName;
          } else {
            _nameController.clear();
          }
          if (user != null && user.email.isNotEmpty) {
            _emailController.text = user.email;
          }
        });
      } else {
        // Existing registered user: finish login
        if (Get.isRegistered<SubscriptionStatusController>()) {
          Get.find<SubscriptionStatusController>().checkStatus();
        }
        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          } else {
            Get.offAllNamed(WebRoutes.home);
          }
        }
      }
    } else {
      setState(() => _errorMessage = result.message ?? 'Invalid OTP code');
    }
  }

  Future<void> _completeProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }
    if (name.length < 3) {
      setState(() => _errorMessage = 'Name must be at least 3 characters');
      return;
    }
    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (phone.isNotEmpty && phone.length != 10) {
      setState(
        () => _errorMessage = 'Please enter a valid 10-digit mobile number',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    var existingUser = await StorageService.getUser();
    final updatedUser = UserModel(
      id: (existingUser != null && existingUser.id.isNotEmpty)
          ? existingUser.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email.isNotEmpty ? email : (existingUser?.email ?? ''),
      phone: phone.isNotEmpty ? phone : (existingUser?.phone ?? ''),
      interests: existingUser?.interests ?? [],
      profileImage: existingUser?.profileImage ?? '',
      profileComplete: true,
      role: existingUser?.role ?? 'USER',
      authProvider:
          (existingUser != null && existingUser.authProvider.isNotEmpty)
          ? existingUser.authProvider
          : 'google',
    );

    await StorageService.saveUser(updatedUser);

    try {
      await _authDatasource.completeProfile(
        userPayload: UserPayload(
          phone: phone.isNotEmpty ? phone : (existingUser?.phone ?? ''),
          name: name,
          email: email,
          interests: [],
          profileComplete: true,
        ),
      );
    } catch (e) {
      debugPrint("completeProfile sync note: $e");
    }

    if (Get.isRegistered<ProfileController>()) {
      try {
        Get.find<ProfileController>().user.value = updatedUser;
      } catch (_) {}
    }

    if (Get.isRegistered<SubscriptionStatusController>()) {
      Get.find<SubscriptionStatusController>().checkStatus();
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Get.offAllNamed(WebRoutes.home);
      }
    }
  }

  Future<void> _googleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final account = await _googleAuthService.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String name =
          (account.displayName != null &&
              account.displayName!.trim().isNotEmpty)
          ? account.displayName!.trim()
          : 'Masti Adda User';
      final String email = account.email.trim();
      final String photoUrl = account.photoUrl ?? '';
      final String googleId = account.id;

      // 1. Immediately create and save user profile locally
      UserModel activeUser = UserModel(
        id: googleId,
        name: name,
        email: email,
        phone: _phoneController.text.trim(),
        interests: [],
        profileImage: photoUrl,
        profileComplete: true,
        role: 'USER',
        authProvider: 'google',
      );

      await StorageService.saveUser(activeUser);
      await StorageService.saveLoginMethod('google');

      // 2. Sync token and backend data in background
      try {
        final auth = await _googleAuthService.getAuthentication(account);
        final idToken = (auth?.idToken != null && auth!.idToken!.isNotEmpty)
            ? auth.idToken!
            : (auth?.accessToken ?? '');

        if (idToken.isNotEmpty) {
          final result = await _authDatasource.googleLogin(
            idToken: idToken,
            accessToken: auth?.accessToken,
            email: email,
            name: name,
            photoUrl: photoUrl,
            googleId: googleId,
          );

          if (result.success) {
            if (result.user != null) {
              activeUser = result.user!;
              await StorageService.saveUser(activeUser);
            }
            final resultToken = result.token ?? '';
            if (resultToken.isNotEmpty) {
              await StorageService.saveToken(resultToken);
            }
          }
        }
      } catch (e) {
        debugPrint("Google login backend sync note: $e");
      }

      // 3. Update GetX controllers
      if (Get.isRegistered<ProfileController>()) {
        try {
          Get.find<ProfileController>().user.value = activeUser;
        } catch (_) {}
      }

      if (Get.isRegistered<SubscriptionStatusController>()) {
        Get.find<SubscriptionStatusController>().checkStatus();
      }

      setState(() => _isLoading = false);

      // 4. Immediately complete login and redirect to home
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          Get.offAllNamed(WebRoutes.home);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google Sign-In failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF14171F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderColor.withOpacity(0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close Button & Brand Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      AppImages.logo,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppColors.primaryPink,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Masti Adda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.secondaryTextColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Modal Title & Subtitle
            Text(
              _isCompletingProfile
                  ? 'Create Your Account'
                  : (_isOtpSent ? 'Verify OTP' : 'Sign In to Masti Adda'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isCompletingProfile
                  ? (_phoneController.text.trim().isNotEmpty
                        ? 'Enter your details to finish setting up your account for +91 ${_phoneController.text.trim()}'
                        : 'Review and confirm your profile details below to continue.')
                  : (_isOtpSent
                        ? 'We sent a 4-digit verification code to +91 ${_phoneController.text.trim()}'
                        : (widget.customMessage ??
                              'Enter your mobile number to unlock full movies, series, and dramas.')),
              style: const TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Error message banner
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_isCompletingProfile) ...[
              // Name Input Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.secondaryTextColor,
                      size: 20,
                    ),
                    hintText: 'Full Name (Required)',
                    hintStyle: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _completeProfile(),
                ),
              ),
              const SizedBox(height: 14),

              // Email Input Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.secondaryTextColor,
                      size: 20,
                    ),
                    hintText: 'Email Address (Optional)',
                    hintStyle: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _completeProfile(),
                ),
              ),
              if (_phoneController.text.trim().isEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderColor.withOpacity(0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      counterText: '',
                      prefixIcon: Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.secondaryTextColor,
                        size: 20,
                      ),
                      hintText: 'Mobile Number (Optional)',
                      hintStyle: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _completeProfile(),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Agreement text
              const Text(
                'By creating an account, you agree to Masti Adda Terms of Service and Privacy Policy.',
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Create Account Button
              ElevatedButton(
                onPressed: _isLoading ? null : _completeProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Account & Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Back to sign in button
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isCompletingProfile = false;
                            _isOtpSent = false;
                            _errorMessage = '';
                            for (var c in _otpControllers) {
                              c.clear();
                            }
                          });
                        },
                  child: const Text(
                    'Cancel & Back to Sign In',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ] else if (!_isOtpSent) ...[
              // Phone Input Field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E222D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.borderColor.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFF2C3242)),
                        ),
                      ),
                      child: const Text(
                        '+91',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter 10-digit mobile number',
                          hintStyle: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onSubmitted: (_) => _sendOtp(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Send OTP Button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Continue with Mobile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // OR Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.1)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign-In Button
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _googleSignIn,
                icon: Image.asset(
                  AppImages.google,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ] else ...[
              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 65,
                    height: 55,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E222D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: AppColors.borderColor.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primaryPink,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _otpFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _otpFocusNodes[index - 1].requestFocus();
                        }
                        if (_otpControllers.every((c) => c.text.isNotEmpty)) {
                          _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify & Proceed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Resend & Change Number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _countdownTimer?.cancel();
                      setState(() {
                        _isOtpSent = false;
                        _errorMessage = '';
                        for (var c in _otpControllers) {
                          c.clear();
                        }
                      });
                    },
                    child: const Text(
                      'Change Number',
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: const TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 13,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: AppColors.primaryPink,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
