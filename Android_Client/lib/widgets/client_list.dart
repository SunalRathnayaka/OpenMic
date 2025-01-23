import 'package:flutter/material.dart';
import 'dart:io';

class ClientList extends StatelessWidget {
  final List<Socket> clients;

  const ClientList({required this.clients, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Connected clients: ${clients.length}',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (clients.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Client IPs:',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          ...clients.map((client) => Text(
                client.remoteAddress.address,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              )),
        ],
      ],
    );
  }
}
