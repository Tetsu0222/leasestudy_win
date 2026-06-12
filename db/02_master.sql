-- =============================================================
-- マスタデータ初期投入
-- 実行: sqlcmd -S localhost -E -C -d LeaseStudyDb -i .\db\02_master.sql
-- =============================================================

USE LeaseStudyDb;
GO

-- 既存データクリア(学習用なので何度でも投入できるように)
DELETE FROM dbo.T_AuditLog;
DELETE FROM dbo.T_Payment;
DELETE FROM dbo.T_Receivable;
DELETE FROM dbo.T_ContractDetail;
DELETE FROM dbo.T_Contract;
DELETE FROM dbo.M_Item;
DELETE FROM dbo.M_Customer;
GO

-- IDENTITY を 1 にリセット
DBCC CHECKIDENT ('dbo.M_Customer', RESEED, 0);
DBCC CHECKIDENT ('dbo.M_Item', RESEED, 0);
DBCC CHECKIDENT ('dbo.T_Contract', RESEED, 0);
DBCC CHECKIDENT ('dbo.T_Receivable', RESEED, 0);
DBCC CHECKIDENT ('dbo.T_Payment', RESEED, 0);
DBCC CHECKIDENT ('dbo.T_AuditLog', RESEED, 0);
GO

-- -------------------------------------------------------------
-- M_Customer: 顧客マスタ
-- -------------------------------------------------------------
INSERT INTO dbo.M_Customer (CustomerCode, CustomerName, PostalCode, Address, Phone, CreditLimit)
VALUES
    ('C001', N'株式会社サンプル商事',    '100-0001', N'東京都千代田区千代田1-1',   '03-1111-2222', 50000000),
    ('C002', N'山田工業株式会社',         '530-0001', N'大阪府大阪市北区梅田2-2-2', '06-3333-4444', 30000000),
    ('C003', N'みらい建設株式会社',       '460-0001', N'愛知県名古屋市中区三の丸1', '052-555-6666', 80000000),
    ('C004', N'北海道フード株式会社',     '060-0001', N'札幌市中央区北一条西1',     '011-777-8888', 20000000),
    ('C005', N'九州物流株式会社',         '812-0001', N'福岡市博多区博多駅東1-1-1', '092-999-0000', 40000000);
GO

-- -------------------------------------------------------------
-- M_Item: 物件マスタ
-- -------------------------------------------------------------
INSERT INTO dbo.M_Item (ItemCode, ItemName, ItemCategory, StandardPrice, UsefulLifeYears)
VALUES
    ('VHC-001', N'4tトラック',             N'車両',       4500000, 5),
    ('VHC-002', N'営業車セダン',           N'車両',       2800000, 5),
    ('VHC-003', N'フォークリフト',         N'車両',       3200000, 6),
    ('OAE-001', N'複合機(A3対応)',       N'OA機器',      850000, 5),
    ('OAE-002', N'業務用PC一式',           N'OA機器',      280000, 4),
    ('OAE-003', N'サーバラック',           N'OA機器',     1200000, 5),
    ('IND-001', N'CNC旋盤',                N'産業機械',  12500000, 7),
    ('IND-002', N'射出成形機',             N'産業機械',   8800000, 7),
    ('IND-003', N'パレット梱包機',         N'産業機械',   3500000, 6);
GO

PRINT '=== マスタデータ投入完了 ===';
SELECT N'顧客' AS 種別, COUNT(*) AS 件数 FROM dbo.M_Customer
UNION ALL
SELECT N'物件', COUNT(*) FROM dbo.M_Item;
GO
