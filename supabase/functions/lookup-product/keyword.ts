export type KeywordEntry = [string, string, ...string[]]

export const HARAM_ENTRIES: KeywordEntry[] = [
  ['alcohol',    'Contains alcohol or alcohol-derived ingredient',
   'alcohol', 'alkohol', 'alcool', 'alcol', 'alkol', 'álcool'],
  ['ethanol',    'Contains alcohol or alcohol-derived ingredient',
   'ethanol', 'äthanol', 'éthanol', 'etanolo', 'etanol'],
  ['wine',       'Contains alcohol or alcohol-derived ingredient',
   'wine', 'wein', 'vin', 'vino', 'şarap', 'wijn', 'vinho'],
  ['beer',       'Contains alcohol or alcohol-derived ingredient',
   'beer', 'bier', 'bière', 'birra', 'cerveza', 'bira', 'cerveja',
   'budweiser', 'heineken', 'corona', 'stella artois', 'carlsberg'],
  ['cognac',    'Contains cognac (alcoholic spirit)',   'cognac', 'kognak'],
  ['brandy',    'Contains brandy (alcoholic spirit)',   'brandy', 'branntwein', 'brandewijn'],
  ['whisky',    'Contains whisky (alcoholic spirit)',   'whisky', 'whiskey', 'whiskie', 'viski'],
  ['vodka',     'Contains vodka (alcoholic spirit)',    'vodka', 'wodka'],
  ['rum',       'Contains rum (alcoholic spirit)',      'rum', 'rhum', 'ron'],
  ['gin',       'Contains gin (alcoholic spirit)',      'gin'],
  ['liqueur',   'Contains liqueur (alcoholic)',         'liqueur', 'likör', 'licor', 'likeur', 'liquore'],
  ['schnapps',  'Contains schnapps (alcoholic spirit)', 'schnapps', 'schnaps'],
  ['champagne', 'Contains champagne (alcoholic)',       'champagne', 'sekt', 'cava', 'spumante'],
  ['prosecco',  'Contains prosecco (alcoholic)',        'prosecco'],
  ['bourbon',   'Contains bourbon (alcoholic spirit)',  'bourbon'],
  ['sake',      'Contains sake (alcoholic)',            'sake', 'saké'],
  ['pork',       'Contains pork or pork-derived ingredient',
   'pork', 'schwein', 'schweinefleisch', 'porc', 'maiale', 'cerdo',
   'domuz', 'varkens', 'varkensvlees', 'porco',
   'свинско', 'свински', 'свинска', 'свинско месо', 'свинска месо'],
  ['lard',       'Contains pork fat',
   'lard', 'schmalz', 'schweineschmalz', 'saindoux', 'strutto',
   'manteca de cerdo', 'domuz yağı', 'banha'],
  ['bacon',      'Contains pork product',
   'bacon', 'speck', 'lardons', 'pancetta', 'domuz pastırması'],
  ['ham',        'Contains pork product',
   'ham', 'schinken', 'jambon', 'prosciutto', 'jamón', 'presunto'],
  ['pepperoni',  'Contains pork product',   'pepperoni'],
  ['salami',     'Contains pork product',   'salami', 'salame'],
  ['chorizo',    'Contains pork product',   'chorizo'],
  ['prosciutto', 'Contains pork product',   'prosciutto'],
  ['carmine',    'Carmine/cochineal is insect-derived',
   'carmine', 'karmin', 'carmín', 'karmín', 'carmin'],
  ['cochineal',  'Carmine/cochineal is insect-derived',
   'cochineal', 'cochenille', 'cocciniglia', 'cochinilla', 'koşnil'],
  ['e120', 'Carmine/cochineal color, animal-derived', 'e120', 'e-120'],
  ['e542', 'Bone phosphate, animal-derived','e542', 'e-542'],
  ['e904', 'Shellac, animal-derived',       'e904', 'e-904'],
]

export const SUSPICIOUS_ENTRIES: KeywordEntry[] = [
  ['gelatin', 'Gelatin source often unspecified — predominantly pork-derived in Western products',
   'gelatin', 'gelatine', 'gelatina', 'jelatin', 'gélatine', 'želatina', 'zselatin'],
  ['e441', 'Gelatin (E441), source often unspecified — predominantly pork-derived',
   'e441', 'e-441'],
  ['e920', 'L-cysteine may be animal-derived',          'e920', 'e-920'],
  ['e322', 'Lecithin may be animal-derived',            'e322', 'e-322'],
  ['e471', 'Mono- and diglycerides may be animal-derived','e471','e-471'],
  ['e472', 'Emulsifiers may be animal-derived',         'e472', 'e-472'],
  ['e473', 'Sucrose esters may be animal-derived',      'e473', 'e-473'],
  ['e927', 'Glycine may be animal-derived',             'e927', 'e-927'],
  ['e422', 'Glycerol may be animal-derived',           'e422', 'e-422'],
  ['e481', 'Sodium stearoyl lactylate may be animal-derived', 'e481', 'e-481'],
  ['e482', 'Calcium stearoyl lactylate may be animal-derived', 'e482', 'e-482'],
  ['e570', 'Fatty acids (E570) may be animal-derived', 'e570', 'e-570'],
  ['e572', 'Magnesium stearate may be animal-derived', 'e572', 'e-572'],
  ['e631', 'Disodium inosinate (E631) may be derived from fish or meat', 'e631', 'e-631'],
  ['e635', 'Disodium ribonucleotides (E635) may be derived from fish or meat', 'e635', 'e-635'],
  ['rennet', 'Rennet may be animal-derived',
   'rennet', 'lab', 'labferment', 'présure', 'caglio', 'cuajo',
   'peynir mayası', 'stremsel'],
  ['whey', 'Whey is a dairy ingredient — source verification recommended.',
   'whey', 'molke', 'lactosérum', 'siero di latte',
   'suero de leche', 'peynir suyu', 'wei'],
  ['l-cysteine', 'L-cysteine may be animal-derived',
   'l-cysteine', 'l-cystein', 'l-cystéine', 'l-cisteina', 'l-sistein'],
  ['natural flavour', 'Natural flavour may include animal-derived extracts or be extracted with alcohol.',
   'natural flavour', 'natural flavor', 'natürliches aroma',
   'natürliche aromen', 'arôme naturel', 'aroma naturale',
   'aroma natural', 'doğal aroma', 'natuurlijk aroma'],
  ['flavouring', 'Aroma / flavouring — source may be animal-derived or extracted with alcohol.',
   'flavouring', 'flavoring', 'aroma', 'arôme', 'smaakstof'],
  ['enzymes', 'Enzymes may be extracted from animal sources',
   'enzymes', 'enzyme', 'enzimi', 'enzimas', 'enzim', 'enzymen'],
  ['glycerol', 'Glycerol may be animal-derived',
   'glycerol', 'glycerin', 'glycérol', 'glicerina', 'gliserin', 'glycerine'],
  ['manteca', 'Fat source unspecified — likely animal fat if not labelled "vegetal" or "de cacao"',
   'manteca', 'manteca animal'],
]

const ALCOHOL_FAMILY = new Set([
  'alcohol','alkohol','alcool','alcol','alkol','álcool',
  'ethanol','äthanol','éthanol','etanolo','etanol',
])

const FATTY_ALCOHOL_PREFIX = /\b(cetyl|stearyl|behenyl|lauryl|myristyl|arachidyl|oleyl|cetostearyl|lanolin|isostearyl|octyldodecyl|decyl)\s+/i

// Plant-derived "manteca" phrases — not suspicious (cocoa butter, shea butter, etc.).
// Uses wPre/wPost instead of \b because trailing non-ASCII chars (é in karité) are not \w.
const SAFE_MANTECA_CONTEXT = /(?<![a-zA-Z\dÀ-ɏß])manteca\s+(?:de\s+(?:cacao|kar[ií]t[eé]|coco)|vegetal)(?![a-zA-Z\dÀ-ɏß])/i

// EU marketing labels that allow trace alcohol up to <0,5% — not halal-safe.
const EU_ALCOHOL_FREE_LABEL = /\b(?:alkoholfrei|alkohol[-\s]?frei|alcool[-\s]?frei|alcohol[-\s]?free|alcoholfree|alcoholvrij|alkols[üu]z|analcolic[oa]|non[-\s]?alcoholic)\b/i

const ALCOHOL_PERCENT_CONTEXT = /(?:alkoholgehalt|alcohol\s+content|teneur\s+en\s+alcool|contenuto\s+alcolico|gehalt\s+an\s+alkohol|contenido\s+de\s+alcohol|\b(?:alkohol|alcohol|alcool|alcol|alkol|ethanol|éthanol|äthanol)\b)/i

function isEuAlcoholFreeLabel(text: string): boolean {
  return EU_ALCOHOL_FREE_LABEL.test(text)
}

function isExplicitZeroPercent(whole: number, fracDigits: string | undefined): boolean {
  if (whole !== 0) return false
  if (!fracDigits || fracDigits.length === 0) return true
  return fracDigits.replace(/0/g, '') === ''
}

function hasDeclaredNonZeroAlcohol(text: string): boolean {
  const lower = text.toLowerCase()
  const percentRe = /(?:[<≤]\s*)?(\d+)(?:([.,])(\d+))?\s*%\s*(?:vol\.?|abv)?/gi
  let m: RegExpExecArray | null
  while ((m = percentRe.exec(lower)) !== null) {
    const whole = parseInt(m[1], 10)
    const frac = m[3]
    if (isExplicitZeroPercent(whole, frac)) continue
    if (ALCOHOL_PERCENT_CONTEXT.test(lower)) return true
  }
  return /\b(?!0(?:[.,]0+)?\s*%)(\d+(?:[.,]\d+)?)\s*%\s*(?:alkohol|alcohol|alcool|alcol|alkol|ethanol|äthanol|éthanol)\b/i.test(lower)
}

// Pre-negation words across all supported languages (EN/DE/FR/NL/IT/ES/TR/CS/SR/HU).
// Used to suppress false positives like "enthält keine Zutaten vom Schwein".
const NEGATION_WORDS = /\b(?:keine?|nicht|ohne|frei\s+von|sans|pas|geen|zonder|vrij\s+van|no|not|without|free\s+from|free\s+of|senza|sin|içermez|içermemektedir|icermez|icermemektedir|neobsahuje|bez|nema|nem|mentes)\b/i

// Post-negation: absence markers after the keyword (EN/DE/TR trailing forms).
const POST_NEGATION_WORDS = /(?:[-](?:free|frei)\b|\b(?:free|frei|yoktur|yok|bulunmamaktadır|bulunmamaktadir|bulunmaz|içermez|içermemektedir|icermez|icermemektedir)\b|e?frei\b)/i

// Microbial / vegetable / fermentation-produced rennet — explicit non-animal source.
const HALAL_RENNET_SOURCE = /\b(?:mikrobiel\w*|mikrobial|mikrobiyal|microbial|microbien\w*|microbienne|microbico|microbiano|microbiële|pflanzlich\w*|vegetable|vegetal|végétal\w*|vegetarisch\w*|plant\w*|non-animal|fermentation\s+produced)\s+(?:lab(?:ferment)?|rennet|présure|caglio|cuajo|stremsel|peynir\s+mayası|sirilo|oltóanyag|syřidlo)\b|\b(?:fermentation[- ]?produced\s+)?chymosin\b|\bfpc\b/i

function isHalalRennetSource(chunk: string): boolean {
  return HALAL_RENNET_SOURCE.test(chunk)
}

function escape(s: string) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') }

// Unicode-aware word boundaries covering basic Latin + extended Latin (À-ɏ, U+00C0-U+024F).
// ß (U+00DF) is added explicitly to guard against case-folding edge cases.
// Mirrors IngredientKeywords.wPre / wPost in the Dart client.
const wPre = '(?<![a-zA-Z\\dÀ-ɏß])'
const wPost = '(?![a-zA-Z\\dÀ-ɏß])'

// Variants that commonly appear as the tail of a hyphenated German/French compound
// (e.g. "Vanille-Aroma", "Erdbeer-Aroma"). They must not match when immediately
// preceded by a hyphen; other keywords (alcohol, pork, …) still match after a
// hyphen so that OFF-style slugs like "contains-alcohol" are caught correctly.
const COMPOUND_TAIL_VARIANTS = new Set(['aroma', 'arôme', 'smaakstof'])
const wPreNoHyphen = '(?<![a-zA-Z\\dÀ-ɏß-])'

function isZeroPercentAlcoholDeclaration(text: string, variant: string): boolean {
  const v = escape(variant)
  return new RegExp(
    `\\b0(?:[.,]0+)?\\s*%\\s*${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))|\\b${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))\\s*(?:\\(?\\s*)?0(?:[.,]0+)?\\s*%`,
    'i',
  ).test(text)
}

function matchesVariant(ingredient: string, variant: string): boolean {
  if (variant.includes(' ')) return ingredient.includes(variant)
  if (ALCOHOL_FAMILY.has(variant)) {
    if (FATTY_ALCOHOL_PREFIX.test(ingredient)) return false
    if (isZeroPercentAlcoholDeclaration(ingredient, variant)) return false
    if (isEuAlcoholFreeLabel(ingredient)) return true
    if (hasDeclaredNonZeroAlcohol(ingredient)) return true
    return new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').test(ingredient)
  }
  if (variant === 'manteca' && SAFE_MANTECA_CONTEXT.test(ingredient)) return false
  if (COMPOUND_TAIL_VARIANTS.has(variant)) {
    return new RegExp(`${wPreNoHyphen}${escape(variant)}${wPost}`, 'i').test(ingredient)
  }
  return new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').test(ingredient)
}

// True when the matched variant is preceded or followed by a negation marker in
// the same ingredient chunk, e.g. "enthält keine Zutaten vom Schwein" or
// "domuz yağı ve katkıları yoktur" → negated.
function isNegated(chunk: string, variant: string, canonical?: string): boolean {
  const lower = chunk.toLowerCase()
  let start: number
  let end: number
  if (variant.includes(' ')) {
    const v = variant.toLowerCase()
    start = lower.indexOf(v)
    if (start < 0) return false
    end = start + v.length
  } else {
    const m = new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').exec(lower)
    if (!m) return false
    start = m.index
    end = m.index + m[0].length
  }
  if (NEGATION_WORDS.test(lower.substring(0, start))) return true
  if (
    canonical === 'alcohol' ||
    canonical === 'ethanol' ||
    ALCOHOL_FAMILY.has(variant)
  ) {
    return false
  }
  return POST_NEGATION_WORDS.test(lower.substring(end))
}

import type { IngredientAnalysisSource } from './ingredientResolution.ts'
import {
  combineMatchSourceKeys,
  isAnalyzableScript,
} from './ingredientResolution.ts'
import { buildSuspiciousExplanation } from './flavouringVerdict.ts'

export interface KeywordResult {
  isHalal: boolean
  isUnknown: boolean
  haram: string[]
  suspicious: string[]
  warnings: Record<string, string>
  /** Flagged ingredient → suspicious canonical (e.g. flavouring, natural flavour). */
  canonicals?: Record<string, string>
  explanation: string
  /** Which ingredient source(s) produced keyword matches (primary, off_en, off_taxonomy, …). */
  keywordMatchSource?: string
  /** Flagged ingredient token → source key that matched it. */
  keywordMatchOrigins?: Record<string, string>
  /** OFF language field used when display text was not keyword-analyzable. */
  analyzeLang?: string | null
}

interface SinglePassResult {
  haram: string[]
  suspicious: string[]
  warnings: Record<string, string>
  canonicals: Record<string, string>
  origins: Record<string, string>
}

function keywordSinglePass(
  ingredients: string[],
  sourceKey: string,
  allHaram: KeywordEntry[],
  allSuspicious: KeywordEntry[],
): SinglePassResult {
  const warnings: Record<string, string> = {}
  const canonicals: Record<string, string> = {}
  const haram: string[] = []
  const suspicious: string[] = []
  const origins: Record<string, string> = {}

  for (const ing of ingredients) {
    const lower = ing.toLowerCase()
    let foundHaram = false
    for (const entry of allHaram) {
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (matchedVariant && !isNegated(lower, matchedVariant, entry[0])) {
        warnings[ing] = entry[1]
        haram.push(ing)
        origins[ing] = sourceKey
        foundHaram = true
        break
      }
    }
    if (foundHaram) continue
    for (const entry of allSuspicious) {
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (
        matchedVariant &&
        entry[0] === 'rennet' &&
        isHalalRennetSource(lower)
      ) {
        continue
      }
      if (matchedVariant && !isNegated(lower, matchedVariant, entry[0])) {
        warnings[ing] = entry[1]
        canonicals[ing] = entry[0]
        suspicious.push(ing)
        origins[ing] = sourceKey
        break
      }
    }
  }

  return { haram, suspicious, warnings, canonicals, origins }
}

function buildKeywordExplanation(
  haram: string[],
  suspicious: string[],
  canonicals: Record<string, string>,
  isUnknown: boolean,
  isUnanalyzableLanguage: boolean,
  labels: string[],
  productName: string,
): string {
  if (haram.length > 0) {
    return `This product contains ingredient(s) that are not permissible: ${haram.join(', ')}. Assessed by keyword matching.`
  }
  if (suspicious.length > 0) {
    return buildSuspiciousExplanation(suspicious, canonicals, labels, productName)
  }
  if (isUnanalyzableLanguage) {
    return 'Ingredients are in a language we cannot analyze. Halal status cannot be determined — check the packaging directly.'
  }
  if (isUnknown) {
    return 'No ingredient data found. Halal status cannot be determined — check the packaging directly.'
  }
  return 'No haram or suspicious ingredients detected. Assessed by keyword matching.'
}

export function keywordAnalysis(
  ingredients: string[],
  extraHaram: KeywordEntry[] = [],
  extraSuspicious: KeywordEntry[] = [],
): KeywordResult {
  return keywordAnalysisFromSources(
    ingredients.length > 0 ? [{ key: 'primary', ingredients }] : [],
    ingredients,
    null,
    extraHaram,
    extraSuspicious,
  )
}

/** Multi-source keyword pass with language-fallback transparency. */
export function keywordAnalysisFromSources(
  sources: IngredientAnalysisSource[],
  displayIngredients: string[],
  analyzeLang: string | null,
  extraHaram: KeywordEntry[] = [],
  extraSuspicious: KeywordEntry[] = [],
): KeywordResult {
  const allHaram = [...HARAM_ENTRIES, ...extraHaram]
  const allSuspicious = [...SUSPICIOUS_ENTRIES, ...extraSuspicious]

  const haram: string[] = []
  const suspicious: string[] = []
  const warnings: Record<string, string> = {}
  const canonicals: Record<string, string> = {}
  const matchOrigins: Record<string, string> = {}
  const matchedSourceKeys: string[] = []

  const seenHaram = new Set<string>()
  const seenSuspicious = new Set<string>()

  for (const source of sources) {
    const pass = keywordSinglePass(
      source.ingredients,
      source.key,
      allHaram,
      allSuspicious,
    )
    if (pass.haram.length > 0 || pass.suspicious.length > 0) {
      matchedSourceKeys.push(source.key)
    }
    for (const ing of pass.haram) {
      const key = ing.toLowerCase()
      if (!seenHaram.has(key)) {
        seenHaram.add(key)
        haram.push(ing)
      }
      matchOrigins[ing] = pass.origins[ing] ?? source.key
      warnings[ing] = pass.warnings[ing] ?? warnings[ing] ?? ''
    }
    for (const ing of pass.suspicious) {
      const key = ing.toLowerCase()
      if (!seenSuspicious.has(key)) {
        seenSuspicious.add(key)
        suspicious.push(ing)
      }
      matchOrigins[ing] = pass.origins[ing] ?? source.key
      warnings[ing] = pass.warnings[ing] ?? warnings[ing] ?? ''
      if (pass.canonicals[ing]) canonicals[ing] = pass.canonicals[ing]
    }
  }

  const primaryText = displayIngredients.join(', ')
  const hasLangFallback = sources.some(
    s => s.key.startsWith('off_') && s.key !== 'off_taxonomy' && s.ingredients.length > 0,
  )

  // Primary label unreadable and no translated OFF text — unknown even when
  // taxonomy IDs exist but matched nothing (e.g. bg:pork + en:water only).
  const isUnanalyzableLanguage = displayIngredients.length > 0 &&
    haram.length === 0 &&
    suspicious.length === 0 &&
    !isAnalyzableScript(primaryText) &&
    !hasLangFallback

  const isUnknown = displayIngredients.length === 0 || isUnanalyzableLanguage
  const explanation = buildKeywordExplanation(
    haram,
    suspicious,
    canonicals,
    displayIngredients.length === 0,
    isUnanalyzableLanguage,
    [],
    '',
  )

  const keywordMatchSource = isUnanalyzableLanguage
    ? 'unanalyzable'
    : combineMatchSourceKeys(matchedSourceKeys)

  return {
    isHalal: !isUnknown && haram.length === 0 && suspicious.length === 0,
    isUnknown,
    haram,
    suspicious,
    warnings,
    canonicals: Object.keys(canonicals).length > 0 ? canonicals : undefined,
    explanation,
    keywordMatchSource,
    keywordMatchOrigins: Object.keys(matchOrigins).length > 0 ? matchOrigins : undefined,
    analyzeLang,
  }
}
