class Builders::Helpers < SiteBuilder
  def build
    helper :format_duration do |duration|
      # Handle both integer seconds and iTunes duration objects
      seconds = duration.respond_to?(:content) ? duration.content.to_i : duration.to_i
      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      secs = seconds % 60

      if hours > 0
        "#{hours}:#{sprintf('%02d', minutes)}:#{sprintf('%02d', secs)}"
      else
        "#{minutes}:#{sprintf('%02d', secs)}"
      end
    end

    helper :truncate do |text, length|
      if text.length <= length
        text
      else
        text[0...length].gsub(/\s\w+\s*$/, '...') + '...'
      end
    end

    helper :slugify do |text|
      text.downcase
        .gsub(/[^\w\s-]/, '')
        .gsub(/\s+/, '-')
        .gsub(/-+/, '-')
        .gsub(/^-|-$/, '')
        .slice(0, 100)
    end
  end
end
