require 'saml_idp_constants'

## GET /api/saml/auth helper methods
module SamlAuthHelper
  def saml_settings
    settings = OneLogin::RubySaml::Settings.new

    # SP settings
    settings.assertion_consumer_service_url = 'http://localhost:3000/test/saml/decode_assertion'
    settings.assertion_consumer_logout_service_url = 'http://localhost:3000/test/saml/decode_slo_request'
    settings.certificate = saml_test_sp_cert
    settings.private_key = saml_test_sp_key
    settings.authn_context = Saml::Idp::Constants::IAL1_AUTHN_CONTEXT_CLASSREF
    settings.name_identifier_format = Saml::Idp::Constants::NAME_ID_FORMAT_PERSISTENT

    # SP + IdP Settings
    settings.issuer = 'http://localhost:3000'
    settings.security[:authn_requests_signed] = true
    settings.security[:logout_requests_signed] = true
    settings.security[:embed_sign] = true
    settings.security[:digest_method] = 'http://www.w3.org/2001/04/xmlenc#sha256'
    settings.security[:signature_method] = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
    settings.double_quote_xml_attribute_values = true
    # IdP setting
    settings.idp_sso_target_url = "http://#{Figaro.env.domain_name}/api/saml/auth2019"
    settings.idp_slo_target_url = "http://#{Figaro.env.domain_name}/api/saml/logout2019"
    settings.idp_cert_fingerprint = idp_fingerprint
    settings.idp_cert_fingerprint_algorithm = 'http://www.w3.org/2001/04/xmlenc#sha256'

    settings
  end

  def sp_fingerprint
    @sp_fingerprint ||= Fingerprinter.fingerprint_cert(
      OpenSSL::X509::Certificate.new(saml_test_sp_cert),
    )
  end

  def idp_fingerprint
    @idp_fingerprint ||= Fingerprinter.fingerprint_cert(
      OpenSSL::X509::Certificate.new(saml_test_idp_cert),
    )
  end

  def saml_test_sp_key
    @private_key ||= OpenSSL::PKey::RSA.new(
      File.read(Rails.root + 'keys/saml_test_sp.key'),
    ).to_pem
  end

  def saml_test_idp_cert
    @saml_test_idp_cert ||= File.read(Rails.root.join('certs', 'saml2019.crt'))
  end

  def saml_test_sp_cert
    @saml_test_sp_cert ||= File.read(Rails.root.join('certs', 'sp', 'saml_test_sp.crt'))
  end

  def auth_request
    @auth_request ||= OneLogin::RubySaml::Authrequest.new
  end

  def authnrequest_get(issuer: nil)
    auth_request.create(saml_spec_settings(issuer: issuer))
  end

  def saml_spec_settings(issuer: nil)
    settings = saml_settings.dup
    settings.issuer = issuer || 'http://localhost:3000'
    settings
  end

  def invalid_authn_context_settings
    settings = saml_settings.dup
    settings.authn_context = 'http://idmanagement.gov/ns/assurance/loa/5'
    settings
  end

  def invalid_service_provider_settings
    settings = saml_settings.dup
    settings.issuer = 'invalid_provider'
    settings
  end

  def invalid_service_provider_and_authn_context_settings
    settings = saml_settings.dup
    settings.authn_context = 'http://idmanagement.gov/ns/assurance/loa/5'
    settings.issuer = 'invalid_provider'
    settings
  end

  def sp1_saml_settings
    settings = saml_settings.dup
    settings.issuer = 'https://rp1.serviceprovider.com/auth/saml/metadata'
    settings
  end

  def aal3_sp1_saml_settings
    settings = saml_settings.dup
    settings.issuer = 'https://aal3.serviceprovider.com/auth/saml/metadata'
    settings
  end

  def sp2_saml_settings
    settings = saml_settings.dup
    settings.issuer = 'https://rp2.serviceprovider.com/auth/saml/metadata'
    settings
  end

  def sp_not_requesting_signed_saml_response_settings
    settings = saml_settings.dup
    settings.issuer = 'test_saml_sp_not_requesting_signed_response_message'
    settings
  end

  def sp_requesting_signed_saml_response_settings
    settings = saml_settings.dup
    settings.issuer = 'test_saml_sp_requesting_signed_response_message'
    settings
  end

  def email_nameid_saml_settings_for_allowed_issuer
    settings = saml_settings.dup
    settings.name_identifier_format = Saml::Idp::Constants::NAME_ID_FORMAT_EMAIL
    settings.issuer = 'https://rp1.serviceprovider.com/auth/saml/metadata'
    settings
  end

  def missing_nameid_format_saml_settings_for_allowed_email_issuer
    settings = saml_settings.dup
    settings.name_identifier_format = nil
    settings.issuer = 'https://rp1.serviceprovider.com/auth/saml/metadata'
    settings
  end

  def missing_nameid_format_saml_settings
    settings = saml_settings.dup
    settings.name_identifier_format = nil
    settings
  end

  def email_nameid_saml_settings_for_disallowed_issuer
    settings = saml_settings.dup
    settings.name_identifier_format = Saml::Idp::Constants::NAME_ID_FORMAT_EMAIL
    settings
  end

  def ial2_saml_settings
    settings = sp1_saml_settings.dup
    settings.name_identifier_format = Saml::Idp::Constants::NAME_ID_FORMAT_EMAIL
    settings.authn_context = Saml::Idp::Constants::IAL2_AUTHN_CONTEXT_CLASSREF
    settings
  end

  def loa3_saml_settings
    settings = sp1_saml_settings.dup
    settings.authn_context = Saml::Idp::Constants::LOA3_AUTHN_CONTEXT_CLASSREF
    settings
  end

  def ialmax_saml_settings
    settings = sp1_saml_settings.dup
    settings.authn_context = Saml::Idp::Constants::IALMAX_AUTHN_CONTEXT_CLASSREF
    settings
  end

  def ialmax_with_bundle_saml_settings
    settings = ialmax_saml_settings
    settings.authn_context = [
      settings.authn_context,
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}first_name:last_name email, ssn",
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}phone",
    ]
    settings
  end

  def ial2_with_bundle_saml_settings
    settings = ial2_saml_settings
    settings.authn_context = [
      settings.authn_context,
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}first_name:last_name email, ssn",
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}phone",
    ]
    settings
  end

  def loa3_with_bundle_saml_settings
    settings = loa3_saml_settings
    settings.authn_context = [
      settings.authn_context,
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}first_name:last_name email, ssn",
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}phone",
    ]
    settings
  end

  def ial1_with_verified_at_saml_settings
    settings = sp1_saml_settings
    settings.authn_context = [
      settings.authn_context,
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}email,verified_at",
    ]
    settings
  end

  def ial1_with_bundle_saml_settings
    settings = sp1_saml_settings
    settings.authn_context = [
      settings.authn_context,
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}first_name:last_name email, ssn",
      "#{Saml::Idp::Constants::REQUESTED_ATTRIBUTES_CLASSREF}phone",
    ]
    settings
  end

  def ial1_with_aal3_saml_settings
    settings = sp1_saml_settings
    settings.authn_context = [
      settings.authn_context,
      Saml::Idp::Constants::AAL3_AUTHN_CONTEXT_CLASSREF,
    ]
    settings
  end

  def sp1_authnrequest
    auth_request.create(sp1_saml_settings)
  end

  def sp2_authnrequest
    auth_request.create(sp2_saml_settings)
  end

  def ial2_authnrequest
    auth_request.create(ial2_saml_settings)
  end

  def aal3_sp1_authnrequest
    auth_request.create(aal3_sp1_saml_settings)
  end

  def ial1_aal3_authnrequest
    auth_request.create(ial1_with_aal3_saml_settings)
  end

  def missing_authn_context_saml_settings
    settings = saml_settings.dup
    settings.authn_context = nil
    settings
  end

  def saml_test_key
    @saml_test_key ||= File.read(Rails.root.join('keys', 'saml_test_sp.key'))
  end

  # generates a SAML response and returns a parsed Nokogiri XML document
  def generate_saml_response(user, settings = saml_settings, link: true)
    # user needs to be signed in in order to generate an assertion
    link_user_to_identity(user, link, settings)
    sign_in(user)
    saml_get_auth(settings)
  end

  def saml_get_auth(settings)
    # GET redirect binding Authn Request
    get :auth, params: { SAMLRequest: CGI.unescape(saml_request(settings)) }
  end

  def saml_post_auth(saml_request)
    # POST redirect binding Authn Request
    post :auth, params: { SAMLRequest: CGI.unescape(saml_request) }
  end

  def visit_saml_auth_path
    visit api_saml_auth2019_path(
      SAMLRequest: CGI.unescape(saml_request(saml_settings)),
    )
  end

  private

  def link_user_to_identity(user, link, settings)
    return unless link

    IdentityLinker.new(
      user,
      settings.issuer,
    ).link_identity(
      ial: ial2_requested?(settings) ? true : nil,
      verified_attributes: ['email'],
    )
  end

  def ial2_requested?(settings)
    settings.authn_context != Saml::Idp::Constants::IAL1_AUTHN_CONTEXT_CLASSREF
  end

  def saml_request(settings)
    authn_request(settings).split('SAMLRequest=').last
  end

  # generate a SAML Authn request
  def authn_request(settings = saml_settings, params = {})
    OneLogin::RubySaml::Authrequest.new.create(settings, params)
  end

  def visit_idp_from_sp_with_ial1(sp)
    if sp == :saml
      @saml_authn_request = auth_request.create(saml_settings)
      visit @saml_authn_request
    elsif sp == :oidc
      @state = SecureRandom.hex
      @client_id = 'urn:gov:gsa:openidconnect:sp:server'
      @nonce = SecureRandom.hex
      visit_idp_from_oidc_sp_with_ial1(state: @state, client_id: @client_id, nonce: @nonce)
    end
  end

  def visit_idp_from_oidc_sp_with_ial1(state: SecureRandom.hex, client_id:, nonce:)
    visit openid_connect_authorize_path(
      client_id: client_id,
      response_type: 'code',
      acr_values: Saml::Idp::Constants::IAL1_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: state,
      prompt: 'select_account',
      nonce: nonce,
    )
  end

  def visit_idp_from_oidc_sp_with_loa1_prompt_login
    state = SecureRandom.hex
    client_id = 'urn:gov:gsa:openidconnect:sp:server'
    nonce = SecureRandom.hex
    visit openid_connect_authorize_path(
      client_id: client_id,
      response_type: 'code',
      acr_values: Saml::Idp::Constants::LOA1_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: state,
      prompt: 'login',
      nonce: nonce,
    )
  end

  def visit_idp_from_oidc_sp_with_hspd12_and_require_piv_cac
    state = SecureRandom.hex
    client_id = 'urn:gov:gsa:openidconnect:sp:server'
    nonce = SecureRandom.hex
    visit openid_connect_authorize_path(
      client_id: client_id,
      response_type: 'code',
      acr_values: Saml::Idp::Constants::IAL1_AUTHN_CONTEXT_CLASSREF + ' ' +
        Saml::Idp::Constants::AAL3_HSPD12_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email x509 x509:presented',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: state,
      prompt: 'select_account',
      nonce: nonce,
    )
  end

  def visit_idp_from_oidc_sp_with_ialmax
    state = SecureRandom.hex
    client_id = 'urn:gov:gsa:openidconnect:sp:server'
    nonce = SecureRandom.hex
    visit openid_connect_authorize_path(
      client_id: client_id,
      response_type: 'code',
      acr_values: Saml::Idp::Constants::IALMAX_AUTHN_CONTEXT_CLASSREF,
      scope: 'openid email profile:name social_security_number',
      redirect_uri: 'http://localhost:7654/auth/result',
      state: state,
      prompt: 'login',
      nonce: nonce,
    )
  end

  def visit_idp_from_saml_sp_with_ialmax
    @saml_authn_request = auth_request.create(ialmax_with_bundle_saml_settings)
    visit @saml_authn_request
  end
end
