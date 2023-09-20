CREATE PROCEDURE [dbo].[GetImportedQuantity]
(
	@FileID			INT
)

AS

DECLARE @FileStartID INT
DECLARE @FileEndID INT

SELECT @FileStartID = StartID, @FileEndID = EndID FROM ImportedFiles WHERE ID = @FileID

SELECT SUM(Quantity) AS Quantity FROM Delivery 
WHERE ID BETWEEN @FileStartID AND @FileEndID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetImportedQuantity] TO PUBLIC
    AS [dbo];

