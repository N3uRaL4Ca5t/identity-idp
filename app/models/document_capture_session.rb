class DocumentCaptureSession < ApplicationRecord
  include NonNullUuid

  belongs_to :user

  def load_result
    DocumentCaptureSessionResult.load(result_id)
  end

  def store_result_from_response(doc_auth_response)
    DocumentCaptureSessionResult.store(
      id: generate_result_id,
      success: doc_auth_response.success?,
      pii: doc_auth_response.pii_from_doc,
    )
    save!
  end

  def expired?
    return true unless requested_at
    requested_at + Figaro.env.doc_capture_request_valid_for_minutes.to_i.minutes < Time.zone.now
  end

  private

  def generate_result_id
    self.result_id = SecureRandom.uuid
  end
end
