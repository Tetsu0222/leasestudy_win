Imports System
Imports System.Collections.Generic
Imports System.Data
Imports Microsoft.Data.SqlClient
Imports LeaseStudyApp.Data
Imports LeaseStudyApp.Models

Namespace Repositories
    ' 債権まわりのストアドプロシージャ呼び出しをラップする層
    '   - 業務ロジック自体は書かない(全部ストアド側)
    '   - VB.Net 側は「パラメータを詰める / 結果を受け取る」だけ
    Public Class DebtRepository

        ' 債権一覧取得
        Public Function GetDebtList(
            Optional receivableId As Integer? = Nothing,
            Optional contractId As Integer? = Nothing,
            Optional status As Integer? = Nothing,
            Optional dueDate As Date? = Nothing
        ) As List(Of Debt)

            Dim list As New List(Of Debt)()

            Using conn = SqlConnectionFactory.Create()
                conn.Open()
                Using cmd As New SqlCommand("dbo.usp_GetDebtList", conn)
                    cmd.CommandType = CommandType.StoredProcedure

                    cmd.Parameters.Add("@ReceivableId", SqlDbType.Int).Value = If(receivableId.HasValue, CObj(receivableId.Value), DBNull.Value)
                    cmd.Parameters.Add("@ContractId", SqlDbType.Int).Value = If(contractId.HasValue, CObj(contractId.Value), DBNull.Value)
                    cmd.Parameters.Add("@Status", SqlDbType.Int).Value = If(status.HasValue, CObj(status.Value), DBNull.Value)
                    cmd.Parameters.Add("@DueDate", SqlDbType.Date).Value = If(dueDate.HasValue, CObj(dueDate.Value), DBNull.Value)

                    Using reader = cmd.ExecuteReader()
                        While reader.Read()
                            Dim oPaymentId As Integer = reader.GetOrdinal("PaymentId")
                            Dim oPaymentDate As Integer = reader.GetOrdinal("PaymentDate")
                            Dim oPaymentAmount As Integer = reader.GetOrdinal("PaymentAmount")

                            list.Add(New Debt() With {
                                .ReceivableId = reader.GetInt32(reader.GetOrdinal("ReceivableId")),
                                .ContractId = reader.GetInt32(reader.GetOrdinal("ContractId")),
                                .DueDate = reader.GetDateTime(reader.GetOrdinal("DueDate")),
                                .DueAmount = reader.GetDecimal(reader.GetOrdinal("DueAmount")),
                                .PaidAmount = reader.GetDecimal(reader.GetOrdinal("PaidAmount")),
                                .Status = reader.GetInt32(reader.GetOrdinal("Status")),
                                .StatusName = reader.GetString(reader.GetOrdinal("StatusName")),
                                .PaymentId = If(reader.IsDBNull(oPaymentId), CType(Nothing, Integer?), reader.GetInt32(oPaymentId)),
                                .PaymentDate = If(reader.IsDBNull(oPaymentDate), CType(Nothing, Date?), reader.GetDateTime(oPaymentDate)),
                                .PaymentAmount = If(reader.IsDBNull(oPaymentAmount), CType(Nothing, Decimal?), reader.GetDecimal(oPaymentAmount))
                            })
                        End While
                    End Using
                End Using
            End Using

            Return list
        End Function

        ' 請求書発行
        Public Function IssueBilling(receivableId As Integer) As Boolean
            Using conn = SqlConnectionFactory.Create()
                conn.Open()
                Using cmd As New SqlCommand("dbo.usp_IssueBilling", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.Add("@ReceivableId", SqlDbType.Int).Value = receivableId
                    cmd.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        ' 入金登録
        Public Function RecordPayment(receivableId As Integer, paymentAmount As Decimal) As Boolean
            Using conn = SqlConnectionFactory.Create()
                conn.Open()
                Using cmd As New SqlCommand("dbo.usp_RecordPayment", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.Add("@ReceivableId", SqlDbType.Int).Value = receivableId
                    cmd.Parameters.Add("@PaymentAmount", SqlDbType.Decimal).Value = paymentAmount
                    cmd.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

    End Class

End Namespace