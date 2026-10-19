-- MAINTENANCE ET QUALITÉ DES DONNÉES
-- Sélectionner renovation_energetique comme schéma actif dans Workbench.
-- Utiliser uniquement les blocs nécessaires ; ne pas exécuter tout le fichier.
-- Instructions SQL du fichier de base conservées sans modification.

-- 1. TRAITEMENT DE LA SURFACE HABITABLE

-- La colonne a été importée en TEXT afin de gérer les valeurs
-- manquantes avant sa conversion en type numérique.

-- Recherche des surfaces NULL ou vides
SELECT COUNT(*) AS surfaces_vides
FROM dpe_95_2024_2025_clean
WHERE surface_habitable_logement IS NULL
   OR TRIM(surface_habitable_logement) = '';

-- Désactivation temporaire du mode Safe Updates
SET SQL_SAFE_UPDATES = 0;

-- Remplacement des chaînes vides par NULL
UPDATE dpe_95_2024_2025_clean
SET surface_habitable_logement = NULL
WHERE TRIM(surface_habitable_logement) = '';

-- Réactivation du mode Safe Updates
SET SQL_SAFE_UPDATES = 1;

-- Vérification du nombre de valeurs NULL
SELECT COUNT(*) AS valeurs_null
FROM dpe_95_2024_2025_clean
WHERE surface_habitable_logement IS NULL;

-- Conversion de la surface habitable en valeur numérique
ALTER TABLE dpe_95_2024_2025_clean
MODIFY surface_habitable_logement DOUBLE;

-- Contrôle du nouveau type de la colonne
SHOW COLUMNS
FROM dpe_95_2024_2025_clean
LIKE 'surface_habitable_logement';

-- 2. VÉRIFICATION DES EFFECTIFS RGE
-- Recontrôler le nombre de lignes, de SIRET distincts et de communes.
-- Un SIRET identifie un établissement, qui peut avoir plusieurs qualifications.
-- Les noms des colonnes SQL sont conservés pour maintenir les connexions existantes.

   SELECT
    COUNT(*) AS nombre_lignes,
    COUNT(DISTINCT siret) AS nombre_entreprises,
    COUNT(DISTINCT commune) AS nombre_communes
FROM rge_95_clean;

-- 3. CONTRÔLE DES CORRESPONDANCES ENTRE COMMUNES RGE ET DPE
-- Afficher les communes RGE sans correspondance dans la table DPE.
-- Une ligne retournée peut signaler une différence de libellé.
-- Un résultat vide indique que tous les libellés RGE trouvent une correspondance.

SELECT DISTINCT r.commune
FROM rge_95_clean AS r

LEFT JOIN (
    SELECT DISTINCT commune
    FROM dpe_95_2024_2025_clean
) AS d
    ON r.commune = d.commune

WHERE d.commune IS NULL;

-- 4. REPÉRAGE DES CARACTÈRES SUSPECTS DANS LES DONNÉES RGE
-- Compter, par colonne, les valeurs contenant les séquences recherchées.
-- HEX affiche les octets du texte sous forme hexadécimale.
-- C383 et C382 peuvent signaler des caractères mal décodés.
-- Ce contrôle est indicatif : il ne détecte pas toutes les anomalies
-- et une correspondance ne prouve pas à elle seule une erreur.
-- UNION ALL rassemble les résultats des différentes colonnes.

SELECT 'nom_entreprise' AS colonne,
       SUM(CASE WHEN HEX(nom_entreprise) LIKE '%C383%'
                     OR HEX(nom_entreprise) LIKE '%C382%'
                THEN 1 ELSE 0 END) AS anomalies
FROM rge_95_clean

UNION ALL

SELECT 'adresse',
       SUM(CASE WHEN HEX(adresse) LIKE '%C383%'
                     OR HEX(adresse) LIKE '%C382%'
                THEN 1 ELSE 0 END)
FROM rge_95_clean

UNION ALL

SELECT 'commune',
       SUM(CASE WHEN HEX(commune) LIKE '%C383%'
                     OR HEX(commune) LIKE '%C382%'
                THEN 1 ELSE 0 END)
FROM rge_95_clean

UNION ALL

SELECT 'code_qualification',
       SUM(CASE WHEN HEX(code_qualification) LIKE '%C383%'
                     OR HEX(code_qualification) LIKE '%C382%'
                THEN 1 ELSE 0 END)
FROM rge_95_clean

UNION ALL

SELECT 'nom_qualification',
       SUM(CASE WHEN HEX(nom_qualification) LIKE '%C383%'
                     OR HEX(nom_qualification) LIKE '%C382%'
                THEN 1 ELSE 0 END)
FROM rge_95_clean

UNION ALL

SELECT 'domaine',
       SUM(CASE WHEN HEX(domaine) LIKE '%C383%'
                     OR HEX(domaine) LIKE '%C382%'
                THEN 1 ELSE 0 END)
FROM rge_95_clean

UNION ALL

SELECT 'meta_domaine',
       SUM(CASE WHEN HEX(meta_domaine) LIKE '%C383%'
                     OR HEX(meta_domaine) LIKE '%C382%'
                THEN 1 ELSE 0 END)
FROM rge_95_clean

UNION ALL

SELECT 'organisme',
       SUM(CASE WHEN HEX(organisme) LIKE '%C383%'
                     OR HEX(organisme) LIKE '%C382%'
                THEN 1 ELSE 0 END)
FROM rge_95_clean;

-- 5. CORRECTION CIBLÉE DE L'ENCODAGE RGE
-- Traitement de maintenance : cette requête modifie les données.
-- À utiliser après vérification des valeurs suspectes et sauvegarde de la table.
--
-- La conversion réinterprète les octets pour corriger le mauvais décodage
-- identifié lors de la préparation des données.
-- CASE conserve les autres valeurs ; WHERE limite les lignes traitées.
-- Les colonnes commune et code_qualification, contrôlées précédemment,
-- ne sont pas modifiées par cette requête.
--
-- Le mode Safe Updates est désactivé pour cette opération,
-- puis réactivé immédiatement après.

SET SQL_SAFE_UPDATES = 0;

UPDATE rge_95_clean
SET

    nom_entreprise = CASE
        WHEN HEX(nom_entreprise) LIKE '%C383%'
          OR HEX(nom_entreprise) LIKE '%C382%'
        THEN CONVERT(
            CAST(CONVERT(nom_entreprise USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE nom_entreprise
    END,

    adresse = CASE
        WHEN HEX(adresse) LIKE '%C383%'
          OR HEX(adresse) LIKE '%C382%'
        THEN CONVERT(
            CAST(CONVERT(adresse USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE adresse
    END,

    nom_qualification = CASE
        WHEN HEX(nom_qualification) LIKE '%C383%'
          OR HEX(nom_qualification) LIKE '%C382%'
        THEN CONVERT(
            CAST(CONVERT(nom_qualification USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE nom_qualification
    END,

    domaine = CASE
        WHEN HEX(domaine) LIKE '%C383%'
          OR HEX(domaine) LIKE '%C382%'
        THEN CONVERT(
            CAST(CONVERT(domaine USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE domaine
    END,

    meta_domaine = CASE
        WHEN HEX(meta_domaine) LIKE '%C383%'
          OR HEX(meta_domaine) LIKE '%C382%'
        THEN CONVERT(
            CAST(CONVERT(meta_domaine USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE meta_domaine
    END,

    organisme = CASE
        WHEN HEX(organisme) LIKE '%C383%'
          OR HEX(organisme) LIKE '%C382%'
        THEN CONVERT(
            CAST(CONVERT(organisme USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE organisme
    END

WHERE
       HEX(nom_entreprise) LIKE '%C383%'
    OR HEX(nom_entreprise) LIKE '%C382%'
    OR HEX(adresse) LIKE '%C383%'
    OR HEX(adresse) LIKE '%C382%'
    OR HEX(nom_qualification) LIKE '%C383%'
    OR HEX(nom_qualification) LIKE '%C382%'
    OR HEX(domaine) LIKE '%C383%'
    OR HEX(domaine) LIKE '%C382%'
    OR HEX(meta_domaine) LIKE '%C383%'
    OR HEX(meta_domaine) LIKE '%C382%'
    OR HEX(organisme) LIKE '%C383%'
    OR HEX(organisme) LIKE '%C382%';

SET SQL_SAFE_UPDATES = 1;

-- 6. REPÉRAGE DES CARACTÈRES SUSPECTS DANS LES DONNÉES DPE
-- Compter les valeurs contenant la séquence C383 dans les colonnes textuelles.
-- Le résultat sert à repérer les champs à examiner avant correction.
-- Ce contrôle ne constitue pas une vérification exhaustive de l'encodage.

SELECT 'type_batiment' AS colonne,
       SUM(CASE WHEN HEX(type_batiment) LIKE '%C383%' THEN 1 ELSE 0 END) AS anomalies
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'periode_construction',
       SUM(CASE WHEN HEX(periode_construction) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'commune',
       SUM(CASE WHEN HEX(commune) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'qualite_isolation_enveloppe',
       SUM(CASE WHEN HEX(qualite_isolation_enveloppe) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'qualite_isolation_murs',
       SUM(CASE WHEN HEX(qualite_isolation_murs) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'qualite_isolation_menuiseries',
       SUM(CASE WHEN HEX(qualite_isolation_menuiseries) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'qualite_isolation_plancher_bas',
       SUM(CASE WHEN HEX(qualite_isolation_plancher_bas) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'type_energie_principale_chauffage',
       SUM(CASE WHEN HEX(type_energie_principale_chauffage) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean

UNION ALL

SELECT 'type_ventilation',
       SUM(CASE WHEN HEX(type_ventilation) LIKE '%C383%' THEN 1 ELSE 0 END)
FROM dpe_95_2024_2025_clean;

-- 7. CORRECTION CIBLÉE DE L'ENCODAGE DPE
-- Traitement de maintenance : cette requête modifie les données.
-- Appliquer uniquement à l'anomalie d'encodage préalablement identifiée.
-- CASE conserve les valeurs non concernées.
-- La colonne type_batiment est contrôlée précédemment,
-- mais n'est pas modifiée dans cette requête.
-- Après traitement, relancer le contrôle de l'étape 29.

SET SQL_SAFE_UPDATES = 0;

UPDATE dpe_95_2024_2025_clean
SET
    periode_construction = CASE
        WHEN HEX(periode_construction) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(periode_construction USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE periode_construction
    END,

    commune = CASE
        WHEN HEX(commune) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(commune USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE commune
    END,

    qualite_isolation_enveloppe = CASE
        WHEN HEX(qualite_isolation_enveloppe) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(qualite_isolation_enveloppe USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE qualite_isolation_enveloppe
    END,

    qualite_isolation_murs = CASE
        WHEN HEX(qualite_isolation_murs) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(qualite_isolation_murs USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE qualite_isolation_murs
    END,

    qualite_isolation_menuiseries = CASE
        WHEN HEX(qualite_isolation_menuiseries) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(qualite_isolation_menuiseries USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE qualite_isolation_menuiseries
    END,

    qualite_isolation_plancher_bas = CASE
        WHEN HEX(qualite_isolation_plancher_bas) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(qualite_isolation_plancher_bas USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE qualite_isolation_plancher_bas
    END,

    type_energie_principale_chauffage = CASE
        WHEN HEX(type_energie_principale_chauffage) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(type_energie_principale_chauffage USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE type_energie_principale_chauffage
    END,

    type_ventilation = CASE
        WHEN HEX(type_ventilation) LIKE '%C383%'
        THEN CONVERT(
            CAST(CONVERT(type_ventilation USING latin1) AS BINARY)
            USING utf8mb4
        )
        ELSE type_ventilation
    END

WHERE
       HEX(periode_construction) LIKE '%C383%'
    OR HEX(commune) LIKE '%C383%'
    OR HEX(qualite_isolation_enveloppe) LIKE '%C383%'
    OR HEX(qualite_isolation_murs) LIKE '%C383%'
    OR HEX(qualite_isolation_menuiseries) LIKE '%C383%'
    OR HEX(qualite_isolation_plancher_bas) LIKE '%C383%'
    OR HEX(type_energie_principale_chauffage) LIKE '%C383%'
    OR HEX(type_ventilation) LIKE '%C383%';

SET SQL_SAFE_UPDATES = 1;

-- 8. CONTRÔLE DE LA STRUCTURE ET DES EFFECTIFS APRÈS TRAITEMENT
-- Vérifier les types de colonnes, le nombre de diagnostics
-- et le nombre de codes INSEE distincts.
-- Une correction de texte ne doit pas supprimer de lignes.

DESCRIBE dpe_95_2024_2025_clean;

SELECT COUNT(*) AS nombre_lignes
FROM dpe_95_2024_2025_clean;
SELECT COUNT(DISTINCT code_insee) AS nombre_communes
FROM dpe_95_2024_2025_clean;

-- 9. CONTRÔLE DES LIBELLÉS D'ISOLATION
-- Afficher les catégories et leurs effectifs après correction.
-- Vérifier la lisibilité et repérer d'éventuelles variantes
-- qui sépareraient une même catégorie dans Power BI.

SELECT
    qualite_isolation_enveloppe,
    COUNT(*) AS nombre
FROM dpe_95_2024_2025_clean
GROUP BY qualite_isolation_enveloppe
ORDER BY nombre DESC;

-- 10. CONSULTATION DE LA DÉFINITION DE LA TABLE
-- Afficher la commande de création : colonnes, types,
-- index et paramètres d'encodage.
-- Cette commande consulte la structure sans recréer la table.
SHOW CREATE TABLE dpe_95_2024_2025_clean;

-- 11. CONTRÔLE DE LA VUE FINALE
-- Vérifier le nombre de lignes de la vue analytique.
-- Résultat de référence : 183 lignes.
-- Le contrôle d'unicité du code INSEE confirme une ligne par commune.

SELECT
    TABLE_NAME,
    VIEW_DEFINITION
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'renovation_energetique'
  AND VIEW_DEFINITION LIKE '%dpe_95_2024_2025_clean%';
  
SELECT COUNT(*) AS nombre_lignes
FROM analyse_territoriale;

-- 12. EXAMEN D'UN CARACTÈRE SUSPECT DANS LES LIBELLÉS DE CHAUFFAGE
-- Afficher les valeurs contenant â et leur représentation hexadécimale.
-- Vérifier le texte avant toute correction :
-- la présence de ce caractère ne prouve pas une anomalie.
SELECT DISTINCT
    type_energie_principale_chauffage,
    HEX(type_energie_principale_chauffage) AS encodage
FROM dpe_95_2024_2025_clean
WHERE type_energie_principale_chauffage LIKE '%â%';

