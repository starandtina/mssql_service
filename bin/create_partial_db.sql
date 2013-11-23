:On Error exit

-- creating a new database as a contained database:
CREATE DATABASE [$(DatabaseName)]
    CONTAINMENT=PARTIAL
GO
