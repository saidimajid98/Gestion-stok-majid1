import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../clients/clients_list_screen.dart';
import 'parametres_screen.dart';

class PlusScreen extends StatelessWidget {
  const PlusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            title: const Text('Clients'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClientsListScreen())),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Paramètres'),
            subtitle: const Text('Entreprise, devise, TVA'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParametresScreen())),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => context.read<AuthService>().seDeconnecter(),
          child: const Text('Se déconnecter'),
        ),
      ]),
    );
  }
}
