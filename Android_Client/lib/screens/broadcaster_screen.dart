import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_broadcaster_service.dart';
import '../services/permission_service.dart';
import '../widgets/connection_info_card.dart';
import '../widgets/error_banner.dart';
import '../widgets/client_list.dart';
import '../config/constants.dart';

class BroadcasterScreen extends StatefulWidget {
  const BroadcasterScreen({super.key});

  @override
  _BroadcasterScreenState createState() => _BroadcasterScreenState();
}

class _BroadcasterScreenState extends State<BroadcasterScreen>
    with WidgetsBindingObserver {
  final _broadcasterService = AudioBroadcasterService();
  final _permissionService = PermissionService();
  String _serverIP = '';
  String? _errorMessage;
  bool _isInitializing = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _broadcasterService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_broadcasterService.isStreaming) {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          _permissionService.enableBackgroundMode();
          break;
        case AppLifecycleState.resumed:
          _permissionService.disableBackgroundMode();
          break;
        default:
          break;
      }
    }
  }

  Future<void> _initialize() async {
    try {
      _hasPermission = await _permissionService.initializeWithPermissions();
      if (_hasPermission) {
        await _broadcasterService.initializeRecorder();
        await _updateNetworkInterfaces();
      } else {
        _showError('Required permissions denied');
      }
    } catch (e) {
      _showError('Error during initialization: $e');
    }
  }

  Future<void> _updateNetworkInterfaces() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      final localIP = interfaces
          .expand((interface) => interface.addresses)
          .map((addr) => addr.address)
          .firstWhere(
            (ip) => ip.startsWith('192.168.') || ip.startsWith('172.'),
            orElse: () => 'No local IP found',
          );

      setState(() {
        _serverIP = localIP;
      });
    } catch (e) {
      setState(() {
        _serverIP = 'Error finding IP';
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _startBroadcasting() async {
    if (!_hasPermission) {
      _showError('No microphone permission');
      return;
    }

    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      await _permissionService.enableBackgroundMode();
      await _broadcasterService.startBroadcasting();
    } catch (e) {
      _showError('Error starting broadcast: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _stopBroadcasting() async {
    try {
      await _permissionService.disableBackgroundMode();
      await _broadcasterService.stopBroadcasting();
    } catch (e) {
      _showError('Error stopping broadcast: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('OpenMic'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<BroadcastState>(
        stream: _broadcasterService.stateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          final isStreaming = state?.isStreaming ?? false;
          final clients = state?.clients ?? [];
          final error = state?.error;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ConnectionInfoCard(
                        serverIP: _serverIP,
                        serverPort: AudioConstants.serverPort,
                      ),
                      const SizedBox(height: 20),
                      if (error != null)
                        ErrorBanner(
                          message: error,
                          onDismiss: () => _broadcasterService,
                        ),
                      if (_isInitializing)
                        const Center(child: CircularProgressIndicator())
                      else
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _hasPermission
                                ? (isStreaming
                                    ? _stopBroadcasting
                                    : _startBroadcasting)
                                : null,
                            icon: Icon(isStreaming ? Icons.stop : Icons.mic),
                            label: Text(isStreaming
                                ? 'Stop Broadcasting'
                                : 'Start Broadcasting'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (isStreaming) ...[
                        Text(
                          'Broadcasting on port ${AudioConstants.serverPort}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ClientList(clients: clients),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateNetworkInterfaces,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh IP address',
      ),
    );
  }
}
