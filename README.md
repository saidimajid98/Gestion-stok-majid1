# Gestion de stock — application Flutter + Supabase

## Mise en route

1. **Créer le projet Supabase**
   - Créez un projet sur https://supabase.com
   - Ouvrez l'éditeur SQL et exécutez le contenu de `../supabase/schema.sql`
   - Récupérez l'URL du projet et la clé "anon public" (Project Settings > API)

2. **Configurer l'application**
   Éditez `lib/config.dart` et renseignez :
   ```dart
   const supabaseUrl = 'https://VOTRE-PROJET.supabase.co';
   const supabaseAnonKey = 'VOTRE-CLE-ANON';
   ```

3. **Créer le premier utilisateur admin**
   - Dans Supabase > Authentication, créez un utilisateur (email/mot de passe)
   - Dans la table `profiles`, insérez une ligne avec son `id`, un `nom`, et `role = 'admin'`

4. **Installer et lancer**
   ```bash
   flutter pub get
   flutter run
   ```

## Structure

- `lib/models/` — classes de données (Produit, Client, Facture, BonLivraison, BonSortie…)
- `lib/services/` — accès Supabase (CRUD) et génération PDF
- `lib/screens/` — écrans de l'application, organisés par module
- `lib/widgets/` — composants réutilisables (éditeur de lignes, cartes, etc.)

## Notes

- Le stock est suivi par entrepôt (table `stocks`). L'application utilise
  par défaut l'entrepôt "Entrepôt principal" créé automatiquement par le
  script SQL ; la sélection multi-entrepôt peut être ajoutée en étendant
  `StockService` et les écrans de formulaire.
- Les mouvements de stock (entrées/sorties/livraisons/corrections) sont
  journalisés automatiquement côté base (`mouvements_stock`) par des
  triggers PostgreSQL — vous n'avez rien à faire côté Flutter.
- Les PDF (facture, bon de livraison, bon de sortie) sont générés
  localement avec les packages `pdf` et `printing` (aperçu, impression,
  partage/enregistrement).
