ActsAsTenant.configure do |config|
  config.require_tenant = true
  config.job_scope = -> { all }
end
