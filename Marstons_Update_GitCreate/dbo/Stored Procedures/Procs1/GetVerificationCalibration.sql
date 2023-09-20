CREATE PROCEDURE GetVerificationCalibration
    @From DATE,
	@To DATE
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

	DECLARE @Company VARCHAR(50)


	SELECT @Company = c.PropertyValue
	FROM Configuration AS c
	WHERE c.PropertyName = 'Company Name'	

	SELECT 
	   pfs.[EDISID]
	  ,pfs.[CreateDate]
      ,REPLACE(SUBSTRING(pfs.[UserName],CHARINDEX('\', pfs.[UserName])+1,LEN(pfs.UserName)),'.',' ') AS CarriedOutBy
	  ,ce.Name AS CellarInspector
      ,@Company AS Customer
	  ,s.SiteID
	  ,s.Name
      ,pfs.[Comment]
      ,cal.CalibratedFonts
	  ,v.VerifiedFonts
	  ,total.TotalFonts
	  , CASE 
			WHEN total.TotalFonts = cal.CalibratedFonts 
				THEN 'Full Calibration'
			WHEN cal.CalibratedFonts > 0 and cal.CalibratedFonts < total.TotalFonts
				THEN 'Partial Calibration'
			ELSE
				'Verification'
		END AS WorkDone  
   FROM [dbo].[ProposedFontSetups] AS pfs
  JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[ContractorEngineers] AS ce
	ON ce.ID = pfs.CAMEngineerID
  JOIN Sites AS s
	ON s.EDISID = pfs.EDISID
  -- Get number of lines calibrated
	LEFT JOIN (
		SELECT p.ProposedFontSetupID, COUNT(DISTINCT p.FontNumber) AS CalibratedFonts
		FROM [ProposedFontSetupCalibrationValues] AS p
		JOIN ProposedFontSetupItems AS pfi
			ON pfi.FontNumber = p.FontNumber AND pfi.ProposedFontSetupID = p.ProposedFontSetupID
		WHERE pfi.InUse = 1
			AND LOWER(pfi.Product) NOT LIKE '%water%' 
			AND pfi.JobType = 2
		GROUP BY p.ProposedFontSetupID	
		) AS cal
		ON cal.ProposedFontSetupID = pfs.ID
	-- Get number of lines verified
	LEFT JOIN (
		SELECT p.ProposedFontSetupID, COUNT(DISTINCT p.FontNumber) AS VerifiedFonts
		FROM [ProposedFontSetupCalibrationValues] AS p
		JOIN ProposedFontSetupItems AS pfi
			ON pfi.FontNumber = p.FontNumber AND pfi.ProposedFontSetupID = p.ProposedFontSetupID
		WHERE pfi.InUse = 1
			AND LOWER(pfi.Product) NOT LIKE '%water%' 
			AND pfi.JobType = 3
		GROUP BY p.ProposedFontSetupID		
		) AS v
		ON v.ProposedFontSetupID = pfs.ID
	-- Get total in use fonts
	LEFT JOIN (
		SELECT p.ProposedFontSetupID, COUNT(DISTINCT p.FontNumber) AS TotalFonts
		FROM ProposedFontSetupItems AS p
		WHERE p.InUse = 1
			AND LOWER(p.Product) NOT LIKE '%water%'
		GROUP BY p.ProposedFontSetupID		 
		) AS total
		ON total.ProposedFontSetupID = pfs.ID
  WHERE pfs.[CreateDate] BETWEEN @From AND @To 
     --pfs.EDISID = 1138
  ORDER BY CreateDate DESC
 
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetVerificationCalibration] TO PUBLIC
    AS [dbo];

