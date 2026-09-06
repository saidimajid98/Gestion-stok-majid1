import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _motDePasse = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  Future<void> _seConnecter() async {
    setState(() { _chargement = true; _erreur = null; });
    final auth = context.read<AuthService>();
    final erreur = await auth.seConnecter(_email.text.trim(), _motDePasse.text);
    if (!mounted) return;
    setState(() { _chargement = false; _erreur = erreur; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Registre', style: TextStyle(fontFamily: 'serif', fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 4),
              const Text('Stock & facturation', style: TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 32),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _motDePasse, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe')),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _chargement ? null : _seConnecter,
                child: _chargement
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Se connecter'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
