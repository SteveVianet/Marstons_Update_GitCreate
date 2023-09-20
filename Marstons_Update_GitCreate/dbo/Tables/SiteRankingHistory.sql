CREATE TABLE [dbo].[SiteRankingHistory] (
    [EDISID]                 INT      NOT NULL,
    [TradingDay]             DATETIME NOT NULL,
    [SiteEquipmentAmbientTL] INT      NULL,
    [SiteEquipmentRecircTL]  INT      NULL,
    [SiteCleaningTL]         INT      NULL,
    [SiteCleaningKegTL]      INT      NULL,
    [SiteCleaningCaskTL]     INT      NULL,
    [SiteThroughputTL]       INT      NULL,
    [SiteThroughputKegTL]    INT      NULL,
    [SiteThroughputCaskTL]   INT      NULL,
    [SiteTemperatureTL]      INT      NULL,
    [SiteTemperatureKegTL]   INT      NULL,
    [SiteTemperatureCaskTL]  INT      NULL,
    [SitePouringYieldTL]     INT      NULL,
    [SitePouringYieldKegTL]  INT      NULL,
    [SitePouringYieldCaskTL] INT      NULL,
    [SiteTillYieldTL]        INT      NULL,
    [SiteTillYieldKegTL]     INT      NULL,
    [SiteTillYieldCaskTL]    INT      NULL,
    CONSTRAINT [PK_SiteRankingHistory] PRIMARY KEY CLUSTERED ([EDISID] ASC, [TradingDay] ASC)
);

