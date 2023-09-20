CREATE PROCEDURE dbo.AssignSystemStockToSite
(
	@StockSiteID VARCHAR(50),
	@ToSiteID VARCHAR(50)
)
AS

SET NOCOUNT ON

DECLARE @ToEDISID INTEGER
DECLARE @StockInstallDate DATETIME

SELECT @ToEDISID = EDISID
FROM Sites
WHERE SiteID = @ToSiteID

UPDATE SystemStock 
SET DateOut = GETDATE(), EDISID = @ToEDISID 
WHERE [ID] = (SELECT [ID] FROM SystemStock WHERE DateOut IS NULL AND WrittenOff =0 AND PreviousEDISID = (SELECT EDISID FROM Sites WHERE SiteID = @StockSiteID))

SELECT @StockInstallDate = OldInstallDate
FROM SystemStock
WHERE [ID] = (SELECT [ID] FROM SystemStock WHERE DateOut IS NULL AND WrittenOff = 0 AND PreviousEDISID = (SELECT EDISID FROM Sites WHERE SiteID = @StockSiteID))

UPDATE Sites SET InstallationDate = @StockInstallDate WHERE SiteID = @ToSiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AssignSystemStockToSite] TO PUBLIC
    AS [dbo];

