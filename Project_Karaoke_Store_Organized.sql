-- Data imports are done with Import Wizard

-- Look up Tables
CREATE TABLE tblGender
(GenderID int IDENTITY(1,1) PRIMARY KEY,
GenderName varchar(10) NOT NULL)

CREATE TABLE tblRegion
(RegionID INT IDENTITY(1,1) PRIMARY KEY,
RegionName varchar(50) NOT NULL)

CREATE TABLE tblRating
(RatingID INT IDENTITY(1,1) PRIMARY KEY,
RatingName varchar(30) NOT NULL,
RatingNumeric NUMERIC(2,1) NOT NULL
)

CREATE TABLE tblSong
(SongID INT IDENTITY(1,1) PRIMARY KEY,
DatePublished DATE NOT NULL,
SongName varchar(200) NOT NULL
)

-- Transactional Tables and Nested Stored Procedures
CREATE TABLE tblCountry
(CountryID INT IDENTITY (1,1) PRIMARY KEY,
RegionID INT FOREIGN KEY REFERENCES tblRegion(RegionID) NOT NULL,
CountryName varchar(50) NOT NULL)

GO
CREATE PROCEDURE get_regionid
@NRegionName varchar(50),
@R_ID INT OUTPUT
AS
SET @R_ID = (SELECT RegionID FROM tblRegion WHERE RegionName = @NRegionName)
GO
CREATE PROCEDURE insert_country
@RegionName varchar(50),
@CountryName varchar(50)
AS
DECLARE @RegionID INT

EXEC get_regionid
@NRegionName = @RegionName,
@R_ID = @RegionID OUTPUT

IF @RegionID IS NULL
    BEGIN
        PRINT '@RegionID came back empty, check spelling';
        THROW 55555, '@RegionID cannot be empty, process is terminating',1;
    END
BEGIN TRAN T22
INSERT INTO tblCountry (RegionID, CountryName)
VALUES (@RegionID, @CountryName)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN T22
    END
ELSE
    COMMIT TRAN T22
GO
-----

CREATE TABLE tblCustomer
(CustID INT IDENTITY (1,1) PRIMARY KEY,
CustFName varchar(30) NOT NULL,
CustLName varchar(30) NOT NULL,
CustBirth DATE NOT NULL,
GenderID INT FOREIGN KEY REFERENCES tblGender(GenderID) NOT NULL,
CountryID INT FOREIGN KEY REFERENCES tblCountry(CountryID) NOT NULL
)
GO

CREATE PROC get_custid
@F varchar(30),
@L varchar(30),
@B DATE,
@C_ID INT OUT
AS
SET @C_ID = (SELECT CustID 
FROM tblCustomer 
WHERE CustFName = @F
AND CustLName = @L
AND CustBirth = @B)


GO
CREATE OR ALTER PROCEDURE insert_customer
@CustFName varchar(30),
@CustLName varchar(30),
@CustBirth DATE,
@GenderName varchar(10),
@CountryName varchar(50)
AS
DECLARE @GenderID INT, @CountryID INT

SET @GenderID = (SELECT GenderID FROM tblGender WHERE GenderName = @GenderName)

IF @GenderID IS NULL
    BEGIN
        PRINT '@GenderID is empty... check spelling';
        THROW 54462, '@GenderID cannot be null; process is terminating', 1;
    END

SET @CountryID = (SELECT CountryID FROM tblCountry WHERE CountryName = @CountryName)

IF @CountryID IS NULL
    BEGIN
        PRINT '@CountryID is empty... check spelling';
        THROW 54466, '@CountryID cannot be null; process is terminating',1;
    END

BEGIN TRANSACTION T1
INSERT INTO tblCustomer (CustFName, CustLName, CustBirth, GenderID, CountryID)
VALUES (@CustFName, @CustLName, @CustBirth, @GenderID, @CountryID)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION T1
    END
ELSE
    COMMIT TRANSACTION T1
GO
SELECT * FROM tblLocation
----------------
CREATE TABLE tblLocation
(LocationID INT IDENTITY (1,1) PRIMARY KEY,
RegionID INT FOREIGN KEY REFERENCES tblRegion(RegionID) NOT NULL,
LocationType varchar(30) NOT NULL,
)
GO
CREATE OR ALTER PROCEDURE insert_location
@RegionName varchar(50),
@LocationType varchar(30)
AS
DECLARE @RegionID INT
EXEC get_regionid
@NRegionName = @RegionName,
@R_ID = @RegionID OUTPUT
IF @RegionID IS NULL
    BEGIN
        PRINT '@RegionID came back empty, please check spelling.';
        THROW 50001, '@RegionID cannot be empty, process terminating', 1;
    END
BEGIN TRAN T2
INSERT INTO tblLocation (RegionID, LocationType)
VALUES (@RegionID, @LocationType)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN T2
    END
ELSE
    COMMIT TRAN T2
----------------

CREATE TABLE tblRoom
(RoomID INT IDENTITY(1,1) PRIMARY KEY,
LocationID INT FOREIGN KEY REFERENCES tblLocation(LocationID) NOT NULL,
RoomNumber varchar(4) NOT NULL
)
GO

CREATE PROC get_locid
@NLocationType varchar(20),
@NRegionName varchar(50),
@L_ID INT OUT
AS
SET @L_ID = (SELECT LocationID FROM tblLocation L
                    JOIN tblRegion R ON L.RegionID = R.RegionID
                   WHERE RegionName = @NRegionName AND LocationType = @NLocationType)
GO
CREATE OR ALTER PROCEDURE insert_room
@RegionName varchar(50),
@LocationType VARCHAR(20),
@RoomNumber varchar(4)
AS
DECLARE @LocationID INT
EXEC get_locid
@NLocationType = @LocationType,
@NRegionName = @RegionName,
@L_ID = @LocationID OUT
IF @LocationID IS NULL
    BEGIN
        PRINT '@LocationID came back empty, please check spelling.';
        THROW 54444, '@LocationID cannot be null, process is terminating', 1;
    END

BEGIN TRAN T3
INSERT INTO tblRoom (LocationID, RoomNumber)
VALUES (@LocationID, @RoomNumber)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN T3
    END
ELSE
    COMMIT TRAN T3
----------------

CREATE TABLE tblCustomer_Room
(CustRoomID INT IDENTITY(1,1) PRIMARY KEY,
CustID INT FOREIGN KEY REFERENCES tblCustomer(CustID) NOT NULL,
RoomID INT FOREIGN KEY REFERENCES tblROOM(RoomID) NOT NULL,
StartTime DATETIME NOT NULL,
EndTime DATETIME NOT NULL)
GO
CREATE OR ALTER PROCEDURE insert_custroom
@CFName varchar(30),
@CLName varchar(30),
@CBirth DATE,
@RoomNum varchar(4),
@StartTime DATETIME,
@EndTime DATETIME
AS
DECLARE @CustID INT, @RoomID INT
SET @CustID = (SELECT CustID FROM tblCustomer WHERE CustFName = @CFName AND CustLName = @CLName AND CustBirth = @CBirth)
IF @CustID IS NULL
    BEGIN
        PRINT '@CustID came back empty, please check spelling';
        THROW 54435, '@CustID cannot be null, process terminating',1;
    END
SET @RoomID = (SELECT RoomID FROM tblRoom WHERE RoomNumber = @RoomNum)
IF @RoomID IS NULL
    BEGIN
        PRINT 'Yo @RoomID is empty, please check spelling'
        RAISERROR ('@RoomID cannot be empty, process is terminating',11,1)
        RETURN
    END
BEGIN TRAN T4
INSERT INTO tblCustomer_Room (CustID, RoomID, StartTime, EndTime)
VALUES (@CustID, @RoomID, @StartTime, @EndTime)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN T4
    END
ELSE
    COMMIT TRAN T4
----------------

CREATE TABLE tblArtist
(ArtistID INT IDENTITY(1,1) PRIMARY KEY,
ArtistName varchar(100) NOT NULL,
CountryID INT FOREIGN KEY REFERENCES tblCOUNTRY(CountryID) NOT NULL,
ArtistTypeID INT FOREIGN KEY REFERENCES tblArtist_Type(ArtistTypeID) NOT NULL,
GenderID INT FOREIGN KEY REFERENCES tblGENDER(GenderID) NOT NULL)

GO
CREATE OR ALTER PROCEDURE insert_artist
@ArtistName varchar(100),
@CountryName varchar(50),
@ArtistTypeName varchar(50),
@GenderName varchar(10)
AS
DECLARE @CountryID INT, @ArtistTypeID INT, @GenderID INT
SET @CountryID = (SELECT CountryID FROM tblCountry WHERE CountryName = @CountryName)
IF @CountryID IS NULL
    BEGIN
        PRINT '@CountryID do be empty, check spelling por favor'
        RAISERROR ('@CountryID cannot be null, process terminating', 11, 1)
        RETURN
    END
SET @ArtistTypeID = (SELECT ArtistTypeID FROM tblArtist_Type WHERE ArtistTypeName = @ArtistTypeName)
IF @ArtistTypeID IS NULL
    BEGIN
        PRINT '@ArtistTypeID came back empty, pls look into it'
        RAISERROR ('ArtistTypeID came back empty, process terminating', 11,1)
        RETURN
    END
SET @GenderID = (SELECT GenderID FROM tblGender WHERE GenderName = @GenderName)
IF @GenderID IS NULL
    BEGIN
        PRINT '@GenderID came back empty, check spelling my guy'
        RAISERROR('@GenderID better not be null, process terminado', 11,1)
        RETURN
    END
BEGIN TRAN T5
INSERT INTO tblArtist (ArtistName, CountryID, ArtistTypeID, GenderID)
VALUES(@ArtistName, @CountryID, @ArtistTypeID, @GenderID)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN T5
    END
ELSE
    COMMIT TRAN T5
----------------

CREATE TABLE tblOrder
(OrderID INT IDENTITY(1,1) PRIMARY KEY,
OrderDate DATE NOT NULL,
CustRoomID INT FOREIGN KEY REFERENCES tblCustomer_Room(CustRoomID) NOT NULL)

GO
CREATE OR ALTER PROCEDURE insert_order
@OrderDate DATE,
@F varchar(30),
@L varchar(30),
@B DATE,
@Num varchar(4)
AS
DECLARE @CustRoomID INT
SET @CustRoomID = (SELECT CustRoomID FROM tblCustomer_Room CR 
                    JOIN tblCustomer C ON CR.CustID = C.CustID
                    JOIN tblRoom R ON CR.RoomID = R.RoomID
                   WHERE CustFName = @F
                   AND CustLName = @L
                   AND CustBirth = @B
                   AND RoomNumber = @Num)
IF @CustRoomID IS NULL
    BEGIN
        PRINT '@CustRoomID is empty man, just like you.';
        THROW 56789, '@CustRoomID cannot be empty, process ending', 1;
    END
BEGIN TRAN T6
INSERT INTO tblOrder (OrderDate, CustRoomID)
VALUES(@OrderDate, @CustRoomID)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN T6
    END
ELSE
    COMMIT TRAN T6


-- Business Rule #1
-- People under age 21 in not allowed to order alcohol(product type).
GO
CREATE FUNCTION fn_minor_alcohol()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (
    SELECT *
    FROM tblCustomer C
        JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
        JOIN tblOrder O ON CR.CustRoomID = O.CustRoomID
        JOIN tblOrder_Product OP ON O.OrderID = OP.OrderID
        JOIN tblProduct P ON OP.ProductID = P.ProductID
        JOIN tblProduct_Type PT ON P.ProductTypeID = PT.ProductTypeID
    WHERE ProductTypeName = 'Alcohol'
    AND CustBirth > DATEADD(Year, -21, GETDATE())
)
SET @RET = 1
RETURN @RET
END
GO
ALTER TABLE tblOrder_Product WITH NOCHECK
ADD CONSTRAINT ck_alcohol_minor 
CHECK (dbo.fn_minor_alcohol() = 0)
select dbo.fn_minor_alcohol()

-- Business Rule #2
-- Customers who sing heavy metal cannot have ratings higher than 4.
GO
CREATE FUNCTION fn_metal_rating()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (
    SELECT *
    FROM tblRecording_Rating RR
        JOIN tblRecording R ON RR.RecordingID = R.RecordingID
        JOIN tblGenre G ON R.GenreID = G.GenreID
        JOIN tblRating RT ON RR.RatingID = RT.RatingID
    WHERE GenreName = 'Heavy Metal'
    AND RatingNumeric > 4
)
SET @RET = 1
RETURN @RET
END
GO

ALTER TABLE tblRecording_Rating WITH NOCHECK
ADD CONSTRAINT ck_heavy_metal_rating
CHECK (dbo.fn_metal_rating() = 0)

-- Business Rule #3 Customers are not allowed to sing when time is up(Remain Time is negative).
GO
CREATE OR ALTER FUNCTION fn_no_excessive_singing()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (
    SELECT *
    FROM tblCustomer_Room
    WHERE RemainTime <= 0
)
SET @RET = 1
RETURN @RET
END
GO

ALTER TABLE tblRecording_Rating WITH NOCHECK
ADD CONSTRAINT ck_use_time
CHECK (dbo.fn_no_excessive_singing() = 0)

-- Computed Column #1
-- Convert DOB into the actual age as INT
GO
CREATE FUNCTION fn_calc_age(@PK INT)
RETURNS INT
AS
BEGIN

DECLARE @RET INT = (
    SELECT DATEDIFF(YEAR, CustBirth, GETDATE())
    FROM tblCustomer
    WHERE CustID = @PK
)
RETURN @RET
END
GO

ALTER TABLE tblCustomer
ADD calc_age AS (dbo.fn_calc_age(CustID))
-- Computed Column #2
-- Calculate the number of recordings each song has.
GO
CREATE FUNCTION fn_num_recordings(@PK INT)
RETURNS INT
AS
BEGIN

DECLARE @RET INT = (
    SELECT Count(P.RecordingID)
    FROM tblSong S
        JOIN tblRecording R ON S.SongID = R.SongID
        JOIN tblPerformance P ON R.RecordingID = P.RecordingID
    WHERE S.SongID = @PK
)
RETURN @RET
END
GO

ALTER TABLE tblSong
ADD Calc_num_recordings AS (dbo.fn_num_recordings(SongID))




-- Synthetic Transaction on Room
GO
CREATE OR ALTER PROCEDURE wrapper_insert_room
@Run INT
AS
DECLARE @RegionName2 varchar(50), @LocationType2 varchar(30), @RoomNumber2 varchar(4)
DECLARE @RegionRowCount INT = (SELECT COUNT(*) FROM tblRegion)
DECLARE @LocationRowCount INT = (SELECT COUNT(*) FROM tblLocation)
DECLARE @RegionPK INT, @LocationPK INT
WHILE @Run > 0

BEGIN
SET @RegionPK = (SELECT RAND() * @RegionRowCount + 1)
SET @LocationPK = (SELECT RAND() * @LocationRowCount + 1)
SET @RoomNumber2 = left(stuff(convert(varchar(36),newid()),9,1,''),4)
SET @RegionName2 = (SELECT RegionName FROM tblRegion WHERE RegionID = @RegionPK)
SET @LocationType2 = (SELECT LocationType FROM tblLocation WHERE LocationID = @LocationPK)
EXEC insert_room
@RegionName = @RegionName2,
@LocationType = @LocationType2,
@RoomNumber = @RoomNumber2

SET @Run = @Run - 1
END

EXEC wrapper_insert_room @Run = 1000

SELECT * FROM tblRoom


-- Synthetic Transaction on Customer_Room
GO
CREATE OR ALTER PROCEDURE wrapper_insert_custroom
@Run INT
AS
DECLARE @F2 varchar(30), @L2 varchar(30), @B2 DATE, @R2 varchar(4), @Start2 DATETIME, @End2 DATETIME
DECLARE @CustRowCount INT = (SELECT COUNT(*) FROM tblCustomer)
DECLARE @RoomRowCount INT = (SELECT COUNT(*) FROM tblRoom)
DECLARE @CustPK INT, @RoomPK INT
WHILE @Run > 0
BEGIN
SET @CustPK = (SELECT RAND() * @CustRowCount + 440004)
SET @F2 = (SELECT CustFName FROM tblCustomer WHERE CustID = @CustPK)
IF @F2 IS NULL
    BEGIN
        SET @F2 = 'Lashawna'
    END
SET @L2 = (SELECT CustLName FROM tblCustomer WHERE CustID = @CustPK)
IF @L2 IS NULL
    BEGIN
        SET @L2 = 'Hottle'
    END
SET @B2 = (SELECT CustBirth FROM tblCustomer WHERE CustID = @CustPK)
IF @B2 IS NULL
    BEGIN
        SET @B2 = '1967-11-06'
    END
SET @RoomPK = (SELECT RAND() * @RoomRowCount + 1)
SET @R2 = (SELECT RoomNumber FROM tblRoom WHERE RoomID = @RoomPK)
IF @R2 IS NULL
    BEGIN
        SET @R2 = 'B17E'
    END
SET @End2 = DateAdd(DAY, -rand() *900, GETDATE())
SET @Start2 = DateAdd(MINUTE, -rand() * 60, @End2)
EXEC insert_custroom
@CFName = @F2,
@CLName = @L2,
@CBirth = @B2,
@RoomNum = @R2,
@StartTime = @Start2,
@EndTime = @End2
SET @Run = @Run - 1
END

EXEC wrapper_insert_custroom @Run = 5000
GO

-- Synthetic Transaction for Artist

CREATE OR ALTER PROCEDURE wrapper_insert_artist2
@Run INT
AS
DECLARE @ArtistName2 varchar(100), @CountryName2 varchar(50), @ArtistTypeName2 varchar(50), @GenderName2 varchar(10)
DECLARE @ArtistRowCount INT = (SELECT COUNT(*) FROM #Temp_Artist)
DECLARE @ArtistPK INT, @ArtistTypePK INT, @GenderPK INT, @CountryPK INT
WHILE @Run > 0
BEGIN

SET @ArtistPK = (SELECT RAND() * @ArtistRowCount + 1)
SET @ArtistTypePK = (SELECT FLOOR(RAND()*(2))+1)
SET @GenderPK = (SELECT FLOOR(RAND() * 3) + 1)
SET @CountryPK = (SELECT FLOOR(RAND() * 193) +9)
SET @ArtistName2 = (SELECT AName FROM #Temp_Artist WHERE PKID = @ArtistPK)
IF @ArtistName2 IS NULL
    BEGIN
        SET @ArtistName2 = 'Coldplay'
    END
SET @CountryName2 = (SELECT CName FROM #Temp_Artist WHERE PKID = @CountryPK)
IF @CountryName2 IS NULL
    BEGIN
        SET @CountryName2 = 'United Kingdom'
    END
SET @ArtistTypeName2 = (SELECT ArtistTypeName FROM tblArtist_Type WHERE ArtistTypeID = @ArtistTypePK)
SET @GenderName2 = (SELECT GenderName FROM tblGender WHERE GenderID = @GenderPK)
EXEC insert_artist
@ArtistName = @ArtistName2,
@CountryName = @CountryName2,
@ArtistTypeName = @ArtistTypeName2,
@GenderName = @GenderName2

SET @Run = @Run - 1
END

EXEC wrapper_insert_artist2 @Run = 1000


-- Cart Processing

-- Step 1. Creating Computed Columns for tblOrder_Product and tblOrder
GO
CREATE FUNCTION fn_inventory_price (@PK INT)
RETURNS Numeric(8,2)
AS
BEGIN

DECLARE @RET Numeric(8,2) = (
    SELECT (P.Price * OP.Quantity)
    FROM tblOrder_Product OP
        JOIN tblProduct P ON OP.ProductID = P.ProductID
    WHERE OP.OrderProductID = @PK
)
RETURN @RET
END

GO

ALTER TABLE tblOrder_Product
ADD InventoryPrice AS (dbo.fn_inventory_price(OrderProductID))

SELECT * FROM tblOrder_Product

GO

CREATE OR ALTER FUNCTION fn_total_price (@PK INT)
RETURNS NUMERIC(8,2)
AS
BEGIN

DECLARE @RET NUMERIC(8,2) = (
    SELECT SUM(InventoryPrice)
    FROM tblOrder_Product OP
        JOIN tblOrder O ON OP.OrderID = O.OrderID
    WHERE O.OrderID = @PK
)
RETURN @RET
END
GO
ALTER TABLE tblORDER
ADD TotalAmount AS (dbo.fn_total_price(OrderID))
GO

INSERT INTO tblProduct (ProductTypeID, ProductName, Price)
VALUES (1, 'Qingdao Beer', 2),
(2, 'Pringles', 4),
(3, 'Sprite', 3),
(3, 'Coke', 3),
(3, 'Doctor Pepper', 2),
(1, 'Fat Tire', 3),
(2, 'Oreos', 3),
(2, 'Beef Jerky', 8),
(3, 'Slurpy', 7),
(1, 'Soju', 3),
(1, 'Vodka', 30),
(2, 'Cheetos', 7),
(2, 'Sour Patch Kids', 5),
(2, 'String Cheese', 5),
(1, 'Budweiser', 3),
(3, 'Fanta', 3),
(2, 'Candy Corn', 8),
(1, 'RIO Cocktail', 5),
(3, 'Mountain Dew', 2)

SELECT * FROM tblProduct
SELECT * FROM tblCustomer_Room

SELECT * FROM tblProduct_Type


-- Step 2. Create Cart Table

CREATE TABLE tblCart
(CartID INT IDENTITY(1,1) PRIMARY KEY,
CustRoomID INT FOREIGN KEY REFERENCES tblCustomer_Room(CustRoomID) NOT NULL,
ProductID INT FOREIGN KEY REFERENCES tblProduct(ProductID) NOT NULL,
CartDate DATE,
Qty INT
)
GO
-- Step 3. Populating Cart

CREATE PROCEDURE pop_cart
@CustRoomID INT,
@ProdName varchar(30),
@CartDate DATE,
@Qty INT
AS
DECLARE @ProductID INT
SET @ProductID = (SELECT ProductID FROM tblProduct WHERE ProductName = @ProdName)
IF @ProductID IS NULL
    BEGIN
        PRINT '@ProductID is NULL, please check spelling'
        RAISERROR('@ProductID cannot be empty, process is terminating', 11,1)
        RETURN
    END
INSERT INTO tblCart (CustRoomID, ProductID, CartDate, Qty)
VALUES (@CustRoomID, @ProductID, @CartDate, @Qty)
GO
-- Step 4. Process Cart
CREATE OR ALTER PROCEDURE Process_Cart
@CustRoomID INT
AS
BEGIN
DECLARE @OrderID INT

BEGIN TRANSACTION H1

-- For this chunk, insert into tblOrder and tblOrder_product
BEGIN TRANSACTION H2
INSERT INTO tblOrder(OrderDate, CustRoomID)
VALUES (GETDATE(), @CustRoomID)

SET @OrderID = (SELECT SCOPE_IDENTITY())

IF @OrderID IS NULL
    BEGIN
        PRINT '@OrderID iS NULL, check spelling';
        THROW 55512, '@OrderID cannot be null, process is terminating', 1;
    END
ELSE
INSERT INTO tblOrder_Product (OrderID, ProductID, Quantity)
SELECT @OrderID, ProductID, SUM(Qty)
FROM tblCart
WHERE CustRoomID = @CustRoomID
GROUP BY ProductID
-- Done with the H2 transaction, now error-handling before going into H3
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN H2
    END
ELSE
    BEGIN
        COMMIT TRAN H2
    END

-- For this chunk, we are deleting rows from tblCART that have been inserted.
-- Remember to count and make sure that number of rows processed is equal to number of rows to be deleted.

BEGIN TRANSACTION H3

PRINT @@ROWCOUNT

DELETE FROM tblCart
WHERE CustRoomID = @CustRoomID

IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN H3
    END
ELSE
    BEGIN
        COMMIT TRAN H3
    END

IF @@ERROR <>0
    BEGIN
        ROLLBACK TRAN H3
    END
ELSE
    BEGIN
        IF @@TRANCOUNT <> 1
            BEGIN
                ROLLBACK TRAN H1
            END
        ELSE
            COMMIT TRAN H1
    END
END
GO

-- Step 5. Test if it works
DECLARE @GetDate DATETIME = (SELECT GETDATE())
DECLARE @CustRoomID_Out INT = (SELECT TOP 1 CustRoomID FROM tblCustomer_Room)
PRINT @CustRoomID_Out
DECLARE @Prod1 VARCHAR(30) = (SELECT TOP 1 ProductName FROM tblProduct), @Prod2 VARCHAR(30) = (SELECT ProductName FROM tblProduct WHERE ProductID = 2),
@Prod3 VARCHAR(30) = (SELECT ProductName FROM tblProduct WHERE ProductID = 5)

EXEC pop_cart
@CustRoomID = @CustRoomID_Out,
@ProdName = @Prod1,
@CartDate = @GetDate,
@Qty = 3

EXEC pop_cart
@CustRoomID = @CustRoomID_Out,
@ProdName = @Prod2,
@CartDate = @GetDate,
@Qty = 7

EXEC pop_cart
@CustRoomID = @CustRoomID_Out,
@ProdName = @Prod3,
@CartDate = @GetDate,
@Qty = 3

EXEC pop_cart
@CustRoomID = @CustRoomID_Out,
@ProdName = @Prod3,
@CartDate = @GetDate,
@Qty = 3

DECLARE @CustRoomID_Out2 INT = (SELECT TOP 1 CustRoomID FROM tblCustomer_Room)
EXEC Process_Cart @CustRoomID = @CustRoomID_Out2

SELECT * FROM tblCart
SELECT * FROM tblOrder
SELECT * FROM tblOrder_Product
SELECT * FROM tblProduct


GO
-- Complex Query

-- For the user that has the 3rd longest use time in our karoake, what is their average rating?

WITH CTE_Cust_Use (CustID, CustFName, CustLName, UseTime, Ranking) AS (
SELECT C.CustID, CustFName, CustLName, SUM(UseTime),
RANK() OVER (ORDER BY SUM(UseTime) DESC)
FROM tblCustomer C
    JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
    JOIN tblRecording_Rating RR ON CR.CustRoomID = RR.CustRoomID
GROUP BY C.CustID, CustFName, CustLName),
CTE_Cust_Rating (CustID, CustFName, CustLName, AvgRating)
AS
(SELECT C.CustID, CustFName, CustLName, Avg(RatingNumeric)
FROM tblCustomer C
    JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
    JOIN tblRecording_Rating RR ON CR.CustRoomID = RR.CustRoomID
    JOIN tblRating R ON RR.RatingID = R.RatingID
GROUP BY C.CustID, CustFName, CustLName
    )
SELECT A.CustFName, A.CustLName, A.UseTime, A.Ranking, B.AvgRating FROM CTE_Cust_Use A
    JOIN CTE_Cust_Rating B ON A.CustID = B.CustID
WHERE Ranking = 3


-- What are US Customers' 2nd ranked most ordered genre of recording?

WITH CTE_US_Genre (GenreName, DRanking)
AS(
SELECT GenreName,
DENSE_RANK() OVER (ORDER BY COUNT(R.GenreID) DESC)
FROM tblCustomer C
    JOIN tblCountry CY ON C.CountryID = CY.CountryID
    JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
    JOIN tblRecording_Rating RR ON CR.CustRoomID = RR.CustRoomID
    JOIN tblRecording R ON RR.RecordingID = R.RecordingID
    JOIN tblGenre G ON R.GenreID = G.GenreID
WHERE CountryName = 'United States'
GROUP BY GenreName)
SELECT * FROM CTE_US_Genre WHERE DRanking = 2




-- Create look up tables and transactional tables
CREATE TABLE tblPayment_Type
(PaymentTypeID INT IDENTITY(1,1) PRIMARY KEY,
PaymentTypeName VARCHAR(50) NOT NULL)

CREATE TABLE tblPayment
(PaymentID INT IDENTITY(1,1) PRIMARY KEY,
PaymentTypeID INT FOREIGN KEY REFERENCES tblPayment_Type(PaymentTypeID) NOT NULL,
OrderID INT FOREIGN KEY REFERENCES tblOrder(OrderID) NOT NULL)

CREATE TABLE tblArtist_Type
(ArtistTypeID INT IDENTITY(1,1) PRIMARY KEY,
ArtistTypeName VARCHAR(50) NOT NULL)

CREATE TABLE tblProduct_Type
(ProductTypeID INT IDENTITY(1,1) PRIMARY KEY,
ProductTypeName VARCHAR(25) NOT NULL)

CREATE TABLE tblGenre
(GenreID INT IDENTITY(1,1) PRIMARY KEY,
GenreName VARCHAR(50) NOT NULL)

CREATE TABLE tblRecording
(RecordingID INT IDENTITY(1,1) PRIMARY KEY,
SongID INT FOREIGN KEY REFERENCES tblSong(SongID) NOT NULL,
GenreID INT FOREIGN KEY REFERENCES tblGenre(GenreID) NOT NULL,
DurationSeconds INT NOT NULL)
ALTER TABLE tblRecording
ADD RecordingName varchar(1000)

CREATE TABLE tblRecording_Rating
(RecRatID INT IDENTITY(1,1) PRIMARY KEY,
CustRoomID INT FOREIGN KEY REFERENCES tblCustomer_Room(CustRoomID) NOT NULL,
RecordingID INT FOREIGN KEY REFERENCES tblRecording(RecordingID) NOT NULL,
RatingID INT FOREIGN KEY REFERENCES tblRating(RatingID) NOT NULL)

CREATE TABLE tblOrder_Product
(OrderProductID INT IDENTITY(1,1) PRIMARY KEY,
OrderID INT FOREIGN KEY REFERENCES tblOrder(OrderID) NOT NULL,
ProductID INT FOREIGN KEY REFERENCES tblProduct(ProductID) NOT NULL)

CREATE TABLE tblProduct
(ProductID INT IDENTITY(1,1) PRIMARY KEY,
ProductName varchar(50) NOT NULL,
Price Numeric(8,2) NOT NULL,
ProductTypeID INT FOREIGN KEY REFERENCES tblProduct_Type(ProductTypeID) NOT NULL)

CREATE TABLE tblPerformance
(PerformanceID INT IDENTITY(1,1) PRIMARY KEY,
ArtistID INT FOREIGN KEY REFERENCES tblArtist(ArtistID) NOT NULL,
RecordingID INT FOREIGN KEY REFERENCES tblRecording(RecordingID) NOT NULL)



-- Nested stored procedures and base proceduress
GO
CREATE PROCEDURE GetProductTypeID
@PTName varchar(50),
@PT_ID INT OUTPUT
AS
SET @PT_ID = (SELECT ProductTypeID FROM tblProduct_Type WHERE ProductTypeName = @PTName)

GO
CREATE or ALTER PROCEDURE insert_product
@PName varchar(50),
@Pricy Numeric(8,2),
@PTName2 varchar(50)
AS
DECLARE @PTID INT

EXEC GetProductTypeID
@PTName = @PTName2,
@PT_ID = @PTID OUTPUT

--error-handling
IF @PTID IS NULL
    BEGIN
        PRINT '@PTID is empty...check spelling';
        THROW 53332, '@PTID cannot be NULL; process is terminating', 1;
    END

BEGIN TRANSACTION T7
INSERT INTO tblProduct(ProductTypeID, ProductName, Price)
VALUES (@PTID, @PName, @Pricy)
IF @@ERROR <> 0
	BEGIN
		PRINT 'ROLLING Back the transaction'
			ROLLBACK TRANSACTION T7
	END
ELSE
	COMMIT TRANSACTION T7
Go


CREATE or ALTER PROCEDURE GetArtistID
@CounN varchar(50),
@ATName varchar(50),
@Gender varchar(50),
@AName varchar(50),
@A_ID INT OUTPUT
AS
SET @A_ID = (SELECT ArtistID 
			FROM tblArtist A
				JOIN tblArtist_Type ATN ON A.ArtistTypeID = ATN.ArtistTypeID
				JOIN tblCountry C ON A.CountryID = C.CountryID
				JOIN tblGender G ON A.GenderID = G.GenderID
			WHERE C.CountryName = @CounN
			AND ATN.ArtistTypeName = @ATName
			AND G.GenderName = @Gender
			AND A.ArtistName = @AName)
 
GO
CREATE or ALTER PROCEDURE insert_performance
@CounN2 varchar(50),
@ATName2 varchar(50),
@Gender2 varchar(50),
@AName2 varchar(50),
@GName2 varchar(50),
@SName2 varchar(50),
@SDate2 DATE,
@DuSec2 INT
AS
DECLARE @RID INT, @AID INT

EXEC GetRecordingID2
@GName = @GName2,
@SName = @SName2,
@SDate = @SDate2,
@DuSec = @DuSec2,
@REC_ID = @RID OUTPUT

IF @RID IS NULL
	BEGIN
		PRINT 'Hey... @RID; please check spelling';
		THROW 53336, '@RID cannot be NULL...process is terminating', 1;
	END

EXEC GetArtistID
@CounN = @CounN2,
@ATName = @ATName2,
@Gender = @Gender2,
@AName = @AName2,
@A_ID = @AID OUTPUT

IF @AID IS NULL
	BEGIN
		PRINT 'Hey... @AID; please check spelling';
		THROW 53337, '@AID cannot be NULL...process is terminating', 1;
	END

BEGIN TRANSACTION T8
INSERT INTO tblPerformance(ArtistID, RecordingID)
VALUES (@AID, @RID)
IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION T8
	END
ELSE
	COMMIT TRANSACTION T8
GO

CREATE PROCEDURE GetOrderID
@STime DATETIME,
@ETime DATETIME,
@ODate DATE,
@O_ID INT OUTPUT
AS
SET @O_ID = (SELECT OrderID 
			FROM tblOrder O
				JOIN tblCustomer_Room CR ON O.OrderID = CR.CustRoomID
			WHERE CR.StartTime = @STime
			AND CR.EndTime = @ETime
			AND O.OrderDate = @ODate)

GO
CREATE PROCEDURE GetProductID
@PName varchar(50),
@Ps Numeric(8,2),
@PTName varchar(50),
@P_ID INT OUTPUT
AS
SET @P_ID = (SELECT ProductID 
			FROM tblProduct P
				JOIN tblProduct_Type PT ON P.ProductID = PT.ProductTypeID
			WHERE PT.ProductTypeName = @PTName
			AND P.ProductName = @PName
			AND P.Price = @Ps)
		
GO
CREATE or ALTER PROCEDURE insert_order_product
@STime2 DATETIME,
@ETime2 DATETIME,
@ODate2 DATE,
@PName2 varchar(50),
@Ps2 Numeric(8,2),
@PTName2 varchar(50)
AS

DECLARE @OID INT, @PID INT

EXEC GetOrderID
@STime = @STime2,
@ETime = @ETime2,
@ODate = @ODate2,
@O_ID = @OID OUTPUT

IF @OID IS NULL
	BEGIN
		PRINT 'Hey...@OID; please check spelling';
		THROW 53338, '@OID cannot be NULL...process is terminating', 1;
	END

EXEC GetProductID
@PName = @PName2,
@Ps = @Ps2,
@PTName = @PTName2,
@P_ID = @PID OUTPUT

IF @PID IS NULL
	BEGIN
		PRINT 'Hey...@PID; please check spelling';
		THROW 53339, '@PID cannot be NULL...process is terminating', 1;
	END

BEGIN TRANSACTION T9
INSERT INTO tblOrder_Product(OrderID, ProductID)
VALUES (@OID, @PID)
IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION T9
	END
ELSE
	COMMIT TRANSACTION T9


GO
CREATE PROCEDURE GetPaymentTypeID
@PTName varchar(50),
@PAY_ID INT OUTPUT
AS
SET @PAY_ID = (SELECT PaymentTypeID FROM tblPayment_Type WHERE PaymentTypeName = @PTName)

GO
CREATE or ALTER PROCEDURE insert_payment
@STime2 DATETIME,
@ETime2 DATETIME,
@ODate2 DATE,
@PTName2 varchar(50)
AS
DECLARE @OID INT, @PAYID INT

EXEC GetOrderID
@STime = @STime2,
@ETime = @ETime2,
@ODate = @ODate2,
@O_ID = @OID OUTPUT

IF @OID IS NULL
	BEGIN
		PRINT 'Hey...@OID; please check spelling';
		THROW 53340, '@OID cannot be NULL...process is terminating', 1;
	END

EXEC GetPaymentTypeID
@PTName = @PTName2,
@PAY_ID = @PAYID OUTPUT

IF @PAYID IS NULL
	BEGIN
		PRINT 'Hey...@PAYID; please check spelling';
		THROW 53341, '@PAYID cannot be NULL...process is terminating', 1;
	END

BEGIN TRANSACTION T10
INSERT INTO tblPayment(PaymentTypeID, OrderID)
VALUES (@PAYID, @OID) 
IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION T10
	END
ELSE
	COMMIT TRANSACTION T10



/*
Business rules (Check Constraint)
- 1) For rooms for less than 30 mins, will not be allowed to pay with card.
*/
GO
CREATE or ALTER FUNCTION fn_RmPayCard()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (SELECT *
	FROM tblCustomer_Room CR
		JOIN tblOrder O ON CR.CustRoomID = O.CustRoomID
		JOIN tblPayment P ON O.OrderID = P.OrderID
		JOIN tblPayment_Type PT ON P.PaymentTypeID = PT.PaymentTypeID
	WHERE DATEDIFF(MINUTE, CR.StartTime, CR.EndTime) < 30
	AND PaymentTypeName LIKE '%card%')
SET @RET = 1
RETURN @RET
END
GO

ALTER TABLE tblPayment WITH NOCHECK
ADD CONSTRAINT CK_NOCARD
CHECK (dbo.fn_RmPayCard() = 0)

-- 2) Customers who chose rock group songs and had ratings lower than 2 will not be allowed to pay with card.
GO
CREATE or ALTER FUNCTION fn_CusRockCard()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (SELECT *
	FROM tblPayment_Type PT
		JOIN tblPayment P ON PT.PaymentTypeID = P.PaymentTypeID
		JOIN tblOrder O ON P.OrderID = O.OrderID
		JOIN tblCustomer_Room CR ON O.CustRoomID = CR.CustRoomID
		JOIN tblRecording_Rating RR ON CR.CustRoomID = RR.CustRoomID
		JOIN tblRating RT ON RR.RatingID = RT.RatingID
		JOIN tblRecording R ON RR.RecordingID = R.RecordingID
		JOIN tblGenre G ON R.GenreID = G.GenreID
		JOIN tblPerformance PF ON R.RecordingID = PF.RecordingID
		JOIN tblArtist A ON PF.ArtistID = A.ArtistID
		JOIN tblArtist_Type AY ON A.ArtistTypeID = AY.ArtistTypeID
	WHERE PaymentTypeName LIKE '%card%'
	AND AY.ArtistTypeName = 'Group'
	AND GenreName LIKE '%rock%'
	AND RT.RatingNumeric < 2)
SET @RET = 1
RETURN @RET
END
GO

ALTER TABLE tblPayment WITH NOCHECK
ADD CONSTRAINT CK_NoCards
CHECK (dbo.fn_CusRockCard() = 0)


/*computed columns
Convert currency based on price
*/
-- CC 1-1
GO
CREATE FUNCTION fn_calc_KRW(@PK INT)
RETURNS INT
AS 
BEGIN

DECLARE @RET INT = (
	SELECT Price * 1303 	
	FROM tblProduct
	WHERE ProductID = @PK
)
RETURN @RET
END
GO

ALTER TABLE tblProduct ADD priceKRW AS (dbo.fn_calc_KRW(ProductID))


-- CC 1-2
GO
CREATE FUNCTION fn_calc_CNY(@PK INT)
RETURNS INT
AS 
BEGIN

DECLARE @RET INT = (
	SELECT Price * 6.76 	
	FROM tblProduct
	WHERE ProductID = @PK
)
RETURN @RET
END
GO

ALTER TABLE tblProduct ADD priceCNY AS (dbo.fn_calc_CNY(ProductID))

-- CC 1-3
GO
CREATE FUNCTION fn_calc_JPY(@PK INT)
RETURNS INT
AS 
BEGIN

DECLARE @RET INT = (
	SELECT Price * 135 	
	FROM tblProduct
	WHERE ProductID = @PK
)
RETURN @RET
END
GO

ALTER TABLE tblProduct ADD priceJPY AS (dbo.fn_calc_JPY(ProductID))


--Calculate duration based on start and end time
--CC 2
GO
CREATE FUNCTION fn_calc_dur(@PK INT)
RETURNS INT
AS 
BEGIN

DECLARE @RET INT = (
	SELECT DATEDIFF(MINUTE, StartTime, EndTime)
	FROM tblCustomer_Room
	WHERE CustRoomID = @PK
)
RETURN @RET
END
GO

ALTER TABLE tblCustomer_Room ADD UseTime AS (dbo.fn_calc_dur(CustRoomID))

GO

-- Insert Values Into tblRecording
-- Write the nested stored procedures first
CREATE OR ALTER PROCEDURE GetGenreID
@GName varchar(250),
@G_ID INT OUTPUT
AS
SET @G_ID = (SELECT GenreID FROM tblGenre WHERE GenreName = @GName)

GO
CREATE OR ALTER PROCEDURE GetSongID
@SName varchar(250),
@SDate DATE,
@S_ID INT OUTPUT
AS
SET @S_ID = (SELECT SongID FROM tblSong WHERE SongName = @SName AND DatePublished = @SDate)

-- base procedure
GO
CREATE OR ALTER PROCEDURE group2_insert_recording
@GName2 varchar(250),
@SName2 varchar(250),
@SDate2 DATE,
@DuSec INT
AS

DECLARE @GID INT, @SID INT

EXEC GetGenreID
@GName = @GName2,
@G_ID = @GID OUTPUT

IF @GID IS NULL
	BEGIN
		PRINT 'Hey...GenreID; please check spelling';
		THROW 50001, '@GID cannot be NULL...process is terminating', 1;
	END
	
EXEC GetSongID
@SName = @SName2,
@SDate = @SDate2,
@S_ID = @SID OUTPUT

IF @SID IS NULL
	BEGIN
		PRINT 'Hey...SongID; please check spelling';
		THROW 50002, '@SID cannot be NULL...process is terminating', 1;
	END

BEGIN TRANSACTION T11
INSERT INTO tblRecording(SongID, GenreID, DurationSeconds)
VALUES (@SID, @GID, @DuSec)
IF @@ERROR <> 0
	BEGIN
		PRINT 'ROLLING Back the transaction'
			ROLLBACK TRANSACTION T11
	END
ELSE
	COMMIT TRANSACTION T11

-- WRAPPER Synthetic Transaction 1
GO
CREATE or ALTER PROCEDURE wrapper_group2_INSERT_Recording
@RUN INT
AS
DECLARE
@GName3 varchar(250),
@SName3 varchar(250),
@SDate3 DATE,
@DuSec2 INT

DECLARE @SRowcount INT = (SELECT Count(*) FROM tblSong)
DECLARE @GRowCount INT = (SELECT COUNT(*) FROM tblGenre)

DECLARE @SPK INT, @GPK INT

WHILE @RUN > 0
BEGIN

SET @SPK = (SELECT RAND() * @SRowcount + 1) 
SET @GPK = (SELECT RAND() * @GRowCount + 1) 

SET @GName3 = (SELECT GenreName FROM tblGenre WHERE GenreID = @GPK)
	IF @GName3 IS NULL
		BEGIN
			SET @GName3 = 'ROCK'
		END
SET @SName3 = (SELECT SongName FROM tblSong WHERE SongID = @SPK)
	IF @SName3 IS NULL
		BEGIN
			SET @SName3 = 'Psycho'
		END
SET @SDate3 = (SELECT DatePublished FROM tblSong WHERE SongID = @SPK)
	IF @SDate3 IS NULL
		BEGIN
			SET @SDate3 = DateAdd(Month, -(rand() *40 +1), 2018-09-14)
		END
SET @DuSec2 = (SELECT RAND() * 301 + 1)

EXEC group2_insert_recording
@GName2 = @GName3,
@SName2 = @SName3,
@SDate2 = @SDate3,
@DuSec = @DuSec2

SET @RUN = @RUN - 1
END


EXEC wrapper_group2_INSERT_Recording
@RUN = 2000

GO
-- Insert Into tblRecording_Rating
CREATE or ALTER PROCEDURE GetRatingID2
@RName varchar(50),
@RNum Numeric(2,1),
@R_ID INT OUTPUT
AS
SET @R_ID = (SELECT RatingID FROM tblRating WHERE RatingName = @RName AND RatingNumeric = @RNum)

GO
CREATE or ALTER PROCEDURE GetRecordingID2
@RName varchar(1000),
@REC_ID INT OUTPUT
AS
SET @REC_ID = (SELECT RecordingID 
			FROM tblRecording R
			WHERE R.RecordingName = @RName)

GO
CREATE or ALTER PROCEDURE GetCustomerRoomID2
@STime DATETIME,
@ETime DATETIME,
@CFname varchar(50),
@CLname varchar(50),
@CDOB DATE,
@RoomNum varchar(4),
@CR_ID INT OUTPUT
AS
SET @CR_ID = (SELECT CustRoomID 
			FROM tblCustomer_Room CR
				JOIN tblCustomer C ON CR.CustID = C.CustID
				JOIN tblRoom R ON CR.RoomID = R.RoomID
			WHERE C.CustFName = @CFname
			AND C.CustLName = @CLname
			AND C.CustBirth = @CDOB
			AND R.RoomNumber = @RoomNum
			AND CR.StartTime = @STime
			AND CR.EndTime = @ETime)

GO
CREATE OR ALTER PROCEDURE insert_recording_rating2
@RecName2 varchar(1000),
@RName2 varchar(50),
@RNum2 Numeric(2,1),
@STime2 DATETIME,
@ETime2 DATETIME,
@CFname2 varchar(50),
@CLname2 varchar(50),
@CDOB2 DATE,
@RoomNum2 varchar(4)
AS

DECLARE @RECID INT, @CRID INT, @RID INT

EXEC GetRatingID2
@RName = @RName2,
@RNum = @RNum2,
@R_ID = @RID OUTPUT

IF @RID IS NULL
	BEGIN
		PRINT 'Hey... @RID; please check spelling';
		THROW 50005, '@RID cannot be NULL...process is terminating', 1;
	END

EXEC GetRecordingID2
@RName = @RecName2,
@REC_ID = @RECID OUTPUT

IF @RECID IS NULL
	BEGIN
		PRINT 'Hey... @RECID; please check spelling';
		THROW 50003, '@RECID cannot be NULL...process is terminating', 1;
	END

EXEC GetCustomerRoomID2
@STime = @STime2,
@ETime = @ETime2,
@CFname = @CFname2,
@CLname = @CLname2,
@CDOB = @CDOB2,
@RoomNum = @RoomNum2,
@CR_ID = @CRID OUTPUT

IF @CRID IS NULL
	BEGIN
		PRINT 'Hey... @CRID; please check spelling';
		THROW 50004, '@CRID cannot be NULL...process is terminating', 1;
	END

BEGIN TRANSACTION T12
INSERT INTO tblRecording_Rating(CustRoomID, RecordingID, RatingID)
VALUES (@CRID, @RECID, @RID)
IF @@ERROR <> 0
	BEGIN
		PRINT 'ROLLING BACK the transaction'
			ROLLBACK TRANSACTION T12
	END
ELSE
	COMMIT TRANSACTION T12

-- WRAPPER Synthetic Transaction 2
GO
CREATE OR ALTER PROCEDURE wrapper_insert_recording_rating2
@RUN INT
AS
DECLARE
@RecName3 varchar(1000),
@RName3 varchar(50),
@RNum3 Numeric(2,1),
@STime3 DATETIME,
@ETime3 DATETIME,
@CFname3 varchar(50),
@CLname3 varchar(50),
@CDOB3 DATE,
@RoomNum3 varchar(4)

DECLARE @RecRowcount INT = ((SELECT Count(*) FROM tblRecording))
DECLARE @CRRowCount INT = ((SELECT COUNT(*) FROM tblCustomer_Room))
DECLARE @RatRowCount INT = (SELECT COUNT(*) FROM tblRating)

DECLARE @RECPK INT, @CRPK INT, @RPK INT

WHILE @RUN > 0
BEGIN

SET @RECPK = (SELECT RAND() * @RecRowcount + 1281) 
SET @CRPK = (SELECT RAND() * @CRRowCount + 63767) 
SET @RPK = (SELECT RAND() * @RatRowCount + 1) 

SET @RecName3 = (SELECT RecordingName FROM tblRecording WHERE RecordingID = @RECPK)
SET @RName3 = (SELECT RatingName FROM tblRating WHERE RatingID = @RPK)
SET @RNum3 = (SELECT RatingNumeric FROM tblRating WHERE RatingID = @RPK)

SET @STime3 = (SELECT StartTime FROM tblCustomer_Room WHERE CustRoomID = @CRPK)
SET @ETime3 = (SELECT EndTime FROM tblCustomer_Room WHERE CustRoomID = @CRPK)
SET @CFname3 = (SELECT CustFName 
			FROM tblCustomer C
				JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
			WHERE CR.CustRoomID = @CRPK)
SET @CLname3 = (SELECT CustLName 
			FROM tblCustomer C
				JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
			WHERE CR.CustRoomID = @CRPK)
SET @CDOB3 = (SELECT CustBirth 
			FROM tblCustomer C
				JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
			WHERE CR.CustRoomID = @CRPK)
SET @RoomNum3 = (SELECT RoomNumber 
			FROM tblRoom R 
				JOIN tblCustomer_Room CR ON R.RoomID = CR.RoomID
			WHERE CR.CustRoomID = @CRPK)

EXEC insert_recording_rating2
@RecName2 = @RecName3,
@RName2 = @RName3,
@RNum2 = @RNum3,
@STime2 = @STime3,
@ETime2 = @ETime3,
@CFname2 = @CFname3,
@CLname2 = @CLname3,
@CDOB2 = @CDOB3,
@RoomNum2 = @RoomNum3

SET @RUN = @RUN - 1
END 

EXEC wrapper_insert_recording_rating2
@RUN = 2000



/* Complex Queries 
Find customers meeting the following conditions:
1) male customers who visit Karaoke shop near bar in North America 
2) customers who were born in 1990s and got 'Very Good' rating for their singings.
*/
-- 1)
SELECT DISTINCT CustFName, CustLName, CustBirth, RG.RegionName
FROM tblCustomer C
	JOIN tblCustomer_Room CR ON C.CustID = C.CustID
	JOIN tblRoom R ON CR.RoomID = R.RoomID
	JOIN tblLocation L ON R.LocationID = L.LocationID
	JOIN tblRegion RG ON L.RegionID = RG.RegionID
	JOIN tblGender GN ON C.GenderID = GN.GenderID
WHERE GN.GenderName = 'Male'
AND L.LocationType = 'Bar'
AND RG.RegionName IN ('North America')
ORDER BY CustBirth DESC

-- 2)
SELECT DISTINCT CustFName, CustLName, CustBirth
FROM tblCustomer C
	JOIN tblCustomer_Room CR ON C.CustID = C.CustID
	JOIN tblRecording_Rating RR ON CR.CustRoomID = RR.CustRoomID
	JOIN tblRating R ON RR.RatingID = R.RatingID
WHERE R.RatingName IN ('Very Good')
AND YEAR(CustBirth) BETWEEN 1990 AND 1999



CREATE VIEW vw_cus_bar_NA_90s
AS
-- wrapper
(SELECT A.CustID, A.CustFName, A.CustLName, A.CustBirth, A.RegionName, B.RatingName, DATEDIFF(MONTH, A.CustBirth, GETDATE())/12 AS Age
FROM

(SELECT DISTINCT C.CustID, CustFName, CustLName, CustBirth, RG.RegionName
FROM tblCustomer C
	JOIN tblCustomer_Room CR ON C.CustID = C.CustID
	JOIN tblRoom R ON CR.RoomID = R.RoomID
	JOIN tblLocation L ON R.LocationID = L.LocationID
	JOIN tblRegion RG ON L.RegionID = RG.RegionID
	JOIN tblGender GN ON C.GenderID = GN.GenderID
WHERE GN.GenderName = 'Male'
AND L.LocationType = 'Bar'
AND RG.RegionName IN ('North America')) A,

(SELECT DISTINCT C.CustID, CustFName, CustLName, CustBirth, R.RatingName
FROM tblCustomer C
	JOIN tblCustomer_Room CR ON C.CustID = C.CustID
	JOIN tblRecording_Rating RR ON CR.CustRoomID = RR.CustRoomID
	JOIN tblRating R ON RR.RatingID = R.RatingID
WHERE R.RatingName IN ('Very Good')
AND YEAR(CustBirth) BETWEEN 1990 AND 1999) B

WHERE A.CustID = B.CustID)


-- Group selected customers from vw_cus_bar_NA_90s by their age to determine its number of customers
SELECT Age, COUNT(CustID) AS NumCustomers
FROM vw_cus_bar_NA_90s
GROUP BY AGE 
ORDER BY COUNT(CustID) DESC

SELECT * FROM vw_cus_bar_NA_90s

-- Complex Query 2
-- Customers who are in 1st - 5th highest total use time in our karaoke shop and meets the following conditions:
-- 1) born in 1990s
-- 2) female customers
-- 3) stay less then 120 minutes at one visit
GO
CREATE VIEW second_query
AS
WITH CTE_UseTime_Cus (ID, CustomerFname, CustomerLname, CustomerDOB, TotalUseTime, D_Ranky)
AS (SELECT C.CustID, CustFName, CustLName, CustBirth, SUM(CR.UseTime),
DENSE_RANK() OVER (ORDER BY SUM(CR.UseTime) DESC) AS DRank_
	FROM tblCustomer C
		JOIN tblCustomer_Room CR ON C.CustID = CR.CustID
		JOIN tblGender G ON C.GenderID = G.GenderID
		JOIN tblCountry CT ON C.CountryID = CT.CountryID
	WHERE CR.UseTime < 120
	AND G.GenderName LIKE '%f%'
	AND YEAR(C.CustBirth) BETWEEN 1990 AND 1999
	GROUP BY C.CustID, CustFName, CustLName, CustBirth)

SELECT *
FROM CTE_UseTime_Cus
WHERE D_Ranky <= 5