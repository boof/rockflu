xml.instruct!
xml.rss 'version' => '2.0', 'xmlns:dc' => 'http://purl.org/dc/elements/1.1/' do
  xml.channel do

    xml.title "Folder: #{ h @folder.name }"
    xml.link folder_path(@folder, :only_path => false)
    xml.pubDate CGI.rfc1123_date(@folder.updated_at)
    xml.description 'Folder'

    @folders.each do |folder|
      xml.item do
        xml.title "Folder: #{ h folder.name }"
        xml.link folder_path(folder, :only_path => false)
        xml.description "#{ h folder.name } is a subfolder of #{ path folder.parent, true, :only_path => false }."
        xml.pubDate CGI.rfc1123_date(folder.updated_at)
        xml.guid folder_path(folder, :only_path => false)
      end
    end

    @files.each do |file|
      xml.item do
        xml.title "File: #{ h file.name }"
        xml.link folder_file_path(file.folder, file, :only_path => false)
        xml.description "#{ h file.name } is a file in #{ path file.folder, true, :only_path => false }."
        xml.pubDate CGI.rfc1123_date(file.updated_at)
        xml.guid folder_file_path(file.folder_id, file, :only_path => false)
      end
    end
  end
end
