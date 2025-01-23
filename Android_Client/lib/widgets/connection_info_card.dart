import 'package:flutter/material.dart';

class ConnectionInfoCard extends StatelessWidget {
  final String serverIP;
  final int serverPort;

  const ConnectionInfoCard({
    required this.serverIP,
    required this.serverPort,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Server IP: $serverIP',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Server Port: $serverPort',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
