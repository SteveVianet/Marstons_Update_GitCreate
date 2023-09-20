CREATE PROCEDURE [dbo].[GetVRSUsersReport] 


AS

SELECT Users.UserName, VRSUserID,
	COUNT(VisitRecords.ID) AS Created, 
	COUNT(CompletedByCustomer) AS Completed,
	(COUNT(VisitRecords.ID) - COUNT(ClosedByCAM) - COUNT(CASE WHEN ClosedByCAM IS NULL THEN CASE VerifiedByVRS WHEN 1 THEN 1 ELSE NULL END ELSE NULL END)) AS AwaitingSubmission, 
	COUNT(VisitRecords.ID) - COUNT(CompletedByCustomer) - (COUNT(VerifiedByVRS) - COUNT(CompletedByCustomer)) - (COUNT(VisitRecords.ID) - COUNT(ClosedByCAM) - COUNT(CASE WHEN ClosedByCAM IS NULL THEN CASE VerifiedByVRS WHEN 1 THEN 1 ELSE NULL END ELSE NULL END)) AS AwaitingVerification, 
	(COUNT(VerifiedByVRS) - COUNT(CompletedByCustomer)) AS AwaitingCompletion
FROM Users
LEFT JOIN VisitRecords ON Users.ID = CAMID AND CustomerID = 0
WHERE VRSUserID IS NOT NULL
AND VisitRecords.Deleted = 0
GROUP BY UserName, VRSUserID