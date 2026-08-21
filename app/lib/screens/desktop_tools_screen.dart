import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:droiddesk/services/platform_bridge.dart';
import 'package:droiddesk/state/app_state.dart';
import 'package:droiddesk/theme/droid_theme.dart';

class DesktopToolsScreen extends StatefulWidget {
  const DesktopToolsScreen({super.key});

  @override
  State<DesktopToolsScreen> createState() => _DesktopToolsScreenState();
}

class _DesktopToolsScreenState extends State<DesktopToolsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _dockSearchController = TextEditingController();
  List<Map<String, dynamic>> _androidApps = const [];
  List<String> _dockPackages = const [];
  List<Map<String, dynamic>> _snapshots = const [];
  bool _dockBusy = true;
  bool _snapshotBusy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadDock();
    _loadSnapshots();
  }

  @override
  void dispose() {
    _dockSearchController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadDock() async {
    final values = await Future.wait([
      DroidDeskPlatform.getAndroidApps(),
      DroidDeskPlatform.getDockPackages(),
    ]);
    if (!mounted) return;
    setState(() {
      _androidApps = values[0] as List<Map<String, dynamic>>;
      _dockPackages = values[1] as List<String>;
      _dockBusy = false;
    });
  }

  Future<void> _saveDock(List<String> packages) async {
    setState(() {
      _dockPackages = packages;
      _dockBusy = true;
    });
    final saved = await DroidDeskPlatform.saveDockPackages(packages);
    if (!mounted) return;
    setState(() => _dockBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Dock updated' : 'Could not update dock')),
    );
  }

  Future<void> _loadSnapshots() async {
    final snapshots = await DroidDeskPlatform.listDesktopSnapshots();
    if (mounted) setState(() => _snapshots = snapshots);
  }

  Future<void> _createSnapshot() async {
    setState(() => _snapshotBusy = true);
    try {
      await DroidDeskPlatform.createDesktopSnapshot();
      await _loadSnapshots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desktop snapshot created')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Snapshot failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _snapshotBusy = false);
    }
  }

  Future<void> _restoreSnapshot(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this snapshot?'),
        content: const Text(
          'The Linux session will stop. Current home files and settings will be replaced, and missing packages will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _snapshotBusy = true);
    try {
      final restored = await DroidDeskPlatform.restoreDesktopSnapshot(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restored ? 'Snapshot restored' : 'Restore failed'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _snapshotBusy = false);
    }
  }

  Future<void> _deleteSnapshot(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete snapshot?'),
        content: Text(name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DroidDeskPlatform.deleteDesktopSnapshot(name);
      await _loadSnapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desktop Tools'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dock_rounded), text: 'Dock'),
            Tab(icon: Icon(Icons.restore_rounded), text: 'Backups'),
            Tab(icon: Icon(Icons.terminal_rounded), text: 'Termux Integration'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: DroidTheme.backgroundGradient,
        ),
        child: TabBarView(
          controller: _tabs,
          children: [_dockTab(), _backupsTab(), _termuxTab(context)],
        ),
      ),
    );
  }

  Widget _dockTab() {
    if (_dockBusy && _androidApps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final byPackage = {
      for (final app in _androidApps) app['package'].toString(): app,
    };
    final query = _dockSearchController.text.trim().toLowerCase();
    final available = _androidApps
        .where((app) {
          if (_dockPackages.contains(app['package'])) return false;
          return query.isEmpty ||
              app['label'].toString().toLowerCase().contains(query) ||
              app['package'].toString().toLowerCase().contains(query);
        })
        .take(30)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('PINNED', style: DroidTheme.label),
            const Spacer(),
            if (_dockBusy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const SizedBox(width: 8),
            Text('${_dockPackages.length}/8', style: DroidTheme.bodySm),
          ],
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _dockPackages.length,
          onReorderItem: (oldIndex, newIndex) {
            final next = [..._dockPackages];
            final value = next.removeAt(oldIndex);
            next.insert(newIndex, value);
            _saveDock(next);
          },
          itemBuilder: (context, index) {
            final package = _dockPackages[index];
            final app = byPackage[package];
            return Card(
              key: ValueKey(package),
              child: ListTile(
                leading: const Icon(Icons.drag_handle_rounded),
                title: Text(app?['label']?.toString() ?? package),
                subtitle: Text(package),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _dockBusy
                      ? null
                      : () => _saveDock([..._dockPackages]..remove(package)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text('ADD AN ANDROID APP', style: DroidTheme.label),
        const SizedBox(height: 8),
        TextField(
          controller: _dockSearchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search installed apps',
          ),
        ),
        const SizedBox(height: 8),
        ...available.map(
          (app) => ListTile(
            title: Text(app['label'].toString()),
            subtitle: Text(app['package'].toString()),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: _dockBusy || _dockPackages.length >= 8
                  ? null
                  : () => _saveDock([
                      ..._dockPackages,
                      app['package'].toString(),
                    ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _backupsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _snapshotBusy ? null : _createSnapshot,
          icon: _snapshotBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
          label: const Text('Create desktop snapshot'),
        ),
        const SizedBox(height: 12),
        Text(
          'Backs up your Linux home, desktop settings, wallpaper and installed-package manifest.',
          style: DroidTheme.bodySm,
        ),
        const SizedBox(height: 20),
        Text('SNAPSHOTS', style: DroidTheme.label),
        const SizedBox(height: 8),
        if (_snapshots.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No snapshots yet')),
            ),
          ),
        ..._snapshots.map((snapshot) {
          final created = DateTime.fromMillisecondsSinceEpoch(
            (snapshot['created'] as num).toInt(),
          );
          return Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(snapshot['name'].toString()),
              subtitle: Text(
                '${created.toLocal()} · ${_formatBytes((snapshot['sizeBytes'] as num).toInt())}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => value == 'restore'
                    ? _restoreSnapshot(snapshot['name'].toString())
                    : _deleteSnapshot(snapshot['name'].toString()),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'restore', child: Text('Restore')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  Widget _termuxTab(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link_rounded, color: DroidTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Direct Termux Link (0 MB Extra Storage)',
                      style: DroidTheme.headingSm,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.isDirectTermuxAvailable
                      ? 'Termux installation detected directly at /data/data/com.termux/files.'
                      : 'Requires sharedUserId="com.termux" and matching APK signature.',
                  style: DroidTheme.bodySm,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: state.isDirectTermuxAvailable
                      ? () => state.useDirectTermuxPrefix(enable: !state.isDirectTermux)
                      : null,
                  icon: Icon(state.isDirectTermux ? Icons.check_circle : Icons.link),
                  label: Text(
                    state.isDirectTermux
                        ? 'Active: Direct Termux Prefix Enabled'
                        : 'Enable Direct Termux Link',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.unarchive_rounded, color: DroidTheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Import Termux Backup Archive',
                      style: DroidTheme.headingSm,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Import your packages, dotfiles, and home directory from an exported backup tarball.\n\n'
                  'ℹ️ Note: This is a COPY operation (non-destructive). Your original Termux app remains intact. '
                  'Once imported and verified, you may delete or clear original Termux data to reclaim storage.',
                  style: DroidTheme.bodySm,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showTermuxImportDialogInTools(context, state),
                  icon: const Icon(Icons.folder_zip_rounded),
                  label: const Text('Import Backup Tarball (.tar.gz)'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTermuxImportDialogInTools(BuildContext context, AppState state) {
    final controller = TextEditingController(text: '/sdcard/Download/termux-backup.tar.gz');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.unarchive_rounded, color: DroidTheme.primary),
            SizedBox(width: 8),
            Text('Import Termux Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the file path of your exported Termux backup archive (created via export-termux-for-droiddesk.sh):',
              style: DroidTheme.bodySm,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Backup Archive Path',
                hintText: '/sdcard/Download/termux-backup.tar.gz',
                prefixIcon: Icon(Icons.folder_zip_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DroidTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DroidTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: DroidTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a COPY operation. Your original Termux app and files will remain safe and intact.',
                      style: DroidTheme.monoSm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.file_download_rounded, size: 18),
            label: const Text('Start Import'),
            onPressed: () async {
              Navigator.pop(ctx);
              final path = controller.text.trim();
              if (path.isEmpty) return;

              final success = await state.importTermuxBackup(path);
              if (context.mounted) {
                if (success) {
                  showDialog(
                    context: context,
                    builder: (alertCtx) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Import Successful!'),
                        ],
                      ),
                      content: const Text(
                        'Your Termux environment has been copied into DroidDesk.\n\n'
                        'ℹ️ Note: Original Termux files were NOT deleted.\n\n'
                        '💡 Recommendation: You can launch and test your desktop installation now. '
                        'Once you verify everything works as expected, you may safely uninstall or clear data from the original Termux app to reclaim storage space.',
                        style: DroidTheme.bodyMd,
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(alertCtx),
                          child: const Text('Got it!'),
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to import backup. Please check file path.')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
