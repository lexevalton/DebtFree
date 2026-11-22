# DebtFree — Architecture & Developer Guide

Personal finance management application built with **Flutter / Dart** targeting **Windows Desktop** and **Android** (native Flutter, no web wrapper).

---

## 1. Architectural Principles

- **Clean Layered Architecture** inside `lib/`:
  - `domain/` — Pure Dart immutable entities and repository contracts. **Zero external or Flutter dependencies.**
  - `core/` — Cross-cutting infrastructure (SQLite v4 database management and cloud sync contracts).
  - `data/` — Data source parsers (CSV) and concrete repository implementations split via mixins.
  - `presentation/` — Modular Flutter UI pages and single-responsibility widgets (~250 lines max per file).
- **Language Rule**: All code, comments, UI labels, and technical documentation are written strictly in **English**.
- **Sync-Ready SQLite**: Configured with `PRAGMA journal_mode = DELETE;` so the single `debt_free.sqlite` file can be safely synced across devices without WAL sidecar conflicts.

---

## 2. Directory Structure

```text
lib/
├── main.dart                                         # App entry point, Dependency Injection
├── core/
│   ├── database/
│   │   └── app_database.dart                         # SQLite v4 singleton (transactions, categories, category_rules, goals)
│   └── sync/
│       ├── cloud_sync_provider.dart                  # Abstract sync contract (pushDatabase / pullDatabase)
│       └── local_only_sync.dart                      # Local no-op sync placeholder (ready for GoogleDriveSync)
├── domain/
│   ├── entities/
│   │   ├── account_type.dart                         # Enum: rbcChequing, rbcVisa, unknown
│   │   ├── goal.dart                                 # Immutable Goal model (saving vs restriction, target, allocated, notes)
│   │   ├── transaction.dart                          # Immutable Transaction model (SHA-256 id, amount, type, category, goalId)
│   │   └── transaction_type.dart                     # Enum: expense, income, transfer
│   └── repositories/
│       └── transaction_repository.dart               # Unified repository contract (transactions, categories, rules, goals)
├── data/
│   ├── repositories/
│   │   ├── sqlite_transaction_repository.dart        # Core transaction CRUD, CSV sync & auto-rule matching
│   │   ├── sqlite_category_mixin.dart                # Category CRUD, ARGB32 colors & merchant rule persistence
│   │   └── sqlite_goals_mixin.dart                   # Goal CRUD, virtual surplus allocation & transaction goal linking
│   └── sources/
│       ├── transaction_source.dart                   # Abstract CSV/data source interface
│       └── rbc_csv_source.dart                       # RBC Chequing & Visa CSV parser + Chequing<->Visa transfer reconciliation
└── presentation/
    ├── pages/
    │   ├── left_menu_page.dart                       # Collapsible NavigationRail shell (Dashboard, All Transactions, Categories, Goals)
    │   ├── dashboard_page.dart                       # Responsive 2-column widget grid (fixed 360px card height)
    │   ├── expenses_page.dart                        # "All Transactions" view, filters, Refresh (Append/Replace), Bulk Edit
    │   ├── categories_page.dart                      # Category creation (HSL hue slider) & memorized merchant rules
    │   └── goals_page.dart                           # Unallocated surplus banner, Goal creation & active goals list
    └── widgets/
        ├── transaction_category_group.dart           # Reusable section header + transaction list (Expenses/Income/Transfers)
        ├── transaction_row_card.dart                 # Interactive row with desktop hover state, badges, tooltip & bulk dropdown
        ├── transaction_edit_dialog.dart              # Modal dialog for category, rule memory, type switch & saving goal link
        ├── gradient_color_slider.dart                # Continuous HSL hue slider for custom category colors
        ├── allTransactions/
        │   ├── expenses_bars.dart                    # ExpensesAppBar, ExpensesFilterBar & BulkEditBottomBar
        │   ├── global_summary_card.dart              # Top cashflow summary with clickable Transfers filter toggle
        │   ├── monthly_cashflow_section.dart         # Monthly container (header + breakdown + 2-column cashflow)
        │   └── month_breakdown_bar.dart              # Expandable Debit vs Credit vs Transfers breakdown bar
        ├── expensesPieChart/
        │   ├── category_pie_chart_card.dart          # Interactive fl_chart PieChart (period selector, fixed/DB colors, slice toggle)
        │   └── category_transactions_card.dart         # Scrollable transaction list for the selected PieChart slice
        ├── dashboard/
        │   └── dashboard_goals_card.dart             # Scrollable Goals & Monthly Limits card with color status & notes tooltip
        └── goals/
            ├── surplus_banner_card.dart              # Unallocated surplus banner with split-allocation dialog for Saving goals
            └── goal_creation_card.dart               # Form to create Saving targets or Category-bound Spending Restrictions
```

---

## 3. Database Schema (`debt_free.sqlite` — v4)

- **`transactions`**
  - `id TEXT PRIMARY KEY` (SHA-256 hash for deterministic deduplication)
  - `account TEXT NOT NULL` (`rbcChequing` | `rbcVisa` | `unknown`)
  - `date TEXT NOT NULL` (`YYYY-MM-DD`)
  - `amount REAL NOT NULL`
  - `merchant TEXT NOT NULL`
  - `type TEXT NOT NULL DEFAULT 'expense'` (`expense` | `income` | `transfer`)
  - `category TEXT NOT NULL DEFAULT 'Uncategorized'`
  - `goal_id TEXT` (nullable foreign link to a `saving` goal, e.g., Wealthsimple transfers)
- **`categories`**
  - `name TEXT PRIMARY KEY` (16 seeded defaults + custom user categories)
  - `color INTEGER NOT NULL DEFAULT 4286091420` (ARGB32 integer)
- **`category_rules`**
  - `merchant_pattern TEXT PRIMARY KEY`
  - `category_name TEXT NOT NULL`
- **`goals`**
  - `id TEXT PRIMARY KEY`
  - `name TEXT NOT NULL`
  - `type TEXT NOT NULL` (`saving` | `restriction`)
  - `target_amount REAL NOT NULL`
  - `allocated_amount REAL NOT NULL DEFAULT 0` (virtual surplus allocated to a saving goal)
  - `category_name TEXT` (required when `type == 'restriction'`)
  - `notes TEXT NOT NULL DEFAULT ''`

---

## 4. Implemented Features

- **Navigation Shell (`LeftMenuPage`)**: Collapsible `NavigationRail` (`Dashboard`, `All Transactions`, `Categories`, `Goals`) toggled manually via header button.
- **CSV Import & Transfer Reconciliation (`RbcCsvSource`)**:
  - Parses RBC Chequing & Visa CSVs with SHA-256 deduplication (`Append` or `Replace all`).
  - Automatically reconciles internal Chequing <-> Visa card payments by matching opposite amounts within ±3 days as `TransactionType.transfer`, and tags Wealthsimple transfers.
- **All Transactions (`ExpensesPage`)**:
  - Global summary bar with expandable breakdown (`Debit Expenses`, `Credit Expenses`, `Net Cashflow`, `Transactions`) and clickable `Transfers` toggle to inspect/reclassify transfers across all months.
  - Monthly cashflow sections with side-by-side **Expenses** (red, left) and **Income** (green, right), desktop hover feedback, `Uncategorized only` filter, and multi-row **Bulk Edit**.
  - Transaction edit dialog supporting category assignment, rule memory, type override, and linking `Transfer` transactions to a `Saving` goal.
- **Categories & Auto-Rules (`CategoriesPage`)**:
  - Custom category creation with a continuous HSL `GradientColorSlider` persisted in SQLite.
  - Automatic merchant pattern matching on import and bulk updates.
- **Goals & Surplus Management (`GoalsPage`)**:
  - Computes real-time unallocated surplus (`Income - Expenses - Virtual Allocations - Linked Wealthsimple Transfers`) and lets users split allocations across multiple `Saving` goals.
  - Supports **Saving Targets** (`saving`) and **Category Spending Restrictions** (`restriction`) with custom notes.
- **Dashboard (`DashboardPage`)**:
  - Responsive 2-column grid with uniform `360px` card heights:
    1. **Expenses by Category (`CategoryPieChartCard`)**: Period dropdown (`Current Month`, `Last 6 Months`, `Last Year`, `All Time`), custom/DB colors, hover badges, and click-to-toggle slice selection.
    2. **Category Transactions (`CategoryTransactionsCard`)**: Scrollable list of transactions matching the clicked PieChart slice.
    3. **Goals & Monthly Limits (`DashboardGoalsCard`)**: Scrollable goal tracker (Green when Saving ≥ target or Restriction ≤ limit; Orange when Saving < target; Red when Restriction > limit) with multi-line hover tooltips (`Name (Type) - Target` + `Notes`).

---

## 5. Next Roadmap Milestones

1. **Anti-Overspending Dashboard Widgets**: Add daily *Safe-to-Spend* indicator, month-over-month category trend comparison, and recurring subscription detection.
2. **Wealthsimple Integration**: Implement `WealthsimpleCsvSource` in `lib/data/sources/` conforming to `TransactionSource`.
3. **Cross-Device Cloud Sync**: Replace `LocalOnlySync` with `GoogleDriveSync` to synchronize `debt_free.sqlite` between Windows Desktop and Android.
