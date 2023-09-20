CREATE PROCEDURE [dbo].[RollbackDownloadedData]
(
	@EDISID 			INTEGER, 
	@FromDate			DATETIME		-- This date is inclusive (it will be deleted)
)

AS

DECLARE @GatewayThree   INT = 10
DECLARE @SystemType     INT

SELECT @SystemType = [Sites].[SystemTypeID]
FROM [dbo].[Sites]
WHERE [EDISID] = @EDISID

IF @SystemType <> @GatewayThree
BEGIN
    DECLARE @MasterDates TABLE(ID INT NOT NULL)

    INSERT INTO @MasterDates
    ([ID])
    SELECT [ID]
    FROM dbo.MasterDates
    WHERE EDISID = @EDISID AND [Date] >= @FromDate

    DELETE
    FROM dbo.DispenseActions
    WHERE DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) >= @FromDate AND EDISID = @EDISID

    DELETE
    FROM dbo.CleaningStack
    WHERE CleaningID IN (SELECT ID FROM @MasterDates)

    DELETE
    FROM dbo.EquipmentReadings
    WHERE LogDate >= @FromDate AND EDISID = @EDISID

    DELETE
    FROM dbo.FaultStack
    WHERE FaultID IN (SELECT ID FROM @MasterDates)

    DELETE
    FROM dbo.WaterStack
    WHERE WaterID IN (SELECT ID FROM @MasterDates)

    DELETE
    FROM dbo.DLData
    WHERE DownloadID IN (SELECT ID FROM @MasterDates)

    DELETE
    FROM dbo.CleaningServiceActions
    WHERE MasterDateID IN (SELECT ID FROM @MasterDates)

    DELETE
    FROM dbo.LineCleaning
    WHERE EDISID = @EDISID AND [Date] >= @FromDate

    UPDATE dbo.SiteProperties
    SET Value = ''
    FROM dbo.SiteProperties
    JOIN dbo.Properties ON dbo.SiteProperties.PropertyID = dbo.Properties.ID
    WHERE Name = 'Last GPRS connection' AND EDISID = @EDISID

    UPDATE dbo.Sites
    SET LastDownload = DATEADD(dd, -1, @FromDate)
    WHERE EDISID = @EDISID
END
ELSE
BEGIN
    PRINT 'Denied Rollback due to System Type'
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RollbackDownloadedData] TO PUBLIC
    AS [dbo];

