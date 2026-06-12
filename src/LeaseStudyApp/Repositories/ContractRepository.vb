Imports System
Imports System.Collections.Generic
Imports System.Data
Imports Microsoft.Data.SqlClient
Imports LeaseStudyApp.Data
Imports LeaseStudyApp.Models

Namespace Repositories

    ' 契約まわりのストアドプロシージャ呼び出しをラップする層
    '   - 業務ロジック自体は書かない(全部ストアド側)
    '   - VB.Net 側は「パラメータを詰める / 結果を受け取る」だけ
    Public Class ContractRepository

        ' 契約登録 → 新規 ContractId を返す
        Public Function CreateContract(
            customerId As Integer,
            contractDate As Date,
            startDate As Date,
            leaseMonths As Integer,
            interestRate As Decimal,
            itemId As Integer,
            quantity As Integer,
            unitPrice As Decimal
        ) As Integer

            Using conn = SqlConnectionFactory.Create()
                conn.Open()
                Using cmd As New SqlCommand("dbo.usp_CreateContract", conn)
                    cmd.CommandType = CommandType.StoredProcedure

                    cmd.Parameters.Add("@CustomerId", SqlDbType.Int).Value = customerId
                    cmd.Parameters.Add("@ContractDate", SqlDbType.Date).Value = contractDate
                    cmd.Parameters.Add("@StartDate", SqlDbType.Date).Value = startDate
                    cmd.Parameters.Add("@LeaseMonths", SqlDbType.Int).Value = leaseMonths
                    cmd.Parameters.Add("@InterestRate", SqlDbType.Decimal).Value = interestRate
                    cmd.Parameters.Add("@ItemId", SqlDbType.Int).Value = itemId
                    cmd.Parameters.Add("@Quantity", SqlDbType.Int).Value = quantity
                    cmd.Parameters.Add("@UnitPrice", SqlDbType.Decimal).Value = unitPrice

                    Dim outId As New SqlParameter("@NewContractId", SqlDbType.Int) With {
                        .Direction = ParameterDirection.Output
                    }
                    cmd.Parameters.Add(outId)

                    cmd.ExecuteNonQuery()
                    Return CInt(outId.Value)
                End Using
            End Using
        End Function

        ' リース料試算
        Public Sub CalculateLeaseFee(
            totalAmount As Decimal,
            leaseMonths As Integer,
            interestRate As Decimal,
            <Runtime.InteropServices.Out> ByRef monthlyFee As Decimal,
            <Runtime.InteropServices.Out> ByRef totalLeaseFee As Decimal,
            <Runtime.InteropServices.Out> ByRef totalInterest As Decimal
        )
            Using conn = SqlConnectionFactory.Create()
                conn.Open()
                Using cmd As New SqlCommand("dbo.usp_CalculateLeaseFee", conn)
                    cmd.CommandType = CommandType.StoredProcedure

                    cmd.Parameters.Add("@TotalAmount", SqlDbType.Decimal).Value = totalAmount
                    cmd.Parameters.Add("@LeaseMonths", SqlDbType.Int).Value = leaseMonths
                    cmd.Parameters.Add("@InterestRate", SqlDbType.Decimal).Value = interestRate

                    Dim outMonthly As New SqlParameter("@MonthlyFee", SqlDbType.Decimal) With {
                        .Direction = ParameterDirection.Output, .Precision = 15, .Scale = 0
                    }
                    Dim outTotal As New SqlParameter("@TotalLeaseFee", SqlDbType.Decimal) With {
                        .Direction = ParameterDirection.Output, .Precision = 15, .Scale = 0
                    }
                    Dim outInterest As New SqlParameter("@TotalInterest", SqlDbType.Decimal) With {
                        .Direction = ParameterDirection.Output, .Precision = 15, .Scale = 0
                    }
                    cmd.Parameters.Add(outMonthly)
                    cmd.Parameters.Add(outTotal)
                    cmd.Parameters.Add(outInterest)

                    cmd.ExecuteNonQuery()

                    monthlyFee = CDec(outMonthly.Value)
                    totalLeaseFee = CDec(outTotal.Value)
                    totalInterest = CDec(outInterest.Value)
                End Using
            End Using
        End Sub

        ' 契約一覧
        Public Function GetContractList(
            Optional customerId As Integer? = Nothing,
            Optional status As Integer? = Nothing,
            Optional startDateFrom As Date? = Nothing,
            Optional startDateTo As Date? = Nothing
        ) As List(Of Contract)

            Dim result As New List(Of Contract)

            Using conn = SqlConnectionFactory.Create()
                conn.Open()
                Using cmd As New SqlCommand("dbo.usp_GetContractList", conn)
                    cmd.CommandType = CommandType.StoredProcedure

                    cmd.Parameters.Add("@CustomerId", SqlDbType.Int).Value =
                        If(customerId.HasValue, CObj(customerId.Value), DBNull.Value)
                    cmd.Parameters.Add("@Status", SqlDbType.Int).Value =
                        If(status.HasValue, CObj(status.Value), DBNull.Value)
                    cmd.Parameters.Add("@StartDateFrom", SqlDbType.Date).Value =
                        If(startDateFrom.HasValue, CObj(startDateFrom.Value), DBNull.Value)
                    cmd.Parameters.Add("@StartDateTo", SqlDbType.Date).Value =
                        If(startDateTo.HasValue, CObj(startDateTo.Value), DBNull.Value)

                    Using reader = cmd.ExecuteReader()
                        While reader.Read()
                            result.Add(New Contract With {
                                .ContractId = reader.GetInt32(reader.GetOrdinal("ContractId")),
                                .ContractNo = reader.GetString(reader.GetOrdinal("ContractNo")),
                                .CustomerCode = reader.GetString(reader.GetOrdinal("CustomerCode")),
                                .CustomerName = reader.GetString(reader.GetOrdinal("CustomerName")),
                                .ContractDate = reader.GetDateTime(reader.GetOrdinal("ContractDate")),
                                .StartDate = reader.GetDateTime(reader.GetOrdinal("StartDate")),
                                .EndDate = reader.GetDateTime(reader.GetOrdinal("EndDate")),
                                .LeaseMonths = reader.GetInt32(reader.GetOrdinal("LeaseMonths")),
                                .TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalAmount")),
                                .MonthlyFee = reader.GetDecimal(reader.GetOrdinal("MonthlyFee")),
                                .Status = reader.GetInt32(reader.GetOrdinal("Status")),
                                .StatusName = reader.GetString(reader.GetOrdinal("StatusName"))
                            })
                        End While
                    End Using
                End Using
            End Using

            Return result
        End Function

    End Class

End Namespace
