
CREATE VIEW [dbo].[ConfigurationPivot]

AS

SELECT
    CAST(LowSaneProdTempConfig.PropertyValue AS INT) AS LowSaneProductTemperature,
    CAST(HighSaneProdTempConfig.PropertyValue AS INT) AS HighSaneProductTemperature,
    CAST(LowSanePourYieldPcntConfig.PropertyValue AS INT) AS LowSanePouringYieldPercent,
    CAST(HighSanePourYieldPcntConfig.PropertyValue AS INT) AS HighSanePouringYieldPercent,
    CAST(LowSaneRetailYieldPcntConfig.PropertyValue AS INT) AS LowSaneRetailYieldPercent,
    CAST(HighSaneRetailYieldPcntConfig.PropertyValue AS INT) AS HighSaneRetailYieldPercent,
    CAST(LowSaneOvrlYieldConfig.PropertyValue AS INT) AS LowSaneOverallYieldPercent,
    CAST(HighSaneOvrlYieldConfig.PropertyValue AS INT) AS HighSaneOverallYieldPercent
FROM Configuration AS LowSaneProdTempConfig
FULL JOIN Configuration AS HighSaneProdTempConfig 
    ON HighSaneProdTempConfig.PropertyName = 'High Sane Product Temperature'
FULL JOIN Configuration AS LowSanePourYieldPcntConfig 
    ON LowSanePourYieldPcntConfig.PropertyName = 'Low Sane Pouring Yield Percent'
FULL JOIN Configuration AS HighSanePourYieldPcntConfig 
    ON HighSanePourYieldPcntConfig.PropertyName = 'High Sane Pouring Yield Percent'
FULL JOIN Configuration AS LowSaneRetailYieldPcntConfig 
    ON LowSaneRetailYieldPcntConfig.PropertyName = 'Low Sane Retail Yield Percent'
FULL JOIN Configuration AS HighSaneRetailYieldPcntConfig 
    ON HighSaneRetailYieldPcntConfig.PropertyName = 'High Sane Retail Yield Percent'
FULL JOIN Configuration AS LowSaneOvrlYieldConfig 
    ON LowSaneOvrlYieldConfig.PropertyName = 'Low Sane Overall Yield Percent'
FULL JOIN Configuration AS HighSaneOvrlYieldConfig 
    ON HighSaneOvrlYieldConfig.PropertyName = 'High Sane Overall Yield Percent'
WHERE LowSaneProdTempConfig.PropertyName = 'Low Sane Product Temperature'


