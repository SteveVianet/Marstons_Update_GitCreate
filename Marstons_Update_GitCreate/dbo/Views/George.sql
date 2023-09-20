CREATE VIEW dbo.George
AS
SELECT     dbo.Sites.SiteID, dbo.Sites.Name, DATEADD([hour], dbo.DLData.Shift - 1, dbo.MasterDates.[Date]) AS [date], dbo.ProductOwners.Name AS BrandOwner, 
                      dbo.ProductCategories.Description AS Category, dbo.DLData.Quantity, dbo.DLData.Shift, dbo.Sites.PostCode, dbo.Products.Description
FROM         dbo.MasterDates INNER JOIN
                      dbo.DLData ON dbo.MasterDates.ID = dbo.DLData.DownloadID INNER JOIN
                      dbo.Products ON dbo.Products.ID = dbo.DLData.Product INNER JOIN
                      dbo.Sites ON dbo.Sites.EDISID = dbo.MasterDates.EDISID INNER JOIN
                      dbo.ProductCategories ON dbo.ProductCategories.ID = dbo.Products.CategoryID INNER JOIN
                      dbo.ProductOwners ON dbo.ProductOwners.ID = dbo.Products.OwnerID
GROUP BY dbo.Sites.SiteID, dbo.Sites.Name, DATEADD([hour], dbo.DLData.Shift - 1, dbo.MasterDates.[Date]), dbo.ProductOwners.Name, 
                      dbo.ProductCategories.Description, dbo.DLData.Shift, dbo.DLData.Quantity, dbo.Sites.PostCode, dbo.Products.Description
HAVING      (DATEADD([hour], dbo.DLData.Shift - 1, dbo.MasterDates.[Date]) > CONVERT(DATETIME, '2009-02-19 00:00:00', 102)) AND (dbo.Sites.SiteID = '3586')
