CREATE DATABASE Faaso;
USE Faaso;

DROP TABLE IF EXISTS driver;
CREATE TABLE driver(driver_id INT,reg_date DATE); 

INSERT INTO driver(driver_id,reg_date) 
VALUES 
(1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');


DROP TABLE IF EXISTS ingredients;
CREATE TABLE ingredients(ingredients_id INT,ingredients_name VARCHAR(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
VALUES 
(1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

DROP TABLE IF EXISTS rolls;
CREATE TABLE rolls(roll_id INT,roll_name VARCHAR(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
VALUES 
(1,'Non Veg Roll'),
(2,'Veg Roll');

DROP TABLE IF EXISTS rolls_recipes;
CREATE TABLE rolls_recipes(roll_id INT,ingredients VARCHAR(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
VALUES 
(1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

DROP TABLE IF EXISTS driver_order;
CREATE TABLE driver_order(order_id INT,driver_id INT,pickup_time DATETIME,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));


INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
VALUES
(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,NULL,NULL,NULL,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',NULL),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',NULL),
(9,2,NULL,NULL,NULL,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',NULL);


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders(order_id INT,customer_id INT,roll_id INT,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date DATETIME);

INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
VALUES 
(1,101,1,'','','2021-01-01 18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,NULL,'1','2021-01-08 21:00:29'),
(6,101,2,NULL,NULL,'2021-01-08 21:03:13'),
(7,105,2,NULL,'1','2021-01-08 21:20:29'),
(8,102,1,NULL,NULL,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,NULL,NULL,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');

-- DATA CLEANING FOR customer_orders

SET SQL_SAFE_UPDATES = 0;

UPDATE customer_orders
SET not_include_items = ""
WHERE not_include_items IS NULL;

UPDATE customer_orders
SET extra_items_included = ""
WHERE extra_items_included = 'NaN' OR extra_items_included IS NULL;

--  DATA CLEANING FOR driver_order

SET SQL_SAFE_UPDATES = 0;

UPDATE driver_order
SET cancellation = 
CASE WHEN cancellation IN ('Cancellation','Customer Cancellation') THEN cancellation ELSE 0 END;

UPDATE driver_order 
SET distance = REPLACE(LOWER(distance),"km","");

UPDATE driver_order 
SET duration = (CASE WHEN duration REGEXP "min" THEN LEFT(duration,POSITION("min" IN duration)-1) ELSE duration END);

-- ------------------------------  ORDER METRICS ------------------------------

-- NUMBER OF ROLLS ORDERED

SELECT COUNT(roll_id) AS "No_Of_Rolls_Ordered" 
FROM customer_orders;

-- NUMBER OF UNIQUE CUSTOMER ORDERS

SELECT COUNT(DISTINCT customer_id) AS "No_Of_Unique_Customers"
FROM customer_orders;

-- NUMBER OF SUCCESSFUL ORDERS DELIVERED BY EACH DRIVER 

SELECT driver_id,COUNT(DISTINCT order_id) AS "No_Of_Orders_Delivered" FROM driver_order
WHERE cancellation = "0"
GROUP BY driver_id;

-- TOTAL ORDERS DELIVERED FOR EACH TYPE OF ROLL

SELECT r.roll_name,COUNT(r.roll_name) AS "No_Of_Orders"
FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id
JOIN rolls AS r
ON c.roll_id = r.roll_id
WHERE cancellation = "0"
GROUP BY r.roll_name;

-- NUMBER OF VEG AND NON-VEG ROLLS ORDERED BY EACH CUSTOMER

SELECT c.customer_id,
COUNT(CASE WHEN r.roll_name = "Non Veg Roll" THEN roll_name END) AS "No_Of_Non_Veg_Rolls",
COUNT(CASE WHEN r.roll_name = "Veg Roll" THEN roll_name END) AS "No_Of_Veg Rolls" 
FROM customer_orders AS c
JOIN rolls AS r
ON c.roll_id = r.roll_id
GROUP BY c.customer_id;

-- MAXIMUM NUMBER OF ROLLS DELIVERED IN A SINGLE ORDER

SELECT c.order_id,COUNT(c.roll_id) "No_Of_Rolls_Delivered" 
FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id
WHERE cancellation = "0"
GROUP BY order_id
ORDER BY COUNT(roll_id) DESC
LIMIT 1;

-- FOR EACH CUSTOMER, HOW MANY DELIVERED ROLLS HAD ATLEAST 1 CHANGE AND HOW MANY HAD NO CHANGES

SELECT c.customer_id,
COUNT(CASE WHEN  (c.not_include_items <> "" OR c.extra_items_included <> "") THEN "With_Change" END) AS Num_Of_Rolls_With_Change,
COUNT(CASE WHEN (c.not_include_items = "" AND c.extra_items_included = "" ) THEN "No_Change" END) AS Num_Of_Rolls_With_No_Change
FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id
WHERE cancellation = "0"
GROUP BY c.customer_id;

-- HOW MANY ROLLS WHERE DELIVERED THAT HAD BOTH EXCLUSIONS AND EXTRAS

SELECT COUNT(roll_id) AS "Count_Of_Rolls" FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id
WHERE cancellation = "0" AND c.not_include_items <> "" AND c.extra_items_included <> "";

-- TOTAL NUMBER OF ROLLS ORDERED FOR EACH HOUR OF THE DAY

SELECT Hour_Bracket,COUNT(Hour_Bracket) AS "No_Of_Rolls" FROM
(SELECT *,CONCAT(HOUR(order_date),"-",HOUR(order_date)+1) AS "Hour_Bracket" 
FROM customer_orders) a
GROUP BY Hour_Bracket;

-- NUMBER OF ORDERS FOR EACH DAY OF THE WEEK

SELECT Day_Of_Week,COUNT(order_id) FROM
(SELECT *,DAYNAME(order_date) AS "Day_Of_Week" 
FROM customer_orders ) a
GROUP BY Day_Of_Week;


-- ------------------------------  DRIVER AND CUSTOMER EXPERIENCE ------------------------------


-- AVERAGE TIME IN MINUTES TOOK FOR EACH DRIVER TO ARRIVE AT THE FASOOS HQ TO PICKUP THE ORDER

SELECT driver_id,AVG(Arrival_Time) AS "Avg_Time" FROM
(SELECT *,ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY Arrival_Time) AS Rnk 
FROM
(SELECT c.order_date,d.*,MINUTE(TIMEDIFF(d.pickup_time,c.order_date)) AS "Arrival_Time"
FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id) a) b
WHERE Rnk = 1
GROUP BY driver_id;

-- NUMBER OF ROLLS ORDERED AND TIME TAKEN TO PREPARE THE ORDER

SELECT c.order_id,COUNT(roll_id) AS "No_Of_Rolls",AVG(MINUTE(TIMEDIFF(d.pickup_time,c.order_date))) AS "Avg_Time"
FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id
WHERE d.pickup_time IS NOT NULL
GROUP BY c.order_id;

-- AVERAGE DISTANCE TRAVELLED BY EACH OF THE CUSTOMER

SELECT customer_id,AVG(distance) AS "Average_Distance_Travelled" FROM
(SELECT c.customer_id,d.distance,d.pickup_time,ROW_NUMBER() OVER(PARTITION BY c.order_id) AS Rnk
FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id) a
WHERE Rnk = 1 AND pickup_time IS NOT NULL
GROUP BY customer_id;

-- AVERAGE SPEED OF EACH DRIVER 

SELECT driver_id,CONCAT(ROUND(AVG(Speed),0)," km/hr") AS "Average_Speed" FROM
(SELECT *,distance/(duration/60) AS "Speed"
FROM driver_order
WHERE distance IS NOT NULL) a
GROUP BY driver_id;

-- SUCCESSFUL DELIVERY PERCENTAGE OF EACH DRIVER

SELECT driver_id,(SUM(delivery_status)/COUNT(delivery_status))*100 AS "Delivery_Percentage" FROM
(SELECT driver_id, 
CASE WHEN LOWER(cancellation) REGEXP "cancel" THEN 0 ELSE 1 END AS "delivery_status"
FROM customer_orders AS c
JOIN driver_order AS d
ON c.order_id = d.order_id) a
GROUP BY driver_id;
