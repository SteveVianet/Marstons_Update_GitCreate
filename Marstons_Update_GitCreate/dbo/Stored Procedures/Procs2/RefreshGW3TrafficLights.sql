CREATE PROCEDURE [dbo].[RefreshGW3TrafficLights]

AS

SET NOCOUNT ON;

DECLARE @Gateway3 INT = 10

DECLARE @ID INT = 1
DECLARE @LastID INT = 1
DECLARE @Sites TABLE ([ID] INT IDENTITY(1,1), [EDISID] INT NOT NULL, [LastDispense] DATE)

DECLARE @CurrentEDISID INT
DECLARE @CurrentDate DATE

INSERT INTO @Sites ([EDISID], [LastDispense])
SELECT 
	[S].[EDISID],
	[S].[LastDownload]
FROM Sites AS [S] WITH (NOLOCK)
WHERE SystemTypeID IN (@Gateway3)

SELECT @LastID = MAX([ID]) FROM @Sites

--SELECT * FROM @Sites

WHILE @ID <= @LastID
BEGIN
	SELECT 
		@CurrentEDISID = [EDISID],
		--@CurrentDate = DATEADD(DAY, -1, [LastDispense])
        @CurrentDate = [LastDispense] -- The UpdateSiteTrafficLights procedure already moves the date back by 1 day
	FROM @Sites
	WHERE [ID] = @ID

	IF @CurrentDate IS NOT NULL
	BEGIN
		PRINT 'Refreshing Site: ' + CAST(@CurrentEDISID AS VARCHAR)
		EXEC UpdateSiteTrafficLights @CurrentEDISID, @CurrentDate, 0, NULL
	END
	ELSE
	BEGIN
		PRINT 'No dispense, skipping Site: ' + CAST(@CurrentEDISID AS VARCHAR)
	END

	SET @ID = @ID+1
END