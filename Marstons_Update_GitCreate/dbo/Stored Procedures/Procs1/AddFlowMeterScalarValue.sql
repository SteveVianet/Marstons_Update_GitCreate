CREATE PROCEDURE [dbo].[AddFlowMeterScalarValue]
(
	-- System Values
	@DatabaseID	INTEGER,
	@EDISID	INTEGER,
	@TimeStamp	DATETIME,
	
	-- Flow Meter Values
	@FlowMeter	INTEGER,
	@Scalar	INTEGER
)

AS

BEGIN

	EXEC [SQL1\SQL1].ServiceLogger.dbo.AddFlowMeterScalarValue @DatabaseID, @EDISID, @TimeStamp, @FlowMeter, @Scalar

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddFlowMeterScalarValue] TO PUBLIC
    AS [dbo];

