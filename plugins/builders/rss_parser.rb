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

        {
          title: item.title,
          description: strip_html(item.description),
          summary: item.itunes_summary ? strip_html(item.itunes_summary) : strip_html(item.description),
          audio_url: item.enclosure&.url,
          duration: duration_seconds,
          pub_date: item.pubDate,
          guid: item.guid&.content,
          keywords: item.itunes_keywords
        }
      end

      site.data[:episodes] = episodes

      # Create individual episode pages
      episodes.each_with_index do |episode, index|
        slug = slugify(episode[:title])

        episode_data = episode.merge({
          episode_number: episodes.length - index,
          slug: slug
        })

        add_resource :episodes, "#{slug}.html" do
          layout :episode
          title episode_data[:title]
          content episode_data[:description]
          data episode_data
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
