module Acuant
  module Requests
    class UploadImageRequest < Acuant::Request
      attr_reader :image_data, :instance_id, :side

      def initialize(image_data:, instance_id:, side:)
        @image_data = image_data
        @instance_id = instance_id
        @side = side
      end

      def path
        "/AssureIDService/Document/#{instance_id}/Image?side=#{side_param}&light=0"
      end

      def body
        image_data
      end

      def side_param
        {
          front: 0,
          back: 1,
        }[side.downcase.to_sym]
      end

      def handle_http_response(_response)
        Acuant::Responses::UploadImageResponse.new
      end

      def method
        :post
      end
    end
  end
end
