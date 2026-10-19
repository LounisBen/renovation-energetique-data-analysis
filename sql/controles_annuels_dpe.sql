-- CONTRÔLES TEMPORELS DES DPE
-- Source : renovation_energetique_base.sql ; instructions SQL inchangées.
-- Comparaisons annuelles, export pour Python et contrôle mensuel.
-- Requêtes en lecture seule ; la vue analyse_territoriale doit exister.

-- 1. COMPARAISON DES VOLUMES ET DES PARTS DE F/G PAR ANNÉE
-- Séparer 2024 et 2025 pour contextualiser les résultats cumulés.
-- YEAR extrait l'année de la date d'établissement du DPE.
-- La part de F/G est calculée parmi les diagnostics de chaque année,
-- et non parmi tous les logements du département.
-- Cette comparaison ne mesure pas directement l'évolution du parc.
SELECT
    YEAR(date_etablissement_dpe) AS annee,

    -- Tous les diagnostics de l’année
    COUNT(*) AS nombre_dpe,

    -- Diagnostics classés F ou G
    SUM(
        CASE WHEN etiquette_dpe IN ('F', 'G')
             THEN 1 ELSE 0 END
    ) AS nombre_fg,

    -- Part des F/G parmi les diagnostics de l’année
    ROUND(
        100.0 * SUM(
            CASE WHEN etiquette_dpe IN ('F', 'G')
                 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS part_fg_pct

FROM renovation_energetique.dpe_95_2024_2025_clean

GROUP BY YEAR(date_etablissement_dpe)
ORDER BY annee;

-- 2. PRÉPARATION DU CONTRÔLE STATISTIQUE ANNUEL
-- Produire une ligne par commune et par année.
-- Recalculer la part de F/G annuelle et ajouter l'ancienneté INSEE,
-- identique pour les deux années.
-- INNER JOIN conserve les codes présents dans la vue analyse_territoriale.
--
-- Export du résultat : controle_dpe_par_annee.csv
-- Utilisation : notebook controle_annuel_dpe.ipynb.
-- Le coefficient de Spearman sera calculé dans Python, pas ici.
SELECT
    YEAR(d.date_etablissement_dpe) AS annee,
    d.code_insee,
    d.commune,

    COUNT(*) AS nombre_dpe,

    ROUND(
        100.0 * SUM(
            CASE WHEN d.etiquette_dpe IN ('F', 'G')
                 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS part_fg_pct,

    a.part_rp_avant_1971_pct

FROM renovation_energetique.dpe_95_2024_2025_clean AS d

INNER JOIN renovation_energetique.analyse_territoriale AS a
    ON d.code_insee = a.code_insee

GROUP BY
    YEAR(d.date_etablissement_dpe),
    d.code_insee,
    d.commune,
    a.part_rp_avant_1971_pct

ORDER BY annee, d.code_insee;

-- 3. CONTRÔLE DES PÉRIODES DISPONIBLES
-- Compter les diagnostics par mois et afficher les dates extrêmes.
-- Vérifier la présence des douze mois de chaque année.
-- La présence de tous les mois ne garantit pas l'exhaustivité de la collecte.
SELECT
    YEAR(date_etablissement_dpe) AS annee,
    MONTH(date_etablissement_dpe) AS mois,
    COUNT(*) AS nombre_dpe,
    MIN(date_etablissement_dpe) AS premiere_date,
    MAX(date_etablissement_dpe) AS derniere_date

FROM renovation_energetique.dpe_95_2024_2025_clean

GROUP BY
    YEAR(date_etablissement_dpe),
    MONTH(date_etablissement_dpe)

ORDER BY annee, mois;