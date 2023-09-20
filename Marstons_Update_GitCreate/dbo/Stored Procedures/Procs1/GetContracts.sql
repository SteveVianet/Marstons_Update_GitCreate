CREATE PROCEDURE [dbo].[GetContracts]

AS

SELECT	[ID],
	[Description],
	ExpiryDate,
	DefaultRaiseStatus,
	RequiresPO,
	CanBeginWithoutPO,
	PercentageIncrease,
	StartDate,
	AllInclusive,
	ISNULL(ContractSiteNumbers.Sites, 0) AS Sites,
	ISNULL(ContractSiteNumbers.BMSSites, 0) AS BMSSites,
	ISNULL(ContractSiteNumbers.IDraughtSites, 0) AS IDraughtSites,
	ISNULL(ContractSiteNumbers.ThreeMonthReview, 0) AS ThreeMonthReviewSites,
	ISNULL(ContractSiteNumbers.OneMonthReview, 0) AS OneMonthReviewSites,
	ISNULL(ContractSiteNumbers.OutOfContract, 0) AS OutOfContractSites,
	[Owner],
	UseBillingItems,
	MaintenancePeriodMin,
	MaintenancePeriodMax,
	TermYears,
	LabourMinutesThreshold,
	InvoiceCostThreshold,
	DataWeeklyIncomePerSite,
	DataWeeklyIncome,
	ServiceWeeklyIncomePerSite,
	ServiceWeeklyIncome,
	[Type]
FROM dbo.Contracts
LEFT JOIN (
	SELECT SiteContracts.ContractID,
		   SUM(CASE WHEN Sites.Quality = 0 THEN 1 ELSE 0 END) AS BMSSites,
		   SUM(CASE WHEN Sites.Quality = 1 THEN 1 ELSE 0 END) AS IDraughtSites,
		   COUNT(*) AS Sites,
		   SUM(CASE WHEN GETDATE() >= DATEADD(MONTH, -3, DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom)) AND GETDATE() < DATEADD(MONTH, -1, DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom)) THEN 1 ELSE 0 END) AS ThreeMonthReview,
		   SUM(CASE WHEN GETDATE() >= DATEADD(MONTH, -1, DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom)) THEN 1 ELSE 0 END) AS OneMonthReview,
		   SUM(CASE WHEN GETDATE() >= DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom) THEN 1 ELSE 0 END) AS OutOfContract
	FROM SiteContracts
	JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
	JOIN Sites ON Sites.EDISID = SiteContracts.EDISID
	LEFT JOIN SiteContractHistory ON SiteContractHistory.EDISID = SiteContracts.EDISID AND SiteContractHistory.ContractID = SiteContracts.ContractID AND SiteContractHistory.ValidTo IS NULL
	WHERE Sites.Hidden = 0
	GROUP BY SiteContracts.ContractID
) AS ContractSiteNumbers ON ContractSiteNumbers.ContractID = dbo.Contracts.[ID]

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetContracts] TO PUBLIC
    AS [dbo];

