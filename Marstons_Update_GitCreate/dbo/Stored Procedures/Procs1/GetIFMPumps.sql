-- =============================================
-- Author:		David Green
-- Create date: 22/June/2009
-- Description:	Retrieve a list of Pumps which
--				are IFMs between the dates 
--				given.
-- =============================================
CREATE PROCEDURE [dbo].[GetIFMPumps]
	-- Add the parameters for the stored procedure here
	@EDISID INT,
	@FromDate DATETIME, 
	@ToDate DATETIME,
	@Pump INT = -1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DispenseActions.Pump AS Pump, DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) AS [Date], AVG(ISNULL(AverageTemperature,-9999)) AS Temp
	FROM DispenseActions 
	WHERE DispenseActions.EDISID = @EDISID
	AND DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @FromDate AND @ToDate
	AND (DispenseActions.Pump = @Pump OR @Pump = -1)
	GROUP BY DispenseActions.Pump, DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime))
	--HAVING AVG(ISNULL(AverageTemperature,-9999)) <> -9999
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetIFMPumps] TO PUBLIC
    AS [dbo];

