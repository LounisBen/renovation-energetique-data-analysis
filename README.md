# Rénovation énergétique : analyse territoriale et stratégie commerciale

Projet Data Analyst réalisé dans le cadre de ma formation Data Analyst & IA.

## Contexte

Les données publiques sur les logements, leur performance énergétique et les professionnels RGE peuvent-elles aider un distributeur de matériaux à compléter sa stratégie commerciale, à choisir les offres à développer et à préparer des actions ciblées auprès des professionnels ?

Pour cette première étude, le périmètre retenu est le Val-d'Oise.

## Objectif

L'objectif du projet est de croiser plusieurs sources de données publiques afin :

- d'identifier les territoires présentant des besoins importants en rénovation énergétique ;
- de comparer ces besoins avec la présence d'établissements RGE ;
- d'étudier les caractéristiques des logements concernés ;
- de construire des indicateurs utiles à la décision commerciale ;
- de proposer des pistes de ciblage pour un distributeur de matériaux.

## Sources de données

L'analyse repose principalement sur :

- ADEME : diagnostics de performance énergétique (DPE) 2024-2025 ;
- INSEE : données logement 2022 ;
- données RGE : établissements et qualifications ;
- DRIHL / DRIEAT : données MaPrimeRénov' utilisées pour contextualiser l'activité de rénovation aidée.

Les fichiers bruts ne sont volontairement pas intégrés au dépôt afin de conserver un portfolio léger et lisible. Les notebooks et scripts présents dans le dépôt illustrent les principales étapes de collecte, préparation, contrôle et analyse.

## Technologies utilisées

- Python : pandas, NumPy, nettoyage et exploration des données
- MySQL : stockage, jointures, agrégations et création de vues
- Power BI : analyse, KPI et visualisation
- DAX : mesures du tableau de bord
- Web scraping : collecte de données complémentaires
- Statistiques : corrélation de Spearman et régression multiple
- Git / GitHub : documentation et partage du projet

## Démarche

### 1. Collecte des données

Récupération des données DPE, INSEE et RGE ainsi que de données complémentaires relatives à MaPrimeRénov'.

### 2. Exploration et nettoyage avec Python

Les fichiers ont été explorés et nettoyés dans des notebooks Python :

- contrôle des valeurs manquantes ;
- normalisation des formats ;
- correction des codes postaux ;
- contrôle des identifiants ;
- suppression ou traitement des doublons ;
- préparation des données destinées à MySQL.

### 3. Analyse avec MySQL

Les données préparées ont été intégrées dans MySQL afin de :

- contrôler les correspondances entre les différentes sources ;
- effectuer les jointures ;
- calculer les indicateurs par commune ;
- agréger les données ;
- construire la vue `analyse_territoriale`.

### 4. Analyse statistique

Des analyses complémentaires ont été réalisées afin d'étudier les relations entre :

- ancienneté du parc immobilier ;
- part de maisons ;
- couverture DPE ;
- part de diagnostics classés F ou G.

Une corrélation de Spearman et une régression multiple ont notamment été utilisées.

### 5. Visualisation avec Power BI

Le tableau de bord Power BI permet :

- une vue globale du Val-d'Oise ;
- l'identification des communes prioritaires ;
- l'analyse des logements classés F ou G ;
- la comparaison maisons / appartements ;
- l'analyse de caractéristiques techniques ;
- une restitution orientée vers la décision commerciale.

## Principaux résultats

L'analyse porte sur :

- 130 843 DPE réalisés en 2024 et 2025 ;
- 8 568 diagnostics classés F ou G ;
- 183 communes du Val-d'Oise ;
- 553 établissements RGE distincts identifiés après nettoyage.

Parmi les communes disposant d'au moins 100 DPE, 12 communes dépassent simultanément trois seuils de travail :

- 93,63 DPE F/G observés ;
- 8,35 % de F/G parmi les diagnostics ;
- 16,91 DPE F/G par établissement RGE local.

Cette méthode permet d'identifier des territoires nécessitant une analyse commerciale plus approfondie.

Par exemple :

- Argenteuil compte 1 004 DPE F/G observés ;
- Montmorency compte 296 DPE F/G pour 5 établissements RGE locaux.

Les résultats montrent également une association positive entre l'ancienneté du parc immobilier et la proportion de logements classés F/G.

## Lecture commerciale

L'analyse ne cherche pas à prédire directement les ventes.

Elle permet plutôt de fournir des éléments complémentaires pour :

- prioriser certains territoires ;
- adapter les campagnes commerciales ;
- mieux comprendre les caractéristiques des logements à rénover ;
- identifier des familles de produits pouvant mériter une analyse commerciale complémentaire ;
- préparer le croisement futur avec des données internes de ventes, clients et marges.

## Limites

Cette étude repose sur des données publiques et ne contient aucune donnée commerciale interne d'une enseigne.

Les DPE étudiés ne représentent pas l'ensemble des logements du département.

Le nombre d'établissements RGE présents dans une commune ne permet pas à lui seul de conclure à une pénurie ou à un excès de professionnels.

Les seuils utilisés pour sélectionner les communes sont des seuils analytiques de travail et non des seuils réglementaires.

## Perspectives

Le projet pourrait être enrichi avec :

- des données commerciales internes ;
- les ventes par famille de produits ;
- les marges et stocks ;
- la localisation des points de vente ;
- les données DVF sur les transactions immobilières ;
- une extension de l'analyse à d'autres départements.

## Auteur

Lounis Benyahia  
Data Analyst

Power BI | SQL | Python | Analyse de données | Business Intelligence
