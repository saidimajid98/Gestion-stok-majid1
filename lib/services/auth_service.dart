import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  User? get currentUser => SupabaseService.client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  AuthService() {
    SupabaseService.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  Future<String?> seConnecter(String email, String motDePasse) async {
    try {
      await SupabaseService.client.auth.signInWithPassword(email: email, password: motDePasse);
      return null; // pas d'erreur
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connexion impossible. Vérifiez votre connexion internet.';
    }
  }

  Future<void> seDeconnecter() async {
    await SupabaseService.client.auth.signOut();
  }

  Future<String?> nomAffiche() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final res = await SupabaseService.client.from('profiles').select('nom').eq('id', uid).maybeSingle();
    return res?['nom'] as String?;
  }
}
