USE LeaseStudyDb;
GO

IF OBJECT_ID('dbo.usp_GetDebtList', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetDebtList;
GO

CREATE PROCEDURE dbo.usp_GetDebtList
    @ReceivableId INT = NULL,
    @ContractId   INT = NULL,
    @Status       INT = NULL,
    @DueDate      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.ReceivableId,
        r.ContractId,
        r.DueDate,
        r.DueAmount,
        r.PaidAmount,
        r.Status,
        CASE r.Status
            WHEN 10 THEN N'未請求'
            WHEN 20 THEN N'請求済'
            WHEN 30 THEN N'入金済'
            WHEN 40 THEN N'一部入金'
            ELSE N'不明'
        END AS StatusName,
        p.PaymentId,
        p.PaymentDate,
        p.PaymentAmount
    FROM dbo.T_Receivable AS r
    LEFT JOIN dbo.T_Payment AS p
        ON p.ReceivableId = r.ReceivableId
    WHERE (@ReceivableId IS NULL OR r.ReceivableId = @ReceivableId)
      AND (@ContractId   IS NULL OR r.ContractId   = @ContractId)
      AND (@Status       IS NULL OR r.Status       = @Status)
      AND (@DueDate      IS NULL OR r.DueDate      = @DueDate)
    ORDER BY r.ContractId DESC, r.DueDate, p.PaymentDate;
END
GO

PRINT '=== usp_GetDebtList 作成完了 ===';
GO