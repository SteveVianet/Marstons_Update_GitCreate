CREATE PROCEDURE [dbo].[GetSiteCalibrationDetails]
(
	@EDISID		INT
)

AS

SELECT EDISID, GlasswareStateID AS GlasswareState
FROM ProposedFontSetups
WHERE CreateDate IN
(
SELECT MAX(CreateDate) AS CreateDate
FROM ProposedFontSetups 
WHERE EDISID = @EDISID
AND Available = 1
)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteCalibrationDetails] TO PUBLIC
    AS [dbo];

