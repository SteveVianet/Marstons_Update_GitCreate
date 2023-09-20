-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.CheckDispenseExists
    
    @EDISID int = NULL,
    @StartTime datetime = NULL,
    @FlowMeter int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PUMP INT;
    SET @PUMP = dbo.fnGetPumpFromFlowmeterAddress(@EDISID, @FlowMeter, @StartTime)

    SELECT TOP (1) [EDISID]
    FROM [dbo].[DispenseActions]
    WITH (NOLOCK)
    WHERE
		[EDISID] = @EDISID AND
        [StartTime] = @StartTime AND
        [Pump] = @PUMP
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[CheckDispenseExists] TO [fusion]
    AS [dbo];

