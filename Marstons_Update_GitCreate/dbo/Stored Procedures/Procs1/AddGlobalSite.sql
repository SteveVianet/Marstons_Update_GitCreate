CREATE PROCEDURE [dbo].[AddGlobalSite]
(
	@EDISID		INTEGER,
	@SiteID		VARCHAR(50),
	@StartDate		DATETIME = NULL,
	@GlobalEDISID		INTEGER OUTPUT
)
AS

BEGIN TRANSACTION

/*
DECLARE @Owner		VARCHAR(50)
DECLARE @OwnerID		INTEGER
DECLARE @Area		VARCHAR(50)
DECLARE @AreaID		INTEGER
DECLARE @SiteGroup		VARCHAR(50)
DECLARE @SiteGroupID	INTEGER

SET NOCOUNT ON

SET @Owner = NULL
SET @Area = NULL
SET @SiteGroup = NULL

Table data to be copied across:

	1. Owner
	2. Area
	3. SiteGroup
	4. Site
	5. SiteGroupSites
	6. PumpSetup
	7. EquipmentItems
	8. MasterDates
	9. DLData
	10. WaterStack
	11 CleaningStack
	12. DispenseConditions
	13. EquipmentReadings
	14. SiteComments
	15. Delivery
	16. Stock
	17. Sales
  	18. SiteProductSpecifications
	19. SiteRankings
	20. SiteProductTies
	21. DispenseActions


--Owner
SELECT @Owner = GlobalOwners.[Name]
FROM [SQL2\SQL2].[Global].dbo.Owners AS GlobalOwners
JOIN Owners ON Owners.[Name] = GlobalOwners.[Name]
JOIN Sites On Sites.OwnerID = Owners.[ID]
WHERE EDISID = @EDISID

IF @Owner IS NULL
BEGIN
	INSERT INTO [SQL2\SQL2].[Global].dbo.Owners
	([Name], Address1, Address2, Address3, Address4, Postcode, ContactName)
	SELECT Owners.[Name], 
	        	Owners.Address1,
		Owners.Address2,
		Owners.Address3,
		Owners.Address4,
		Owners.Postcode,
		Owners.ContactName
	FROM Owners
	JOIN Sites ON Sites.OwnerID = Owners.[ID]
	WHERE EDISID = @EDISID

	--SET @OwnerID = @@IDENTITY

	SELECT @OwnerID = GlobalOwners.[ID]
	FROM [SQL2\SQL2].[Global].dbo.Owners AS GlobalOwners
	JOIN Owners ON Owners.[Name] = GlobalOwners.[Name]
	JOIN Sites ON Sites.OwnerID = Owners.[ID]
	WHERE EDISID = @EDISID

END
ELSE
BEGIN
	SELECT @OwnerID = [ID]
	FROM [SQL2\SQL2].[Global].dbo.Owners AS Owners
	WHERE [Name] = @Owner
END

SELECT @Area = GlobalAreas.[Description]
FROM [SQL2\SQL2].[Global].dbo.Areas AS GlobalAreas
JOIN Areas ON Areas.[Description] = GlobalAreas.[Description]
JOIN Sites ON Sites.AreaID = Areas.[ID]
WHERE EDISID = @EDISID

--Area
IF @Area IS NULL
BEGIN
	INSERT INTO [SQL2\SQL2].[Global].dbo.Areas
	([Description])
	SELECT [Description]
	FROM Areas
	JOIN Sites ON Sites.AreaID = Areas.[ID]
	WHERE EDISID = @EDISID

	SELECT @AreaID = GlobalAreas.[ID]
	FROM [SQL2\SQL2].[Global].dbo.Areas AS GlobalAreas
	JOIN Areas ON Areas.[Description] = GlobalAreas.[Description]
	JOIN Sites ON Sites.AreaID = Areas.[ID]
	WHERE Sites.EDISID = @EDISID
END
ELSE
BEGIN
	SELECT @AreaID = [ID]
	FROM [SQL2\SQL2].[Global].dbo.Areas AS Areas
	WHERE [Description] = @Area
END

--SiteGroup
SELECT @SiteGroupID = SiteGroups.[ID]
FROM SiteGroups
JOIN Sites ON Sites.SiteGroupID = SiteGroups.[ID]
WHERE EDISID = @EDISID

IF @SiteGroupID IS NOT NULL
BEGIN
	SET @SiteGroupID = NULL	

	SELECT @SiteGroupID = GlobalSiteGroups.[ID]
	FROM [SQL2\SQL2].[Global].dbo.SiteGroups AS GlobalSiteGroups
	JOIN SiteGroups ON SiteGroups.[Description] = GlobalSiteGroups.[Description]
	JOIN Sites ON Sites.SiteGroupID = SiteGroups.[ID]
	WHERE Sites.EDISID = @EDISID

	IF @SiteGroupID IS NULL
	BEGIN
		INSERT INTO [SQL2\SQL2].[Global].dbo.SiteGroups
		([Description], TypeID)
		SELECT [Description],
			 TypeID
		FROM SiteGroups
		JOIN Sites ON Sites.SiteGroupID = SiteGroups.[ID]
		WHERE Sites.EDISID = @EDISID

		SELECT @SiteGroupID = GlobalSiteGroups.[ID]
		FROM [SQL2\SQL2].[Global].dbo.SiteGroups AS GlobalSiteGroups
		JOIN SiteGroups ON SiteGroups.[Description] = GlobalSiteGroups.[Description]
		JOIN Sites ON Sites.SiteGroupID = SiteGroups.[ID]
		WHERE Sites.EDISID = @EDISID
		
	END

END

--Site
INSERT INTO [SQL2\SQL2].[Global].dbo.Sites
(OwnerID, SiteID, [Name], TenantName, Address1, Address2, Address3, Address4, PostCode, SiteTelNo, EDISTelNo, EDISPassword, SiteOnline, 
SerialNo, Classification, Budget, Region, SiteClosed, Version, LastDownload, ModemTypeID, Comment, BDMComment, IsVRSMember, Hidden, 
SiteUser, InternalComment, SystemTypeID, AreaID, SiteGroupID, VRSOwner, CommunicationProviderID, OwnershipStatus, AltSiteTelNo, Quality, 
InstallationDate, GlobalEDISID)
SELECT @OwnerID,
	SiteID,
	[Name],
	TenantName,
	Address1,
	Address2,
	Address3,
	Address4,
	PostCode,
	SiteTelNo,
	EDISTelNo,
	EDISPassword,
	SiteOnline,
	SerialNo,
	Classification,
	Budget,
	1,
	SiteClosed,
	Version,
	LastDownload,
	ModemTypeID,
	Comment,
	BDMComment,
	IsVRSMember,
	Hidden,
	SiteUser,
	InternalComment,
	SystemTypeID,
	@AreaID,
	@SiteGroupID,
	VRSOwner,
	CommunicationProviderID,
	OwnershipStatus,
	AltSiteTelNo,
	Quality,
	InstallationDate,
	GlobalEDISID
FROM Sites
WHERE EDISID = @EDISID

SELECT @GlobalEDISID = EDISID
FROM [SQL2\SQL2].[Global].dbo.Sites
WHERE SiteID = @SiteID
--SET @NewEDISID = @@IDENTITY

UPDATE Sites
SET GlobalEDISID = @GlobalEDISID
WHERE EDISID = @EDISID

--SiteGroupSites
INSERT INTO [SQL2\SQL2].[Global].dbo.SiteGroupSites
(SiteGroupID, EDISID, IsPrimary)
SELECT @SiteGroupID,
	 GlobalSites.EDISID,
	 IsPrimary
FROM SiteGroupSites
JOIN Sites ON Sites.SiteGroupID = SiteGroupSites.SiteGroupID AND Sites.EDISID = SiteGroupSites.EDISID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
WHERE Sites.EDISID = @EDISID

--PumpSetup
INSERT INTO [SQL2\SQL2].[Global].dbo.PumpSetup
(EDISID, Pump, ProductID, LocationID, ValidFrom, ValidTo, InUse, BarPosition)
SELECT @GlobalEDISID,
       Pump,
       Products.GlobalID,
       Locations.GlobalID,
       ValidFrom,
       ValidTo,
       InUse,
       BarPosition
FROM PumpSetup
JOIN Products ON PumpSetup.ProductID = Products.[ID]
JOIN Locations ON Locations.[ID] = PumpSetup.LocationID
WHERE EDISID = @EDISID
--AND (ValidFrom >= @StartDate OR @StartDate IS NULL)

--EquipmentItems
INSERT INTO [SQL2\SQL2].[Global].dbo.EquipmentItems
(EDISID, InputID, LocationID, EquipmentTypeID, [Description], ValueSpecification, ValueTolerance)
SELECT Sites.GlobalEDISID,
       InputID,
       Locations.GlobalID,
       EquipmentTypeID,
       EquipmentItems.[Description],
       ValueSpecification,
       ValueTolerance
FROM EquipmentItems
JOIN Sites ON Sites.EDISID = EquipmentItems.EDISID
JOIN Locations ON Locations.[ID] = EquipmentItems.LocationID
WHERE EquipmentItems.EDISID = @EDISID

--MasterDates
INSERT INTO [SQL2\SQL2].[Global].dbo.MasterDates
(EDISID, [Date])
SELECT GlobalSites.EDISID,
	 [Date]
FROM MasterDates
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
WHERE (MasterDates.[Date] BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--DLData
INSERT INTO [SQL2\SQL2].[Global].dbo.DLData
(DownloadID, Pump, Shift, Product, Quantity)
SELECT GlobalMasterDates.[ID], 
       Pump,
       Shift,
       Products.GlobalID,
       Quantity
FROM DLData
JOIN MasterDates ON MasterDates.[ID] = DLData.DownloadID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN Products ON Products.[ID] = DLData.Product
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
JOIN [SQL2\SQL2].[Global].dbo.MasterDates AS GlobalMasterDates ON GlobalMasterDates.EDISID = Sites.GlobalEDISID AND 
GlobalMasterDates.[Date] = MasterDates.[Date]
WHERE (DATEADD(hour, DATEPART(hour, Shift-1), CAST(CONVERT(VARCHAR(10), MasterDates.[Date], 12) AS DATETIME)) BETWEEN @StartDate AND 
GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--WaterStack
INSERT INTO [SQL2\SQL2].[Global].dbo.WaterStack
(WaterID, [Time], Line, Volume)
SELECT GlobalMasterDates.[ID],
       [Time],
       Line,
       Volume
FROM WaterStack
JOIN MasterDates ON MasterDates.[ID] = WaterStack.WaterID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
JOIN [SQL2\SQL2].[Global].dbo.MasterDates AS GlobalMasterDates ON GlobalMasterDates.EDISID = Sites.GlobalEDISID AND 
GlobalMasterDates.[Date] = MasterDates.[Date]
WHERE (DATEADD(Second, DATEPART(Second, WaterStack.Time), DATEADD(Minute, DATEPART(Minute, WaterStack.Time), DATEADD(Hour, DATEPART(Hour, 
WaterStack.Time), CAST(CONVERT(VARCHAR(10), MasterDates.[Date], 12) AS DATETIME)))) BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--CleaningStack
INSERT INTO [SQL2\SQL2].[Global].dbo.CleaningStack
(CleaningID, [Time], Line, Volume)
SELECT GlobalMasterDates.[ID],
       [Time],
       Line,
       Volume
FROM CleaningStack
JOIN MasterDates ON MasterDates.[ID] = CleaningStack.CleaningID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
JOIN [SQL2\SQL2].[Global].dbo.MasterDates AS GlobalMasterDates ON GlobalMasterDates.EDISID = Sites.GlobalEDISID AND 
GlobalMasterDates.[Date] = MasterDates.[Date]
WHERE (DATEADD(Second, DATEPART(Second, CleaningStack.Time), DATEADD(Minute, DATEPART(Minute, CleaningStack.Time), DATEADD(Hour, 
DATEPART(Hour, CleaningStack.Time), CAST(CONVERT(VARCHAR(10), MasterDates.[Date], 12) AS DATETIME)))) BETWEEN @StartDate AND GETDATE() OR 
@StartDate IS NULL)
AND Sites.EDISID = @EDISID

--DispenseConditions
INSERT INTO [SQL2\SQL2].[Global].dbo.DispenseConditions
(MasterDateID, Pump, StartTime, Duration, AverageTemperature, MinimumTemperature, ProductID, LiquidType, OriginalLiquidType, OffsetApplied, 
MaximumTemperature, MinimumConductivity, AverageConductivity, MaximumConductivity, Pints)
SELECT GlobalMasterDates.[ID],
       Pump,
       StartTime,
       Duration,
       AverageTemperature,
       MinimumTemperature,
       Products.GlobalID,
       LiquidType,
       OriginalLiquidType,
       OffsetApplied,
       MaximumTemperature,
       MinimumConductivity,
       AverageConductivity,
       MaximumConductivity,
       Pints
FROM DispenseConditions
JOIN MasterDates ON MasterDates.[ID] = DispenseConditions.MasterDateID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
JOIN Products ON Products.[ID] = DispenseConditions.ProductID
JOIN [SQL2\SQL2].[Global].dbo.MasterDates AS GlobalMasterDates ON GlobalMasterDates.EDISID = Sites.GlobalEDISID AND 
GlobalMasterDates.[Date] = MasterDates.[Date]
WHERE (DATEADD(Second, DATEPART(Second, DispenseConditions.StartTime), DATEADD(Minute, DATEPART(Minute, DispenseConditions.StartTime), 
DATEADD(Hour, DATEPART(Hour, DispenseConditions.StartTime), CAST(CONVERT(VARCHAR(10), MasterDates.[Date], 12) AS DATETIME)))) BETWEEN 
@StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--EquipmentReadings
INSERT INTO [SQL2\SQL2].[Global].dbo.EquipmentReadings
(EDISID, InputID, LogDate, TradingDate, LocationID, EquipmentTypeID, Value)
SELECT Sites.GlobalEDISID,
	  InputID,
	  LogDate,
	  TradingDate,
	  Locations.GlobalID,
	  EquipmentTypeID,
	  Value
FROM EquipmentReadings
JOIN Sites ON Sites.EDISID = EquipmentReadings.EDISID
JOIN Locations ON Locations.[ID] = EquipmentReadings.LocationID
WHERE (LogDate BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--SiteComments
INSERT INTO [SQL2\SQL2].[Global].dbo.SiteComments
(EDISID, Type, [Date], HeadingType, [Text], AddedOn, AddedBy, EditedOn, EditedBy, Deleted)
SELECT GlobalSites.EDISID,
       	 Type,
       	 [Date],
      	  HeadingType,
       	 [Text],
       	 AddedOn,
       	 AddedBy,
       	 EditedOn,
       	 EditedBy,
       	 Deleted
FROM SiteComments
JOIN Sites ON Sites.EDISID = SiteComments.EDISID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
WHERE (SiteComments.[Date] BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--Delivery
INSERT INTO [SQL2\SQL2].[Global].dbo.Delivery
(DeliveryID, Product, Quantity, DeliveryIdent)
SELECT GlobalMasterDates.[ID],
	 Products.GlobalID,
	 Quantity,
	 DeliveryIdent
FROM Delivery
JOIN MasterDates ON MasterDates.[ID] = Delivery.DeliveryID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN Products ON Products.[ID] = Delivery.Product
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
JOIN [SQL2\SQL2].[Global].dbo.MasterDates AS GlobalMasterDates ON GlobalMasterDates.EDISID = Sites.GlobalEDISID AND 
GlobalMasterDates.[Date] = MasterDates.[Date]
WHERE (MasterDates.[Date] BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--Stock
INSERT INTO [SQL2\SQL2].[Global].dbo.Stock
(MasterDateID, ProductID, Quantity, [Hour], BeforeDelivery)
SELECT GlobalMasterDates.[ID],
	 Products.GlobalID,
	 Quantity,
	 [Hour],
	 BeforeDelivery
FROM Stock
JOIN MasterDates ON MasterDates.[ID] = Stock.MasterDateID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN Products ON Products.[ID] = Stock.ProductID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
JOIN [SQL2\SQL2].[Global].dbo.MasterDates AS GlobalMasterDates ON GlobalMasterDates.EDISID = Sites.GlobalEDISID AND 
GlobalMasterDates.[Date] = MasterDates.[Date]
WHERE (MasterDates.[Date] BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--Sales
INSERT INTO [SQL2\SQL2].[Global].dbo.Sales
(MasterDateID, ProductID, Quantity, SaleIdent, SaleTime, ProductAlias, External, TradingDate, SaleDate, EDISID)
SELECT GlobalMasterDates.[ID],
	 Products.GlobalID,
	 Quantity,
              SaleIdent,
	 SaleTime,
	ProductAlias,
	External,
	TradingDate,
	SaleDate,
	Sales.EDISID	
FROM Sales
JOIN MasterDates ON MasterDates.[ID] = Sales.MasterDateID
JOIN Sites ON Sites.EDISID = MasterDates.EDISID
JOIN Products ON Products.[ID] = Sales.ProductID
JOIN [SQL2\SQL2].[Global].dbo.Sites AS GlobalSites ON GlobalSites.EDISID = Sites.GlobalEDISID
JOIN [SQL2\SQL2].[Global].dbo.MasterDates AS GlobalMasterDates ON GlobalMasterDates.EDISID = Sites.GlobalEDISID AND 
GlobalMasterDates.[Date] = MasterDates.[Date]
WHERE (MasterDates.[Date] BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

--SiteProductSpecifications
INSERT INTO [SQL2\SQL2].[Global].dbo.SiteProductSpecifications
(EDISID, ProductID, CleanDaysBeforeAmber, CleanDaysBeforeRed, TempSpec, TempTolerance, FlowSpec, FlowTolerance)
SELECT Sites.GlobalEDISID,
	 Products.GlobalID,
              CleanDaysBeforeAmber,
              CleanDaysBeforeRed,
              TempSpec,
              TempTolerance,
              FlowSpec,
              FlowTolerance
FROM SiteProductSpecifications
JOIN Sites ON Sites.EDISID = SiteProductSpecifications.EDISID
JOIN Products ON Products.[ID] = SiteProductSpecifications.ProductID
WHERE Sites.EDISID = @EDISID

--SiteRankings
INSERT INTO [SQL2\SQL2].[Global].dbo.SiteRankings
(EDISID, ValidFrom, ValidTo, RankingTypeID, ManualText, AssignedBy, RankingCategoryID)
SELECT Sites.GlobalEDISID,
       ValidFrom,
       ValidTo,
       RankingTypeID,
       ManualText,
       AssignedBy,
       RankingCategoryID
FROM SiteRankings
JOIN Sites ON Sites.EDISID = SiteRankings.EDISID
WHERE Sites.EDISID = @EDISID
AND ValidFrom >= @StartDate 
AND ValidTo <= GETDATE()

--SiteProductTies
INSERT INTO [SQL2\SQL2].[Global].dbo.SiteProductTies
(EDISID, ProductID, Tied)
SELECT Sites.GlobalEDISID,
       Products.GlobalID,
       SiteProductTies.Tied
FROM SiteProductTies
JOIN Sites ON Sites.EDISID = SiteProductTies.EDISID
JOIN Products ON Products.[ID] = SiteProductTies.ProductID
WHERE Sites.EDISID = @EDISID

--DispenseActions
INSERT INTO [SQL2\SQL2].[Global].dbo.DispenseActions
(EDISID, StartTime, TradingDay, Pump, Location, Product, Duration, AverageTemperature, MinimumTemperature, MaximumTemperature, LiquidType, OriginalLiquidType, IFMLiquidType, 
AverageConductivity, MinimumConductivity, MaximumConductivity, Pints, PintsBackup, EstimatedDrinks)
SELECT Sites.GlobalEDISID,
       StartTime,       
       TradingDay,
       Pump,
       Locations.GlobalID,
       Products.GlobalID,
       Duration,
       AverageTemperature,
       MinimumTemperature,
       MaximumTemperature,
       LiquidType,
       OriginalLiquidType,
       IFMLiquidType,
       AverageConductivity,
       MinimumConductivity,
       MaximumConductivity,
       Pints,
       PintsBackup,
       EstimatedDrinks
FROM DispenseActions
JOIN Sites ON Sites.EDISID = DispenseActions.EDISID
JOIN Products ON Products.[ID] = DispenseActions.Product
JOIN Locations ON Locations.ID = DispenseActions.Location
WHERE (DATEADD(dd, 0, DATEDIFF(dd, 0, StartTime)) BETWEEN @StartDate AND GETDATE() OR @StartDate IS NULL)
AND Sites.EDISID = @EDISID

*/
COMMIT


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddGlobalSite] TO PUBLIC
    AS [dbo];

