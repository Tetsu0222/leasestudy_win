Imports System
Imports LeaseStudyApp.Data
Imports LeaseStudyApp.UI

' =============================================================
' エントリポイント
'   - 接続確認 → メニュー表示の流れ
'   - 業務ロジックは Services/Repositories を経由してストアドへ
' =============================================================
Module Program

    Sub Main(args As String())
        Console.OutputEncoding = System.Text.Encoding.UTF8
        Console.WriteLine("=== LeaseStudyApp (リース業務想定 学習用) ===")
        Console.WriteLine($"Runtime : .NET {Environment.Version}")
        Console.WriteLine($"OS      : {Environment.OSVersion}")
        Console.WriteLine()

        ' 1. 接続確認
        Try
            SqlConnectionFactory.TestConnection()
            Console.WriteLine("--- SQL Server 接続成功 ---")
            Console.WriteLine()
        Catch ex As Exception
            Console.WriteLine("!!! SQL Server 接続失敗 !!!")
            Console.WriteLine(ex.Message)
            Environment.ExitCode = 1
            Return
        End Try

        ' 2. メニュー起動
        Dim menu As New MenuPresenter()
        menu.Run()
    End Sub

End Module
