-- =============================================================
-- usp_CalculateLeaseFee: リース料計算(契約登録前の試算用)
--   - 物件価格・期間・利率から月額・総額を計算
--   - DBへの書き込みは行わない(純粋な計算ストアド)
-- パラメータ:
--   @TotalAmount  : 物件価格合計
--   @LeaseMonths  : リース期間(月)
--   @InterestRate : 年利率
--   @MonthlyFee   : OUTPUT 月額リース料
--   @TotalLeaseFee: OUTPUT リース料総額
--   @TotalInterest: OUTPUT 利息相当額
-- =============================================================

USE LeaseStudyDb;
GO

IF OBJECT_ID('dbo.usp_CalculateLeaseFee', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CalculateLeaseFee;
GO

CREATE PROCEDURE dbo.usp_CalculateLeaseFee
    @TotalAmount   DECIMAL(15, 0),
    @LeaseMonths   INT,
    @InterestRate  DECIMAL(7, 5),
    @MonthlyFee    DECIMAL(15, 0) OUTPUT,
    @TotalLeaseFee DECIMAL(15, 0) OUTPUT,
    @TotalInterest DECIMAL(15, 0) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @TotalAmount <= 0
            THROW 50101, N'物件価格は正の値を指定してください。', 1;
        IF @LeaseMonths <= 0 OR @LeaseMonths > 120
            THROW 50102, N'リース期間は 1〜120ヶ月の範囲で指定してください。', 1;
        IF @InterestRate < 0 OR @InterestRate > 1
            THROW 50103, N'年利率は 0〜1 の範囲で指定してください。', 1;

        DECLARE @MonthlyRate DECIMAL(18, 10) = @InterestRate / 12.0;

        IF @MonthlyRate = 0
        BEGIN
            -- 無利息: 元金を期間で按分
            SET @MonthlyFee = CAST(ROUND(@TotalAmount * 1.0 / @LeaseMonths, 0) AS DECIMAL(15, 0));
        END
        ELSE
        BEGIN
            -- 元利均等返済式
            DECLARE @Power FLOAT = POWER(1.0 + CAST(@MonthlyRate AS FLOAT), @LeaseMonths);
            SET @MonthlyFee = CAST(
                ROUND(@TotalAmount * CAST(@MonthlyRate AS FLOAT) * @Power / (@Power - 1.0), 0)
                AS DECIMAL(15, 0));
        END

        SET @TotalLeaseFee = @MonthlyFee * @LeaseMonths;
        SET @TotalInterest = @TotalLeaseFee - @TotalAmount;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '=== usp_CalculateLeaseFee 作成完了 ===';
GO
