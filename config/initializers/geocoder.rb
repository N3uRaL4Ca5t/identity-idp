# For some reason the test result class does not impelement the `language=`
# method. This patches an empty method onto it to prevent NoMethodErrors in
# the tests
module Geocoder
  module Result
    class Test
      def language=(_locale); end
    end
  end
end

GEO_DATA_FILEPATH = Rails.root.join('geo_data', 'GeoLite2-City.mmdb').freeze

if !Rails.env.production? && !File.exist?(GEO_DATA_FILEPATH)
  Geocoder.configure(ip_lookup: :test)
  Geocoder::Lookup::Test.add_stub(
    '127.0.0.1', [
      { 'city' => '', 'country' => 'United States', 'state_code' => '' },
    ]
  )
  Geocoder::Lookup::Test.add_stub(
    '::1', [
      { 'city' => '', 'country' => 'United States', 'state_code' => '' },
    ]
  )
else
  Geocoder.configure(
    ip_lookup: :geoip2,
    geoip2: {
      file: GEO_DATA_FILEPATH,
    },
  )
end
