CREATE PROCEDURE [dbo].[AddCleaningProgressTracking]

	@CustomerName VARCHAR(250),
	@DatabaseID INT,
	@SiteID VARCHAR(250),
	@EDISID INT,
	@DateViewed DATE,
	@PumpID INT,
	@TypeViewed VARCHAR(50), -- C OR W
	@ProductID INT,
	@ProductName VARCHAR(250),
	@ProductIsCask BIT,
	@TimeSpent FLOAT,
	@TimeEnteredCleaningMode DATETIME,
	@AuditorName VARCHAR(100) = NULL
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PCName AS VARCHAR(250)
	SET @PCName = HOST_NAME()

	EXEC [SQL1\SQL1].Auditing.dbo.AddLiquidTypeChanges  @PCName, @CustomerName, @DatabaseID, @SiteID,
	@EDISID, @DateViewed, @PumpID, @TypeViewed, @ProductID, @ProductName, @ProductIsCask, @TimeSpent, 
	@TimeEnteredCleaningMode, @AuditorName
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCleaningProgressTracking] TO PUBLIC
    AS [dbo];

