require 'rails_helper'

describe Idv::CaptureDocController do
  include DocAuthHelper
  include DocCaptureHelper

  describe 'before_actions' do
    it 'includes corrects before_actions' do
      expect(subject).to have_actions(:before,
                                      :ensure_user_id_in_session,
                                      :fsm_initialize,
                                      :ensure_correct_step)
    end
  end

  let(:user) { create(:user) }

  before do
    stub_analytics
    allow(@analytics).to receive(:track_event)
  end

  describe '#index' do
    context 'document capture step disabled' do
      token = nil
      before do
        allow(FeatureManagement).to receive(:document_capture_step_enabled?).and_return(false)
        capture_doc = CaptureDoc::CreateRequest.call(user.id)
        token = capture_doc.request_token
      end

      context 'with no token' do
        it 'redirects to the root url' do
          get :index

          expect(response).to redirect_to root_url
        end
      end

      context 'with a bad token' do
        it 'redirects to the root url' do
          get :index, params: { token: 'foo' }

          expect(response).to redirect_to root_url
        end
      end

      context 'with an expired token' do
        it 'redirects to the root url' do
          Timecop.travel(Time.zone.now + 1.day) do
            get :index, params: { token: token }
          end

          expect(response).to redirect_to root_url
        end
      end

      context 'with a good token' do
        it 'redirects to the first step' do
          get :index, params: { token: token }

          expect(response).to redirect_to idv_capture_doc_step_url(step: :mobile_front_image)
        end
      end

      context 'with a user id in session and no token' do
        it 'redirects to the first step' do
          mock_session(user.id)
          get :index

          expect(response).to redirect_to idv_capture_doc_step_url(step: :mobile_front_image)
        end
      end
    end

    context 'document capture step enabled' do
      session_uuid = nil
      before do
        allow(FeatureManagement).to receive(:document_capture_step_enabled?).and_return(true)
        document_capture_session = DocumentCaptureSession.create!(requested_at: Time.zone.now)
        session_uuid = document_capture_session.uuid
      end

      context 'with no session' do
        it 'redirects to the root url' do
          get :index

          expect(response).to redirect_to root_url
        end
      end

      context 'with a bad session' do
        it 'redirects to the root url' do
          get :index, params: { 'document-capture-session': 'foo' }

          expect(response).to redirect_to root_url
        end
      end

      context 'with an expired token' do
        it 'redirects to the root url' do
          Timecop.travel(Time.zone.now + 1.day) do
            get :index, params: { 'document-capture-session': session_uuid }
          end

          expect(response).to redirect_to root_url
        end
      end

      context 'with a good session uuid' do
        it 'redirects to the first step' do
          get :index, params: { 'document-capture-session': session_uuid }

          expect(response).to redirect_to idv_capture_doc_step_url(step: :document_capture)
        end
      end

      context 'with a user id in session and no session uuid' do
        it 'redirects to the first step' do
          mock_session(user.id)
          get :index

          expect(response).to redirect_to idv_capture_doc_step_url(step: :document_capture)
        end
      end
    end
  end

  describe '#show' do
    context 'with a user id in session' do
      before do
        mock_session(user.id)
      end

      it 'renders the document_capture template' do
        mock_next_step(:document_capture)
        get :show, params: { step: 'document_capture' }

        expect(response).to render_template :document_capture
      end

      it 'renders the capture_complete template' do
        mock_next_step(:capture_complete)
        get :show, params: { step: 'capture_complete' }

        expect(response).to render_template :capture_complete
      end

      it 'renders a 404 with a non existent step' do
        get :show, params: { step: 'foo' }

        expect(response).to_not be_not_found
      end

      it 'tracks analytics' do
        mock_next_step(:capture_complete)
        result = { step: 'capture_complete' }

        get :show, params: { step: 'capture_complete' }

        expect(@analytics).to have_received(:track_event).with(
          Analytics::CAPTURE_DOC + ' visited', result
        )
      end

      it 'add unsafe-eval to the CSP for capture steps' do
        steps = %i[document_capture]
        steps.each do |step|
          mock_next_step(step)

          get :show, params: { step: step }

          script_src = response.request.headers.env['secure_headers_request_config'].csp.script_src
          expect(script_src).to include("'unsafe-eval'")
        end
      end

      it 'does not add unsafe-eval to the CSP for non-capture steps' do
        mock_next_step(:capture_complete)

        get :show, params: { step: 'capture_complete' }

        secure_header_config = response.request.headers.env['secure_headers_request_config']
        expect(secure_header_config).to be_nil
      end
    end
  end

  def mock_next_step(step)
    allow_any_instance_of(Idv::Flows::CaptureDocFlow).to receive(:next_step).and_return(step)
  end

  def mock_session(user_id)
    session[:doc_capture_user_id] = user_id
  end
end
