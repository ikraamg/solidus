class ActionMailer::MessageDelivery
  # This fixes an issue where the Tenant is lost with the thread when using deliver_later
  def deliver_later
    deliver_now
  rescue StandardError
      nil
  end
end
