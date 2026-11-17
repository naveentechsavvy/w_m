import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/colors.dart';
import '../models/user_coupon_model.dart';

/// Ticket-style card for one coupon. Used on My Coupons and in the
/// cart's "Apply coupon" sheet.
class CouponCard extends StatelessWidget {
  final UserCoupon coupon;

  /// When set, shows an "Apply" button instead of "Copy".
  final VoidCallback? onApply;

  const CouponCard({super.key, required this.coupon, this.onApply});

  String? get _statusLabel {
    if (coupon.isUsed) return 'Used';
    if (coupon.isExpired) return 'Expired';
    if (coupon.isNotStartedYet) return 'Not started';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final usable = coupon.isUsableNow;
    final status = _statusLabel;
    final dateFormat = DateFormat('d MMM yyyy');

    final details = <String>[
      if (coupon.minOrder > 0)
        'Min order ₹${coupon.minOrder.toStringAsFixed(0)}',
      if (coupon.discountType == 'percent' && coupon.maxDiscount != null)
        'Up to ₹${coupon.maxDiscount!.toStringAsFixed(0)}',
      if (coupon.validTo != null)
        'Valid till ${dateFormat.format(coupon.validTo!)}',
      if (usable && coupon.usesLeft > 1) '${coupon.usesLeft} uses left',
    ];

    return Opacity(
      opacity: usable ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left value strip
              Container(
                width: 92,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: usable ? AppColors.primary : AppColors.textLight,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  coupon.valueLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                coupon.code,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                          if (status != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              status,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (coupon.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          coupon.description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          details.join('  •  '),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (usable) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: onApply != null
                              ? TextButton(
                                  onPressed: onApply,
                                  child: const Text('Apply'),
                                )
                              : TextButton.icon(
                                  onPressed: () => _copy(coupon.code),
                                  icon: const Icon(Icons.copy_rounded,
                                      size: 16),
                                  label: const Text('Copy code'),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    Get.snackbar(
      'Copied',
      'Coupon code $code copied.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }
}
