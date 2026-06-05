import { VEGAN_ONLY_LABELS } from './categories.ts'

export const FLAVOURING_AROMA_CANONICALS = new Set(['flavouring', 'natural flavour'])

const VEGAN_FLAVOURING_WARNING =
  'Vegan-certified (non-animal); alcohol used in extraction cannot be ruled out.'

export function hasVeganLabelEvidence(labels: string[], name: string): boolean {
  const nameLower = name.toLowerCase()
  if (nameLower.includes('vegan')) return true
  return labels.some(l => {
    const lower = l.toLowerCase()
    return VEGAN_ONLY_LABELS.has(lower) ||
      (lower.includes('vegan') && !lower.includes('non-vegan'))
  })
}

export function buildSuspiciousExplanation(
  suspicious: string[],
  canonicals: Record<string, string>,
  labels: string[],
  productName: string,
): string {
  if (suspicious.length === 0) return ''

  const vegan = hasVeganLabelEvidence(labels, productName)
  const flavouring: string[] = []
  const other: string[] = []
  for (const ing of suspicious) {
    const canonical = canonicals[ing]
    if (canonical && FLAVOURING_AROMA_CANONICALS.has(canonical)) {
      flavouring.push(ing)
    } else {
      other.push(ing)
    }
  }

  if (vegan && flavouring.length > 0 && other.length === 0) {
    return `No definitively haram ingredients found. Product is vegan-certified; ` +
      `flagged aroma/flavouring is non-animal per certification, but alcohol ` +
      `content cannot be ruled out: ${flavouring.join(', ')}. ` +
      `Assessed by keyword matching.`
  }
  if (vegan && flavouring.length > 0 && other.length > 0) {
    return `No definitively haram ingredients found. Product is vegan-certified; ` +
      `flagged aroma/flavouring is non-animal per certification, but alcohol ` +
      `content cannot be ruled out: ${flavouring.join(', ')}. ` +
      `The following may still be animal-derived: ${other.join(', ')}. ` +
      `Assessed by keyword matching.`
  }
  if (flavouring.length > 0 && other.length === 0) {
    return `No definitively haram ingredients found, but the following may be ` +
      `animal-derived or extracted with alcohol: ${flavouring.join(', ')}. ` +
      `Assessed by keyword matching.`
  }
  if (flavouring.length > 0 && other.length > 0) {
    return `No definitively haram ingredients found. The following may be ` +
      `animal-derived or extracted with alcohol: ${flavouring.join(', ')}. ` +
      `The following may be animal-derived: ${other.join(', ')}. ` +
      `Assessed by keyword matching.`
  }
  return `No definitively haram ingredients found, but the following may be ` +
    `animal-derived: ${suspicious.join(', ')}. Assessed by keyword matching.`
}

export function adjustFlavouringForVegan(args: {
  suspicious: string[]
  warnings: Record<string, string>
  canonicals: Record<string, string>
  labels: string[]
  productName: string
}): { warnings: Record<string, string>; explanation: string } {
  const { suspicious, warnings, canonicals, labels, productName } = args
  const vegan = hasVeganLabelEvidence(labels, productName)
  const updatedWarnings = { ...warnings }
  if (vegan) {
    for (const ing of suspicious) {
      const canonical = canonicals[ing]
      if (canonical && FLAVOURING_AROMA_CANONICALS.has(canonical)) {
        updatedWarnings[ing] = VEGAN_FLAVOURING_WARNING
      }
    }
  }
  return {
    warnings: updatedWarnings,
    explanation: buildSuspiciousExplanation(suspicious, canonicals, labels, productName),
  }
}
