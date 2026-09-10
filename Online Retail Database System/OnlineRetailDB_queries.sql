-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Mohammed Uddin's 7 Queries for Online Retail Database System
-- OnlineRetailDB_queries.sql (currently viewing)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- File breakdown:
-- 1. OnlineRetailDB_schema.sql – Database schema
-- 2. OnlineRetailDB_query_results_screenshots.pdf – Workbench result-grid screenshots
-- 3. OnlineRetailDB_formal_language.pdf
-- 4. OnlineRetailDB_queries.sql – The 7 queries with the inline comments

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Query 1: Customers Who Have Ordered Every Product in a Specific Category. Retrieve the First_Name, Last_Name, and
-- Email of all customers who have placed orders for every single product that belongs to the 'Electronics'
-- category.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

USE OnlineRetailDB;
-- "Electronics products" here means Electronics itself plus every descendant category beneath it, Laptops,
-- Smartphones, and so on, (using the same recursive pattern as Query 4 below). The first version of this query only
-- matched products assigned directly to Electronics, and the result set it returned looked fine on the surface.
-- Looking back at the actual product data made it obvious something was off: almost nothing is assigned directly to
-- Electronics, everything sits one level down in Laptops or Smartphones. So the original query was really only
-- checking whether a customer bought the one product in the parent category, not the category as a whole, which
-- isn't what the question means.

-- https://dev.mysql.com/doc/refman/8.0/en/with.html
-- https://stackoverflow.com/questions/18840998/recursive-in-sql

WITH RECURSIVE ElectronicsCategoryTree AS (
    -- Starting point of the recursion, just the Electronics row itself.
    SELECT CategoryID FROM Categories WHERE Category_Name = 'Electronics'

    UNION ALL

    -- Joins the CTE back to Categories to pull in whatever is one level further down each pass,
    -- stopping on its own once nothing new matches.
    SELECT child_categories.CategoryID FROM Categories AS child_categories
    
    INNER JOIN ElectronicsCategoryTree ON child_categories.Parent_Category = ElectronicsCategoryTree.CategoryID
)

-- Division by counting instead of the nested NOT EXISTS pattern. The idea: join each customer
-- to every Electronics-tree product they've actually ordered, then GROUP BY collapses that down to one row per
-- customer with a count of how many distinct products showed up. HAVING keeps only the customers whose count
-- matches the total number of Electronics-tree products that exist, since matching the full count is the only way
-- to have ordered every single one of them. Same underlying logic as Query 3, just reached through counting
-- instead of double negation.
SELECT
    customers.CustomerID,
    customers.First_Name,
    customers.Last_Name,
    customers.Email

FROM Customers AS customers
	-- INNER JOIN Orders AS orders ON orders.CustomerID = customers.CustomerID AND orders.Status != 'Cancelled'
	INNER JOIN Orders AS orders ON orders.CustomerID = customers.CustomerID AND orders.Status <> 'Cancelled'
	INNER JOIN Order_Items AS order_items ON order_items.OrderID = orders.OrderID
	INNER JOIN Products AS electronics_products ON electronics_products.ProductID = order_items.ProductID
    
    AND electronics_products.CategoryID IN (SELECT CategoryID FROM ElectronicsCategoryTree)

	GROUP BY customers.CustomerID, customers.First_Name, customers.Last_Name, customers.Email

	HAVING COUNT(DISTINCT electronics_products.ProductID) = (
    SELECT COUNT(*) FROM Products WHERE CategoryID IN (SELECT CategoryID FROM ElectronicsCategoryTree)
	);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Query 2: Top 3 Categories by Total Revenue (Excluding Cancelled Orders). Identify the top 3 Category_Names that
-- have generated the highest total revenue from products sold, considering only orders with a Status of 'Shipped'
-- or 'Delivered'.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
USE OnlineRetailDB;

SELECT
    categories.Category_Name,
    SUM(order_items.Quantity * order_items.Unit_Price) AS Category_Total_Revenue

	FROM Categories AS categories
		INNER JOIN Products AS products ON categories.CategoryID = products.CategoryID
		INNER JOIN Order_Items AS order_items ON products.ProductID = order_items.ProductID
		INNER JOIN Orders AS orders ON order_items.OrderID = orders.OrderID

	WHERE orders.Status IN ('Shipped', 'Delivered')

	-- SUM() is an aggregate function, so SQL needs GROUP BY to know which rows belong together before it can add
	-- anything. Skip the GROUP BY and the SUM just collapses the entire result set into one number instead of one
	-- total per category. Category_Name is technically determined by CategoryID alone, so grouping by CategoryID
	-- would be enough on its own, but including both here felt like the safer move rather than leaning on that
	-- relationship implicitly.
	GROUP BY categories.CategoryID, categories.Category_Name
	ORDER BY Category_Total_Revenue DESC

LIMIT 3;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Query 3: Products Supplied by All Suppliers in a Specific Region (Conceptual). Retrieve the Product_Name and
-- Price of products that are supplied by all suppliers located in the 'North America' region.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

USE OnlineRetailDB;
-- This one stays as double NOT EXISTS rather than the counting approach Query 1 uses above, mainly because the
-- Tuple Relational Calculus version of this exact question in the Section 5 document uses a universal quantifier
-- and an implication, and this structure maps onto that reasoning more directly than a count comparison would.

SELECT products.Product_Name, products.Price FROM Products AS products

WHERE NOT EXISTS (
    SELECT 1 FROM Suppliers AS suppliers
    
    WHERE suppliers.Supplier_Region = 'North America'
    AND NOT EXISTS (
        SELECT 1 FROM Product_Suppliers AS product_suppliers
        
        WHERE product_suppliers.ProductID = products.ProductID
		 AND product_suppliers.SupplierID = suppliers.SupplierID
    )
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Query 4: Recursive Category Hierarchy (All Descendants). List all Category_Names that are subcategories, direct
-- or indirect, of the 'Electronics' category, including Electronics itself.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

USE OnlineRetailDB;
-- Walks down the category tree starting from Electronics, through however many child categories exist beneath it,
-- Laptops, Smartphones, and any further levels if they existed. Getting the UNION ALL structured correctly took a
-- couple of tries; it's not obvious at first that the two halves are doing different jobs. The first SELECT, the
-- anchor member, just finds Electronics itself. The second SELECT, the recursive member, is the one that actually
-- repeats, joining the CTE back to Categories to pull in the next level down each time, until there are no more
-- child categories left to find. The Fibonacci example in the MySQL docs is what finally made the mechanics click:
-- https://dev.mysql.com/doc/refman/8.0/en/with.html

WITH RECURSIVE CategoryHierarchy AS (

    SELECT CategoryID, Category_Name, Parent_Category, 0 AS Hierarchy_Level
    FROM Categories
    WHERE Category_Name = 'Electronics'

    UNION ALL

    SELECT 
        child_categories.CategoryID, 
        child_categories.Category_Name, 
        child_categories.Parent_Category, 
        CategoryHierarchy.Hierarchy_Level + 1 -- Without + 1, every row retrieved would stay hardcoded at 0.
    
    FROM Categories AS child_categories
    
    INNER JOIN CategoryHierarchy ON child_categories.Parent_Category = CategoryHierarchy.CategoryID
    
)

SELECT CategoryID, Category_Name, Parent_Category, Hierarchy_Level FROM CategoryHierarchy
ORDER BY Hierarchy_Level, CategoryID;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Query 5: Orders with Mixed Status Items. Find the OrderIDs and Order_Dates of orders containing at least one item
-- from a product that also appears in a Shipped order, AND at least one item from a product that also appears in a
-- Pending order.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

USE OnlineRetailDB;
-- The double EXISTS version of this technically works but it's checking the same relationship twice from two
-- different directions, which felt like more machinery than the question actually needs. What the condition
-- really boils down to is: does this order contain a product that shows up somewhere in the Shipped group and
-- somewhere in the Pending group at the same time. That's just an intersection of two product lists, so two small
-- CTEs plus a couple of plain joins get the same result with far less nesting.

WITH ShippedProducts AS (
    SELECT DISTINCT order_items.ProductID
    FROM Order_Items AS order_items
		INNER JOIN Orders AS orders ON orders.OrderID = order_items.OrderID
		WHERE orders.Status = 'Shipped'
),

PendingProducts AS (
    SELECT DISTINCT order_items.ProductID
    FROM Order_Items AS order_items
		INNER JOIN Orders AS orders ON orders.OrderID = order_items.OrderID
		WHERE orders.Status = 'Pending'
)

SELECT DISTINCT orders.OrderID, orders.Order_Date
FROM Orders AS orders

	-- Verifies the order contains at least one item matching the Shipped products pool...
	WHERE EXISTS (
		SELECT 1 FROM Order_Items AS order_items
		INNER JOIN ShippedProducts ON ShippedProducts.ProductID = order_items.ProductID
		WHERE order_items.OrderID = orders.OrderID
	)

	-- ...AND at least one item matching the Pending products pool (which can be a completely different product in the same order).
	AND EXISTS (
		SELECT 1 FROM Order_Items AS order_items
		INNER JOIN PendingProducts ON PendingProducts.ProductID = order_items.ProductID
		WHERE order_items.OrderID = orders.OrderID
	);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Query 6: Customers with Above-Average Spending in Their Top Category. For each customer, identify their
-- CustomerID, First_Name, Last_Name, and the Category_Name they have spent the most money in. Only include
-- customers whose spending in that top category exceeds the overall average spending per customer across all
-- categories.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

USE OnlineRetailDB;
-- Three CTEs feeding into each other, since this really is three separate questions chained together rather than
-- one query. First, how much has each customer spent in each category. Second, out of those, which category is each
-- customer's single highest one. Third, what's the average total spending across all customers, so there's
-- something to actually compare the top category against.
-- https://dev.mysql.com/doc/refman/8.0/en/with.html
WITH CustomerCategorySpending AS (
    SELECT
        customers.CustomerID, customers.First_Name, customers.Last_Name,
        categories.CategoryID, categories.Category_Name,
        SUM(order_items.Quantity * order_items.Unit_Price) AS Category_Spending
   
   FROM Customers AS customers
		INNER JOIN Orders AS orders ON customers.CustomerID = orders.CustomerID
		INNER JOIN Order_Items AS order_items ON orders.OrderID = order_items.OrderID
		INNER JOIN Products AS products ON order_items.ProductID = products.ProductID
		INNER JOIN Categories AS categories ON products.CategoryID = categories.CategoryID
    
    WHERE orders.Status <> 'Cancelled'
    GROUP BY customers.CustomerID, customers.First_Name, customers.Last_Name, categories.CategoryID, categories.Category_Name
),

TopCategoryPerCustomer AS (
    -- ROW_NUMBER() here numbers each customer's categories from highest spending to lowest, restarting back at 1
    -- for every new customer because of PARTITION BY CustomerID. Category_Rank = 1 is what "top category" actually
    -- means once this runs.
    SELECT
        CustomerID, First_Name, Last_Name, CategoryID, Category_Name, Category_Spending,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID 
            ORDER BY Category_Spending DESC, CategoryID ASC
        ) AS Category_Rank
    FROM CustomerCategorySpending
),

AverageCustomerSpending AS (
    -- This inner subquery computes one total per customer first, cancelled orders excluded, and only then averages
    -- those totals together. Averaging Orders.Total_Amount directly, without collapsing to one row per customer
    -- first, would have quietly computed the average order instead of the average customer, which is a different
    -- number entirely.
    SELECT AVG(Customer_Total_Spending) AS Average_Spending
    FROM (
        SELECT
            customers.CustomerID,
            COALESCE(SUM(CASE WHEN orders.Status <> 'Cancelled' THEN orders.Total_Amount ELSE 0 END), 0) AS Customer_Total_Spending
        FROM Customers AS customers
        LEFT JOIN Orders AS orders ON customers.CustomerID = orders.CustomerID
        GROUP BY customers.CustomerID
    ) AS CustomerTotals
)

SELECT
    TopCategoryPerCustomer.CustomerID,
    TopCategoryPerCustomer.First_Name,
    TopCategoryPerCustomer.Last_Name,
    TopCategoryPerCustomer.Category_Name,
    TopCategoryPerCustomer.Category_Spending
    
    -- CROSS JOIN here is intentional, not a mistake. Average_Spending is a single number with no CustomerID to join
    -- against, so every customer row just needs that same one number attached to it in order to compare against it
    -- in the WHERE clause below.
	FROM TopCategoryPerCustomer
	CROSS JOIN AverageCustomerSpending
	WHERE TopCategoryPerCustomer.Category_Rank = 1
	  AND TopCategoryPerCustomer.Category_Spending > AverageCustomerSpending.Average_Spending

	ORDER BY TopCategoryPerCustomer.Category_Spending DESC;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Query 7: Supplier Performance Score. For each supplier, calculate a Supplier_Score as (Total Quantity Supplied of
-- In-Stock Products) minus (Count of Products Supplied That Are Currently Out-of-Stock). Display Supplier_Name and
-- Supplier_Score, including suppliers who might not have any in-stock products.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

USE OnlineRetailDB;
-- LEFT JOIN going from Suppliers into Product_Suppliers and Products, not INNER JOIN, because the question
-- specifically says to include suppliers who might not have any in-stock products. An INNER JOIN would just drop a
-- supplier out of the results entirely once none of their products have stock left, which makes them look like they
-- don't exist rather than showing an accurate, possibly low or negative, score.

-- The two CASE expressions carry the actual scoring logic: the first only counts a product's stock toward the total
-- once that stock is above zero, and the second counts how many of a supplier's products currently sit at zero.
-- COALESCE around the first SUM matters because a supplier who matched through the LEFT JOIN but has zero in-stock
-- products would otherwise return NULL there instead of 0, and NULL minus anything is just NULL, which would
-- silently wipe out the whole score.

-- https://www.w3schools.com/sql/func_mysql_coalesce.asp
-- https://www.w3schools.com/sql/sql_case.asp
SELECT
    suppliers.Supplier_Name,
    COALESCE(SUM(CASE WHEN products.Stock_Quantity > 0 THEN products.Stock_Quantity ELSE 0 END), 0)
    - SUM(CASE WHEN products.Stock_Quantity = 0 THEN 1 ELSE 0 END) AS Supplier_Score

FROM Suppliers AS suppliers
	LEFT JOIN Product_Suppliers AS product_suppliers 
		ON suppliers.SupplierID = product_suppliers.SupplierID
	LEFT JOIN Products AS products 
		ON product_suppliers.ProductID = products.ProductID
	
    GROUP BY suppliers.SupplierID, suppliers.Supplier_Name
	ORDER BY Supplier_Score DESC;
