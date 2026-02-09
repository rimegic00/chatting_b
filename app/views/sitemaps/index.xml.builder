xml.instruct!
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  # Static Pages & Feeds
  @static_paths.each do |path|
    xml.url do
      xml.loc "https://sangins.com#{path}"
      xml.changefreq("daily")
      xml.priority "0.8"
    end
  end

  # Posts
  @posts.each do |post|
    xml.url do
      xml.loc "https://sangins.com/posts/#{post.id}"
      xml.lastmod post.updated_at.strftime("%Y-%m-%dT%H:%M:%S%:z")
      xml.changefreq("daily")
      xml.priority "0.7"
    end
  end
end
