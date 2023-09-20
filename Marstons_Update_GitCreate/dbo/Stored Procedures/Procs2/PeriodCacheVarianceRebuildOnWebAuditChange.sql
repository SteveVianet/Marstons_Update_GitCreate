CREATE PROCEDURE [dbo].[PeriodCacheVarianceRebuildOnWebAuditChange]
(
	@OverrideAuditDateChange BIT = 0
)
AS

SET NOCOUNT ON

DECLARE @WebAuditDateChanged BIT
DECLARE @Auditor VARCHAR(512)

SELECT @WebAuditDateChanged = CAST(PropertyValue AS BIT)
FROM Configuration
WHERE PropertyName = 'Web Audit Date Changed'

IF (@WebAuditDateChanged = 1) OR (@OverrideAuditDateChange = 1)
BEGIN
	DECLARE @Now DATETIME
	DECLARE @VarianceFrom DATETIME
	DECLARE @WebAuditDate DATETIME
	DECLARE @LastWeekDataCount INT

	SELECT @WebAuditDate = CAST(PropertyValue AS DATETIME)
	FROM Configuration
	WHERE PropertyName = 'AuditDate'

	SET @Now = CAST(DATEADD(DAY, 6, CAST(@WebAuditDate AS DATE)) AS NVARCHAR)
	SET @VarianceFrom = CAST(DATEADD(WEEK,-12,CAST(@WebAuditDate AS DATE)) AS NVARCHAR) 

	EXEC ('EXEC dbo.PeriodCacheVarianceRebuild ''' + @VarianceFrom + ''', ''' + @Now + '''')
	
	IF @OverrideAuditDateChange = 0
	BEGIN
		SET @Now = CAST(CAST(GETDATE() AS DATE) AS NVARCHAR)
		
		SELECT @LastWeekDataCount = COUNT(*)
		FROM PeriodCacheVariance
		WHERE WeekCommencing = @WebAuditDate

		IF @LastWeekDataCount > 0
		BEGIN
			SELECT @Auditor = CAST(PropertyValue AS VARCHAR)
			FROM Configuration
			WHERE PropertyName = 'AuditorEMail'

			UPDATE dbo.Configuration
			SET PropertyValue = '0'
			WHERE PropertyName = 'Web Audit Date Changed'

			UPDATE dbo.Configuration
			SET PropertyValue = @Now
			WHERE PropertyName = 'Period Cache Variance Refresh Date'

			IF @Auditor <> ''
			BEGIN
				DECLARE @Subject VARCHAR(1000)
				DECLARE @Body VARCHAR(8000)

				SET @Subject = 'Website Refresh Complete'

				SET @Body = '<html><head></head>' 
							+ '<body>'
							+ '<p>Website refresh has now completed after web audit date change.<BR><BR> Please login to the website to test.<BR><BR> If you need to send weekly report emails through Auditor, please now do so.</p>'
							+ '</body></html>'

				EXEC dbo.SendEmail  '', '', @Auditor, @Subject, @Body, '', NULL, NULL

			END
	
		END

	END

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[PeriodCacheVarianceRebuildOnWebAuditChange] TO PUBLIC
    AS [dbo];

