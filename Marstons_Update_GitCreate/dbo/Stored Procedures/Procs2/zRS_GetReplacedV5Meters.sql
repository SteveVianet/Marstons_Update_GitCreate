CREATE PROCEDURE [dbo].[zRS_GetReplacedV5Meters]
AS

DECLARE @Today AS DATETIME = GETDATE()

SELECT DB_NAME() AS Customer,Sites.SiteID, Sites.Name, History.PhysicalAddress, History.CreateDate AS DateIn, History.FontNumber, History.Product,
            CASE WHEN Replacements.LatestCreateDate IS NULL THEN 'Active' ELSE 'Replaced' END AS MeterStatus,
            Replacements.LatestCreateDate AS ReplacedOn,
            DATEDIFF(Day, History.CreateDate, Replacements.LatestCreateDate) AS DaysUntilReplaced,
            CASE WHEN Replacements.LatestCreateDate IS NULL THEN DATEDIFF(Day, History.CreateDate, @Today) ELSE NULL END AS DaysLive
FROM (
      SELECT PhysicalAddress, CreateDate, EDISID, FontNumber, Product
      FROM (
            SELECT  PhysicalAddress,
                        CreateDate,
                        EDISID,
                        FontNumber,
                        Product,
                        MIN(CreateDate) OVER (PARTITION BY PhysicalAddress) FirstCreateDate
            FROM ProposedFontSetups
            JOIN ProposedFontSetupItems ON ProposedFontSetupItems.ProposedFontSetupID = ProposedFontSetups.ID
            WHERE ProposedFontSetupItems.Version = 5
            AND PhysicalAddress NOT IN (70444,70445,70446,70447,70448,70449,70450,70451,70452,70453,70454,70455)
            AND JobType = 1   -- new meter
      ) AS MeterHistory
   --   WHERE MeterHistory.CreateDate = MeterHistory.FirstCreateDate      

) AS History
LEFT JOIN (
            SELECT  EDISID,
                        FontNumber,
                        MAX(CreateDate) AS LatestCreateDate
            FROM ProposedFontSetups
            JOIN ProposedFontSetupItems ON ProposedFontSetupItems.ProposedFontSetupID = ProposedFontSetups.ID
       --     WHERE ProposedFontSetupItems.Version = 5
            AND PhysicalAddress NOT IN (70444,70445,70446,70447,70448,70449,70450,70451,70452,70453,70454,70455)
            AND JobType = 1   -- new meter
            GROUP BY EDISID, FontNumber
) AS Replacements ON Replacements.EDISID = History.EDISID AND Replacements.FontNumber = History.FontNumber AND Replacements.LatestCreateDate > History.CreateDate
JOIN Sites ON Sites.EDISID = History.EDISID
WHERE Sites.SiteID NOT IN ('RDtest', 'RDbr', 'Nathan1')
ORDER BY SiteID, Name, History.FontNumber, History.Product, History.PhysicalAddress, History.CreateDate, MeterStatus
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_GetReplacedV5Meters] TO PUBLIC
    AS [dbo];

