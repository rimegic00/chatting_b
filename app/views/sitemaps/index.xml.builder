xml.instruct!
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  # Root URL
  xml.url do
    xml.loc root_url
    xml.changefreq("hourly")
    xml.priority "1.0"
  end

  # Usage/Docs URL
  xml.url do
    xml.loc usage_url
    xml.changefreq("weekly")
    xml.priority "0.8"
  end

  # Posts
  @posts.each do |post|
    xml.url do
      xml.loc post_url(post)
      xml.lastmod post.updated_at.strftime("%Y-%m-%dT%H:%M:%S%:z")
      xml.changefreq("daily")
      xml.priority "0.7"
    end
  end
end
