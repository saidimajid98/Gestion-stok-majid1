import 'supabase_service.dart';
import '../models/client.dart';

class ClientsService {
  final _sb = SupabaseService.client;

  Future<List<Client>> lister({String? recherche}) async {
    var query = _sb.from('clients').select();
    if (recherche != null && recherche.trim().isNotEmpty) {
      query = query.ilike('nom', '%${recherche.trim()}%');
    }
    final res = await query.order('nom');
    return (res as List).map((m) => Client.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<void> creer(Client c) async => _sb.from('clients').insert(c.toInsertMap());
  Future<void> modifier(String id, Client c) async => _sb.from('clients').update(c.toInsertMap()).eq('id', id);
  Future<void> supprimer(String id) async => _sb.from('clients').delete().eq('id', id);
}
