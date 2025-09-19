// Non-web fallback for PWA install button.
import 'package:flutter/material.dart';

class PwaInstallButton extends StatefulWidget {
  final ButtonStyle? style;
  const PwaInstallButton({super.key, this.style});

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
