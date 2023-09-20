CREATE PROCEDURE [dbo].[UpdatePATRecord]
(
	@ApplianceID 		NVARCHAR(10),
	@CallID			BIGINT,
	@TestDate		SMALLDATETIME,
	@ReTestDue		DATETIME OUTPUT,
	@Visual			TINYINT,
	@Polarity		TINYINT,
	@EarthCont		TINYINT,
	@EarthContOperator	TINYINT,
	@EarthContReading	FLOAT = NULL,
	@Insulation		TINYINT,
	@InsulationOperator	TINYINT,
	@InsulationReading	FLOAT = NULL,
	@Load			TINYINT,
	@LoadOperator		TINYINT,
	@LoadReading		FLOAT = NULL,
	@Leakage		TINYINT,
	@LeakageOperator	TINYINT,
	@LeakageReading	FLOAT = NULL,
	@TouchLeak		TINYINT,
	@SubLeak		TINYINT,
	@Flash			TINYINT,
	@PanelInstalled		SMALLDATETIME = NULL,
	@TouchLeakReading 	FLOAT = NULL,
	@TouchLeakOperator 	TINYINT = 0
)

AS

SET NOCOUNT ON

SET @ReTestDue = DATEADD(yy, 1, @TestDate)

UPDATE dbo.PATTracking

SET ApplianceID = @ApplianceID, 
PanelInstalled = @PanelInstalled, 
TestDate = @TestDate, 
Visual = @Visual, 
Polarity = @Polarity, 
EarthCont = @EarthCont, 
EarthContOperator = @EarthContOperator, 
EarthContReading = @EarthContReading, 
Insulation = @Insulation, 
InsulationOperator = @InsulationOperator, 
InsulationReading = @InsulationReading, 
[Load] = @Load, 
LoadOperator = @LoadOperator, 
LoadReading = @LoadReading, 
Leakage = @Leakage, 
LeakageOperator = @LeakageOperator, 
LeakageReading = @LeakageReading, 
TouchLeak = @TouchLeak, 
SubLeak = @SubLeak, 
Flash = @Flash,
TouchLeakReading = @TouchLeakReading,
TouchLeakOperator =  @TouchLeakOperator


WHERE CallID = @CallID
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdatePATRecord] TO PUBLIC
    AS [dbo];

