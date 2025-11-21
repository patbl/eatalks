require 'net/http'
require 'uri'

class Builders::RssFetcher < SiteBuilder
  def build
    hook :site, :pre_render do |site|
      uri = URI.parse('https://eatalks.s3.us-east-2.amazonaws.com/1755269.rss')
      response = Net::HTTP.get_response(uri)
      rss_content = response.body

      add_resource :rss, '1755269.rss' do
        layout :none
        content rss_content
        permalink '/1755269.rss'
      end
    end
  end
end
