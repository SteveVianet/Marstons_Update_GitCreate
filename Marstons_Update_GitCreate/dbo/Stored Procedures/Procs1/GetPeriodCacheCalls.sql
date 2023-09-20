﻿CREATE PROCEDURE [dbo].[GetPeriodCacheCalls] 
(
	@Date	DATETIME = NULL
)
AS
BEGIN

	SET NOCOUNT ON;

	IF @Date IS NULL
	BEGIN
		SELECT @Date = MAX([Date])
		FROM PeriodCacheCalls
	END
	
	SELECT	DatabaseID,
			CustomerName,
			[Date],
			DMSSites,
			IDraughtSites,
			DMSCompletedCalls,
			IDraughtCompletedCalls,
			DMSCompletedCallsInSLA,
			IDraughtCompletedCallsInSLA,
			DMSCompletedCallsOutSLA,
			IDraughtCompletedCallsOutSLA,
			SNACallsTotal,
			SNACallsInSLA,
			SNACallsOutSLA,
			CallsOutstanding,
			CallsOpen,
			AvgDaysFaultToApproved,
			AvgDaysApprovedToCompleted,
			SitesWithZeroCalls,
			SitesWithOverFiveCalls,
			DMSSitesWithZeroCalls,
			DMSSitesWithOverFiveCalls,
			IDraughtSitesWithZeroCalls,
			IDraughtSitesWithOverFiveCalls,
			CallsOnHold,
			DMSCallsOnHold,
			IDraughtCallsOnHold,
			CallsOnHoldBrulinesIssue,
			CallsOnHoldClientIssue,
			FlowmetersInstalled,
			DMSFlowmetersInstalledTotal,
			IDraughtFlowmetersInstalledTotal,
			DMSFlowmetersInstalledInPeriod,
			IDraughtFlowmetersInstalledInPeriod,
			FlowmetersCleaned,
			CallsCompleted,
			CallsRaised,
			CallsCancelled,
			CallsAborted,
			AvgDMSDaysApprovedToCompleted,
			AvgIDraughtDaysApprovedToCompleted,
			CalFailureNoProduct,
			CalFailureFobbing,
			CalFailureDispenseIssue,
			CallsCompletedLast6Periods,
			AvgDMSDaysApprovedToCompletedLast6Periods,
			AvgIDraughtDaysApprovedToCompletedLast6Periods,
			CallsInProgress,
			CallsOpenAvgDays,
			CallsInProgressAvgDays,
			CallsOpenOutsideSLA,
			CallsOpenOutsideSLAAvgDays,
			CallsOpenOutsideSLADMS,
			CallsOpenOutsideSLADMSAvgDays,
			CallsOpenOutsideSLAIDraught,
			CallsOpenOutsideSLAIDraughtAvgDays,
			SNACallsDMSTotal,
			SNACallsDMSInSLA,
			SNACallsDMSOutSLA,
			SNACallsIDraughtTotal,
			SNACallsIDraughtInSLA,
			SNACallsIDraughtOutSLA,
			CallsRaisedDMS,
			CallsRaisedIDraught,
			CallsOutstandingDMS,
			CallsOutstandingIDraught,
			CallsOpenDMS,
			CallsOpenIDraught,
			CallsInProgressDMS,
			CallsInProgressIDraught,
			CallsInProgressAvgDaysDMS,
			CallsInProgressAvgDaysIDraught,
			DMSCallsOnHoldBrulinesIssue,
			IDraughtCallsOnHoldBrulinesIssue,
			DMSCallsOnHoldClientIssue,
			IDraughtCallsOnHoldClientIssue,
			FlowmetersCleanedDMS,
			FlowmetersCleanedIDraught,
			CallsCancelledDMS,
			CallsCancelledIDraught,
			CallsAbortedDMS,
			CallsAbortedIDraught,
			CalibrationFailureNoProductDMS,
			CalibrationFailureNoProductIDraught,
			CalibrationFailureFobbingDMS,
			CalibrationFailureFobbingIDraught,
			CalibrationFailureDispenseIssueDMS,
			CalibrationFailureDispenseIssueIDraught,
			CallsOpenAvgDaysDMS,
			CallsOpenAvgDaysIDraught,
			PriorityCallsOpenDMS,
			PriorityCallsRaisedDMS,
			PriorityCallsOutstandingDMS,
			PriorityCallsInProgressDMS,
			PriorityCallsInProgressAvgDaysDMS,
			PriorityCallsOpenOutsideSLADMS,
			PriorityCallsOpenAvgDaysDMS,
			PriorityCallsOpenOutsideSLADMSAvgDays,
			PriorityCallsOpenIDraught,
			PriorityCallsRaisedIDraught,
			PriorityCallsOutstandingIDraught,
			PriorityCallsInProgressIDraught,
			PriorityCallsInProgressAvgDaysIDraught,
			PriorityCallsOpenOutsideSLAIDraught,
			PriorityCallsOpenAvgDaysIDraught,
			PriorityCallsOpenOutsideSLAIDraughtAvgDays,
			DMSSitesAllInclusive,
			IDraughtSitesAllInclusive,
			DMSSitesPAYGOther,
			IDraughtSitesPAYGOther,
			DMSSitesOver5Years,
			IDraughtSitesOver5Years,
			DMSSitesUnder5Years,
			IDraughtSitesUnder5Years
	FROM PeriodCacheCalls
	WHERE [Date] = @Date
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetPeriodCacheCalls] TO PUBLIC
    AS [dbo];

