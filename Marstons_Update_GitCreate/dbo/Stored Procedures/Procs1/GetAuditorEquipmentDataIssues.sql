CREATE PROCEDURE [dbo].[GetAuditorEquipmentDataIssues]
AS

SET NOCOUNT ON

DECLARE @From DATETIME
DECLARE @To DATETIME

SET @To = GETDATE()
SET @From = DATEADD(day, -1, @To)

DECLARE @EquipmentMaxTemps TABLE(EDISID INT NOT NULL, InputID INT NOT NULL, EquipmentType VARCHAR(50) NOT NULL, Value FLOAT NOT NULL)DECLARE @EquipmentDataIssues TABLE(EDISID INT NOT NULL, InputID INT NOT NULL, EquipmentType VARCHAR(50) NOT NULL, Value FLOAT NOT NULL)

DECLARE @CustomerID INT
SELECT @CustomerID = CAST(PropertyValue AS INTEGER)
FROM Configuration
WHERE PropertyName = 'Service Owner ID'

INSERT INTO @EquipmentMaxTemps
(EDISID, InputID, EquipmentType, Value)
SELECT EDISID, InputID, EquipmentTypes.[Description], MAX(Value)
FROM EquipmentReadings
JOIN EquipmentTypes ON EquipmentTypes.[ID] = EquipmentReadings.EquipmentTypeID
JOIN EquipmentSubTypes ON EquipmentSubTypes.[ID] = EquipmentTypes.EquipmentSubTypeID
WHERE LogDate BETWEEN @From AND @To
AND EquipmentSubTypes.ID IN (1, 2)
GROUP BY EDISID, InputID, EquipmentTypes.[Description]

INSERT INTO @EquipmentDataIssues
(EDISID, InputID, EquipmentType, Value)
SELECT EDISID, InputID, EquipmentType, Value
FROM @EquipmentMaxTemps
WHERE Value NOT BETWEEN -5 AND 40

SELECT @CustomerID AS Customer,
	   EquipmentDataIssues.EDISID,
	   CASE WHEN OpenCalls.[ID] IS NULL THEN NULL ELSE dbo.GetCallReference(OpenCalls.[ID]) END AS CallRef,
	   EquipmentDataIssues.EquipmentType,
	   EquipmentDataIssues.InputID,
	   EquipmentDataIssues.Value
FROM @EquipmentDataIssues AS EquipmentDataIssues
LEFT JOIN (	SELECT Calls.EDISID, Calls.[ID], MAX(CallStatusHistory.StatusID) AS Status
			FROM Calls
			JOIN @EquipmentDataIssues AS EquipmentDataIssues ON EquipmentDataIssues.EDISID = Calls.EDISID
			JOIN CallStatusHistory ON CallStatusHistory.CallID = Calls.[ID] AND CallStatusHistory.StatusID <> 6
			GROUP BY Calls.EDISID, Calls.[ID]
			HAVING MAX(CallStatusHistory.StatusID) NOT IN (4, 5) 
		  ) AS OpenCalls ON OpenCalls.EDISID = EquipmentDataIssues.EDISID

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetAuditorEquipmentDataIssues] TO PUBLIC
    AS [dbo];

