# Copyright (c) 2013-2015 VMware, Inc.
require "pp"
require "securerandom"
require "uri"

module VCAP
  module Services
    module MSSQL
      module Util
        VALID_CREDENTIAL_CHARACTERS = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a

        def log(*args) #:nodoc:
          args.unshift(Time.now)
          PP::pp(args.compact, $stdout, 120)
        end

        def debug(*args) #:nodoc:
          log(*args)
        end

        def trace(*args) #:nodoc:
          log(*args)
        end

        def generate_credential(length=12)
          Array.new(length) { VALID_CREDENTIAL_CHARACTERS[rand(VALID_CREDENTIAL_CHARACTERS.length)] }.join
        end
      end
    end
  end
end