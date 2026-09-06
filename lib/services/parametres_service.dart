import 'supabase_service.dart';
import '../models/parametres.dart';

class ParametresService {
  final _sb = SupabaseService.client;

  Future<ParametresEntreprise> obtenir() async {
    final res = await _sb.from('parametres_entreprise').select().eq('id', 1).single();
    return ParametresEntreprise.fromMap(res);
  }

  Future<void> enregistrer(ParametresEntreprise p) async {
    await _sb.from('parametres_entreprise').update(p.toUpdateMap()).eq('id', 1);
  }
}
