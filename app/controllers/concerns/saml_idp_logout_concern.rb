require 'saml_idp/logout_response_builder'

module SamlIdpLogoutConcern
  extend ActiveSupport::Concern

  private

  def sign_out_with_flash
    track_logout_event
    sign_out if user_signed_in?
    flash[:success] = t('devise.sessions.signed_out')
    redirect_to root_url
  end

  def handle_valid_sp_logout_request
    render_template_for(
      Base64.strict_encode64(logout_response),
      saml_request.response_url,
      'SAMLResponse',
    )
    sign_out if user_signed_in?
  end

  def logout_response
    response = encode_response(
      current_user,
      signature: saml_response_signature_options,
    )
    # rubocop:disable Metrics/LineLength
    Rails.logger.info "#{'~' * 10} Response #{'~' * 10}\n#{response}\n#{'~' * 10} Done with response #{'~' * 10}"
    # rubocop:enable Metrics/LineLength
    response
  end

  def track_logout_event
    sp_initiated = saml_request.present?
    analytics.track_event(
      Analytics::LOGOUT_INITIATED,
      sp_initiated: sp_initiated,
      oidc: false,
      saml_request_valid: sp_initiated ? valid_saml_request? : true,
    )
  end

  def saml_response_signature_options
    endpoint = SamlEndpoint.new(request)
    {
      x509_certificate: endpoint.x509_certificate,
      secret_key: endpoint.secret_key,
    }
  end
end
