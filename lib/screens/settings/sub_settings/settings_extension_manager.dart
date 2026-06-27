import 'dart:io';

import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/screens/extensions/widgets/plugin_manager.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex_extension_runtime_bridge/AnymeXBridge.dart';
import 'package:anymex_extension_runtime_bridge/ExtensionManager.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsExtensionManager extends StatefulWidget {
  const SettingsExtensionManager({super.key});

  @override
  State<SettingsExtensionManager> createState() =>
      _SettingsExtensionManagerState();
}

class _SettingsExtensionManagerState extends State<SettingsExtensionManager> {
  final _pluginManager = PluginManager();
  bool _isCheckingUpdate = false;

  // ---- iOS remote-bridge state ----
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isConnecting = false;
  String _connectStatus = '';
  bool _remoteConnected = false;
  DateTime? _lastConnectedAt;
  bool _iosInitialized = false;

  String get _installedVersion => AnymeXRuntimeBridge.installedVersion;
  String get _installedReleaseTitle => AnymeXRuntimeBridge.installedReleaseTitle;
  bool get _isPluginInstalled => AnymeXRuntimeBridge.isPluginInstalled;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _initIosRemoteBridge();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _initIosRemoteBridge() async {
    final settings = await RemoteBridgeSettings.load();
    _hostController.text = settings.host;
    _portController.text = settings.port.toString();
    _usernameController.text = settings.username;
    final hasKey = await settings.hasSavedKey;

    if (!mounted) return;
    setState(() {
      _iosInitialized = true;
      _lastConnectedAt = settings.lastConnectedAt;
    });

    // If ExtensionManager is already registered and connected (auto-connected
    // at app startup), reflect that.
    if (Get.isRegistered<ExtensionManager>()) {
      final mgr = Get.find<ExtensionManager>();
      if (mgr.isRemoteBridgeConnected) {
        if (!mounted) return;
        setState(() => _remoteConnected = true);
      }
    } else if (!hasKey) {
      // No key yet — leave disconnected, user taps Connect to generate one.
      return;
    }
  }

  void _showInstallPopup() async {
    await _pluginManager.showInstallSheet(context);
    if (mounted) setState(() {});
  }

  void _showUpdatePopup() async {
    final release = await _pluginManager.fetchLatestRelease();
    if (!mounted) return;
    if (release == null) {
      errorSnackBar('Failed to check for updates.');
      return;
    }
    final currentVersion = _installedVersion;
    if (currentVersion.isEmpty) {
      _showInstallPopup();
      return;
    }
    if (_pluginManager.isNewerVersion(currentVersion, release.tagName)) {
      await _pluginManager.showUpdateSheet(
        context,
        release: release,
        installedVersion: currentVersion,
      );
      if (mounted) setState(() {});
    } else {
      successSnackBar('Plugin is already up to date.');
    }
  }

  void _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final release = await _pluginManager.fetchLatestRelease();
      if (!mounted) return;
      if (release == null) {
        errorSnackBar('Failed to check for updates.');
        return;
      }
      final currentVersion = _installedVersion;
      if (currentVersion.isEmpty) {
        _showInstallPopup();
        return;
      }
      if (_pluginManager.isNewerVersion(currentVersion, release.tagName)) {
        _showUpdatePopup();
      } else {
        successSnackBar('Plugin is already up to date.');
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  void _forceReDownload() async {
    final bridge = AnymeXRuntimeBridge.controller;
    if (bridge.isDownloading.value) return;
    try {
      await AnymeXRuntimeBridge.setupRuntime(force: true);
      if (bridge.isReady.value) {
        await Get.find<ExtensionManager>()
            .onRuntimeBridgeInitialization(force: true);
        if (mounted) {
          setState(() {});
          successSnackBar('Plugin re-downloaded successfully.');
        }
      }
    } catch (error) {
      if (mounted) errorSnackBar('Re-download failed: $error');
    }
  }

  /// iOS: connect to the remote bridge using the host/port/username fields.
  /// Generates a fresh ed25519 keypair on first connect (or reuses the
  /// saved one if the user is just reconnecting with different host/port).
  Future<void> _connectRemoteBridge() async {
    if (_isConnecting) return;

    final host = _hostController.text.trim();
    final portStr = _portController.text.trim();
    final username = _usernameController.text.trim();

    if (host.isEmpty) {
      errorSnackBar('Host is required');
      return;
    }
    final port = int.tryParse(portStr);
    if (port == null || port < 1 || port > 65535) {
      errorSnackBar('Port must be between 1 and 65535');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectStatus = 'Starting…';
    });

    try {
      // Load existing settings to reuse the saved key if present.
      final existing = await RemoteBridgeSettings.load();
      String? privateKeyPem = existing.privateKeyPem;
      if (privateKeyPem == null || privateKeyPem.isEmpty) {
        setState(() => _connectStatus = 'Generating SSH keypair…');
        privateKeyPem = await RemoteBridgeKeyGenerator.generatePrivateKeyPem();
      }

      final mgr = Get.isRegistered<ExtensionManager>()
          ? Get.find<ExtensionManager>()
          : null;

      if (mgr == null) {
        throw StateError('ExtensionManager not registered yet');
      }

      await mgr.connectRemoteBridge(
        host,
        port,
        username: username,
        privateKeyPem: privateKeyPem,
        onProgress: (status) {
          if (mounted) setState(() => _connectStatus = status);
        },
      );

      if (!mounted) return;
      setState(() {
        _remoteConnected = true;
        _lastConnectedAt = DateTime.now();
      });
      successSnackBar('Connected to $host:$port');
    } catch (e) {
      if (mounted) {
        setState(() => _remoteConnected = false);
        errorSnackBar('Connection failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectStatus = '';
        });
      }
    }
  }

  /// iOS: disconnect and forget the saved key.
  Future<void> _disconnectRemoteBridge() async {
    try {
      if (Get.isRegistered<ExtensionManager>()) {
        await Get.find<ExtensionManager>().disconnectRemoteBridge();
      }
      if (!mounted) return;
      setState(() {
        _remoteConnected = false;
        _lastConnectedAt = null;
      });
      successSnackBar('Disconnected from remote bridge');
    } catch (e) {
      if (mounted) errorSnackBar('Disconnect failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Extension Manager'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: getResponsiveValue(context,
                      mobileValue:
                          const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
                      desktopValue:
                          const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexExpansionTile(
                        initialExpanded: true,
                        title: Platform.isIOS
                            ? 'Remote Bridge'
                            : 'Plugin Status',
                        content: Column(
                          children: [
                            if (Platform.isIOS)
                              _buildRemoteBridgeCard(context)
                            else
                              _buildPluginStatusCard(context),
                            const SizedBox(height: 10),
                            if (Platform.isIOS)
                              _buildRemoteBridgeActions(context)
                            else
                              _buildPluginActions(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // iOS: Remote Bridge card
  // ====================================================================

  Widget _buildRemoteBridgeCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _remoteConnected
                      ? colors.primaryContainer
                      : (_isConnecting
                          ? colors.tertiaryContainer
                          : colors.errorContainer),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isConnecting
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.onTertiaryContainer,
                        ),
                      )
                    : Icon(
                        _remoteConnected
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        size: 22,
                        color: _remoteConnected
                            ? colors.onPrimaryContainer
                            : colors.onErrorContainer,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnecting
                          ? 'Connecting…'
                          : _remoteConnected
                              ? 'Connected'
                              : 'Not Connected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isConnecting
                          ? _connectStatus
                          : _remoteConnected
                              ? 'Aniyomi & CloudStream ready via remote bridge'
                              : 'Connect to enable Aniyomi & CloudStream on iOS',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isConnecting && _connectStatus.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                backgroundColor: colors.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
          if (_remoteConnected && _lastConnectedAt != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _buildMetaRow(
              colors,
              'Connected since',
              _formatDateTime(_lastConnectedAt!),
            ),
            const SizedBox(height: 8),
            _buildMetaRow(
              colors,
              'Bridge Mode',
              'remote',
            ),
            const SizedBox(height: 8),
            _buildMetaRow(
              colors,
              'Local engine',
              'Sora + Mangayomi (on-device)',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemoteBridgeActions(BuildContext context) {
    final colors = context.colors;
    if (_isConnecting) {
      return const SizedBox.shrink();
    }

    if (!_iosInitialized) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        // Host field
        _buildTextField(
          context,
          controller: _hostController,
          label: 'Host',
          hint: 'anymex.duckdns.org',
          icon: Icons.dns_rounded,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 10),
        // Port + Username row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                context,
                controller: _portController,
                label: 'Port',
                hint: '3022',
                icon: Icons.numbers_rounded,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: _buildTextField(
                context,
                controller: _usernameController,
                label: 'Username',
                hint: 'anymex',
                icon: Icons.person_rounded,
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Connect / Disconnect button
        if (!_remoteConnected)
          CustomTile(
            icon: Icons.cloud_upload_rounded,
            title: 'Connect',
            description:
                'Generate SSH keypair and connect to the remote bridge',
            onTap: _connectRemoteBridge,
          )
        else ...[
          CustomTile(
            icon: Icons.cloud_off_rounded,
            title: 'Disconnect',
            description: 'Disconnect and forget the saved SSH key',
            onTap: _disconnectRemoteBridge,
          ),
          const SizedBox(height: 8),
          CustomTile(
            icon: Icons.refresh_rounded,
            title: 'Reconnect',
            description: 'Reconnect using the current host/port',
            onTap: _connectRemoteBridge,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
        hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: TextStyle(fontSize: 14, color: colors.onSurface),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)} · '
        '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  // ====================================================================
  // Android / Desktop: original Plugin Status card (unchanged)
  // ====================================================================

  Widget _buildPluginStatusCard(BuildContext context) {
    final colors = context.colors;
    final bridge = AnymeXRuntimeBridge.controller;
    return Obx(() {
      final isDownloading = bridge.isDownloading.value;
      final progress = bridge.downloadProgress.value;
      final status = bridge.status.value;
      final isReady = bridge.isReady.value;
      final sizeInfo = bridge.sizeInfo.value;
      final hasError = bridge.error.value.isNotEmpty;
      final isBusy = isDownloading ||
          (status != "Idle" &&
              !isReady &&
              (status.contains("Extracting") ||
                  status.contains("Finalizing")));

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surfaceContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isBusy
                        ? colors.tertiaryContainer
                        : _isPluginInstalled
                            ? colors.primaryContainer
                            : colors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isBusy
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colors.onTertiaryContainer,
                          ),
                        )
                      : Icon(
                          _isPluginInstalled
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          size: 22,
                          color: _isPluginInstalled
                              ? colors.onPrimaryContainer
                              : colors.onErrorContainer,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBusy
                            ? 'Downloading Plugin...'
                            : _isPluginInstalled
                                ? 'Plugin Installed'
                                : 'Plugin Not Installed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isBusy
                            ? status
                            : _isPluginInstalled
                                ? 'Aniyomi & Cloudstream ready'
                                : 'Download plugin to unlock Aniyomi & Cloudstream',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isBusy) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progress > 0 ? progress : null,
                        backgroundColor: colors.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                  ),
                  if (sizeInfo.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      sizeInfo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (hasError) ...[
              const SizedBox(height: 12),
              Text(
                bridge.error.value,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.error,
                ),
              ),
            ],
            if (_isPluginInstalled && !isBusy) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildMetaRow(colors, 'Version', _installedVersion),
              const SizedBox(height: 8),
              _buildMetaRow(
                  colors,
                  'Release',
                  _installedReleaseTitle.isNotEmpty
                      ? _installedReleaseTitle
                      : 'Unknown'),
              const SizedBox(height: 8),
              _buildMetaRow(
                colors,
                'Bridge Mode',
                PluginKeys.bridgeMode.get<String>('sidecar'),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMetaRow(ColorScheme colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.onSurfaceVariant,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPluginActions(BuildContext context) {
    final colors = context.colors;
    final bridge = AnymeXRuntimeBridge.controller;
    return Obx(() {
      final isBusy = bridge.isDownloading.value ||
          (bridge.status.value != "Idle" && !bridge.isReady.value);
      if (isBusy) return const SizedBox.shrink();
      if (!_isPluginInstalled) {
        return CustomTile(
          icon: Icons.download_rounded,
          title: 'Download Plugin',
          description: 'Install the runtime plugin to enable Aniyomi & Cloudstream',
          onTap: _showInstallPopup,
        );
      }
      return Column(
        children: [
          CustomTile(
            icon: Icons.system_update_alt_rounded,
            title: 'Check for Updates',
            description: 'Check if a newer plugin version is available',
            onTap: _isCheckingUpdate ? null : _checkForUpdates,
            postFix: _isCheckingUpdate
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          CustomTile(
            icon: Icons.refresh_rounded,
            title: 'Force Re-download',
            description: 'Re-download and reinstall the plugin from scratch',
            onTap: _forceReDownload,
          ),
        ],
      );
    });
  }
}
