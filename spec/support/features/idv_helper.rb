module IdvHelper
  def self.included(base)
    base.class_eval { include JavascriptDriverHelper }
  end

  def max_attempts_less_one
    idv_max_attempts - 1
  end

  def idv_max_attempts
    Throttle::THROTTLE_CONFIG[:idv_resolution][:max_attempts]
  end

  def user_password
    Features::SessionHelper::VALID_PASSWORD
  end

  def fill_out_phone_form_ok(phone = '415-555-0199')
    fill_in :idv_phone_form_phone, with: phone
  end

  # Fill out the phone form with a phone that's already been confirmed so the app will skip sending
  # the token it would have to send for a new, unconfirmed number
  def fill_out_phone_form_mfa_phone(user)
    fill_out_phone_form_ok(MfaContext.new(user).phone_configurations.first.phone)
  end

  def fill_out_phone_form_fail
    fill_in :idv_phone_form_phone, with: '(703) 555-5555'
  end

  def click_idv_continue
    click_on t('forms.buttons.continue')
  end

  def choose_idv_otp_delivery_method_sms
    page.find(
      'label',
      text: t('two_factor_authentication.otp_delivery_preference.sms'),
    ).click
    click_on t('idv.buttons.send_confirmation_code')
  end

  def choose_idv_otp_delivery_method_voice
    page.find(
      'label',
      text: t('two_factor_authentication.otp_delivery_preference.voice'),
    ).click
    click_on t('idv.buttons.send_confirmation_code')
  end

  def visit_idp_from_sp_with_ial2(sp, **extra)
    if sp == :saml
      settings = ial2_with_bundle_saml_settings
      settings.security[:embed_sign] = false
      if javascript_enabled?
        idp_domain_name = "#{page.server.host}:#{page.server.port}"
        settings.idp_sso_target_url = "http://#{idp_domain_name}/api/saml/auth"
        settings.idp_slo_target_url = "http://#{idp_domain_name}/api/saml/logout"
      end
      @saml_authn_request = auth_request.create(settings)
      visit @saml_authn_request
    elsif sp == :oidc
      @state = SecureRandom.hex
      @client_id = 'urn:gov:gsa:openidconnect:sp:server'
      @nonce = SecureRandom.hex
      visit_idp_from_oidc_sp_with_ial2(state: @state, client_id: @client_id, nonce: @nonce, **extra)
    end
  end

  def visit_idp_from_oidc_sp_with_ial2(
    state: SecureRandom.hex,
    client_id:,
    nonce:,
    verified_within: nil
  )
    visit openid_connect_authorize_path(
      client_id: client_id,
      response_type: 'code',
      acr_values: Saml::Idp::Constants::IAL2_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email profile:name phone social_security_number',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: state,
      prompt: 'select_account',
      nonce: nonce,
      verified_within: verified_within,
    )
  end

  def visit_idp_from_oidc_sp_with_loa3
    visit openid_connect_authorize_path(
      client_id: 'urn:gov:gsa:openidconnect:sp:server',
      response_type: 'code',
      acr_values: Saml::Idp::Constants::LOA3_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email profile:name phone social_security_number',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: SecureRandom.hex,
      prompt: 'select_account',
      nonce: SecureRandom.hex,
    )
  end

  def visit_idp_from_oidc_sp_with_ial2_strict
    visit openid_connect_authorize_path(
      client_id: 'urn:gov:gsa:openidconnect:sp:server',
      response_type: 'code',
      acr_values: Saml::Idp::Constants::IAL2_STRICT_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email profile:name phone social_security_number',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: SecureRandom.hex,
      prompt: 'select_account',
      nonce: SecureRandom.hex,
    )
  end

  def visit_idp_from_saml_sp_with_loa3
    settings = loa3_with_bundle_saml_settings
    settings.security[:embed_sign] = false
    if javascript_enabled?
      idp_domain_name = "#{page.server.host}:#{page.server.port}"
      settings.idp_sso_target_url = "http://#{idp_domain_name}/api/saml/auth"
      settings.idp_slo_target_url = "http://#{idp_domain_name}/api/saml/logout"
    end
    @saml_authn_request = auth_request.create(settings)
    visit @saml_authn_request
  end
end
