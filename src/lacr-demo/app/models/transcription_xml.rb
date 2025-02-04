class TranscriptionXml < ApplicationRecord
  # Use unique filenames and overwrite on upload
  validates_uniqueness_of :filename
  validates :filename, :xml, presence: true

#-----------------------------------
# Definition of functions
#-----------------------------------

  HISTEI_NS = 'http://www.tei-c.org/ns/1.0'
  # Mount the file uploader
  mount_uploader :xml, XmlUploader

  # Extract the volume, page and paragraph from the Entry ID
  def splitEntryID(id)
    return id.to_s.split(/-|_/).map{|x| x.to_i}.delete_if{|i| i==0}
  end

  # Recursive function to convert the XML format to valid HTML5
  def xml_to_html(tag)
    tag.children().each do |c|
      # Rename the attributes
      c.keys.each do |k|
        c["data-#{k}"] = c.delete(k)
      end
      # Rename the tag and replace lb with br
      c['class'] = "xml-tag #{c.name.gsub(':', '-')}"
      # To avoid invalid void tags: Use "br" if "lb", otherwise "span"
      c.name = c.name == 'lb' ?  "br" : "span"
      # Use recursion
      xml_to_html(c)
    end
  end

#-----------------------------------
# Parsing the paragraphs
#-----------------------------------

  def histei_split_to_paragraphs
    doc = Nokogiri::XML (File.open(xml.current_path))

    # Remove Processing Instructions. Tags of type <? .. ?>
    doc.xpath('//processing-instruction()').remove

    #-----------------------------------
    # Create empty page for each not-problemtatic page break
    #-----------------------------------

    # Get all page break tags which are not inside of div entry
    page_breaks = doc.xpath("//xmlns:pb[@n][not(ancestor::xmlns:div[@xml:id])]", 'xmlns' => HISTEI_NS)
    # Volume = the volume of any div in the document (Assuming it is always the same)
    volume = splitEntryID(doc.xpath('//xmlns:div[@xml:id]/@xml:id', 'xmlns' => HISTEI_NS)[0])[0]

    # Fix for empty pages
    page_breaks.each do |pb|
      begin
        # The attribute @n is assumed to be the page number
        page = pb.xpath('@n').to_s.to_i
        # If the page in the DB in not yet created
        if not Search.exists?(page: page, volume: volume, paragraph: 1)
          # Create a page with message "Page is empty."
          pr = TrParagraph.new
          pr.content_xml = "<note xmlns=\"http://www.tei-c.org/ns/1.0\"/>Page is empty.<note>"
          pr.content_html = "Page is empty."
          pr.save
          s = Search.new
          s.volume = volume
          s.page = page
          s.paragraph = 1
          s.tr_paragraph = pr
          s.transcription_xml = self
          s.save
        end
      rescue Exception => e
        logger.error(e)
      end
    end

    #-----------------------------------
    # Insert the content of each paragraph
    #-----------------------------------

    # Extract all "div" tags with atribute "xml:id"
    entries = doc.xpath("//xmlns:div[@xml:id]", 'xmlns' => HISTEI_NS)
    # Parse each entry as follows
    entries.each do |entry|

      # Go to the closest parent "div" of the entry and find a child "date"
      # and extract the 'when' argument
      date_str = entry.xpath("ancestor::xmlns:div[1]//xmlns:date/@when", 'xmlns' => HISTEI_NS).to_s
      date_from = entry.xpath("ancestor::xmlns:div[1]//xmlns:date/@from", 'xmlns' => HISTEI_NS).to_s
      date_to = entry.xpath("ancestor::xmlns:div[1]//xmlns:date/@to", 'xmlns' => HISTEI_NS).to_s
      if date_str.split('-').length == 3
        entry_date_incorrect = nil
        entry_date = date_str.to_date
      elsif date_str.split('-').length == 2
        entry_date_incorrect = date_str
        entry_date = "#{date_str}-1".to_date # If the day is missing set ot 1-st
      elsif date_str.split('-').length == 1
        entry_date_incorrect = date_str
        entry_date = "#{date_str}-1-1".to_date # If the day and month are missing set ot 1-st Jan.
      else
        entry_date_incorrect = date_from ? "#{date_from} : #{date_to}": 'N/A'
        entry_date = nil # The date is missing
      end

      # Convert the 'entry' and 'date' Nokogiri objects to Ruby Hashes
      entry_id = entry.xpath("@xml:id").to_s
      entry_lang = entry.xpath("@xml:lang").to_s
      case entry_lang # Fix language standad
      when 'sc'
        entry_lang = 'sco'
      when 'la'
        entry_lang = 'lat'
      when 'nl'
        entry_lang = 'nld'
      end
      entry_xml = entry.to_xml.gsub('xml:lang="sc"', 'xml:lang="sco"').gsub('xml:lang="la"', 'xml:lang="lat"').gsub('xml:lang="nl"', 'xml:lang="nld"')
      entry_text =(Nokogiri::XML(entry_xml.gsub('<lb break="yes"/>', "\n"))).xpath('normalize-space()')
      xml_to_html(entry)
      entry_html = entry.to_xml

      # Split entryID
      volume, page, paragraph = splitEntryID(entry)
      # Overwrite if exists
      if Search.exists?(page: page, volume: volume, paragraph: paragraph)
        s = Search.find_by(page: page, volume: volume, paragraph: paragraph)
        # Get existing paragraph
        pr = s.tr_paragraph
      else
        # Create new search record
        s = Search.new
        # Create TrParagraph record
        pr = TrParagraph.new
      end

      # Save the new content
      pr.content_xml = entry_xml
      pr.content_html = entry_html
      pr.save

      # Create Search record
      s.entry = entry_id
      s.volume = volume
      s.page = page
      s.paragraph = paragraph
      s.tr_paragraph = pr
      s.transcription_xml = self
      s.lang = entry_lang
      s.date = entry_date
      s.date_incorrect = entry_date_incorrect
      # Replace line-break tag with \n and normalize whitespace
      s.content = entry_text
      s.save
    end

    doc = Nokogiri::XML (File.open(xml.current_path))
    doc.xpath('//processing-instruction()').remove
    entries_with_page_break = doc.xpath('//xmlns:div[@xml:id]//xmlns:pb[@n]/ancestor::xmlns:div[@xml:id]', 'xmlns' => HISTEI_NS)

    #-----------------------------------
    # Fix problematic page breaks
    # -> Page breaks inside entries
    #-----------------------------------

    # Get all entries with page break inside

    entries_with_page_break.each do |entry|
      begin

        # Split the string of content by the page break
        xmlContentFirstPart, xmlContentSecondPart = entry.to_s.split(/<.*pb.*\/>/)
        xmlContentFirstPart = xmlContentFirstPart.gsub('xml:lang="sc"', 'xml:lang="sco"').gsub('xml:lang="la"', 'xml:lang="lat"').gsub('xml:lang="nl"', 'xml:lang="nld"')
        xmlContentSecondPart = xmlContentSecondPart.gsub('xml:lang="sc"', 'xml:lang="sco"').gsub('xml:lang="la"', 'xml:lang="lat"').gsub('xml:lang="nl"', 'xml:lang="nld"')

        htmlContentFirstPart = Nokogiri::XML("<p>#{xmlContentFirstPart}</p>")
        htmlContentSecondPart = Nokogiri::XML("<p>#{xmlContentSecondPart}</p>")

        # Get the id of the problematic entry
        oldEntryId = entry.xpath('@xml:id').to_s

        # Split the id into page, paragraph, volume
        volume, page, paragraph = splitEntryID(oldEntryId)
        newPage = page + 1

        #
        # Insert the extracted content in the new paragraph
        #

        # if the new paragraph is not created
        # This is false when:
        # -> There is inconcistency the first paragraph of the page
        #    has started in the previous entry
        # -> The document is overwritten
        #
        if Search.exists?(page: newPage, volume: volume, paragraph: 1)
          # Get existing paragraph
          s = Search.find_by(page: newPage, volume: volume, paragraph: 1)
          # Get paragraph record
          pr = s.tr_paragraph
          # Store the updated content for the paragraph record
          pr.content_xml = xmlContentSecondPart
          pr.content_html = htmlContentSecondPart.to_xml+"<span class=\"xml-tag pb\"></span>"+ pr.content_html
          pr.save

        else

          # Create new search record
          s = Search.new

          # Create TrParagraph record
          pr = TrParagraph.new
          pr.content_xml = xmlContentSecondPart
          pr.content_html = htmlContentSecondPart.to_xml
          pr.save

        end

        textContentFirstPart =(Nokogiri::XML("<p>"+xmlContentFirstPart.gsub('<lb break="yes"/>', "\n")+"</p>")).xpath('normalize-space()')
        textContentSecondPart =(Nokogiri::XML("<p>"+xmlContentSecondPart.gsub('<lb break="yes"/>', "\n")+"</p>")).xpath('normalize-space()')

        # Find the original record
        previousEntry = Search.find_by(volume: volume,page: page,paragraph: paragraph)

        # Create Search record
        s.tr_paragraph = pr
        s.entry = previousEntry.entry
        s.volume = volume
        s.page = newPage
        s.paragraph = 1
        s.transcription_xml = self
        s.lang = previousEntry.lang
        s.date = previousEntry.date
        s.date_incorrect = previousEntry.date_incorrect
        # Replace line-break tag with \n and normalize whitespace
        s.content = "#{textContentSecondPart}\n#{s.content}"
        s.save

        previousEntry.content = textContentFirstPart
        # Get paragraph record
        prPreviusEntry = previousEntry.tr_paragraph
        # Remove duplicated content from entry which contains the page break
        prPreviusEntry.content_xml = xmlContentFirstPart
        prPreviusEntry.content_html = htmlContentFirstPart.to_xml
        prPreviusEntry.save
        # Save the change
        previousEntry.tr_paragraph = prPreviusEntry
        previousEntry.save
      rescue Exception => e
        logger.error(e)
      end
    end

  end
end
