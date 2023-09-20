CREATE PROCEDURE [dbo].[zRS_CellarTemperature]
(   
      @From DATETIME    = NULL,
      @To   DATETIME    = NULL
)
AS
SET NOCOUNT ON

SELECT  Sites.SiteID
      ,Sites.Name + '-' + Sites.Address3 As FullSiteName
   ,Sites.PostCode
   ,AVG (Value) AS 'Average Cellar'
      ,CAST ((TradingDate) AS DATE) AS 'Date'
     ,ET.Description

  FROM [dbo].[EquipmentReadings]
  INNER JOIN EquipmentTypes AS ET ON ET.ID = EquipmentReadings.EquipmentTypeID
  INNER JOIN Sites AS Sites ON Sites.EDISID = EquipmentReadings.EDISID

  WHERE Sites.Hidden =0 AND ET.ID = 12 AND TradingDate BETWEEN @From AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @To))-- AND SiteID IN ('1007','1096','6402','7616')

  GROUP BY CAST ((TradingDate) AS DATE),Sites.SiteID,Sites.Name,Sites.Address3,ET.Description,Sites.PostCode

  ORDER BY SiteID,CAST ((TradingDate) AS DATE)
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_CellarTemperature] TO PUBLIC
    AS [dbo];

