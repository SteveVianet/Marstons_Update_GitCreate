CREATE VIEW [dbo].[CallsSLA]

AS

--SET DATEFIRST 1
--Damn, can't do this in a view - must do it in calling SQL

SELECT	dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), COALESCE(ClosedOn, GETDATE())) AS DaysToComplete,
		OverrideSLA - dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), COALESCE(ClosedOn, GETDATE())) AS DaysLeftToCompleteWithinSLA,
		CAST(CASE WHEN OverrideSLA - dbo.fnGetWeekdayCount(COALESCE(CASE WHEN YEAR(POConfirmed) > 1950 THEN POConfirmed ELSE NULL END, RaisedOn), COALESCE(ClosedOn, GETDATE())) >= 0 THEN 1 ELSE 0 END AS BIT) AS CallWithinSLA,
		CallStatuses.CurrentStatusID AS CurrentStatusID,
		Calls.*
FROM Calls
JOIN (
	SELECT CallStatusHistoryIDs.CallID, StatusID AS CurrentStatusID
	FROM (
		SELECT CallID, MAX(ID) AS MaxStatusHistoryID
		FROM CallStatusHistory
		GROUP BY CallID
	) AS CallStatusHistoryIDs
	JOIN CallStatusHistory ON CallStatusHistory.ID = CallStatusHistoryIDs.MaxStatusHistoryID
) AS CallStatuses ON CallStatuses.CallID = Calls.ID
