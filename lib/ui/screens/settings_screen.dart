import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../state/app_state.dart';
import 'compass_settings_screen.dart';

/// Ecranul de setări: limba interfeței, notificările și accesul la reglajul
/// busolei.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Limbă.
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white70),
            title: Text(s.languageLabel,
                style: const TextStyle(color: Colors.white)),
            trailing: DropdownButton<AppLang>(
              value: state.lang,
              dropdownColor: const Color(0xFF333333),
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: AppLang.ro, child: Text('RO')),
                DropdownMenuItem(value: AppLang.en, child: Text('EN')),
              ],
              onChanged: (v) {
                if (v != null) context.read<AppState>().setLang(v);
              },
            ),
          ),
          const Divider(color: Colors.white12),

          // Notificări.
          SwitchListTile(
            secondary:
                const Icon(Icons.notifications_active, color: Colors.white70),
            title: Text(s.notifications,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(s.notificationsHelp,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            value: state.notificationsEnabled,
            onChanged: (v) =>
                context.read<AppState>().setNotificationsEnabled(v),
          ),
          const Divider(color: Colors.white12),

          // Reglaj busolă.
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.white70),
            title: Text(s.compassTuning,
                style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompassSettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
