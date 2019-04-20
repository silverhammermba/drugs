require 'pdf-reader'
require 'set'
require 'json'

reader = PDF::Reader.new ARGV[0]

$box = 0x25af.chr Encoding::UTF_8
$bullet = 0x2022.chr Encoding::UTF_8

$sections = ["Classification", "Therapeutic Effects", "Indications", "Contraindications", "Side Effects", "Adult Dosing", "Pediatric Dosing", "Notes & Precautions"]

$secreg = Regexp.new("^ ?(#{Regexp.union($sections).source})")

$data = {}
$previous_line_content = nil
$drug_name = nil
$section =nil
$section_padding = nil
$section_content = nil
$drug = nil

def clean_bullet line
	if !line.empty? && line =~ /^\s*#$box/
		line.sub $box, $bullet
	else
		line
	end
end

def process page

	page.text.each_line do |line|
		# skip page number lines
		if line.length > 90 && line =~ / {5,}\d+$/
			next
		end

		# skip random or empty lines
		if line =~ /^Reading Hospital/ || line =~ /^\s*$/
			next
		end

		# check for start of new section
		if match = $secreg.match(line)
			section = match[0].strip

			# first section, now we know what the drug is and can save the previous
			if section == "Classification"
				if $drug
					$drug[$section] = $section_content
					$data[$drug_name] = $drug
				end
				$drug_name = $previous_line_content
				$drug = {}
			else # if it's the start of any other section, save the previous section
				$drug[$section] = $section_content
			end

			$section = section

			# figure out how many spaces precede section content
			initial = match[0].length
			$section_padding = line.match(/\s+/, initial)[0].length + initial

			$section_content = clean_bullet line[$section_padding..-1]
		elsif $section
			# TODO somehow still getting "CONTINUED ON NEXT PAGE" in a few spots
			if line[0...$section_padding] =~ /\S/
				# weird case, probably next drug name, could be something else...
			else
				$section_content += clean_bullet(line[$section_padding..-1])
			end
		end

		$previous_line_content = line.strip
	end
end

reader.pages[4...-3].each do |page|
	process page
end

$drug[$section] = $section_content
$data[$drug_name] = $drug

puts JSON.pretty_generate($data)