# Retail Management Analysis SQL Queries - README
# Overview
This project consists of multiple SQL queries designed to analyze customer behavior, inventory management, product preferences, and complaint resolution in a retail environment. The aim is to identify patterns that help the company reward loyal customers, manage inventory efficiently, and resolve complaints in order of priority.

# Key Use Cases:
Customer Loyalty & Reward System: Identify top loyal customers based on the length of their association and purchasing activity.
Bulk Purchasing Trends: Find customers with bulk purchases in different segments.
Complaint Management: Prioritize complaints by volume and track the resolution status of complaints.
Product & Inventory Management: Analyze product categories based on sales, returns, and time spent in inventory.
Ranking & Segmentation: Rank customers based on their purchases and create household customer segments based on total purchase power.
Revenue and Complaint Tracking: Weekly comparison of purchase activity and complaint resolution.
Key SQL Queries Breakdown

# Identify the Oldest Customer:

Retrieves the customer who has been with the company for the longest period.
# My Code
SELECT Customer_Id, Name, YEAR(NOW()) - Customer_Since AS TotalYears 
FROM CustomerDim 
ORDER BY TotalYears DESC LIMIT 1;
Top Customers by Purchase Activity (Last Quarter):

# Lists the top 5 customers with the most purchases in the last quarter, sorted by name in case of a tie.
# My Code
SELECT CD.Name, EXTRACT(QUARTER FROM P.DateOfPurchase) AS quarter, COUNT(*) AS TotalPurchases 
FROM ProductSalesFact AS P 
JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY Name, EXTRACT(QUARTER FROM DateOfPurchase) 
ORDER BY TotalPurchases DESC, Name LIMIT 5;

# Bulk Purchasing by Usage Segment: Identifies customers with bulk purchasing in various usage segments in the last quarter.
# My Code
SELECT T1.* 
FROM (SELECT P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM P.DateOfPurchase) AS quarter, SUM(Quantity) AS QuantityPurchased 
FROM ProductSalesFact AS P 
JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY P.Cust_Usage, CD.Name, EXTRACT(QUARTER FROM DateOfPurchase)) AS T1;
Promotion Messages for Top Customers:

# Generates personalized promotional messages for top customers who frequently purchase.
# My Code
SELECT T1.*, 
CONCAT("Congratulations ", Name , "! You are eligible for a coupon of 75% off upto 5000 INR to be redeemed till ", 
DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 30 DAY), '%M %e, %Y'), ". You can find that in your email.") AS promotionmsg 
FROM (SELECT P.Cust_Usage, CD.Name, COUNT(*) AS TotalPurchases 
FROM ProductSalesFact AS P JOIN CustomerDim AS CD ON CD.Customer_Id = P.Customer_Id 
GROUP BY P.Cust_Usage, CD.Name) AS T1;
Inventory Management (Products Older Than 90 Days):

# Identifies product categories with items that have been in inventory for more than 90 days, sorted by total stock price.
# My Code
SELECT Category_Id, COUNT(*) AS TotalProducts, SUM(Price) TotalStockPrice 
FROM ProductDim 
WHERE DATEDIFF(NOW(), In_Inventory) > 90 
GROUP BY Category_Id 
ORDER BY TotalStockPrice DESC;
Customer Ranking by Purchase Amount:

# Ranks customers based on total purchase amount.
# My Code
SELECT Customer_Id, TotalAmountPaid,
RANK() OVER(ORDER BY TotalAmountPaid DESC) AS _Rank,
DENSE_RANK() OVER(ORDER BY TotalAmountPaid DESC) AS DenseRank
FROM (SELECT Customer_Id, SUM(Amount_Paid) AS TotalAmountPaid 
FROM ProductSalesFact 
GROUP BY Customer_Id) AS T;
Complaint Resolution Tracking:

# Prioritizes complaints based on their volume and tracks resolution status.
# My Code
SELECT C.*, P.Category_Id, COUNT(*) OVER(PARTITION BY Category_Id, Resolved) AS TotalComplaintsbyCategory 
FROM Complaints AS C JOIN ProductSalesFact AS PS ON C.Complaint_Id = PS.Complaint_Id 
JOIN ProductDim AS P ON PS.Product_Id = P.Product_Id 
ORDER BY TotalComplaintsbyCategory DESC;
Customer Segmentation by Purchase Power:

# Divides household customers into three segments: low, medium, and high purchase based on ranking by total purchase amount.
# My Code
SELECT *,
CASE 
WHEN _rank < 0.25 THEN 'lowPurchase'
WHEN _rank BETWEEN 0.25 AND 0.75 THEN 'mediumPurchase'
ELSE 'highPurchase'
END AS PurchasePower
FROM (SELECT Customer_Id, SUM(Amount_Paid) AS TotalPurchase 
FROM ProductSalesFact 
WHERE Cust_Usage = 'Household'
GROUP BY Customer_Id) AS T;

# Potential Enhancements:
# Dashboard Creation: Integrate these queries into BI dashboards for real-time monitoring.
# Automated Reporting: Automate the generation of loyalty rewards and promotional messages based on customer activity.
# Product and Complaint Analysis: Use these queries for deeper insights into product categories that experience high return rates or complaint volumes.
# Dependencies:
# Database tables involved: CustomerDim, ProductSalesFact, ProductDim, Complaints.
