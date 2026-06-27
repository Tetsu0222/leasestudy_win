Imports System
Imports Microsoft.EntityFrameworkCore
Imports LeaseStudyApp.Models

Namespace Data

    Public Class LeaseStudyDbContext
        Inherits DbContext

        Private ReadOnly _connectionString As String
        Public Property Contracts As DbSet(Of Contract)

        Public Sub New()
            _connectionString = SqlConnectionFactory.GetConnectionString()
        End Sub

        Protected Overrides Sub OnConfiguring(optionsBuilder As DbContextOptionsBuilder)
            optionsBuilder.UseSqlServer(_connectionString)
        End Sub

        Protected Overrides Sub OnModelCreating(modelBuilder As ModelBuilder)
            Dim contract = modelBuilder.Entity(Of Contract)()
            contract.ToTable("T_Contract")
            contract.HasKey(Function(c) c.ContractId)

            ' Contract は元々ストアド結果用の表示モデルで、JOIN/CASE 由来の列を含む。
            ' T_Contract テーブルに存在しない列は EF Core から見えなくする。
            contract.Ignore(Function(c) c.ContractNo)
            contract.Ignore(Function(c) c.CustomerCode)
            contract.Ignore(Function(c) c.CustomerName)
            contract.Ignore(Function(c) c.ContractDate)
            contract.Ignore(Function(c) c.StartDate)
            contract.Ignore(Function(c) c.EndDate)
            contract.Ignore(Function(c) c.LeaseMonths)
            contract.Ignore(Function(c) c.TotalAmount)
            contract.Ignore(Function(c) c.MonthlyFee)
            contract.Ignore(Function(c) c.Status)
            contract.Ignore(Function(c) c.StatusName)
        End Sub

    End Class

End Namespace
