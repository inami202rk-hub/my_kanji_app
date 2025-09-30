import 'package:flutter/widgets.dart';

/// Non-web stub. Used on mobile/desktop where PWA install is not applicable.
class PwaInstallButton extends StatelessWidget {
  const PwaInstallButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Show nothing (or a tiny SizedBox) on non-web.
    return const SizedBox.shrink();
  }
}
