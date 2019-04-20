'use strict';

window.sections = [
    "Classification",
    "Therapeutic Effects",
    "Indications",
    "Contraindications",
    "Side Effects",
    "Adult Dosing",
    "Pediatric Dosing",
    "Notes & Precautions"
]

function format_append_section(name, section, element, level) {
		var header = document.createElement('h' + level);
		header.innerHTML = name;
		element.appendChild(header);

		if (Array.isArray(section)) {
			var list = document.createElement('ul');
			for (var j = 0; j < section.length; ++j) {
				var item = document.createElement('li');
				item.innerHTML = section[j];
				list.appendChild(item);
			}
			element.appendChild(list);
		} else if (section && (typeof section === "object")) {
			for (var subsection in section) {
				format_append_section(subsection, section[subsection], element, level + 1);
			}
		} else if (typeof section === "string") {
			var par = document.createElement('p');
			par.innerHTML = section;
			element.appendChild(par);
		} else {
			console.log("Can't format section:", section);
		}
}

function create_drug_element(drug) {
	var element = document.createElement('section');

	// title
	var title = document.createElement('h2');
	var title_text = drug.Names[0];
	console.log(drug.Names)
	if (drug.Names.length > 1) {
		title_text = title_text + " (" + drug.Names.slice(1).join(", ") + ")"
	}
	title.innerHTML = title_text;

	element.appendChild(title);

	for (var i = 0; i < sections.length; ++i) {
		format_append_section(sections[i], drug[sections[i]], element, 3);
	}

	return element;
}

for (var i = 0; i < drug_data.length; ++i) {
	document.body.appendChild(create_drug_element(drug_data[i]));
}

