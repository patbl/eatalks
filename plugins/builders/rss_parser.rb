require 'rss'
require 'open-uri'

class Builders::RssParser < SiteBuilder
  def build
    hook :site, :pre_render do |site|
      # Parse the RSS feed
      rss_file = File.read(File.join(site.root_dir, 'feed.rss'))
      feed = RSS::Parser.parse(rss_file, false)

      # Store podcast metadata
      site.data[:podcast] = {
        title: feed.channel.title,
        description: strip_html(feed.channel.description),
        author: feed.channel.itunes_author,
        image: feed.channel.itunes_image&.href || feed.channel.image&.url,
        link: feed.channel.link,
        language: feed.channel.language,
        copyright: feed.channel.copyright,
        keywords: feed.channel.itunes_keywords
      }

      # Parse episodes
      episodes = feed.items.map do |item|
        duration = item.itunes_duration
        duration_seconds = duration.respond_to?(:content) ? duration.content.to_i : duration.to_i

        # Extract episode ID from GUID (e.g., "Buzzsprout-12217213" -> "12217213")
        episode_id = item.guid&.content&.sub('Buzzsprout-', '')

        # Extract full slug from audio URL
        # e.g., "https://www.buzzsprout.com/1755269/episodes/12217213-hilary-greaves....mp3"
        # becomes "12217213-hilary-greaves-..."
        audio_url = item.enclosure&.url
        slug = if audio_url && audio_url.include?('/episodes/')
          audio_url.split('/episodes/').last&.sub(/\.mp3$/, '')
        else
          "#{episode_id}-#{slugify(item.title)}"
        end

        # Replace Buzzsprout URL with S3 URL
        s3_audio_url = if slug
          "https://eatalks.s3.us-east-2.amazonaws.com/audio/#{slug}.mp3"
        else
          audio_url
        end

        {
          title: item.title,
          description: strip_html(item.description),
          summary: item.itunes_summary ? strip_html(item.itunes_summary) : strip_html(item.description),
          audio_url: s3_audio_url,
          duration: duration_seconds,
          pub_date: item.pubDate,
          guid: item.guid&.content,
          episode_id: episode_id,
          slug: slug,
          keywords: item.itunes_keywords
        }
      end

      site.data[:episodes] = episodes

      # Create individual episode pages with Buzzsprout URL structure
      episodes.each_with_index do |episode, index|
        episode_data = episode.merge({
          episode_number: episodes.length - index
        })

        # Use the slug extracted from the RSS feed
        slug = episode[:slug]

        # Create path: /1755269/episodes/{slug}.html
        add_resource :episodes, "#{slug}.html" do
          layout :episode
          title episode_data[:title]
          content episode_data[:description]
          data episode_data
          permalink "/1755269/episodes/#{slug}/"
        end
      end
    end
  end

  private

  def strip_html(text)
    return '' unless text
    text.gsub(/<\/?[^>]*>/, '').gsub(/\s+/, ' ').strip
  end

  def slugify(text)
    text.downcase
      .gsub(/[^\w\s-]/, '')
      .gsub(/\s+/, '-')
      .gsub(/-+/, '-')
      .gsub(/^-|-$/, '')
      .slice(0, 100) # Limit length
  end
end
