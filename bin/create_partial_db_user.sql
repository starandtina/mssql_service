:On Error exit

-- create contained database user with the role of db_owner
USE [$(DatabaseName)]
GO
CREATE USER [$(UserName)] WITH PASSWORD=N'$(Password)'
ALTER ROLE [db_owner] ADD MEMBER [$(UserName)]
GO
