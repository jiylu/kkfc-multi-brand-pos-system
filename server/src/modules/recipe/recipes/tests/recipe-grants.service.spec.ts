import { ConfigService } from '@nestjs/config';
import { RecipeGrantsService } from '../recipe-grants.service';

describe('Recipe delegation configuration', () => {
  const grant = {
    user_id: '00000000-0000-4000-8000-000000000001',
    recipe_id: '00000000-0000-4000-8000-000000000002',
    brand_id: '00000000-0000-4000-8000-000000000003',
    approved_by_id: '00000000-0000-4000-8000-000000000004',
    can_read: true,
    can_write: false,
    is_active: true,
  };
  const build = (raw: string) =>
    new RecipeGrantsService(new ConfigService({ RECIPE_ACCESS_GRANTS: raw }));

  it('UT-RCP-001: defaults to no delegation and matches only exact user and recipe', () => {
    expect(
      new RecipeGrantsService(new ConfigService()).find(
        grant.user_id,
        grant.recipe_id,
      ),
    ).toBeUndefined();
    const service = build(JSON.stringify([grant]));
    expect(service.find(grant.user_id, grant.recipe_id)).toEqual(grant);
    expect(service.find(grant.approved_by_id, grant.recipe_id)).toBeUndefined();
    expect(service.find(grant.user_id, grant.brand_id)).toBeUndefined();
    expect(Object.isFrozen(service.find(grant.user_id, grant.recipe_id))).toBe(
      true,
    );
  });

  it.each([
    '',
    '{invalid',
    '{}',
    'null',
    '[null]',
    JSON.stringify([{ ...grant, can_read: 'true' }]),
    JSON.stringify([{ ...grant, recipe_id: '*' }]),
    JSON.stringify([{ ...grant, approved_by_id: undefined }]),
    JSON.stringify([{ ...grant, is_active: undefined }]),
    JSON.stringify([{ ...grant, department: 'OWNER' }]),
    JSON.stringify([grant, grant]),
  ])(
    'UT-RCP-002: fails closed without echoing invalid configuration %s',
    (raw) => {
      expect(() => build(raw)).toThrow(
        'Invalid RECIPE_ACCESS_GRANTS configuration.',
      );
    },
  );
});
