CREATE PROCEDURE [dbo].[GetSiteProductIFMSetpoint]
(
	@EDISID INT,
	@ProductID INT,
	@Pump INT = 0
)

AS

SET NOCOUNT ON

SELECT IFMConfiguration
FROM PumpSetup
WHERE EDISID = @EDISID
AND ProductID = @ProductID
AND ValidTo IS NULL
AND (Pump = @Pump OR @Pump = 0)

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteProductIFMSetpoint] TO PUBLIC
    AS [dbo];

