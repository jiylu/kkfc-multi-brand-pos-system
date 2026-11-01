const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const vm = require('node:vm');
const {
  parseFeature,
  describeTest,
  renderReport,
} = require('./gherkin-reporter.cjs');

test('read both tagged and legacy Test Case ID scenarios without mixing steps', () => {
  const scenarios = parseFeature(
    `Feature: Authentication
  @UT-AUTH-001
  Scenario: Login
    Given an active account
    When login is requested
    Then issue a token

  Scenario: Reject login
    Test Case ID: UT-AUTH-002
    Given an inactive account
    When login is requested
    Then reject it`,
    'auth.feature',
  );
  assert.equal(scenarios.length, 2);
  assert.equal(scenarios[0].id, 'UT-AUTH-001');
  assert.match(
    scenarios[0].gherkin,
    /Given an active account\n    When login is requested\n    Then issue a token/,
  );
  assert.doesNotMatch(scenarios[0].gherkin, /inactive/);
  assert.equal(scenarios[1].id, 'UT-AUTH-002');
});

test('preserve Background, And, But, Examples tables, and docstring contents', () => {
  const [scenario] = parseFeature(
    `Feature: Orders
  Background:
    Given a cashier
  @IT-ORD-001
  Scenario Outline: Create order
    Given a <channel> order
    And a body:
      """json
      {"notes":"hello"}
      """
    When submitted
    Then accept it
    But hide recipe instructions
    Examples:
      | channel |
      | TAKEAWAY |`,
    'orders.feature',
  );
  for (const content of [
    'Background:',
    'Given a cashier',
    'Scenario Outline:',
    'And a body:',
    '{"notes":"hello"}',
    'But hide recipe instructions',
    'Examples:',
    '| TAKEAWAY |',
  ]) {
    assert.ok(scenario.gherkin.includes(content), content);
  }
});

test('match parameterized test variants by Test ID and retain the full outline', () => {
  const scenario = {
    gherkin:
      'Scenario Outline: Claim\n  Given <role>\n  When claimed\n  Then save\n  Examples:\n    | role |\n    | staff |',
    file: 'kitchen.feature',
  };
  const scenarios = new Map([['IT-KT-001', [scenario]]]);
  const result = describeTest(
    {
      fullName: 'Kitchen IT-KT-001: allows KITCHEN_STAFF',
      title: 'IT-KT-001: allows KITCHEN_STAFF',
    },
    scenarios,
  );
  assert.equal(result.gherkin, scenario.gherkin);
  assert.equal(result.source, 'kitchen.feature');
});

test('use concrete inline Gherkin when no feature scenario exists', () => {
  const title =
    'UT-NEW-001: Given a queued ticket, When claimed, Then save the preparer';
  const result = describeTest(
    { title, fullName: `Tickets ${title}` },
    new Map(),
  );
  assert.equal(
    result.gherkin,
    'Scenario: UT-NEW-001\n  Given a queued ticket\n  When claimed\n  Then save the preparer',
  );
});

test('report missing and ambiguous mappings without inventing Gherkin', () => {
  const assertion = {
    title: 'UT-AUTH-001: login',
    fullName: 'Auth UT-AUTH-001: login',
  };
  assert.match(describeTest(assertion, new Map()).note, /No matching Gherkin/);
  const result = describeTest(assertion, new Map([['UT-AUTH-001', [{}, {}]]]));
  assert.match(result.note, /Multiple feature scenarios/);
  assert.equal(result.gherkin, undefined);
});

test('escape report content and retain failed, skipped, and suite setup failures', () => {
  const projectRoot = path.resolve('server');
  const result = {
    numPassedTests: 0,
    numFailedTests: 1,
    numPendingTests: 1,
    testResults: [
      {
        testFilePath: path.join(projectRoot, 'src', 'auth.spec.ts'),
        testExecError: { message: 'setup <failed>' },
        testResults: [
          {
            title: '<script>alert(1)</script>',
            fullName: '<script>alert(1)</script>',
            status: 'failed',
            failureMessages: ['expected <body>'],
            duration: 2,
          },
          {
            title: 'skipped',
            fullName: 'skipped',
            status: 'pending',
            failureMessages: [],
          },
        ],
      },
    ],
  };
  const html = renderReport(result, new Map(), 'Report <title>', projectRoot);
  assert.ok(!html.includes('<script>alert(1)</script>'));
  for (const content of [
    '&lt;script&gt;',
    'expected &lt;body&gt;',
    'setup &lt;failed&gt;',
    'data-status="pending"',
    '1 failed',
    '1 skipped',
    'not separately executed step results',
    'jest.html',
  ])
    assert.ok(html.includes(content), content);
});

test('search and status filters combine and retain skipped entries', () => {
  const cards = [
    {
      textContent: 'UT-AUTH-001 Given an active account',
      dataset: { status: 'passed' },
    },
    {
      textContent: 'UT-KT-001 Given a queued ticket',
      dataset: { status: 'failed' },
    },
    {
      textContent: 'UT-KT-002 Given an assigned ticket',
      dataset: { status: 'pending' },
    },
  ];
  const controls = {
    search: { value: '', addEventListener() {} },
    status: { value: '', addEventListener() {} },
    visible: { textContent: '' },
  };
  const html = renderReport(
    {
      testResults: [],
      numPassedTests: 0,
      numFailedTests: 0,
      numPendingTests: 0,
    },
    new Map(),
    'Tests',
    path.resolve('server'),
  );
  const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
  const context = vm.createContext({
    document: {
      getElementById: (id) => controls[id],
      querySelectorAll: () => cards,
    },
  });
  vm.runInContext(script, context);
  assert.equal(controls.visible.textContent, '3 test entries shown');
  controls.search.value = 'queued';
  vm.runInContext('filter()', context);
  assert.deepEqual(
    cards.map((card) => card.hidden),
    [true, false, true],
  );
  controls.status.value = 'pending';
  vm.runInContext('filter()', context);
  assert.equal(controls.visible.textContent, '0 test entries shown');
  controls.search.value = '';
  vm.runInContext('filter()', context);
  assert.deepEqual(
    cards.map((card) => card.hidden),
    [true, true, false],
  );
});
