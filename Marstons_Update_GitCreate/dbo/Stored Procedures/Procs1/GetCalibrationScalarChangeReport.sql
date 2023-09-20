CREATE PROCEDURE dbo.GetCalibrationScalarChangeReport
(
	@From			DATETIME,
	@To				DATETIME,
	@PercentThreshold	INT
)
AS

SET NOCOUNT ON

DECLARE @Customer VARCHAR(50)

SELECT @Customer = CAST(PropertyValue AS VARCHAR)
FROM Configuration
WHERE PropertyName = 'Company Name'

SELECT	@Customer AS Customer,
		Sites.SiteID,
		Sites.Name,
		ProposedFontSetups.CreateDate,
		FontNumber,
		(NewCalibrationValue / CAST(OriginalCalibrationValue AS FLOAT) - 1) * 100 AS PercentageDifference,
		OriginalCalibrationValue,
		NewCalibrationValue,
		CASE WHEN (NewCalibrationValue / CAST(OriginalCalibrationValue AS FLOAT) - 1) * 100 < @PercentThreshold THEN 'Increase' ELSE 'Decrease' END AS EffectOnData
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
JOIN Sites ON Sites.EDISID = ProposedFontSetups.EDISID
WHERE JobType = 2
AND ProposedFontSetups.CreateDate BETWEEN @From AND DATEADD(DAY, 1, @To)
AND (NewCalibrationValue IS NOT NULL AND OriginalCalibrationValue IS NOT NULL) 
AND (OriginalCalibrationValue <> 0)
AND ((NewCalibrationValue / CAST(OriginalCalibrationValue AS FLOAT) - 1) * 100 > @PercentThreshold OR (NewCalibrationValue / CAST(OriginalCalibrationValue AS FLOAT) - 1) * 100 < (@PercentThreshold*-1))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCalibrationScalarChangeReport] TO PUBLIC
    AS [dbo];

