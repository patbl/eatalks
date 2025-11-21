require 'rss'

class Builders::RssFetcher < SiteBuilder
  def build
    hook :site, :pre_render do |site|
      # Get podcast metadata
      podcast = site.data[:podcast]
      episodes = site.data[:episodes]

      # Create RSS feed
      rss = RSS::Maker.make("2.0") do |maker|
        # Channel-level information
        maker.channel.title = podcast[:title]
        maker.channel.link = "https://patbl.github.io/eatalks2/"
        maker.channel.description = podcast[:description]
        maker.channel.language = podcast[:language]

        # iTunes namespace
        maker.channel.itunes_explicit = podcast[:explicit] ? 'yes' : 'no'

        # iTunes image
        maker.channel.itunes_image = podcast[:image]

        # iTunes owner
        maker.channel.itunes_owner.itunes_name = podcast[:owner_name]
        maker.channel.itunes_owner.itunes_email = podcast[:owner_email]

        # iTunes categories
        podcast[:categories].each do |cat_data|
          category = maker.channel.itunes_categories.new_category
          category.text = cat_data['category']
        end


        # Add episodes
        episodes.each do |episode|
          maker.items.new_item do |item|
            item.title = episode[:title]
            item.link = "https://patbl.github.io/eatalks2/1755269/episodes/#{episode[:slug]}/"
            item.description = episode[:description]
            item.pubDate = episode[:pub_date]
            item.guid.content = episode[:audio_url]
            item.guid.isPermaLink = false

            # Enclosure (audio file)
            item.enclosure.url = episode[:audio_url]
            item.enclosure.type = "audio/mpeg"
            item.enclosure.length = 0 # We don't have file sizes in the data

            # iTunes duration (can be integer seconds as string)
            item.itunes_duration = episode[:duration].to_s
          end
        end
      end

      # Add the RSS feed as a resource
      add_resource :rss, '1755269.rss' do
        layout :none
        content rss.to_s
        permalink '/1755269.rss'
      end
    end
  end
end
