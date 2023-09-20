CREATE FUNCTION dbo.fnYearsApart
(
        @FromDate DATETIME,
        @ToDate DATETIME
)
RETURNS INT
AS
BEGIN
        RETURN  CASE
                       WHEN @FromDate > @ToDate THEN NULL
                       WHEN DATEPART(day, @FromDate) > DATEPART(day, @ToDate) THEN DATEDIFF(month, @FromDate, @ToDate) - 1
                       ELSE DATEDIFF(month, @FromDate, @ToDate)
               END / 12
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnYearsApart] TO PUBLIC
    AS [dbo];

