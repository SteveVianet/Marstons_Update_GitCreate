CREATE PROCEDURE [neo].[GetYieldTargets]
	@UserID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT ms.EDISID, ms.Name, o.ID, o.Name, o.TargetPouringYieldPercent, o.TargetTillYieldPercent
	FROM dbo.fnGetMultiCellarSites(@UserID, NULL, NULL) AS ms
	JOIN Sites AS s
		ON s.EDISID = ms.EDISID
	JOIN Owners AS o
		ON o.ID = s.OwnerID
END
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetYieldTargets] TO PUBLIC
    AS [dbo];

