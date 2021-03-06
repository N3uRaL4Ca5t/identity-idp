require 'rails_helper'

describe TwoFactorAuthCode::WebauthnAuthenticationPresenter do
  include Rails.application.routes.url_helpers

  let(:view) { ActionController::Base.new.view_context }
  let(:reauthn) {}
  let(:presenter) do
    TwoFactorAuthCode::WebauthnAuthenticationPresenter.
      new(data: { reauthn: reauthn }, view: view)
  end

  let(:allow_user_to_switch_method) { false }
  let(:aal3_required) { false }
  let(:service_provider_mfa_policy) do
    instance_double(
      ServiceProviderMfaPolicy,
      aal3_required?: aal3_required,
      allow_user_to_switch_method?: allow_user_to_switch_method,
    )
  end

  before do
    allow(presenter).to receive(:service_provider_mfa_policy).and_return service_provider_mfa_policy
  end

  describe '#help_text' do
    context 'with aal3 required'
    it 'supplies no help text' do
      expect(presenter.help_text).to eq('')
    end
  end

  describe '#link_text' do
    let(:aal3_required) { true }

    context 'with multiple AAL3 methods' do
      let(:allow_user_to_switch_method) { true }

      it 'supplies link text' do
        expect(presenter.link_text).to eq(t('two_factor_authentication.webauthn_piv_available'))
      end
    end

    context 'with only one AAL3 method do' do
      it 'supplies no link text' do
        expect(presenter.link_text).to eq('')
      end
    end
  end

  describe '#fallback_question' do
    let(:allow_user_to_switch_method) { true }

    it 'supplies a fallback_question' do
      expect(presenter.fallback_question).to \
        eq(t('two_factor_authentication.webauthn_fallback.question'))
    end
  end

  describe '#cancel_link' do
    let(:locale) { LinkLocaleResolver.locale }

    context 'reauthn' do
      let(:reauthn) { true }

      it 'returns the account path' do
        expect(presenter.cancel_link).to eq account_path(locale: locale)
      end
    end

    context 'not reauthn' do
      let(:reauthn) { false }

      it 'returns the sign out path' do
        expect(presenter.cancel_link).to eq sign_out_path(locale: locale)
      end
    end
  end

  it 'handles multiple locales' do
    I18n.available_locales.each do |locale|
      I18n.locale = locale
      if locale == :en
        expect(presenter.cancel_link).not_to match(%r{/en/})
      else
        expect(presenter.cancel_link).to match(%r{/#{locale}/})
      end
    end
  end
end
