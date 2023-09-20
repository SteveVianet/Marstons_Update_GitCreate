CREATE PROCEDURE [dbo].[UpdateVisitDamages]
(
	@DamagesID			INT,
	@DamagesType		INT,
	@Damages			NUMERIC(10,2) = NULL,
	@Product			NVARCHAR(50) = NULL,
	@ReportedDraughtVolume	NUMERIC(10,2) = NULL,
	@DraughtVolume		NUMERIC(10,2) = NULL,
	@DraughtStock			NUMERIC(10,2) = NULL,
	@Cases			INT = NULL,
	@Bottles			INT = NULL,
	@CalCheck			INT = NULL,
	@Agreed			BIT = NULL,
	@Comment			NVARCHAR(2000) = NULL
)
AS

SET NOCOUNT ON

--Bodge to prevent random bug where Damages had value where no volume had been supplied
IF @DraughtVolume = 0 AND @Damages > 0 AND @DamagesType IN (1, 2)
BEGIN
	DECLARE @DamagesRate		INT

	SELECT @DamagesRate = CAST(PropertyValue AS INTEGER)
	FROM Configuration
	WHERE PropertyName = 'Damages Per Barrel'

	SET @Damages = ISNULL(@Damages, 0)
	SET @DraughtVolume =  ROUND(@Damages / @DamagesRate/36.0, 0)
	
END

UPDATE dbo.VisitDamages
SET 	DamagesType = @DamagesType, 
	Damages = @Damages,
	Product = @Product, 
	ReportedDraughtVolume = @ReportedDraughtVolume, 
	DraughtVolume = @DraughtVolume, 
	DraughtStock = @DraughtStock,
	Cases = @Cases, 
	Bottles = @Bottles, 
	CalCheck = @CalCheck, 
	Agreed = @Agreed,
	Comment = @Comment

WHERE DamagesID = @DamagesID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateVisitDamages] TO PUBLIC
    AS [dbo];

