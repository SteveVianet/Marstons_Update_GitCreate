CREATE PROCEDURE [neo].[GetHighestFontNumber]
(
	@EDISID	int,
	@Date DATETIME
)

AS

SET NOCOUNT ON

Select MAX(Pump) as MaxFont
From PumpSetup
Where EDISID = @EDISID
AND (ValidFrom <= @Date and (ValidTo is null or ValidTo >= @Date))
GO
GRANT EXECUTE
    ON OBJECT::[neo].[GetHighestFontNumber] TO PUBLIC
    AS [dbo];

