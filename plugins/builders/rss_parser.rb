class Builders::RssParser < SiteBuilder
  def build
    hook :site, :pre_render do |site|
      site.data[:podcast] = {
        title: site.data.podcast['title'],
        description: site.data.podcast['description'],
        image: site.data.podcast['image'],
        owner_name: site.data.podcast['owner_name'],
        owner_email: site.data.podcast['owner_email'],
        explicit: site.data.podcast['explicit'],
        language: site.data.podcast['language'],
        categories: site.data.podcast['categories']
      }

      episodes = site.data.episodes.map do |episode|
        slug = episode['slug']

        # Generate S3 audio URL
        s3_audio_url = if slug
          "https://eatalks.s3.us-east-2.amazonaws.com/audio/#{slug}.mp3"
        else
          nil
        end

        {
          title: episode['title'],
          description: episode['description'],
          summary: episode['summary'],
          audio_url: s3_audio_url,
          duration: episode['duration'],
          pub_date: Time.parse(episode['pub_date']),
          slug: slug
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
end
