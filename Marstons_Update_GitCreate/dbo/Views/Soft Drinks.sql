CREATE VIEW dbo.[Soft Drinks]
AS
SELECT     dbo.Sites.SiteID, dbo.Sites.Name, DATEADD([hour], dbo.DLData.Shift - 1, dbo.MasterDates.[Date]) AS [date], dbo.ProductOwners.Name AS BrandOwner, 
                      dbo.ProductCategories.Description AS Category, dbo.DLData.Quantity, dbo.DLData.Shift, dbo.Sites.PostCode
FROM         dbo.MasterDates INNER JOIN
                      dbo.DLData ON dbo.MasterDates.ID = dbo.DLData.DownloadID INNER JOIN
                      dbo.Products ON dbo.Products.ID = dbo.DLData.Product INNER JOIN
                      dbo.ScheduleSites ON dbo.ScheduleSites.EDISID = dbo.MasterDates.EDISID INNER JOIN
                      dbo.Sites ON dbo.Sites.EDISID = dbo.MasterDates.EDISID INNER JOIN
                      dbo.ProductCategories ON dbo.ProductCategories.ID = dbo.Products.CategoryID INNER JOIN
                      dbo.ProductOwners ON dbo.ProductOwners.ID = dbo.Products.OwnerID
WHERE     (dbo.ScheduleSites.ScheduleID = 1312)
GROUP BY dbo.Sites.SiteID, dbo.Sites.Name, DATEADD([hour], dbo.DLData.Shift - 1, dbo.MasterDates.[Date]), dbo.ProductOwners.Name, 
                      dbo.ProductCategories.Description, dbo.DLData.Shift, dbo.DLData.Quantity, dbo.Sites.PostCode
