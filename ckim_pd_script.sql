SELECT *
FROM cbsa;


-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
    
--		NPI 1881634483 had 99,707 claims

SELECT npi, SUM(total_claim_count) as total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 10;

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

-- BRUCE PENDLEY, Family Practice, 99,707

SELECT nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, SUM(total_claim_count) as total_claims
FROM prescription AS p1
	LEFT JOIN prescriber AS p2
	USING(npi)
GROUP BY p1.npi, nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description
ORDER BY total_claims DESC
LIMIT 10;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
--		Family Practice 9,752,347

SELECT specialty_description, SUM(total_claim_count) as total_claims
FROM prescription AS p1
	LEFT JOIN prescriber AS p2
	USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 10;

--     b. Which specialty had the most total number of claims for opioids?
--		Nurse Practitioners had 900,845 claims for opiods

SELECT specialty_description, SUM(total_claim_count) as total_claims
FROM prescription AS p1
	LEFT JOIN prescriber AS p2
	USING(npi)
	LEFT JOIN drug AS d
	USING(drug_name)
WHERE opioid_drug_flag LIKE 'Y'	
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 10;


SELECT *
FROM drug
LIMIT 10;

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
--		RECHECK THIS QUESTION 
SELECT specialty_description, SUM(total_claim_count) as total_claims
FROM prescription AS p1
	LEFT JOIN prescriber AS p2
	USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) = 0;

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!*
--		For each specialty, report the percentage of total claims by that specialty which are for opioids.
--		Which specialties have a high percentage of opioids?
-- Case Manager/Care Coordinater (72%)
-- Orthopaedic Surgery (68.98%)
-- Interventional Pain Management (60.89%)
-- Pain Management (59.42%)
-- Anesthesiology (59.32%)

-- The Short Way
SELECT specialty_description,
		-- opioid claims / total claims
		COALESCE(ROUND((SUM(
		CASE WHEN drug_name IN 
			(SELECT drug_name
			FROM drug
			WHERE opioid_drug_flag = 'Y') THEN total_claim_count END)
			/
		SUM (total_claim_count))*100,2),0) AS percent_opioid_claim
FROM prescriber AS p_ber
	LEFT JOIN
	prescription AS p_tion
	USING (npi)
GROUP BY specialty_description
ORDER BY percent_opioid_claim DESC;




-- The Long Way
SELECT all_claims.specialty_description, COALESCE(ROUND((opioid_claims.claim_count_opioid / all_claims.claim_count_all)*100,2),0) AS percent_opioid
FROM	-- speciality_description, claim_count ALL
		(SELECT	specialty_description,
		COALESCE(SUM(total_claim_count),0) AS claim_count_all
		FROM 
		 	(SELECT specialty_description, npi
			FROM prescriber) AS p_ber
		LEFT JOIN
		 	(SELECT npi, total_claim_count
			FROM prescription) AS p_tion
		ON p_ber.npi = p_tion.npi
		GROUP BY specialty_description) AS all_claims
LEFT JOIN --specialty_description, claim_count WHERE opioid = Y
		(SELECT specialty_description, COALESCE(SUM(total_claim_count),0) AS claim_count_opioid
		FROM 	(SELECT specialty_description, npi
				FROM prescriber) AS p_ber
		LEFT JOIN
		 		(SELECT npi, drug_name, total_claim_count
				FROM prescription) AS p_tion
		ON p_ber.npi = p_tion.npi
		LEFT JOIN
		 		(SELECT drug_name, opioid_drug_flag
				FROM drug) AS d
		ON p_tion.drug_name = d.drug_name
		WHERE opioid_drug_flag = 'Y'
		GROUP BY specialty_description, opioid_drug_flag
		ORDER BY specialty_description) AS opioid_claims
ON all_claims.specialty_description = opioid_claims.specialty_description
ORDER BY percent_opioid DESC;







-- opioid_flag
SELECT drug_name
FROM drug
WHERE opioid_drug_flag = 'Y';

-- speciality_description, claim_count ALL
SELECT	specialty_description,
		COALESCE(SUM(total_claim_count),0) AS claim_count_all
FROM 	(SELECT specialty_description, npi
		FROM prescriber) AS p_ber
	LEFT JOIN	(SELECT npi, total_claim_count
				FROM prescription) AS p_tion
	ON p_ber.npi = p_tion.npi
GROUP BY specialty_description;

--specialty_description, claim_count WHERE opioid = Y
SELECT specialty_description, COALESCE(SUM(total_claim_count),0) AS claim_count_opioid
FROM 	(SELECT specialty_description, npi
		FROM prescriber) AS p_ber
	LEFT JOIN	(SELECT npi, drug_name, total_claim_count
				FROM prescription) AS p_tion
	ON p_ber.npi = p_tion.npi
	LEFT JOIN	(SELECT drug_name, opioid_drug_flag
				FROM drug) AS d
	ON p_tion.drug_name = d.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY specialty_description;
	
	
	

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
-- INSULIN GLARGINE, HUM.REC.ANLOG $104,264,066.35

SELECT generic_name, SUM(total_drug_cost::money)
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
GROUP BY generic_name
ORDER BY SUM(total_drug_cost::money) DESC
LIMIT 10;



--     b. Which drug (generic_name) has the hightest total cost per day?
--		**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
-- 		C1 ESTERASE INHIBITOR $3,495.22 / day

SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS total_cost_per_day
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC
LIMIT 10;

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type'
-- 		which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs
-- 		which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
		CASE	WHEN opioid_drug_flag LIKE 'Y' THEN 'opioid'
				WHEN antibiotic_drug_flag LIKE 'Y' THEN 'antibiotic'
				ELSE 'neither' END AS drug_type
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
ORDER BY drug_type;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost)
--		on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
--		Opioid sum_total_drug_cost = 105,080,626.37 and Antibiotic sum_total_drug_cost = 38,435,121.26

SELECT 
		CASE	WHEN opioid_drug_flag LIKE 'Y' THEN 'opioid'
				WHEN antibiotic_drug_flag LIKE 'Y' THEN 'antibiotic'
				ELSE 'neither' END AS drug_type,
		SUM(total_drug_cost::text::money) AS sum_total_drug_cost
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
GROUP BY drug_type
ORDER BY SUM(total_drug_cost::text::money) DESC;

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
--		There are 10 distinct CBSAs in TN
SELECT COUNT(DISTINCT cbsa) AS TN_CBSA_Count
FROM cbsa
	LEFT JOIN fips_county
	USING(fipscounty)
WHERE state LIKE 'TN';


--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--		Largest - Nashville-Davidson-Murfreesboro--Franklin,TN 1,830,410
--		Smallest - Morristown, TN with a population of 116,352

SELECT DISTINCT c.cbsaname, SUM(p.population)
FROM population AS p
		LEFT JOIN cbsa AS c
		USING(fipscounty)
WHERE c.cbsaname IS NOT NULL
GROUP BY c.cbsaname
ORDER BY SUM(p.population) DESC
LIMIT 10;


SELECT DISTINCT c.cbsaname, SUM(p.population)
FROM population AS p
		LEFT JOIN cbsa AS c
		USING(fipscounty)
WHERE c.cbsaname IS NOT NULL
GROUP BY c.cbsaname
ORDER BY SUM(p.population)
LIMIT 10;



--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
--		Sevier with 95,524 people

SELECT fc.county, p.population
FROM population AS p
		LEFT JOIN cbsa AS c
		USING(fipscounty)
		LEFT JOIN fips_county as fc
		USING (fipscounty)
WHERE c.cbsaname IS NULL
GROUP BY fc.county, p.population
ORDER BY p.population DESC
LIMIT 5;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 	drug_name,
		opioid_drug_flag,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		total_claim_count
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
	LEFT JOIN prescriber
	USING (npi)
WHERE total_claim_count >= 3000
GROUP BY drug_name, opioid_drug_flag,nppes_provider_first_name, nppes_provider_last_org_name,total_claim_count
ORDER BY total_claim_count DESC;



-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville
--	and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists
--		(specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
--		where the drug is an opioid (opiod_drug_flag = 'Y').
--		**Warning:** Double-check your query before running it.
--		You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


SELECT p_ber.npi, d.drug_name  
FROM prescriber AS p_ber
	CROSS JOIN drug AS d
WHERE p_ber.npi IN 
			(SELECT npi
		 	FROM prescriber
		 	WHERE specialty_description = 'Pain Management'
			AND nppes_provider_city = 'NASHVILLE')
		AND d.drug_name IN
			(SELECT drug_name
			FROM drug
			WHERE opioid_drug_flag = 'Y')
GROUP BY d.drug_name, p_ber.npi
ORDER BY d.drug_name;


--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations,
--		whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT DISTINCT p_ber.npi, d.drug_name, coalesce(p_tion.total_claim_count,0)
FROM prescriber AS p_ber
	CROSS JOIN drug AS d
	LEFT JOIN prescription AS p_tion
	ON p_ber.npi = p_tion.npi
	AND d.drug_name = p_tion.drug_name
WHERE p_ber.npi IN 
			(SELECT npi
		 	FROM prescriber
		 	WHERE specialty_description = 'Pain Management'
			AND nppes_provider_city = 'NASHVILLE')
		AND d.drug_name IN
			(SELECT drug_name
			FROM drug
			WHERE opioid_drug_flag = 'Y')
ORDER BY d.drug_name;



--	7 distinct NPIs
SELECT COUNT(DISTINCT npi)
FROM prescriber
WHERE specialty_description = 'Pain Management'
		AND nppes_provider_city = 'NASHVILLE';

-- 91 opioids
SELECT COUNT(DISTINCT drug_name)
FROM drug
WHERE opioid_drug_flag = 'Y';



    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
--		Hint - Google the COALESCE function.


