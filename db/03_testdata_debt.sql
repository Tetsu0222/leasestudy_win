-- =============================================================
-- 債権管理(usp_GetDebtList)動作確認用テストデータ
-- 実行例:
--   sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -C -d LeaseStudyDb -i .\db\03_testdata_debt.sql
-- 前提: 01_schema.sql / 02_master.sql 投入済(M_Customer に CustomerId=1..5 が存在)
-- =============================================================

USE LeaseStudyDb;
GO

SET NOCOUNT ON;
GO

-- -------------------------------------------------------------
-- 既存の債権・入金・契約データをクリア
-- (マスタは消さない)
-- -------------------------------------------------------------
DELETE FROM dbo.T_Payment;
DELETE FROM dbo.T_Receivable;
DELETE FROM dbo.T_ContractDetail;
DELETE FROM dbo.T_Contract;
GO

DBCC CHECKIDENT ('dbo.T_Contract',   RESEED, 0);
DBCC CHECKIDENT ('dbo.T_Receivable', RESEED, 0);
DBCC CHECKIDENT ('dbo.T_Payment',    RESEED, 0);
GO

-- -------------------------------------------------------------
-- T_Contract: 契約ヘッダ(3件)
--   ContractId は IDENTITY なので 1, 2, 3 が振られる想定
-- -------------------------------------------------------------
INSERT INTO dbo.T_Contract
    (ContractNo, CustomerId, ContractDate, StartDate, EndDate,
     LeaseMonths, InterestRate, TotalAmount, MonthlyFee, Status)
VALUES
    -- ContractId=1: サンプル商事 / 4tトラック 36ヶ月
    ('LC-2026-0001', 1, '2026-01-15', '2026-02-01', '2029-01-31',
     36, 0.03500, 4500000, 132000, 20),
    -- ContractId=2: 山田工業 / 複合機 24ヶ月
    ('LC-2026-0002', 2, '2026-02-10', '2026-03-01', '2028-02-29',
     24, 0.03000, 850000,  37500, 20),
    -- ContractId=3: みらい建設 / CNC旋盤 60ヶ月
    ('LC-2026-0003', 3, '2026-03-05', '2026-04-01', '2031-03-31',
     60, 0.04000, 12500000, 230000, 20);
GO

-- -------------------------------------------------------------
-- T_ContractDetail: 契約明細
-- -------------------------------------------------------------
INSERT INTO dbo.T_ContractDetail (ContractId, [LineNo], ItemId, Quantity, UnitPrice)
VALUES
    (1, 1, 1, 1, 4500000),   -- 4tトラック
    (2, 1, 4, 1,  850000),   -- 複合機
    (3, 1, 7, 1, 12500000);  -- CNC旋盤
GO

-- -------------------------------------------------------------
-- T_Receivable: 債権(各契約に4ヶ月分=合計12件)
--   Status: 10=未請求 / 20=請求済 / 30=入金済 / 40=一部入金
--
--   ReceivableId 想定値(IDENTITY=1からの順):
--     ContractId=1: 1,2,3,4
--     ContractId=2: 5,6,7,8
--     ContractId=3: 9,10,11,12
-- -------------------------------------------------------------

-- ContractId=1 (月額 132,000)
INSERT INTO dbo.T_Receivable (ContractId, DueDate, DueAmount, PaidAmount, Status)
VALUES
    (1, '2026-02-28', 132000, 132000, 30),  -- 入金済
    (1, '2026-03-31', 132000,  50000, 40),  -- 一部入金
    (1, '2026-04-30', 132000,      0, 20),  -- 請求済(未入金)
    (1, '2026-05-31', 132000,      0, 10);  -- 未請求

-- ContractId=2 (月額 37,500)
INSERT INTO dbo.T_Receivable (ContractId, DueDate, DueAmount, PaidAmount, Status)
VALUES
    (2, '2026-03-31',  37500,  37500, 30),  -- 入金済
    (2, '2026-04-30',  37500,  37500, 30),  -- 入金済
    (2, '2026-05-31',  37500,      0, 20),  -- 請求済
    (2, '2026-06-30',  37500,      0, 10);  -- 未請求

-- ContractId=3 (月額 230,000)
INSERT INTO dbo.T_Receivable (ContractId, DueDate, DueAmount, PaidAmount, Status)
VALUES
    (3, '2026-04-30', 230000, 230000, 30),  -- 入金済(分割2回)
    (3, '2026-05-31', 230000, 100000, 40),  -- 一部入金
    (3, '2026-06-30', 230000,      0, 20),  -- 請求済
    (3, '2026-07-31', 230000,      0, 10);  -- 未請求
GO

-- -------------------------------------------------------------
-- T_Payment: 入金履歴
--   - 入金済(30)には満額の入金レコード
--   - 一部入金(40)には部分入金レコード
--   - ContractId=3 / ReceivableId=9 は分割入金で2レコード
--   - 請求済(20)/未請求(10)には入金レコード無し(LEFT JOIN動作確認用)
-- -------------------------------------------------------------
INSERT INTO dbo.T_Payment (ReceivableId, PaymentDate, PaymentAmount)
VALUES
    (1, '2026-02-25', 132000),  -- ContractId=1 / 1回目: 満額
    (2, '2026-03-30',  50000),  -- ContractId=1 / 2回目: 一部
    (5, '2026-03-28',  37500),  -- ContractId=2 / 1回目: 満額
    (6, '2026-04-27',  37500),  -- ContractId=2 / 2回目: 満額
    (9, '2026-04-20', 100000),  -- ContractId=3 / 1回目: 分割1
    (9, '2026-04-28', 130000),  -- ContractId=3 / 1回目: 分割2(合計230,000)
    (10,'2026-05-29', 100000);  -- ContractId=3 / 2回目: 一部
GO

-- -------------------------------------------------------------
-- 確認: 投入件数
-- -------------------------------------------------------------
PRINT '=== テストデータ投入完了 ===';
SELECT N'契約'   AS 種別, COUNT(*) AS 件数 FROM dbo.T_Contract
UNION ALL
SELECT N'明細',           COUNT(*)         FROM dbo.T_ContractDetail
UNION ALL
SELECT N'債権',           COUNT(*)         FROM dbo.T_Receivable
UNION ALL
SELECT N'入金',           COUNT(*)         FROM dbo.T_Payment;
GO

-- -------------------------------------------------------------
-- 動作確認サンプル(必要なら手で実行)
-- -------------------------------------------------------------
-- 全件:
--   EXEC dbo.usp_GetDebtList;
-- 契約ID指定:
--   EXEC dbo.usp_GetDebtList @ContractId = 1;
-- ステータス指定(40=一部入金):
--   EXEC dbo.usp_GetDebtList @Status = 40;
-- 期日指定:
--   EXEC dbo.usp_GetDebtList @DueDate = '2026-03-31';
-- 債権ID指定(分割入金の確認):
--   EXEC dbo.usp_GetDebtList @ReceivableId = 9;
