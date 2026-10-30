import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

/// Dialogul „Despre" (i), în stilul cardului din Turist Pro: iconiță sus,
/// nume, subtitlu, o căsuță cu autorul și contactul, buton „Închide".
Future<void> showAppInfo(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _AppInfoDialog(),
  );
}

class _AppInfoDialog extends StatelessWidget {
  const _AppInfoDialog();

  static const _sepia = Color(0xFFC8A26C);
  static const _grey = Color(0xFF8E8E96);
  static const _purple = Color(0xFFA78BDA);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return Dialog(
      backgroundColor: const Color(0xFF2C2C30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MoonBadge(size: 76),
            const SizedBox(height: 16),
            const Text(
              'Moon Hunter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.appSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Căsuța cu autor și contact.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF37373D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLabel(s.author),
                  const SizedBox(height: 2),
                  const Text('Mereu Mihai',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 14),
                  _InfoLabel(s.contact),
                  const SizedBox(height: 2),
                  const SelectableText(
                    'mihaimereu97@gmail.com',
                    style: TextStyle(color: Color(0xFF64B5F6), fontSize: 16),
                  ),
                ],
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  s.close,
                  style: const TextStyle(
                    color: Color(0xFF64B5F6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String text;
  const _InfoLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white38, fontSize: 13),
    );
  }
}

/// Iconița aplicației desenată din widget-uri: 3 benzi (sepia/gri/mov) cu o
/// lună cremoasă în centru. Aceeași identitate ca iconița de lansare.
class _MoonBadge extends StatelessWidget {
  final double size;
  const _MoonBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: const [
                Expanded(
                    child: ColoredBox(
                        color: _AppInfoDialog._sepia,
                        child: SizedBox(width: double.infinity))),
                Expanded(
                    child: ColoredBox(
                        color: _AppInfoDialog._grey,
                        child: SizedBox(width: double.infinity))),
                Expanded(
                    child: ColoredBox(
                        color: _AppInfoDialog._purple,
                        child: SizedBox(width: double.infinity))),
              ],
            ),
            Container(
              width: size * 0.56,
              height: size * 0.56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8F4E6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(120),
                    blurRadius: size * 0.12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
