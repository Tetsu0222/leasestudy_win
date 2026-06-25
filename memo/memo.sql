-- # テーブル変数 DECLARE @t TABLE (Listに近い)
DECLARE @Targets TABLE (
    ContractID INT,
    Amount DECIMAL(18,2)
);

INSERT INTO @Targets (ContractID, Amount)
SELECT ContractID, MonthlyFee
FROM Contracts
WHERE Status = 'Active';

-- 次のクエリで使う
UPDATE p
SET p.Status = 'Billed'
FROM Payments p
INNER JOIN @Targets t ON p.ContractID = t.ContractID;


-- # 一時テーブル #temp (大きめのList)
CREATE TABLE #Targets (ContractID INT PRIMARY KEY, Amount DECIMAL(18,2));
CREATE INDEX IX_Amount ON #Targets(Amount);
-- ... INSERT / SELECT
DROP TABLE #Targets;


-- # ユーザー定義テーブル型 (TVP)
CREATE TYPE dbo.ContractIdList AS TABLE (ContractID INT PRIMARY KEY);
GO

CREATE PROCEDURE usp_BillContracts
    @Targets dbo.ContractIdList READONLY
AS
BEGIN
    SELECT * FROM Contracts c
    INNER JOIN @Targets t ON c.ContractID = t.ContractID;
END
