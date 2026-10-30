import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../models/scene.dart';
import '../../state/app_state.dart';
import 'opportunities_screen.dart';
import 'scene_editor_screen.dart';

/// Lista scenelor fotografice salvate. Adaugi cu butonul +, editezi atingând o
/// scenă, ștergi din meniul scenei.
class ScenesListScreen extends StatelessWidget {
  const ScenesListScreen({super.key});

  void _addScene(BuildContext context) {
    final s = context.read<AppState>().s;
    final scene = context.read<AppState>().addScene(s.newSceneName);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SceneEditorScreen(scene: scene)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.s;
    final scenes = state.scenes;

    return Scaffold(
      appBar: AppBar(title: Text(s.scenes)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addScene(context),
        child: const Icon(Icons.add),
      ),
      body: scenes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  s.scenesEmptyHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: scenes.length,
              itemBuilder: (context, i) => _SceneTile(scene: scenes[i]),
            ),
    );
  }
}

class _SceneTile extends StatelessWidget {
  final Scene scene;
  const _SceneTile({required this.scene});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    return Card(
      child: ListTile(
        title: Text(scene.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          s.sceneSummary(
            scene.azimuthMin.round(),
            scene.azimuthMax.round(),
            scene.elevationMin.round(),
            scene.elevationMax.round(),
            scene.startLabel,
            scene.endLabel,
            scene.minIllumination.round(),
          ),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        isThreeLine: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SceneEditorScreen(scene: scene)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              tooltip: s.findOpportunities,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OpportunitiesScreen(scene: scene),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final s = context.read<AppState>().s;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: Text(s.deleteSceneTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(s.deleteSceneBody(scene.name),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteScene(scene);
              Navigator.of(dialogContext).pop();
            },
            child: Text(s.delete,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
