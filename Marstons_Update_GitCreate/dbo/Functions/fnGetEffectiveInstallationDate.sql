CREATE FUNCTION [dbo].[fnGetEffectiveInstallationDate]
(
	@EDISID	INT
)

RETURNS DATETIME

AS

BEGIN
	DECLARE @Date DATETIME
	DECLARE @PropertyDate DATETIME
	DECLARE @InstallDate DATETIME
	DECLARE @DispenseDate DATETIME
	DECLARE @ServiceDate DATETIME
	
	-- Most important place is site property, which is used for transfers etc.
	SELECT @PropertyDate = CONVERT(DATETIME, LEFT(Value,10), 103)
	FROM SiteProperties
	JOIN Properties ON Properties.ID = SiteProperties.PropertyID
	WHERE EDISID = @EDISID AND Properties.Name = 'Original Install Date'
	
	IF @PropertyDate IS NOT NULL
	BEGIN
		SET @Date = @PropertyDate
		RETURN @Date
	END
	
	-- First fall back is to find an installation record
	SELECT @InstallDate = MAX(ClosedOn)
	FROM Calls
	WHERE CallTypeID = 2 AND EDISID = @EDISID
	AND AbortReasonID = 0
	
	IF @InstallDate IS NOT NULL
	BEGIN
		SET @Date = @InstallDate
		RETURN @Date
	END
	
	-- Second fall-back is earliest service call
	SELECT @ServiceDate = MIN(ClosedOn)
	FROM Calls
	WHERE CallTypeID = 1 AND EDISID = @EDISID
	AND AbortReasonID = 0
	
	IF @ServiceDate IS NOT NULL
	BEGIN
		SET @Date = @ServiceDate
	
		RETURN @Date
	END
	
	-- Third fall-back is earliest dispense date
	SELECT @DispenseDate = MIN(MasterDates.Date)
	FROM DLData WITH (NOLOCK)
	JOIN MasterDates WITH (NOLOCK) ON MasterDates.ID = DLData.DownloadID
	WHERE MasterDates.EDISID = @EDISID
	
	IF @DispenseDate IS NOT NULL
	BEGIN
		SET @Date = @DispenseDate
	
		RETURN @Date
	END
	
	-- Final fall back is to SiteOnline, which will always be set to something
	SELECT @Date = SiteOnline
	FROM Sites
	WHERE @EDISID = EDISID
	
	RETURN @Date 

END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnGetEffectiveInstallationDate] TO PUBLIC
    AS [dbo];

