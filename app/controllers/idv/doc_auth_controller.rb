module Idv
  class DocAuthController < ApplicationController
    before_action :confirm_two_factor_authenticated
    before_action :redirect_if_mail_bounced
    before_action :redirect_if_pending_profile
    before_action :extend_timeout_using_meta_refresh_for_select_paths
    before_action :add_unsafe_eval_to_capture_steps

    include IdvSession # remove if we retire the non docauth LOA3 flow
    include Flow::FlowStateMachine

    FSM_SETTINGS = {
      step_url: :idv_doc_auth_step_url,
      final_url: :idv_review_url,
      flow: Idv::Flows::DocAuthFlow,
      analytics_id: Analytics::DOC_AUTH,
    }.freeze

    def doc_capture_poll
      result = if FeatureManagement.document_capture_step_enabled?
                 document_capture_session_poll_render_result
               else
                 doc_capture_poll_render_result
               end

      render result
    end

    def doc_capture_poll_render_result
      doc_capture = DocCapture.find_by(user_id: user_id)
      return { plain: 'Not authorized', status: :not_authorized } if doc_capture.blank?
      return { plain: 'Pending', status: :accepted } if doc_capture.acuant_token.blank?
      { plain: 'Complete', status: :ok }
    end

    def document_capture_session_poll_render_result
      session_uuid = flow_session[:document_capture_session_uuid]
      document_capture_session = DocumentCaptureSession.find_by(uuid: session_uuid)
      return { plain: 'Not authorized', status: :not_authorized } unless document_capture_session

      result = document_capture_session.load_result
      return { plain: 'Pending', status: :accepted } if result.blank?
      return { plain: 'Not authorized', status: :not_authorized } unless result.success?
      { plain: 'Complete', status: :ok }
    end

    def redirect_if_mail_bounced
      redirect_to idv_usps_url if current_user.decorate.usps_mail_bounced?
    end

    def redirect_if_pending_profile
      redirect_to verify_account_url if current_user.decorate.pending_profile_requires_verification?
    end

    def extend_timeout_using_meta_refresh_for_select_paths
      return unless request.path == idv_doc_auth_step_path(step: :link_sent)
      max_10min_refreshes = Figaro.env.doc_auth_extend_timeout_by_minutes.to_i / 10
      return if max_10min_refreshes <= 0
      meta_refresh_count = flow_session[:meta_refresh_count].to_i
      return if meta_refresh_count >= max_10min_refreshes
      do_meta_refresh(meta_refresh_count)
    end

    def do_meta_refresh(meta_refresh_count)
      @meta_refresh = 10 * 60
      flow_session[:meta_refresh_count] = meta_refresh_count + 1
    end

    def flow_session
      user_session['idv/doc_auth']
    end

    def add_unsafe_eval_to_capture_steps
      capture_steps = %w[
        front_image
        back_image
        mobile_front_image
        mobile_back_image
        capture_mobile_back_image
        selfie
        document_capture
      ]
      return unless capture_steps.include?(params[:step])

      # required to run wasm until wasm-eval is available
      SecureHeaders.append_content_security_policy_directives(
        request,
        script_src: ['\'unsafe-eval\''],
      )
    end
  end
end
