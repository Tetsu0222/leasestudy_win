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

        DECLARE @DueAmount      DECIMAL(15, 0);
        DECLARE @CurrentPaid    DECIMAL(15, 0);
        DECLARE @NewPaid        DECIMAL(15, 0);
        DECLARE @NewStatus      INT;

        SELECT @DueAmount   = DueAmount,
               @CurrentPaid = PaidAmount
        FROM dbo.T_Receivable
        WHERE ReceivableId = @ReceivableId;

        SET @NewPaid = @CurrentPaid + @PaymentAmount;

        IF @NewPaid > @DueAmount
        BEGIN
            THROW 50001, N'入金額が請求額を超えています。', 1;
        END

        IF @NewPaid = @DueAmount
            SET @NewStatus = 30;  -- 入金済
        ELSE
            SET @NewStatus = 40;  -- 一部入金

        INSERT INTO dbo.T_Payment (ReceivableId, PaymentDate, PaymentAmount)
        VALUES (@ReceivableId, ISNULL(@PaymentDate, CAST(SYSDATETIME() AS DATE)), @PaymentAmount);

        UPDATE dbo.T_Receivable
        SET PaidAmount = @NewPaid,
            Status = @NewStatus,
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