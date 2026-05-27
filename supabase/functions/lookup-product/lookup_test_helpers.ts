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
function productsFullChain(
  getData: () => Record<string, unknown> | null,
) {
  return {
    select: () => ({
      eq: () => ({
        maybeSingle: async () => ({ data: getData(), error: null }),
      }),
    }),
  }
}

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
      return productsFullChain(() => opts.productsFullRow ?? null)
    }
    throw new Error(`mockSupabase: unexpected table ${table}`)
  }
  return { from } as unknown as SupabaseClient
}

export interface HandlerMockSupabaseOpts {
  /** First (and usually only) products_full read for cache lookup. */
  cacheProduct?: Record<string, unknown> | null
  /** Row returned after persistLookupAndRespond re-reads products_full. */
  savedProduct?: Record<string, unknown> | null
  geminiLookupEmptyOff?: boolean
  approvedContribution?: string[] | null
  approvedAiRequest?: boolean
}

/** Supabase mock for handleLookup / handler tests (app_config, keywords, etc.). */
export function mockHandlerSupabase(opts: HandlerMockSupabaseOpts = {}): SupabaseClient {
  let productsFullReads = 0
  let upsertCount = 0

  const from = (table: string) => {
    if (table === 'products_full') {
      return {
        select: () => ({
          eq: () => ({
            maybeSingle: async () => {
              productsFullReads++
              if (productsFullReads === 1) {
                return { data: opts.cacheProduct ?? null, error: null }
              }
              return {
                data: opts.savedProduct ?? opts.cacheProduct ?? null,
                error: null,
              }
            },
          }),
        }),
      }
    }
    if (table === 'app_config') {
      return {
        select: () => ({
          eq: () => ({
            maybeSingle: async () => ({
              data: { value: opts.geminiLookupEmptyOff ? 'true' : 'false' },
              error: null,
            }),
          }),
        }),
      }
    }
    if (table === 'keywords') {
      return {
        select: () => Promise.resolve({ data: [], error: null }),
      }
    }
    if (table === 'ingredient_contributions') {
      return {
        select: () => ({
          eq: () => ({
            eq: () => ({
              order: () => ({
                limit: () => ({
                  maybeSingle: async () => ({
                    data: opts.approvedContribution?.length
                      ? { ingredient_text: opts.approvedContribution.join(', ') }
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
    if (table === 'ai_ingredient_requests') {
      return {
        select: () => ({
          eq: () => ({
            eq: () => ({
              limit: () => ({
                maybeSingle: async () => ({
                  data: opts.approvedAiRequest ? { id: '1' } : null,
                  error: null,
                }),
              }),
            }),
          }),
        }),
      }
    }
    if (table === 'products' || table === 'product_analysis') {
      return {
        upsert: async () => {
          upsertCount++
          return { error: null }
        },
      }
    }
    throw new Error(`mockHandlerSupabase: unexpected table ${table}`)
  }

  const client = { from, upsertCount: () => upsertCount } as unknown as SupabaseClient
  return client
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
