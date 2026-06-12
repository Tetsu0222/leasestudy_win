Imports System

Namespace Models

    ' 契約一覧で使う表示用モデル
    Public Class Contract
        Public Property ContractId As Integer
        Public Property ContractNo As String = ""
        Public Property CustomerCode As String = ""
        Public Property CustomerName As String = ""
        Public Property ContractDate As Date
        Public Property StartDate As Date
        Public Property EndDate As Date
        Public Property LeaseMonths As Integer
        Public Property TotalAmount As Decimal
        Public Property MonthlyFee As Decimal
        Public Property Status As Integer
        Public Property StatusName As String = ""
    End Class

End Namespace
