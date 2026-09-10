-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Mohammed Uddin's Online Retail Database System
-- OnlineRetailDB_schema.sql (currently viewing)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- File breakdown:
-- 1. OnlineRetailDB_schema.sql – Database schema
-- 2. OnlineRetailDB_query_results_screenshots.pdf – Workbench result-grid screenshots
-- 3. OnlineRetailDB_formal_language.pdf
-- 4. OnlineRetailDB_queries.sql – The 7 queries with the inline comments

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

CREATE DATABASE IF NOT EXISTS OnlineRetailDB;

USE OnlineRetailDB;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

SET FOREIGN_KEY_CHECKS = 0; -- MySQL blocks the action and throws Error 3730; orphaned relational dependencies

DROP TABLE IF EXISTS Order_Items;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Product_Suppliers;
DROP TABLE IF EXISTS Suppliers;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Categories;
DROP TABLE IF EXISTS Customers;

SET FOREIGN_KEY_CHECKS = 1; -- MySQL blocks the action and throws Error 3730; orphaned relational dependencies

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

CREATE TABLE Customers (
	CustomerID INT AUTO_INCREMENT PRIMARY KEY,
	First_Name VARCHAR(50) NOT NULL,
	Last_Name VARCHAR(50) NOT NULL,
	Email VARCHAR(100) UNIQUE NOT NULL,
	Phone_Number VARCHAR(20) NOT NULL,
	Street VARCHAR(100) NOT NULL,
	City VARCHAR(50) NOT NULL,
	State VARCHAR(20) NOT NULL,
	Zip_Code VARCHAR(10) NOT NULL
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Parent_Category references CategoryID within this same table. A category can point at another row in 
-- Categories as its parent, and a top-level category just leaves this NULL. It is worth noting this took 
-- a bit to get comfortable with, since it is easy to assume a hierarchy like this needs a separate table 
-- for each level. It doesn't; every row already carries a pointer to its own parent, so the same structure 
-- supports any depth without changing the schema. 

-- GeeksforGeeks has a decent breakdown of how ER relationships map onto relational tables in general:
-- https://www.geeksforgeeks.org/dbms/mapping-from-er-model-to-relational-model/

-- ON DELETE SET NULL rather than CASCADE, since deleting a parent category should orphan its children 
-- back to the top level, not delete them along with it. General overview of what CASCADE actually does 
-- across different actions, for reference: https://www.geeksforgeeks.org/sql/cascade-in-sql/

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ON UPDATE CASCADE is paired with it mostly out of habit more than necessity.

-- It means if a parent's CategoryID ever changed, every child row pointing at it would automatically 
-- update to match instead of the relationship silently breaking. In practice that is unlikely to ever 
-- actually happen here, since CategoryID is AUTO_INCREMENT and nothing in this project updates a primary
-- key once a row exists. I kept it anyway since it costs nothing to have and protects against a case I am 
-- not using now but could run into if the schema changed later, rather than because I expect it to ever 
-- actually trigger.

CREATE TABLE Categories (
	CategoryID INT AUTO_INCREMENT PRIMARY KEY,
	Category_Name VARCHAR(100) NOT NULL UNIQUE,
	Parent_Category INT DEFAULT NULL,
		FOREIGN KEY (Parent_Category)
			REFERENCES Categories(CategoryID)
			ON DELETE SET NULL
			ON UPDATE CASCADE
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- CHECK constraints go directly on the columns instead of relying on an application to validate input before it 
-- reaches the database. A constraint at the schema level holds no matter what's doing the inserting, an app, a
-- script, or someone typing straight into Workbench, where application-side validation only protects the one path 
-- that actually runs through that application.
-- https://www.w3schools.com/sql/sql_check.asp

CREATE TABLE Products (
	ProductID INT AUTO_INCREMENT PRIMARY KEY,
	Product_Name VARCHAR(150) NOT NULL,
	Description TEXT,
	Price DECIMAL(12, 2) NOT NULL CHECK (Price > 0),
	Stock_Quantity INT NOT NULL DEFAULT 0 CHECK (Stock_Quantity >= 0),
	CategoryID INT NOT NULL,
		FOREIGN KEY (CategoryID)
			REFERENCES Categories(CategoryID)
			ON DELETE RESTRICT
			ON UPDATE CASCADE
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
CREATE TABLE Suppliers (
	SupplierID INT AUTO_INCREMENT PRIMARY KEY,
	Supplier_Name VARCHAR(150) NOT NULL,
	Contact_Person VARCHAR(100),
	Phone_Number VARCHAR(20),
	Supplier_Region VARCHAR(50) DEFAULT 'North America'
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

CREATE TABLE Product_Suppliers (
	SupplierID INT NOT NULL,
	ProductID INT NOT NULL,
	Date_Supplied DATE NOT NULL,
	PRIMARY KEY (SupplierID, ProductID),
		FOREIGN KEY (SupplierID)
			REFERENCES Suppliers(SupplierID)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
		FOREIGN KEY (ProductID)
			REFERENCES Products(ProductID)
			ON DELETE CASCADE
			ON UPDATE CASCADE
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

CREATE TABLE Orders (
	OrderID INT AUTO_INCREMENT PRIMARY KEY,
	Order_Date DATETIME DEFAULT CURRENT_TIMESTAMP,
	CustomerID INT NOT NULL,
    Total_Amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
	Status VARCHAR(20) NOT NULL DEFAULT 'Pending'
		CHECK (
			Status IN (
				'Pending',
				'Processing',
				'Shipped',
				'Delivered',
				'Cancelled'
			)
	),
	
	FOREIGN KEY (CustomerID)
		REFERENCES Customers(CustomerID)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

CREATE TABLE Order_Items (
	OrderItemID INT AUTO_INCREMENT PRIMARY KEY,
	OrderID INT NOT NULL,
	ProductID INT NOT NULL,
	Quantity INT NOT NULL CHECK (Quantity > 0),
	Unit_Price DECIMAL(12, 2) NOT NULL CHECK (Unit_Price > 0),
		FOREIGN KEY (OrderID)
			REFERENCES Orders(OrderID)
			ON DELETE CASCADE
			ON UPDATE CASCADE,
		FOREIGN KEY (ProductID)
			REFERENCES Products(ProductID)
			ON DELETE RESTRICT
			ON UPDATE CASCADE
);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Phone numbers use the 555-01XX block on purpose. The 555 exchange, specifically 555-0100 through 555-0199, 
-- is reserved by the North American Numbering Plan for exactly this purpose, fictional use in sample data, so
-- these numbers are guaranteed not to reach a real person no matter which area code they are paired with.
-- https://clearlyip.com/2025/05/07/why-movies-use-555-the-truth-behind-fictional-phone-numbers/

INSERT INTO Customers (First_Name, Last_Name, Email, Phone_Number, Street, City, State, Zip_Code)
	VALUES
		('Michael', 'Turner', 'michael.turner82@gmail.com', '305-555-0142', '482 Palm Grove Lane', 'Miami', 'FL', '33131'),
		('Daniel', 'Brooks', 'd.brooks@yahoo.com', '702-555-0187', '1620 Desert Ridge Drive, Unit 3B', 'Las Vegas', 'NV', '89101'),
		('Sarah', 'Mitchell', 'sarah.mitchell@outlook.com', '212-555-0129', '214 Prince Street, Apt 5', 'New York', 'NY', '10012'),
		('Robert', 'Chen', 'robert.chen19@gmail.com', '310-555-0163', '456 Sunset Blvd', 'Los Angeles', 'CA', '90028'),
		('Emily', 'Carter', 'emily.carter@icloud.com', '615-555-0118', '905 Music Row', 'Nashville', 'TN', '37203'),
		('Amanda', 'Price', 'amanda.price@gmail.com', '212-555-0154', '77 Orchard Street, Apt 12', 'New York', 'NY', '10002'),
		('Kevin', 'Alvarez', 'kevin.alvarez@yahoo.com', '305-555-0176', '233 Ocean Drive, Unit 402', 'Miami', 'FL', '33139'),
		('Marcus', 'Bennett', 'marcus.bennett@gmail.com', '404-555-0133', '410 Peachtree Street', 'Atlanta', 'GA', '30301'),
		('Rachel', 'Simmons', 'rachel.simmons@outlook.com', '713-555-0197', '318 Main Street', 'Houston', 'TX', '77002'),
		('Justin', 'Cole', 'justin.cole@gmail.com', '212-555-0148', '145 Canal Street, Apt 3', 'New York', 'NY', '10013'),
		('Olivia', 'Grant', 'olivia.grant@icloud.com', '310-555-0121', '9200 Wilshire Boulevard, Suite 210', 'Los Angeles', 'CA', '90210'),
		('Vikram', 'Nair', 'vikram.nair@gmail.com', '212-555-0169', '250 West 57th Street, Apt 14B', 'New York', 'NY', '10019'),
		('Farhan', 'Ahmed', 'farhan.ahmed@yahoo.com', '310-555-0155', '1712 Vine Street', 'Los Angeles', 'CA', '90028'),
		('Nathan', 'Reed', 'nathan.reed@gmail.com', '310-555-0138', '24500 Pacific Coast Highway', 'Malibu', 'CA', '90265'),
		('Christopher', 'Lane', 'chris.lane@outlook.com', '310-555-0182', '822 Figueroa Street', 'Los Angeles', 'CA', '90001'),
		('Laura', 'Bishop', 'laura.bishop@gmail.com', '310-555-0117', '3200 Cahuenga Boulevard, Apt 6', 'Los Angeles', 'CA', '90068'),
		('Derek', 'Foster', 'derek.foster@yahoo.com', '718-555-0193', '112 Bedford Avenue', 'New York', 'NY', '11206'),
		('Srinivas', 'Rao', 'srinivas.rao@gmail.com', '512-555-0126', '600 Congress Avenue, Suite 8', 'Austin', 'TX', '78701'),
		('Ethan', 'Parker', 'ethan.parker@icloud.com', '212-555-0161', '150 West 30th Street, Apt 9', 'New York', 'NY', '10001'),
		('Lucas', 'Bergman', 'lucas.bergman@gmail.com', '212-555-0144', '85 Broad Street', 'New York', 'NY', '10005');

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

INSERT INTO Categories (Category_Name, Parent_Category)
	VALUES
		('Electronics', NULL),
		('Laptops', 1),
		('Smartphones', 1),
		('Apparel', NULL),
		('Accessories', 4),
		('Luxury Watches', 5),
		('Fine Jewelry', 5),
		('Luxury Phone Cases', 3);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

INSERT INTO Products (Product_Name, Description, Price, Stock_Quantity, CategoryID)
	VALUES
		('Gold-Plated MacBook Pro 16', 'Custom 24K Gold 32GB RAM 1TB SSD', 4999.99, 10, 2),
		('iPhone 17 Pro Max (24K Gold Edition)', 'Custom 24K gold-plated chassis, 1TB, Titanium Core', 4999.99, 5, 3),
		('iPhone 16 Pro Max (24K Gold Edition)', '24K gold-plated backplate and frame, 1TB', 3499.99, 3, 3),
		('iPhone 18 Pro Max (24K Gold Edition)', 'Pre-order 24K Gold Prototype with variable aperture camera', 5999.99, 2, 3),
		('iPhone Fold Ultra (24K Gold and Diamond Edition)', 'Custom foldable 24K gold body with VVS diamond hinge accents', 8999.99, 1, 3),
		('Patek Philippe Grandmaster Chime 6300G', 'White gold dual-dial with 20 complications', 3200000.00, 1, 6),
		('Rolex Daytona Rainbow 116595RBOW', '18K Everose gold with factory rainbow baguette sapphire bezel', 450000.00, 3, 6),
		('Jacob and Co. Astronomia Tourbillon', 'Gravitational triple-axis tourbillon with rotating magnesium Earth', 1100000.00, 0, 6),
		('Custom FIFA World Cup Championship Ring', 'Solid 18K Yellow Gold with 15 carats of VVS diamonds and emerald accents', 250000.00, 2, 7),
		('Solid Gold FIFA Winners Trophy Ring', '18K Rose Gold signet ring featuring a three-dimensional replica World Cup trophy in pave diamonds', 85000.00, 4, 7),
		('20mm Bustdown Cuban Link Chain', '18K Yellow Gold iced with 45 carats of VVS Flawless diamonds', 125000.00, 3, 7),
		('Custom Gold Pendant and Franco Chain', '14K Solid Gold heavy Franco chain with custom diamond-paved emblem', 45000.00, 5, 7),
		('3-Carat VVS Diamond Stud Earrings', 'Unisex 18K White Gold screw-back solitaire diamond studs', 28000.00, 8, 7),
		('Baguette Diamond Hoop Earrings', 'Unisex 18K Yellow Gold hoops lined with channel-set baguette diamonds', 18500.00, 10, 7),
		('24K Solid Gold PlayStation 5 Pro', 'Custom 24K solid gold housing with dual gold controllers', 12500.00, 2, 1),
		('Bugatti Chiron Diamond Key Fob', 'Platinum casing set with 10 carats of black and white diamonds', 45000.00, 4, 5),
		('Audemars Piguet Royal Oak Offshore Gold', '18K Yellow Gold with custom baguette diamond bezel', 75000.00, 2, 6),
		('Custom 100-Carat Diamond Tennis Necklace', 'Solid 18K White Gold iced out with round brilliant diamonds', 350000.00, 1, 7),
		('1kg 999.9 Fine Gold Bullion Bar', 'Investment grade stamped 24K solid gold bar with serial certification', 95000.00, 10, 7),
		('Richard Mille RM 56-02 Sapphire Tourbillon', 'Pure sapphire crystal case with cable-suspended movement architecture', 2200000.00, 1, 6),
		('Vacheron Constantin Overseas Perpetual Calendar', '18K 5N Pink Gold case with ultra-thin perpetual calendar movement', 115000.00, 2, 6),
		('15mm 18K Solid Gold Mariner Anchor Chain', 'Heavy 500g solid 18K yellow gold diamond-cut mariner link chain', 65000.00, 3, 7),
		('Graduated VVS Diamond Tennis Chain', '18K White Gold setting with 50 carats of graduated round brilliant diamonds', 185000.00, 2, 7),
		('Cartier High Jewelry Diamond and Emerald Panther Bracelet', '18K White Gold paved with brilliant diamonds, emerald eyes, and onyx spots', 320000.00, 1, 7),
		('22K Heavy Bustdown Cuban Link Bracelet', 'Solid 22K Gold bracelet paved with 20 carats of VVS diamonds', 55000.00, 4, 7),
		('22K Solid Gold Royal Temple Jhumka Earrings', 'Handcrafted 22K gold bridal Jhumkas with natural Burmese rubies and pearls', 32000.00, 5, 7),
		('24K Fine Gold Uncut Diamond Kundan Jhumkas', 'Traditional 24K gold Jhumkas with Kundan setting and drop pearls', 48000.00, 3, 7),
		('22K Solid Gold Heavy Bridal Anklet Payal Set', 'Pair of handcrafted 22K gold anklets with antique finish and ghungroo bells', 38000.00, 4, 7),
		('Diamond-Encrusted 18K Gold Ankle Bracelet', 'Sleek 18K Yellow Gold leg chain lined with 8 carats of VVS diamonds', 24500.00, 6, 7),
		('Van Cleef and Arpels Alhambra 20-Motif Gold Necklace', '18K Yellow Gold vintage Alhambra necklace with guilloche motifs', 68000.00, 2, 7),
		('Solid Titanium Armor iPhone Case', 'Aerospace-grade Grade 5 titanium chassis with custom Damascus steel back insert', 4500.00, 8, 8),
		('VVS Diamond-Encrusted 18K Rose Gold iPhone Case', 'Solid 18K rose gold frame iced with 15 carats of VVS round brilliant diamonds', 85000.00, 2, 8),
		('Forged Carbon Fiber and Black Diamond Case', 'Aerospace forged carbon fiber backplate inlaid with 5 carats of natural black diamonds', 18500.00, 5, 8),
		('24K Solid Gold and Emerald Executive Case', '24K yellow gold rear plate accented with 4 carats of natural Colombian emeralds', 62000.00, 3, 8),
		('Pure Platinum and Solitaire Diamond iPhone Case', 'Solid 950 Platinum housing featuring a 2-carat D-Flawless solitaire center diamond', 120000.00, 1, 8);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

INSERT INTO Suppliers (Supplier_Name, Contact_Person, Phone_Number, Supplier_Region)
	VALUES
		('Apex Luxury Vaults', 'Sarah Jenkins', '212-555-0199', 'North America'),
		('Crown Jewelers Group', 'David Chen', '310-555-0288', 'North America'),
		('Genevan Horology Guild', 'Marco Rossi', '442-555-0377', 'Europe');

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

INSERT INTO Product_Suppliers (SupplierID, ProductID, Date_Supplied)
	VALUES
		(1, 2, '2026-01-10'),
		(2, 2, '2026-01-12'),
		(1, 3, '2026-01-15'),
		(2, 3, '2026-01-18'),
		(1, 4, '2026-01-20'),
		(2, 4, '2026-01-22'),
		(1, 5, '2026-01-25'),
		(2, 5, '2026-01-28'),
		(3, 6, '2026-02-01'),
		(3, 8, '2026-02-05'),
		(2, 9, '2026-02-10'),
		(2, 11, '2026-02-12'),
		(1, 15, '2026-02-15'),
		(2, 18, '2026-02-20'),
		(3, 20, '2026-02-21'),
		(2, 22, '2026-02-22'),
		(2, 24, '2026-02-23'),
		(2, 26, '2026-02-24'),
		(2, 28, '2026-02-25'),
		(1, 31, '2026-02-26'),
		(2, 32, '2026-02-27'),
		(2, 35, '2026-02-28');

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

INSERT INTO Orders (CustomerID, Order_Date, Total_Amount, Status)
	VALUES
		(1, '2026-02-01 10:00:00', 23499.96, 'Shipped'),
		(1, '2026-02-05 14:30:00', 250000.00, 'Delivered'),
		(2, '2026-02-10 09:15:00', 450000.00, 'Pending'),
		(3, '2026-02-12 11:20:00', 125000.00, 'Pending'),
		(4, '2026-02-15 16:45:00', 3200000.00, 'Shipped'),
		(5, '2026-02-18 18:00:00', 28000.00, 'Delivered'),
		(8, '2026-02-20 20:00:00', 12500.00, 'Processing'),
		(9, '2026-02-22 12:00:00', 320000.00, 'Delivered'),
		(3, '2026-02-25 15:10:00', 70000.00, 'Shipped'),
		(11, '2026-02-28 17:30:00', 85000.00, 'Shipped');

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

INSERT INTO Order_Items (OrderID, ProductID, Quantity, Unit_Price)
	VALUES
		(1, 2, 1, 4999.99),
		(1, 3, 1, 3499.99),
		(1, 4, 1, 5999.99),
		(1, 5, 1, 8999.99),
		(2, 9, 1, 250000.00),
		(3, 7, 1, 450000.00),
		(4, 11, 1, 125000.00),
		(5, 6, 1, 3200000.00),
		(6, 13, 1, 28000.00),
		(7, 15, 1, 12500.00),
		(8, 24, 1, 320000.00),
		(9, 26, 1, 32000.00),
		(9, 28, 1, 38000.00),
		(10, 32, 1, 85000.00);

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- 'Cancelled' status edge case the assignment specifically asks the sample data to cover. No 
-- Order_Status_History table in this required-only version, so there's nothing further to log 
-- alongside it here, this just sets the Status column itself on an existing order.
UPDATE Orders
SET Status = 'Cancelled'
WHERE OrderID = 4;
