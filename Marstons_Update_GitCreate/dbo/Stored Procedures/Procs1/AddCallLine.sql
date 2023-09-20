CREATE PROCEDURE AddCallLine
(
	@CallID INT,
	@LineNumber INT,
	@Location VARCHAR(255),
	@VolumeDispensed FLOAT,
	@Product VARCHAR(255)
)

AS

INSERT INTO CallLines
(CallID, LineNumber, Location, VolumeDispensed, Product)
VALUES
(@CallID, @LineNumber, @Location, @VolumeDispensed, @Product)


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddCallLine] TO PUBLIC
    AS [dbo];

