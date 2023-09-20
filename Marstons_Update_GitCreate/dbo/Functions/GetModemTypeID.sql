CREATE FUNCTION [dbo].[GetModemTypeID]
(
	@Prefix		VARCHAR(512)
)
RETURNS INT
AS
BEGIN
	SET @Prefix = REPLACE(@Prefix, ' ', '')
	SET @Prefix = REPLACE(@Prefix, '-', '')

	IF @Prefix = ''
	BEGIN
		RETURN 8
	END

	-- INTERNET
	IF CHARINDEX('.', @Prefix) > 0
	BEGIN
		RETURN 6
	END

	-- NETWORK
	IF LEFT(@Prefix, 2) = '07'
	BEGIN
		DECLARE @ModemTypeID INT = 9
	
		SELECT @ModemTypeID = [ModemTypeID]
		FROM [EDISSQL1\SQL1].[ServiceLogger].[dbo].[NetworkPrefixes]
		WHERE [Prefix] = SUBSTRING(@Prefix, 2, 5)

		RETURN @ModemTypeID
	END

	-- LANDLINE
	IF LEFT(@Prefix, 1) = '0'
	BEGIN
		IF LEFT(@Prefix, 3) = '001'
		BEGIN
			-- CINGULAR
			IF SUBSTRING(@Prefix, 4, 3) = '571' OR SUBSTRING(@Prefix, 4, 3) = '412'
			BEGIN
				RETURN 7
			END
		END
		
		RETURN 1
	END
	
	-- Default to None
	RETURN 9

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetModemTypeID] TO PUBLIC
    AS [dbo];

