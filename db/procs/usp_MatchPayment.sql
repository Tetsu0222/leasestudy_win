-- =============================================================
-- usp_MatchPayment: 債権(月次の請求データ)
--   - Status: 10=未請求 / 20=請求済 / 30=入金済 / 40=一部入金
-- パラメータ:
--   @ReceivableId : 債権ID
--   @ContractId   : 契約ID
--   @DueDate      : 期限日
--   @DueAmount    : 期限日までの月額リース料
--   @PaidAmount   : OUTPUT 入金額
--   @Status       : OUTPUT 債権ステータス
-- =============================================================

USE LeaseStudyDb;
GO

IF OBJECT_ID('dbo.usp_MatchPayment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_MatchPayment;
GO

