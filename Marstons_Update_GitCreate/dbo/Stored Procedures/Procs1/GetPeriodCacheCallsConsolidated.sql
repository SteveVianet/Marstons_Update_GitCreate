CREATE PROCEDURE [dbo].[GetPeriodCacheCallsConsolidated]
(
	@SiteLimit	INT = NULL,
	@Quality	BIT = 0
)
AS

EXEC [EDISSQL1\SQL1].ServiceLogger.dbo.GetPeriodCacheEstateCalls @SiteLimit, @Quality

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPeriodCacheCallsConsolidated] TO PUBLIC
    AS [dbo];

