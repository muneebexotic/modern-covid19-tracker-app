import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:covid19_tracker_flutter/Utils/text_styles.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';
import 'package:covid19_tracker_flutter/Utils/formatters.dart';

/// The header widget shows the back button, share, favorite, flag, title and risk badge.
/// It's a pure UI widget — share is done here by calling Share.share with the provided text.
class CountryHeader extends StatelessWidget {
  final String countryName;
  final String flagUrl;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String riskLevel;
  final Color riskColor;

  const CountryHeader({
    Key? key,
    required this.countryName,
    required this.flagUrl,
    required this.onBack,
    this.onShare,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.riskLevel,
    required this.riskColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? const Color(0xff334155) : const Color(0xfff1f5f9);

    return Row(
      children: [
        // back button
        _iconContainer(
          child: Icon(Icons.arrow_back_ios_rounded, size: 18, color: isDark ? Colors.white : AppColors.darkCard),
          onTap: onBack,
          bgColor: iconBg,
        ),

        const SizedBox(width: 12),

        // flag + name
        Expanded(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 50,
                  child: flagUrl.isEmpty
                      ? Container(color: AppColors.muted.withOpacity(0.1), child: const Icon(Icons.flag_rounded))
                      : CachedNetworkImage(
                          imageUrl: flagUrl,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (ctx, url, error) => Container(
                            color: AppColors.muted.withOpacity(0.1),
                            child: const Icon(Icons.flag_rounded),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(countryName, style: AppTextStyles.heading(context, size: 20)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: riskColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        'Risk Level: $riskLevel',
                        style: TextStyle(color: riskColor, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // actions
        _iconContainer(
          child: Icon(Icons.share_rounded, size: 18, color: isDark ? Colors.white : AppColors.darkCard),
          onTap: () async {
            if (onShare != null) onShare!.call();
          },
          bgColor: iconBg,
        ),

        const SizedBox(width: 8),

        _iconContainer(
          child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18, color: isFavorite ? AppColors.danger : (isDark ? Colors.white : AppColors.darkCard)),
          onTap: onToggleFavorite,
          bgColor: isFavorite ? AppColors.danger.withOpacity(0.1) : iconBg,
        ),
      ],
    );
  }

  Widget _iconContainer({required Widget child, required VoidCallback onTap, required Color bgColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Center(child: child),
      ),
    );
  }
}
