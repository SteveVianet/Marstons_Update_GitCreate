CREATE PROCEDURE [dbo].[AddGlobalProduct]
(
	@Description					VARCHAR(100),
	@CategoryID						INT,
	@LowTemperatureSpecification	FLOAT,
	@HighTemperatureSpecification	FLOAT,
	@LowFlowrateSpecification		FLOAT,
	@HighFlowrateSpecification		FLOAT,
	@ID								INT OUTPUT
)

AS

EXEC [EDISSQL1\SQL1].[Product].dbo.AddProduct @Description,
											  @CategoryID,
											  @LowTemperatureSpecification,
											  @HighTemperatureSpecification,
											  @LowFlowrateSpecification,
											  @HighFlowrateSpecification,
											  @ID OUTPUT

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddGlobalProduct] TO PUBLIC
    AS [dbo];

