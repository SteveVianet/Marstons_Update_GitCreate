CREATE PROCEDURE [dbo].[GetPrescalers]

	@EDISID AS INTEGER,
	@Pump AS INTEGER = NULL,
	@Date AS DATETIME = NULL

AS


SELECT ProposedFontSetupItems.FontNumber, ProposedFontSetupItems.NewCalibrationValue AS Prescaler 
FROM ProposedFontSetups
JOIN (SELECT MAX(ProposedFontSetups.ID) AS ID, ProposedFontSetupItems.FontNumber
	  FROM ProposedFontSetups
	  JOIN ProposedFontSetupItems ON ID = ProposedFontSetupID
	  WHERE EDISID = @EDISID AND (CreateDate <= @Date OR @Date IS NULL) AND ProposedFontSetupItems.NewCalibrationValue IS NOT NULL
	  GROUP BY ProposedFontSetupItems.FontNumber) AS SetupItems ON SetupItems.ID = ProposedFontSetups.ID
JOIN ProposedFontSetupItems ON ProposedFontSetupItems.ProposedFontSetupID = ProposedFontSetups.ID
 AND SetupItems.FontNumber = ProposedFontSetupItems.FontNumber
WHERE EDISID = @EDISID AND (ProposedFontSetupItems.FontNumber = @Pump OR @Pump IS NULL)
ORDER BY ProposedFontSetupItems.FontNumber
