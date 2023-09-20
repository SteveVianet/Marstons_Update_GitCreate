CREATE PROCEDURE [neo].[GetLatestFont]
(
	@EDISID		                INTEGER,
	@Pump		                INTEGER = NULL,
	@Date		                DATETIME,
	@ShowNotInUse		        BIT = 1
)

AS

SET NOCOUNT ON

BEGIN
	SELECT ps.Pump,
		 ProductID,
		 LocationID,
		 ps.InUse,
		 BarPosition,
		 ps.ValidFrom,
		 ValidTo,
		 Products.Description

	FROM dbo.PumpSetup AS ps 
	JOIN dbo.Products ON ps.ProductID = dbo.Products.ID
	JOIN (SELECT Pump, MAX(ValidFrom) AS ValidFrom
		  FROM PumpSetup
		  WHERE @EDISID = EDISID
		  GROUP BY Pump) AS mDate ON mDate.Pump = ps.Pump
	WHERE (ps.Pump = @Pump OR @Pump IS NULL)
	AND ps.EDISID = @EDISID
	AND ps.ValidFrom <= @Date
	AND (ValidTo >= @Date OR ValidTo IS NULL)
	AND ps.ValidFrom  = mDate.ValidFrom
	AND (ps.InUse = 1 OR @ShowNotInUse = 1)
GROUP BY ps.Pump, ProductID, LocationID, ps.InUse, BarPosition, ps.ValidFrom, ValidTo, Products.Description
	ORDER BY ps.Pump
END

GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetLatestFont] TO PUBLIC
    AS [dbo];

