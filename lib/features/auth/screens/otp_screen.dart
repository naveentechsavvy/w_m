import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/theme/colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_title.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    title: "Verify OTP",
                    subtitle:
                        "Enter the 6-digit code sent to ${controller.phoneController.text}",
                  ),

                  const SizedBox(height: 32),

                  // Capped width so boxes stay grouped together
                  // instead of stretching edge-to-edge on wide screens.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _OtpBoxesInput(
                      controller: controller.otpController,
                      length: 6,
                      onCompleted: () {
                        if (!controller.loading.value) {
                          controller.verifyOtp();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  Obx(
                    () => PrimaryButton(
                      title: "Verify",
                      loading: controller.loading.value,
                      onPressed: controller.verifyOtp,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: _secondsLeft > 0
                        ? Text(
                            "Resend OTP in ${_secondsLeft}s",
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          )
                        : TextButton(
                            onPressed: _handleResend,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: Text(
                              "Resend OTP",
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final filled = index < _text.length;
              final isActiveCursor =
                  _hasFocus && index == _text.length;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActiveCursor
                        ? AppColors.primary
                        : (filled
                            ? AppColors.primary.withOpacity(0.5)
                            : AppColors.textSecondary.withOpacity(0.25)),
                    width: isActiveCursor ? 2 : 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  filled ? _text[index] : '',
                  style: AppTextStyles.heading2.copyWith(fontSize: 22),
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