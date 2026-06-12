Imports System

Namespace Common

    ' 業務例外(SQL側 THROW と区別したい場合に使う)
    '   現場では「業務エラー」と「システムエラー」を分けて画面表示・ログ出力する
    '   その分岐ポイントとしてこの例外を使う
    Public Class AppException
        Inherits Exception

        Public ReadOnly Property ErrorCode As Integer

        Public Sub New(message As String)
            MyBase.New(message)
        End Sub

        Public Sub New(errorCode As Integer, message As String)
            MyBase.New(message)
            Me.ErrorCode = errorCode
        End Sub

        Public Sub New(errorCode As Integer, message As String, inner As Exception)
            MyBase.New(message, inner)
            Me.ErrorCode = errorCode
        End Sub

    End Class

End Namespace
