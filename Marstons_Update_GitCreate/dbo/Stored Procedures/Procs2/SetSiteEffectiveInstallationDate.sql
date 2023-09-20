CREATE PROCEDURE dbo.SetSiteEffectiveInstallationDate
(
	@SiteID 	VARCHAR(50),
	@Date		DATETIME
)

AS

SET NOCOUNT ON

DECLARE @EDISID		INTEGER

-- Find EDISID
SELECT @EDISID = [EDISID]
FROM dbo.Sites
WHERE SiteID = @SiteID

DECLARE @PropertyID INT
DECLARE @SitePropertyExists INT

-- Ensure Property exists in this database
SELECT @PropertyID = [ID]
FROM dbo.Properties
WHERE [Name] = 'Original Install Date'

IF @PropertyID IS NULL
BEGIN
	INSERT INTO dbo.Properties
	([Name])
	VALUES
	('Original Install Date')

	SET @PropertyID = @@IDENTITY
END

-- Ensure property is assigned to this site
SELECT @SitePropertyExists = COUNT(*)
FROM dbo.SiteProperties
WHERE [PropertyID] = @PropertyID AND EDISID = @EDISID

IF @SitePropertyExists < 1
BEGIN
	INSERT INTO dbo.SiteProperties
	([EDISID], [PropertyID], [Value])
	VALUES
	(@EDISID, @PropertyID, CAST(DATEPART(day, @Date) AS VARCHAR) + '/' + CAST(DATEPART(month, @Date) AS VARCHAR) + '/' + CAST(DATEPART(year, @Date) AS VARCHAR))
END
ELSE
BEGIN
	UPDATE dbo.SiteProperties
	SET Value = CAST(DATEPART(day, @Date) AS VARCHAR) + '/' + CAST(DATEPART(month, @Date) AS VARCHAR) + '/' + CAST(DATEPART(year, @Date) AS VARCHAR)
	WHERE SiteProperties.EDISID = @EDISID
	AND SiteProperties.[PropertyID] = @PropertyID
END
