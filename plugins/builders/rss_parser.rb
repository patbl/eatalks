class Builders::RssParser < SiteBuilder
  def build
    hook :site, :pre_render do |site|
      # Load podcast data from YAML file
      yaml_data = site.data.podcast_data

      # Store podcast metadata
      site.data[:podcast] = {
        title: yaml_data['podcast']['title'],
        image: yaml_data['podcast']['image']
      }

      # Parse episodes and add S3 audio URLs
      episodes = yaml_data['episodes'].map do |item|
        slug = item['slug']

        # Generate S3 audio URL
        s3_audio_url = if slug
          "https://eatalks.s3.us-east-2.amazonaws.com/audio/#{slug}.mp3"
        else
          nil
        end

        {
          title: item['title'],
          description: item['description'],
          summary: item['summary'],
          audio_url: s3_audio_url,
          duration: item['duration'],
          pub_date: Time.parse(item['pub_date']),
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
