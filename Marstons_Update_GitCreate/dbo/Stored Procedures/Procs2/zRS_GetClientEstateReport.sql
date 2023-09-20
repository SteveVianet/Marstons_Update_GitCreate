CREATE PROCEDURE [dbo].[zRS_GetClientEstateReport]
(
@InstalledActive        BIT = 0,
@InstalledClosed        BIT = 0,
@InstalledFOT           BIT = 0,
@InstalledLegals        BIT = 0,
@InstalledWrittenOff    BIT = 0,
@InstalledNotReportedOn BIT = 0,
@NotInstalledOrMissing  BIT = 0,
@NotInstalledNonVianet  BIT = 0,
@NotInstalledToBeRefit  BIT = 0,
@NotInstalledUplifted   BIT = 0,
@TelcomsActive          BIT=  0,
@Unknown                BIT = 0
)
AS
SELECT     DB_NAME() AS Customer, dbo.Sites.SiteID, dbo.Sites.Name, dbo.Sites.PostCode, dbo.Sites.Address3,dbo.Sites.Address4,EDISTelNo,Sites.SerialNo,
                      CASE WHEN dbo.Sites.SiteClosed = 1 THEN 'CLOSED' ELSE 'OPEN' END AS MarkedOpen,
                      CASE WHEN dbo.Sites.Hidden = 1 THEN 'Hidden' ELSE 'Not hidden' END AS Hidden,
                      CASE WHEN dbo.Sites.Quality = 1 THEN 'iDraught' ELSE 'BMS' END AS Product,
                  --    ISNULL(CellarDetails.CellarCount, 1) AS CellarCount,
                      CASE International.Value  WHEN 'en-US' THEN 'US' ELSE 'Europe' END AS Country,
                      CASE dbo.Sites.Status WHEN 1 THEN 'Installed - Active' WHEN 2 THEN 'Installed - Closed' WHEN 10 THEN 'Installed - FOT' WHEN 3 THEN 'Installed - Legals'
                       WHEN 4 THEN 'Installed - Not Reported On' WHEN 5 THEN 'Installed - Written Off' WHEN 7 THEN 'Not Installed - Missing/Not Uplifted By Brulines' WHEN
                       9 THEN 'Not Installed - Non Brulines'
WHEN 8 THEN 'Not Installed System To Be Refit'
WHEN 11 THEN 'Telecoms Active'
WHEN 6 THEN 'Not Installed - Uplifted' WHEN 0 THEN 'Unknown'
                       END AS Sitestatus, 
                       CAST(StatusChange.ChangeDate AS DATE) AS SitestatusChanged,
                       DATEDIFF(DAY, CAST(StatusChange.ChangeDate AS DATE), GETDATE()) AS SitestatusChangedDays,
                       dbo.Sites.InstallationDate AS PanelBirthday, dbo.Owners.Name AS Owner, SiteSyrupMeters.MetricCount,
                      SiteMetersinstalled.Metersinstalled, dbo.Sites.Address1, dbo.CommunicationProviders.ProviderName, dbo.Contracts.Description AS SiteContract,
                      dbo.SystemTypes.Description, dbo.Sites.LastInstallationDate AS LastInstall, dbo.Sites.BirthDate AS SiteBirthday,
                      dbo.ModemTypes.Description AS MobileType, dbo.Sites.EDISTelNo
FROM         dbo.Contracts INNER JOIN
                      dbo.SiteContracts ON dbo.Contracts.ID = dbo.SiteContracts.ContractID INNER JOIN
                      dbo.Sites INNER JOIN
                      dbo.Owners ON dbo.Sites.OwnerID = dbo.Owners.ID INNER JOIN
                      dbo.SystemTypes ON dbo.Sites.SystemTypeID = dbo.SystemTypes.ID INNER JOIN
                      dbo.CommunicationProviders ON dbo.Sites.CommunicationProviderID = dbo.CommunicationProviders.ID ON
                      dbo.SiteContracts.EDISID = dbo.Sites.EDISID LEFT JOIN
                        (SELECT EDISID, MAX(ValidFrom) AS [ChangeDate]
                        FROM SiteStatusHistory 
                        GROUP BY EDISID) AS StatusChange ON StatusChange.EDISID = Sites.EDISID
                      INNER JOIN
                      dbo.ModemTypes ON dbo.Sites.ModemTypeID = dbo.ModemTypes.ID LEFT OUTER JOIN
                          (SELECT     dbo.SiteProperties.EDISID, dbo.Properties.Name, dbo.SiteProperties.Value
                            FROM          dbo.SiteProperties INNER JOIN
                                                   dbo.Properties ON dbo.Properties.ID = dbo.SiteProperties.PropertyID
                            WHERE      (dbo.Properties.Name = 'International')) AS International ON dbo.Sites.EDISID = International.EDISID LEFT OUTER JOIN
                          (SELECT     dbo.PumpSetup.EDISID, COUNT(*) AS MetricCount
                            FROM          dbo.PumpSetup INNER JOIN
                                                   dbo.Products ON dbo.Products.ID = dbo.PumpSetup.ProductID
                            WHERE      (dbo.PumpSetup.ValidTo IS NULL) AND (dbo.Products.IsMetric = 1)
                            GROUP BY dbo.PumpSetup.EDISID) AS SiteSyrupMeters ON SiteSyrupMeters.EDISID = dbo.Sites.EDISID LEFT OUTER JOIN
                          (SELECT     PumpSetup_1.EDISID, COUNT(*) AS Metersinstalled
                            FROM          dbo.PumpSetup AS PumpSetup_1 INNER JOIN
                                                   dbo.Products AS Products_1 ON Products_1.ID = PumpSetup_1.ProductID
                            WHERE      (PumpSetup_1.ValidTo IS NULL) AND (Products_1.IsMetric = 0)
                            GROUP BY PumpSetup_1.EDISID) AS SiteMetersinstalled ON SiteMetersinstalled.EDISID = dbo.Sites.EDISID
                            --LEFT JOIN (
                            --                                SELECT
                            --                                      SiteGroups.ID AS GroupID,
                            --                                      Primaries.EDISID AS PrimaryEDISID,
                            --                                      COUNT(SiteGroupSites.EDISID) AS CellarCount
                            --                                FROM
                            --                                      SiteGroups
                            --                                JOIN
                            --                                      SiteGroupSites
                            --                                      ON SiteGroupSites.SiteGroupID = SiteGroups.ID
                            --                                LEFT JOIN (
                            --                                      SELECT
                            --                                            EDISID,
                            --                                            MIN(SiteGroupID) AS SiteGroupID
                            --                                      FROM
                            --                                            SiteGroupSites WHERE IsPrimary = 1
                            --                                      GROUP BY EDISID) AS Primaries
                            --                                      ON Primaries.SiteGroupID = SiteGroups.ID
                            --                                WHERE
                            --                                      SiteGroups.TypeID = 1
                            --                                GROUP BY
                            --                                      SiteGroups.ID,
                            --                                      Primaries.EDISID) AS CellarDetails ON CellarDetails.PrimaryEDISID = Sites.EDISID
							WHERE
                            (Sites.Status = 1) AND (@InstalledActive = 1)
                            OR (Sites.Status = 2) AND (@InstalledClosed=1)
                            OR (Sites.Status = 3) AND (@InstalledLegals        =1)
                            OR (Sites.Status = 4) AND (@InstalledNotReportedOn =1)
                            OR (Sites.Status = 5) AND (@InstalledWrittenOff    =1)
                            OR (Sites.Status = 6) AND (@NotInstalledUplifted   =1)
                            OR (Sites.Status = 7) AND (@NotInstalledOrMissing  =1)
                            OR (Sites.Status = 8) AND (@NotInstalledToBeRefit  =1)
                            OR (Sites.Status = 9) AND (@NotInstalledNonVianet  =1)
                            OR (Sites.Status = 10) AND (@InstalledFOT=1)
                            OR (Sites.Status =11) AND (@TelcomsActive=1)
							OR (Sites.Status = 0) AND (@Unknown   =1)
                            ORDER BY SiteID


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_GetClientEstateReport] TO PUBLIC
    AS [dbo];

