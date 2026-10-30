import 'package:flutter/material.dart';
import '../../models/moon_info.dart';

/// Afișează imaginea Lunii corespunzătoare fazei curente
/// (assets/moon/luna_N.png).
///
/// Are un fallback: dacă fișierul lipsește din orice motiv, în loc de un gol
/// (bug-ul din versiunea Python) se afișează un placeholder cu indexul cerut.
/// Astfel problema devine vizibilă și ușor de depanat, nu silențioasă.
class MoonImage extends StatelessWidget {
  final MoonPhase phase;
  final double size;

  const MoonImage({super.key, required this.phase, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      phase.imageAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Lipsește\nluna_${phase.imageIndex}.png',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
