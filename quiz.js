'use strict';

function shuffleArray(array) {
	return getRandomSubarray(array, array.count);
}

function getRandomSubarray(arr, size) {
    var shuffled = arr.slice(0), i = arr.length, temp, index;
    while (i--) {
        index = Math.floor((i + 1) * Math.random());
        temp = shuffled[index];
        shuffled[index] = shuffled[i];
        shuffled[i] = temp;
    }
    return shuffled.slice(0, size);
}

Array.prototype.randomElement = function () {
    return this[Math.floor(Math.random() * this.length)]
}

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

function obscure_name(drug, text) {
	for (var i = 0; i < drug.Names.length; ++i) {
		var pattern = new RegExp('\\b(' + drug.Names[i] + ')', 'i');
		text = text.replace(pattern, '<span class="redacted">REDACTED</span><span class="name">$1</span>');
	}
	return text;
}

function format_append_section(name, section, element, level, hidden, drug, correct) {
	var div = document.createElement('div');

	if (drug && !correct) {
		var header = document.createElement('h' + level);
		header.classList.add('drug_name');
		header.innerHTML = drug_name(drug);
		div.appendChild(header);
	}

	div.addEventListener("click", function() {
		div.classList.add('clicked');
	});

	if (correct) {
		div.classList.add('correct');
	}

	var header = document.createElement('h' + level);
	header.innerHTML = name;
	div.appendChild(header);

	if (Array.isArray(section)) {
		var list = document.createElement('ul');
		for (var j = 0; j < section.length; ++j) {
			var item = document.createElement('li');
			if (hidden) {
				item.innerHTML = obscure_name(drug, section[j]);
			} else {
				item.innerHTML = section[j];
			}
			list.appendChild(item);
		}
		div.appendChild(list);
	} else if (section && (typeof section === "object")) {
		for (var subsection in section) {
			format_append_section(subsection, section[subsection], div, level + 1, hidden, drug);
		}
	} else if (typeof section === "string") {
		var par = document.createElement('p');
		if (hidden) {
			par.innerHTML = obscure_name(drug, section);
		} else {
			par.innerHTML = section;
		}
		div.appendChild(par);
	} else {
		console.log("Can't format section:", section);
	}

	element.appendChild(div);
}

function drug_h2(drug) {
	// title
	var title = document.createElement('h2');
	title.innerHTML = drug_name(drug);

	return title;
}

function drug_name(drug) {
	var title_text = drug.Names[0];
	if (drug.Names.length > 1) {
		title_text = title_text + " (" + drug.Names.slice(1).join(", ") + ")"
	}
	return title_text;
}

function create_drug_element(drug) {
	var element = document.createElement('section');

	element.appendChild(drug_h2(drug));

	for (var i = 0; i < sections.length; ++i) {
		format_append_section(sections[i], drug[sections[i]], element, 3, false);
	}

	return element;
}

function create_random_section_element(drugs) {
	// TODO: this could select random drugs with the same section content, which would make a stupid question
	var selection = getRandomSubarray(drugs, 4);

	// create section with header
	var element = document.createElement('section');
	element.appendChild(drug_h2(selection[0]));

	// pick a random section to quiz on
	var random_section = sections.randomElement();

	var shuffled_drugs = shuffleArray(selection);

	for (var i = 0; i < shuffled_drugs.length; ++i) {
		var correct = (shuffled_drugs[i][random_section] === selection[0][random_section]);
		var actual_drug = drug_name(shuffled_drugs[i]);
		// TODO: only shows one drug, even when multiple have the same text
		format_append_section(random_section, shuffled_drugs[i][random_section], element, 3, true, shuffled_drugs[i], correct);
	}

	return element
}

// TODO: map drug_data to inner html?
document.body.appendChild(create_random_section_element(drug_data));

/*
for (var i = 0; i < drug_data.length; ++i) {
	document.body.appendChild(create_drug_element(drug_data[i]));
}
*/
