


CREATE PROCEDURE AddReportParameter
(
	@GenerationID	BIGINT,
	@ParameterName	NVARCHAR(50),
	@ParameterValue	NVARCHAR(50)
)
AS
EXEC [SQL1\SQL1].ServiceLogger.dbo.AddReportParameter @GenerationID, @ParameterName, @ParameterValue

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddReportParameter] TO PUBLIC
    AS [dbo];

