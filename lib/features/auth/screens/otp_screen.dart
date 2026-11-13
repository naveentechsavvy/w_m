import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final AuthController controller = Get.find<AuthController>();

  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  Timer? _resendTimer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _startResendTimer();
  }

  void _startResendTimer() {
    _secondsLeft = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _handleResend() {
    controller.sendOtp();
    _startResendTimer();
  }

  @override
  void dispose() {
    _animController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = controller.phoneController.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon badge
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.sms_outlined,
                            color: AppColors.primary,
                            size: 34,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Text(
                        "Verify OTP",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text.rich(
                        TextSpan(
                          text: "Enter the 6-digit code sent to\n",
                          children: [
                            TextSpan(
                              text: phone,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 36),

                      _OtpBoxesInput(
                        controller: controller.otpController,
                        length: 6,
                        onCompleted: () {
                          if (!controller.loading.value) {
                            controller.verifyOtp();
                          }
                        },
                      ),

                      const SizedBox(height: 36),

                      Obx(
                        () => PrimaryButton(
                          title: "Verify",
                          loading: controller.loading.value,
                          onPressed: controller.verifyOtp,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: _secondsLeft > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Resend OTP in "
                                      "00:${_secondsLeft.toString().padLeft(2, '0')}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Didn't receive the code?",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _handleResend,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    child: Text(
                                      "Resend OTP",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of [length] boxes that visually represent individual OTP
/// digits, backed by a single hidden TextField using the same
/// TextEditingController the rest of the app already reads from
/// (controller.otpController) — so AuthController.verifyOtp() keeps
/// working unchanged; this widget only changes how input looks, not
/// how it's stored.
class _OtpBoxesInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final VoidCallback? onCompleted;

  const _OtpBoxesInput({
    required this.controller,
    required this.length,
    this.onCompleted,
  });

  @override
  State<_OtpBoxesInput> createState() => _OtpBoxesInputState();
}

class _OtpBoxesInputState extends State<_OtpBoxesInput> {
  final FocusNode _focusNode = FocusNode();
  late String _text;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _text = widget.controller.text;
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  void _onChanged() {
    setState(() => _text = widget.controller.text);
    if (_text.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: List.generate(widget.length * 2 - 1, (i) {
              if (i.isOdd) return const SizedBox(width: 10);
              final index = i ~/ 2;
              final filled = index < _text.length;
              final isActiveCursor = _hasFocus && index == _text.length;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 58,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.primaryTint : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActiveCursor
                          ? AppColors.primary
                          : (filled
                              ? AppColors.primary.withOpacity(0.45)
                              : AppColors.divider),
                      width: isActiveCursor ? 2 : 1.2,
                    ),
                    boxShadow: isActiveCursor
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const [],
                  ),
                  alignment: Alignment.center,
                  child: isActiveCursor
                      ? Container(
                          width: 2,
                          height: 24,
                          color: AppColors.primary,
                        )
                      : Text(
                          filled ? _text[index] : '',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
              );
            }),
          ),

          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ],
      ),
    );
  }
}
