CREATE PROCEDURE neo.GetOwnerPouringYieldTarget
	@UserID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Doesn't take into account users that have sites which span owners...
	SELECT o.TargetPouringYieldPercent AS PouringYieldTarget, o.PouringYieldCashValue
	FROM dbo.fnGetMultiCellarSites(@UserID, NULL, NULL) AS ms
	JOIN Sites AS s
		ON s.EDISID = ms.EDISID
	JOIN Owners AS o
		ON o.ID = s.OwnerID
	GROUP BY o.TargetPouringYieldPercent, o.PouringYieldCashValue
END

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetOwnerPouringYieldTarget] TO PUBLIC
    AS [dbo];

