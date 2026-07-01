/**
 * Halal verdict pipeline (bootstrap → AI tiers → post-rules).
 * Documented step-by-step in VERDICT_PIPELINE.md — update that file when changing order or skip logic.
 */
import { keywordAnalysis, keywordAnalysisFromSources } from './keyword.ts'
import type { KeywordEntry, KeywordResult } from './keyword.ts'
import type { IngredientAnalysisSource } from './ingredientResolution.ts'
import {
  ANIMAL_PRODUCT_CATEGORIES, HALAL_CERT_LABELS, ANIMAL_PRODUCT_NAME_TERMS,
  ANIMAL_INGREDIENT_TERMS, matchesAnimalTerm,
} from './categories.ts'
import {
  analyzeWithGemini, analyzeWithClaude, analyzeWithClaudeVision, type AiVerdict,
} from './ai.ts'
import { adjustFlavouringForVegan } from './flavouringVerdict.ts'

export interface VerdictContext {
  barcode: string
  /** Ingredient list shown in the app. */
  ingredients: string[]
  /** Optional multi-source analysis (OFF language fallback + taxonomy). */
  analyzeSources?: IngredientAnalysisSource[]
  displayLang?: string
  analyzeLang?: string | null
  name: string
  labels: string[]
  /** OFF `additives_tags` raw array (e.g. ["en:e120-carmine", "en:e441"]). */
  additivesTags: string[]
  rawCategories: string[]
  isNonFood: boolean
  ingredientSource: 'off' | 'ai' | 'community'
  haramCategory: string | null
  isHalalByCategory: boolean
  customHaramEntries: KeywordEntry[]
  customSuspiciousEntries: KeywordEntry[]
  imageIngredientsUrl: string
  /** When true, skip Gemini/Claude text AI and vision (stored-data re-analysis only). */
  skipAi?: boolean
}

export interface VerdictResult {
  isHalal: boolean
  isUnknown: boolean
  haramIngredients: string[]
  suspiciousIngredients: string[]
  ingredientWarnings: Record<string, string>
  haramLabels: string[]
  suspiciousLabels: string[]
  labelWarnings: Record<string, string>
  haramAdditives: string[]
  suspiciousAdditives: string[]
  additiveWarnings: Record<string, string>
  explanation: string
  analyzedByAI: boolean
  requiresHalalCert: boolean
  ingredients: string[]
  keywordMatchSource?: string
  keywordMatchOrigins?: Record<string, string>
  /** Flagged ingredient/label/additive token → source language of the matched keyword (e.g. "de"). Transparency only. */
  keywordMatchLanguages?: Record<string, string>
  /** Category/name/ingredient term that triggered `requiresHalalCert`, when set. */
  halalCertMatchTerm?: string
  /** Source language of `halalCertMatchTerm` (category tag prefix, or the term's tagged language). */
  halalCertMatchLang?: string | null
  analyzeLang?: string | null
  displayLang?: string
}

/** Verdict fields mutated by keyword, AI, and post-analysis steps. */
export interface VerdictSnapshot {
  isHalal: boolean
  isUnknown: boolean
  haramIngredients: string[]
  suspiciousIngredients: string[]
  ingredientWarnings: Record<string, string>
  haramLabels: string[]
  suspiciousLabels: string[]
  labelWarnings: Record<string, string>
  haramAdditives: string[]
  suspiciousAdditives: string[]
  additiveWarnings: Record<string, string>
  explanation: string
  keywordMatchSource?: string
  keywordMatchOrigins?: Record<string, string>
  keywordMatchLanguages?: Record<string, string>
  halalCertMatchTerm?: string
  halalCertMatchLang?: string | null
  analyzeLang?: string | null
}

interface VerdictState {
  ctx: VerdictContext
  ingredients: string[]
  kwFirst: KeywordResult
  kwLabels: KeywordResult
  kwAdditives: KeywordResult
  analyzedByAI: boolean
  requiresHalalCert: boolean
  snapshot: VerdictSnapshot
}

type AsyncVerdictStep = (state: VerdictState) => Promise<VerdictState>

interface AiEnv {
  aiVerdictEnabled: boolean
  geminiEnabled: boolean
  claudeEnabled: boolean
  geminiKey: string | undefined
  claudeKey: string | undefined
}

interface PostRuleContext {
  ctx: VerdictContext
  kwFirst: KeywordResult
  kwLabels: KeywordResult
  kwAdditives: KeywordResult
}

type PostRule = (snapshot: VerdictSnapshot, ruleCtx: PostRuleContext) => VerdictSnapshot

const POST_ANALYSIS_RULES: PostRule[] = [
  applyKeywordHaramOverride,
  applyKeywordSuspiciousOverride,
  applyHaramCategoryOverride,
  applyNameFallback,
  applyLabelHaramOverride,
  applyLabelSuspiciousOverride,
  applyAdditivesHaramOverride,
  applyAdditivesSuspiciousOverride,
  applyVeganFlavouringAdjustment,
]

const VERDICT_PIPELINE: AsyncVerdictStep[] = [
  stepTieredTextAi,
  stepVisionWithOptionalAi,
  stepPostAnalysis,
]

export async function computeVerdict(ctx: VerdictContext): Promise<VerdictResult> {
  let state = createInitialState(ctx)
  for (const step of VERDICT_PIPELINE) {
    state = await step(state)
  }
  return toVerdictResult(state)
}

/** Strip placeholder tokens that are not real ingredients (e.g. stored "unknown." from OFF). */
function stripPlaceholderIngredients(ingredients: string[]): string[] {
  return ingredients.filter(i => !/^unknown[.!?,;:]*$/i.test(i.trim()))
}

function runInitialKeywordAnalysis(ctx: VerdictContext): KeywordResult {
  if (ctx.analyzeSources && ctx.analyzeSources.length > 0) {
    return keywordAnalysisFromSources(
      ctx.analyzeSources,
      ctx.ingredients,
      ctx.analyzeLang ?? null,
      ctx.customHaramEntries,
      ctx.customSuspiciousEntries,
    )
  }
  return keywordAnalysis(
    ctx.ingredients,
    ctx.customHaramEntries,
    ctx.customSuspiciousEntries,
  )
}

/** Strip the language prefix (e.g. "en:", "fr:") from an OFF tag slug. */
function stripLangPrefix(tag: string): string {
  return tag.includes(':') ? tag.split(':').slice(1).join(':') : tag
}

/** Normalize additive tags for keyword analysis: deduplicate + strip lang prefix. */
function normalizeAdditiveTags(tags: string[]): string[] {
  return [...new Set(tags.map(stripLangPrefix).filter(t => t.length > 0))]
}

/** Deduplicate labels that differ only in language prefix or hyphen/space variant (e.g. "en:pure-pork" vs "en:pure pork"). */
function deduplicateLabels(labels: string[]): string[] {
  const normalize = (l: string) => l.toLowerCase().replace(/^[a-z]{2,3}:/, '').replace(/[-_]/g, ' ').trim()
  const seen = new Set<string>()
  return labels.filter(l => {
    const key = normalize(l)
    return seen.has(key) ? false : (seen.add(key), true)
  })
}

function createInitialState(ctx: VerdictContext): VerdictState {
  const ingredients = stripPlaceholderIngredients(ctx.ingredients)
  const ctx2 = ingredients.length !== ctx.ingredients.length ? { ...ctx, ingredients } : ctx
  const { isNonFood, isHalalByCategory } = ctx2
  const kwFirst = runInitialKeywordAnalysis(ctx2)
  const kwLabelsRaw = keywordAnalysis(deduplicateLabels(ctx.labels), ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = {
    ...kwLabelsRaw,
    warnings: Object.fromEntries(
      Object.entries(kwLabelsRaw.warnings).map(([k, v]) => [k, `Found on label: ${v}`]),
    ),
  }
  const kwAdditivesRaw = keywordAnalysis(
    normalizeAdditiveTags(ctx.additivesTags),
    ctx.customHaramEntries,
    ctx.customSuspiciousEntries,
  )
  const kwAdditives = {
    ...kwAdditivesRaw,
    warnings: Object.fromEntries(
      Object.entries(kwAdditivesRaw.warnings).map(([k, v]) => [k, `Found in additives: ${v}`]),
    ),
  }
  console.log(
    `[${ctx.barcode}] keywords: isHalal=${kwFirst.isHalal} isUnknown=${kwFirst.isUnknown} ` +
    `haram=[${kwFirst.haram.join(', ')}] suspicious=[${kwFirst.suspicious.join(', ')}]`,
  )
  if (kwLabels.haram.length > 0 || kwLabels.suspicious.length > 0) {
    console.log(
      `[${ctx.barcode}] label keywords: haram=[${kwLabels.haram.join(', ')}] suspicious=[${kwLabels.suspicious.join(', ')}]`,
    )
  }
  if (kwAdditives.haram.length > 0 || kwAdditives.suspicious.length > 0) {
    console.log(
      `[${ctx.barcode}] additive keywords: haram=[${kwAdditives.haram.join(', ')}] suspicious=[${kwAdditives.suspicious.join(', ')}]`,
    )
  }
  const halalByCategoryNoIngredients = isHalalByCategory && ingredients.length === 0
  return {
    ctx: ctx2,
    ingredients,
    kwFirst,
    kwLabels,
    kwAdditives,
    analyzedByAI: false,
    requiresHalalCert: false,
    snapshot: {
      isHalal: isNonFood ? false : (halalByCategoryNoIngredients ? true : kwFirst.isHalal),
      isUnknown: isNonFood ? false : (halalByCategoryNoIngredients ? false : kwFirst.isUnknown),
      haramIngredients: kwFirst.haram,
      suspiciousIngredients: kwFirst.suspicious,
      ingredientWarnings: kwFirst.warnings,
      haramLabels: kwLabels.haram,
      suspiciousLabels: kwLabels.suspicious,
      labelWarnings: kwLabels.warnings,
      haramAdditives: kwAdditives.haram,
      suspiciousAdditives: kwAdditives.suspicious,
      additiveWarnings: kwAdditives.warnings,
      explanation: isNonFood
        ? 'This is a non-food product. Islamic dietary rules do not apply.'
        : (halalByCategoryNoIngredients
            ? 'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.'
            : kwFirst.explanation),
      keywordMatchSource: kwFirst.keywordMatchSource,
      keywordMatchOrigins: kwFirst.keywordMatchOrigins,
      keywordMatchLanguages: {
        ...kwFirst.keywordMatchLanguages,
        ...kwLabels.keywordMatchLanguages,
        ...kwAdditives.keywordMatchLanguages,
      },
      analyzeLang: kwFirst.analyzeLang,
    },
  }
}

function withSnapshot(state: VerdictState, snapshot: VerdictSnapshot): VerdictState {
  return { ...state, snapshot }
}

function withAiVerdict(state: VerdictState, ai: AiVerdict): VerdictState {
  return withSnapshot(state, {
    ...state.snapshot,
    isHalal: ai.isHalal,
    isUnknown: ai.isUnknown,
    haramIngredients: ai.haramIngredients,
    suspiciousIngredients: ai.suspiciousIngredients,
    ingredientWarnings: ai.ingredientWarnings,
    explanation: ai.explanation,
  })
}

function withAnalyzedByAI(state: VerdictState, ai: AiVerdict): VerdictState {
  return { ...withAiVerdict(state, ai), analyzedByAI: true }
}

function readAiEnv(): AiEnv {
  return {
    aiVerdictEnabled: Deno.env.get('AI_VERDICT_ENABLED') === 'true',
    geminiEnabled: Deno.env.get('GEMINI_ENABLED') !== 'false',
    claudeEnabled: Deno.env.get('CLAUDE_ENABLED') !== 'false',
    geminiKey: Deno.env.get('GEMINI_API_KEY'),
    claudeKey: Deno.env.get('CLAUDE_API_KEY'),
  }
}

function shouldSkipTextAi(state: VerdictState): boolean {
  const { ctx, kwFirst, kwLabels, kwAdditives, ingredients } = state
  if (ctx.skipAi) return true
  return ctx.isNonFood || ctx.isHalalByCategory || kwFirst.haram.length > 0 ||
    kwLabels.haram.length > 0 || kwAdditives.haram.length > 0 || ctx.haramCategory !== null ||
    ingredients.length === 0 || ctx.ingredientSource === 'ai'
}

function skipTextAiReason(state: VerdictState): string {
  const { ctx, kwFirst, kwLabels, kwAdditives } = state
  if (ctx.skipAi) return 'rules-only-reanalysis'
  if (ctx.isNonFood) return 'non-food'
  if (ctx.isHalalByCategory) return 'halal-by-category'
  if (ctx.haramCategory !== null) return `haram-category(${ctx.haramCategory})`
  if (kwFirst.haram.length > 0) return `keyword-haram(${kwFirst.haram.join(', ')})`
  if (kwLabels.haram.length > 0) return `label-haram(${kwLabels.haram.join(', ')})`
  if (kwAdditives.haram.length > 0) return `additive-haram(${kwAdditives.haram.join(', ')})`
  if (ctx.ingredientSource === 'ai') return 'ai-sourced-ingredients'
  return 'no-ingredients'
}

async function stepTieredTextAi(state: VerdictState): Promise<VerdictState> {
  if (shouldSkipTextAi(state)) {
    console.log(`[${state.ctx.barcode}] AI: skipped — ${skipTextAiReason(state)}`)
    return state
  }
  const env = readAiEnv()
  const { barcode } = state.ctx
  let next = state

  if (!env.aiVerdictEnabled) {
    console.log(`[${barcode}] AI verdict: skipped — AI_VERDICT_ENABLED not set to true`)
    return state
  }

  if (!env.geminiEnabled) {
    console.log(`[${barcode}] Gemini: skipped — disabled by GEMINI_ENABLED=false`)
  } else if (!env.geminiKey) {
    console.log(`[${barcode}] Gemini: skipped — GEMINI_API_KEY not set`)
  } else {
    const aiVerdict = await analyzeWithGemini(state.ingredients, barcode, env.geminiKey)
    if (aiVerdict) next = withAnalyzedByAI(next, aiVerdict)
  }

  if (!next.analyzedByAI) {
    if (!env.claudeEnabled) {
      console.log(`[${barcode}] Claude: skipped — disabled by CLAUDE_ENABLED=false`)
    } else if (!env.claudeKey) {
      console.log(`[${barcode}] Claude: skipped — CLAUDE_API_KEY not set`)
    } else {
      const aiVerdict = await analyzeWithClaude(state.ingredients, barcode, env.claudeKey)
      if (aiVerdict) next = withAnalyzedByAI(next, aiVerdict)
    }
  }

  return next
}

function shouldRunVision(state: VerdictState): boolean {
  const { ctx, ingredients, analyzedByAI } = state
  if (ctx.skipAi) return false
  return !analyzedByAI && ingredients.length === 0 && !ctx.isNonFood &&
    !ctx.isHalalByCategory && ctx.haramCategory === null
}

async function stepVisionWithOptionalAi(state: VerdictState): Promise<VerdictState> {
  if (!shouldRunVision(state)) return state

  const { ctx } = state
  const { barcode, imageIngredientsUrl, customHaramEntries, customSuspiciousEntries } = ctx
  const env = readAiEnv()

  if (!env.claudeEnabled) {
    console.log(`[${barcode}] Claude vision: skipped — disabled by CLAUDE_ENABLED=false`)
    return state
  }
  if (!imageIngredientsUrl) {
    console.log(`[${barcode}] Claude vision: skipped — no ingredients image`)
    return state
  }
  if (!env.claudeKey) {
    console.log(`[${barcode}] Claude vision: skipped — CLAUDE_API_KEY not set`)
    return state
  }

  const visionIngredients = await analyzeWithClaudeVision(imageIngredientsUrl, barcode, env.claudeKey)
  if (!visionIngredients?.length) return state

  const kwVision = keywordAnalysis(visionIngredients, customHaramEntries, customSuspiciousEntries)
  let next: VerdictState = {
    ...state,
    ingredients: visionIngredients,
    snapshot: {
      ...state.snapshot,
      isHalal: kwVision.isHalal,
      isUnknown: kwVision.isUnknown,
      haramIngredients: kwVision.haram,
      suspiciousIngredients: kwVision.suspicious,
      ingredientWarnings: kwVision.warnings,
      explanation: kwVision.explanation,
      keywordMatchSource: kwVision.keywordMatchSource,
      keywordMatchOrigins: kwVision.keywordMatchOrigins,
      analyzeLang: kwVision.analyzeLang,
    },
  }

  if (kwVision.haram.length > 0) return next

  if (env.geminiEnabled && env.geminiKey) {
    const aiVerdict = await analyzeWithGemini(visionIngredients, barcode, env.geminiKey)
    if (aiVerdict) next = withAnalyzedByAI(next, aiVerdict)
  }
  if (!next.analyzedByAI && env.claudeEnabled && env.claudeKey) {
    const aiVerdict = await analyzeWithClaude(visionIngredients, barcode, env.claudeKey)
    if (aiVerdict) next = withAnalyzedByAI(next, aiVerdict)
  }

  return next
}

async function stepPostAnalysis(state: VerdictState): Promise<VerdictState> {
  const { snapshot, requiresHalalCert } = applyPostAnalysisRules(
    state.snapshot,
    state.ctx,
    state.kwFirst,
    state.kwLabels,
    state.kwAdditives,
  )
  return { ...state, snapshot, requiresHalalCert }
}

/** Exported for unit tests — keyword safety, category, cert, and suspicious rules. */
export function applyPostAnalysisRules(
  snapshot: VerdictSnapshot,
  ctx: VerdictContext,
  kwFirst: KeywordResult,
  kwLabels: KeywordResult = { haram: [], suspicious: [], warnings: {}, isHalal: true, isUnknown: false, explanation: '', keywordMatchSource: undefined, keywordMatchOrigins: {}, analyzeLang: null },
  kwAdditives: KeywordResult = { haram: [], suspicious: [], warnings: {}, isHalal: true, isUnknown: false, explanation: '', keywordMatchSource: undefined, keywordMatchOrigins: {}, analyzeLang: null },
): { snapshot: VerdictSnapshot; requiresHalalCert: boolean } {
  const ruleCtx: PostRuleContext = { ctx, kwFirst, kwLabels, kwAdditives }
  const afterCore = POST_ANALYSIS_RULES.reduce(
    (s, rule) => rule(s, ruleCtx),
    snapshot,
  )
  const { snapshot: afterCert, requiresHalalCert } = applyHalalCertRequirement(afterCore, ctx)
  return {
    requiresHalalCert,
    snapshot: applySuspiciousNotHalal(afterCert, ruleCtx),
  }
}

function applyKeywordHaramOverride(snapshot: VerdictSnapshot, { kwFirst }: PostRuleContext): VerdictSnapshot {
  if (kwFirst.haram.length === 0 || !snapshot.isHalal) return snapshot
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    haramIngredients: [...new Set([...snapshot.haramIngredients, ...kwFirst.haram])],
    ingredientWarnings: { ...snapshot.ingredientWarnings, ...kwFirst.warnings },
    explanation: kwFirst.explanation,
  }
}

function applyKeywordSuspiciousOverride(snapshot: VerdictSnapshot, { kwFirst }: PostRuleContext): VerdictSnapshot {
  if (kwFirst.suspicious.length === 0 || !snapshot.isHalal) return snapshot
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    suspiciousIngredients: [...new Set([...snapshot.suspiciousIngredients, ...kwFirst.suspicious])],
    ingredientWarnings: { ...snapshot.ingredientWarnings, ...kwFirst.warnings },
    explanation: kwFirst.haram.length === 0 ? kwFirst.explanation : snapshot.explanation,
  }
}

function applyHaramCategoryOverride(snapshot: VerdictSnapshot, { ctx }: PostRuleContext): VerdictSnapshot {
  if (!ctx.haramCategory || !snapshot.isHalal) return snapshot
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    explanation: `This product belongs to a category that is not permissible: ${ctx.haramCategory}.`,
  }
}

function applyNameFallback(snapshot: VerdictSnapshot, { ctx }: PostRuleContext): VerdictSnapshot {
  if (!snapshot.isUnknown) return snapshot
  const nameCheck = keywordAnalysis(
    [ctx.name.toLowerCase()],
    ctx.customHaramEntries,
    ctx.customSuspiciousEntries,
  )
  // Only override when the name actually matched a haram keyword (not merely
  // unanalyzable script, which sets isHalal=false with an empty haram list).
  if (nameCheck.haram.length === 0) return snapshot
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    haramIngredients: nameCheck.haram,
    ingredientWarnings: nameCheck.warnings,
    explanation:
      `No ingredient list found, but the product name contains a haram indicator: ${nameCheck.haram.join(', ')}.`,
  }
}

function applyLabelHaramOverride(snapshot: VerdictSnapshot, { kwLabels }: PostRuleContext): VerdictSnapshot {
  if (kwLabels.haram.length === 0) return snapshot
  const mergedHaram = [...new Set([...snapshot.haramLabels, ...kwLabels.haram])]
  const labelNote = `Product label also indicates: ${mergedHaram.join(', ')}.`
  const explanation = snapshot.haramIngredients.length > 0
    ? `${snapshot.explanation} ${labelNote}`
    : `This product's label indicates it contains: ${mergedHaram.join(', ')}.`
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    haramLabels: mergedHaram,
    labelWarnings: { ...snapshot.labelWarnings, ...kwLabels.warnings },
    explanation,
  }
}

function applyLabelSuspiciousOverride(snapshot: VerdictSnapshot, { kwLabels }: PostRuleContext): VerdictSnapshot {
  if (kwLabels.suspicious.length === 0) return snapshot
  const suspiciousLabels = [...new Set([...snapshot.suspiciousLabels, ...kwLabels.suspicious])]
  const mergedLabelWarnings = { ...snapshot.labelWarnings, ...kwLabels.warnings }
  if (!snapshot.isHalal) {
    // Already not-halal — capture labels and append a note to the existing explanation.
    const suspiciousNote = `Product labels may also indicate animal-derived content: ${suspiciousLabels.join(', ')}.`
    return {
      ...snapshot,
      suspiciousLabels,
      labelWarnings: mergedLabelWarnings,
      explanation: `${snapshot.explanation} ${suspiciousNote}`,
    }
  }
  const allFlaggedLabels = [...snapshot.haramLabels, ...suspiciousLabels]
  const explanation =
    snapshot.suspiciousIngredients.length === 0 && snapshot.haramIngredients.length === 0
      ? `Product labels may indicate animal-derived content: ${allFlaggedLabels.join(', ')}.`
      : snapshot.explanation
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    suspiciousLabels,
    labelWarnings: mergedLabelWarnings,
    explanation,
  }
}

function applyAdditivesHaramOverride(snapshot: VerdictSnapshot, { kwAdditives }: PostRuleContext): VerdictSnapshot {
  if (kwAdditives.haram.length === 0) return snapshot
  const mergedHaram = [...new Set([...snapshot.haramAdditives, ...kwAdditives.haram])]
  const additiveNote = `Product additives indicate: ${mergedHaram.join(', ')}.`
  const explanation = snapshot.haramIngredients.length > 0 || snapshot.haramLabels.length > 0
    ? `${snapshot.explanation} ${additiveNote}`
    : `This product's additives indicate it contains: ${mergedHaram.join(', ')}.`
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    haramAdditives: mergedHaram,
    additiveWarnings: { ...snapshot.additiveWarnings, ...kwAdditives.warnings },
    explanation,
  }
}

function applyVeganFlavouringAdjustment(
  snapshot: VerdictSnapshot,
  { ctx, kwFirst }: PostRuleContext,
): VerdictSnapshot {
  if (snapshot.haramIngredients.length > 0 || snapshot.suspiciousIngredients.length === 0) {
    return snapshot
  }
  const adjusted = adjustFlavouringForVegan({
    suspicious: snapshot.suspiciousIngredients,
    warnings: snapshot.ingredientWarnings,
    canonicals: kwFirst.canonicals ?? {},
    labels: ctx.labels,
    productName: ctx.name,
  })
  return {
    ...snapshot,
    ingredientWarnings: { ...snapshot.ingredientWarnings, ...adjusted.warnings },
    explanation: adjusted.explanation,
  }
}

function applyAdditivesSuspiciousOverride(snapshot: VerdictSnapshot, { kwAdditives }: PostRuleContext): VerdictSnapshot {
  if (kwAdditives.suspicious.length === 0) return snapshot
  const suspiciousAdditives = [...new Set([...snapshot.suspiciousAdditives, ...kwAdditives.suspicious])]
  const mergedAdditiveWarnings = { ...snapshot.additiveWarnings, ...kwAdditives.warnings }
  if (!snapshot.isHalal) {
    const suspiciousNote = `Product additives may also be animal-derived: ${suspiciousAdditives.join(', ')}.`
    return {
      ...snapshot,
      suspiciousAdditives,
      additiveWarnings: mergedAdditiveWarnings,
      explanation: `${snapshot.explanation} ${suspiciousNote}`,
    }
  }
  const explanation =
    snapshot.suspiciousIngredients.length === 0 && snapshot.haramIngredients.length === 0
      ? `Product additives may be animal-derived: ${suspiciousAdditives.join(', ')}.`
      : snapshot.explanation
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    suspiciousAdditives,
    additiveWarnings: mergedAdditiveWarnings,
    explanation,
  }
}

function applySuspiciousNotHalal(snapshot: VerdictSnapshot, { ctx }: PostRuleContext): VerdictSnapshot {
  if (
    snapshot.isUnknown ||
    ctx.isHalalByCategory ||
    snapshot.haramIngredients.length > 0 ||
    snapshot.haramLabels.length > 0 ||
    snapshot.suspiciousIngredients.length === 0
  ) {
    return snapshot
  }
  return { ...snapshot, isHalal: false }
}

/** OFF category tag language prefix, e.g. "de:hähnchenfleisch" → "de". */
function categoryLanguage(category: string): string | null {
  const colon = category.indexOf(':')
  return colon > 0 ? category.slice(0, colon).toLowerCase() : null
}

function applyHalalCertRequirement(
  snapshot: VerdictSnapshot,
  ctx: VerdictContext,
): { snapshot: VerdictSnapshot; requiresHalalCert: boolean } {
  const matchedCategory = ctx.rawCategories.find(c => ANIMAL_PRODUCT_CATEGORIES.has(c.toLowerCase()))
  const matchedNameTerm = [...ANIMAL_PRODUCT_NAME_TERMS.keys()].find(term =>
    matchesAnimalTerm(ctx.name.toLowerCase(), term)
  )
  let matchedIngredient: string | undefined
  let matchedIngredientTerm: string | undefined
  for (const ingredient of ctx.ingredients) {
    const lower = ingredient.toLowerCase()
    matchedIngredientTerm = [...ANIMAL_INGREDIENT_TERMS.keys()].find(term => matchesAnimalTerm(lower, term))
    if (matchedIngredientTerm) {
      matchedIngredient = ingredient
      break
    }
  }
  const isAnimalProduct = !!matchedCategory || !!matchedNameTerm || !!matchedIngredientTerm
  const hasHalalCert = ctx.labels.some(l => HALAL_CERT_LABELS.has(l.toLowerCase()))
  const requiresHalalCert = isAnimalProduct && !hasHalalCert && !ctx.isNonFood &&
    !ctx.haramCategory && !ctx.isHalalByCategory &&
    snapshot.haramIngredients.length === 0 && snapshot.haramLabels.length === 0
  if (!requiresHalalCert) return { snapshot, requiresHalalCert: false }

  const matchLang = matchedCategory
    ? categoryLanguage(matchedCategory)
    : matchedNameTerm
    ? ANIMAL_PRODUCT_NAME_TERMS.get(matchedNameTerm) ?? null
    : matchedIngredientTerm
    ? ANIMAL_INGREDIENT_TERMS.get(matchedIngredientTerm) ?? null
    : null

  const reason = matchedCategory
    ? `category "${matchedCategory}"`
    : matchedNameTerm
    ? `product name (matched "${matchedNameTerm}", ${matchLang} term)`
    : `ingredient "${matchedIngredient}" (matched "${matchedIngredientTerm}", ${matchLang} term)`

  // Flag when the matched term's language doesn't match the language the ingredient
  // text was actually analyzed in — e.g. a German term matching inside Spanish text is
  // usually a substring collision, not a real translation (see barcode 20289119: "ente"
  // matched inside Spanish "preferentemente"). Category/name matches aren't checked —
  // OFF category tags and product names are frequently in a different language than the
  // ingredient list, so a mismatch there is expected, not suspicious.
  const analyzedTextLang = ctx.analyzeLang ?? ctx.displayLang ?? null
  const possibleMismatch = !!matchedIngredientTerm && !!matchLang && !!analyzedTextLang &&
    matchLang !== analyzedTextLang
  const mismatchNote = possibleMismatch
    ? ` This matched a ${matchLang} term while the ingredient text was analyzed as ${analyzedTextLang} — verify this isn't a false positive.`
    : ''

  return {
    requiresHalalCert: true,
    snapshot: {
      ...snapshot,
      isHalal: false,
      isUnknown: false,
      explanation:
        `This product appears to be an animal product (${reason}) with no halal certification on file. ` +
        `Halal slaughter cannot be confirmed.${mismatchNote}`,
      halalCertMatchTerm: matchedCategory ?? matchedNameTerm ?? matchedIngredientTerm,
      halalCertMatchLang: matchLang,
    },
  }
}

function toVerdictResult(state: VerdictState): VerdictResult {
  const { ctx, ingredients, snapshot, analyzedByAI, requiresHalalCert } = state
  const {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, haramLabels, suspiciousLabels, labelWarnings,
    haramAdditives, suspiciousAdditives, additiveWarnings,
    explanation, keywordMatchSource, keywordMatchOrigins, keywordMatchLanguages,
    halalCertMatchTerm, halalCertMatchLang, analyzeLang,
  } = snapshot
  console.log(
    `[${ctx.barcode}] verdict: isHalal=${isHalal} isUnknown=${isUnknown} analyzedByAI=${analyzedByAI} ` +
    `requiresHalalCert=${requiresHalalCert} haram=[${haramIngredients.join(', ')}] suspicious=[${suspiciousIngredients.join(', ')}] ` +
    `haramLabels=[${haramLabels.join(', ')}] suspiciousLabels=[${suspiciousLabels.join(', ')}] ` +
    `haramAdditives=[${haramAdditives.join(', ')}] suspiciousAdditives=[${suspiciousAdditives.join(', ')}] ` +
    `keywordMatchSource=${keywordMatchSource ?? 'n/a'} halalCertMatch=${halalCertMatchTerm ?? 'n/a'}(${halalCertMatchLang ?? 'n/a'})`,
  )
  return {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, haramLabels, suspiciousLabels, labelWarnings,
    haramAdditives, suspiciousAdditives, additiveWarnings,
    explanation, analyzedByAI, requiresHalalCert,
    ingredients,
    keywordMatchSource,
    keywordMatchOrigins,
    keywordMatchLanguages,
    halalCertMatchTerm,
    halalCertMatchLang,
    analyzeLang,
    displayLang: ctx.displayLang,
  }
}
