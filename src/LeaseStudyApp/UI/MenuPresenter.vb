Imports System
Imports LeaseStudyApp.Repositories

Namespace UI

    ' コンソールメニュー(WebでいうところのController相当の入口)
    '   学習用の最小セット:
    '     1. 契約一覧
    '     2. リース料試算
    '     3. 契約登録
    '     0. 終了
    Public Class MenuPresenter

        Private ReadOnly _contractRepo As New ContractRepository()
        Private ReadOnly _debtRepo As New DebtRepository()

        Public Sub Run()
            Do
                Console.WriteLine()
                Console.WriteLine("======== メニュー ========")
                Console.WriteLine("  1) 契約一覧")
                Console.WriteLine("  2) リース料試算")
                Console.WriteLine("  3) 契約登録")
                Console.WriteLine("  4) 債権管理")
                Console.WriteLine("  0) 終了")
                Console.Write("選択 > ")
                Dim input = Console.ReadLine()

                Try
                    Select Case input
                        Case "1" : ShowContractList()
                        Case "2" : SimulateLeaseFee()
                        Case "3" : CreateContract()
                        Case "4" : ManageDebt()
                        Case "0" : Return
                        Case Else : Console.WriteLine("無効な選択です。")
                    End Select
                Catch ex As Exception
                    Console.WriteLine("[エラー] " & ex.Message)
                End Try
            Loop
        End Sub

        Private Sub ShowContractList()
            Dim list = _contractRepo.GetContractList()
            If list.Count = 0 Then
                Console.WriteLine("契約はまだありません。")
                Return
            End If

            Console.WriteLine()
            Console.WriteLine("契約No        顧客                       開始        満了        月額         ステータス")
            Console.WriteLine(New String("-"c, 90))
            For Each c In list
                Console.WriteLine($"{c.ContractNo,-12} {c.CustomerName,-25} {c.StartDate:yyyy-MM-dd} {c.EndDate:yyyy-MM-dd} {c.MonthlyFee,12:N0} {c.StatusName}")
            Next
        End Sub

        Private Sub SimulateLeaseFee()
            Console.Write("物件価格合計(円) > ")
            Dim total = CDec(Console.ReadLine())
            Console.Write("リース期間(月) > ")
            Dim months = CInt(Console.ReadLine())
            Console.Write("年利率(例: 0.035) > ")
            Dim rate = CDec(Console.ReadLine())

            Dim monthly, totalFee, interest As Decimal
            _contractRepo.CalculateLeaseFee(total, months, rate, monthly, totalFee, interest)

            Console.WriteLine($"月額リース料 : {monthly,15:N0} 円")
            Console.WriteLine($"リース料総額 : {totalFee,15:N0} 円")
            Console.WriteLine($"利息相当額   : {interest,15:N0} 円")
        End Sub

        Private Sub CreateContract()
            Console.Write("顧客ID > ")
            Dim customerId = CInt(Console.ReadLine())
            Console.Write("契約締結日 (yyyy-MM-dd) > ")
            Dim contractDate = Date.Parse(Console.ReadLine())
            Console.Write("リース開始日 (yyyy-MM-dd) > ")
            Dim startDate = Date.Parse(Console.ReadLine())
            Console.Write("リース期間(月) > ")
            Dim months = CInt(Console.ReadLine())
            Console.Write("年利率(例: 0.035) > ")
            Dim rate = CDec(Console.ReadLine())
            Console.Write("物件ID > ")
            Dim itemId = CInt(Console.ReadLine())
            Console.Write("数量 > ")
            Dim qty = CInt(Console.ReadLine())
            Console.Write("単価(円) > ")
            Dim unitPrice = CDec(Console.ReadLine())

            Dim newId = _contractRepo.CreateContract(
                customerId, contractDate, startDate, months, rate,
                itemId, qty, unitPrice)

            Console.WriteLine($"契約登録完了。 新規ContractId = {newId}")
        End Sub

        Private Sub ManageDebt()
            Console.WriteLine("債権管理機能が選択されました。")
            Do
                Console.WriteLine()
                Console.WriteLine("======== メニュー ========")
                Console.WriteLine("  1) 債権情報一覧")
                Console.WriteLine("  2) 請求登録")
                Console.WriteLine("  3) 入金登録")
                Console.WriteLine("  0) 終了")
                Console.Write("選択 > ")
                Dim input = Console.ReadLine()

                Try
                    Select Case input
                        Case "1" : ShowDebtList()
                        Case "2" : RegisterBilling()
                        Case "3" : RegisterPayment()
                        Case "0" : Return
                        Case Else : Console.WriteLine("無効な選択です。")
                    End Select
                Catch ex As Exception
                    Console.WriteLine("[エラー] " & ex.Message)
                End Try
            Loop
        End Sub

        Private Sub ShowDebtList()
            Console.WriteLine("[未実装] 債権情報一覧")
        End Sub

        Private Sub RegisterBilling()
            Console.WriteLine("[未実装] 請求登録")
        End Sub

        Private Sub RegisterPayment()
            Console.WriteLine("[未実装] 入金登録")
        End Sub

    End Class

End Namespace
