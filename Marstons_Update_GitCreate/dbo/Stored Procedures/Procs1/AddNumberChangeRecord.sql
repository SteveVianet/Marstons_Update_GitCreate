CREATE PROCEDURE [dbo].[AddNumberChangeRecord]
(
	@EDISID		INT,
	@Date		DATETIME,
	@Description	VARCHAR(255),
	@Time		DATETIME
)

AS

DECLARE @DBID INT
DECLARE @CombinedDate AS DATETIME

SET @Date = CAST(CONVERT(VARCHAR(10), @Date, 12) AS DATETIME)
SET @Time = CAST('1899-12-30 ' + CONVERT(VARCHAR(10), @Time, 8) AS DATETIME)

SELECT @DBID = PropertyValue FROM Configuration WHERE PropertyName = 'Service Owner ID'
SET @CombinedDate = CAST(STR(DATEPART(year,@Date),4) + '-' + STR(DATEPART(month,@Date),LEN(DATEPART(month,@Date))) + '-' + STR(DATEPART(day,@Date),LEN(DATEPART(day,@Date))) + ' ' + STR(DATEPART(hour,@Time),LEN(DATEPART(hour,@Time))) + ':' + STR(DATEPART(minute,@Time),LEN(DATEPART(minute,@Time))) + ':' + STR(DATEPART(second,@Time),LEN(DATEPART(second,@Time))) AS DATETIME)

EXEC [SQL1\SQL1].ServiceLogger.dbo.AddEDISNumberChange @DBID, @EDISID, @CombinedDate, @Description

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddNumberChangeRecord] TO PUBLIC
    AS [dbo];

