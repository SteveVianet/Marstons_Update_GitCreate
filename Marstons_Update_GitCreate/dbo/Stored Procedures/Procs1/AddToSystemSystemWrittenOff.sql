CREATE PROCEDURE [dbo].[AddToSystemSystemWrittenOff]
(
	@SiteID		VARCHAR(100),
	@WrittenOff	BIT
)
AS

INSERT INTO SystemStock
(DateIn, DateOut, OldInstallDate, EDISID, SystemTypeID, CallID, PreviousEDISID, PreviousName, PreviousPostcode, PreviousFMCount, WrittenOff, Comment)
SELECT	GETDATE(),
		NULL,
		Sites.InstallationDate,
		0,
		Sites.SystemTypeID,
		ISNULL(LastCallID.LastCall, 0),
		Sites.EDISID,
		Sites.Name,
		Sites.PostCode,
		ISNULL(SitePumps.Pumps, 0),
		@WrittenOff,
		CASE WHEN @WrittenOff = 1 THEN 'Written off' ELSE '' END
FROM Sites
LEFT JOIN (SELECT EDISID, MAX([ID]) AS LastCall FROM Calls GROUP BY EDISID) AS LastCallID ON LastCallID.EDISID = Sites.EDISID
LEFT JOIN (SELECT EDISID, COUNT(*) AS Pumps FROM PumpSetup WHERE ValidTo IS NULL GROUP BY EDISID) AS SitePumps ON SitePumps.EDISID = Sites.EDISID
WHERE Sites.SiteID = @SiteID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddToSystemSystemWrittenOff] TO PUBLIC
    AS [dbo];

