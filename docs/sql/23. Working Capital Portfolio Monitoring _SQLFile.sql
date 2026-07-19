--1. Total Portfolio Customers
SELECT COUNT(DISTINCT Customer_ID) AS Total_Portfolio_Customers
FROM Customers_Table;



--2. Product Wise Distribution
SELECT p.Product_Name, 
COUNT(l.Account_ID) AS Total_Accounts,
SUM(l.Sanctioned_Limit) AS Total_Exposure 
FROM Loan_Account_Table l
JOIN Product_Master p 
ON l.Product_ID = p.Product_ID
GROUP BY p.Product_Name;



--3. Segment Wise Distribution
SELECT s.Segment_Name, 
COUNT(c.Customer_ID) AS Total_Customers 
FROM Customers_Table c
JOIN Segment_Master s 
ON c.Segment_ID = s.Segment_ID
GROUP BY s.Segment_Name;




--4. Top 5 Industry Concentration
SELECT TOP 5 i.Industry_Name, SUM(l.Sanctioned_Limit) AS Total_Exposure FROM Customers_Table c
JOIN Industry_Master i ON c.Industry_ID = i.Industry_ID
JOIN Loan_Account_Table l ON c.Customer_ID = l.Customer_ID
GROUP BY i.Industry_Name
ORDER BY Total_Exposure DESC;




--5. Sanction Vs Utilization
SELECT
l.Customer_ID, l.Account_ID, p.Product_Name, l.Sanctioned_Limit, l.Utilized_Amount,
ROUND(
(l.Utilized_Amount * 100.0) / l.Sanctioned_Limit, 2) 
AS Utilization_Percentage FROM Loan_Account_Table l
JOIN Product_Master p ON l.Product_ID = p.Product_ID
ORDER BY Utilization_Percentage DESC;




--6. Portfolio Level Sanction vs Utilization
SELECT
SUM(Sanctioned_Limit) AS Total_Sanctioned_Limit,
SUM(Utilized_Amount) AS Total_Utilized_Amount,
ROUND(
SUM(Utilized_Amount) * 100.0 /
SUM(Sanctioned_Limit),2) AS Portfolio_Utilization_Percentage 
FROM Loan_Account_Table;




--7.  Product Level Sanction vs Utilization
SELECT p.Product_Name,
SUM(l.Sanctioned_Limit) AS Total_Sanctioned_Limit,
SUM(l.Utilized_Amount) AS Total_Utilized_Amount,
ROUND(SUM(l.Utilized_Amount) * 100.0 / SUM(l.Sanctioned_Limit),2) AS Utilization_Percentage 
FROM Loan_Account_Table l
JOIN Product_Master p 
ON l.Product_ID = p.Product_ID
GROUP BY p.Product_Name
ORDER BY Utilization_Percentage DESC;



--8. SMA / NPA Monitoring
SELECT
CASE
WHEN DPD BETWEEN 1 AND 30 THEN 'SMA-0 (1-30 Days)'
WHEN DPD BETWEEN 31 AND 60 THEN 'SMA-1 (31-60 Days)'
WHEN DPD BETWEEN 61 AND 90 THEN 'SMA-2 (61-90 Days)'
WHEN DPD > 90 THEN 'NPA (>90 Days)'
END AS SMA_Bucket,
COUNT(*) AS Account_Count
FROM Overdue_Status
WHERE DPD > 0
GROUP BY
CASE
WHEN DPD BETWEEN 1 AND 30 THEN 'SMA-0 (1-30 Days)'
WHEN DPD BETWEEN 31 AND 60 THEN 'SMA-1 (31-60 Days)'
WHEN DPD BETWEEN 61 AND 90 THEN 'SMA-2 (61-90 Days)'
WHEN DPD > 90 THEN 'NPA (>90 Days)'
END;



--9. Renewal Pipeline Next 60 Days
SELECT Account_ID, Renewal_Due_Date, Renewal_Status
FROM Renewal_Details
WHERE Renewal_Due_Date BETWEEN GETDATE()
AND DATEADD(DAY,60,GETDATE())
ORDER BY Renewal_Due_Date;


-- 10. Renewal Pending Buckets
SELECT 'TOTAL PENDING ACCOUNTS' AS Customer_Name,
COUNT(*) AS Account_Count, 
NULL AS Account_ID,
NULL AS Renewal_Due_Date 
FROM Renewal_Details
WHERE Renewal_Status = 'Pending'

UNION ALL

SELECT C.Customer_Name, NULL, R.Account_ID, R.Renewal_Due_Date
FROM Renewal_Details R
JOIN Loan_Account_Table L 
ON R.Account_ID = L.Account_ID
JOIN Customers_Table C 
ON L.Customer_ID = C.Customer_ID
WHERE R.Renewal_Status = 'Pending';



--11. High Utilization >80%
SELECT Account_ID, Customer_ID, Product_ID, Sanctioned_Limit, Utilized_Amount,
ROUND(Utilized_Amount*100.0/Sanctioned_Limit,2) AS Utilization_Percentage 
FROM Loan_Account_Table
WHERE Utilized_Amount*100.0/Sanctioned_Limit > 80;



--12. Low Utilization <50% with Customer Name
SELECT C.Customer_Name, L.Account_ID, L.Product_ID, L.Sanctioned_Limit, L.Utilized_Amount,
ROUND(L.Utilized_Amount * 100.0 / L.Sanctioned_Limit, 2) AS Utilization_Percentage
FROM Loan_Account_Table L
JOIN Customers_Table C
ON L.Customer_ID = C.Customer_ID
WHERE L.Utilized_Amount * 100.0 / L.Sanctioned_Limit < 50
ORDER BY L.Sanctioned_Limit DESC;


--13. Total Count Row
SELECT C.Customer_Name, A.Account_ID,
AVG(A.Cash_Inflow) AS Avg_Cash_Inflow,
AVG(G.GST3B_Sales) AS Avg_GST3B_Sales,
ROUND(
(AVG(A.Cash_Inflow) * 100.0) / AVG(G.GST3B_Sales), 2) AS Cashflow_Percentage
FROM Account_Churning A
JOIN Loan_Account_Table L 
ON A.Account_ID = L.Account_ID
JOIN Customers_Table C 
ON L.Customer_ID = C.Customer_ID
JOIN GST3B_Sales G 
ON L.Customer_ID = G.Customer_ID
GROUP BY
C.Customer_Name,A.Account_ID
HAVING AVG(A.Cash_Inflow) < 0.7 * AVG(G.GST3B_Sales);




--14.Interest Not Serviced On Due Date
SELECT C.Customer_Name, I.Account_ID, I.Due_Date, I.Serviced_Date, I.Interest_Amount
FROM Interest_Servicing I
JOIN Loan_Account_Table L
ON I.Account_ID = L.Account_ID
JOIN Customers_Table C
ON L.Customer_ID = C.Customer_ID
WHERE I.Serviced_Date > I.Due_Date OR I.Serviced_Date IS NULL
ORDER BY I.Due_Date;


--15. Deferral Expiring Next 30 Days
SELECT Account_ID, Document_Type, Expiry_Date
FROM Deferral_Documents 
WHERE Expiry_Date BETWEEN GETDATE() AND DATEADD(DAY,30,GETDATE());



--16. Expired Deferrals
SELECT Account_ID, Document_Type, Expiry_Date
FROM Deferral_Documents
WHERE Expiry_Date < GETDATE();



--17. Pending Stock Statements for last 3 months
SELECT C.Customer_Name, S.Account_ID, S.Statement_Month, S.Status
FROM Stock_Statement S
JOIN Loan_Account_Table L
ON S.Account_ID = L.Account_ID
JOIN Customers_Table C
ON L.Customer_ID = C.Customer_ID
WHERE S.Status = 'Pending'
AND S.Statement_Month >= DATEADD(MONTH, -3, GETDATE())
ORDER BY C.Customer_Name;