CREATE PROCEDURE [dbo].[UpdateSiteProductIFMSetpoint]
(
	@EDISID INT,
	@ProductID INT,
	@Setpoint VARCHAR(150),
	@Pump INT = 0
)
AS

SET NOCOUNT ON

DECLARE @Sites TABLE(EDISID INT)
DECLARE @SiteGroupID INT

INSERT INTO @Sites
(EDISID)
SELECT @EDISID AS EDISID

SELECT @SiteGroupID = SiteGroupID
FROM SiteGroupSites
JOIN SiteGroups ON SiteGroups.ID = SiteGroupSites.SiteGroupID
WHERE TypeID = 1 AND EDISID = @EDISID

INSERT INTO @Sites
(EDISID)
SELECT EDISID
FROM SiteGroupSites
WHERE SiteGroupID = @SiteGroupID AND EDISID <> @EDISID

UPDATE PumpSetup SET IFMConfiguration = @Setpoint
FROM PumpSetup
JOIN @Sites AS Sites ON Sites.EDISID = PumpSetup.EDISID
WHERE ValidTo IS NULL
AND ProductID = @ProductID
AND (Pump = @Pump OR @Pump = 0)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteProductIFMSetpoint] TO PUBLIC
    AS [dbo];

