require 'pdf-reader'
require 'set'
require 'json'

class Parser
  def initialize
    sections = ["Classification", "Therapeutic Effects", "Indications", "Contraindications", "Side Effects", "Adult Dosing", "Pediatric Dosing", "Notes & Precautions"]
    @secreg = Regexp.new("^ ?(#{Regexp.union(sections).source})")

    @data = {}
    @previous_line_content = nil
    @drug_name = nil
    @section = nil
    @section_padding = nil
    @section_content = nil
    @drug = nil

  end

  def parse_line line
    # skip page number lines
    if line.length > 90 && line =~ / {5,}\d+$/
      return
    end

    # skip random or empty lines
    if line =~ /^Reading Hospital/ || line =~ /^\s*$/
      return
    end

    # check for start of new section
    if match = @secreg.match(line)
      section = match[0].strip

      save_current_section

      # first section, now we know what the drug is and can save the previous one
      if section == "Classification"
        # save previous drug
        if @drug
          @data[@drug_name] = @drug
        end
        names = parse_name @previous_line_content
        @drug_name = names[0]
        @drug = {"Names" => names}
      end

      @section = section

      # figure out how many spaces precede section content
      initial = match[0].length
      @section_padding = line.match(/\s+/, initial)[0].length + initial

      @section_content = clean_bullet line[@section_padding..-1]
    elsif @section
      # TODO: somehow still getting "CONTINUED ON NEXT PAGE" in a few spots
      if line[0...@section_padding] =~ /\S/
        # weird case, probably next drug name, could be something else...
      else
        @section_content += clean_bullet(line[@section_padding..-1])
      end
    end

    @previous_line_content = line.strip
  end

  def data
    # return data plus whatever partial content we have leftover
    drug = @drug.dup
    data = @data.dup
    drug[@section] = process_section @section, @section_content
    data[@drug_name] = drug
    data
  end

  private
  def clean_bullet line
    if !line.empty? && line =~ /^\s*▯/
      line.sub ?▯, ?•
    else
      line
    end
  end

  def parse_name name
    if name =~ /(.*)\((.*)\)/
      canon = $1.strip
      others = $2.split(?,).map(&:strip)
      return [canon]+others
    else
      return [name]
    end
  end

  def process_section name, content
    # if the section is split into categories
    if content.each_line.first =~ /^([^•]*):/

      categories = {}
      category_content = nil
      next_category_content = nil
      category = nil

      content.each_line do |line|
        # start of a new category
        if line =~ /^([^•]*?):(.*)/
          if category
            # save last item in category
            if category_content
              category_content << next_category_content
            else # it's one paragraph, we haven't saved it yet
              category_content = next_category_content
            end
            categories[category] = category_content
          end
          category = $1.strip
          category_content = nil
          # assumes we don't have a bullet right after a category name
          next_category_content = $2.strip
          next_category_content = nil if next_category_content.empty?
        # start of a new bullet point
        elsif line =~ /^\s*•(.*)/
          unless category_content
            category_content = []
          end
          if next_category_content
            # assume we must have a list of bullet points by now
            category_content << next_category_content
          end
          next_category_content = $1.strip
        # start of a new paragraph, or continuation of a bullet point/paragraph
        else
          if next_category_content
            next_category_content += " " + line.strip
          else
            next_category_content = line.strip
          end
        end
      end

      # save last item in category
      if category_content
        category_content << next_category_content
      else # it's one paragraph, we haven't saved it yet
        category_content = next_category_content
      end
      categories[category] = category_content

      content = categories

    elsif content =~ /\A\s*•/
      bullets = []
      current_bullet = nil

      content.each_line do |line|
        if line =~ /^\s*•(.*)/
          if current_bullet
            bullets << current_bullet
          end
          current_bullet = $1.strip
        else
          current_bullet += " " + line.strip
        end
      end

      bullets << current_bullet
      content = bullets
    else # general section content
      content = content.strip.gsub("\n", " ")
    end

    return content
  end

  def save_current_section
    return unless @drug

    content = process_section @section, @section_content

    @drug[@section] = content
    @section = nil
    @section_content = nil
  end
end

reader = PDF::Reader.new ARGV[0]
parser = Parser.new

reader.pages[4...-3].each do |page|
  page.text.each_line do |line|
    parser.parse_line line
  end
end

puts JSON.pretty_generate(parser.data)
