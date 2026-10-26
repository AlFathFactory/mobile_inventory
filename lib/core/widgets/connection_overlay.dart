import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Full-screen recovery state for a lost connection to live data.
class ConnectionOverlay extends StatelessWidget {
  const ConnectionOverlay({
    required this.isRetrying,
    required this.onRetry,
    super.key,
  });

  final bool isRetrying;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('connection-overlay'),
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/image/no_wifi.png',
                    key: const Key('no-wifi-image'),
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    semanticLabel: 'لا يوجد اتصال بالإنترنت',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'تعذر الاتصال',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle.copyWith(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 24,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تحقق من اتصالك بالإنترنت، ثم اضغط إعادة المحاولة لتحديث البيانات.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      color: AppColors.neutral700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('retry-connection'),
                      onPressed: isRetrying ? null : onRetry,
                      style: FilledButton.styleFrom(
                        textStyle: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      icon: isRetrying
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        isRetrying ? 'جارِ الاتصال...' : 'إعادة المحاولة',
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
