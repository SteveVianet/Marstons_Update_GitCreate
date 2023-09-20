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

GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[26] 4[24] 2[31] 3) )"
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
               Bottom = 106
               Right = 206
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "DLData (dbo)"
            Begin Extent = 
               Top = 6
               Left = 244
               Bottom = 173
               Right = 412
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "Products (dbo)"
            Begin Extent = 
               Top = 6
               Left = 450
               Bottom = 121
               Right = 680
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ScheduleSites (dbo)"
            Begin Extent = 
               Top = 6
               Left = 718
               Bottom = 91
               Right = 886
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Sites (dbo)"
            Begin Extent = 
               Top = 6
               Left = 924
               Bottom = 173
               Right = 1144
            End
            DisplayFlags = 280
            TopColumn = 6
         End
         Begin Table = "ProductCategories (dbo)"
            Begin Extent = 
               Top = 6
               Left = 1182
               Bottom = 91
               Right = 1350
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ProductOwners (dbo)"
            Begin Extent = 
               Top = 96
               Left = 718
               Bottom = 181
               R', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Soft Drinks';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'ight = 886
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
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 4725
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Soft Drinks';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Soft Drinks';

