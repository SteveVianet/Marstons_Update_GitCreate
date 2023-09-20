CREATE PROCEDURE [dbo].[zRS_CustomersStockHoldings]
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
 
    -- Insert statements for procedure here
SELECT 
       DB_NAME() AS Customer
 
      ,[DateIn]
      ,[DateOut]
      ,[OldInstallDate]
      ,SystemStock.EDISID AS 'CurrentEDISID'
      ,Sites.SiteID + ': ' + Sites.Name  + ', ' + Sites.Address1 +', ' + Sites.Address3 AS 'CurrentorlastSite'
         ,Sites.SiteID AS 'CurrentSiteID'
         ,WOS.SiteID AS 'OLDSiteID' 
  , WOS.SiteID + ': ' + WOS.Name  + ', ' + WOS.Address1 +', ' + WOS.Address3 AS 'OldSite'
     ,SystemTypes.Description
      ,[CallID]
      ,[PreviousEDISID] AS 'PreviousEDISID'
      ,[PreviousName]
      ,[PreviousPostcode]
      ,[PreviousFMCount]
      ,[WrittenOff]
      ,[SystemStock].[Comment]
  FROM [SystemStock]
FULL OUTER JOIN Sites ON Sites.EDISID = SystemStock.EDISID
JOIN Sites AS WOS ON WOS.EDISID =PreviousEDISID
JOIN SystemTypes ON SystemTypes.ID = SystemStock.SystemTypeID
 
END
 

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_CustomersStockHoldings] TO PUBLIC
    AS [dbo];

