CREATE FUNCTION [dbo].[fnConvertSiteDispenseVolume]
(
      @EDISID             INT,
      @Volume			  FLOAT
)

RETURNS FLOAT

AS

BEGIN
      DECLARE @ConvertedVolume	FLOAT
      DECLARE @Unit				VARCHAR(100)

      SELECT @Unit = UPPER(CAST(SiteProperties.Value AS VARCHAR))
      FROM SiteProperties
      JOIN Properties ON Properties.[ID] = SiteProperties.PropertyID
      WHERE EDISID = @EDISID
      AND Properties.[Name] = 'Small Unit'

      IF @Unit IS NULL
      BEGIN
            SELECT @ConvertedVolume = @Volume

      END

      ELSE IF @Unit = 'US PINTS'
      BEGIN
            SELECT @ConvertedVolume = @Volume * 1.20095
            
      END

      ELSE IF @Unit = '50 CENTILITRES'
      BEGIN
			SELECT @ConvertedVolume = @Volume * (56.8261485 / 50)

      END

      ELSE IF @Unit = 'US FLOZ'
      BEGIN
            SELECT @ConvertedVolume = @Volume * 19.2152

      END
		
	  ELSE
	  BEGIN
			SELECT @ConvertedVolume = @Volume
			
	  END
	  
      RETURN @ConvertedVolume

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnConvertSiteDispenseVolume] TO PUBLIC
    AS [dbo];

