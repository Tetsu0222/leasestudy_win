USE LeaseStudyDb;
GO

IF OBJECT_ID('dbo.usp_IssueBilling', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_IssueBilling;
GO

CREATE PROCEDURE dbo.usp_IssueBilling
    @ReceivableId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.T_Receivable
    SET Status = 20
    WHERE ReceivableId = @ReceivableId;
END
GO

PRINT '=== usp_IssueBilling 請求情報登録完了 ===';
GO