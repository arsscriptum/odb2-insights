let currentMakeData = {};

async function populateCarMakes() {
  const response = await fetch('data/CarMakes.json');
  const carMakes = await response.json();
  const select = document.getElementById('makeSelect');

  carMakes.forEach(make => {
    const option = document.createElement('option');
    option.value = make.Name.toLowerCase();  // e.g. "bmw"
    option.textContent = make.Name.toUpperCase(); // e.g. "BMW"
    select.appendChild(option);
  });
}

async function loadMakeCodes() {
  const make = document.getElementById('makeSelect').value;
  if (!make) return;

  const path = `data/ManufacturerSpecificCodes/${make}.json`;

  try {
    const response = await fetch(path);
    currentMakeData = await response.json();
  } catch (err) {
    console.error(`Failed to load manufacturer codes for ${make}`, err);
    currentMakeData = {};
  }
}

function lookupCode() {
  const code = document.getElementById('codeInput').value.toUpperCase();
  const resultDiv = document.getElementById('result');

  const entry = currentMakeData[code];
  if (entry) {
    resultDiv.innerHTML = `
      <h2>${code}</h2>
      <p>${entry.description || 'No description available.'}</p>
      ${entry.causes ? `<ul>${entry.causes.map(c => `<li>${c}</li>`).join('')}</ul>` : ''}
    `;
  } else {
    resultDiv.innerHTML = `<p>No information found for <strong>${code}</strong>.</p>`;
  }
}

document.addEventListener('DOMContentLoaded', populateCarMakes);
