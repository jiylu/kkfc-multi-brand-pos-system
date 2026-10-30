import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { isUUID } from 'class-validator';

interface RecipeGrant {
  user_id: string;
  recipe_id: string;
  brand_id: string;
  approved_by_id: string;
  can_read: boolean;
  can_write: boolean;
  is_active: boolean;
}

// Trusted deployment configuration only; never populated from request data.
// Validate once at startup and require a restart to apply grant changes.
@Injectable()
export class RecipeGrantsService {
  private readonly grants: readonly Readonly<RecipeGrant>[];

  constructor(config: ConfigService) {
    const raw = config.get<string>('RECIPE_ACCESS_GRANTS');
    if (raw === undefined) {
      this.grants = [];
      return;
    }
    const invalid = () =>
      new Error('Invalid RECIPE_ACCESS_GRANTS configuration.');
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw) as unknown;
    } catch {
      throw invalid();
    }
    if (!Array.isArray(parsed)) throw invalid();
    const keys = new Set<string>();
    this.grants = Object.freeze(
      parsed.map((entry: unknown) => {
        if (!entry || typeof entry !== 'object' || Array.isArray(entry))
          throw invalid();
        const grant = entry as Record<string, unknown>;
        const ids = ['user_id', 'recipe_id', 'brand_id', 'approved_by_id'];
        const flags = ['can_read', 'can_write', 'is_active'];
        if (
          Object.keys(grant).some((key) => ![...ids, ...flags].includes(key)) ||
          ids.some(
            (key) => typeof grant[key] !== 'string' || !isUUID(grant[key]),
          ) ||
          flags.some((key) => typeof grant[key] !== 'boolean')
        )
          throw invalid();
        const validated = grant as unknown as RecipeGrant;
        const key = `${validated.user_id}:${validated.recipe_id}`;
        if (keys.has(key)) throw invalid();
        keys.add(key);
        return Object.freeze(validated);
      }),
    );
  }

  find(userId: string, recipeId: string) {
    return this.grants.find(
      (grant) => grant.user_id === userId && grant.recipe_id === recipeId,
    );
  }
}
