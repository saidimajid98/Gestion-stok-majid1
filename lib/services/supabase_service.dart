import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

// Point d'accès unique au client Supabase. Appelez `SupabaseService.init()`
// une seule fois au démarrage de l'application (voir main.dart).
class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  // id de l'entrepôt utilisé par défaut par l'application (MVP mono-entrepôt).
  static Future<String> entrepotParDefautId() async {
    final res = await client.from('entrepots').select('id').order('created_at').limit(1).single();
    return res['id'] as String;
  }
}
