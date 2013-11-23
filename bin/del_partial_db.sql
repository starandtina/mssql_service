:On Error exit

-- drop partially contained database
USE MASTER
GO

ALTER DATABASE [$(DatabaseName)]
  SET SINGLE_USER 
  WITH ROLLBACK IMMEDIATE
GO

DROP DATABASE [$(DatabaseName)]
GO
