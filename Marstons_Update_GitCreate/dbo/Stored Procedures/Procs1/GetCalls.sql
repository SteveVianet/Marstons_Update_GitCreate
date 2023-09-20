CREATE PROCEDURE [dbo].[GetCalls]
(
	@EDISID			INT	= NULL,
	@IncludeOpen		BIT		= 1,
	@IncludeOnHold		BIT	= 1,
	@IncludeInProgress	BIT		= 1,
	@IncludeClosed		BIT		= 1,
	@IncludeInvoiced	BIT		= NULL,
	@ClosedFrom		DATETIME	= NULL,
	@ClosedTo		DATETIME	= NULL,
	@CallID			INT		= NULL,
	@IncludePreRaised	BIT		= NULL,
	@IncludeCallTypeID	INT 		= NULL
)

AS

SET DATEFIRST 1

SELECT	Calls.[ID],
	EDISID,
	CallTypeID,
	RaisedOn,
	RaisedBy,
	ReportedBy,
	EngineerID,
	ContractorReference,
	PriorityID,
	POConfirmed,
	VisitedOn,
	ClosedOn,
	ClosedBy,
	InvoicedOn,
	InvoicedBy,
	SignedBy,
	AuthCode,
	POStatusID,
	SalesReference,
	CallStatusHistory.StatusID AS CurrentStatusID,
	CallStatusHistory.SubStatusID AS CurrentSubStatusID,
	CallStatusHistory.ChangedOn,
	WorkDetailComment,
	AbortReasonID,
	AbortDate,
	AbortUser,
	AbortCode,
	InProgressStatus.ChangedOn AS DateActioned,
	MostRecentOnHoldStatus.ChangedOn AS MostRecentOnHoldDate,
	SubsequentOnHoldStatus.ChangedOn AS AfterOnHoldDate,
	CustomerAbortCode,
	TelecomReference,
	SupplementaryCallStatusItems.[ID] AS SupplementaryCallStatusItemID,
	SupplementaryCallStatusItems.SupplementaryCallStatusID,
	SupplementaryCallStatusItems.SupplementaryDate,
	SupplementaryCallStatusItems.SupplementaryText,
	PreviousCallStatus.StatusID AS PreviousStatusID,
	PreviousCallStatus.SubStatusID AS PreviousSubStatusID,
	PreviousCallStatus.ChangedOn AS PreviousStatusChangedOn,
	DaysOnHold,
	OverrideSLA,
	IsChargeable,
	NumberOfVisits,
	VisitStartedOn,
	VisitEndedOn,
	PlanningIssueID,
	ReRaiseFromCallID,
	CallCategoryID,
	QualitySite,
	InstallationDate,
	RequestID,
	FlagToFinance,
	IncompleteReasonID,
	IncompleteDate,
	DaysToComplete,
	DaysLeftToCompleteWithinSLA,
	CallWithinSLA,
	AuthorisationRequired,
	ContractID,
	UseBillingItems,
	CreditDate,
	CreditAmount,
	StandardLabourCharge,
	AdditionalLabourCharge,
	ChargeReasonID
FROM dbo.CallsSLA AS Calls WITH (NOLOCK)
JOIN dbo.CallStatusHistory WITH (NOLOCK) ON CallStatusHistory.CallID = Calls.[ID]
LEFT JOIN dbo.SupplementaryCallStatusItems ON SupplementaryCallStatusItems.CallID = Calls.[ID]
LEFT JOIN dbo.CallStatusHistory AS InProgressStatus 
	ON InProgressStatus.CallID = Calls.[ID]
	AND InProgressStatus.StatusID <> 1
	AND InProgressStatus.[ID] =	(SELECT MIN(CallStatusHistory.[ID])
					FROM dbo.CallStatusHistory
					WHERE CallID = Calls.[ID]
					AND CallStatusHistory.StatusID <> 1)
LEFT JOIN dbo.CallStatusHistory AS MostRecentOnHoldStatus
	ON MostRecentOnHoldStatus.CallID = Calls.[ID]
	AND MostRecentOnHoldStatus.StatusID = 2
	AND MostRecentOnHoldStatus.[ID] =	(SELECT MAX(CallStatusHistory.[ID])
						FROM dbo.CallStatusHistory
						WHERE CallID = Calls.[ID]
						AND CallStatusHistory.StatusID = 2)
LEFT JOIN dbo.CallStatusHistory AS SubsequentOnHoldStatus
	ON SubsequentOnHoldStatus.CallID = Calls.[ID]
	AND SubsequentOnHoldStatus.StatusID <> 2
	AND SubsequentOnHoldStatus.[ID] =	(SELECT MIN(CallStatusHistory.[ID])
						FROM dbo.CallStatusHistory
						WHERE CallID = Calls.[ID]
						AND CallStatusHistory.[ID] > MostRecentOnHoldStatus.[ID])
LEFT JOIN dbo.CallStatusHistory AS PreviousCallStatus
	ON PreviousCallStatus.CallID = Calls.[ID]
	AND PreviousCallStatus.[ID] =	(SELECT MAX(InnerCallStatusHistory.[ID])
					FROM dbo.CallStatusHistory AS InnerCallStatusHistory
					WHERE CallID = Calls.[ID]
					AND InnerCallStatusHistory.[ID] <> CallStatusHistory.[ID])
WHERE (EDISID = @EDISID OR @EDISID IS NULL)
AND CallStatusHistory.[ID] =	(SELECT MAX(CallStatusHistory.[ID])
				FROM dbo.CallStatusHistory
				WHERE CallID = Calls.[ID])
AND (SupplementaryCallStatusItems.[ID] =	(SELECT MAX(SupplementaryCallStatusItems.[ID])
						FROM dbo.SupplementaryCallStatusItems
						WHERE CallID = Calls.[ID])
	OR SupplementaryCallStatusItems.[ID] IS NULL)
AND ((CallStatusHistory.StatusID = 1 AND @IncludeOpen = 1)
OR (CallStatusHistory.StatusID = 2 AND @IncludeOnHold = 1)
OR (CallStatusHistory.StatusID = 3 AND @IncludeInProgress = 1)
OR (CallStatusHistory.StatusID = 4 AND @IncludeClosed = 1)
OR (CallStatusHistory.StatusID = 6 AND @IncludePreRaised = 1))
AND (Calls.CallTypeID = @IncludeCallTypeID OR @IncludeCallTypeID IS NULL)
AND ((Calls.InvoicedOn IS NULL AND @IncludeInvoiced = 0)
OR (Calls.InvoicedOn IS NOT NULL AND @IncludeInvoiced = 1)
OR (@IncludeInvoiced IS NULL))
AND (@ClosedFrom IS NULL OR (CallStatusHistory.StatusID = 4 AND CallStatusHistory.ChangedOn >= @ClosedFrom))
AND (@ClosedTo IS NULL OR (CallStatusHistory.StatusID = 4 AND CallStatusHistory.ChangedOn <= @ClosedTo))
AND (Calls.[ID] = @CallID OR @CallID IS NULL)
ORDER BY Calls.RaisedOn
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetCalls] TO PUBLIC
    AS [dbo];

