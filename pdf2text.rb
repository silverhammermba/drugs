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

    @box = 0x25af.chr Encoding::UTF_8
    @bullet = 0x2022.chr Encoding::UTF_8
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
    if !line.empty? && line =~ /^\s*#$box/
      line.sub @box, @bullet
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
    # nested bullets in categories
    if content.each_line.first =~ /:\s*$/ && content.include?(@bullet)
      categories = {}
      current_category = nil
      category_content = nil
      current_bullet = nil

      # TODO: should be more general, category might have a new line, else a bullet
      # e.g. Amiodarone
      content.each_line do |line|
        if line =~ /(.*):\s*$/
          if current_category
            categories[current_category] = category_content
          end
          current_category = $1.strip
          category_content = []
          current_bullet = nil
        elsif line =~ /^\s*#@bullet(.*)/
          if current_bullet
            category_content << current_bullet
          end
          current_bullet = $1.strip
        else
          if !current_bullet
            current_bullet = line.strip
          else
            current_bullet += " " + line.strip
          end
        end
      end
      categories[current_category] = category_content
      content = categories
    # categories, no bullets inside
    elsif content.each_line.first =~ /:.*$/
      categories = {}
      current_category = nil
      category_content = nil
      content.each_line do |line|
        if line =~ /:/
          if current_category
            categories[current_category] = category_content
          end
          current_category, category_content = line.split(?:, 2).map(&:strip)
        else
          category_content += " " + line.strip
        end
      end
      categories[current_category] = category_content
      content = categories
    # just bullets
    elsif content =~ /\A\s*#@bullet/
      bullets = []
      current_bullet = nil
      content.each_line do |line|
        if line =~ /^\s*#@bullet(.*)/
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
    else # generaly section content
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
