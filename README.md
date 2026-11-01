# WooManager — Gestion WordPress / WooCommerce sur Mac

Application macOS native (Swift/SwiftUI) pour gérer un site WordPress + WooCommerce :
produits, commandes et contenu (articles/pages).

## Fonctions

- **Produits** : liste avec recherche, modification du prix, du stock et du statut publié/brouillon.
- **Commandes** : liste filtrable par statut, changement de statut en un clic.
- **Contenu** : articles et pages avec statut et lien vers le site.
- **Réglages** : connexion au site + test de connexion, clés sauvegardées localement.

## Prérequis

- macOS 13+
- Xcode (avec les Command Line Tools) : `xcode-select --install`

## Compilation

```bash
cd WooManager
swift build -c release
```

Lancement :

```bash
swift run
```

Ou ouvrir le dossier dans Xcode et cliquer sur ▶︎ Run.

## Configuration de votre site

1. Admin WordPress → **WooCommerce → Réglages → Avancé → API REST** → « Ajouter une clé ».
2. Permissions : **Lecture/Écriture**.
3. Copiez la **Clé client** (`ck_…`) et le **Secret client** (`cs_…`).
4. Dans l'app : **Réglages** → renseignez l'URL du site et les deux clés → **Tester la connexion**.

## Notes

- Les clés sont stockées uniquement dans le trousseau local de votre Mac (UserDefaults).
- L'app parle directement à l'API REST officielle de WooCommerce (`/wp-json/wc/v3`) — aucun plugin supplémentaire à installer.
