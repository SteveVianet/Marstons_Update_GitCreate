CREATE PROCEDURE [dbo].[UpdateSiteKeyTaps] AS

DECLARE @To		DATETIME
DECLARE @From	DATETIME

SET @To = DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0) 
SET @From = DATEADD(wk, -6, @To)

-- clear table
DELETE FROM dbo.SiteKeyTaps

--Major (Type: 1) – 10% of total volume in last 6 weeks or 1056 pints 
--Middle (Type: 2) – 5 to 10% of total volume in last 6 weeks
--Minor (Type: 3) – Anything else

-- refill it
INSERT INTO dbo.SiteKeyTaps
SELECT	PumpSetup.EDISID,
		PumpSetup.Pump,
		MIN(CASE WHEN PumpDispense.Quantity > 1056 OR PumpDispense.Quantity >= (SiteDispense.Quantity/100)*10 THEN 1
			 WHEN PumpDispense.Quantity BETWEEN (SiteDispense.Quantity/100)*5 AND (SiteDispense.Quantity/100)*10 THEN 2
			 ELSE 3 END) AS [Type]
FROM PumpSetup
LEFT JOIN (SELECT EDISID, Pump, SUM(Quantity) AS Quantity
	  FROM DLData
	  JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
	  WHERE MasterDates.[Date] BETWEEN @From AND @To
	  GROUP BY EDISID, Pump
) AS PumpDispense ON PumpDispense.EDISID = PumpSetup.EDISID AND PumpDispense.Pump = PumpSetup.Pump
LEFT JOIN (SELECT EDISID, SUM(Quantity) AS Quantity
	  FROM DLData
	  JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
	  WHERE MasterDates.[Date] BETWEEN @From AND @To
	  GROUP BY EDISID) AS SiteDispense ON SiteDispense.EDISID = PumpSetup.EDISID
WHERE ValidTo IS NULL
GROUP BY PumpSetup.EDISID,
		PumpSetup.Pump

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteKeyTaps] TO PUBLIC
    AS [dbo];

