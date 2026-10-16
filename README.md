# Bulletins Néhémie

Page de saisie des notes de l'École Néhémie de Katibougou (second cycle).

- Les enseignants se connectent avec l'identifiant et le mot de passe donnés par la direction.
- Chaque enseignant ne voit que ses classes et ses matières.
- Saisie des devoirs (/20) et des compositions (notes de classe /20, composition /40, élèves dispensés).
- Saisie possible sans réseau : les notes partent automatiquement au retour de la connexion.
- Le directeur et le secrétariat gèrent les élèves (onglet « Élèves ») : ajout un par un ou en collant une liste, modification, changement de classe.
- Certificat de fréquentation scolaire : bouton « Certificat » à côté de chaque élève ; on remplit les noms des parents, puis on imprime.
- Le directeur suit les saisies en direct (mise à jour toutes les 15 secondes).
- Le directeur et le secrétariat préviennent les parents sur WhatsApp (onglet « Messages ») : image de la note de devoir, résultats du trimestre (moyenne et rang), alertes de suivi et félicitations. Chaque message part du téléphone utilisé ; la page retient quels parents ont été prévenus. Script à exécuter une fois : `sql/messages_parents.sql`.

Les données sont dans la base Supabase **BULLETINS-NEHEMIE**, protégée par des règles d'accès.
La clé écrite dans `index.html` est une clé publique : elle ne donne accès à rien sans un compte valide.

## Fichiers

- `index.html` : la page
- `sw.js` : garde la page sur le téléphone pour l'ouvrir hors connexion
- `manifest.json` : permet d'ajouter la page à l'écran d'accueil du téléphone

Pour l'entretien et le fonctionnement interne, voir [GUIDE-TECHNIQUE.md](GUIDE-TECHNIQUE.md).
