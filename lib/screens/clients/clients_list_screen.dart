import 'package:flutter/material.dart';
import '../../services/clients_service.dart';
import '../../models/client.dart';
import '../../widgets/empty_state.dart';
import 'client_form_screen.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _service = ClientsService();
  final _recherche = TextEditingController();
  Future<List<Client>>? _futur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() => setState(() => _futur = _service.lister(recherche: _recherche.text));

  Future<void> _ouvrirFormulaire([Client? c]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClientFormScreen(client: c)));
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton(onPressed: () => _ouvrirFormulaire(), child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _recherche,
            decoration: const InputDecoration(hintText: 'Rechercher un client…', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => _charger(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Client>>(
              future: _futur,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final clients = snap.data!;
                if (clients.isEmpty) {
                  return EmptyState(message: 'Aucun client enregistré.', actionLabel: 'Ajouter un client', onAction: () => _ouvrirFormulaire());
                }
                return ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (context, i) {
                    final c = clients[i];
                    return Card(
                      child: ListTile(
                        title: Text(c.nom),
                        subtitle: Text(c.telephone?.isNotEmpty == true ? c.telephone! : 'Pas de téléphone'),
                        onTap: () => _ouvrirFormulaire(c),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
