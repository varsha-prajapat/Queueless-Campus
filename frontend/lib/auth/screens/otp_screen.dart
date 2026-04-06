import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/otp_service.dart';
import '../../services/socket_service.dart';
import '../../../routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../provider/profile_provider.dart';
import "../../utils/auth_role_helper.dart";
import "../../services/staff_service/counter_service.dart";

const String PURPOSE_REGISTER = "EMAIL_VERIFICATION";
const String PURPOSE_LOGIN = "LOGIN_2FA";

class OTPScreen extends StatefulWidget {
  final String email;
  final String purpose;

  const OTPScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final int otpLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get otp => _controllers.map((c) => c.text).join();

  Future<void> verifyOtp() async {
    if (otp.length != otpLength) {
      showBottomError("Enter 6-digit OTP");
      return;
    }

    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      await OTPService.verifyOtp(
        email: widget.email,
        otp: otp,
        purpose: widget.purpose,
      );

      if (!mounted) return;

      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      if (widget.purpose == PURPOSE_LOGIN) {
        await profileProvider.fetchProfile();

        final socketService = SocketService();
        final userId = await AuthRoleHelper.getUserId();
        final String role = (await AuthRoleHelper.getRole()).toUpperCase();

        List<String> counterIds = [];

        if (role.toLowerCase() == "staff") {
          try {
            final counters =
                await CounterService.getUserCounters(staffId: userId);

            counterIds = counters.map((c) => c.id).toList();
          } catch (_) {
            counterIds = [];
          }
        }

        socketService.init(
          userId: userId,
          roles: [role],
          counters: counterIds,
        );

        socketService.connect();
      }

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.purpose == PURPOSE_REGISTER ? AppRoutes.login : AppRoutes.app,
        (_) => false,
      );
    } catch (e) {
      final message =
          e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
      showBottomError(message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showBottomError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 42,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        keyboardType: TextInputType.number,
        textInputAction: index == otpLength - 1
            ? TextInputAction.done
            : TextInputAction.next,
        maxLength: 1,
        textAlign: TextAlign.center,
        cursorColor: AppColors.primary,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.only(bottom: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < otpLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.purpose == PURPOSE_REGISTER
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.black,
                onPressed: () {
                  if (widget.purpose == PURPOSE_LOGIN) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (_) => false,
                    );
                  }
                },
              ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgTop,
                  AppColors.bgBottom,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 30),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 25,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "OTP Verification",
                          style: AppTextStyles.appTitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Enter the 6-digit code sent to\n${widget.email}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            otpLength,
                            (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _otpBox(i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  )
                                : const Text(
                                    "Verify",
                                    style: AppTextStyles.buttonText,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
