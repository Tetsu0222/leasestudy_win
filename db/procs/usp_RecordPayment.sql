USE LeaseStudyDb;
GO

IF OBJECT_ID('dbo.usp_RecordPayment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_RecordPayment;
GO

CREATE PROCEDURE dbo.usp_RecordPayment
    @ReceivableId INT = NULL,
    @PaymentAmount DECIMAL(18,2) = NULL,
    @PaymentDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.T_Payment (ReceivableId, PaymentDate, PaymentAmount)
        VALUES (@ReceivableId, ISNULL(@PaymentDate, CAST(SYSDATETIME() AS DATE)), @PaymentAmount);

        UPDATE dbo.T_Receivable
        SET PaidAmount = PaidAmount + @PaymentAmount,
            Status = 30,
            UpdatedAt = SYSDATETIME()
        WHERE ReceivableId = @ReceivableId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

PRINT '=== usp_RecordPayment 入金情報登録完了 ===';
GO