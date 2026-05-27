/** Shared mocks for lookup-product Deno tests (not imported by production code). */

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export function jsonResp(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

/** Open Food Facts / Open Beauty Facts product JSON envelope. */
export function offApiProduct(product: Record<string, unknown> | null): Response {
  if (!product) {
    return jsonResp({ status: 0, product: undefined })
  }
  return jsonResp({ status: 1, product })
}

export function geminiGenerateText(text: string): Response {
  return jsonResp({
    candidates: [{ content: { parts: [{ text }] }, finishReason: 'STOP' }],
    usageMetadata: { promptTokenCount: 1, candidatesTokenCount: 1, totalTokenCount: 2 },
  })
}

export function claudeTextContent(text: string): Response {
  return jsonResp({ content: [{ type: 'text', text }] })
}

export function aiVerdictJson(overrides: Record<string, unknown> = {}): string {
  return JSON.stringify({
    isHalal: true,
    isUnknown: false,
    haramIngredients: [],
    suspiciousIngredients: [],
    ingredientWarnings: {},
    explanation: 'AI says halal.',
    ...overrides,
  })
}

type FetchHandler = (req: Request) => Response | Promise<Response>

/** Replace global fetch for the duration of `fn`; always restores prior fetch. */
export async function withMockedFetch<T>(
  handler: FetchHandler,
  fn: () => Promise<T>,
): Promise<T> {
  const original = globalThis.fetch
  globalThis.fetch = (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url
    return Promise.resolve(handler(new Request(url, init)))
  }
  try {
    return await fn()
  } finally {
    globalThis.fetch = original
  }
}

export interface MockSupabaseOpts {
  approvedIngredients?: string[] | null
  productsFullRow?: Record<string, unknown> | null
}

/** Minimal Supabase client for reanalysis / persistence tests. */
export function mockSupabase(opts: MockSupabaseOpts = {}): SupabaseClient {
  const from = (table: string) => {
    if (table === 'ingredient_contributions') {
      return {
        select: () => ({
          eq: () => ({
            eq: () => ({
              order: () => ({
                limit: () => ({
                  maybeSingle: async () => ({
                    data: opts.approvedIngredients?.length
                      ? { ingredient_text: opts.approvedIngredients.join(', ') }
                      : null,
                    error: null,
                  }),
                }),
              }),
            }),
          }),
        }),
      }
    }
    if (table === 'products' || table === 'product_analysis') {
      return {
        upsert: async () => ({ error: null }),
      }
    }
    if (table === 'products_full') {
      return {
        select: () => ({
          eq: () => ({
            maybeSingle: async () => ({
              data: opts.productsFullRow ?? null,
              error: null,
            }),
          }),
        }),
      }
    }
    throw new Error(`mockSupabase: unexpected table ${table}`)
  }
  return { from } as unknown as SupabaseClient
}

const TEST_ENV_KEYS = [
  'GEMINI_API_KEY',
  'GEMINI_ENABLED',
  'CLAUDE_API_KEY',
  'CLAUDE_ENABLED',
] as const

export function saveTestEnv(): Record<string, string | undefined> {
  const saved: Record<string, string | undefined> = {}
  for (const k of TEST_ENV_KEYS) {
    saved[k] = Deno.env.get(k)
  }
  return saved
}

export function restoreTestEnv(saved: Record<string, string | undefined>): void {
  for (const k of TEST_ENV_KEYS) {
    const v = saved[k]
    if (v === undefined) Deno.env.delete(k)
    else Deno.env.set(k, v)
  }
}

export function setAiEnvEnabled(): void {
  Deno.env.set('GEMINI_API_KEY', 'test-gemini-key')
  Deno.env.set('GEMINI_ENABLED', 'true')
  Deno.env.set('CLAUDE_API_KEY', 'test-claude-key')
  Deno.env.set('CLAUDE_ENABLED', 'true')
}
