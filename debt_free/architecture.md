# DebtFree — Architecture & État du Projet

## 1. Objectif & Stack Technique
Application personnelle de suivi et de planification budgétaire multi-comptes (RBC Chèques, RBC Visa, et bientôt Wealthsimple) fonctionnant nativement sur **Windows Desktop** et **Android**.
- **Framework :** Flutter / Dart (zéro React/JS)
- **Base de données locale :** SQLite (`sqflite` + `sqflite_common_ffi` sur Windows)
- **Synchronisation :** Encapsulée via interface (`LocalOnlySync` actuellement, `GoogleDriveSync` prévu)

---

## 2. Règles d'Architecture Strictes
1. **Clean Layered Architecture :** Aucune dépendance circulaire ; la couche `domain` ne dépend d'aucun package externe ni de Flutter.
2. **Encapsulation totale des données brutes :** Les fichiers CSV ou futurs appels API sont immédiatement convertis en entités immuables (`Transaction`) dans `data/sources/`. L'UI ne manipule jamais de données brutes ni de requêtes SQL.
3. **Intégrité SQLite pour la synchronisation :** `PRAGMA journal_mode = DELETE;` est forcé à l'ouverture pour garantir que toute la base reste dans un seul fichier `.sqlite`.

---

## 3. Arborescence des Fichiers (`lib/`)

```text
lib/
├── core/
│   ├── database/
│   │   └── app_database.dart               # SQLite v3 (tables: transactions, categories, category_rules)
│   └── sync/
│       ├── cloud_sync_provider.dart        # Interface abstraite de synchronisation
│       └── local_only_sync.dart            # Implémentation locale actuelle (no-op)
│
├── domain/
│   ├── entities/
│   │   ├── account_type.dart               # Enum: rbcChequing, rbcVisa, wealthsimpleCash, unknown
│   │   ├── transaction_type.dart           # Enum: expense, income, transfer
│   │   └── transaction.dart                # Entité immuable Transaction
│   └── repositories/
│       └── transaction_repository.dart     # Contrat unique utilisé par l'UI
│
├── data/
│   ├── sources/
│   │   ├── transaction_source.dart         # Interface abstraite d'importation
│   │   └── rbc_csv_source.dart             # Parseur CSV RBC (Chèques & Visa), hash SHA-256, détection Transfers
│   └── repositories/
│       └── sqlite_transaction_repository.dart # Implémentation SQLite + moteur de règles auto
│
├── presentation/
│   ├── pages/
│   │   ├── left_menu.dart                  # NavigationRail principal (Dashboard, All Transactions, Categories)
│   │   ├── dashboard_page.dart             # Page d'accueil : dépenses totales & répartition par catégorie
│   │   ├── expenses_page.dart              # Page "All Transactions" : vue mensuelle 2 colonnes + Bulk Edit
│   │   └── categories_page.dart            # Gestion des catégories et des règles apprises par commerçant
│   └── widgets/
│       ├── global_summary_card.dart        # Bandeau global avec tiroir dépliable ("Show more / Show less")
│       └── monthly_cashflow_section.dart   # Bloc mensuel : Expenses (gauche), Income (droite), Transfers (bleu)
│
└── main.dart                               # Point d'entrée & injection de dépendances
```

---

## 4. Fonctionnalités Implémentées (Itérations 1 & 2)
- **Importation RBC CSV :** Support multi-fichiers (Chèques + Visa), déduplication par empreinte SHA-256 + compteur journalier, choix *Append* ou *Replace all* au clic sur `Refresh`.
- **Classification 3 états :**
  - `Expense` (rouge, colonne de gauche)
  - `Income` (vert, colonne de droite)
  - `Transfer` (bleu, section séparée en dessous — détecte automatiquement les paiements de carte Visa et virements internes, exclus des totaux).
- **Catégorisation intelligente :**
  - 16 catégories par défaut adaptées au budget familial (incluant `Taxes & Gov`, `School Fees`, `Kids Activities`, `Kids Clothing & Gear`, `My Clothing & Jewelry`, `Car, Gas & Auto Ins.`, `Subscriptions`, etc.).
  - Mémorisation automatique des règles (`merchant_pattern -> category_name`) appliquée rétroactivement et sur les futurs imports.
  - Mode **Bulk Edit** multi-catégories en ligne avec sauvegarde groupée (`Save All`), filtre `Uncategorized only (X)`, et `Tooltip` au survol du libellé commerçant.

---

## 5. Feuille de Route (Prochaines Étapes)
1. **Dashboard avancé :** Moyenne mensuelle par catégorie, filtre par mois/période, graphiques d'évolution et budget prévisionnel.
2. **Multi-banques :** Création de `WealthsimpleCsvSource` (et/ou connecteur API SimpleFIN/Plaid).
3. **Synchronisation Mobile/Desktop :** Implémentation de `GoogleDriveSync` (OAuth + Drive API) pour partager `debt_free.sqlite` entre Windows et Android.
