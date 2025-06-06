let allCodes = [];
let carMakeMap = {};

document.addEventListener("DOMContentLoaded", async () => {
  await loadData();
  populateMakeSelect();
  loadSiteInfo();
});

async function loadSiteInfo() {
  try {
    const res = await fetch("site.json");
    const site = await res.json();

    const el = document.getElementById("siteInfo");
    el.innerHTML = `
      <strong>${site.Title}</strong> | 
      Version <code>${site.Version}</code> |
      Branch <code>${site.Branch}</code> |
      Revision <code>${site.Revision}</code> |
      Built on <code>${site.BuiltOn}</code>
    `;
  } catch (e) {
    console.warn("Failed to load site.json:", e);
  }
}


async function loadData() {
  const files = [
    "Code.json", "CodeType.json", "PartType.json", "SystemCategory.json", "CarMake.json"
  ];

  const [codes, codeTypes, partTypes, systemCats, carMakes] = await Promise.all(
    files.map(file => fetch(`data/${file}`).then(res => res.json()))
  );

  const mapById = (arr, key = 'Id') =>
    arr.reduce((acc, obj) => { acc[obj[key] || obj[key.toLowerCase()]] = obj; return acc; }, {});

  const codeTypeMap = mapById(codeTypes, "CodeTypeId");
  const partTypeMap = mapById(partTypes, "PartTypeId");
  const systemCategoryMap = mapById(systemCats, "SystemCategoryId");
  carMakeMap = mapById(carMakes, "CarMakeId");

  allCodes = codes.map(code => ({
    ...code,
    CodeType: codeTypeMap[code.CodeTypeId]?.Name || "Unknown",
    PartType: partTypeMap[code.PartTypeId]?.PartType || "Unknown",
    SystemCategory: systemCategoryMap[code.SystemCategoryId]?.Name || "Unknown",
    CarMake: carMakeMap[code.CarMakeId]?.Description || "Universal"
  }));
}

function populateMakeSelect() {
  const select = document.getElementById("makeSelect");

  Object.values(carMakeMap).forEach(make => {
    const option = document.createElement("option");
    option.value = make.Name;
    option.textContent = make.Description;
    select.appendChild(option);
  });
}

function lookupCode() {
  const makeFilter = document.getElementById("makeSelect").value.toLowerCase();
  const codesInput = document.getElementById("codeInput").value.trim().toLowerCase();
  const codeList = codesInput.split(",").map(c => c.trim()).filter(c => c);

  const results = allCodes.filter(code =>
    (makeFilter === "" || code.CarMake.toLowerCase() === makeFilter) &&
    (codeList.length === 0 || codeList.includes(code.DiagnosticCode.toLowerCase()))
  );

  populateTable(results);
}

function populateTable(results) {
  const tbody = document.getElementById("resultsTable").querySelector("tbody");
  tbody.innerHTML = "";

  results.forEach(entry => {
    const tr = document.createElement("tr");

    // DiagnosticCode as clickable link if DetailsUrl exists
    const tdCode = document.createElement("td");
    const url = entry.DetailsUrl?.trim();
    
    if (url) {
      const link = document.createElement("a");
      link.href = url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.title = `Open details for ${entry.DiagnosticCode}`;
      link.innerHTML = `<strong>${entry.DiagnosticCode}</strong>`;
      tdCode.appendChild(link);
    } else {
      tdCode.textContent = entry.DiagnosticCode;
    }
    
    tr.appendChild(tdCode);

    // Description
    const tdDesc = document.createElement("td");
    tdDesc.textContent = entry.Description;
    tr.appendChild(tdDesc);

    // Details column: metadata + clickable link
    const tdDetails = document.createElement("td");
    const detailsText = `${entry.CodeType} - ${entry.PartType} - ${entry.SystemCategory} - ${entry.CarMake}`;
    if (url) {
      const link = document.createElement("a");
      link.href = url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.title = `View full info for ${entry.DiagnosticCode}`;
      link.innerHTML = '<i class="fas fa-external-link-alt"></i> View Details';

      tdDetails.innerHTML = `${detailsText}<br>`;
      tdDetails.appendChild(link);
    } else {
      tdDetails.textContent = detailsText;
    }

    tr.appendChild(tdDetails);
    tbody.appendChild(tr);
  });
}
