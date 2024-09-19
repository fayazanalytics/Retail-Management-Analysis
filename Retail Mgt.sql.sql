-- Company has decided to give rewards to loyal customers. They will either provide high discount coupons or may decide to give the products for free to the customers as a loyalty reward.
-- Identify the oldest customer in our database.

SELECT Customer_Id, Name, YEAR(NOW()) - Customer_Since AS TotalYears 
FROM CustomerDim 
ORDER BY TotalYears DESC LIMIT 1;

--  Identify the customers having a lot of purchase activity on our platform in the last quarter. 
-- LIMIT it to top 5 customers and get the customer names in asc order where it’s a tie. 
-- Now, based on the output table, who is the person present in the second row?

SELECT CD.Name, EXTRACT(QUARTER FROM P.DateOfPurchase) AS quarter, COUNT(*) AS TotalPurchases 
FROM ProductSalesFact AS P 
JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY Name, EXTRACT(QUARTER FROM DateOfPurchase) 
HAVING quarter IN (SELECT MAX(EXTRACT(QUARTER FROM DateOfPurchase))  
FROM ProductSalesFact) 
ORDER BY TotalPurchases 
DESC, Name LIMIT 5; -- Answer : "Aditya Arora"


-- Identify the customers with bulk purchasing orders in different usage segments in the last quarter.

SELECT T1.* 
FROM ( SELECT P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM P.DateOfPurchase) AS quarter, SUM(Quantity) AS QuantityPurchased 
FROM ProductSalesFact AS P JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM DateOfPurchase) 
HAVING quarter IN (SELECT MAX(EXTRACT(QUARTER FROM DateOfPurchase)) 
FROM ProductSalesFact)) AS T1 
JOIN (SELECT Cust_Usage, MAX(QuantityPurchased) AS MaxQuantitiesPurchased 
FROM (SELECT P.Cust_Usage, CD.Name,EXTRACT(QUARTER FROM P.DateOfPurchase) AS quarter, 
SUM(Quantity) AS QuantityPurchased 
FROM ProductSalesFact AS P 
JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM DateOfPurchase) 
HAVING quarter IN (SELECT MAX(EXTRACT(QUARTER FROM DateOfPurchase)) 
FROM ProductSalesFact)) AS T 
GROUP BY Cust_Usage) T2 ON T1.Cust_Usage = T2.Cust_Usage 
AND T1.QuantityPurchased = T2.MaxQuantitiesPurchased;


--  Now based on above identified customers, 
-- create strings for top customers having frequent purchase activity in different usage segment in format “Congratulations {Customer_Name}! 
-- You are eligible for a coupon of 75% off upto 5000 INR to be redeemed till {date}. 
-- You can find that in your email.”


SELECT T1.*, 
CONCAT("Congratulations ", Name , "! You are eligible for a coupon of 75% off upto 5000 INR to be redeemed till ", 
DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 30 DAY), '%M %e, %Y'), ". You can find that in your email") AS promotionmsg 
FROM ( SELECT P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM P.DateOfPurchase) AS quarter, 
COUNT(*) AS TotalPurchases 
FROM ProductSalesFact AS P JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM DateOfPurchase) 
HAVING quarter IN (SELECT MAX(EXTRACT(QUARTER FROM DateOfPurchase)) 
FROM ProductSalesFact)) AS T1 
JOIN (SELECT Cust_Usage, MAX(TotalPurchases) AS MaxTimesPurchased 
FROM (SELECT P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM P.DateOfPurchase) AS quarter, 
COUNT(*) AS TotalPurchases FROM ProductSalesFact AS P 
JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM DateOfPurchase) 
HAVING quarter IN (SELECT MAX(EXTRACT(QUARTER FROM DateOfPurchase)) 
FROM ProductSalesFact)) AS T 
GROUP BY Cust_Usage) T2 ON T1.Cust_Usage = T2.Cust_Usage 
AND T1.TotalPurchases = T2.MaxTimesPurchased;


-- Let’s suppose we want to limit the customers to certain product categories that they can spend their discount coupon on but we can try to identify the categories that they like.
-- Identify No. of products that are 90 days older in our inventory by Product category sorted in top to bottom order by the total stock price.

SELECT Category_Id, COUNT(*) AS TotalProducts, SUM(Price) TotalStockPrice 
FROM ProductDim 
WHERE DATEDIFF(NOW(), In_Inventory) > 90 
GROUP BY Category_Id 
ORDER BY TotalStockPrice DESC;

-- Identify Product category with Return or Exchange type sorted from bottom to top by the total stock price.

SELECT Category_Id, Return_Or_Exchange, COUNT(*) AS TotalProducts, SUM(Price) TotalStockPrice 
FROM ProductDim 
WHERE DATEDIFF(NOW(), In_Inventory) > 90 
GROUP BY Category_Id, Return_Or_Exchange 
ORDER BY TotalStockPrice;

-- Identify the product category which customers have bought a lot in each month in different usage segments ordered from top to bottom by their frequencies.

SELECT Cust_Usage, EXTRACT(MONTH FROM P.DateOfPurchase) AS month,  COUNT(*) AS TotalPurchases 
FROM ProductSalesFact AS P 
JOIN ProductDim AS PD ON PD.Product_Id = P.Product_Id 
GROUP BY Cust_Usage, EXTRACT(MONTH FROM DateOfPurchase) 
ORDER BY TotalPurchases DESC;

-- Consider the scenario that we have quite a lot of complaints for different products in product categories.
-- An organization can’t resolve all the queries at the same time so they try to prioritise the complaints received in highest volumes first.

SELECT C.*, P.Category_Id, COUNT(*) OVER(PARTITION BY Category_Id, Resolved) AS TotalComplaintsbyCategory 
FROM Complaints AS C JOIN ProductSalesFact AS PS ON C.Complaint_Id = PS.Complaint_Id 
JOIN ProductDim AS P ON PS.Product_Id = P.Product_Id 
ORDER BY TotalComplaintsbyCategory DESC;

--  Identify the fraction of complaints that are resolved by each product category vs fraction of complaints that aren’t resolved by each product category with complaint level details.

SELECT C.*, 
P.Category_Id, 
COUNT(*) OVER(PARTITION BY Category_Id, Resolved) / COUNT(*) OVER(PARTITION BY Category_Id) AS FractionComplaintsResolvedvsUnresolvedbyCategory 
FROM Complaints 
AS C JOIN ProductSalesFact AS PS ON C.Complaint_Id = PS.Complaint_Id 
JOIN ProductDim AS P ON PS.Product_Id = P.Product_Id;

--- Rank the customers based on total purchasing they have done in terms of amount in desc order :

SELECT Customer_Id, TotalAmountPaid,
RANK() OVER(ORDER BY TotalAmountPaid DESC) AS _Rank,
DENSE_RANK() OVER(ORDER BY TotalAmountPaid DESC) AS DenseRank
FROM (SELECT Customer_Id,
      SUM(Amount_Paid) AS TotalAmountPaid 
      FROM ProductSalesFact 
      GROUP BY Customer_Id) AS T;
      
      
--- Rank the customers based on total quantities they have purchased by descending order :

SELECT Customer_Id, TotalQuantityPurchased,
RANK() OVER(ORDER BY TotalQuantityPurchased DESC) AS _Rank,
DENSE_RANK() OVER(ORDER BY TotalQuantityPurchased DESC) AS DenseRank
FROM (SELECT Customer_Id,
      SUM(Quantity) AS TotalQuantityPurchased
      FROM ProductSalesFact 
      GROUP BY Customer_Id) AS T;
      
      
--- Identify the top 1 ranking product/s within each product category by their Price 

SELECT *
FROM
(
SELECT Product_Id, Price, Category_Id,
DENSE_RANK() OVER(PARTITION BY Category_Id ORDER BY Price DESC) AS _rank
FROM ProductDim) AS T
WHERE _rank = 1;

--- Identify the top 1 ranking product/s within each product category by their number of days they are in inventory from the current date.

SELECT *
FROM
(
SELECT Product_Id, DATEDIFF(NOW(),In_Inventory) TotalDays, Category_Id,
DENSE_RANK() OVER(PARTITION BY Category_Id ORDER BY DATEDIFF(NOW(),In_Inventory) DESC) AS _rank
FROM ProductDim) AS T
WHERE _rank = 1;

---  Rank the complaints that are not resolved by their number of days in top to bottom order. Categorize the results by the Complaint Name.

SELECT 
Complaint_Name, DATEDIFF(NOW(),Complaint_Date) AS TotalDaysNotResolved, 
RANK() OVER(PARTITION BY Complaint_Name 
ORDER BY DATEDIFF(NOW(),Complaint_Date) DESC) AS _rank FROM Complaints 
WHERE Resolved != 'Resolved';

--- Compare the total purchase by amount that happened for each Usage type on a week by week basis. Remove records where we have null values on past or future values.
--- Compare the earnings and calculate the profit or loss compared to last week.

SELECT *,
TotalPurchase - Past AS RevenueFromLastWeek
FROM
(
SELECT *,
LAG(TotalPurchase) OVER(PARTITION BY Cust_Usage ORDER BY _week) AS Past,
LEAD(TotalPurchase) OVER(PARTITION BY Cust_Usage ORDER BY _week) AS Future
FROM (SELECT Cust_Usage,
     EXTRACT(WEEK FROM DateofPurchase) as _week,
     SUM(Amount_Paid) AS TotalPurchase
     FROM ProductSalesFact
     GROUP BY Cust_Usage, _week) AS T) AS T
     WHERE Past IS NOT NULL AND Future IS NOT NULL;
     
     
--- Compare the total number of complaints resolved on a week by week basis [include only past values].

SELECT *,
LAG(TotalComplaints) OVER(PARTITION BY Resolved ORDER BY _week) AS Past
FROM (SELECT Resolved,
     EXTRACT(WEEK FROM Complaint_Date) as _week,
     COUNT(*) AS TotalComplaints
     FROM Complaints
     GROUP BY Resolved, _week) AS T;
     
--- Get the number of customers that you witness week-by-week on your platform for each usage type including past and future values.

SELECT *,
LAG(TotalCustomers) OVER(PARTITION BY Cust_Usage ORDER BY _week) AS Past,
LEAD(TotalCustomers) OVER(PARTITION BY Cust_Usage ORDER BY _week) AS Future
FROM (SELECT Cust_Usage,
     EXTRACT(WEEK FROM DateofPurchase) as _week,
     COUNT(*) AS TotalCustomers
     FROM ProductSalesFact
     GROUP BY Cust_Usage, _week) AS T
     
     
--- Select only the first and last record across each category in the above question.

SELECT *,
FIRST_VALUE(TotalCustomers) OVER(PARTITION BY Cust_Usage ORDER BY _week RANGE BETWEEN
	    UNBOUNDED PRECEDING AND
            UNBOUNDED FOLLOWING) AS firstvalue,
LAST_VALUE(TotalCustomers) OVER(PARTITION BY Cust_Usage ORDER BY _week RANGE BETWEEN
	    UNBOUNDED PRECEDING AND
            UNBOUNDED FOLLOWING) AS lastvalue
FROM (SELECT Cust_Usage,
     EXTRACT(WEEK FROM DateofPurchase) as _week,
     COUNT(*) AS TotalCustomers
     FROM ProductSalesFact
     GROUP BY Cust_Usage, _week) AS T
     
     
--- Divide the household customer into 3 segments: highPurchase, mediumPurchase and lowPurchase 
--- based on ranking of customers by their total purchase amount (first 25% in low, 25 to 75 medium and > 75% high).

SELECT *,
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'mediumPurchase'
ELSE 'highPurchase'
END AS PurchasePower
FROM
(
SELECT *,
PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage, 
      SUM(Amount_Paid) AS TotalPurchase
      FROM ProductSalesFact 
      GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = "Household") AS T;

--- Find the Number of customers in each of the categories of derived household customers.

SELECT *,
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END AS PurchasePower
FROM
(Update the c
SELECT *,
PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage, 
      SUM(Amount_Paid) AS TotalPurchase
      FROM ProductSalesFact 
      GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = "Household") AS T;


---  Total purchase within each household category in terms of Quantity they purchased.

SELECT CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END AS PurchasePower,
COUNT(*) AS TotalCustomersBySegment
FROM
(
SELECT *,
PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage, 
      SUM(Amount_Paid) AS TotalPurchase
      FROM ProductSalesFact 
      GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = "Household") AS T
GROUP BY
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END;

--- Total purchase within each household category in terms of total Purchase amount.

SELECT
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END AS PurchasePower,
SUM(TotalPurchase) AS TotalPurchaseBySegment,
SUM(TotalQuantity) AS TotalQuantityBySegment
FROM
(
SELECT *,
PERCENT_RANK() OVER(ORDER BY TotalPurchase) AS _rank
FROM (SELECT Customer_Id, Cust_Usage, 
      SUM(Amount_Paid) AS TotalPurchase,
      SUM(Quantity) AS TotalQuantity
      FROM ProductSalesFact 
      GROUP BY Customer_Id, Cust_Usage) AS T
WHERE Cust_Usage = "Household") AS T
GROUP BY 
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'medicumPurchase'
ELSE 'highPurchase'
END;
