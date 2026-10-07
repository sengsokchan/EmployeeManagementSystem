-- Creates the tables this API uses in the database you are already connected to.
-- Safe to run again: a table that already exists is left unchanged.
-- After this, run seed.sql for roles, permissions, and demo users.
-- This script does not create a login or store a password.

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Branches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Branches (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(120) NOT NULL,
        Address NVARCHAR(300) NULL,
        Latitude DECIMAL(10, 7) NULL,
        Longitude DECIMAL(10, 7) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

IF OBJECT_ID(N'dbo.Departments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Departments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(120) NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

IF OBJECT_ID(N'dbo.Positions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Positions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DepartmentId INT NOT NULL,
        Title NVARCHAR(120) NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Positions_Departments FOREIGN KEY (DepartmentId) REFERENCES dbo.Departments(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.Employees', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Employees (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeCode NVARCHAR(20) NOT NULL UNIQUE,
        FullName NVARCHAR(180) NOT NULL,
        Gender NVARCHAR(20) NOT NULL,
        DateOfBirth DATE NOT NULL,
        Email NVARCHAR(180) NOT NULL UNIQUE,
        Phone NVARCHAR(40) NULL,
        DepartmentId INT NOT NULL,
        PositionId INT NOT NULL,
        BranchId INT NOT NULL,
        ManagerId INT NULL,
        ContractType NVARCHAR(60) NOT NULL,
        JoinDate DATE NOT NULL,
        ResignDate DATE NULL,
        Status NVARCHAR(30) NOT NULL,
        EmergencyContact NVARCHAR(180) NULL,
        EducationHistory NVARCHAR(MAX) NULL,
        WorkExperience NVARCHAR(MAX) NULL,
        BasicSalary DECIMAL(18, 2) NOT NULL DEFAULT 500,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NULL,
        CONSTRAINT FK_Employees_Departments FOREIGN KEY (DepartmentId) REFERENCES dbo.Departments(Id),
        CONSTRAINT FK_Employees_Positions FOREIGN KEY (PositionId) REFERENCES dbo.Positions(Id),
        CONSTRAINT FK_Employees_Branches FOREIGN KEY (BranchId) REFERENCES dbo.Branches(Id),
        CONSTRAINT FK_Employees_Manager FOREIGN KEY (ManagerId) REFERENCES dbo.Employees(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(80) NOT NULL UNIQUE
    );
END
GO

IF OBJECT_ID(N'dbo.Permissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Permissions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Code NVARCHAR(120) NOT NULL UNIQUE,
        Description NVARCHAR(240) NOT NULL
    );
END
GO

IF OBJECT_ID(N'dbo.RolePermissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePermissions (
        RoleId INT NOT NULL,
        PermissionId INT NOT NULL,
        PRIMARY KEY (RoleId, PermissionId),
        CONSTRAINT FK_RolePermissions_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(Id),
        CONSTRAINT FK_RolePermissions_Permissions FOREIGN KEY (PermissionId) REFERENCES dbo.Permissions(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NULL,
        RoleId INT NOT NULL,
        Email NVARCHAR(180) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(400) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        MustChangePassword BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Users_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(Id),
        CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.Attendance', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Attendance (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        WorkDate DATE NOT NULL,
        CheckIn DATETIME2 NULL,
        CheckOut DATETIME2 NULL,
        WorkMode NVARCHAR(40) NOT NULL,
        Status NVARCHAR(40) NOT NULL,
        Latitude DECIMAL(10, 7) NULL,
        Longitude DECIMAL(10, 7) NULL,
        LateMinutes INT NOT NULL DEFAULT 0,
        OvertimeMinutes INT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Attendance_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(Id),
        CONSTRAINT UQ_Attendance_EmployeeDate UNIQUE (EmployeeId, WorkDate)
    );
END
GO

IF OBJECT_ID(N'dbo.LeaveRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LeaveRequests (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        LeaveType NVARCHAR(60) NOT NULL,
        StartDate DATE NOT NULL,
        EndDate DATE NOT NULL,
        IsHalfDay BIT NOT NULL DEFAULT 0,
        Reason NVARCHAR(600) NOT NULL,
        AttachmentUrl NVARCHAR(500) NULL,
        Status NVARCHAR(40) NOT NULL,
        ManagerComment NVARCHAR(600) NULL,
        HrComment NVARCHAR(600) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt DATETIME2 NULL,
        CONSTRAINT FK_LeaveRequests_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.LeaveBalances', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LeaveBalances (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        LeaveType NVARCHAR(60) NOT NULL,
        [Year] INT NOT NULL,
        EntitledDays DECIMAL(6, 1) NOT NULL,
        CONSTRAINT FK_LeaveBalances_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(Id),
        CONSTRAINT UQ_LeaveBalances_EmployeeTypeYear UNIQUE (EmployeeId, LeaveType, [Year])
    );
END
GO

IF OBJECT_ID(N'dbo.Payroll', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payroll (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeId INT NOT NULL,
        PeriodStart DATE NOT NULL,
        PeriodEnd DATE NOT NULL,
        BasicSalary DECIMAL(18, 2) NOT NULL,
        Allowance DECIMAL(18, 2) NOT NULL DEFAULT 0,
        Bonus DECIMAL(18, 2) NOT NULL DEFAULT 0,
        Tax DECIMAL(18, 2) NOT NULL DEFAULT 0,
        Deduction DECIMAL(18, 2) NOT NULL DEFAULT 0,
        OvertimePay DECIMAL(18, 2) NOT NULL DEFAULT 0,
        NetSalary AS (BasicSalary + Allowance + Bonus + OvertimePay - Tax - Deduction) PERSISTED,
        Status NVARCHAR(40) NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_Payroll_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.AuditLogs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditLogs (
        Id BIGINT IDENTITY(1,1) PRIMARY KEY,
        UserId INT NULL,
        Action NVARCHAR(120) NOT NULL,
        EntityName NVARCHAR(120) NOT NULL,
        EntityId NVARCHAR(80) NULL,
        Details NVARCHAR(MAX) NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

IF OBJECT_ID(N'dbo.LoginSecurity', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LoginSecurity (
        Email NVARCHAR(180) NOT NULL PRIMARY KEY,
        UserId INT NULL,
        FailedAccessCount INT NOT NULL DEFAULT 0,
        LockoutCycles INT NOT NULL DEFAULT 0,
        LockoutEndAt DATETIME2 NULL,
        RequiresAdminReset BIT NOT NULL DEFAULT 0,
        UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_LoginSecurity_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(Id)
    );
END
GO

IF OBJECT_ID(N'dbo.sp_GetDashboardSummary', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetDashboardSummary;
GO
CREATE PROCEDURE dbo.sp_GetDashboardSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(*) FROM Employees WHERE Status = 'Active') AS TotalEmployees,
        (SELECT COUNT(*) FROM Attendance WHERE WorkDate = CONVERT(date, SYSUTCDATETIME()) AND CheckIn IS NOT NULL) AS TodayAttendance,
        (SELECT COUNT(*) FROM Attendance WHERE WorkDate = CONVERT(date, SYSUTCDATETIME()) AND LateMinutes > 0) AS LateEmployees,
        (SELECT COUNT(*) FROM LeaveRequests WHERE Status IN ('Pending', 'ManagerApproved')) AS PendingLeaveRequests;
END;
GO

IF OBJECT_ID(N'dbo.sp_CreateLeaveRequest', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateLeaveRequest;
GO
CREATE PROCEDURE dbo.sp_CreateLeaveRequest
    @EmployeeId INT,
    @LeaveType NVARCHAR(60),
    @StartDate DATE,
    @EndDate DATE,
    @IsHalfDay BIT,
    @Reason NVARCHAR(600)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO LeaveRequests (EmployeeId, LeaveType, StartDate, EndDate, IsHalfDay, Reason, Status)
    VALUES (@EmployeeId, @LeaveType, @StartDate, @EndDate, @IsHalfDay, @Reason, 'Pending');

    SELECT SCOPE_IDENTITY() AS LeaveRequestId;
END;
GO

IF OBJECT_ID(N'dbo.sp_UpsertAttendance', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpsertAttendance;
GO
CREATE PROCEDURE dbo.sp_UpsertAttendance
    @EmployeeId INT,
    @WorkDate DATE,
    @CheckIn DATETIME2 = NULL,
    @CheckOut DATETIME2 = NULL,
    @WorkMode NVARCHAR(40),
    @Latitude DECIMAL(10,7) = NULL,
    @Longitude DECIMAL(10,7) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Attendance WHERE EmployeeId = @EmployeeId AND WorkDate = @WorkDate)
    BEGIN
        UPDATE Attendance
        SET CheckOut = COALESCE(@CheckOut, CheckOut),
            Status = CASE WHEN COALESCE(@CheckOut, CheckOut) IS NULL THEN Status ELSE 'Present' END
        WHERE EmployeeId = @EmployeeId AND WorkDate = @WorkDate;
    END
    ELSE
    BEGIN
        INSERT INTO Attendance (EmployeeId, WorkDate, CheckIn, WorkMode, Status, Latitude, Longitude, LateMinutes)
        VALUES (
            @EmployeeId,
            @WorkDate,
            @CheckIn,
            @WorkMode,
            CASE WHEN DATEPART(HOUR, @CheckIn) > 8 OR (DATEPART(HOUR, @CheckIn) = 8 AND DATEPART(MINUTE, @CheckIn) > 30) THEN 'Late' ELSE 'Present' END,
            @Latitude,
            @Longitude,
            CASE WHEN @CheckIn > DATEADD(MINUTE, 510, CAST(@WorkDate AS DATETIME2)) THEN DATEDIFF(MINUTE, DATEADD(MINUTE, 510, CAST(@WorkDate AS DATETIME2)), @CheckIn) ELSE 0 END
        );
    END
END;
GO

IF OBJECT_ID(N'dbo.sp_ResetLoginSecurity', N'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ResetLoginSecurity;
GO
CREATE PROCEDURE dbo.sp_ResetLoginSecurity
    @Email NVARCHAR(180)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM LoginSecurity
    WHERE Email = LOWER(LTRIM(RTRIM(@Email)));
END;
GO
