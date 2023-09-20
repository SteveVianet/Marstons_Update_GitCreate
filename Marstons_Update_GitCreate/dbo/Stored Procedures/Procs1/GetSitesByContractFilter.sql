CREATE PROCEDURE [dbo].[GetSitesByContractFilter]
(
	@ContractID					INT = NULL,
	@SystemTypeID				INT = NULL,
	@ShowBMS					BIT = 1,
	@ShowIDraught				BIT = 1,
	@ShowLessThan1YearSites		BIT = 1,
	@ShowBetween1And2YearSites	BIT = 1,
	@ShowBetween2And3YearSites	BIT = 1,
	@ShowBetween3And4YearSites	BIT = 1,
	@ShowBetween4And5YearSites	BIT = 1,
	@ShowMoreThan5YearSites		BIT = 1,
	@ShowInContractSites		BIT = 1,
	@ShowThreeMonthReviewSites	BIT = 1,
	@ShowOneMonthSites			BIT = 1,
	@ShowOutOfContractSites		BIT = 1,
	@ShowActiveSites			BIT = 1,
	@ShowClosedSites			BIT = 1,
	@ShowFOTSites				BIT = 1,
	@ShowLegalsSites			BIT = 1,
	@ShowNotReportedOnSites		BIT = 1,
	@ShowWrittenOffSites		BIT = 1,
	@ShowUnknownSites			BIT = 1
)
AS

SELECT	Sites.EDISID,
		Sites.SiteID,
		Sites.Name,
		Sites.PostCode,
		Sites.Quality,
		SiteContracts.ContractID,
		Contracts.[Description] AS ContractDescription,
		Contracts.TermYears,
		SiteContractHistory.ValidFrom AS BeganContract,
		DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom) AS ContractEndDate,
		SystemTypes.[Description] AS SystemType,
		ContractStatuses.ContractStatus,
		Contracts.MaintenancePeriodMin,
		Contracts.MaintenancePeriodMax,
		Sites.LastInstallationDate,
		Sites.InstallationDate AS PanelBirthDate,
		Installs.LastInstallActivity,
		ISNULL(Installs.UsedStock, 0) AS UsedStock,
		Installs.CallID,
		CASE WHEN DATEADD(YEAR, TermYears, SiteContractHistory.ValidFrom) >= DATEADD(MONTH, -1, DATEADD(YEAR, TermYears, GETDATE())) AND DATEADD(YEAR, TermYears, SiteContractHistory.ValidFrom) <= DATEADD(YEAR, TermYears, GETDATE()) THEN 1 ELSE 0 END
FROM Sites
JOIN SystemTypes ON SystemTypes.[ID] = Sites.SystemTypeID
LEFT JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
LEFT JOIN SiteContractHistory ON SiteContractHistory.EDISID = SiteContracts.EDISID AND SiteContractHistory.ValidTo IS NULL
LEFT JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
LEFT JOIN (
	SELECT Calls.EDISID, Calls.[ID] AS CallID, dbo.udfConcatCallReasonsInstalls(Calls.[ID]) AS LastInstallActivity, UsedStock
	FROM Calls
	JOIN (
		SELECT Sites.EDISID, MAX(CallID) AS CallID, MAX(CASE WHEN GlobalCallReasonTypes.GetFromSystemStock = 1 THEN 1 ELSE 0 END) AS UsedStock
		FROM CallReasons
		JOIN [EDISSQL1\SQL1].ServiceLogger.dbo.CallReasonTypes AS GlobalCallReasonTypes ON GlobalCallReasonTypes.[ID] = CallReasons.ReasonTypeID
		JOIN Calls ON Calls.[ID] = CallReasons.CallID
		JOIN Sites ON Sites.EDISID = Calls.EDISID
		WHERE CategoryID IN (4, 9)
		GROUP BY Sites.EDISID
	) AS LatestInstalls ON LatestInstalls.CallID = Calls.[ID]
) AS Installs ON Installs.EDISID = Sites.EDISID
LEFT JOIN (
			SELECT Sites.EDISID, Contracts.ID AS ContractID, 
					CASE WHEN GETDATE() >= DATEADD(MONTH, -1, DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom)) THEN 'One Month Review'
						 WHEN GETDATE() >= DATEADD(MONTH, -3, DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom)) AND GETDATE() < DATEADD(MONTH, -1, DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom)) THEN 'Three Month Review'
						 WHEN GETDATE() >= DATEADD(YEAR, Contracts.TermYears, SiteContractHistory.ValidFrom) THEN 'Out of Contract'
					ELSE 'In Contract' END AS ContractStatus
			FROM Sites
			LEFT JOIN SiteContracts ON SiteContracts.EDISID = Sites.EDISID
			LEFT JOIN SiteContractHistory ON SiteContractHistory.EDISID = SiteContracts.EDISID AND SiteContractHistory.ValidTo IS NULL
			LEFT JOIN Contracts ON Contracts.[ID] = SiteContracts.ContractID
			WHERE SiteContractHistory.ValidTo IS NULL
) AS ContractStatuses ON ContractStatuses.EDISID = Sites.EDISID AND ContractStatuses.ContractID = Contracts.[ID]
WHERE Hidden = 0 
AND (SystemTypes.[ID] = @SystemTypeID OR @SystemTypeID IS NULL)
AND (SiteContracts.ContractID = @ContractID OR @ContractID IS NULL)
AND ((Sites.Quality = 0 AND @ShowBMS = 1) OR (Sites.Quality = 1 AND @ShowIDraught = 1))
AND ((CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 1 THEN 1 ELSE 0 END = 1 AND @ShowLessThan1YearSites = 1)
OR (CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 1 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 2 THEN 1 ELSE 0 END = 1 AND @ShowBetween1And2YearSites = 1)
OR (CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 2 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 3 THEN 1 ELSE 0 END = 1 AND @ShowBetween2And3YearSites = 1)
OR (CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 3 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 4 THEN 1 ELSE 0 END = 1 AND @ShowBetween3And4YearSites = 1)
OR (CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 4 AND dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) < 5 THEN 1 ELSE 0 END = 1 AND @ShowBetween4And5YearSites = 1)
OR (CASE WHEN dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) >= 5 OR dbo.fnYearsApart(Sites.InstallationDate, GETDATE()) IS NULL THEN 1 ELSE 0 END = 1 AND @ShowMoreThan5YearSites = 1))
AND (([Status] = 1 AND @ShowActiveSites = 1)
OR ([Status] = 2 AND @ShowClosedSites = 1)
OR ([Status] = 10 AND @ShowFOTSites = 1)
OR ([Status] = 3 AND @ShowLegalsSites = 1)
OR ([Status] = 4 AND @ShowNotReportedOnSites = 1)
OR ([Status] = 5 AND @ShowWrittenOffSites = 1)
OR ([Status] = 0 AND @ShowUnknownSites = 1))
AND ((ContractStatuses.ContractStatus = 'In Contract' AND @ShowInContractSites = 1)
OR (ContractStatuses.ContractStatus = 'Three Month Review' AND @ShowThreeMonthReviewSites = 1)
OR (ContractStatuses.ContractStatus = 'One Month Review' AND @ShowOneMonthSites = 1)
OR (ContractStatuses.ContractStatus = 'Out of Contract' AND @ShowOutOfContractSites = 1))

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesByContractFilter] TO PUBLIC
    AS [dbo];

