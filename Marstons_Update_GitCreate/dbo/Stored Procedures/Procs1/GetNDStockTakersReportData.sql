CREATE PROCEDURE dbo.GetNDStockTakersReportData
(
	@DateFrom			AS datetime,
	@DateTo			AS datetime,
	@RegionalManagerID 		AS int
)
AS
SELECT DISTINCT 
                      TOP 100 PERCENT dbo.Users.UserName AS BDM_Name, dbo.Users.ID AS BDM_ID, dbo.MasterDates.[Date] AS Date_Taken, 
                      dbo.Sites.EDISID AS EDIS_ID, dbo.Sites.Name AS House_Name
FROM         dbo.Stock INNER JOIN
                      dbo.MasterDates ON dbo.Stock.MasterDateID = dbo.MasterDates.ID INNER JOIN
                      dbo.Sites ON dbo.MasterDates.EDISID = dbo.Sites.EDISID INNER JOIN
                      dbo.UserSites ON dbo.Sites.EDISID = dbo.UserSites.EDISID INNER JOIN
                      dbo.UserSites UserSites_1 ON dbo.Sites.EDISID = UserSites_1.EDISID INNER JOIN
                      dbo.Users ON dbo.UserSites.UserID = dbo.Users.ID INNER JOIN
                      dbo.UserTypes ON dbo.Users.UserType = dbo.UserTypes.ID
WHERE     (dbo.UserTypes.ID = 2) AND
	         (dbo.MasterDates.[Date] BETWEEN @DateFrom AND @DateTo) AND
	         (UserSites_1.UserID = @RegionalManagerID)
ORDER BY dbo.Users.UserName, dbo.MasterDates.[Date], dbo.Sites.Name

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetNDStockTakersReportData] TO PUBLIC
    AS [dbo];

