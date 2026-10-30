import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../state/app_state.dart';

/// Panou Time Shift colapsabil. Antetul (cu starea) e mereu vizibil; conținutul
/// cu controale se deschide la atingere. Starea desfășurat/colapsat o ține
/// AppState (implicit colapsat).
class TimeShiftWidget extends StatelessWidget {
  const TimeShiftWidget({super.key});

  String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pick(BuildContext context) async {
    final state = context.read<AppState>();
    final start = state.referenceTime;

    final date = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null) return;

    state.setTimeshift(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;
    final shifted = state.isTimeshifted;
    final dir = state.timeDirection;
    final expanded = state.timeShiftExpanded;

    final timeColor = switch (dir) {
      TimeDirection.real => Colors.white,
      TimeDirection.past => AppColors.past,
      TimeDirection.future => AppColors.future,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Antet — atinge pentru a deschide/închide.
            InkWell(
              onTap: () => context.read<AppState>().toggleTimeShift(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(s.timeShift,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    // Când e colapsat și simulat, arătăm momentul în antet.
                    if (shifted && !expanded)
                      Expanded(
                        child: Text(
                          _fmt(state.referenceTime),
                          style: TextStyle(color: timeColor, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    _StatusChip(
                      dir: dir,
                      label: switch (dir) {
                        TimeDirection.real => s.timeReal,
                        TimeDirection.past => s.timePast,
                        TimeDirection.future => s.timeFuture,
                      },
                    ),
                    const SizedBox(width: 4),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54),
                  ],
                ),
              ),
            ),

            // Conținut (doar când e desfășurat).
            if (expanded) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _fmt(state.referenceTime),
                  style: TextStyle(fontSize: 18, color: timeColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StepGroup(
                    label: s.day,
                    onMinus: () => context
                        .read<AppState>()
                        .shiftBy(const Duration(days: -1)),
                    onPlus: () => context
                        .read<AppState>()
                        .shiftBy(const Duration(days: 1)),
                  ),
                  _StepGroup(
                    label: s.hour,
                    onMinus: () => context
                        .read<AppState>()
                        .shiftBy(const Duration(hours: -1)),
                    onPlus: () => context
                        .read<AppState>()
                        .shiftBy(const Duration(hours: 1)),
                  ),
                  _StepGroup(
                    label: s.min,
                    onMinus: () => context
                        .read<AppState>()
                        .shiftBy(const Duration(minutes: -10)),
                    onPlus: () => context
                        .read<AppState>()
                        .shiftBy(const Duration(minutes: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(s.pickDateTime),
                      onPressed: () => _pick(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restore, size: 18),
                      label: Text(s.now),
                      onPressed: shifted
                          ? () => context.read<AppState>().resetTime()
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TimeDirection dir;
  final String label;
  const _StatusChip({required this.dir, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = switch (dir) {
      TimeDirection.real => Colors.greenAccent,
      TimeDirection.past => AppColors.past,
      TimeDirection.future => AppColors.future,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StepGroup extends StatelessWidget {
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StepGroup({
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundBtn(icon: Icons.remove, onTap: onMinus),
            const SizedBox(width: 6),
            _RoundBtn(icon: Icons.add, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
