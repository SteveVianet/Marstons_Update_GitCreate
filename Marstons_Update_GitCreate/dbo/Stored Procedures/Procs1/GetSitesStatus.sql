CREATE PROCEDURE [dbo].[GetSitesStatus]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Company AS VARCHAR(50)

	SELECT @Company = c.PropertyValue
	FROM Configuration AS c
	WHERE c.PropertyName = 'Company Name'

	DECLARE @SystemType As TABLE
	(
		SystemTypeID INT,
		Frequency VARCHAR(20)
	)

	INSERT INTO @SystemType (SystemTypeID, Frequency)
	VALUES (1, 'Weekly'), --EDIS 2
		(2, 'Weekly'), -- edisBOX
		(3, 'Weekly'), -- Cardiff
		(5, 'Weekly'), -- EDIS 3
		(6, '15 Min'), -- Kunick
		(7, '15 Min'), -- Starway
		(8, 'Hourly'), -- ComTech
		(9, 'Unknown'), -- None
		(10, 'Hourly') -- Gateway 3


	DECLARE @GPRSPropertyValue INT

	SELECT @GPRSPropertyValue = p.ID
	FROM Properties AS p
	WHERE p.Name = 'GPRSInterval'

	IF @GPRSPropertyValue IS NOT NULL 
	BEGIN
		SELECT 
			@Company AS Company,
			s.SiteID,
			s.Name,
			s.PostCode,
			s.LastDownload,
			CASE 
				WHEN sp.Value IS NULL THEN st.Frequency
				WHEN sp.Value = 15 THEN '15 Min'
				WHEN sp.Value = 30 THEN '30 Min'
				WHEN sp.Value = 60 THEN 'Hourly'
			END AS Frequency		
			FROM Sites AS s
			LEFT JOIN @SystemType AS st
				ON st.SystemTypeID = s.SystemTypeID
			-- Get sites with a manually adjusted Download Frequency
			LEFT JOIN (
					SELECT *
					FROM SiteProperties
					WHERE PropertyID = @GPRSPropertyValue
				) AS sp
				ON sp.EDISID = s.EDISID
	END
	ELSE
	BEGIN
		SELECT 
			@Company AS Company,
			s.SiteID,
			s.Name,
			s.PostCode,
			s.LastDownload,
			COALESCE(st.Frequency, 'Unknown') AS Frequency
			FROM Sites AS s
			LEFT JOIN @SystemType AS st
				ON st.SystemTypeID = s.SystemTypeID
				
	END
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetSitesStatus] TO PUBLIC
    AS [dbo];

