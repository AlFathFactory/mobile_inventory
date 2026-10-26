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
    return ColoredBox(
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
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.accentVerySoft,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.accent,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'تعذر الاتصال',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تحقق من اتصالك بالإنترنت، ثم اضغط إعادة المحاولة لتحديث البيانات.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('retry-connection'),
                      onPressed: isRetrying ? null : onRetry,
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
