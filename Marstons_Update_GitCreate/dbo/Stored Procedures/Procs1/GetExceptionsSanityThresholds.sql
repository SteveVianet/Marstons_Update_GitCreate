
CREATE PROCEDURE dbo.GetExceptionsSanityThresholds
AS

SET NOCOUNT ON

DECLARE @LowSaneOverallYieldPercent				FLOAT
DECLARE @HighSaneOverallYieldPercent			FLOAT
DECLARE @LowSaneRetailYieldPercent				FLOAT
DECLARE @HighSaneRetailYieldPercent				FLOAT
DECLARE @LowSanePouringYieldPercent				FLOAT
DECLARE @HighSanePouringYieldPercent			FLOAT
DECLARE @LowSaneCleaningVolumePintsThreshold	FLOAT
DECLARE @LowSaneProductTemperaturePercent		FLOAT
DECLARE @HighSaneProductTemperaturePercent		FLOAT
DECLARE @LowSaneOutOfHoursVolumePintsThreshold	FLOAT

SELECT @LowSaneOverallYieldPercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'Low Sane Overall Yield Percent'

SELECT @HighSaneOverallYieldPercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'High Sane Overall Yield Percent'

SELECT @LowSaneRetailYieldPercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'Low Sane Retail Yield Percent'

SELECT @HighSaneRetailYieldPercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'High Sane Retail Yield Percent'

SELECT @LowSanePouringYieldPercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'Low Sane Pouring Yield Percent'

SELECT @HighSanePouringYieldPercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'High Sane Pouring Yield Percent'

SELECT @LowSaneCleaningVolumePintsThreshold = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'Low Sane Cleaning Volume Pints Threshold'

SELECT @LowSaneProductTemperaturePercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'Low Sane Product Temperature Percent'

SELECT @HighSaneProductTemperaturePercent = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'High Sane Product Temperature Percent'

SELECT @LowSaneOutOfHoursVolumePintsThreshold = CAST(PropertyValue AS FLOAT)
FROM Configuration
WHERE PropertyName = 'Low Sane Out of Hours Volume Pints Threshold'

SELECT	@LowSaneOverallYieldPercent AS LowSaneOverallYieldPercent,
		@HighSaneOverallYieldPercent AS HighSaneOverallYieldPercent,
		@LowSaneRetailYieldPercent AS LowSaneRetailYieldPercent,
		@HighSaneRetailYieldPercent AS HighSaneRetailYieldPercent,
		@LowSanePouringYieldPercent AS LowSanePouringYieldPercent,
		@HighSanePouringYieldPercent AS HighSanePouringYieldPercent,
		@LowSaneCleaningVolumePintsThreshold AS LowSaneCleaningVolumePintsThreshold,
		@LowSaneProductTemperaturePercent AS LowSaneProductTemperaturePercent,
		@HighSaneProductTemperaturePercent AS HighSaneProductTemperaturePercent,
		@LowSaneOutOfHoursVolumePintsThreshold AS LowSaneOutOfHoursVolumePintsThreshold

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetExceptionsSanityThresholds] TO PUBLIC
    AS [dbo];

