# Copyright (c) 2013-2015 VMware, Inc.

class VCAP::Services::MSSQL::MSSQLError < VCAP::Services::Base::Error::ServiceError
    MSSQL_DISK_FULL = [31001, HTTP_INTERNAL, 'Node disk is full.']
    MSSQL_CONFIG_NOT_FOUND = [31002, HTTP_NOT_FOUND, 'MSSQL configuration %s not found.']
    MSSQL_CRED_NOT_FOUND = [31003, HTTP_NOT_FOUND, 'MSSQL credential %s not found.']
    MSSQL_LOCAL_DB_ERROR = [31004, HTTP_INTERNAL, 'MSSQL node local db error.']
    MSSQL_INVALID_PLAN = [31005, HTTP_INTERNAL, 'Invalid plan %s.']
    MSSQL_BAD_SERIALIZED_DATA = [31007, HTTP_BAD_REQUEST, "File %s can't be verified"]
end
