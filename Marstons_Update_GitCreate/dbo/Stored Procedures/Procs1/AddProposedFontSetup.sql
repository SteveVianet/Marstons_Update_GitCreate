CREATE PROCEDURE [dbo].[AddProposedFontSetup]
(
                @EDISID              INT,
                @GlasswareStateID INT = 4,
    @User VARCHAR(500) = NULL,
	@CAMEngineerID INT = NULL,
	@CallID INT = NULL
)

AS

IF @User IS NOT NULL
BEGIN
                INSERT INTO dbo.ProposedFontSetups
                (EDISID, GlasswareStateID, UserName, Calibrator, CAMEngineerID, CallID)
                VALUES
                (@EDISID, @GlasswareStateID, @User, @User, @CAMEngineerID, @CallID)
END
ELSE
BEGIN
                INSERT INTO dbo.ProposedFontSetups
                (EDISID, GlasswareStateID, UserName, Calibrator, CAMEngineerID, CallID)
                VALUES
                (@EDISID, @GlasswareStateID, SUSER_NAME(), SUSER_NAME(), @CAMEngineerID, @CallID)
END

RETURN @@IDENTITY

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[AddProposedFontSetup] TO PUBLIC
    AS [dbo];

