Imports System
Imports Microsoft.Data.SqlClient

Namespace Data

    ' SqlConnection を生成するファクトリ
    '  - 接続文字列は環境変数 LEASE_SQLSERVER_CONNECTION で上書き可能
    '  - 既定は Windows 認証で LeaseStudyDb に接続
    Public Module SqlConnectionFactory

        ' 既定は Docker の SQL Server コンテナ(SA認証)向け。
        ' Windows認証ローカルSQLを使うときは LEASE_SQLSERVER_CONNECTION を上書き。
        Private ReadOnly DefaultConnStr As String =
            "Server=localhost,1433;Database=LeaseStudyDb;User ID=sa;Password=YourStrong!Passw0rd;TrustServerCertificate=True;"

        Public Function GetConnectionString() As String
            Dim envValue = Environment.GetEnvironmentVariable("LEASE_SQLSERVER_CONNECTION")
            If String.IsNullOrWhiteSpace(envValue) Then
                Return DefaultConnStr
            End If
            Return envValue
        End Function

        Public Function Create() As SqlConnection
            Return New SqlConnection(GetConnectionString())
        End Function

        ' 接続確認用(@@VERSION と DB名を取って例外なく終われば OK)
        Public Sub TestConnection()
            Using conn = Create()
                conn.Open()
                Using cmd As New SqlCommand("SELECT DB_NAME();", conn)
                    Dim dbName = CStr(cmd.ExecuteScalar())
                    Console.WriteLine($"接続DB: {dbName}")
                End Using
            End Using
        End Sub

    End Module

End Namespace
