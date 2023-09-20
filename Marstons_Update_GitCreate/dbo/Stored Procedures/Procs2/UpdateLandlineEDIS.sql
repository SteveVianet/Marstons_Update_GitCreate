CREATE PROCEDURE [dbo].[UpdateLandlineEDIS]
(
	@EDISTelNo		VARCHAR(50),
	@SiteID		VARCHAR(15)
)
AS

DECLARE @DatabaseID	INT

SELECT @DatabaseID = [PropertyValue]
FROM dbo.Configuration
WHERE PropertyName = 'Service Owner ID'

UPDATE Landline
SET Landline.PhoneNumber = @EDISTelNo
FROM [EDISSQL1\SQL1].PhoneBill.dbo.LandlineEDIS AS Landline
WHERE Landline.SiteID = @SiteID
AND Landline.DatabaseID = @DatabaseID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateLandlineEDIS] TO PUBLIC
    AS [dbo];

