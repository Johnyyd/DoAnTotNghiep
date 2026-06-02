/* =========================================================================
   SQL SERVER BACKUP / RESTORE JOBS - GMP-WHO
   - Full backup: 17:00 every Saturday
   - Differential backup: 17:00 every Tuesday and Thursday
   - Requires SQL Server Agent and an existing backup directory.
   Docker default backup directory: /var/opt/mssql/backups
   ========================================================================= */

USE [master];
GO

IF DB_ID(N'PharmaceuticalProcessingManagementSystem') IS NULL
BEGIN
    THROW 51000, 'Database PharmaceuticalProcessingManagementSystem does not exist.', 1;
END
GO

ALTER DATABASE [PharmaceuticalProcessingManagementSystem] SET RECOVERY FULL;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RestoreGmpDatabaseFromBackup
    @FullBackupFileName NVARCHAR(260),
    @DifferentialBackupFileName NVARCHAR(260) = NULL,
    @BackupDirectory NVARCHAR(4000) = N'/var/opt/mssql/backups'
AS
BEGIN
    SET NOCOUNT ON;

    IF @FullBackupFileName IS NULL
       OR @FullBackupFileName NOT LIKE N'%.bak'
       OR CHARINDEX(N'..', @FullBackupFileName) > 0
       OR CHARINDEX(N'/', @FullBackupFileName) > 0
       OR CHARINDEX(N'\', @FullBackupFileName) > 0
       OR (@DifferentialBackupFileName IS NOT NULL AND (
            @DifferentialBackupFileName NOT LIKE N'%.bak'
            OR CHARINDEX(N'..', @DifferentialBackupFileName) > 0
            OR CHARINDEX(N'/', @DifferentialBackupFileName) > 0
            OR CHARINDEX(N'\', @DifferentialBackupFileName) > 0
       ))
    BEGIN
        THROW 51001, 'Invalid backup file name.', 1;
    END

    DECLARE @DatabaseName SYSNAME = N'PharmaceuticalProcessingManagementSystem';
    WHILE RIGHT(@BackupDirectory, 1) IN (N'/', N'\')
    BEGIN
        SET @BackupDirectory = LEFT(@BackupDirectory, LEN(@BackupDirectory) - 1);
    END

    DECLARE @FullBackupPath NVARCHAR(4000) = CONCAT(@BackupDirectory, N'/', @FullBackupFileName);
    DECLARE @DifferentialBackupPath NVARCHAR(4000) =
        CASE WHEN @DifferentialBackupFileName IS NULL THEN NULL ELSE CONCAT(@BackupDirectory, N'/', @DifferentialBackupFileName) END;
    DECLARE @Sql NVARCHAR(MAX);

    SET @Sql = N'
ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE ' + QUOTENAME(@DatabaseName) + N'
FROM DISK = @FullBackupPath
WITH REPLACE, ' + CASE WHEN @DifferentialBackupFileName IS NULL THEN N'RECOVERY' ELSE N'NORECOVERY' END + N', CHECKSUM;'
        + CASE WHEN @DifferentialBackupFileName IS NULL THEN N'' ELSE N'
RESTORE DATABASE ' + QUOTENAME(@DatabaseName) + N'
FROM DISK = @DifferentialBackupPath
WITH RECOVERY, CHECKSUM;' END + N'
ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET MULTI_USER;';

    BEGIN TRY
        EXEC sys.sp_executesql
            @Sql,
            N'@FullBackupPath NVARCHAR(4000), @DifferentialBackupPath NVARCHAR(4000)',
            @FullBackupPath = @FullBackupPath,
            @DifferentialBackupPath = @DifferentialBackupPath;
    END TRY
    BEGIN CATCH
        BEGIN TRY
            SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@DatabaseName) + N' SET MULTI_USER;';
            EXEC sys.sp_executesql @Sql;
        END TRY
        BEGIN CATCH
        END CATCH;

        THROW;
    END CATCH
END;
GO

USE [PharmaceuticalProcessingManagementSystem];
GO

IF OBJECT_ID(N'dbo.DatabaseBackupLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DatabaseBackupLog
    (
        BackupLogId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DatabaseBackupLog PRIMARY KEY,
        BackupType NVARCHAR(20) NOT NULL,
        BackupPath NVARCHAR(4000) NOT NULL,
        StartedAt DATETIME2(0) NOT NULL CONSTRAINT DF_DatabaseBackupLog_StartedAt DEFAULT SYSDATETIME(),
        FinishedAt DATETIME2(0) NULL,
        IsSuccess BIT NOT NULL CONSTRAINT DF_DatabaseBackupLog_IsSuccess DEFAULT 0,
        ErrorMessage NVARCHAR(MAX) NULL
    );
END
GO

CREATE OR ALTER PROCEDURE dbo.usp_BackupGmpDatabase
    @BackupType NVARCHAR(20),
    @BackupDirectory NVARCHAR(4000) = N'/var/opt/mssql/backups'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NormalizedBackupType NVARCHAR(20) = UPPER(LTRIM(RTRIM(@BackupType)));

    IF @NormalizedBackupType NOT IN (N'FULL', N'DIFFERENTIAL')
    BEGIN
        THROW 51002, 'BackupType must be FULL or DIFFERENTIAL.', 1;
    END

    DECLARE @DatabaseName SYSNAME = DB_NAME();
    DECLARE @Timestamp CHAR(15) = CONVERT(CHAR(8), GETDATE(), 112) + N'_' + REPLACE(CONVERT(CHAR(8), GETDATE(), 108), N':', N'');
    DECLARE @FileName NVARCHAR(260) =
        CONCAT(@DatabaseName, N'_', LOWER(@NormalizedBackupType), N'_', @Timestamp, N'.bak');
    WHILE RIGHT(@BackupDirectory, 1) IN (N'/', N'\')
    BEGIN
        SET @BackupDirectory = LEFT(@BackupDirectory, LEN(@BackupDirectory) - 1);
    END

    DECLARE @BackupPath NVARCHAR(4000) = CONCAT(@BackupDirectory, N'/', @FileName);
    DECLARE @BackupLogId BIGINT;
    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @BackupName NVARCHAR(300) = CONCAT(@DatabaseName, N' ', @NormalizedBackupType, N' ', @Timestamp);

    INSERT INTO dbo.DatabaseBackupLog (BackupType, BackupPath)
    VALUES (@NormalizedBackupType, @BackupPath);

    SET @BackupLogId = SCOPE_IDENTITY();

    BEGIN TRY
        SET @Sql = N'BACKUP DATABASE ' + QUOTENAME(@DatabaseName) + N'
TO DISK = @BackupPath
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10, NAME = @BackupName'
            + CASE WHEN @NormalizedBackupType = N'DIFFERENTIAL' THEN N', DIFFERENTIAL' ELSE N'' END
            + N';
RESTORE VERIFYONLY FROM DISK = @BackupPath WITH CHECKSUM;';

        EXEC sys.sp_executesql
            @Sql,
            N'@BackupPath NVARCHAR(4000), @BackupName NVARCHAR(300)',
            @BackupPath = @BackupPath,
            @BackupName = @BackupName;

        UPDATE dbo.DatabaseBackupLog
        SET FinishedAt = SYSDATETIME(),
            IsSuccess = 1
        WHERE BackupLogId = @BackupLogId;
    END TRY
    BEGIN CATCH
        UPDATE dbo.DatabaseBackupLog
        SET FinishedAt = SYSDATETIME(),
            IsSuccess = 0,
            ErrorMessage = ERROR_MESSAGE()
        WHERE BackupLogId = @BackupLogId;

        THROW;
    END CATCH
END;
GO

USE [msdb];
GO

DECLARE @DatabaseName SYSNAME = N'PharmaceuticalProcessingManagementSystem';
DECLARE @BackupDirectory NVARCHAR(4000) = N'/var/opt/mssql/backups';
DECLARE @FullJobName SYSNAME = N'GMP - Weekly Full Database Backup';
DECLARE @DiffJobName SYSNAME = N'GMP - Tuesday Thursday Differential Database Backup';
DECLARE @FullBackupCommand NVARCHAR(MAX) =
    N'EXEC dbo.usp_BackupGmpDatabase @BackupType = N''FULL'', @BackupDirectory = N'''
    + REPLACE(@BackupDirectory, N'''', N'''''') + N''';';
DECLARE @DifferentialBackupCommand NVARCHAR(MAX) =
    N'EXEC dbo.usp_BackupGmpDatabase @BackupType = N''DIFFERENTIAL'', @BackupDirectory = N'''
    + REPLACE(@BackupDirectory, N'''', N'''''') + N''';';

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @FullJobName)
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = @FullJobName;
END

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @DiffJobName)
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = @DiffJobName;
END

IF EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = N'GMP - Saturday 17:00 Full Backup')
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'GMP - Saturday 17:00 Full Backup';
END

IF EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = N'GMP - Tuesday Thursday 17:00 Differential Backup')
BEGIN
    EXEC msdb.dbo.sp_delete_schedule @schedule_name = N'GMP - Tuesday Thursday 17:00 Differential Backup';
END

EXEC msdb.dbo.sp_add_job
    @job_name = @FullJobName,
    @enabled = 1,
    @description = N'Full backup for GMP database every Saturday at 17:00.',
    @category_name = N'Database Maintenance';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @FullJobName,
    @step_name = N'Run full backup',
    @subsystem = N'TSQL',
    @database_name = @DatabaseName,
    @command = @FullBackupCommand,
    @retry_attempts = 2,
    @retry_interval = 5;

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'GMP - Saturday 17:00 Full Backup',
    @enabled = 1,
    @freq_type = 8,
    @freq_interval = 64,
    @freq_recurrence_factor = 1,
    @active_start_time = 170000;

EXEC msdb.dbo.sp_attach_schedule
    @job_name = @FullJobName,
    @schedule_name = N'GMP - Saturday 17:00 Full Backup';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = @FullJobName;

EXEC msdb.dbo.sp_add_job
    @job_name = @DiffJobName,
    @enabled = 1,
    @description = N'Differential backup for GMP database every Tuesday and Thursday at 17:00.',
    @category_name = N'Database Maintenance';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @DiffJobName,
    @step_name = N'Run differential backup',
    @subsystem = N'TSQL',
    @database_name = @DatabaseName,
    @command = @DifferentialBackupCommand,
    @retry_attempts = 2,
    @retry_interval = 5;

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'GMP - Tuesday Thursday 17:00 Differential Backup',
    @enabled = 1,
    @freq_type = 8,
    @freq_interval = 20,
    @freq_recurrence_factor = 1,
    @active_start_time = 170000;

EXEC msdb.dbo.sp_attach_schedule
    @job_name = @DiffJobName,
    @schedule_name = N'GMP - Tuesday Thursday 17:00 Differential Backup';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = @DiffJobName;
GO
