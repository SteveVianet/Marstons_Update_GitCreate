CREATE PROCEDURE GetGroupHistoricalFont
(
	@GroupID		INTEGER,
	@FromDate		DATETIME,
	@ToDate		DATETIME,
	@ShowNotInUse	BIT = 1,
	@ShowWater		BIT = 1
)

AS

SELECT SiteGroupSites.EDISID,
	 IsPrimary,
	 Pump,
	 ProductID,
	 LocationID,
	 InUse,
	 BarPosition,
	 ValidFrom,
	 ValidTo

FROM dbo.PumpSetup 
JOIN dbo.SiteGroupSites ON PumpSetup.EDISID = SiteGroupSites.EDISID
JOIN dbo.Products ON dbo.PumpSetup.ProductID = dbo.Products.ID

WHERE SiteGroupID = @GroupID
AND (@FromDate <= ValidTo  OR ValidTo IS NULL) AND (@ToDate >= ValidFrom)
AND (IsWater = 0 OR @ShowWater = 1)
AND (InUse = 1 OR @ShowNotInUse = 1)

ORDER BY IsPrimary DESC, SiteGroupSites.EDISID, Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetGroupHistoricalFont] TO PUBLIC
    AS [dbo];

