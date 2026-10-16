# Guide technique — Bulletins Néhémie

Ce guide explique comment le module de notes et de bulletins de l'École Néhémie de Katibougou est construit, et comment faire les gestes d'entretien courants. Il s'adresse au directeur et à toute personne qui reprendrait l'outil plus tard, même sans connaître le projet.

**À tenir à jour :** chaque fois que l'outil change, ajoutez une ligne à l'[historique](#11-historique) en bas de ce fichier.

---

## 1. En bref

| Élément | Où il se trouve |
|---|---|
| La page utilisée par tous | https://luclkone12-dev.github.io/module-bulletins-/ |
| Le code de la page | Dépôt GitHub public `luclkone12-dev/module-bulletins-`, branche `main` |
| Les données (notes, élèves, comptes) | Projet Supabase **BULLETINS-NEHEMIE**, identifiant `fdrnjgmuzxiklncyjqio` (offre gratuite) |
| Les messages aux parents | Envoyés depuis le WhatsApp du téléphone utilisé (rien ne part tout seul) |
| Les sauvegardes | Fichiers Excel téléchargés depuis Réglages › Sauvegarde, à garder sur le PC de l'école |

Le dépôt privé « bulletins de module » du même compte GitHub n'est pas utilisé.

## 2. Les trois morceaux

```
 Téléphone ou ordinateur                     Internet
 ┌──────────────────────────┐   la page   ┌──────────────────────────┐
 │ Navigateur (Chrome)      │ ◄────────── │ GitHub Pages             │
 │ index.html               │             │ (fichiers du dépôt)      │
 │ + cache hors connexion   │             └──────────────────────────┘
 │                          │  données    ┌──────────────────────────┐
 │                          │ ◄─────────► │ Supabase                 │
 │                          │             │ base PostgreSQL + comptes│
 └──────────┬───────────────┘             └──────────────────────────┘
            │ lien wa.me
            ▼
        WhatsApp du téléphone → parents
```

- **GitHub Pages** ne fait que servir les fichiers. Il ne contient aucune donnée.
- **Supabase** garde toutes les données et vérifie, pour chaque lecture ou écriture, que le compte connecté y a droit.
- La clé écrite dans `index.html` (`SB_KEY`) est une **clé publique**. Elle ne donne accès à rien sans un compte valide : ce sont les règles de la base qui protègent les données.

### Les fichiers du dépôt

| Fichier | Rôle |
|---|---|
| `index.html` | Toute l'application : présentation, calculs, écrans (environ 1 500 lignes) |
| `sw.js` | Garde la page sur le téléphone pour l'ouvrir sans réseau |
| `manifest.json` | Permet « Ajouter à l'écran d'accueil » |
| `sql/messages_parents.sql` | Script déjà exécuté une fois pour l'onglet Messages |
| `README.md` | Présentation courte |
| `GUIDE-TECHNIQUE.md` | Ce guide |

Bibliothèques chargées depuis Internet : `supabase-js` 2.45.4 (jsDelivr) et `xlsx` 0.18.5 (cdnjs, seulement pour la sauvegarde Excel).

## 3. Comptes et rôles

- On se connecte avec un **identifiant** (ex. `a.traore`). En interne, il devient l'adresse `a.traore@personnel.nehemie` : ce n'est pas un vrai e-mail, aucun message n'y est envoyé.
- Les comptes se créent et se gèrent dans **Réglages › Comptes** (directeur seul).

| Rôle | Ce qu'il voit et fait |
|---|---|
| **Directeur** | Tout : notes de toutes les classes, bulletins, élèves, messages, DEF, En direct, Réglages, journal |
| **Secrétariat** | Notes de toutes les classes, bulletins, palmarès, élèves, messages, DEF. Pas les Réglages ni En direct |
| **Enseignant** | Seulement ses classes et matières (affectations), pour l'année en cours : devoirs, compositions, notes d'examen blanc du DEF |

Les affectations (quel enseignant, quelle classe, quelle matière) sont **rattachées à une année scolaire**.

## 4. Organisation de `index.html`

Le script est découpé en sections, chacune annoncée par un commentaire. Pour trouver une partie, cherchez son titre dans le fichier.

| Titre de section dans le code | Contenu |
|---|---|
| `Configuration` | Adresse Supabase, clé publique, liste des classes (`CLASSES`), rôles |
| `Utilitaires` | Formats des notes et des dates, appréciations, messages d'erreur |
| `Cache sur le téléphone` | Copie des données dans le téléphone pour travailler sans réseau |
| `Chargement depuis la base` | Lecture des matières, affectations, élèves, devoirs, notes |
| `Vue fusionnée` | Mélange les données de la base et les saisies pas encore envoyées |
| `Envoi des saisies` | File d'attente des notes saisies hors connexion, puis envoi |
| `Affichage` | En-tête, onglets, écran de connexion, onglet Notes |
| `Saisie d'un devoir ou de la composition` | Écran de saisie des notes |
| `Élèves` | Formulaire élève, liste collée (F ou G obligatoire) |
| `Certificat de fréquentation` | Fiche à remplir (parents, naissance, n°) puis impression A4 |
| `Bulletins` | Calcul des moyennes et des rangs, bulletin imprimé, contrôle des notes manquantes |
| `Palmarès et statistiques` | Trois premiers, effectifs et taux par sexe, impression |
| `Messages aux parents` | Textes WhatsApp, images, alertes de suivi, encouragements |
| `Réglages` | Comptes, affectations, matières et coefficients, école (nom, logo, année) |
| `Sauvegarde` | Export Excel de toutes les données, rappel après 7 jours |
| `Examens blancs du DEF` | Onglet DEF, saisie par matière, élèves à risque |
| `Saisies en direct` | Fil des saisies pour le directeur (toutes les 15 secondes) |
| `Personnes connectées` | Liste des personnes qui ont la page ouverte |
| `Événements` | Réactions aux boutons, aux champs et aux formulaires |
| `Démarrage et mises à jour` | Ouverture de session, actualisations périodiques |

Tout l'état de la page vit dans un seul objet JavaScript, `S` (profil connecté, élèves, notes, onglet ouvert…). Chaque écran est une fonction `view…()` qui renvoie du HTML, et `render()` redessine la page.

## 5. La base de données

Toutes les tables sont dans le schéma `public` de Supabase.

| Table | Contenu |
|---|---|
| `profils` | Un compte par personne : identifiant, nom, rôle, actif ou non |
| `affectations` | Qui enseigne quoi : année, compte, classe, matière |
| `reglages` | Une ligne `ecole` : nom, année scolaire en cours, directeur, logo |
| `matieres` | Matières, niveaux concernés (7, 8, 9), coefficients par niveau, ordre sur le bulletin |
| `eleves` | Élèves : matricule, nom, prénom, sexe, classe, parent et téléphone, naissance |
| `evaluations` | Devoirs et compositions : année, classe, matière, trimestre, type, titre, date |
| `notes` | Une note par élève et par évaluation (`note`, `note_classe`, `dispense`) |
| `verrous` | Trimestres verrouillés par classe (les notes ne se modifient plus) |
| `examens` | Examens blancs du DEF : année, titre, date |
| `notes_examen` | Notes d'examen blanc : examen, élève, matière, classe, note sur 20 |
| `envois_devoirs`, `envois_bulletins`, `suivis` | Mémoire des messages WhatsApp déjà envoyés |
| `journal` | Historique de toutes les modifications (qui, quand, avant, après). Ne peut être ni modifié ni effacé |
| `verifs` | Prévue pour le code de vérification des bulletins (pas encore utilisée par la page) |
| `certificats` | Prévue pour les certificats de fréquentation (pas encore utilisée : la page imprime sans rien enregistrer) |

### Automatismes dans la base

- **Journal** : chaque ajout, modification ou suppression dans les tables principales est copié dans `journal` par les déclencheurs `j_…`. Le déclencheur `journal_intouchable` empêche d'effacer ou de modifier le journal.
- **Matricule** : le déclencheur `eleves_matricule_auto` donne à chaque élève un matricule `NEH-AA-NNNNF` (fille) ou `NEH-AA-NNNNG` (garçon). `AA` = début de l'année scolaire en cours, `NNNN` = numéro à la suite pour toute l'école. Le numéro est donné dès que le sexe est connu, ne se modifie pas à la main, et seule la lettre change si le sexe est corrigé.
- **Année en cours** : la fonction `annee_en_cours()` lit l'année dans Réglages › École (par défaut `2026-2027`).

## 6. La sécurité

- La **sécurité au niveau des lignes** (RLS) est activée sur toutes les tables. Chaque règle s'appuie sur quelques fonctions :
  - `mon_role()` : le rôle du compte connecté, s'il est actif ;
  - `est_directeur()`, `est_bureau()` (directeur ou secrétariat) ;
  - `enseigne(année, classe, matière)` et `a_la_classe(année, classe)` : affectations de l'enseignant ;
  - `peut_lire_eval()`, `peut_ecrire_eval()`, `est_verrouille()` : droits sur un devoir et sur les trimestres verrouillés.
- Les fonctions `admin_…` (créer un compte, changer un mot de passe, modifier matières et affectations, réglages de l'école) commencent toutes par vérifier que la personne est le directeur. Contrôlé le 15 octobre 2026.
- Les visiteurs non connectés ne peuvent appeler aucune fonction interne (fermé le 15 octobre 2026).
- Un compte désactivé perd aussitôt tous ses droits.

## 7. Les règles de calcul

**Moyenne d'une matière au trimestre**
- Notes de classe sur 20 : celles saisies avec la composition. À défaut, la moyenne des devoirs du trimestre dans la matière.
- Composition : saisie sur 40, ramenée sur 20.
- Moyenne = (notes de classe + 2 × composition sur 20) ÷ 3.
- S'il manque l'une des deux, la moyenne est provisoire et marquée `*`.
- Élève dispensé : la matière ne compte ni dans ses points ni dans son total de coefficients.

**Moyenne générale, rang, décision**
- Moyenne générale = Σ (moyenne × coefficient) ÷ Σ coefficients des matières notées. Coefficients du bulletin de 9e pour toutes les classes, plus Musique (coef 1) en 7e et 8e.
- Rang : par moyenne arrondie au millième. Les élèves à égalité ont le même rang (« ex æquo »).
- Moyenne annuelle = moyenne des trois trimestres. Admis en classe supérieure à partir de 10/20.
- Appréciations : 0–1 Nul, 2–3 Mal, 4–5 Médiocre, 6–7 Faible, 8–9 Insuffisant, 10–11 Passable, 12–13 Assez-Bien, 14–15 Bien, 16–17 Très-Bien, 18 et plus Excellent.

**Palmarès et statistiques**
- A composé : au moins une note de composition dans le trimestre (pour l'année : les trois moyennes existent).
- A la moyenne : moyenne générale ≥ 10, parmi ceux qui ont composé.
- Taux de réussite = ont la moyenne ÷ ont composé. Taux d'échec = le reste.

**Examens blancs du DEF (9e)**
- 8 matières : Rédaction, Dictée-Questions, Histoire-Géographie, Maths, Sciences naturelles, Physique-Chimie, ECM, Anglais, avec les coefficients du bulletin de 9e (total 18).
- Moyenne = Σ (note × coef) ÷ Σ coef des matières notées. Élève à risque : moyenne ≤ 9,99.

**Messages aux parents**
- Alerte de suivi : trois devoirs de suite sous 10/20, toutes matières confondues (absences ignorées).
- Encouragements : trois bonnes notes de suite (16/20, ou 13/20 en Rédaction), ou moyenne en hausse de 2 points d'un trimestre à l'autre.
- Les notes de composition ne sont jamais envoyées aux parents.

## 8. Le fonctionnement sans réseau

- Après une première connexion, les données utiles sont copiées dans le téléphone (`saveCache`). La page s'ouvre ensuite même sans réseau, grâce à `sw.js`.
- Les devoirs et compositions saisis hors connexion vont dans une **file d'attente** (`outbox`) et partent tout seuls au retour du réseau (essai toutes les 30 secondes).
- Si l'enseignant touche « Quitter » avant l'envoi, ces saisies sont perdues : la page l'avertit.
- Les notes d'examen blanc du DEF, les élèves et les réglages ne s'enregistrent **qu'en ligne**.

## 9. Gestes courants

### Modifier la page et publier la modification
1. Sur GitHub, ouvrez le dépôt `module-bulletins-`, puis le fichier à changer, puis l'icône crayon (« Edit »).
2. Faites la modification, puis « Commit changes ».
3. **Dans `sw.js`, augmentez le numéro de version** (`bulletins-v9` devient `bulletins-v10`), pour que les téléphones prennent la nouvelle version.
4. Attendez une à deux minutes, puis rouvrez la page.

### Annuler une modification de la page
Sur GitHub, ouvrez l'historique des commits (« Commits »), trouvez la modification, et utilisez « Revert ». Les données de Supabase ne sont pas touchées par cette opération.

### Ajouter un compte, changer un mot de passe, désactiver quelqu'un
Réglages › Comptes, avec le compte directeur. Mot de passe : au moins 6 caractères.

### Changer les classes et matières d'un enseignant
Réglages › Comptes : ouvrez la fiche de l'enseignant et modifiez ses classes et matières.

### Ajouter une matière ou changer un coefficient
Réglages › Matières. Une matière qui a déjà des notes n'est pas effacée : elle est seulement masquée.

### Passer à une nouvelle année scolaire
1. Faites une **sauvegarde Excel** complète de l'année qui se termine.
2. Réglages › École : changez l'année scolaire (ex. `2027-2028`).
3. Refaites les affectations des enseignants pour la nouvelle année (elles sont rattachées à l'année).
4. Mettez à jour la classe des élèves qui passent, et ajoutez les nouveaux élèves : ils recevront des matricules `NEH-27-…`.

### Le projet Supabase s'est mis en pause
L'offre gratuite met le projet en pause après environ une semaine sans activité. Une tâche programmée (« Réveil des bases Supabase », le lundi et le jeudi matin) le vérifie et le relance. Pour le relancer à la main : site de Supabase › projet BULLETINS-NEHEMIE › « Restore project ». Les données ne sont pas perdues.

### Exécuter un script SQL
Site de Supabase › projet BULLETINS-NEHEMIE › SQL Editor › coller le script › « Run ». À ne faire qu'avec un script préparé et compris : une erreur peut toucher toutes les données.

### Sauvegarder et restaurer
- **Sauvegarder** : Réglages › Sauvegarde télécharge un fichier Excel daté avec tous les élèves, devoirs et notes. Gardez-le sur le PC de l'école et sur une clé USB. Le directeur reçoit un rappel après 7 jours sans sauvegarde.
- **Restaurer** : il n'y a pas de bouton de restauration. En cas de perte, les données du fichier Excel peuvent être remises dans la base par un script préparé pour l'occasion. L'offre gratuite de Supabase ne fournit pas de sauvegarde téléchargeable : les fichiers Excel sont la vraie sauvegarde.

## 10. Points connus et limites

- **Un seul gros fichier** (`index.html`) : simple à héberger, mais long à parcourir. Utilisez les titres de section (partie 4).
- **Les tables `envois_bulletins` et `suivis`** (mémoire des messages envoyés) acceptent l'écriture de tout compte connecté. Elles ne contiennent aucune note : au pire, un message pourrait apparaître comme « déjà envoyé ».
- **La liste des personnes connectées** passe par un canal Supabase Realtime public. Il ne transporte que des identifiants internes et l'écran ouvert, jamais de nom ni de note.
- **Protection contre les mots de passe piratés** : réservée à l'offre payante de Supabase, donc non activée.
- **Offre gratuite Supabase** : 500 Mo de données et mise en pause après une semaine d'inactivité. Largement suffisant pour environ 200 élèves.
- **Pas encore faits** : code de vérification sur les bulletins, envoi WhatsApp automatique (aujourd'hui semi-automatique).

## 11. Historique

| Date | Changement |
|---|---|
| 14 oct. 2026 | Page de saisie en ligne, onglets Élèves, Bulletins, Réglages, Messages, Sauvegarde Excel |
| 15 oct. 2026 | Sécurité : fonctions internes fermées aux visiteurs non connectés, contrôle des fonctions d'administration |
| 15 oct. 2026 | Matricules automatiques `NEH-AA-NNNNF/G`, sexe obligatoire, suppression du devoir d'essai |
| 15 oct. 2026 | En direct : liste des personnes connectées |
| 15 oct. 2026 | Bulletins : palmarès et statistiques (trimestre ou année) |
| 15 oct. 2026 | Onglet DEF : examens blancs des 9e |
| 15 oct. 2026 | Tâche programmée de réveil des bases Supabase ; ce guide technique |
| 16 oct. 2026 | Certificat de fréquentation scolaire : bouton « Certificat » dans la liste des élèves, noms du père et de la mère saisis à l'impression (non enregistrés), numéro proposé d'après le dernier imprimé sur le téléphone, en-tête Académie de Kalabancoro et CAP de Ouezzindougou |
