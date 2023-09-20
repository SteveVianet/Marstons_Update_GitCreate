CREATE PROCEDURE dbo.GetSiteRankingHistory
(
	@EDISID		INT,
	@TradingDay	DATETIME = NULL
)
AS

SELECT	EDISID,
		TradingDay,
		SiteEquipmentAmbientTL,
		SiteEquipmentRecircTL,
		SiteCleaningTL, 
		SiteCleaningKegTL,
		SiteCleaningCaskTL, 
		SiteThroughputTL, 
		SiteThroughputKegTL, 
		SiteThroughputCaskTL, 
		SiteTemperatureTL, 
		SiteTemperatureKegTL, 
		SiteTemperatureCaskTL, 
		SitePouringYieldTL, 
		SitePouringYieldKegTL, 
		SitePouringYieldCaskTL, 
		SiteTillYieldTL,
		SiteTillYieldKegTL, 
		SiteTillYieldCaskTL
FROM SiteRankingHistory
WHERE EDISID = @EDISID
AND (TradingDay = @TradingDay OR @TradingDay IS NULL)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteRankingHistory] TO PUBLIC
    AS [dbo];

