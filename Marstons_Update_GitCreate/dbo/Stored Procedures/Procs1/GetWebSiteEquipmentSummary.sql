CREATE PROCEDURE [dbo].[GetWebSiteEquipmentSummary]
(
	@EDISID				INT,
	@EquipmentSubTypeID INT
)
AS

SELECT	Name,
		EquipmentTypeID,
		[Type],
		Location,
		Temperature,
		AlertNoData,
		AlertDate,
		AlertValue
FROM WebSiteTLEquipment
JOIN SiteRankingCurrent ON SiteRankingCurrent.EDISID = WebSiteTLEquipment.EDISID
WHERE WebSiteTLEquipment.EDISID = @EDISID
AND EquipmentSubTypeID = @EquipmentSubTypeID
AND LastUpdated >= DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebSiteEquipmentSummary] TO PUBLIC
    AS [dbo];

