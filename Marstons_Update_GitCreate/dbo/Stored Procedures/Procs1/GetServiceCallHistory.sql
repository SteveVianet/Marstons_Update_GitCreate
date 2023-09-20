 
CREATE PROCEDURE [dbo].[GetServiceCallHistory]
    @EDISID INT = NULL,
	@From DATE,
	@To DATE,
	@WorkItems VARCHAR(500) = NULL
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;


	DECLARE @CompanyName VARCHAR(500)
	SELECT @CompanyName = PropertyValue
	From dbo.Configuration
	WHERE PropertyName = 'Company Name'

	DECLARE @Items TABLE (
		ItemID INT
	)

	DECLARE @temp VARCHAR(500) = @WorkItems

	DECLARE @index INT = CHARINDEX(',', @temp)

	WHILE @index > 0
	BEGIN
		INSERT INTO @Items
		VALUES (SUBSTRING(@temp, 1, @index-1))

		SET @temp = SUBSTRING(@temp, @index+1, LEN(@temp)-@index)

		SET @index = CHARINDEX(',', @temp)
	END

	INSERT INTO @Items
		VALUES (@temp)

	

	DECLARE @BillingItems TABLE (
		CallID INT,
		WorkItem VARCHAR(150)
	)


	INSERT INTO @BillingItems
	SELECT c.ID,  (bi.Description + ' (' + CAST(wi.Quantity AS VARCHAR(10)) + ')' ) AS WorkItem
	FROM Calls AS c
	JOIN CallBillingItems as wi
		ON wi.CallID = c.ID
	JOIN [SQL1\SQL1].[ServiceLogger].[dbo].BillingItems AS bi
		ON bi.ID = wi.BillingItemID
	WHERE c.RaisedOn BETWEEN @From AND @To
		AND (@WorkItems IS NULL 
			OR bi.ID IN (
				SELECT *
				FROM @Items
							)
		)
	ORDER BY bi.Description

	

	SELECT 
		@CompanyName AS Customer,
		s.EDISID,
		s.SiteID,
		s.Name,
		s.Address1 AS [Address],
		CASE
            WHEN Address3 = '' AND Address2 = '' THEN ''
            WHEN Address3 = '' THEN Address2
            ELSE Address3
        END AS City,
		s.PostCode,		
		dbo.GetCallReference(c.ID) AS Reference,
		cs.Description AS Status,
		c.RaisedOn,
		(crt.[Description] + ' - ' + cr.AdditionalInfo) AS ReportedFault,
		c.ClosedOn,
		Work.WorkItem,
		(CAST(wdc.SubmittedOn AS VARCHAR(20)) + ' ' + wdc.WorkDetailCommentBy + ' ' + CAST(wdc.WorkDetailComment as varchar(100)) ) AS EngineerComment,
		c.SalesReference,
		c.AuthCode
	FROM Calls As c
	JOIN Sites AS s
		ON s.EDISID = c.EDISID
	-- Get current call status ID
	JOIN (
			SELECT csh.CallID, csh.StatusID 
			FROM CallStatusHistory as csh
			--Get Latest call status
			JOIN (
					SELECT csh.CallID, MAX(csh.ChangedOn) AS LastStatusChange
					FROM CallStatusHistory as csh
					GROUP BY csh.CallID
				) AS csh2
				ON csh2.CallID = csh.CallID
			WHERE csh.ChangedOn = csh2.LastStatusChange
		) AS [Status]
		ON [Status].CallID = c.ID 
	JOIN [SQL1\SQL1].ServiceLogger.dbo.CallStatuses AS cs
		ON cs.ID = [Status].StatusID
	JOIN CallReasons AS cr
		ON cr.CallID = c.ID
	JOIN [SQL1\SQL1].[ServiceLogger].[dbo].[CallReasonTypes] as crt
		on crt.ID = cr.ReasonTypeID
	JOIN CallWorkDetailComments as wdc
		ON wdc.CallID = c.ID
	JOIN (
		SELECT bi.CallID,
			(SELECT bi2.WorkItem + CHAR(10)
			FROM @BillingItems as bi2
			WHERE bi.CallID = bi2.CallID
			ORDER BY bi2.WorkItem
				FOR XML PATH('')
			) AS WorkItem
		FROM @BillingItems AS bi
		GROUP BY bi.CallID
		) AS Work
		ON Work.CallID = c.ID
	WHERE c.RaisedOn BETWEEN @From AND @To
		AND wdc.IsInvoice = 0

 
END 
 
GRANT EXEC ON [dbo].[GetServiceCallHistory] TO [public]
 

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetServiceCallHistory] TO PUBLIC
    AS [dbo];

