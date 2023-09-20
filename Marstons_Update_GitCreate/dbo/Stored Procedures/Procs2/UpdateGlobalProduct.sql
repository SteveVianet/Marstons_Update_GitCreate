CREATE PROCEDURE [dbo].[UpdateGlobalProduct]
(
	@Description					VARCHAR(100),
	@CategoryID						INT,
	@LowTemperatureSpecification	FLOAT,
	@HighTemperatureSpecification	FLOAT,
	@LowFlowrateSpecification		FLOAT,
	@HighFlowrateSpecification		FLOAT,
	@UWeaveSetpoint					VARCHAR(150),
	@ID								INT
)

AS

EXEC [EDISSQL1\SQL1].Product.dbo.UpdateProduct @Description,
											   @CategoryID,
											   @LowTemperatureSpecification,
											   @HighTemperatureSpecification,
											   @LowFlowrateSpecification,
											   @HighFlowrateSpecification,
											   @UWeaveSetpoint,
											   @ID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateGlobalProduct] TO PUBLIC
    AS [dbo];

