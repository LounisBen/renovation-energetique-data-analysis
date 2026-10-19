-- ANALYSE DU PROJET
-- Contrôles de départ, indicateurs, vues et ciblage territorial.
-- Instructions SQL du fichier de base conservées sans modification.


-- PROJET : Rénovation énergétique - Val-d'Oise
-- Base de données MySQL


-- 1. CRÉATION ET SÉLECTION DE LA BASE

-- Création de la base si elle n'existe pas déjà
CREATE DATABASE IF NOT EXISTS renovation_energetique;

-- Sélection de la base utilisée pour les requêtes suivantes
USE renovation_energetique;

-- Vérification des tables présentes dans la base
SHOW TABLES;

-- 2. CONTRÔLE DE LA TABLE INSEE

-- Vérification de la structure et des types de colonnes
DESCRIBE insee_logement_2022;

-- Aperçu des 5 premières lignes
SELECT *
FROM insee_logement_2022
LIMIT 5;

-- Vérification du nombre de communes présentes
SELECT
    COUNT(*) AS nombre_lignes,
    COUNT(DISTINCT code_insee) AS nombre_communes
FROM insee_logement_2022;


-- 3. CONTRÔLE DE LA TABLE DPE

-- Vérification du nombre total de DPE importés
SELECT COUNT(*) AS nombre_lignes
FROM dpe_95_2024_2025_clean;

-- Aperçu des 5 premières lignes
SELECT *
FROM dpe_95_2024_2025_clean
LIMIT 5;

-- Vérification de la structure et des types de colonnes
DESCRIBE dpe_95_2024_2025_clean;

-- Vérification du nombre de communes présentes
SELECT
    COUNT(*) AS nombre_lignes,
    COUNT(DISTINCT code_insee) AS nombre_communes
FROM dpe_95_2024_2025_clean;

-- Contrôle de cohérence :
-- un code INSEE ne doit correspondre qu'à un seul nom de commune
SELECT
    code_insee,
    COUNT(DISTINCT commune) AS nombre_noms_commune
FROM dpe_95_2024_2025_clean
GROUP BY code_insee
HAVING COUNT(DISTINCT commune) > 1;

-- 4. CONTRÔLE DE LA TABLE RGE

-- Comptage :
-- 1 607 lignes attendues
-- 553 entreprises RGE distinctes
-- 102 communes représentées
--
-- Une entreprise peut apparaître plusieurs fois lorsqu'elle
-- possède plusieurs qualifications RGE.

SELECT
    COUNT(*) AS nombre_lignes,
    COUNT(DISTINCT siret) AS nombre_entreprises,
    COUNT(DISTINCT commune) AS nombre_communes
FROM rge_95_clean;

-- Aperçu des 5 premières lignes
SELECT *
FROM rge_95_clean
LIMIT 5;

-- Vérification de la structure de la table
DESCRIBE rge_95_clean;

-- Vérification de la qualité des codes postaux
-- Le résultat attendu est 0 ligne.
SELECT
    code_postal,
    COUNT(*) AS nombre_lignes
FROM rge_95_clean
WHERE LENGTH(code_postal) <> 5
GROUP BY code_postal;

-- 5. CONTRÔLE DES CLÉS DE JOINTURE

-- Vérification de la jointure DPE / INSEE sur le code INSEE
SELECT
    d.code_insee,
    d.commune,
    d.etiquette_dpe,
    i.logements_total_2022
FROM dpe_95_2024_2025_clean AS d

INNER JOIN insee_logement_2022 AS i
    ON d.code_insee = i.code_insee

LIMIT 10;

-- Vérification que toutes les communes présentes dans le RGE
-- trouvent une correspondance dans le DPE.
-- Le résultat attendu est 0 ligne.

SELECT DISTINCT
    r.commune
FROM rge_95_clean AS r

LEFT JOIN (
    SELECT DISTINCT commune
    FROM dpe_95_2024_2025_clean
) AS d
    ON r.commune = d.commune

WHERE d.commune IS NULL

ORDER BY r.commune;

-- 6. AGRÉGATION DES DPE PAR COMMUNE

-- Calcul des principaux indicateurs DPE par commune :
-- nombre de DPE,
-- nombre de passoires énergétiques F/G,
-- consommation moyenne,
-- part des passoires énergétiques.

SELECT
    code_insee,
    commune,
    COUNT(*) AS nombre_dpe,
    SUM(passoire_fg) AS nombre_passoires_fg,

    ROUND(
        AVG(conso_5_usages_par_m2_ep),
        2
    ) AS consommation_moyenne,

    ROUND(
        SUM(passoire_fg) / COUNT(*) * 100,
        2
    ) AS part_passoires_fg_pct

FROM dpe_95_2024_2025_clean

GROUP BY
    code_insee,
    commune

ORDER BY nombre_dpe DESC;

-- 7. CROISEMENT DPE / INSEE AVEC UNE CTE

-- La CTE crée temporairement une table agrégée des DPE
-- à l'échelle communale.

WITH dpe_commune AS (

    SELECT
        code_insee,
        commune,
        COUNT(*) AS nombre_dpe,
        SUM(passoire_fg) AS nombre_passoires_fg,

        ROUND(
            AVG(conso_5_usages_par_m2_ep),
            2
        ) AS consommation_moyenne,

        ROUND(
            SUM(passoire_fg) / COUNT(*) * 100,
            2
        ) AS part_passoires_fg_pct

    FROM dpe_95_2024_2025_clean

    GROUP BY
        code_insee,
        commune
)

-- Croisement avec les données du parc de logements INSEE
SELECT
    d.code_insee,
    d.commune,
    d.nombre_dpe,
    d.nombre_passoires_fg,
    d.consommation_moyenne,
    d.part_passoires_fg_pct,

    i.logements_total_2022,
    i.residences_principales_2022,
    i.maisons_2022,
    i.appartements_2022

FROM dpe_commune AS d

INNER JOIN insee_logement_2022 AS i
    ON d.code_insee = i.code_insee

ORDER BY d.part_passoires_fg_pct DESC;


-- 8. CRÉATION DE LA VUE ANALYTIQUE DPE / INSEE

-- Création d'une vue réutilisable pour les analyses
-- et pour une future exploitation dans Power BI.

CREATE OR REPLACE VIEW analyse_dpe_insee AS

SELECT
    d.code_insee,
    d.commune,

    COUNT(*) AS nombre_dpe,

    SUM(d.passoire_fg) AS nombre_passoires_fg,

    ROUND(
        AVG(d.conso_5_usages_par_m2_ep),
        2
    ) AS consommation_moyenne,

    ROUND(
        SUM(d.passoire_fg) / COUNT(*) * 100,
        2
    ) AS part_passoires_fg_pct,

    i.logements_total_2022,
    i.residences_principales_2022,
    i.residences_secondaires_occasionnelles_2022,
    i.logements_vacants_2022,
    i.maisons_2022,
    i.appartements_2022

FROM dpe_95_2024_2025_clean AS d

INNER JOIN insee_logement_2022 AS i
    ON d.code_insee = i.code_insee

GROUP BY
    d.code_insee,
    d.commune,
    i.logements_total_2022,
    i.residences_principales_2022,
    i.residences_secondaires_occasionnelles_2022,
    i.logements_vacants_2022,
    i.maisons_2022,
    i.appartements_2022;

-- Vérification de la vue
SELECT *
FROM analyse_dpe_insee;

-- Exemple d'analyse :
-- communes disposant d'au moins 500 DPE,
-- classées selon le nombre de passoires énergétiques.

SELECT *
FROM analyse_dpe_insee

WHERE nombre_dpe >= 500

ORDER BY nombre_passoires_fg DESC;


-- 9. CRÉATION DE LA VUE RGE PAR COMMUNE

-- Les données RGE contiennent plusieurs lignes pour une même
-- entreprise lorsqu'elle possède plusieurs qualifications.
--
-- Cette vue agrège une seule fois les données à l'échelle communale.
-- Elle sera ensuite réutilisée dans toutes les analyses suivantes,
-- afin d'éviter de répéter la même agrégation dans chaque requête.

CREATE OR REPLACE VIEW rge_commune AS

SELECT
    commune,
    COUNT(DISTINCT siret) AS nombre_entreprises_rge,
    COUNT(*) AS nombre_qualifications_rge

FROM rge_95_clean

GROUP BY commune;

-- Vérification de la vue.
SELECT *
FROM rge_commune
ORDER BY nombre_entreprises_rge DESC;

-- 10. CROISEMENT DPE / INSEE / RGE PAR COMMUNE

-- Croisement de la vue DPE / INSEE avec la vue RGE.
--
-- Le LEFT JOIN conserve les 183 communes,
-- y compris celles ne possédant aucune entreprise RGE recensée.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_dpe,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,
    a.consommation_moyenne,
    a.logements_total_2022,
    a.maisons_2022,
    a.appartements_2022,

    -- Les valeurs NULL deviennent 0 lorsqu'aucune entreprise
    -- ou qualification RGE n'est recensée dans la commune.
    COALESCE(r.nombre_entreprises_rge, 0) AS nombre_entreprises_rge,
    COALESCE(r.nombre_qualifications_rge, 0) AS nombre_qualifications_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

ORDER BY a.nombre_passoires_fg DESC;


-- 11. COMPTAGE DES COMMUNES SANS ENTREPRISE RGE

-- Comptage des communes DPE / INSEE ne possédant
-- aucune entreprise RGE recensée.
--
-- Résultat obtenu : 81 communes.

SELECT
    COUNT(*) AS communes_sans_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE r.nombre_entreprises_rge IS NULL;

-- 12. IDENTIFICATION DES COMMUNES SANS ENTREPRISE RGE

-- Recherche des communes sans entreprise RGE afin de comparer
-- l'absence d'offre locale avec les besoins énergétiques observés.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_dpe,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,
    a.logements_total_2022,
    a.maisons_2022,
    a.appartements_2022,

    COALESCE(r.nombre_entreprises_rge, 0) AS nombre_entreprises_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE r.nombre_entreprises_rge IS NULL

ORDER BY a.nombre_passoires_fg DESC;

-- 13. COMMUNES SANS RGE AVEC UN VOLUME DE DPE SIGNIFICATIF

-- Le seuil de 100 DPE permet d'écarter les communes disposant
-- de très peu d'observations.
--
-- Ce seuil est un choix de travail pour l'analyse
-- et non un seuil statistique officiel.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_dpe,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,
    a.logements_total_2022,
    a.maisons_2022,
    a.appartements_2022,

    COALESCE(r.nombre_entreprises_rge, 0) AS nombre_entreprises_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE a.nombre_dpe >= 100
  AND r.nombre_entreprises_rge IS NULL

ORDER BY a.nombre_passoires_fg DESC;

-- 14. AJOUT DU TAUX DE COUVERTURE DES DPE

-- Le taux de couverture compare le nombre de DPE disponibles
-- au nombre total de logements recensés par l'INSEE.
--
-- Il ne mesure pas la représentativité statistique des DPE.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_dpe,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,
    a.logements_total_2022,

    ROUND(
        a.nombre_dpe / a.logements_total_2022 * 100,
        2
    ) AS taux_couverture_dpe_pct,

    COALESCE(r.nombre_entreprises_rge, 0) AS nombre_entreprises_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE a.nombre_dpe >= 100
  AND r.nombre_entreprises_rge IS NULL

ORDER BY a.nombre_passoires_fg DESC;

-- 15. ANALYSE DE LA TENSION ENTRE BESOIN ÉNERGÉTIQUE ET OFFRE RGE

-- Analyse des communes disposant d'au moins 100 DPE.
--
-- L'objectif est de comparer :
-- - le besoin énergétique observé ;
-- - la taille du parc ;
-- - la couverture DPE ;
-- - l'offre locale RGE.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_dpe,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,
    a.logements_total_2022,

    ROUND(
        a.nombre_dpe / a.logements_total_2022 * 100,
        2
    ) AS taux_couverture_dpe_pct,

    COALESCE(r.nombre_entreprises_rge, 0) AS nombre_entreprises_rge,

    -- Indicateur comparatif de tension locale :
    -- nombre de passoires F/G observées par entreprise RGE.
    --
    -- Il ne représente pas un nombre réel de chantiers
    -- à réaliser par entreprise.

    CASE
        WHEN COALESCE(r.nombre_entreprises_rge, 0) = 0
            THEN NULL
        ELSE ROUND(
            a.nombre_passoires_fg / r.nombre_entreprises_rge,
            2
        )
    END AS passoires_fg_par_entreprise_rge,

    COALESCE(r.nombre_qualifications_rge, 0) AS nombre_qualifications_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE a.nombre_dpe >= 100

ORDER BY a.nombre_passoires_fg DESC;

-- 16. CLASSEMENT DES COMMUNES SELON LA TENSION LOCALE

-- Analyse uniquement des communes :
-- - disposant d'au moins 100 DPE ;
-- - possédant au moins une entreprise RGE.
--
-- Les territoires sont classés selon le rapport entre
-- passoires F/G observées et entreprises RGE locales.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_dpe,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,
    a.logements_total_2022,

    ROUND(
        a.nombre_dpe / a.logements_total_2022 * 100,
        2
    ) AS taux_couverture_dpe_pct,

    r.nombre_entreprises_rge,

    ROUND(
        a.nombre_passoires_fg / r.nombre_entreprises_rge,
        2
    ) AS passoires_fg_par_entreprise_rge,

    r.nombre_qualifications_rge

FROM analyse_dpe_insee AS a

INNER JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE a.nombre_dpe >= 100

ORDER BY passoires_fg_par_entreprise_rge DESC;

-- 17. REPÈRES MOYENS POUR L'ANALYSE DES COMMUNES

-- Calcul de valeurs moyennes sur les communes disposant
-- d'au moins 100 DPE.
--
-- Ces valeurs servent de repères de comparaison
-- et non de seuils réglementaires ou commerciaux officiels.

SELECT
    COUNT(*) AS nombre_communes,

    ROUND(
        AVG(a.nombre_passoires_fg),
        2
    ) AS moyenne_passoires_fg,

    ROUND(
        AVG(a.part_passoires_fg_pct),
        2
    ) AS moyenne_part_passoires_fg_pct,

    -- AVG ignore les valeurs NULL.
    -- Les communes sans entreprise RGE ne sont donc pas prises
    -- en compte dans la moyenne de tension.
    ROUND(
        AVG(
            CASE
                WHEN r.nombre_entreprises_rge IS NULL
                    THEN NULL
                ELSE
                    a.nombre_passoires_fg / r.nombre_entreprises_rge
            END
        ),
        2
    ) AS moyenne_tension_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE a.nombre_dpe >= 100;

-- 18. COMMUNES AU-DESSUS DES TROIS REPÈRES MOYENS

-- Recherche des communes présentant simultanément :
-- - plus de 93,63 passoires F/G ;
-- - plus de 8,35 % de passoires F/G ;
-- - une tension RGE supérieure à 16,91.
--
-- Résultat obtenu : 12 communes.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,

    r.nombre_entreprises_rge,

    ROUND(
        a.nombre_passoires_fg / r.nombre_entreprises_rge,
        2
    ) AS passoires_fg_par_entreprise_rge

FROM analyse_dpe_insee AS a

INNER JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE a.nombre_dpe >= 100
  AND a.nombre_passoires_fg > 93.63
  AND a.part_passoires_fg_pct > 8.35
  AND a.nombre_passoires_fg / r.nombre_entreprises_rge > 16.91

ORDER BY passoires_fg_par_entreprise_rge DESC;

-- 19. ANCIENNETÉ DU PARC DE LOGEMENTS DES COMMUNES CIBLÉES

-- Analyse de l'ancienneté du parc pour les 12 communes
-- identifiées précédemment.
--
-- La somme des périodes :
-- avant 1919 + 1919-1945 + 1946-1970
-- correspond aux résidences principales construites avant 1971.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,

    r.nombre_entreprises_rge,

    ROUND(
        a.nombre_passoires_fg / r.nombre_entreprises_rge,
        2
    ) AS passoires_fg_par_entreprise_rge,

    -- Nombre de résidences principales construites avant 1971.
    ROUND(
        i.rp_avant_1919
        + i.rp_1919_1945
        + i.rp_1946_1970,
        0
    ) AS rp_avant_1971,

    -- Part du parc de résidences principales construit avant 1971.
    ROUND(
        (
            i.rp_avant_1919
            + i.rp_1919_1945
            + i.rp_1946_1970
        )
        / i.residences_principales_2022 * 100,
        2
    ) AS part_rp_avant_1971_pct

FROM analyse_dpe_insee AS a

INNER JOIN rge_commune AS r
    ON a.commune = r.commune

INNER JOIN insee_logement_2022 AS i
    ON a.code_insee = i.code_insee

WHERE a.nombre_dpe >= 100
  AND a.nombre_passoires_fg > 93.63
  AND a.part_passoires_fg_pct > 8.35
  AND a.nombre_passoires_fg / r.nombre_entreprises_rge > 16.91

ORDER BY part_rp_avant_1971_pct DESC;

-- 20. STRUCTURE DU PARC : MAISONS / APPARTEMENTS

-- Analyse de la structure du parc des 12 communes ciblées :
-- - maisons individuelles ;
-- - appartements.
--
-- Cette distinction permet de mieux qualifier
-- le type de marché résidentiel.

SELECT
    a.code_insee,
    a.commune,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,

    r.nombre_entreprises_rge,

    ROUND(
        a.nombre_passoires_fg / r.nombre_entreprises_rge,
        2
    ) AS passoires_fg_par_entreprise_rge,

    ROUND(a.maisons_2022, 0) AS maisons_2022,

    ROUND(a.appartements_2022, 0) AS appartements_2022,

    ROUND(
        a.maisons_2022 / a.logements_total_2022 * 100,
        2
    ) AS part_maisons_pct,

    ROUND(
        a.appartements_2022 / a.logements_total_2022 * 100,
        2
    ) AS part_appartements_pct

FROM analyse_dpe_insee AS a

INNER JOIN rge_commune AS r
    ON a.commune = r.commune

WHERE a.nombre_dpe >= 100
  AND a.nombre_passoires_fg > 93.63
  AND a.part_passoires_fg_pct > 8.35
  AND a.nombre_passoires_fg / r.nombre_entreprises_rge > 16.91

ORDER BY part_maisons_pct DESC;

-- 21. ANALYSE DES DOMAINES RGE DANS LES COMMUNES CIBLÉES

-- Jusqu'à présent, l'analyse portait principalement sur le nombre
-- d'entreprises RGE présentes dans chaque commune.
--
-- Cette requête cherche maintenant à identifier les domaines
-- de compétences RGE disponibles dans les 12 communes ciblées.
--
-- L'objectif est de ne plus seulement répondre à :
-- "Combien d'entreprises RGE sont présentes ?"
--
-- mais également à :
-- "Quelles compétences RGE sont présentes localement ?"
--
-- Une entreprise pouvant posséder plusieurs qualifications,
-- le nombre de qualifications peut être supérieur au nombre
-- d'entreprises distinctes.

SELECT
    a.commune,
    r.meta_domaine,
    r.domaine,

    COUNT(DISTINCT r.siret) AS nombre_entreprises_rge,

    COUNT(*) AS nombre_qualifications_rge

FROM analyse_dpe_insee AS a

INNER JOIN rge_commune AS rc
    ON a.commune = rc.commune

INNER JOIN rge_95_clean AS r
    ON a.commune = r.commune

-- Conservation des 12 communes identifiées précédemment
-- grâce aux trois indicateurs supérieurs à la moyenne.
WHERE a.nombre_dpe >= 100
  AND a.nombre_passoires_fg > 93.63
  AND a.part_passoires_fg_pct > 8.35
  AND a.nombre_passoires_fg / rc.nombre_entreprises_rge > 16.91

GROUP BY
    a.commune,
    r.meta_domaine,
    r.domaine

ORDER BY
    a.commune,
    nombre_entreprises_rge DESC,
    nombre_qualifications_rge DESC;
    
-- ============================================================
-- 22. CRÉATION DE LA VUE FINALE D'ANALYSE TERRITORIALE
-- ============================================================

-- Cette vue rassemble les principaux indicateurs construits
-- pendant l'analyse SQL.
--
-- Elle constitue la table analytique principale qui pourra
-- ensuite être utilisée dans Power BI.
--
-- Elle regroupe :
-- - les indicateurs DPE ;
-- - les caractéristiques du parc INSEE ;
-- - l'ancienneté du parc ;
-- - la structure maisons / appartements ;
-- - l'offre RGE ;
-- - le taux de couverture DPE ;
-- - l'indicateur de tension locale.
--
-- Le LEFT JOIN avec la vue RGE permet de conserver les 183 communes,
-- y compris celles sans entreprise RGE recensée.

CREATE OR REPLACE VIEW analyse_territoriale AS

SELECT
    a.code_insee,
    a.commune,

    -- ----------------------------
    -- INDICATEURS DPE
    -- ----------------------------

    a.nombre_dpe,
    a.nombre_passoires_fg,
    a.part_passoires_fg_pct,
    a.consommation_moyenne,

    -- ----------------------------
    -- PARC DE LOGEMENTS INSEE
    -- ----------------------------

    a.logements_total_2022,
    a.residences_principales_2022,
    a.maisons_2022,
    a.appartements_2022,

    -- ----------------------------
    -- TAUX DE COUVERTURE DPE
    -- ----------------------------

    ROUND(
        a.nombre_dpe / a.logements_total_2022 * 100,
        2
    ) AS taux_couverture_dpe_pct,

    -- ----------------------------
    -- ANCIENNETÉ DU PARC
    -- ----------------------------

    ROUND(
        i.rp_avant_1919
        + i.rp_1919_1945
        + i.rp_1946_1970,
        0
    ) AS rp_avant_1971,

    ROUND(
        (
            i.rp_avant_1919
            + i.rp_1919_1945
            + i.rp_1946_1970
        )
        / i.residences_principales_2022 * 100,
        2
    ) AS part_rp_avant_1971_pct,

    -- ----------------------------
    -- STRUCTURE MAISONS / APPARTEMENTS
    -- ----------------------------

    ROUND(
        a.maisons_2022 / a.logements_total_2022 * 100,
        2
    ) AS part_maisons_pct,

    ROUND(
        a.appartements_2022 / a.logements_total_2022 * 100,
        2
    ) AS part_appartements_pct,

    -- ----------------------------
    -- OFFRE RGE
    -- ----------------------------

    COALESCE(
        r.nombre_entreprises_rge,
        0
    ) AS nombre_entreprises_rge,

    COALESCE(
        r.nombre_qualifications_rge,
        0
    ) AS nombre_qualifications_rge,

    -- ----------------------------
    -- INDICATEUR DE TENSION LOCALE
    -- ----------------------------

    -- Nombre de passoires F/G observées par entreprise RGE.
    --
    -- NULL lorsqu'aucune entreprise RGE n'est présente,
    -- car une division par zéro n'aurait pas de sens.
    --
    -- Cet indicateur est comparatif :
    -- il ne représente pas un nombre réel de chantiers.

    CASE
        WHEN COALESCE(r.nombre_entreprises_rge, 0) = 0
            THEN NULL

        ELSE ROUND(
            a.nombre_passoires_fg / r.nombre_entreprises_rge,
            2
        )
    END AS tension_rge

FROM analyse_dpe_insee AS a

LEFT JOIN rge_commune AS r
    ON a.commune = r.commune

INNER JOIN insee_logement_2022 AS i
    ON a.code_insee = i.code_insee;


-- 23. CONTRÔLE FINAL ET EXTRACTION DES COMMUNES CIBLÉES

-- Dernier contrôle de la vue avant son exploitation dans Power BI.

-- On vérifie notamment :
-- - le nombre total de communes ;
-- - le nombre de communes avec au moins 100 DPE ;
-- - le nombre de communes sans entreprise RGE ;
-- - le nombre de communes correspondant aux critères
--   de ciblage utilisés pendant l'analyse.

SELECT
    COUNT(*) AS nombre_total_communes,

    SUM(
        CASE
            WHEN nombre_dpe >= 100
                THEN 1
            ELSE 0
        END
    ) AS communes_avec_100_dpe,

    SUM(
        CASE
            WHEN nombre_entreprises_rge = 0
                THEN 1
            ELSE 0
        END
    ) AS communes_sans_rge,

    SUM(
        CASE
            WHEN nombre_dpe >= 100
             AND nombre_passoires_fg > 93.63
             AND part_passoires_fg_pct > 8.35
             AND tension_rge > 16.91
                THEN 1
            ELSE 0
        END
    ) AS communes_ciblees

FROM analyse_territoriale;


-- EXTRACTION DE LA SHORT-LIST FINALE ISSUE DE L'ANALYSE SQL

-- Affichage des communes qui dépassent simultanément
-- les trois repères moyens utilisés pendant l'analyse.
--
-- Cette short-list constitue une première sélection analytique.
-- Elle ne représente pas encore un classement commercial définitif :
-- Power BI et les autres sources permettront de confirmer,
-- compléter ou nuancer ces résultats.

SELECT
    commune,
    nombre_dpe,
    nombre_passoires_fg,
    part_passoires_fg_pct,
    taux_couverture_dpe_pct,
    part_rp_avant_1971_pct,
    part_maisons_pct,
    part_appartements_pct,
    nombre_entreprises_rge,
    tension_rge

FROM analyse_territoriale

WHERE nombre_dpe >= 100
  AND nombre_passoires_fg > 93.63
  AND part_passoires_fg_pct > 8.35
  AND tension_rge > 16.91

ORDER BY tension_rge DESC;
   
