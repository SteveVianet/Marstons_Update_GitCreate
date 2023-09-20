CREATE PROCEDURE [dbo].[UpdateSiteLastElectricalCheckDate]
(
	@EDISID					INT,
	@LastElectricalCheck	DATETIME
)

AS

UPDATE Sites
SET LastElectricalCheckDate = @LastElectricalCheck
WHERE EDISID = @EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateSiteLastElectricalCheckDate] TO PUBLIC
    AS [dbo];

