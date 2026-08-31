-- ============================================================
-- Customer Sales & Churn Analytics — Cohort & Churn SQL Queries
-- Database: Oracle (tested on 10g)
-- Tables: customers, products, sellers, sales, rfm_scores
-- ============================================================


-- 1. Revenue and customer count by RFM segment
-- Business question: which segments matter most to the business?
SELECT r.Segment,
       COUNT(*) AS customer_count,
       ROUND(SUM(r.Monetary), 2) AS total_revenue,
       ROUND(AVG(r.Monetary), 2) AS avg_revenue_per_customer
FROM rfm_scores r
GROUP BY r.Segment
ORDER BY total_revenue DESC;


-- 2. Top 10 cities by At-Risk revenue
-- Business question: where should a win-back campaign focus geographically?
SELECT City, at_risk_customers, at_risk_revenue FROM (
    SELECT c.City,
           COUNT(*) AS at_risk_customers,
           ROUND(SUM(r.Monetary), 2) AS at_risk_revenue
    FROM rfm_scores r
    JOIN customers c ON r.Customer_ID = c.Customer_ID
    WHERE r.Segment = 'At Risk'
    GROUP BY c.City
    ORDER BY at_risk_revenue DESC
)
WHERE ROWNUM <= 10;


-- 3. Top product categories bought by Champions
-- Business question: what do our best customers buy? Guides upsell campaigns.
SELECT p.Category,
       COUNT(*) AS orders,
       ROUND(SUM(s.Total_Amount), 2) AS revenue
FROM rfm_scores r
JOIN sales s ON r.Customer_ID = s.Customer_ID
JOIN products p ON s.Product_ID = p.Product_ID
WHERE r.Segment = 'Champions'
GROUP BY p.Category
ORDER BY revenue DESC;


-- 4. Payment method preference by segment
-- Business question: do high-value segments prefer different payment methods?
SELECT r.Segment, s.Payment_Method, COUNT(*) AS order_count
FROM rfm_scores r
JOIN sales s ON r.Customer_ID = s.Customer_ID
GROUP BY r.Segment, s.Payment_Method
ORDER BY r.Segment, order_count DESC;


-- 5. Window function: rank each customer's spend within their city
-- Demonstrates PARTITION BY / RANK() — identifies the top spender per city
-- without collapsing rows the way GROUP BY would.
SELECT c.City,
       c.Customer_ID,
       r.Monetary,
       RANK() OVER (PARTITION BY c.City ORDER BY r.Monetary DESC) AS rank_in_city
FROM rfm_scores r
JOIN customers c ON r.Customer_ID = c.Customer_ID
WHERE r.Segment IN ('Champions','Loyal Customers')
ORDER BY c.City, rank_in_city;


-- 6. Window function: monthly revenue with running cumulative total
-- Demonstrates a running total using SUM() OVER (ORDER BY ...)
SELECT TO_CHAR(s.Order_Date,'YYYY-MM') AS month,
       ROUND(SUM(s.Total_Amount),2) AS monthly_revenue,
       ROUND(SUM(SUM(s.Total_Amount)) OVER (ORDER BY TO_CHAR(s.Order_Date,'YYYY-MM')),2) AS cumulative_revenue
FROM sales s
GROUP BY TO_CHAR(s.Order_Date,'YYYY-MM')
ORDER BY month;
