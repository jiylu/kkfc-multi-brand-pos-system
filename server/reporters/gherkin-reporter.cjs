const fs = require('node:fs');
const path = require('node:path');

const testId = /\b(?:UT|IT)-[A-Z][A-Z0-9-]*-\d{3}\b/;

// Read scenario descriptions for reporting; Jest still executes the assertions.
function parseFeature(source, file) {
  const scenarios = [];
  let feature = '';
  let background = [];
  let inBackground = false;
  let pendingId;
  let current;
  let docString;
  function finish() {
    if (current?.id) {
      scenarios.push({
        ...current,
        feature,
        file,
        gherkin: [
          `Feature: ${feature}`,
          ...(background.length ? ['', '  Background:', ...background] : []),
          '',
          `  ${current.heading}`,
          ...current.lines,
        ]
          .join('\n')
          .trimEnd(),
      });
    }
    current = undefined;
  }
  for (const line of source.split(/\r?\n/)) {
    const text = line.trim();
    if (docString) {
      (inBackground ? background : current.lines).push(line);
      if (text === docString) docString = undefined;
      continue;
    }
    if (text.startsWith('Feature:')) {
      feature = text.slice(8).trim();
    } else if (text.startsWith('@')) {
      finish();
      pendingId = text.match(testId)?.[0];
    } else if (/^Background:/.test(text)) {
      finish();
      inBackground = true;
    } else if (/^Scenario(?: Outline| Template)?:/.test(text)) {
      finish();
      inBackground = false;
      current = { id: pendingId, heading: text, lines: [] };
      pendingId = undefined;
    } else if (/^Test Case ID:/.test(text) && current) {
      current.id = text.match(testId)?.[0];
    } else if (
      /^(Given|When|Then|And|But|\*)\s|^Examples:|^\||^"""|^```/.test(text)
    ) {
      if (inBackground) background.push(`    ${text}`);
      else if (current) current.lines.push(`    ${text}`);
      if ((inBackground || current) && /^("""|```)/.test(text))
        docString = text.slice(0, 3);
    }
  }
  finish();
  return scenarios;
}

function readScenarios(directory) {
  const scenarios = new Map();
  function visit(folder) {
    for (const entry of fs.readdirSync(folder, { withFileTypes: true })) {
      const file = path.join(folder, entry.name);
      if (entry.isDirectory()) visit(file);
      else if (entry.name.endsWith('.feature')) {
        for (const scenario of parseFeature(
          fs.readFileSync(file, 'utf8'),
          file,
        )) {
          const existing = scenarios.get(scenario.id) || [];
          scenarios.set(scenario.id, [...existing, scenario]);
        }
      }
    }
  }
  visit(directory);
  return scenarios;
}

function describeTest(assertion, scenarios) {
  const id = assertion.fullName.match(testId)?.[0];
  const matches = scenarios.get(id) || [];
  if (matches.length === 1) {
    return { id, gherkin: matches[0].gherkin, source: matches[0].file };
  }
  if (matches.length > 1) {
    return {
      id,
      note: 'Multiple feature scenarios share this Test ID; resolve the duplicate to display its specification.',
    };
  }
  const inline = assertion.title.match(
    /\bGiven\s+(.+?),?\s+When\s+(.+?),?\s+Then\s+(.+)$/s,
  );
  if (inline) {
    return {
      id,
      source: 'Executed Jest test name',
      gherkin: `Scenario: ${assertion.title.split(/:?\s+Given\s/)[0]}\n  Given ${inline[1]}\n  When ${inline[2]}\n  Then ${inline[3]}`,
    };
  }
  return {
    id,
    note: 'No matching Gherkin scenario. Add a Test ID and corresponding .feature scenario to document this test.',
  };
}

function escapeHtml(value) {
  return String(value).replace(
    /[&<>"']/g,
    (char) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[
        char
      ],
  );
}

function renderReport(results, scenarios, title, projectRoot) {
  const tests = results.testResults.flatMap((suite) =>
    suite.testResults.map((test) => ({
      ...test,
      file: path.relative(projectRoot, suite.testFilePath),
      ...describeTest(test, scenarios),
    })),
  );
  const documented = tests.filter((test) => test.gherkin).length;
  const cards = tests
    .map(
      (test) => `<article data-status="${escapeHtml(test.status)}">
    <header><strong class="status ${escapeHtml(test.status)}">${escapeHtml(test.status.toUpperCase())}</strong> <strong>${escapeHtml(test.id || 'No Test ID')}</strong> <span>${test.duration ?? 0} ms</span></header>
    <h2>${escapeHtml(test.fullName)}</h2><p class="source">${escapeHtml(test.file)}</p>
    ${test.gherkin ? `<pre>${escapeHtml(test.gherkin)}</pre><p class="source">Scenario source: ${escapeHtml(test.source.startsWith(projectRoot) ? path.relative(projectRoot, test.source) : test.source)}</p>` : `<p class="missing">${escapeHtml(test.note)}</p>`}
    ${test.failureMessages.length ? `<details open><summary>Failure details</summary><pre>${escapeHtml(test.failureMessages.join('\n'))}</pre></details>` : ''}
  </article>`,
    )
    .join('\n');
  const suiteErrors = results.testResults
    .filter((suite) => suite.testExecError)
    .map(
      (suite) =>
        `<article><h2>Suite could not run: ${escapeHtml(path.relative(projectRoot, suite.testFilePath))}</h2><pre>${escapeHtml(suite.failureMessage || suite.testExecError.message)}</pre></article>`,
    )
    .join('\n');
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHtml(title)}</title>
  <style>
  :root{font-family:system-ui,sans-serif;color:#172438;background:#f1f5f9}body{max-width:1100px;margin:32px auto;padding:0 20px}h1{font-size:28px}h2{font-size:16px;overflow-wrap:anywhere}p{line-height:1.6}article{background:white;border:1px solid #cbd5e1;border-radius:10px;padding:20px;margin:16px 0}header{display:flex;align-items:center;gap:12px}header span{margin-left:auto;color:#475569}.status{padding:4px 8px;border-radius:4px;background:#e2e8f0}.passed{background:#dcfce7;color:#166534}.failed{background:#fee2e2;color:#991b1b}.pending,.todo,.skipped{background:#fef3c7;color:#78350f}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f8fafc;padding:16px;border-radius:6px;line-height:1.65;font-size:13px}.source{font-size:13px;color:#475569}.missing{color:#78350f}nav{display:flex;gap:12px;flex-wrap:wrap;align-items:center}input,select{font:inherit;padding:10px;border:1px solid #94a3b8;border-radius:6px}input{flex:1;min-width:220px}a{color:#1d4ed8}article[hidden]{display:none}
  </style></head><body><h1>${escapeHtml(title)}</h1>
  <p>${results.numPassedTests} passed · ${results.numFailedTests} failed · ${results.numPendingTests} skipped · ${results.numTodoTests || 0} todo · ${results.numRuntimeErrorTestSuites || 0} suite errors</p>
  <p>${documented} of ${tests.length} executed test entries have Gherkin descriptions. Generated ${escapeHtml(new Date().toISOString())}.</p>
  <p>Statuses describe each Jest test as a whole. Gherkin steps are scenario documentation, not separately executed step results. Outlines retain their Examples tables; each card's Jest name identifies the executed variant.</p>
  <nav><input id="search" type="search" aria-label="Search tests" placeholder="Search Test ID, scenario, steps, or file"><select id="status" aria-label="Filter status"><option value="">All statuses</option><option>passed</option><option>failed</option><option>pending</option><option>todo</option><option>skipped</option></select><a href="jest.html">Original Jest report</a></nav>
  <p id="visible" aria-live="polite"></p>${suiteErrors}${cards}
  <script>
  const search=document.getElementById('search'),status=document.getElementById('status'),cards=[...document.querySelectorAll('article[data-status]')];
  function filter(){const query=search.value.toLowerCase();let count=0;for(const card of cards){card.hidden=!(card.textContent.toLowerCase().includes(query)&&(!status.value||card.dataset.status===status.value));if(!card.hidden)count++;}document.getElementById('visible').textContent=count+' test entries shown';}search.addEventListener('input',filter);status.addEventListener('change',filter);filter();
  </script></body></html>`;
}

class GherkinReporter {
  constructor(globalConfig, options) {
    this.projectRoot = path.resolve(globalConfig.rootDir, '..');
    this.options = options;
  }

  onRunComplete(_contexts, results) {
    const directory = path.resolve(
      this.projectRoot,
      this.options.outputDirectory,
    );
    const scenarios = readScenarios(
      path.resolve(this.projectRoot, '../features'),
    );
    fs.mkdirSync(directory, { recursive: true });
    fs.writeFileSync(
      path.join(directory, 'report.html'),
      renderReport(results, scenarios, this.options.title, this.projectRoot),
    );
    console.log(`Gherkin report: ${path.join(directory, 'report.html')}`);
  }
}

module.exports = GherkinReporter;
module.exports.parseFeature = parseFeature;
module.exports.describeTest = describeTest;
module.exports.renderReport = renderReport;
