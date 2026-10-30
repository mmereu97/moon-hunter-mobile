import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../models/opportunity.dart';
import '../../models/scene.dart';
import '../../state/app_state.dart';

/// Caută și afișează oportunitățile pentru o scenă, pe un an înainte.
/// Cât timp scanează, arată o bară de progres; apoi lista de oportunități.
class OpportunitiesScreen extends StatefulWidget {
  final Scene scene;
  const OpportunitiesScreen({super.key, required this.scene});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  double _progress = 0;
  List<Opportunity>? _results;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final results = await context.read<AppState>().findOpportunities(
          widget.scene,
          days: 365,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
    if (mounted) setState(() => _results = results);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _date(DateTime dt, S s) {
    final l = dt.toLocal();
    return '${s.weekdayAbbr(l.weekday)} ${_two(l.day)}.${_two(l.month)}.${_two(l.year % 100)}';
  }

  String _hm(DateTime dt) {
    final l = dt.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    final results = _results;

    return Scaffold(
      appBar: AppBar(title: Text(s.opportunitiesTitle(widget.scene.name))),
      body: results == null
          ? _buildProgress(s)
          : results.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      s.noOpportunities,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: results.length,
                  itemBuilder: (context, i) => _OpportunityCard(
                    s: s,
                    opp: results[i],
                    date: _date(results[i].bestMoment, s),
                    window: '${_hm(results[i].start)}–${_hm(results[i].end)}',
                    best: _hm(results[i].bestMoment),
                  ),
                ),
    );
  }

  Widget _buildProgress(S s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.scanningYear,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${(_progress * 100).round()}%',
                style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final S s;
  final Opportunity opp;
  final String date;
  final String window;
  final String best;

  const _OpportunityCard({
    required this.s,
    required this.opp,
    required this.date,
    required this.window,
    required this.best,
  });

  @override
  Widget build(BuildContext context) {
    final d = opp.distance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(s.illuminatedPct(opp.illumination.round()),
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 6),
            Text(s.windowPeakLine(window, best),
                style: const TextStyle(color: Colors.white70)),
            Text(
              s.atPeakLine(opp.bestAltitude.toStringAsFixed(0),
                  opp.bestAzimuth.toStringAsFixed(0)),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${s.distanceStatus(d.status)} (${d.rating}/10) • ${d.distanceKm.toStringAsFixed(0)} km',
              style: TextStyle(color: d.color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
