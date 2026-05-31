/**
 * Halal verdict pipeline (bootstrap → AI tiers → post-rules).
 * Documented step-by-step in VERDICT_PIPELINE.md — update that file when changing order or skip logic.
 */
import { keywordAnalysis, keywordAnalysisFromSources } from './keyword.ts'
import type { KeywordEntry, KeywordResult } from './keyword.ts'
import type { IngredientAnalysisSource } from './ingredientResolution.ts'
import {
  ANIMAL_PRODUCT_CATEGORIES, HALAL_CERT_LABELS, ANIMAL_PRODUCT_NAME_TERMS,
} from './categories.ts'
import {
  analyzeWithGemini, analyzeWithClaude, analyzeWithClaudeVision, type AiVerdict,
} from './ai.ts'

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
  explanation: string
  analyzedByAI: boolean
  requiresHalalCert: boolean
  ingredients: string[]
  keywordMatchSource?: string
  keywordMatchOrigins?: Record<string, string>
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
  explanation: string
  keywordMatchSource?: string
  keywordMatchOrigins?: Record<string, string>
  analyzeLang?: string | null
}

interface VerdictState {
  ctx: VerdictContext
  ingredients: string[]
  kwFirst: KeywordResult
  kwLabels: KeywordResult
  analyzedByAI: boolean
  requiresHalalCert: boolean
  snapshot: VerdictSnapshot
}

type AsyncVerdictStep = (state: VerdictState) => Promise<VerdictState>

interface AiEnv {
  geminiEnabled: boolean
  claudeEnabled: boolean
  geminiKey: string | undefined
  claudeKey: string | undefined
}

interface PostRuleContext {
  ctx: VerdictContext
  kwFirst: KeywordResult
  kwLabels: KeywordResult
}

type PostRule = (snapshot: VerdictSnapshot, ruleCtx: PostRuleContext) => VerdictSnapshot

const POST_ANALYSIS_RULES: PostRule[] = [
  applyKeywordHaramOverride,
  applyKeywordSuspiciousOverride,
  applyHaramCategoryOverride,
  applyNameFallback,
  applyLabelHaramOverride,
  applyLabelSuspiciousOverride,
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

function createInitialState(ctx: VerdictContext): VerdictState {
  const { ingredients, isNonFood, isHalalByCategory } = ctx
  const kwFirst = runInitialKeywordAnalysis(ctx)
  const kwLabelsRaw = keywordAnalysis(ctx.labels, ctx.customHaramEntries, ctx.customSuspiciousEntries)
  const kwLabels = {
    ...kwLabelsRaw,
    warnings: Object.fromEntries(
      Object.entries(kwLabelsRaw.warnings).map(([k, v]) => [k, `Found on label: ${v}`]),
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
  const halalByCategoryNoIngredients = isHalalByCategory && ingredients.length === 0
  return {
    ctx,
    ingredients,
    kwFirst,
    kwLabels,
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
      explanation: isNonFood
        ? 'This is a non-food product. Islamic dietary rules do not apply.'
        : (halalByCategoryNoIngredients
            ? 'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.'
            : kwFirst.explanation),
      keywordMatchSource: kwFirst.keywordMatchSource,
      keywordMatchOrigins: kwFirst.keywordMatchOrigins,
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
    geminiEnabled: Deno.env.get('GEMINI_ENABLED') !== 'false',
    claudeEnabled: Deno.env.get('CLAUDE_ENABLED') !== 'false',
    geminiKey: Deno.env.get('GEMINI_API_KEY'),
    claudeKey: Deno.env.get('CLAUDE_API_KEY'),
  }
}

function shouldSkipTextAi(state: VerdictState): boolean {
  const { ctx, kwFirst, kwLabels, ingredients } = state
  if (ctx.skipAi) return true
  return ctx.isNonFood || ctx.isHalalByCategory || kwFirst.haram.length > 0 ||
    kwLabels.haram.length > 0 || ctx.haramCategory !== null ||
    ingredients.length === 0 || ctx.ingredientSource === 'ai'
}

function skipTextAiReason(state: VerdictState): string {
  const { ctx, kwFirst, kwLabels } = state
  if (ctx.skipAi) return 'rules-only-reanalysis'
  if (ctx.isNonFood) return 'non-food'
  if (ctx.isHalalByCategory) return 'halal-by-category'
  if (ctx.haramCategory !== null) return `haram-category(${ctx.haramCategory})`
  if (kwFirst.haram.length > 0) return `keyword-haram(${kwFirst.haram.join(', ')})`
  if (kwLabels.haram.length > 0) return `label-haram(${kwLabels.haram.join(', ')})`
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
  )
  return { ...state, snapshot, requiresHalalCert }
}

/** Exported for unit tests — keyword safety, category, cert, and suspicious rules. */
export function applyPostAnalysisRules(
  snapshot: VerdictSnapshot,
  ctx: VerdictContext,
  kwFirst: KeywordResult,
  kwLabels: KeywordResult = { haram: [], suspicious: [], warnings: {}, isHalal: true, isUnknown: false, explanation: '', keywordMatchSource: undefined, keywordMatchOrigins: {}, analyzeLang: null },
): { snapshot: VerdictSnapshot; requiresHalalCert: boolean } {
  const ruleCtx: PostRuleContext = { ctx, kwFirst, kwLabels }
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
  const explanation = snapshot.haramIngredients.length > 0
    ? snapshot.explanation
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
  if (kwLabels.suspicious.length === 0 || !snapshot.isHalal) return snapshot
  return {
    ...snapshot,
    isHalal: false,
    isUnknown: false,
    suspiciousLabels: [...new Set([...snapshot.suspiciousLabels, ...kwLabels.suspicious])],
    labelWarnings: { ...snapshot.labelWarnings, ...kwLabels.warnings },
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

function applyHalalCertRequirement(
  snapshot: VerdictSnapshot,
  ctx: VerdictContext,
): { snapshot: VerdictSnapshot; requiresHalalCert: boolean } {
  const categoryIsAnimalProduct = ctx.rawCategories.some(c =>
    ANIMAL_PRODUCT_CATEGORIES.has(c.toLowerCase())
  )
  const nameIsAnimalProduct = [...ANIMAL_PRODUCT_NAME_TERMS].some(term =>
    ctx.name.toLowerCase().includes(term)
  )
  const isAnimalProduct = categoryIsAnimalProduct || nameIsAnimalProduct
  const hasHalalCert = ctx.labels.some(l => HALAL_CERT_LABELS.has(l.toLowerCase()))
  const requiresHalalCert = isAnimalProduct && !hasHalalCert && !ctx.isNonFood &&
    !ctx.haramCategory && !ctx.isHalalByCategory &&
    snapshot.haramIngredients.length === 0 && snapshot.haramLabels.length === 0
  if (!requiresHalalCert) return { snapshot, requiresHalalCert: false }
  return {
    requiresHalalCert: true,
    snapshot: { ...snapshot, isHalal: false, isUnknown: false },
  }
}

function toVerdictResult(state: VerdictState): VerdictResult {
  const { ctx, ingredients, snapshot, analyzedByAI, requiresHalalCert } = state
  const {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, haramLabels, suspiciousLabels, labelWarnings,
    explanation, keywordMatchSource, keywordMatchOrigins, analyzeLang,
  } = snapshot
  console.log(
    `[${ctx.barcode}] verdict: isHalal=${isHalal} isUnknown=${isUnknown} analyzedByAI=${analyzedByAI} ` +
    `requiresHalalCert=${requiresHalalCert} haram=[${haramIngredients.join(', ')}] suspicious=[${suspiciousIngredients.join(', ')}] ` +
    `haramLabels=[${haramLabels.join(', ')}] suspiciousLabels=[${suspiciousLabels.join(', ')}] ` +
    `keywordMatchSource=${keywordMatchSource ?? 'n/a'}`,
  )
  return {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, haramLabels, suspiciousLabels, labelWarnings,
    explanation, analyzedByAI, requiresHalalCert,
    ingredients,
    keywordMatchSource,
    keywordMatchOrigins,
    analyzeLang,
    displayLang: ctx.displayLang,
  }
}
