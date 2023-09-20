CREATE FUNCTION [dbo].[fnGetPumpFromFlowmeterAddress]
(
	@EDISID 	INTEGER,
	@Flowmeter 	INTEGER,
	@Date 		DATETIME
)

RETURNS INT

AS

BEGIN
	DECLARE @Pump 	INTEGER
	
	SELECT TOP 1 @Pump = FontNumber
	FROM ProposedFontSetupItems AS pfsi
	JOIN ProposedFontSetups AS pfs ON pfs.ID = pfsi.ProposedFontSetupID
	JOIN PumpSetup AS ps ON pfs.EDISID = ps.EDISID
	WHERE PhysicalAddress = @Flowmeter
		AND DATEDIFF(Day, ps.ValidFrom, @Date) >= 0
		AND (DATEDIFF(Day, @Date, ps.ValidTo) <= 0 OR ps.ValidTo IS NULL)
		AND pfs.EDISID = @EDISID
	ORDER BY ID DESC
	
	RETURN @Pump

END