CREATE PROCEDURE [dbo].[AddPAT]
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
	@LeakageReading         FLOAT = NULL,
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

INSERT INTO dbo.PATTracking
(ApplianceID, CallID, PanelInstalled, TestDate, ReTestDue, Visual, Polarity, EarthCont, EarthContOperator, EarthContReading, Insulation, InsulationOperator, InsulationReading, 
[Load], LoadOperator, LoadReading, Leakage, LeakageOperator, LeakageReading, TouchLeak, SubLeak, Flash, TouchLeakReading, TouchLeakOperator)
VALUES
(@ApplianceID, @CallID, @PanelInstalled, @TestDate, @ReTestDue, @Visual, @Polarity, @EarthCont, @EarthContOperator, @EarthContReading, @Insulation, @InsulationOperator, 
@InsulationReading, @Load, @LoadOperator, @LoadReading, @Leakage, @LeakageOperator, @LeakageReading, @TouchLeak, @SubLeak, @Flash, @TouchLeakReading, @TouchLeakOperator)





GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddPAT] TO PUBLIC
    AS [dbo];

