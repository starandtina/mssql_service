module VCAP::Services::MSSQL::Backup
  include VCAP::Services::Base::AsyncJob::Backup

  class BaseBackupJob < BackupJob

    def perform
      begin
        required_options :service_id
        @name = options["service_id"]
        @logger.info "Launch job: #{self.class} for #{name}"

        lock = create_lock

        lock.lock do
          result = execute
          @logger.info "Result of the stored procedure: #{result}"
          completed(Yajl::Encoder.encode({:result => :ok}))
          @logger.info "Complete job: #{self.class} for #{name}"
        end
      rescue => e
        handle_error(e)
      ensure
        set_status({:complete_time => Time.now.to_s})
      end
    end

    def execute
      # TODO: HOOK
    end
  end

end