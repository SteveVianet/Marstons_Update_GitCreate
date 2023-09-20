CREATE PROCEDURE [dbo].[GetProposedFontSetupGlasswareItems]
(
	@ProposedFontSetupID	INT
)

AS

SET NOCOUNT ON

DECLARE @EDISID INT
DECLARE @LastNewMeters TABLE(Pump INT NULL, LastNewMeterDate DATETIME NULL)

SELECT @EDISID = EDISID
FROM ProposedFontSetups
WHERE [ID] = @ProposedFontSetupID

INSERT INTO @LastNewMeters
(Pump, LastNewMeterDate)
SELECT FontNumber, MAX(CASE WHEN JobType = 1 THEN ProposedFontSetups.CreateDate ELSE NULL END) AS LastNewMeter
FROM ProposedFontSetups
LEFT JOIN ProposedFontSetupItems ON ProposedFontSetupItems.ProposedFontSetupID = ProposedFontSetups.[ID]
WHERE ProposedFontSetups.EDISID = @EDISID
AND [ID] < @ProposedFontSetupID
GROUP BY FontNumber

SELECT FontNumber, MAX(COALESCE(LastNewMeters.LastNewMeterDate, ProposedFontSetups.CreateDate)) AS LastGlassCal
FROM ProposedFontSetupItems
JOIN ProposedFontSetups ON ProposedFontSetups.ID = ProposedFontSetupItems.ProposedFontSetupID
JOIN @LastNewMeters AS LastNewMeters ON LastNewMeters.Pump = ProposedFontSetupItems.FontNumber
WHERE ProposedFontSetups.EDISID = @EDISID
AND GlasswareID IS NOT NULL
AND JobType IN (1,2)
AND [ID] < @ProposedFontSetupID
AND (ProposedFontSetups.CreateDate >= LastNewMeters.LastNewMeterDate OR LastNewMeters.LastNewMeterDate IS NULL)
GROUP BY FontNumber

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetProposedFontSetupGlasswareItems] TO PUBLIC
    AS [dbo];

