CREATE PROCEDURE [dbo].[zRS_Variance_CD]
(
@From DATETIME =NULL,
@To DATETIME =NULL
)

AS 

SET NOCOUNT ON;

SET DATEFIRST 1;

CREATE TABLE #SitesToExclude(EDISID INT);	-- SBain (20191008): Temp Table to hold Sites to Exclude

/*** SBain (20191008): Select Sites set to "Exclude From Reds" ***/
INSERT INTO #SitesToExclude
	SELECT	EDISID
	FROM	dbo.SiteProperties AS sp
		INNER JOIN dbo.Properties AS p ON (sp.[PropertyID] = p.[ID])
	WHERE	(p.[Name] = 'Exclude From Reds');

SELECT		Sites.SiteID,
			PCC.[Period],
			PCC.Processed,
			PCC.PeriodYear,
			PCC.PeriodNumber,
			PCC.[FromWC],
			PCC.ToWC,
			PCC.[PeriodWeeks],
			[PeriodDelivered],
			[PeriodDispensed],
			[PeriodVariance],
			-- [InsufficientData],
			[CD]     
  FROM		[dbo].[Reds]
		INNER JOIN Sites ON (Sites.EDISID = Reds.EDISID)
		INNER JOIN PubcoCalendars PCC ON (Reds.Period = PCC.Period)
  WHERE		(InsufficientData = 0) AND (PCC.[FromWC] BETWEEN @From AND @To) AND (PCC.Processed = 1) AND (Sites.Hidden = 0) -- AND SiteID='125944'
		AND (Sites.EDISID NOT IN (SELECT EDISID FROM #SitesToExclude));		-- SBain (20191008): Exclude From Reds

DROP TABLE #SitesToExclude;		-- SBain (20191008): Drop Temp Table
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[zRS_Variance_CD] TO PUBLIC
    AS [dbo];

