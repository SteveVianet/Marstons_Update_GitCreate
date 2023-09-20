CREATE PROCEDURE [dbo].[zRS_GetHourlyData]
(
      @SiteID                             VARCHAR(60),
      @From                         DATETIME,
      @To                                 DATETIME
)
AS

SET DATEFIRST 1
SET NOCOUNT ON

DECLARE @EDISID INT

SELECT @EDISID = EDISID
FROM Sites
WHERE SiteID = @SiteID
SELECT     dbo.DLData.Shift, Products.Description as ProductDescription, SUM(dbo.DLData.Quantity) AS Pints, dbo.ProductCategories.Description as Category, 
                      dbo.Sites.SiteID, DATEPART(DW, MasterDates.Date) AS [DayOfWeek]
FROM         dbo.DLData INNER JOIN
                      dbo.MasterDates ON MasterDates.ID = DLData.DownloadID INNER JOIN
                      dbo.Products ON Products.ID = DLData.Product INNER JOIN
                      dbo.ProductCategories ON dbo.Products.CategoryID = dbo.ProductCategories.ID INNER JOIN
                      dbo.Sites ON dbo.MasterDates.EDISID = dbo.Sites.EDISID
WHERE     (MasterDates.Date BETWEEN @From AND @To) AND dbo.Sites.EDISID=@EDISID
GROUP BY dbo.DLData.Shift, Products.Description, DATEPART(DW, MasterDates.Date), dbo.ProductCategories.Description, dbo.Sites.SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_GetHourlyData] TO PUBLIC
    AS [dbo];

