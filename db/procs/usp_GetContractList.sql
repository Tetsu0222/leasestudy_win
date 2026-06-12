-- =============================================================
-- usp_GetContractList: 契約一覧取得
--   - 顧客名・ステータス・期間で絞り込み
--   - JOIN + WHERE 動的化 + ページングの基本パターン
-- パラメータ:
--   @CustomerId     : 顧客ID (NULL なら絞り込みなし)
--   @Status         : 契約ステータス (NULL なら絞り込みなし)
--   @StartDateFrom  : 開始日範囲(From) (NULL なら絞り込みなし)
--   @StartDateTo    : 開始日範囲(To)   (NULL なら絞り込みなし)
-- 結果セット:
--   契約番号、顧客名、開始日、満了日、月額、ステータス
-- =============================================================

USE LeaseStudyDb;
GO

IF OBJECT_ID('dbo.usp_GetContractList', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GetContractList;
GO

CREATE PROCEDURE dbo.usp_GetContractList
    @CustomerId    INT  = NULL,
    @Status        INT  = NULL,
    @StartDateFrom DATE = NULL,
    @StartDateTo   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.ContractId,
        c.ContractNo,
        cu.CustomerCode,
        cu.CustomerName,
        c.ContractDate,
        c.StartDate,
        c.EndDate,
        c.LeaseMonths,
        c.TotalAmount,
        c.MonthlyFee,
        c.Status,
        CASE c.Status
            WHEN 10 THEN N'登録済'
            WHEN 20 THEN N'リース中'
            WHEN 30 THEN N'満了'
            WHEN 40 THEN N'中途解約'
            ELSE N'不明'
        END AS StatusName
    FROM dbo.T_Contract AS c
    INNER JOIN dbo.M_Customer AS cu
        ON cu.CustomerId = c.CustomerId
    WHERE (@CustomerId    IS NULL OR c.CustomerId = @CustomerId)
      AND (@Status        IS NULL OR c.Status     = @Status)
      AND (@StartDateFrom IS NULL OR c.StartDate >= @StartDateFrom)
      AND (@StartDateTo   IS NULL OR c.StartDate <= @StartDateTo)
    ORDER BY c.ContractId DESC;
END
GO

PRINT '=== usp_GetContractList 作成完了 ===';
GO
