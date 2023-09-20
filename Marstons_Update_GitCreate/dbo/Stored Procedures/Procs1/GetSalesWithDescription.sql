-- =============================================
-- Author:		CJ Thomas
-- Create date: 11/08/2016
-- Description:	Gets Sales Data
-- =============================================
CREATE PROCEDURE [dbo].[GetSalesWithDescription] 
	(@EDISID INT,
	@From DateTime,
	@To Datetime,
	@IncludeCasks BIT,
	@IncludeKegs BIT,
	@IncludeMetric BIT)
AS
BEGIN
SET NOCOUNT ON;

DECLARE @GroupingInterval INT
SET @GroupingInterval = 0;	
	
DECLARE @Temp TABLE (
	EDISID INT,
	CurrentDate DateTime,
	TradingDate DateTime,
	ProductID INT,
	Quantity FLOAT,
	SaleIdent VARCHAR(100)
)

INSERT INTO @Temp
EXEC GetSiteRawSales @EDISID,
		@From,
		@To,
		@GroupingInterval,
		@IncludeCasks,
		@IncludeKegs,
		@IncludeMetric

SELECT t.EDISID, t.CurrentDate, t.TradingDate, p.[Description], t.Quantity, t.SaleIdent
FROM @Temp t INNER JOIN Products p
ON t.ProductID = p.ID
ORDER BY TradingDate DESC
   
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSalesWithDescription] TO PUBLIC
    AS [dbo];

