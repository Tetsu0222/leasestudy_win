-- =============================================================
-- usp_CreateContract: リース契約の新規登録
--   - 契約ヘッダ + 明細をトランザクション内で INSERT
--   - リース料を簡易計算してヘッダに保持
--   - 監査ログにINSERTを記録
-- パラメータ:
--   @CustomerId      : 顧客ID
--   @ContractDate    : 契約締結日
--   @StartDate       : リース開始日
--   @LeaseMonths     : リース期間(月)
--   @InterestRate    : 年利率 (例: 0.035 = 3.5%)
--   @ItemId          : 物件ID(明細は1件のみ。学習用簡略版)
--   @Quantity        : 数量
--   @UnitPrice       : 単価
--   @NewContractId   : OUTPUT 新規契約ID
-- =============================================================

USE LeaseStudyDb;
GO

IF OBJECT_ID('dbo.usp_CreateContract', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CreateContract;
GO

CREATE PROCEDURE dbo.usp_CreateContract
    @CustomerId      INT,
    @ContractDate    DATE,
    @StartDate       DATE,
    @LeaseMonths     INT,
    @InterestRate    DECIMAL(7, 5),
    @ItemId          INT,
    @Quantity        INT,
    @UnitPrice       DECIMAL(15, 0),
    @NewContractId   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 入力チェック(現場ではここで業務ルールを潰す)
        IF NOT EXISTS (SELECT 1 FROM dbo.M_Customer WHERE CustomerId = @CustomerId AND IsActive = 1)
        BEGIN
            THROW 50001, N'指定された顧客が存在しないか、無効です。', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.M_Item WHERE ItemId = @ItemId AND IsActive = 1)
        BEGIN
            THROW 50002, N'指定された物件が存在しないか、無効です。', 1;
        END

        IF @LeaseMonths <= 0 OR @LeaseMonths > 120
        BEGIN
            THROW 50003, N'リース期間は 1〜120ヶ月の範囲で指定してください。', 1;
        END

        -- 物件価格合計
        DECLARE @TotalAmount DECIMAL(15, 0) = @Quantity * @UnitPrice;

        -- 月額リース料(簡易計算: 元利均等返済の月額)
        -- 月利 = 年利 / 12
        -- 月額 = 元金 × 月利 × (1+月利)^n / ((1+月利)^n - 1)
        DECLARE @MonthlyRate DECIMAL(18, 10) = @InterestRate / 12.0;
        DECLARE @MonthlyFee  DECIMAL(15, 0);

        IF @MonthlyRate = 0
        BEGIN
            SET @MonthlyFee = CAST(ROUND(@TotalAmount * 1.0 / @LeaseMonths, 0) AS DECIMAL(15, 0));
        END
        ELSE
        BEGIN
            DECLARE @Power FLOAT = POWER(1.0 + CAST(@MonthlyRate AS FLOAT), @LeaseMonths);
            SET @MonthlyFee = CAST(
                ROUND(@TotalAmount * CAST(@MonthlyRate AS FLOAT) * @Power / (@Power - 1.0), 0)
                AS DECIMAL(15, 0));
        END

        -- 契約満了日 (開始日 + 期間 - 1日)
        DECLARE @EndDate DATE = DATEADD(DAY, -1, DATEADD(MONTH, @LeaseMonths, @StartDate));

        -- 契約番号 (年4桁 + 連番5桁) ※学習用簡易版
        DECLARE @ContractNo VARCHAR(20) =
            CONCAT('L', FORMAT(YEAR(@ContractDate), '0000'),
                   FORMAT(ISNULL((SELECT MAX(ContractId) FROM dbo.T_Contract), 0) + 1, '00000'));

        -- ヘッダINSERT
        INSERT INTO dbo.T_Contract (
            ContractNo, CustomerId, ContractDate, StartDate, EndDate,
            LeaseMonths, InterestRate, TotalAmount, MonthlyFee, Status
        )
        VALUES (
            @ContractNo, @CustomerId, @ContractDate, @StartDate, @EndDate,
            @LeaseMonths, @InterestRate, @TotalAmount, @MonthlyFee, 10  -- 10=登録済
        );

        SET @NewContractId = SCOPE_IDENTITY();

        -- 明細INSERT
        INSERT INTO dbo.T_ContractDetail (ContractId, [LineNo], ItemId, Quantity, UnitPrice)
        VALUES (@NewContractId, 1, @ItemId, @Quantity, @UnitPrice);

        -- 監査ログ
        INSERT INTO dbo.T_AuditLog (TableName, KeyValue, Operation, Detail)
        VALUES (
            'T_Contract',
            CAST(@NewContractId AS NVARCHAR(100)),
            'INSERT',
            CONCAT(N'契約番号=', @ContractNo,
                   N' 顧客ID=', @CustomerId,
                   N' 月額=', @MonthlyFee)
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;  -- 上位(VB.Net側)に例外を伝播
    END CATCH
END
GO

PRINT '=== usp_CreateContract 作成完了 ===';
GO
