/**
 * Resolves which OFF ingredient text to display vs analyze for keyword matching.
 * See VERDICT_PIPELINE.md — ingredient language resolution.
 */

/** Locales covered by built-in keyword variant lists (keyword.ts / app constants). */
export const KEYWORD_LOCALES = [
  'en', 'de', 'fr', 'tr', 'es', 'it', 'nl', 'sr', 'hu', 'cs',
] as const

export type KeywordLocale = typeof KEYWORD_LOCALES[number]

export type IngredientMatchSourceKey =
  | 'primary'
  | 'off_taxonomy'
  | `off_${KeywordLocale}`
  | 'unanalyzable'
  | 'none'

export interface IngredientAnalysisSource {
  key: IngredientMatchSourceKey
  ingredients: string[]
}

export interface ResolvedOffIngredients {
  /** Shown in the app — original label language from OFF. */
  display: string[]
  /** Sources passed to keyword matching (may include fallbacks + taxonomy). */
  sources: IngredientAnalysisSource[]
  displayLang: string
  /** When analysis used a different OFF language field than display. */
  analyzeLang: string | null
}

// Latin extended + digits/punctuation — mirrors keyword.ts word-boundary range.
const LATIN_LETTER = /[a-zA-Z\dÀ-ɏß]/u
const CYRILLIC_LETTER = /[\u0400-\u04FF]/u
const ARABIC_LETTER = /[\u0600-\u06FF]/u
const CJK_LETTER = /[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF]/u
const E_NUMBER = /\be-?\s?\d{3,4}\b/i

export function splitIngredientText(text: string): string[] {
  return text
    .split(/[,;]/)
    .map(s => s.trim())
    .filter(s => s.length > 0)
}

// deno-lint-ignore no-explicit-any
export function parseDisplayIngredientList(pd: Record<string, any>): string[] {
  let text: string = (pd['ingredients_text'] ?? '').trim()
  if (!text) {
    const structured = pd['ingredients']
    if (Array.isArray(structured) && structured.length > 0) {
      text = structured
        // deno-lint-ignore no-explicit-any
        .filter((i: any) => typeof i?.text === 'string')
        // deno-lint-ignore no-explicit-any
        .map((i: any) => i.text as string)
        .join(', ')
    }
  }
  return splitIngredientText(text.toLowerCase())
}

/** True when keyword lists can reasonably match the text (Latin extended or E-numbers). */
export function isAnalyzableScript(text: string): boolean {
  if (!text.trim()) return false
  if (E_NUMBER.test(text)) return true

  let latin = 0
  let nonLatin = 0
  for (const ch of text) {
    if (/\s|[\d.,()%\-_]/u.test(ch)) continue
    if (LATIN_LETTER.test(ch)) latin++
    else if (
      CYRILLIC_LETTER.test(ch) || ARABIC_LETTER.test(ch) || CJK_LETTER.test(ch)
    ) nonLatin++
  }
  if (latin === 0 && nonLatin === 0) return true
  if (latin === 0 && nonLatin > 0) return false
  return latin >= nonLatin
}

function isSupportedLocale(lang: string): boolean {
  return (KEYWORD_LOCALES as readonly string[]).includes(lang)
}

// deno-lint-ignore no-explicit-any
function extractOffTaxonomyIds(pd: Record<string, any>): string[] {
  const ids: string[] = []
  const structured = pd['ingredients']
  if (!Array.isArray(structured)) return ids

  // deno-lint-ignore no-explicit-any
  const addId = (item: any) => {
    const raw = (item?.id ?? '').toString()
    const colon = raw.indexOf(':')
    if (colon > 0) {
      const canonical = raw
        .slice(colon + 1)
        .replace(/-/g, ' ')
        .trim()
      if (canonical) ids.push(canonical)
    }
    const sub = item?.ingredients
    if (Array.isArray(sub)) sub.forEach(addId)
  }

  structured.forEach(addId)
  return ids
}

// deno-lint-ignore no-explicit-any
export function resolveOffIngredientAnalysis(pd: Record<string, any>): ResolvedOffIngredients {
  const display = parseDisplayIngredientList(pd)
  const displayLang = ((pd['ingredients_lc'] ?? pd['lc'] ?? '') as string).toLowerCase()
  const primaryText = display.join(', ')

  const sources: IngredientAnalysisSource[] = []
  if (display.length > 0) {
    sources.push({ key: 'primary', ingredients: display })
  }

  const localeSupported = displayLang === '' || isSupportedLocale(displayLang)
  const scriptAnalyzable = isAnalyzableScript(primaryText)
  let analyzeLang: string | null = null

  if (display.length > 0 && (!localeSupported || !scriptAnalyzable)) {
    for (const lang of KEYWORD_LOCALES) {
      const alt = (pd[`ingredients_text_${lang}`] ?? '').toString().trim()
      if (!alt) continue
      const altList = splitIngredientText(alt.toLowerCase())
      if (altList.length === 0) continue
      sources.push({ key: `off_${lang}`, ingredients: altList })
      if (analyzeLang === null) analyzeLang = lang
    }
  }

  const taxonomyIds = extractOffTaxonomyIds(pd)
  if (taxonomyIds.length > 0) {
    sources.push({ key: 'off_taxonomy', ingredients: taxonomyIds })
  }

  return { display, sources, displayLang, analyzeLang }
}

/** Compact key describing which sources contributed matches (for storage + UI). */
export function combineMatchSourceKeys(keys: string[]): IngredientMatchSourceKey | string {
  const unique = [...new Set(keys.filter(Boolean))]
  if (unique.length === 0) return 'none'
  if (unique.length === 1) return unique[0] as IngredientMatchSourceKey
  return unique.sort().join('+')
}
