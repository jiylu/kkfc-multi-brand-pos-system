const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  testDeclarations,
  validateMappings,
  verifyRepository,
} = require('./verify-scenarios.cjs');

test('collect literal Jest, parameterized, skipped, and todo declarations without treating helpers as tests', () => {
  const source = `
    describe('suite', () => {
      it('UT-DEMO-001: normal', () => {});
      it.each([1, 2])('UT-DEMO-002: variant %s', (value) => {});
      test.skip('UT-DEMO-003: skipped', () => {});
      test.todo('UT-DEMO-004: planned');
      helper('not a test', () => {});
    });`;
  const declarations = testDeclarations(source, 'demo.spec.ts');
  assert.equal(declarations.length, 4);
  assert.equal(declarations[1].title, 'UT-DEMO-002: variant %s');
  assert.equal(declarations[3].line, 6);
});

const declaration = {
  title: 'UT-DEMO-001: normal',
  file: 'demo.spec.ts',
  line: 1,
};
const scenario = {
  id: 'UT-DEMO-001',
  file: 'demo.feature',
  gherkin:
    'Scenario: Normal\n  Given a fixture\n  When requested\n  Then accept',
};

test('accept a unique ID with a complete matching scenario', () => {
  assert.deepEqual(validateMappings([declaration], [scenario]), []);
});

test('reject missing and dynamic test titles instead of silently leaving them undocumented', () => {
  for (const title of ['normal without an ID', undefined]) {
    assert.match(
      validateMappings([{ ...declaration, title }], [scenario])[0],
      /missing a literal/,
    );
  }
});

test('reject IDs without scenarios and ambiguous feature mappings', () => {
  assert.match(validateMappings([declaration], [])[0], /0 matching/);
  assert.match(
    validateMappings([declaration], [scenario, scenario])[0],
    /2 matching/,
  );
});

test('reject duplicate executable IDs, wrong layer prefixes, and incomplete Gherkin', () => {
  assert.ok(
    validateMappings([declaration, declaration], [scenario]).some((error) =>
      error.includes('also used'),
    ),
  );
  assert.ok(
    validateMappings(
      [{ ...declaration, file: 'demo.http.spec.ts' }],
      [scenario],
    ).some((error) => error.includes('must use IT-')),
  );
  assert.ok(
    validateMappings(
      [declaration],
      [{ ...scenario, gherkin: 'Given a fixture\nWhen requested' }],
    ).some((error) => error.includes('missing a Then')),
  );
});

test('all backend Jest declarations have complete and unambiguous feature documentation', () => {
  const result = verifyRepository();
  assert.ok(result.tests > 0);
  assert.deepEqual(result.errors, []);
});
