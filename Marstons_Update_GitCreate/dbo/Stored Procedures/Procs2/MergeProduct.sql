CREATE PROCEDURE [dbo].[MergeProduct]
(
	@OldProductID INT = NULL,
	@NewProductID INT = NULL
)
AS

UPDATE Calibrations
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE DLData
SET Product = @NewProductID
Where Product = @OldProductID

UPDATE Delivery
SET Product = @NewProductID
Where Product = @OldProductID

UPDATE Sales
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE ProductAlias
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE ProductPrices
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE PumpSetup
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE DispenseActions
SET Product = @NewProductID
Where Product = @OldProductID

UPDATE SiteKeyProducts
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE SiteProductTies
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE Stock
SET ProductID = @NewProductID
Where ProductID = @OldProductID

UPDATE ServiceIssuesYield
SET PrimaryProductID = @NewProductID
Where PrimaryProductID = @OldProductID

UPDATE ServiceIssuesYield
SET ProductID = @NewProductID
Where ProductID = @OldProductID

DELETE FROM Products
where ID = @OldProductID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[MergeProduct] TO PUBLIC
    AS [dbo];

