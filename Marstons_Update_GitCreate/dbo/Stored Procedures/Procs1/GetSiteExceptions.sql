
CREATE PROCEDURE [dbo].[GetSiteExceptions]
(
	@SiteID         VARCHAR(15),
	@AlarmDate	    DATETIME
)
AS

SET NOCOUNT ON

DECLARE @EDISID INT
DECLARE @SiteGroupID INT
DECLARE @CasioAlarmPropertyName VARCHAR(50) = 'CasioAlarmEnabled'

SELECT @SiteGroupID = [SiteGroups].[ID]
FROM [SiteGroupSites]
JOIN [SiteGroups] ON [SiteGroups].[ID] = [SiteGroupSites].[SiteGroupID]
JOIN [SiteGroupTypes] ON [SiteGroups].[TypeID] = [SiteGroupTypes].[ID]
JOIN [Sites] ON [SiteGroupSites].[EDISID] = [Sites].[EDISID]
WHERE [SiteGroupTypes].[HasPrimary] = 1
AND [Sites].[SiteID] = @SiteID

IF @SiteGroupID IS NOT NULL
BEGIN
    -- We need to get the EDISID of the primary site of the multi-cellar group
	SELECT @EDISID = [EDISID]
	FROM [SiteGroupSites]
	WHERE [SiteGroupSites].[IsPrimary] = 1
	AND [SiteGroupID] = @SiteGroupID
END
ELSE
BEGIN
    -- Get the EDISID of the Site
    SELECT @EDISID = [EDISID]
    FROM [Sites]
    WHERE [Sites].[SiteID] = @SiteID
END

SELECT
    [SiteExceptions].[TradingDate] AS [TradingDate],
    [SiteExceptions].[ShiftStart] AS [Timestamp],
    [SiteExceptions].[AdditionalInformation] AS [Type],
    [SiteExceptions].[Value] AS [Value],
    [SiteExceptionTypes].[Rank]
FROM [SiteExceptions]
JOIN [SiteProperties] ON [SiteProperties].[EDISID] = [SiteExceptions].[EDISID]
JOIN [Properties] ON [SiteProperties].[PropertyID] = [Properties].[ID]
JOIN [SiteExceptionTypes] ON [SiteExceptions].[Type] = [SiteExceptionTypes].[Description]
WHERE [SiteExceptions].[EDISID] = @EDISID
AND [SiteExceptions].[TradingDate] >= @AlarmDate
AND [SiteExceptions].[ExceptionEmailID] IS NULL
AND [SiteExceptions].[Type] <> 'Equipment Alarm'
AND [Properties].[Name] = @CasioAlarmPropertyName
ORDER BY [SiteExceptions].[TradingDate] ASC, [SiteExceptionTypes].[Rank] DESC

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSiteExceptions] TO PUBLIC
    AS [dbo];

