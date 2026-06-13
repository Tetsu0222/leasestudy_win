Imports System

Namespace Models

    ' 債権一覧で使う表示用モデル
    Public Class Debt
        Public Property ReceivableId As Integer
        Public Property ContractId As Integer
        Public Property DueDate As Date
        Public Property DueAmount As Decimal
        Public Property PaidAmount As Decimal
        Public Property Status As Integer
        Public Property StatusName As String = ""
        Public Property PaymentId As Integer?
        Public Property PaymentDate As Date?
        Public Property PaymentAmount As Decimal?
    End Class

End Namespace
