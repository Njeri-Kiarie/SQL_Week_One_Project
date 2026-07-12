CREATE DATABASE Humanitarian_Program;

USE Humanitarian_Program;

CREATE TABLE Jurisdiction_Hierarchy(
	ID INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    partner_name VARCHAR(30) NOT NULL UNIQUE,
    admin_level VARCHAR(20) NOT NULL, CHECK(admin_level IN ('County','Sub-county','Village')),
    parent VARCHAR (30) NULL,
   
    FOREIGN KEY (parent)
		REFERENCES Jurisdiction_Hierarchy(partner_name) 
        ON DELETE CASCADE
);

CREATE TABLE Village_Locations(
	village_id INT PRIMARY KEY AUTO_INCREMENT,
    village VARCHAR (30) NOT NULL UNIQUE,
    total_population INT NOT NULL, CHECK (total_population >= 0),
    
 
	FOREIGN KEY (village)
		REFERENCES Jurisdiction_Hierarchy(partner_name) 
        ON DELETE CASCADE
);

CREATE TABLE Beneficiary_Partner_Data(
	partner_id INT PRIMARY KEY AUTO_INCREMENT,
    partner VARCHAR (30) NOT NULL,
    village VARCHAR (30) NOT NULL,
    beneficiaries INT NOT NULL, CHECK(beneficiaries >= 0),
    beneficiary_type VARCHAR (30) CHECK (beneficiary_type IN ('Individuals', 'Households')),
    
    
		FOREIGN KEY (village)
		REFERENCES village_locations(village)
        ON DELETE CASCADE
);

-- Inserting data manually into our data
INSERT INTO Jurisdiction_Hierarchy(partner_name, admin_level, parent)
VALUES
('Nairobi', 'County', NULL),
('Kiambu', 'County', NULL),
('Mombasa', 'County', NULL),
('Westlands', 'Sub-county', 'Nairobi'),
('Kasarani', 'Sub-county', 'Nairobi'),
('Lari', 'Sub-county', 'Kiambu'),
('Gatundu South', 'Sub-county', 'Kiambu'),
('Kisauni', 'Sub-county', 'Mombasa'),
('Likoni', 'Sub-county', 'Mombasa'),
('Parklands', 'Village', 'Westlands'),
('Kangemi', 'Village', 'Westlands'),
('Roysambu', 'Village', 'Kasarani'),
('Githurai', 'Village', 'Kasarani'),
('Kiamwangi', 'Village', 'Lari'),
('Lari Town', 'Village', 'Lari'),
('Kamwangi', 'Village', 'Gatundu South'),
('Kisauni Town', 'Village', 'Kisauni'),
('Mtopanga', 'Village', 'Kisauni'),
('Likoni Town', 'Village', 'Likoni'),
('Shika Adabu', 'Village', 'Likoni');

INSERT INTO Village_Locations (village, total_population)
VALUES
('Parklands', 15000),
('Kangemi', 18000),
('Roysambu', 13000),
('Githurai', 12500),
('Kiamwangi', 12800),
('Lari Town', 9485),
('Kamwangi', 5212),
('Kisauni Town', 20500),
('Mtopanga', 15500),
('Likoni Town', 12000),
('Shika Adabu', 9000);

INSERT INTO Beneficiary_Partner_Data (partner, village, beneficiaries, beneficiary_type)
VALUES
('IRC', 'Parklands', 1450, 'Individuals'),
('NRC', 'Parklands', 50, 'Households'),
('SCI', 'Kangemi', 1123, 'Individuals'),
('IMC', 'Kangemi', 1245, 'Individuals'),
('CESVI', 'Roysambu', 5200, 'Individuals'),
('IMC', 'Githurai', 70, 'Households'),
('IRC', 'Githurai', 2100, 'Individuals'),
('SCI', 'Kiamwangi', 1800, 'Individuals'),
('IMC', 'Lari Town', 1340, 'Individuals'),
('CESVI', 'Kamwangi', 55, 'Households'),
('IRC', 'Kisauni Town', 4500, 'Individuals'),
('SCI', 'Kisauni Town', 1670, 'Individuals'),
('IMC', 'Mtopanga', 1340, 'Individuals'),
('CESVI', 'Likoni Town', 4090, 'Individuals'),
('IRC', 'Shika Adabu', 2930, 'Individuals'),
('SCI', 'Shika Adabu', 5200, 'Individuals');

SET SQL_SAFE_UPDATES = 0;

-- Checking if the records have been inserted in all the tables
SELECT * FROM Jurisdiction_Hierarchy;
SELECT * FROM Village_Locations;
SELECT * FROM Beneficiary_Partner_Data;

# 1. AGGREGATE FUNCTIONS: GROUP BY AND CASE WHEN
-- Total Beneficiaries per partner
-- From the data (1 household = 6 individuals)
SELECT
	partner,
    SUM(
		CASE
			WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
			ELSE beneficiaries
		END
        ) AS total_beneficiaries
FROM Beneficiary_Partner_Data
GROUP BY partner;

-- 2. Count the Number of villages served per parnter
SELECT
    partner,
    COUNT(DISTINCT village) AS villages_per_partner
FROM Beneficiary_Partn

-- 3. Compute the average beneficiaries per village
SELECT
    village,
    AVG(
        CASE
            WHEN beneficiary_type='Households' THEN beneficiaries * 6
            ELSE beneficiaries
        END
    ) AS average_beneficiaries
FROM Beneficiary_Partner_Data
GROUP BY village;

-- 4. Identify partners serving more than 5000 beneficiaries (HAVING).
SELECT
    partner,
    SUM(
        CASE
            WHEN beneficiary_type='Households' THEN beneficiaries * 6
            ELSE beneficiaries
        END
    ) AS total_beneficiaries
FROM beneficiary_partner_data
GROUP BY partner
HAVING total_beneficiaries > 5000;

-- 5. Find villages with multiple partners (HAVING).
SELECT
    village,
    COUNT(DISTINCT partner) AS partner_count
FROM beneficiary_partner_data
GROUP BY village
HAVING partner_count > 1;


# JOINS AND COMBINED QUERIES
-- 1. Join beneficiary_partner_data and village_locations to calculate coverage per village (beneficiaries / total_population).
SELECT
    village,
    total_population,
    beneficiaries,
    ROUND((beneficiaries / total_population), 2) AS coverage_per_village
FROM
(
    SELECT
        vl.village,
        vl.total_population,
        SUM(
            CASE
                WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                ELSE bpd.beneficiaries
            END
        ) AS beneficiaries
    FROM village_locations vl
    INNER JOIN beneficiary_partner_data bpd
        ON vl.village = bpd.village
    GROUP BY
        vl.village,
        vl.total_population
) AS village_summary;

-- 2. Create a combined query showing all villages and partners serving them, including villages with no partners using UNION.
SELECT
    vl.village,
    bpd.partner
FROM village_locations vl
LEFT JOIN beneficiary_partner_data bpd
	ON vl.village=bpd.village

UNION

SELECT
    village,
    partner
FROM beneficiary_partner_data;


# NESTED QUERIES OR SUBQUERIES
-- 1. Find villages where coverage is above the average village coverage.
SELECT * FROM(
    SELECT
        vl.village,
        SUM(
            CASE
                WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                ELSE bpd.beneficiaries
            END
        ) / vl.total_population AS coverage
    FROM Village_Locations vl
    INNER JOIN Beneficiary_Partner_Data bpd
        ON vl.village = bpd.village
    GROUP BY
        vl.village, vl.total_population
) AS village_coverage
WHERE coverage >
(
    SELECT AVG(coverage) FROM(
        SELECT
            SUM(
                CASE
                    WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                    ELSE bpd.beneficiaries
                END
            ) / vl.total_population AS coverage
        FROM Village_Locations vl
        INNER JOIN Beneficiary_Partner_Data bpd
            ON vl.village = bpd.village
        GROUP BY vl.village, vl.total_population
    ) AS average_coverage
);

-- 2. Find partners who serve more than the average number of beneficiaries.
SELECT
    partner,
    total_beneficiaries
FROM(
    SELECT
        partner,
        SUM(
            CASE
                WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
                ELSE beneficiaries
            END
        ) AS total_beneficiaries
    FROM Beneficiary_Partner_Data
    GROUP BY partner
) AS partner_totals
WHERE total_beneficiaries >
(
    SELECT AVG(total_beneficiaries)
    FROM(
        SELECT
            SUM(
                CASE
                    WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
                    ELSE beneficiaries
                END
            ) AS total_beneficiaries
        FROM Beneficiary_Partner_Data
        GROUP BY partner
    ) AS average_totals
);


# CTEs (Common Table Expressions)
-- 1. Create a district-level summary showing total beneficiaries, total population, coverage using a CTE.
WITH District_Level_Summary AS(
    SELECT jh.parent AS district,
			SUM(
				CASE
					WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
					ELSE bpd.beneficiaries
				END
			) AS total_beneficiaries,
			SUM(vl.total_population) AS total_population
    FROM Beneficiary_Partner_Data bpd
    INNER JOIN Village_Locations vl
        ON bpd.village = vl.village
    INNER JOIN Jurisdiction_Hierarchy jh
        ON vl.village = jh.partner_name
    GROUP BY jh.parent
)
-- Using the CTE
SELECT
    district,
    total_beneficiaries,
    total_population,
    ROUND((total_beneficiaries / total_population), 2) AS coverage_per_village
FROM District_Level_Summary;

-- 2. Rank districts by coverage using a window function inside a CTE.
WITH District_Level_Summary AS(
    SELECT jh.parent AS district,
			SUM(
				CASE
					WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
					ELSE bpd.beneficiaries
				END
			) AS total_beneficiaries,
			SUM(vl.total_population) AS total_population
    FROM Beneficiary_Partner_Data bpd
    INNER JOIN Village_Locations vl
        ON bpd.village = vl.village
    INNER JOIN Jurisdiction_Hierarchy jh
        ON vl.village = jh.partner_name
    GROUP BY jh.parent
)
SELECT
    district,
    total_beneficiaries,
    total_population,
    ROUND((total_beneficiaries / total_population), 2) AS coverage_per_village,
	RANK() OVER (ORDER BY total_beneficiaries / total_population DESC) AS district_rank
FROM District_Level_Summary;

# WINDOW FUNCTIONS
-- 1. Rank partners based on total beneficiaries (RANK() OVER).
SELECT
    partner,
    SUM(
        CASE
            WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
            ELSE beneficiaries
        END
    ) AS total_beneficiaries,
	RANK() OVER
			(ORDER BY SUM(
						CASE
							WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
							ELSE beneficiaries
						END
					) DESC
    ) AS partner_rank
FROM Beneficiary_Partner_Data
GROUP BY partner;

-- 2. Rank districts within each region based on beneficiaries served (PARTITION BY).
WITH district_totals AS(
    SELECT
        county.partner_name AS county,
        district.partner_name AS district,
		SUM(
            CASE
                WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                ELSE bpd.beneficiaries
            END
        ) AS total_beneficiaries
	FROM Beneficiary_Partner_Data bpd
	JOIN Jurisdiction_Hierarchy village
        ON bpd.village = village.partner_name
	JOIN Jurisdiction_Hierarchy district
        ON village.parent = district.partner_name
	JOIN Jurisdiction_Hierarchy county
        ON district.parent = county.partner_name
	GROUP BY county.partner_name, district.partner_name
)
SELECT
    county,
    district,
    total_beneficiaries,
	RANK() OVER(PARTITION BY county ORDER BY total_beneficiaries DESC) AS district_rank
FROM district_totals;

-- 3. Top performing partner per district (ROW_NUMBER()).
-- Creating a CTE
WITH partner_totals AS(
    SELECT
        district.partner_name AS district,
        bpd.partner,
		SUM(
            CASE
                WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                ELSE bpd.beneficiaries
            END
        ) AS total_beneficiaries
	FROM Beneficiary_Partner_Data bpd
	JOIN Jurisdiction_Hierarchy village
        ON bpd.village = village.partner_name
	JOIN Jurisdiction_Hierarchy district
        ON village.parent = district.partner_name
	GROUP BY district.partner_name, bpd.partner
)
-- Using the CTE
SELECT
    district,
    partner,
    total_beneficiaries
FROM(
    SELECT
        district,
        partner,
        total_beneficiaries,
	ROW_NUMBER() OVER (PARTITION BY district ORDER BY total_beneficiaries DESC) AS row_num
	FROM partner_totals
) ranked_partners
WHERE row_num = 1;


# VIEWS
-- 1. Create view district_summary with district-level beneficiaries, population, coverage, number of partners.
CREATE VIEW district_summary AS
SELECT 
	district.partner_name AS district,
	SUM(
        CASE
            WHEN bpd.beneficiary_type='Households' THEN bpd.beneficiaries*6
            ELSE bpd.beneficiaries
        END
    ) AS total_beneficiaries,
	SUM(vl.total_population) AS total_population,
	ROUND(
        (
            SUM(
                CASE
                    WHEN bpd.beneficiary_type='Households' THEN bpd.beneficiaries*6
                    ELSE bpd.beneficiaries
                END
            ) / SUM(vl.total_population)
        ),2) AS coverage_per_village,
	COUNT(DISTINCT bpd.partner) AS number_of_partners
FROM Beneficiary_Partner_Data bpd
JOIN Village_Locations vl
    ON bpd.village = vl.village
JOIN Jurisdiction_Hierarchy village
    ON vl.village = village.partner_name
JOIN Jurisdiction_Hierarchy district
    ON village.parent = district.partner_name
GROUP BY district.partner_name;

SELECT * FROM district_summary;

-- 2. Create view partner_summary with partner name, villages served, districts reached, total beneficiaries.
CREATE VIEW partner_summary AS
SELECT
	bpd.partner,
	COUNT(DISTINCT bpd.village) AS villages_served,
	COUNT(DISTINCT district.partner_name) AS districts_reached,
	SUM(
        CASE
            WHEN bpd.beneficiary_type='Households' THEN bpd.beneficiaries*6
            ELSE bpd.beneficiaries
        END
    ) AS total_beneficiaries
FROM Beneficiary_Partner_Data bpd
JOIN Jurisdiction_Hierarchy village
    ON bpd.village = village.partner_name
JOIN Jurisdiction_Hierarchy district
    ON village.parent = district.partner_name
GROUP BY bpd.partner;

SELECT * FROM partner_summary;


# TRIGGERS
-- 1. Trigger on beneficiary_partner_data to log a message when a new record is inserted.
-- Creating a log table to record the triggers
CREATE TABLE Beneficiary_Log(
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    partner VARCHAR(30),
    village VARCHAR(30),
    message VARCHAR(100),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Creating the trigger
DELIMITER //

CREATE TRIGGER Insert_Beneficiary
AFTER INSERT
ON Beneficiary_Partner_Data
FOR EACH ROW
BEGIN
INSERT INTO Beneficiary_Log(partner, village, message)
VALUES(NEW.partner, NEW.village, 'New beneficiary record added');

END //

DELIMITER ;beneficiary_log

-- Testing the trigger
INSERT INTO Beneficiary_Log(partner, village, message)
VALUES('IRC', 'Roysambu', 'New beneficiary record added');

SELECT * FROM Beneficiary_Partner_Data;
SELECT * FROM Beneficiary_Log;

-- 2. Trigger to prevent inserting negative beneficiaries.
DELIMITER //

CREATE TRIGGER trg_check_beneficiaries
BEFORE INSERT ON Beneficiary_Partner_Data
FOR EACH ROW
BEGIN
    IF NEW.beneficiaries < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Beneficiaries cannot be negative';
    END IF;
END //

DELIMITER ;

-- Attempting to add a negative beneficiary
SELECT * FROM Beneficiary_Partner_Data;
INSERT INTO Beneficiary_Partner_Data(partner, village, beneficiaries, beneficiary_type)
VALUES
('IRC','Parklands',-100,'Individuals');
-- Error message successfully printed out


# STORED PROCEDURES
-- 1. GetPartnerReport(partner_name) → returns villages served, districts served, total beneficiaries, partner ranking.
DELIMITER //

CREATE PROCEDURE GetPartnerReport(IN p_partner VARCHAR(30))
BEGIN
	SELECT
        bpd.partner,
		COUNT(DISTINCT bpd.village) AS villages_served,
		COUNT(DISTINCT district.partner_name) AS districts_served,
		SUM(
            CASE
                WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                ELSE bpd.beneficiaries
            END
        ) AS total_beneficiaries
	FROM Beneficiary_Partner_Data bpd
	JOIN Jurisdiction_Hierarchy village
        ON bpd.village = village.partner_name
	JOIN Jurisdiction_Hierarchy district
        ON village.parent = district.partner_name
	WHERE bpd.partner = p_partner
	GROUP BY bpd.partner;

END //

DELIMITER ;

-- Using the stored procedure
SELECT * FROM Beneficiary_Partner_Data;
CALL GetPartnerReport('CESVI');

-- 2. GetDistrictImpact(district_name) → returns region, district population, total beneficiaries, coverage rate, number of partners.
DELIMITER //

CREATE PROCEDURE GetDistrictImpact(IN p_district VARCHAR(30))
BEGIN
SELECT
	county.partner_name AS county,
	district.partner_name AS district,
	SUM(vl.total_population) AS total_population,
	SUM(
        CASE
            WHEN bpd.beneficiary_type='Households' THEN bpd.beneficiaries*6
            ELSE bpd.beneficiaries
        END
    ) AS total_beneficiaries,
	ROUND(
        (
			SUM(
                CASE
                    WHEN bpd.beneficiary_type='Households' THEN bpd.beneficiaries*6
                    ELSE bpd.beneficiaries
                END
            ) / SUM(vl.total_population)
        ), 2) AS coverage_per_village,
	COUNT(DISTINCT bpd.partner) AS number_of_partners
FROM Beneficiary_Partner_Data bpd
JOIN Village_Locations vl
    ON bpd.village = vl.village
JOIN Jurisdiction_Hierarchy village
    ON vl.village = village.partner_name
JOIN Jurisdiction_Hierarchy district
    ON village.parent = district.partner_name
JOIN Jurisdiction_Hierarchy county
    ON district.parent = county.partner_name
WHERE district.partner_name = p_district
GROUP BY county.partner_name, district.partner_name;

END //

DELIMITER ;

SELECT * FROM District_Summary;
CALL GetDistrictImpact('Gatundu South');

# BONUS CHALLENGES
-- 1. Find partners operating in more than 3 villages.
SELECT
    partner,
    COUNT(DISTINCT village) AS villages_served
FROM Beneficiary_Partner_Data
GROUP BY partner
HAVING COUNT(DISTINCT village) > 3;

-- 2. Find districts where total beneficiaries exceed 10,000.
SELECT
    district.partner_name AS district,
	SUM(
        CASE
            WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
            ELSE bpd.beneficiaries
        END
    ) AS total_beneficiaries
FROM Beneficiary_Partner_Data bpd
JOIN Jurisdiction_Hierarchy village
    ON bpd.village = village.partner_name
JOIN Jurisdiction_Hierarchy district
    ON village.parent = district.partner_name
GROUP BY district.partner_name
HAVING total_beneficiaries > 10000;

-- 3. Identify partners dominating a district (highest beneficiaries per district).
WITH partner_totals AS(
    SELECT
        district.partner_name AS district,
		bpd.partner,
		SUM(
            CASE
                WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                ELSE bpd.beneficiaries
            END
        ) AS total_beneficiaries
	FROM Beneficiary_Partner_Data bpd
	JOIN Jurisdiction_Hierarchy village
        ON bpd.village = village.partner_name
	JOIN Jurisdiction_Hierarchy district
        ON village.parent = district.partner_name
GROUP BY district.partner_name, bpd.partner
)
SELECT
    district,
    partner,
    total_beneficiaries
FROM
(
    SELECT
        district,
        partner,
        total_beneficiaries,
		ROW_NUMBER() OVER (PARTITION BY district ORDER BY total_beneficiaries DESC) AS row_num
	FROM partner_totals
) ranked_partners
WHERE row_num = 1;