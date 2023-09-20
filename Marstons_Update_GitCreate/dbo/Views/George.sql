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

GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1[50] 2[25] 3) )"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1 [56] 4 [18] 2))"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "MasterDates (dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 231
               Right = 206
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "DLData (dbo)"
            Begin Extent = 
               Top = 6
               Left = 244
               Bottom = 230
               Right = 412
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "Products (dbo)"
            Begin Extent = 
               Top = 112
               Left = 448
               Bottom = 227
               Right = 678
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Sites (dbo)"
            Begin Extent = 
               Top = 6
               Left = 924
               Bottom = 121
               Right = 1144
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductCategories (dbo)"
            Begin Extent = 
               Top = 177
               Left = 1175
               Bottom = 262
               Right = 1343
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductOwners (dbo)"
            Begin Extent = 
               Top = 28
               Left = 1172
               Bottom = 113
               Right = 1340
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      RowHeights = 220
      Begin ColumnWidt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'George';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'hs = 10
         Width = 284
         Width = 1440
         Width = 1440
         Width = 2850
         Width = 1440
         Width = 1440
         Width = 1440
         Width = 1440
         Width = 1440
         Width = 1440
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'George';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'George';

