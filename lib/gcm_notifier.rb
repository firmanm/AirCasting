require 'gcm'

class GcmNotifier
  def initialize(gcm_token, session_id)
    @gcm_token = gcm_token
    @session_id = session_id
  end

  def call
    return unless gcm_token

    gcm = GCM.new(ENV["GCM_API_KEY"])
    options = { data: { session_id: session_id },
                collapse_key: "fixed_session_update"
              }

    response = gcm.send([gcm_token.to_s], options)

    Rails.logger.info("============================================")
    Rails.logger.info(gcm.to_s)
    Rails.logger.info(ENV["GCM_API_KEY"].to_s)
    Rails.logger.info(response)
    Rails.logger.info("============================================")
  end

  private
  attr_reader :gcm_token, :session_id
end
