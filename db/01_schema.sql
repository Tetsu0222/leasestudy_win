-- =============================================================
-- LeaseStudyDb スキーマ作成スクリプト
-- 実行: docker exec leasestudy-mssql /opt/mssql-tools18/bin/sqlcmd ... -i /scripts/01_schema.sql
-- =============================================================

-- 計算列(PERSISTED)を扱うため QUOTED_IDENTIFIER ON が必要。
-- sqlcmd の既定セッションは OFF で繋いでくるので明示。
SET QUOTED_IDENTIFIER ON;
GO

USE master;
GO

IF DB_ID('LeaseStudyDb') IS NULL
BEGIN
    CREATE DATABASE LeaseStudyDb;
END
GO

USE LeaseStudyDb;
GO

-- 既存テーブルがあれば削除(学習用なので何度でも作り直せるように)
IF OBJECT_ID('dbo.T_AuditLog', 'U') IS NOT NULL DROP TABLE dbo.T_AuditLog;
IF OBJECT_ID('dbo.T_Payment', 'U') IS NOT NULL DROP TABLE dbo.T_Payment;
IF OBJECT_ID('dbo.T_Receivable', 'U') IS NOT NULL DROP TABLE dbo.T_Receivable;
IF OBJECT_ID('dbo.T_ContractDetail', 'U') IS NOT NULL DROP TABLE dbo.T_ContractDetail;
IF OBJECT_ID('dbo.T_Contract', 'U') IS NOT NULL DROP TABLE dbo.T_Contract;
IF OBJECT_ID('dbo.M_Item', 'U') IS NOT NULL DROP TABLE dbo.M_Item;
IF OBJECT_ID('dbo.M_Customer', 'U') IS NOT NULL DROP TABLE dbo.M_Customer;
GO

-- -------------------------------------------------------------
-- M_Customer: 顧客マスタ
-- -------------------------------------------------------------
CREATE TABLE dbo.M_Customer (
    CustomerId      INT             NOT NULL IDENTITY(1,1),
    CustomerCode    VARCHAR(10)     NOT NULL,
    CustomerName    NVARCHAR(100)   NOT NULL,
    PostalCode      VARCHAR(8)      NULL,
    Address         NVARCHAR(200)   NULL,
    Phone           VARCHAR(20)     NULL,
    CreditLimit     DECIMAL(15, 0)  NOT NULL DEFAULT 0,  -- 与信限度額
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_M_Customer PRIMARY KEY CLUSTERED (CustomerId),
    CONSTRAINT UQ_M_Customer_Code UNIQUE (CustomerCode)
);
GO

-- -------------------------------------------------------------
-- M_Item: 物件マスタ
-- -------------------------------------------------------------
CREATE TABLE dbo.M_Item (
    ItemId          INT             NOT NULL IDENTITY(1,1),
    ItemCode        VARCHAR(20)     NOT NULL,
    ItemName        NVARCHAR(100)   NOT NULL,
    ItemCategory    NVARCHAR(50)    NOT NULL,  -- 車両 / OA機器 / 産業機械 など
    StandardPrice   DECIMAL(15, 0)  NOT NULL,
    UsefulLifeYears INT             NOT NULL DEFAULT 5,  -- 法定耐用年数
    IsActive        BIT             NOT NULL DEFAULT 1,
    CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_M_Item PRIMARY KEY CLUSTERED (ItemId),
    CONSTRAINT UQ_M_Item_Code UNIQUE (ItemCode)
);
GO

-- -------------------------------------------------------------
-- T_Contract: 契約ヘッダ
--   Status: 10=登録済 / 20=リース中 / 30=満了 / 40=中途解約
-- -------------------------------------------------------------
CREATE TABLE dbo.T_Contract (
    ContractId      INT             NOT NULL IDENTITY(1,1),
    ContractNo      VARCHAR(20)     NOT NULL,
    CustomerId      INT             NOT NULL,
    ContractDate    DATE            NOT NULL,  -- 契約締結日
    StartDate       DATE            NOT NULL,  -- リース開始日(検収日)
    EndDate         DATE            NOT NULL,  -- リース満了日
    LeaseMonths     INT             NOT NULL,  -- リース期間(月)
    InterestRate    DECIMAL(7, 5)   NOT NULL,  -- 年利率 (例: 0.03500 = 3.5%)
    TotalAmount     DECIMAL(15, 0)  NOT NULL,  -- 物件価格合計
    MonthlyFee      DECIMAL(15, 0)  NOT NULL DEFAULT 0,  -- 月額リース料
    Status          INT             NOT NULL DEFAULT 10,
    CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_T_Contract PRIMARY KEY CLUSTERED (ContractId),
    CONSTRAINT UQ_T_Contract_No UNIQUE (ContractNo),
    CONSTRAINT FK_T_Contract_Customer FOREIGN KEY (CustomerId)
        REFERENCES dbo.M_Customer (CustomerId)
);
GO

CREATE INDEX IX_T_Contract_CustomerId ON dbo.T_Contract (CustomerId);
CREATE INDEX IX_T_Contract_Status ON dbo.T_Contract (Status);
GO

-- -------------------------------------------------------------
-- T_ContractDetail: 契約明細
-- -------------------------------------------------------------
-- 注: LineNo は SQL Server の予約キーワード扱いになるため、ブラケットで囲む。
CREATE TABLE dbo.T_ContractDetail (
    ContractId      INT             NOT NULL,
    [LineNo]        INT             NOT NULL,
    ItemId          INT             NOT NULL,
    Quantity        INT             NOT NULL DEFAULT 1,
    UnitPrice       DECIMAL(15, 0)  NOT NULL,
    Amount          AS (Quantity * UnitPrice) PERSISTED,  -- 計算列
    CONSTRAINT PK_T_ContractDetail PRIMARY KEY CLUSTERED (ContractId, [LineNo]),
    CONSTRAINT FK_T_ContractDetail_Contract FOREIGN KEY (ContractId)
        REFERENCES dbo.T_Contract (ContractId),
    CONSTRAINT FK_T_ContractDetail_Item FOREIGN KEY (ItemId)
        REFERENCES dbo.M_Item (ItemId)
);
GO

-- -------------------------------------------------------------
-- T_Receivable: 債権(月次の請求データ)
--   Status: 10=未請求 / 20=請求済 / 30=入金済 / 40=一部入金
-- -------------------------------------------------------------
CREATE TABLE dbo.T_Receivable (
    ReceivableId    INT             NOT NULL IDENTITY(1,1),
    ContractId      INT             NOT NULL,
    DueDate         DATE            NOT NULL,  -- 請求月の支払期日
    DueAmount       DECIMAL(15, 0)  NOT NULL,
    PaidAmount      DECIMAL(15, 0)  NOT NULL DEFAULT 0,
    Status          INT             NOT NULL DEFAULT 10,
    CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_T_Receivable PRIMARY KEY CLUSTERED (ReceivableId),
    CONSTRAINT FK_T_Receivable_Contract FOREIGN KEY (ContractId)
        REFERENCES dbo.T_Contract (ContractId)
);
GO

CREATE INDEX IX_T_Receivable_ContractId ON dbo.T_Receivable (ContractId);
CREATE INDEX IX_T_Receivable_DueDate ON dbo.T_Receivable (DueDate);
GO

-- -------------------------------------------------------------
-- T_Payment: 入金履歴
-- -------------------------------------------------------------
CREATE TABLE dbo.T_Payment (
    PaymentId       INT             NOT NULL IDENTITY(1,1),
    ReceivableId    INT             NOT NULL,
    PaymentDate     DATE            NOT NULL,
    PaymentAmount   DECIMAL(15, 0)  NOT NULL,
    CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_T_Payment PRIMARY KEY CLUSTERED (PaymentId),
    CONSTRAINT FK_T_Payment_Receivable FOREIGN KEY (ReceivableId)
        REFERENCES dbo.T_Receivable (ReceivableId)
);
GO

-- -------------------------------------------------------------
-- T_AuditLog: 監査ログ(現場では必須)
-- -------------------------------------------------------------
CREATE TABLE dbo.T_AuditLog (
    LogId           BIGINT          NOT NULL IDENTITY(1,1),
    TableName       NVARCHAR(50)    NOT NULL,
    KeyValue        NVARCHAR(100)   NOT NULL,
    Operation       VARCHAR(10)     NOT NULL,  -- INSERT / UPDATE / DELETE
    OperationDate   DATETIME2(0)    NOT NULL DEFAULT SYSDATETIME(),
    UserId          NVARCHAR(50)    NOT NULL DEFAULT SUSER_SNAME(),
    Detail          NVARCHAR(MAX)   NULL,
    CONSTRAINT PK_T_AuditLog PRIMARY KEY CLUSTERED (LogId)
);
GO

PRINT '=== LeaseStudyDb スキーマ作成完了 ===';
GO
