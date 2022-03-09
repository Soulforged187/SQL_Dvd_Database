--drop any existing duplicates
DROP TABLE detailed;
DROP TABLE top_sellers;

--- create new tables 
CREATE TABLE IF NOT EXISTS detailed(
staff_id integer,
first_name varchar(45),
last_name  varchar(45),
amount numeric(5,2),
payment_date timestamp);

CREATE TABLE IF NOT EXISTS top_sellers(
full_name varchar (90),
amount_sum numeric(7,2));

---function for deletion and then insertion for detailed
CREATE OR REPLACE PROCEDURE rebuild_detailed()
LANGUAGE SQL
AS $$
INSERT INTO detailed(staff_id,first_name, last_name, amount, payment_date)
SELECT 
staff.staff_id, staff.first_name, staff.last_name, payment.amount, payment.payment_date
FROM
staff
RIGHT JOIN payment ON staff.staff_id = payment.staff_id
order by staff.staff_id desc
$$;

--function for deletion then insertion for top_sellers 
CREATE OR REPLACE PROCEDURE rebuild_top_performer()
LANGUAGE SQL
AS $$

DELETE FROM top_sellers;

INSERT INTO top_sellers (full_name,amount_sum)
SELECT
concat_ws(',',last_name,first_name) AS full_name,
CAST(SUM(amount) AS money) AS amount_sum
FROM
detailed
WHERE payment_date::TIMESTAMP BETWEEN '2007-01-01' AND CURRENT_DATE 
GROUP BY full_name
ORDER BY amount_sum DESC
LIMIT 2;
$$;

--function to rebuild tables 
CREATE PROCEDURE rebuild()
LANGUAGE SQL
AS $$
DELETE FROM detailed;
DELETE FROM top_sellers;
CALL rebuild_detailed();
CALL rebuild_top_performer();
$$;

-- Call the function to clear and insert both tables
call rebuild();

CREATE OR REPLACE FUNCTION start_rebuild()
RETURNS trigger AS
$$
BEGIN
 CALL rebuild();
RETURN NULL;
END;
$$
Language 'plpgsql';

---trigger statement
CREATE TRIGGER new_input
AFTER INSERT 
ON detailed
FOR EACH ROW
EXECUTE PROCEDURE start_rebuild();

SELECT * FROM detailed;

SELECT * FROM top_sellers;


