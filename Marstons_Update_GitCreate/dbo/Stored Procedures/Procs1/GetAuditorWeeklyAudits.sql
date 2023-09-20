CREATE PROCEDURE [dbo].[GetAuditorWeeklyAudits]
AS

SET NOCOUNT ON
SET DATEFIRST 1

DECLARE @From DATETIME
DECLARE @To DATETIME

SET @From = CONVERT(DATETIME, FLOOR(CONVERT(FLOAT, DATEADD(day, -DATEPART(dw, GETDATE()) +1 , GETDATE()))))
SET @To = GETDATE()

DECLARE @CustomerID INT
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

SELECT @CustomerID AS Customer,
	   EDISID,
	   dbo.udfNiceName(UserName) AS Auditor,
	   AuditType
FROM SiteAudits
WHERE [TimeStamp] BETWEEN @From AND @To

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorWeeklyAudits] TO PUBLIC
    AS [dbo];

