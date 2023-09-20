CREATE FUNCTION DateOnly(@DateTime DATETIME)
-- Returns @DateTime at midnight; i.e., it removes the time portion of a DateTime value.
RETURNS DATETIME
AS
    BEGIN
    RETURN DATEADD(dd,0, DATEDIFF(dd,0,@DateTime))
    END


