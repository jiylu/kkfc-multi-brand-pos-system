const fs = require('node:fs');
const path = require('node:path');
const ts = require('typescript');
const { parseFeature } = require('./gherkin-reporter.cjs');

const idPattern = /\b(?:UT|IT)-[A-Z][A-Z0-9-]*-\d{3}\b/;

function testDeclarations(source, file) {
  const ast = ts.createSourceFile(file, source, ts.ScriptTarget.Latest, true);
  const declarations = [];
  function visit(node) {
    if (ts.isCallExpression(node)) {
      const expression = node.expression.getText(ast);
      const [name, callback] = node.arguments;
      if (
        /^(?:it|test|fit|xit|xtest)(?:\b|\.)/.test(expression) &&
        name &&
        ((callback &&
          (ts.isArrowFunction(callback) ||
            ts.isFunctionExpression(callback))) ||
          /\.todo$/.test(expression))
      ) {
        declarations.push({
          file,
          line: ast.getLineAndCharacterOfPosition(name.getStart(ast)).line + 1,
          title: ts.isStringLiteralLike(name) ? name.text : undefined,
        });
      }
    }
    ts.forEachChild(node, visit);
  }
  visit(ast);
  return declarations;
}

function validateMappings(tests, scenarios) {
  const errors = [];
  const seen = new Map();
  const byId = new Map();
  for (const scenario of scenarios) {
    const matches = byId.get(scenario.id) || [];
    byId.set(scenario.id, [...matches, scenario]);
  }
  for (const test of tests) {
    const location = `${test.file}:${test.line}`;
    const id = test.title?.match(idPattern)?.[0];
    if (!id) {
      errors.push(
        `${location}: missing a literal UT/IT Test ID in the Jest title`,
      );
      continue;
    }
    const expected = test.file.endsWith('.http.spec.ts') ? 'IT-' : 'UT-';
    if (!id.startsWith(expected))
      errors.push(`${location}: ${id} must use ${expected}`);
    if (seen.has(id))
      errors.push(`${location}: ${id} is also used at ${seen.get(id)}`);
    seen.set(id, location);
    const matches = byId.get(id) || [];
    if (matches.length !== 1) {
      errors.push(
        `${location}: ${id} has ${matches.length} matching .feature scenarios; expected exactly one`,
      );
      continue;
    }
    for (const keyword of ['Given', 'When', 'Then']) {
      if (!new RegExp(`^\\s*${keyword}\\s+`, 'm').test(matches[0].gherkin)) {
        errors.push(`${matches[0].file}: ${id} is missing a ${keyword} step`);
      }
    }
  }
  return errors;
}

function filesUnder(directory, suffix) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const file = path.join(directory, entry.name);
    return entry.isDirectory()
      ? filesUnder(file, suffix)
      : file.endsWith(suffix)
        ? [file]
        : [];
  });
}

function verifyRepository(projectRoot = path.resolve(__dirname, '..')) {
  const tests = filesUnder(path.join(projectRoot, 'src'), '.spec.ts').flatMap(
    (file) => testDeclarations(fs.readFileSync(file, 'utf8'), file),
  );
  const scenarios = filesUnder(
    path.resolve(projectRoot, '../features'),
    '.feature',
  ).flatMap((file) => parseFeature(fs.readFileSync(file, 'utf8'), file));
  return { tests: tests.length, errors: validateMappings(tests, scenarios) };
}

if (require.main === module) {
  const result = verifyRepository();
  if (result.errors.length) {
    console.error(result.errors.join('\n'));
    process.exitCode = 1;
  } else {
    console.log(
      `Gherkin traceability: all ${result.tests} Jest declarations have a unique Test ID and a matching Given/When/Then scenario.`,
    );
  }
}

module.exports = { testDeclarations, validateMappings, verifyRepository };
