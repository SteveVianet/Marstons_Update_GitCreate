

CREATE PROCEDURE [dbo].[ProductVariancesStaging]
/*
Purpose     Process Product variances to staging table ready to lift and shift to Azure
                 Originally this was query 07 and being called from the PerPour container in the SSIS job
                but it took such a long time it makes sense to process it at source

                Dependent on dbo.PeriodCacheVarianceInternalStaging so make sure that exists

By          Nigel Bell
On         21 August 2018

Update     Changed to use cte per original query as this variant does not return correct results
By              Nigel Bell
On            26 September 2018

Update     Redesigned to remove reliance on OUTER APPLY as it was running for 3 days without completing!
By              Nigel Bell
On            1 October 2018

Update      Removed ISNULL from trafficLightStatus
By              Nigel Bell
On            4 October 2018

Update	Replaced '2017-01-02 00:00:00.000' with DATEADD(yy,-1,DATEADD(yy,DATEDIFF(yy,0,GETDATE()),1))
By            Nigel Bell
On           15 October 2018

--*/
(
@OrganisationID INT = 20
)

AS
BEGIN
SET NOCOUNT ON
SET DATEFIRST 1

--Empty staging table
TRUNCATE TABLE dbo.PeriodCacheVarianceInternalStaging


--Get a list of week commencing dates to @DateTable table variable
DECLARE @DateTable TABLE ( WCDate DATETIME )
DECLARE @StartDate DATETIME
DECLARE @CurrentDate DATETIME

SET @StartDate = '01/01/2017'

--Replace the 2 below with whichever day of the week you are looking for (1=Sunday, 2=Monday, .... 7=Saturday)
SET @CurrentDate = DATEADD( dd, 1 - DATEPART( dw, @StartDate ), @StartDate )

IF @CurrentDate < @StartDate
BEGIN
SET @CurrentDate = DATEADD( dd, 7, @CurrentDate )
END

WHILE @CurrentDate <= DATEADD(wk, DATEDIFF(wk, 1, GETDATE()), 0)--most recent Monday
BEGIN
    INSERT INTO @DateTable
    SELECT @CurrentDate
    SET @CurrentDate = DATEADD( dd, 7, @CurrentDate )
END


--Get RAG status by site by week
;WITH cteRAG (WCDate,EDISID, trafficLightStatus)
AS
(
SELECT
    d.WCDate,
    r.EDISID,
    r.trafficLightStatus
FROM @DateTable d
LEFT JOIN 
    (
        SELECT  
            sr.EDISID, 
            srt.Name AS trafficLightStatus, 
            DATEADD(DD, 1 - DATEPART(DW, sr.ValidFrom), sr.ValidFrom) as ValidFromWc, 
            DATEADD(DD, 1 - DATEPART(DW, sr.ValidTo), sr.ValidTo) as ValidToWc
       FROM  dbo.SiteRankings sr
       INNER JOIN dbo.SiteRankingTypes srt ON sr.RankingTypeID = srt.ID
       WHERE 
            RankingCategoryID = 1 
            AND (sr.ValidFrom >= '2017-01-01 00:00:00.000' OR sr.ValidTo IS NULL)  
            AND DATEDIFF(D,(DATEADD(DD, 1 - DATEPART(DW, sr.ValidFrom), sr.ValidFrom) ),(DATEADD(DD, 1 - DATEPART(DW, sr.ValidTo), sr.ValidTo)))=7 --ensure a full weeks data
 ) AS r ON r.ValidFromWc >= d.WCDate AND r.ValidToWc <= DATEADD(d,7,d.WCDate)
)
--Results query
INSERT INTO dbo.PeriodCacheVarianceInternalStaging(
                                                                                    WeekCommencing,
                                                                                    OrganisationID,
                                                                                    SiteID,
                                                                                    StockDate,
                                                                                    Stock,
                                                                                    Delivered,
                                                                                    Dispensed,
                                                                                    StockAdjustedDispensed,
                                                                                    Variance,
                                                                                    DeliveredBeforeStocktake,
                                                                                    DeliveredAfterStocktake,
                                                                                    StockAdjustedDelivered,
                                                                                    StockAdjustedVariance,
                                                                                    DispensedMinusFive,
                                                                                    StockAdjustedDispenseMinusFive,
                                                                                    varianceMinusFive,
                                                                                    stockAdjustedVarianceMinusFive,
                                                                                    trafficLightStatus,
                                                                                    [DATE],
                                                                                    OldWorldProductId,
                                                                                    IsTied
                                                                                    )
SELECT  
                pc.WeekCommencing as [interval],
                @OrganisationID AS OrganisationID,
                pc.EDISID AS SiteID,
                /*
                '' AS ProductName,
                '' as SiteName,
                0 AS       neoProductId,
                0 AS CategoryID,
                'None' AS ContainerType,
                'None' CategoryDescription,
                null as ThresholdReferenceData,
                --*/
                pc.StockDate,
                pc.Stock,
                --null as DeliveredDate,
                pc.Delivered,
                pc.Dispensed,
                pc.StockAdjustedDispensed,
                pc.Variance,
                pc.DeliveredBeforeStock as DeliveredBeforeStocktake,
                pc.DeliveredAfterStock as DeliveredAfterStocktake,
                pc.StockAdjustedDelivered,
                pc.StockAdjustedVariance,
                pc.Dispensed * 0.95 AS DispensedMinusFive,
                pc.StockAdjustedDispensed * 0.95 as StockAdjustedDispenseMinusFive,
                pc.Delivered - (pc.StockAdjustedDispensed * 0.95) as varianceMinusFive,
                pc.StockAdjustedDelivered - (pc.StockAdjustedDispensed * 0.95) as stockAdjustedVarianceMinusFive,
                r.trafficLightStatus,
                CAST(pc.WeekCommencing as DATE) as 'Date',
                pc.ProductID as OldWorldProductId,
                ISNULL(pc.IsTied, 0) AS IsTied
FROM   dbo.PeriodCacheVarianceInternal pc
--INNER JOIN dbo.Sites s ON pc.EDISID = s.EDISID
--INNER JOIN dbo.Products p ON pc.ProductID = p.ID
--LEFT JOIN dbo.SiteRankings sr ON s.EDISID = sr.EDISID AND pc.WeekCommencing >= sr.ValidFrom AND pc.WeekCommencing <= sr.ValidTo AND sr.RankingCategoryID = 1
--LEFT JOIN dbo.SiteRankingTypes srt ON sr.RankingTypeID = srt.ID
LEFT JOIN cteRAG r ON pc.EDISID = r.EDISID AND pc.WeekCommencing = r.WCDate
/*
OUTER APPLY 
(
                SELECT TOP 1 *
                FROM cte_rankings cter
                WHERE pc.EDISID = cter.EDISID AND  pc.WeekCommencing >= cter.ValidFromWc AND  pc.WeekCommencing <= cter.ValidToWc
                ORDER BY cter.RankResult DESC
) Ranks
--*/
WHERE 
	pc.WeekCommencing >= DATEADD(yy,-1,DATEADD(yy,DATEDIFF(yy,0,GETDATE()),1))  --First monday of 2017
	AND 
	pc.WeekCommencing < DATEADD(wk, DATEDIFF(wk, 1, GETDATE()), 0)  --Previous Monday replaces hard-coded '2018-06-04'
END
