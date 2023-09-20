
  CREATE FUNCTION [dbo].[fnGetPubcoPeriod]

(

       @Date                             DATETIME = NULL

  )

  RETURNS varchar(10) 

  AS

  BEGIN

  

  DECLARE @Period VARCHAR(10)

  

  SELECT @Period = Period

  FROM PubcoCalendars

 

  WHERE @Date BETWEEN FromWC AND DATEADD(DAY, 6, ToWC)

  ORDER BY FromWC

  

  RETURN @Period

  

  END


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnGetPubcoPeriod] TO PUBLIC
    AS [dbo];

