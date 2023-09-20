CREATE PROCEDURE UpdateCallLine
(
	@CallID INT,
	@LineNumber INT,
	@Location VARCHAR(255),
	@VolumeDispensed FLOAT,
	@Product VARCHAR(255)
)

AS

UPDATE CallLines
SET	Location = @Location,
	VolumeDispensed = @VolumeDispensed,
	Product = @Product
WHERE CallID = @CallID
AND LineNumber = @LineNumber


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[UpdateCallLine] TO PUBLIC
    AS [dbo];

