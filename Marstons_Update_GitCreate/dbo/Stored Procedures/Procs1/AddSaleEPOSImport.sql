CREATE PROCEDURE [dbo].[AddSaleEPOSImport]
(
    @SiteID         VARCHAR(50) = NULL,         -- Must supply either SiteID or
    @EDISID         INTEGER = NULL,             -- EDISID as a site reference
    @ProductAlias   VARCHAR(50),
    @SaleIdent      VARCHAR(255),
    @Date                   DATE,
    @Time                   TIME,
    @Quantity               FLOAT,
    @CheckIdent             BIT = 0,            -- Set to 1 for Quintek Files
    @BackwardsCompatible    BIT = 0,            -- Replicates legacy behaviour
    @AllowDBDuplicates      BIT = 0,
    @AllowFileDuplicates    BIT = 0,
    @AllowOverwrites        BIT = 0,            -- Unsafe to combine with Dupes
    @ID                     INT OUTPUT,
    @ErrorDescription       VARCHAR(1000) = NULL OUTPUT,
    @Transaction            VARCHAR(50) = NULL,
    @Teller                 VARCHAR(50) = NULL,
    @ProductDescription     VARCHAR(50) = NULL
)

AS

SET NOCOUNT ON

DECLARE @IsExternal     INT = 0

DECLARE @MasterDateID   INT
DECLARE @TradingDate    DATETIME
DECLARE @Conflicting    INT = 0
DECLARE @ProductID      INT

-- Ensure we don't have conflicting options, unless we are told to ignore
-- the situation for backwards compatibility purposes.
IF @AllowOverwrites = 1 
    AND @BackwardsCompatible = 0
    AND (@AllowDBDuplicates = 1 OR @AllowFileDuplicates = 1)
BEGIN
    SET @ErrorDescription = 'Duplicates/Overwrites settings conflict'
    RETURN -1
END

-- Calculate TradingDate
SET @TradingDate = 
    CASE WHEN DATEPART(Hour, @Time) < 5 
         THEN DATEADD(Day, -1, @Date) 
         ELSE @Date 
         END

-- If we have a SiteID, look up the EDISID
IF @SiteID IS NOT NULL
BEGIN
    SELECT @EDISID = [EDISID]
    FROM [dbo].[Sites]
    WHERE [SiteID] = @SiteID
END

-- If we couldn't find the Site, abort
IF @EDISID IS NULL
BEGIN
    SET @ErrorDescription = 'Site ID ' + ISNULL(@SiteID, '') 
        + ' could not be found.'
    RETURN -1
END

-- Look up the ProductID
SELECT @ProductID = [ProductID]
FROM [dbo].[ProductAlias]
WHERE UPPER(Alias) = UPPER(@ProductAlias)

-- If we couldn't find the Product, abort
IF @ProductAlias IS NULL
BEGIN
    SET @ErrorDescription = 'Product Alias ' + ISNULL(@ProductAlias, '') 
        + ' could not be found.'
    RETURN -1
END

-- Look up the MasterDateID
SELECT @MasterDateID = [ID]
FROM [dbo].[MasterDates]
WHERE [EDISID] = @EDISID
AND [Date] = @Date

-- If we couldn't find an existing MasterDateID, create one now
IF @MasterDateID IS NULL
BEGIN
    INSERT INTO [dbo].[MasterDates]
    (EDISID, [Date])
    VALUES
    (@EDISID, @Date)

    SET @MasterDateID = SCOPE_IDENTITY()
END

BEGIN TRAN

	IF @AllowDBDuplicates = 0 AND @CheckIdent = 0
	BEGIN
		SELECT @Conflicting = COUNT(*)
		FROM [dbo].[Sales] WITH (UPDLOCK)
		WHERE [EDISID] = @EDISID
		AND UPPER([ProductAlias]) = UPPER(@ProductAlias)
		AND CAST([SaleDate] AS DATE) = @Date
		AND CAST([SaleTime] AS TIME) = @Time
	END
	ELSE IF @AllowDBDuplicates = 0 AND @CheckIdent = 1
	BEGIN
		SELECT @Conflicting = COUNT(*)
		FROM [dbo].[Sales] WITH (UPDLOCK)
		WHERE [EDISID] = @EDISID
		AND UPPER([ProductAlias]) = UPPER(@ProductAlias)
		AND CAST([SaleDate] AS DATE) = @Date
		AND CAST([SaleTime] AS TIME) = @Time
		AND [SaleIdent] = @SaleIdent
	END
	ELSE IF @AllowDBDuplicates = 1
	BEGIN
		SET @Conflicting = 0
	END

	-- If we have any conflicting Sales, abort unless overwrites are enabled
	IF @Conflicting = 0
	BEGIN
	
		INSERT INTO [dbo].[Sales]
		([MasterDateID], [ProductID], [Quantity], [SaleIdent], [SaleTime], 
		 [EDISID], [ProductAlias], [External], [TradingDate], [SaleDate], 
		 [Transaction], [Teller], [ProductDescription])
		VALUES
		(@MasterDateID, @ProductID, @Quantity, @SaleIdent, @Time, 
		 @EDISID, @ProductAlias, @IsExternal, @TradingDate, @Date,
		 @Transaction, @Teller, @ProductDescription)

		SET @ID = @@IDENTITY
		
	END
	ELSE
	BEGIN
		-- Conflicting Sales have been found
		IF @AllowOverwrites = 1
		BEGIN
			IF @Conflicting = 1 OR (@Conflicting >= 1 AND @BackwardsCompatible = 1)
			BEGIN
				SELECT TOP 1 @ID = [ID]
				FROM [Sales]
				WHERE [EDISID] = @EDISID
				AND UPPER([ProductAlias]) = UPPER(@ProductAlias)
				AND CAST([SaleDate] AS DATE) = @Date
				AND CAST([SaleTime] AS TIME) = @Time

				UPDATE [dbo].[Sales]
				SET [Quantity] = @Quantity
				WHERE [EDISID] = @EDISID
				AND UPPER([ProductAlias]) = UPPER(@ProductAlias)
				AND CAST([SaleDate] AS DATE) = @Date
				AND CAST([SaleTime] AS TIME) = @Time
			END
			ELSE IF @Conflicting >= 1 AND @BackwardsCompatible = 0
			BEGIN
				SET @ErrorDescription = 'Cannot overwrite multiple matching sales'
				ROLLBACK TRAN
				RETURN -1
			END
		END
		ELSE IF @CheckIdent = 0 AND @AllowFileDuplicates = 1
		BEGIN
			-- If CheckIdent is disabled, the Ident will contain File information
			-- Check whether any duplicates are from different file. If so, deny it
			DECLARE @ConflictingDuplicate INT = 0

			SELECT @ConflictingDuplicate = COUNT([ID])
			FROM [Sales]
			WHERE [EDISID] = @EDISID
			AND UPPER([ProductAlias]) = UPPER(@ProductAlias)
			AND CAST([SaleDate] AS DATE) = @Date
			AND CAST([SaleTime] AS TIME) = @Time
			AND [SaleIdent] <> @SaleIdent

			IF @ConflictingDuplicate = 0
			BEGIN
				INSERT INTO [dbo].[Sales]
				([MasterDateID], [ProductID], [Quantity], [SaleIdent], [SaleTime], 
				 [EDISID], [ProductAlias], [External], [TradingDate], [SaleDate],
				 [Transaction], [Teller], [ProductDescription])
				VALUES
				(@MasterDateID, @ProductID, @Quantity, @SaleIdent, @Time, 
				 @EDISID, @ProductAlias, @IsExternal, @TradingDate, @Date,
				 @Transaction, @Teller, @ProductDescription)

				SET @ID = @@IDENTITY
			END
			ELSE
			BEGIN
				SET @ErrorDescription = 'Duplicate sale found in database'
				ROLLBACK TRAN
				RETURN -1
			END
		END
		ELSE
		BEGIN
			SET @ErrorDescription = 'Duplicate sale found in database'
			ROLLBACK TRAN
			RETURN -1
		END
	END
COMMIT TRAN

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddSaleEPOSImport] TO PUBLIC
    AS [dbo];

