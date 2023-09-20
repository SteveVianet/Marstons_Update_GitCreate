-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.GetLiveSyrupSites

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT  SiteID,
		Sites.Name,
		Sites.PostCode,
		Products.Description
	FROM Sites
	JOIN PumpSetup ON PumpSetup.EDISID = Sites.EDISID
	JOIN Products ON Products.ID = PumpSetup.ProductID
	WHERE PumpSetup.ValidTo IS NULL AND Products.IsMetric = 1
END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetLiveSyrupSites] TO PUBLIC
    AS [dbo];

