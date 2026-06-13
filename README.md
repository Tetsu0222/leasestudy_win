# leasestudy_win — リース業務想定 VB.Net + SQL Server 学習プロジェクト

リース業務システム(基幹系)の構造をミニチュアで再現した、VB.Net + SQL Server の個人学習用プロジェクトです。
**業務ロジックは原則ストアドプロシージャに書き、VB.Net 側はそれを呼ぶインターフェースとして使う**、という現場ど真ん中の構成を体験します。

## 学習の狙い

- **T-SQL でストアドプロシージャを書く・呼ぶ**経験を積む(学習比重 60%)
- **リース業務の用語・データモデル**に慣れる(学習比重 20%)
- **VB.Net の ADO.NET 呼び出しお作法**を身につける(学習比重 15%)
- **トランザクション・例外処理・監査ログ**といった現場の「堅さ」を体感する(学習比重 5%)

## 構成

```
leasestudy_win/
├── README.md
├── .gitignore
├── db/
│   ├── 01_schema.sql           # テーブル作成(M_, T_)
│   ├── 02_master.sql           # 顧客・物件マスタの初期データ
│   └── procs/
│       ├── usp_CreateContract.sql       # 契約登録
│       ├── usp_CalculateLeaseFee.sql    # リース料計算
│       └── usp_GetContractList.sql      # 契約一覧
└── src/
    └── LeaseStudyApp/
        ├── LeaseStudyApp.vbproj
        ├── Program.vb               # エントリポイント + メニュー
        ├── Data/
        │   └── SqlConnectionFactory.vb
        ├── Repositories/
        │   └── ContractRepository.vb
        ├── Models/
        │   ├── Contract.vb
        │   ├── Customer.vb
        │   └── Item.vb
        ├── UI/
        │   └── MenuPresenter.vb
        └── Common/
            └── AppException.vb
```

## テーブル設計(ミニチュア版)

| テーブル | 種別 | 役割 |
|---|---|---|
| `M_Customer` | マスタ | 顧客(リース契約の借主) |
| `M_Item` | マスタ | 物件(リース対象物:車両、OA機器、産業機械など) |
| `T_Contract` | トランザクション | リース契約ヘッダ |
| `T_ContractDetail` | トランザクション | 契約明細(1契約に複数物件) |
| `T_Receivable` | トランザクション | 月次の債権(請求データ) |
| `T_Payment` | トランザクション | 入金履歴 |
| `T_AuditLog` | トランザクション | 監査ログ(操作履歴) |

命名規約は `M_` がマスタ、`T_` がトランザクションテーブル。
ストアドは `usp_` + 動詞 + 対象 (例:`usp_CreateContract`)。

## 前提

- Windows 11 + **Docker Desktop**(SQL Server も .NET SDK もコンテナで動かす)
- SQL 認証(SAユーザ + パスワード)
  - Linux版 SQL Server コンテナは Windows 認証非対応のため

ホスト側に SQL Server / `sqlcmd` / .NET SDK を入れる必要はありません。

## セットアップ

### 1. SQL Server コンテナを起動

```powershell
# 任意: パスワードを変えたいときは .env を作成
Copy-Item .env.example .env

# 起動(初回はイメージ pull で数分かかる)
docker compose up -d

# 起動完了待ち(healthcheck が healthy になればOK)
docker compose ps
```

### 2. スキーマ + ストアド投入

`db/` フォルダはコンテナ内 `/scripts` にマウントされているので、
**コンテナ内の `sqlcmd` を `docker exec` 経由で叩きます**。

一括投入用スクリプトを用意してあります:

```powershell
.\db\apply.ps1
```

中身を理解したい場合は、個別に叩くこともできます:

`-I` は `QUOTED_IDENTIFIER ON` を強制するオプション。
計算列やインデックス付きビューを含むスクリプトを流すときの定番。

```powershell
$pwd_ = "YourStrong!Passw0rd"   # .env で変えたなら合わせる
$sql  = "/opt/mssql-tools18/bin/sqlcmd"

# DB作成 + テーブル作成(master に接続して実行)
docker exec leasestudy-mssql $sql -S localhost -U sa -P $pwd_ -C -I -d master -i /scripts/01_schema.sql

# マスタデータ投入
docker exec leasestudy-mssql $sql -S localhost -U sa -P $pwd_ -C -I -d LeaseStudyDb -i /scripts/02_master.sql

# ストアドプロシージャ投入
docker exec leasestudy-mssql $sql -S localhost -U sa -P $pwd_ -C -I -d LeaseStudyDb -i /scripts/procs/usp_CreateContract.sql
docker exec leasestudy-mssql $sql -S localhost -U sa -P $pwd_ -C -I -d LeaseStudyDb -i /scripts/procs/usp_CalculateLeaseFee.sql
docker exec leasestudy-mssql $sql -S localhost -U sa -P $pwd_ -C -I -d LeaseStudyDb -i /scripts/procs/usp_GetContractList.sql
docker exec leasestudy-mssql $sql -S localhost -U sa -P $pwd_ -C -I -d LeaseStudyDb -i /scripts/procs/usp_GetDebtList.sql
```

対話的に SQL を叩きたいときは:

```powershell
docker exec -it leasestudy-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourStrong!Passw0rd -C -d LeaseStudyDb
```

### 3. アプリ実行

`.NET 8 SDK` コンテナで `dotnet run` を実行します:

```powershell
docker compose run --rm app dotnet run
```

- `app` サービスはプロジェクトルートを `/workspace` にマウントしているので、ソース変更はホストから即反映
- 接続先は内部ネットワーク経由で `mssql:1433` に自動接続(compose の `LEASE_SQLSERVER_CONNECTION` で指定済み)
- NuGet キャッシュは `./.nuget-cache` に作られて再ビルドが速くなる(`.gitignore` 済み)
- 初回実行時は `Microsoft.Data.SqlClient` の復元に数十秒かかります

ホストに .NET SDK を入れている場合は、ホストから直接動かすことも可能:

```powershell
$env:LEASE_SQLSERVER_CONNECTION = "Server=localhost,1433;Database=LeaseStudyDb;User ID=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;"
dotnet run --project .\src\LeaseStudyApp
```

### 後片付け

```powershell
docker compose down              # コンテナ停止 (データは残る)
docker compose down -v           # ボリュームも削除 = DB完全初期化
```

## 学習ロードマップ(3週間想定)

### Week 1:基盤づくり
- [ ] `01_schema.sql` を読み解く、SSMS で実行して ER 図を眺める
- [ ] `02_master.sql` で顧客・物件マスタを投入
- [ ] `usp_CreateContract` を読んで動かす(ストアド単体で実行)
- [ ] VB.Net から `usp_CreateContract` を呼んでみる
- [ ] `Try-Catch` でエラーハンドリング

**目標**:VB.Net → ストアド呼び出し → DB更新の1サイクルを完成させる

### Week 2:業務ロジック
- [ ] `usp_CalculateLeaseFee` を読んで、金額計算ロジックを理解する
- [ ] `Decimal` の丸め、`DATEADD/DATEDIFF` を実際に動かす
- [ ] `usp_GetContractList` で JOIN + WHERE 動的化を経験
- [ ] `T_Contract.Status` のステータス遷移を整理

**目標**:業務ロジックを T-SQL で書く感覚を掴む

### Week 3:現場リアル要素
- [ ] トランザクション(`BEGIN TRAN / COMMIT / ROLLBACK`)を全ストアドで意識
- [ ] `TRY...CATCH` + `THROW` で例外発出
- [ ] `T_AuditLog` への自動INSERT
- [ ] 入金消込ストアド `usp_MatchPayment` を自分で書いてみる
- [ ] 月次バッチ `usp_GenerateMonthlyBilling` を自分で書いてみる

**目標**:現場で求められる「堅さ」を体感する

## リース業務 最低限の用語

| 用語 | 意味 |
|---|---|
| **リース契約** | 顧客が物件を一定期間借りる契約 |
| **物件** | リースの対象物(車両・OA機器・産業機械等) |
| **検収日** | 物件が顧客に納品されたことの確認日(リース開始の起点) |
| **リース料率** | 物件価格に対する月額リース料の割合 |
| **残価** | リース満了時の物件残存価値 |
| **再リース** | 契約満了後に低額で継続して借りる契約 |
| **中途解約** | 契約期間途中での解約(違約金計算あり) |
| **債権管理** | 月次のリース料請求・入金消込 |

## メモ

- 個人学習用構成です。実際のリース業務はこの何倍も複雑です(税務・会計連携・与信管理など)。
- 戦闘シミュレーター(`cardgame_win`)とは独立。あちらは VB.Net 文法の練習用に温存します。
- `bin/` `obj/` は `.gitignore` 済み。
