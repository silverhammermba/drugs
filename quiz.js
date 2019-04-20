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

function format_append_section(name, section, element, level, correct) {
	var div = document.createElement('div');
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
			item.innerHTML = section[j];
			list.appendChild(item);
		}
		div.appendChild(list);
	} else if (section && (typeof section === "object")) {
		for (var subsection in section) {
			format_append_section(subsection, section[subsection], div, level + 1, correct);
		}
	} else if (typeof section === "string") {
		var par = document.createElement('p');
		par.innerHTML = section;
		div.appendChild(par);
	} else {
		console.log("Can't format section:", section);
	}

	element.appendChild(div);
}

function drug_h2(drug) {
	// title
	var title = document.createElement('h2');
	var title_text = drug.Names[0];
	if (drug.Names.length > 1) {
		title_text = title_text + " (" + drug.Names.slice(1).join(", ") + ")"
	}
	title.innerHTML = title_text;

	return title;
}

function create_drug_element(drug) {
	var element = document.createElement('section');

	element.appendChild(drug_h2(drug));

	for (var i = 0; i < sections.length; ++i) {
		format_append_section(sections[i], drug[sections[i]], element, 3);
	}

	return element;
}

function create_random_section_element(drugs) {
	// TODO: this could select random drugs with the same section content, which would make a stupid question
	var selection = getRandomSubarray(drugs, 4);

	var element = document.createElement('section');
	element.appendChild(drug_h2(selection[0]));

	var random_section = sections.randomElement();

	var choices = [];

	for (var i = 0; i < selection.length; ++i) {
		choices.push(selection[i][random_section]);
	}

	choices = shuffleArray(choices);
	console.log(choices)

	for (var i = 0; i < choices.length; ++i) {
		var correct = (choices[i] === selection[0][random_section]);
		format_append_section(random_section, choices[i], element, 3, correct);
	}

	return element
}

document.body.appendChild(create_random_section_element(drug_data));

/*
for (var i = 0; i < drug_data.length; ++i) {
	document.body.appendChild(create_drug_element(drug_data[i]));
}
*/
