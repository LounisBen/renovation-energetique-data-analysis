# Projet rénovation énergétique — Fichiers SQL

Étude du Val-d’Oise à partir des DPE 2024–2025, des données logement INSEE 2022 et du fichier des établissements RGE collecté pour le projet.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `analyse_renovation_energetique.sql` | Contrôles de départ des tables INSEE, DPE et RGE, vérification des jointures, calcul des indicateurs, création des vues et sélection des communes ciblées. |
| `outils_maintenance_qualite_donnees.sql` | Traitement de la surface habitable, diagnostic et correction de l’encodage, contrôles techniques après traitement. Exécuter uniquement le bloc nécessaire. |
| `controles_annuels_dpe.sql` | Comparaison des volumes et parts de F/G par année, préparation de l’export communal annuel et vérification des périodes disponibles. |

Le script de maintenance ne doit pas être exécuté intégralement. Il conserve les traitements utilisés pendant la préparation des données ; leur présence ne signifie pas qu’ils doivent être appliqués à nouveau.

## Utiliser les scripts sur la base du projet

Les tables sources doivent déjà être importées et contrôlées :

- `insee_logement_2022`
- `dpe_95_2024_2025_clean`
- `rge_95_clean`

1. Ouvrir la connexion MySQL du projet.
2. Exécuter le script d’analyse pour contrôler les tables et créer les vues. Il contient la sélection de la base avec `USE renovation_energetique`.
3. Si nécessaire, exécuter le script de contrôles annuels après création des vues.
4. Utiliser la maintenance uniquement si une anomalie justifie le traitement concerné.

Les vues sont créées avec `CREATE OR REPLACE VIEW` : une nouvelle exécution remplace leur définition.

Les scripts d’analyse et de contrôle annuel ne réimportent pas les données et ne créent pas les tables sources.

Les trois vues principales du projet sont :

- `analyse_dpe_insee`
- `rge_commune`
- `analyse_territoriale`

### Export du contrôle annuel vers Python

Dans `controles_annuels_dpe.sql`, le résultat du contrôle statistique annuel peut être exporté au format CSV avec les en-têtes.

Nom utilisé :

`controle_dpe_par_annee.csv`

Ce fichier est ensuite exploité dans le notebook :

`analyse_statistique_renovation_energetique.ipynb`

Le calcul de la corrélation de Spearman est réalisé dans Python.

## Contrôles de référence

| Contrôle | Résultat attendu |
|---|---:|
| Diagnostics DPE | 130 843 |
| Diagnostics classés F/G | 8 568 |
| Communes dans `analyse_territoriale` | 183 |
| Lignes du fichier RGE | 1 607 |
| Établissements RGE distincts par SIRET | 553 |
| Communes répondant aux critères de ciblage | 12 |

