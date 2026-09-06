# Conventions Google Calendar — Sairen.io

Document de référence interne. Dernière mise à jour : 6 septembre 2026.

## 1. Les agendas et leur rôle

| Agenda | Rôle |
|---|---|
| Agenda perso (prenom.nom@sairen.io) | Agenda individuel |
| **Shared Agenda** | Rituels d'entreprise + absences / télétravail |
| **Sales Agenda** | RDV prospects sortants |
| **Customer Care** | Onboarding, formations, audits, points d'étape clients |
| **Inbound Sales** (sales@sairen.io) | Bookings Cal.com entrants |

## 2. Règle des couleurs — Sales Agenda

**Qui a créé l'événement n'est pas qui le traite.** Les SDR (Lucas, Roch) posent les RDV
sur l'agenda ; l'AE à qui le RDV est assigné se lit **uniquement à la couleur**. Ne jamais
déduire l'assignation du créateur de l'invitation ni de la liste des invités.

La couleur d'un RDV porte **soit l'AE qui le tient, soit son statut**.

### Par AE

| Couleur Google | ID | AE |
|---|---|---|
| Banane (jaune) | 5 | Solal Weill |
| Sauge (vert clair) | 2 | Nathan Bouloudnine |
| Myrtille (bleu) | 9 | Angelo Kahloun |
| *(à définir)* | — | Nathan Attias |

### Par statut

| Couleur Google | ID | Signification |
|---|---|---|
| Basilic (vert foncé) | 10 | Déplacement sur site |
| Raisin (violet) | 3 | No show |
| Graphite (gris) | 8 | Non assigné |

> **Limite connue.** Un événement ne porte qu'une seule couleur : un no-show de Boulou ou un
> déplacement de Solal ne peut pas afficher à la fois l'AE et le statut. Les couleurs de statut
> écrasent la couleur d'AE, donc un RDV passé en no-show perd la trace de l'AE à qui il était
> assigné.

**Un RDV sans couleur = non assigné**, au même titre que le gris. C'est un RDV posé par un SDR
qui attend encore son AE.

Le Sales Agenda ne contient que des RDV prospects. Les rituels internes, les événements
personnels et les RDV déjà portés par un autre agenda n'y ont pas leur place : ils faussent le
comptage du pipe.

## 3. Règle des couleurs — Shared Agenda

| Couleur Google | ID | Signification |
|---|---|---|
| Flamant rose | 4 | Absence / télétravail (journée entière) |
| Graphite | 8 | Plages horaires — AUDIT |
| Couleur d'agenda par défaut | — | Rituels récurrents |

## 4. Nommage des absences et du télétravail

Journée entière sur le **Shared Agenda**, en flamant rose (ID 4) :

- `ABS — Prénom`
- `TT — Prénom`

Règles :

- Une absence de plusieurs jours = **un seul événement** couvrant toute la période, jamais un événement par jour.
- Trois Nathan dans l'équipe : utiliser `ABS — Boulou`, `ABS — Nathan Attias`, `ABS — Nathan Berracasa` pour lever l'ambiguïté.

## 5. Nommage des autres événements

| Agenda | Format |
|---|---|
| Sales Agenda | `Prospect x Sairen`, suffixe `- R2` / `- R3` pour les relances |
| Customer Care | `Client x Sairen : point d'étape`, `Formation Sairen : X`, `Audit X` |

Les numéros de téléphone et coordonnées vont dans la **description**, jamais dans le titre.

## 6. Règles générales

- Un événement n'existe que sur **un seul agenda**. Pas de copie entre agendas.
- Les RDV clients ne se suppriment et ne se déplacent pas sans l'accord de la personne qui les a fixés.
