-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
-- 4,458
(SELECT npi
FROM prescriber)
EXCEPT
(SELECT npi
FROM prescription);


-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
-- Potassium Chloride (510,315)
-- Levothyroxine Sodium (380,865)
-- Lisinopril (311,494)
-- Atorvastatin Calcium (308,512)
-- Amlodipine Besylate (304,319)


--1,195 Distinct Rows
SELECT DISTINCT drug_name, SUM(total_claim_count) AS claim_count
FROM 
		(	SELECT p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
		 	FROM 
				(SELECT specialty_description, npi
				FROM prescriber
				WHERE specialty_description = 'Family Practice') AS p1

				LEFT JOIN

				prescription AS p2
				ON p1.npi=p2.npi

				LEFT JOIN

				drug AS d1
				ON p2.drug_name = d1.drug_name
			GROUP BY p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
		) AS t1
WHERE drug_name IS NOT NULL AND total_claim_count IS NOT NULL
GROUP BY drug_name
ORDER BY claim_count DESC
LIMIT 5;

-- 1,195 Distinct Drug Names
SELECT COUNT(DISTINCT drug_name)
FROM 
		(	SELECT p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
		 	FROM 
				(SELECT specialty_description, npi
				FROM prescriber
				WHERE specialty_description = 'Family Practice') AS p1

				LEFT JOIN

				(SELECT npi, total_claim_count, drug_name
				FROM prescription) AS p2
				ON p1.npi=p2.npi

				LEFT JOIN

				(SELECT drug_name, generic_name
				FROM drug) AS d1
				ON p2.drug_name = d1.drug_name
			GROUP BY p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
		) AS t1
WHERE drug_name IS NOT NULL AND total_claim_count IS NOT NULL




--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
-- Atorvastatin Calcium (120,640)
-- Potassium Chloride (112,536)
-- Carvedilol (106,787)
-- Metoprolol Tartrate (93,940)
-- Clodipogrel (86,971)



SELECT DISTINCT drug_name, SUM(total_claim_count) AS claim_count
FROM 
		(	SELECT p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
		 	FROM 
				(SELECT specialty_description, npi
				FROM prescriber
				WHERE specialty_description = 'Cardiology') AS p1

				LEFT JOIN

				(SELECT npi, total_claim_count, drug_name
				FROM prescription) AS p2
				ON p1.npi=p2.npi

				LEFT JOIN

				(SELECT drug_name, generic_name
				FROM drug) AS d1
				ON p2.drug_name = d1.drug_name
			GROUP BY p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
		) AS t1
WHERE drug_name IS NOT NULL AND total_claim_count IS NOT NULL
GROUP BY drug_name
ORDER BY claim_count DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT drug_name
FROM 
		(SELECT DISTINCT drug_name, SUM(total_claim_count) AS claim_count
		FROM 
				(	SELECT p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
					FROM 
						(SELECT specialty_description, npi
						FROM prescriber
						WHERE specialty_description = 'Family Practice') AS p1

						LEFT JOIN

						(SELECT npi, total_claim_count, drug_name
						FROM prescription) AS p2
						ON p1.npi=p2.npi

						LEFT JOIN

						(SELECT drug_name, generic_name
						FROM drug) AS d1
						ON p2.drug_name = d1.drug_name
					GROUP BY p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
				) AS t1
		WHERE drug_name IS NOT NULL AND total_claim_count IS NOT NULL
		GROUP BY drug_name
		ORDER BY claim_count DESC
		LIMIT 5) AS FP_top_drugs

INTERSECT

SELECT drug_name
FROM 
			(SELECT DISTINCT drug_name, SUM(total_claim_count) AS claim_count
			FROM 
					(	SELECT p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
						FROM 
							(SELECT specialty_description, npi
							FROM prescriber
							WHERE specialty_description = 'Cardiology') AS p1

							LEFT JOIN

							(SELECT npi, total_claim_count, drug_name
							FROM prescription) AS p2
							ON p1.npi=p2.npi

							LEFT JOIN

							(SELECT drug_name, generic_name
							FROM drug) AS d1
							ON p2.drug_name = d1.drug_name
						GROUP BY p1.specialty_description, p1.npi, p2.total_claim_count, p2.drug_name, d1.generic_name
					) AS t1
			WHERE drug_name IS NOT NULL AND total_claim_count IS NOT NULL
			GROUP BY drug_name
			ORDER BY claim_count DESC
			LIMIT 5) AS c_top_drugs;




-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
-- 1538103692 (53,622)
-- 1497893556 (29,929)
-- 1659331924 (26,013)
-- 1881638971 (25,511)
-- 1962499582 (23,703)


SELECT	p1.npi, p1.nppes_provider_city, p2.claim_count
FROM 	((SELECT DISTINCT npi, nppes_provider_city
		 FROM prescriber) AS p1

			LEFT JOIN

		(SELECT npi, SUM(total_claim_count) AS claim_count
		FROM prescription
		GROUP BY npi
		ORDER BY npi) AS p2
		ON p1.npi = p2.npi)
WHERE p1.nppes_provider_city ILIKE 'Nashville' AND claim_count IS NOT NULL
ORDER BY p2.claim_count DESC
LIMIT 5
;

--     b. Now, report the same for Memphis.

SELECT	p1.npi, p1.nppes_provider_city, p2.claim_count
FROM 	((SELECT DISTINCT npi, nppes_provider_city
		 FROM prescriber) AS p1

			LEFT JOIN

		(SELECT npi, SUM(total_claim_count) AS claim_count
		FROM prescription
		GROUP BY npi
		ORDER BY npi) AS p2
		ON p1.npi = p2.npi)
WHERE p1.nppes_provider_city ILIKE 'Memphis' AND claim_count IS NOT NULL
ORDER BY p2.claim_count DESC
LIMIT 5
;
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

-- Nashville 
(SELECT	p1.npi, p1.nppes_provider_city, p2.claim_count
FROM 	((SELECT DISTINCT npi, nppes_provider_city
		 FROM prescriber) AS p1

			LEFT JOIN

		(SELECT npi, SUM(total_claim_count) AS claim_count
		FROM prescription
		GROUP BY npi
		ORDER BY npi) AS p2
		ON p1.npi = p2.npi)
WHERE p1.nppes_provider_city ILIKE 'Nashville' AND claim_count IS NOT NULL
ORDER BY p2.claim_count DESC
LIMIT 5)

UNION

-- Memphis
(SELECT	p1.npi, p1.nppes_provider_city, p2.claim_count
FROM 	((SELECT DISTINCT npi, nppes_provider_city
		 FROM prescriber) AS p1

			LEFT JOIN

		(SELECT npi, SUM(total_claim_count) AS claim_count
		FROM prescription
		GROUP BY npi
		ORDER BY npi) AS p2
		ON p1.npi = p2.npi)
WHERE p1.nppes_provider_city ILIKE 'Memphis' AND claim_count IS NOT NULL
ORDER BY p2.claim_count DESC
LIMIT 5)

UNION 

-- Knoxville 
(SELECT	p1.npi, p1.nppes_provider_city, p2.claim_count
FROM 	((SELECT DISTINCT npi, nppes_provider_city
		 FROM prescriber) AS p1

			LEFT JOIN

		(SELECT npi, SUM(total_claim_count) AS claim_count
		FROM prescription
		GROUP BY npi
		ORDER BY npi) AS p2
		ON p1.npi = p2.npi)
WHERE p1.nppes_provider_city ILIKE 'Knoxville' AND claim_count IS NOT NULL
ORDER BY p2.claim_count DESC
LIMIT 5)

UNION

-- Chattanooga 
(SELECT	p1.npi, p1.nppes_provider_city, p2.claim_count
FROM 	((SELECT DISTINCT npi, nppes_provider_city
		 FROM prescriber) AS p1

			LEFT JOIN

		(SELECT npi, SUM(total_claim_count) AS claim_count
		FROM prescription
		GROUP BY npi
		ORDER BY npi) AS p2
		ON p1.npi = p2.npi)
WHERE p1.nppes_provider_city ILIKE 'Chattanooga' AND claim_count IS NOT NULL
ORDER BY p2.claim_count DESC
LIMIT 5)

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT fip.county, above_avg_deaths.deaths
FROM 
		(SELECT *
		FROM overdoses AS od
		GROUP BY od.fipscounty, deaths, suppressed
		HAVING deaths > (SELECT AVG(deaths) FROM overdoses)) AS above_avg_deaths

		LEFT JOIN

		(SELECT * FROM fips_county) AS fip
		ON above_avg_deaths.fipscounty = fip.fipscounty
ORDER BY deaths DESC;



-- 5.
--     a. Write a query that finds the total population of Tennessee.
-- 		6,597,381
SELECT f1.state, SUM(p1.population)
FROM 

		(SELECT fipscounty, population
		FROM population) AS p1

		LEFT JOIN

		(SELECT fipscounty, state
		FROM fips_county) AS f1

		ON p1.fipscounty = f1.fipscounty
GROUP BY f1.state;
    
--     b. Build off of the query that you wrote in part a to write a query that returns for
-- each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.


SELECT f1.county, p1.population,
		ROUND(p1.population / (SELECT SUM(p1.population)
							FROM 

								(SELECT fipscounty, population
								FROM population) AS p1

							LEFT JOIN

								(SELECT fipscounty, state
								FROM fips_county) AS f1

							ON p1.fipscounty = f1.fipscounty)*100,2) AS percent_of_TN

FROM 

		(SELECT fipscounty, population
		FROM population) AS p1

		LEFT JOIN

		(SELECT fipscounty, county, state
		FROM fips_county) AS f1

		ON p1.fipscounty = f1.fipscounty
		
ORDER BY percent_of_TN DESC
	