
CREATE PROCEDURE SaveExceptionEmail
	@TemplateHTML	VARCHAR(MAX),
	@Column			VARCHAR(100),
	@OwnerID		INT,
	@SubjectColumn	VARCHAR(100),
	@Subject		VARCHAR(255),
	@ApplyAll		BIT
AS

SET NOCOUNT ON;

DECLARE @SQL VARCHAR(MAX)
DECLARE @WhereSQL VARCHAR(50)

IF @ApplyAll = 1
	SET @WhereSQL = ''
ELSE
	SET @WhereSQL = 'WHERE ID = ' + CAST(@OwnerID AS VARCHAR)

SET @SQL = 'UPDATE Owners SET ' + @Column + ' = ''' + @TemplateHTML + ''' ' + @WhereSQL

EXECUTE(@SQL)

SET @SQL = 'UPDATE Owners SET ' + @SubjectColumn + ' = ''' + @Subject + ''' ' + @WhereSQL

EXECUTE(@SQL)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SaveExceptionEmail] TO PUBLIC
    AS [dbo];

