import { keywordAnalysis } from './keyword.ts'
import type { KeywordEntry } from './keyword.ts'
import {
  ANIMAL_PRODUCT_CATEGORIES, HALAL_CERT_LABELS, ANIMAL_PRODUCT_NAME_TERMS,
} from './categories.ts'
import { analyzeWithGemini, analyzeWithClaude, analyzeWithClaudeVision } from './ai.ts'

export interface VerdictContext {
  barcode: string
  ingredients: string[]
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
}

export interface VerdictResult {
  isHalal: boolean
  isUnknown: boolean
  haramIngredients: string[]
  suspiciousIngredients: string[]
  ingredientWarnings: Record<string, string>
  explanation: string
  analyzedByAI: boolean
  requiresHalalCert: boolean
  ingredients: string[]
}

export async function computeVerdict(ctx: VerdictContext): Promise<VerdictResult> {
  const {
    barcode, name, labels, rawCategories, isNonFood, ingredientSource,
    haramCategory, isHalalByCategory, customHaramEntries, customSuspiciousEntries,
    imageIngredientsUrl,
  } = ctx
  let ingredients = ctx.ingredients

  const kwFirst = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
  console.log(
    `[${barcode}] keywords: isHalal=${kwFirst.isHalal} isUnknown=${kwFirst.isUnknown} ` +
    `haram=[${kwFirst.haram.join(', ')}] suspicious=[${kwFirst.suspicious.join(', ')}]`,
  )

  let isHalal = isNonFood
    ? false
    : (isHalalByCategory && ingredients.length === 0 ? true : kwFirst.isHalal)
  let isUnknown = isNonFood
    ? false
    : (isHalalByCategory && ingredients.length === 0 ? false : kwFirst.isUnknown)
  let haramIngredients      = kwFirst.haram
  let suspiciousIngredients = kwFirst.suspicious
  let ingredientWarnings    = kwFirst.warnings
  let explanation = isNonFood
    ? 'This is a non-food product. Islamic dietary rules do not apply.'
    : (isHalalByCategory && ingredients.length === 0
        ? 'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.'
        : kwFirst.explanation)
  let analyzedByAI = false

  const geminiEnabled = Deno.env.get('GEMINI_ENABLED') !== 'false'
  const claudeEnabled = Deno.env.get('CLAUDE_ENABLED') !== 'false'

  const skipAI = isNonFood || isHalalByCategory || kwFirst.haram.length > 0 ||
    haramCategory !== null || ingredients.length === 0 || ingredientSource === 'ai'
  if (skipAI) {
    const skipReason = isNonFood              ? 'non-food'
      : isHalalByCategory                    ? 'halal-by-category'
      : haramCategory !== null               ? `haram-category(${haramCategory})`
      : kwFirst.haram.length > 0             ? `keyword-haram(${kwFirst.haram.join(', ')})`
      : ingredientSource === 'ai'            ? 'ai-sourced-ingredients'
      :                                        'no-ingredients'
    console.log(`[${barcode}] AI: skipped — ${skipReason}`)
  } else {
    // Tier 1: Gemini Flash — free 1,500 req/day; handles the vast majority of scans
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiEnabled) {
      console.log(`[${barcode}] Gemini: skipped — disabled by GEMINI_ENABLED=false`)
    } else if (!geminiKey) {
      console.log(`[${barcode}] Gemini: skipped — GEMINI_API_KEY not set`)
    } else {
      const aiVerdict = await analyzeWithGemini(ingredients, barcode, geminiKey)
      if (aiVerdict) {
        ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = aiVerdict)
        analyzedByAI = true
      }
    }

    // Tier 2: Claude Haiku — paid fallback when Gemini is unavailable or fails
    if (!analyzedByAI) {
      const claudeKey = Deno.env.get('CLAUDE_API_KEY')
      if (!claudeEnabled) {
        console.log(`[${barcode}] Claude: skipped — disabled by CLAUDE_ENABLED=false`)
      } else if (!claudeKey) {
        console.log(`[${barcode}] Claude: skipped — CLAUDE_API_KEY not set`)
      } else {
        const aiVerdict = await analyzeWithClaude(ingredients, barcode, claudeKey)
        if (aiVerdict) {
          ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = aiVerdict)
          analyzedByAI = true
        }
      }
    }
  }

  // Tier 3: Vision — when no text ingredients but an ingredient image exists.
  // Claude reads the label photo; rule engine + optional AI run on the extracted list.
  if (!analyzedByAI && ingredients.length === 0 && !isNonFood && !isHalalByCategory && haramCategory === null) {
    const claudeKey = Deno.env.get('CLAUDE_API_KEY')
    if (!claudeEnabled) {
      console.log(`[${barcode}] Claude vision: skipped — disabled by CLAUDE_ENABLED=false`)
    } else if (!imageIngredientsUrl) {
      console.log(`[${barcode}] Claude vision: skipped — no ingredients image`)
    } else if (!claudeKey) {
      console.log(`[${barcode}] Claude vision: skipped — CLAUDE_API_KEY not set`)
    } else {
      const visionIngredients = await analyzeWithClaudeVision(imageIngredientsUrl, barcode, claudeKey)
      if (visionIngredients && visionIngredients.length > 0) {
        ingredients = visionIngredients
        const kwVision = keywordAnalysis(ingredients, customHaramEntries, customSuspiciousEntries)
        isHalal             = kwVision.isHalal
        isUnknown           = kwVision.isUnknown
        haramIngredients    = kwVision.haram
        suspiciousIngredients = kwVision.suspicious
        ingredientWarnings  = kwVision.warnings
        explanation         = kwVision.explanation
        if (kwVision.haram.length === 0) {
          const geminiKey = Deno.env.get('GEMINI_API_KEY')
          if (geminiEnabled && geminiKey) {
            const aiVerdict = await analyzeWithGemini(ingredients, barcode, geminiKey)
            if (aiVerdict) {
              ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = aiVerdict)
              analyzedByAI = true
            }
          }
          if (!analyzedByAI && claudeEnabled && claudeKey) {
            const aiVerdict = await analyzeWithClaude(ingredients, barcode, claudeKey)
            if (aiVerdict) {
              ;({ isHalal, isUnknown, haramIngredients, suspiciousIngredients, ingredientWarnings, explanation } = aiVerdict)
              analyzedByAI = true
            }
          }
        }
      }
    }
  }

  // Keyword safety override: haram/suspicious always win over AI verdict.
  if (kwFirst.haram.length > 0 && isHalal) {
    isHalal            = false
    isUnknown          = false
    haramIngredients   = [...new Set([...haramIngredients, ...kwFirst.haram])]
    ingredientWarnings = { ...ingredientWarnings, ...kwFirst.warnings }
    explanation        = kwFirst.explanation
  }
  if (kwFirst.suspicious.length > 0 && isHalal) {
    isHalal               = false
    isUnknown             = false
    suspiciousIngredients = [...new Set([...suspiciousIngredients, ...kwFirst.suspicious])]
    ingredientWarnings    = { ...ingredientWarnings, ...kwFirst.warnings }
    if (kwFirst.haram.length === 0) explanation = kwFirst.explanation
  }

  // Category override: haram categories always win.
  if (haramCategory && isHalal) {
    isHalal     = false
    isUnknown   = false
    explanation = `This product belongs to a category that is not permissible: ${haramCategory}.`
  }

  // Name fallback: when no ingredients, check the product name for haram keywords.
  if (isUnknown) {
    const nameCheck = keywordAnalysis([name.toLowerCase()], customHaramEntries, customSuspiciousEntries)
    if (!nameCheck.isHalal) {
      isHalal            = false
      isUnknown          = false
      haramIngredients   = nameCheck.haram
      ingredientWarnings = nameCheck.warnings
      explanation        = `No ingredient list found, but the product name contains a haram indicator: ${nameCheck.haram.join(', ')}.`
    }
  }

  // Halal certification check for animal products without a verified cert.
  const categoryIsAnimalProduct = rawCategories.some(c => ANIMAL_PRODUCT_CATEGORIES.has(c.toLowerCase()))
  const nameIsAnimalProduct     = [...ANIMAL_PRODUCT_NAME_TERMS].some(term => name.toLowerCase().includes(term))
  const isAnimalProduct         = categoryIsAnimalProduct || nameIsAnimalProduct
  const hasHalalCert            = labels.some(l => HALAL_CERT_LABELS.has(l.toLowerCase()))
  const requiresHalalCert       = isAnimalProduct && !hasHalalCert && !isNonFood &&
    !haramCategory && !isHalalByCategory && haramIngredients.length === 0
  if (requiresHalalCert) {
    isHalal   = false
    isUnknown = false
  }

  // Suspicious ingredients alone make a product not halal.
  if (!isUnknown && !isHalalByCategory && haramIngredients.length === 0 && suspiciousIngredients.length > 0) {
    isHalal = false
  }

  console.log(
    `[${barcode}] verdict: isHalal=${isHalal} isUnknown=${isUnknown} analyzedByAI=${analyzedByAI} ` +
    `requiresHalalCert=${requiresHalalCert} haram=[${haramIngredients.join(', ')}] suspicious=[${suspiciousIngredients.join(', ')}]`,
  )

  return {
    isHalal, isUnknown, haramIngredients, suspiciousIngredients,
    ingredientWarnings, explanation, analyzedByAI, requiresHalalCert,
    ingredients,
  }
}
