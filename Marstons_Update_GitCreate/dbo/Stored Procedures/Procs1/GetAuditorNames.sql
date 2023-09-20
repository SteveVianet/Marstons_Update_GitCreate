CREATE PROCEDURE [dbo].[GetAuditorNames]

	@EDISID As INT = NULL

AS

DECLARE @MultipleAuditors AS BIT

SELECT @MultipleAuditors = MultipleAuditors 
FROM [SQL1\SQL1].ServiceLogger.dbo.EDISDatabases 
WHERE Name = DB_NAME()
AND (LimitToClient = HOST_NAME() OR LimitToClient IS NULL)

IF @MultipleAuditors = 0
BEGIN
	SELECT 'MAINGROUP\' + REPLACE(REPLACE(UPPER(PropertyValue), '@BRULINES.COM', ''), '@BRULINES.CO.UK', '') As SiteUser FROM Configuration WHERE PropertyName = 'AuditorEMail'
END
ELSE
BEGIN
	SELECT UPPER(SiteUser) As SiteUser
	FROM Sites
	WHERE EDISID = @EDISID OR @EDISID IS NULL AND SiteUser <>'' AND Hidden = 0
	GROUP BY UPPER(SiteUser)
	ORDER BY UPPER(SiteUser) ASC
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorNames] TO PUBLIC
    AS [dbo];

