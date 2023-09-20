CREATE PROCEDURE [neo].[GetOwnerYieldTargets]
	@UserID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Doesn't take into account users that have sites which span owners...
	SELECT o.TargetPouringYieldPercent AS PouringYieldTarget, o.TargetTillYieldPercent AS TillYieldTarget, o.PouringYieldCashValue, o.POSYieldCashValue
	FROM dbo.fnGetMultiCellarSites(@UserID, NULL, NULL) AS ms
	JOIN Sites AS s
		ON s.EDISID = ms.EDISID
	JOIN Owners AS o
		ON o.ID = s.OwnerID
	GROUP BY o.TargetPouringYieldPercent, o.TargetTillYieldPercent, o.PouringYieldCashValue, o.POSYieldCashValue
END

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetOwnerYieldTargets] TO PUBLIC
    AS [dbo];

