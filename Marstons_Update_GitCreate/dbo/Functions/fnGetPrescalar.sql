CREATE FUNCTION [dbo].[fnGetPrescalar]
(
	@EDISID 	INTEGER,
	@Pump 	INTEGER,
	@Date 		DATETIME
)

RETURNS INT

AS

BEGIN
	DECLARE @Prescalar 	INTEGER

	SELECT TOP 1 @Prescalar = NewCalibrationValue
	FROM ProposedFontSetups AS pfs
	JOIN ProposedFontSetupItems AS pfsi ON pfs.ID = pfsi.ProposedFontSetupID
	JOIN PumpSetup AS ps ON pfs.EDISID = ps.EDISID
	WHERE  pfs.EDISID = @EDISID
		AND DATEDIFF(Day, ps.ValidFrom, @Date) >= 0
		AND (DATEDIFF(Day, @Date, ps.ValidTo) <= 0 OR ps.ValidTo IS NULL)
		AND pfsi.FontNumber = @Pump
		AND NewCalibrationValue IS NOT NULL
		AND NewCalibrationValue > 0
	ORDER BY ID DESC
	
	RETURN @Prescalar

END