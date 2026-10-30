import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../models/moon_info.dart';
import '../../state/app_state.dart';

/// Ecran "Rating luni pline": următoarele 12 luni pline, cu data, statusul
/// (perigeu/apogeu/intermediar), rating-ul și distanța — colorate după rating.
/// Util pentru a planifica fotografierea unui "supermoon".
class FullMoonRatingsScreen extends StatefulWidget {
  const FullMoonRatingsScreen({super.key});

  @override
  State<FullMoonRatingsScreen> createState() => _FullMoonRatingsScreenState();
}

class _FullMoonRatingsScreenState extends State<FullMoonRatingsScreen> {
  List<FullMoonRating>? _ratings;

  @override
  void initState() {
    super.initState();
    // Calculul (scanare în timp) se face o singură dată, la deschidere.
    // Îl amânăm un cadru ca să apuce să apară ecranul.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ratings = context.read<AppState>().fullMoonRatings(count: 12);
      if (mounted) setState(() => _ratings = ratings);
    });
  }

  String _date(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${two(dt.year % 100)}';
  }

  /// Distanța în km cu punct ca separator de mii: 356738 -> "356.738".
  String _km(double km) {
    final s = km.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    final ratings = _ratings;

    return Scaffold(
      appBar: AppBar(title: Text(s.fullMoonRatings)),
      body: ratings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ratings.length,
              itemBuilder: (context, i) {
                final r = ratings[i];
                final d = r.distance;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            _date(r.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${s.distanceStatus(d.status)} (${d.rating}/10) • ${_km(d.distanceKm)} km',
                            style: TextStyle(
                              color: d.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
