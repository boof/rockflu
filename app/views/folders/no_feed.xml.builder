xml.instruct!
xml.rss 'version' => '2.0', 'xmlns:dc' => 'http://purl.org/dc/elements/1.1/' do
  xml.channel do

    xml.title 'Boxroom folder: this folder does not exist anymore'
    xml.link url_for(root_path(:only_path => false))
    xml.pubDate CGI.rfc1123_date(Time.now)
    xml.description 'Not existing folder in Boxroom'

    xml.item do
      xml.title 'This folder does not exist (anymore).'
      xml.link url_for(root_path(:only_path => false))
      xml.description 'The Boxroom folder to which you are subscribed does not exist anymore. Please unsubscribe from this feed.'
      xml.pubDate CGI.rfc1123_date(Time.now)
    end
  end
end
