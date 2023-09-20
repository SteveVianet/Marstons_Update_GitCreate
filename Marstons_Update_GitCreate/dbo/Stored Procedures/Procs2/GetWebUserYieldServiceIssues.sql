
CREATE PROCEDURE GetWebUserYieldServiceIssues
(
	@UserID			INT,
	@DateFrom		DATETIME,
	@DateTo			DATETIME
)
AS

SET NOCOUNT ON;

DECLARE @IsAllSitesVisible   BIT

DECLARE @RelevantSites TABLE (EDISID INT NOT NULL)

SELECT @IsAllSitesVisible = UserTypes.AllSitesVisible
FROM Users
JOIN UserTypes ON UserTypes.ID = Users.UserType
WHERE Users.ID = @UserID

IF @IsAllSitesVisible = 0
BEGIN
	INSERT INTO @RelevantSites
	(EDISID)
	SELECT UserSites.EDISID
	FROM UserSites
	JOIN Sites ON Sites.EDISID = UserSites.EDISID
	WHERE UserID = @UserID
	AND Sites.Hidden = 0
	AND Sites.Quality = 1
END
ELSE
BEGIN
	INSERT INTO @RelevantSites
	(EDISID)
	SELECT EDISID
	FROM Sites
	WHERE Hidden = 0
	AND Sites.Quality = 1
END

SELECT sie.CallID, 
	DateFrom, 
	CAST(DateTo AS DATE) AS DateTo, 
	Products.[Description], 
	sie.PrimaryProductID AS ID, 
	Calls.VisitedOn AS VisitedOn, 
	CallReasonTypes.[Description] AS CallReason,
	dbo.udfConcatCallBillingItemsWorkCompleted(sie.CallID) AS WorkCompleted,
	CallCategories.[Description] AS CallCategory,
	CallTypes.[Description] AS CallType
FROM ServiceIssuesYield AS sie
INNER JOIN Products ON Products.ID = sie.ProductID
INNER JOIN Calls ON Calls.ID = sie.CallID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallCategories AS CallCategories ON CallCategories.ID = Calls.CallCategoryID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallTypes AS CallTypes ON CallTypes.ID = Calls.CallTypeID
INNER JOIN [SQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS CallReasonTypes ON CallReasonTypes.ID = sie.CallReasonTypeID
INNER JOIN @RelevantSites AS RelevantSites ON sie.EDISID = RelevantSites.EDISID
WHERE (sie.DateTo IS NULL OR CAST(sie.DateTo AS DATE) >= @DateFrom)
AND sie.DateFrom <= @DateTo


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetWebUserYieldServiceIssues] TO PUBLIC
    AS [dbo];

