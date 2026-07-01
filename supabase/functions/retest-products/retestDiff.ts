import type { AnalysisRow, ProductRow } from '../lookup-product/persistence.ts'

/** Compact, comparable subset of a product's verdict — used for the diff UI and equality check. */
export interface RetestSnapshot {
  isHalal: boolean
  isUnknown: boolean
  haramIngredients: string[]
  suspiciousIngredients: string[]
  haramLabels: string[]
  suspiciousLabels: string[]
  haramAdditives: string[]
  suspiciousAdditives: string[]
  requiresHalalCert: boolean
  explanation: string
}

function asStringArray(value: unknown): string[] {
  return Array.isArray(value) ? (value as unknown[]).map(String) : []
}

/** Snapshot from a `products_full` row (current stored verdict). */
export function snapshotFromStoredRow(row: Record<string, unknown>): RetestSnapshot {
  return {
    isHalal: !!row.is_halal,
    isUnknown: !!row.is_unknown,
    haramIngredients: asStringArray(row.haram_ingredients),
    suspiciousIngredients: asStringArray(row.suspicious_ingredients),
    haramLabels: asStringArray(row.haram_labels),
    suspiciousLabels: asStringArray(row.suspicious_labels),
    haramAdditives: asStringArray(row.haram_additives),
    suspiciousAdditives: asStringArray(row.suspicious_additives),
    requiresHalalCert: !!row.requires_halal_cert,
    explanation: typeof row.explanation === 'string' ? row.explanation : '',
  }
}

/** Snapshot from a freshly computed (not yet persisted) verdict. */
export function snapshotFromComputed(productRow: ProductRow, analysisRow: AnalysisRow): RetestSnapshot {
  return {
    isHalal: analysisRow.isHalal,
    isUnknown: analysisRow.isUnknown,
    haramIngredients: analysisRow.haramIngredients,
    suspiciousIngredients: analysisRow.suspiciousIngredients,
    haramLabels: analysisRow.haramLabels,
    suspiciousLabels: analysisRow.suspiciousLabels,
    haramAdditives: analysisRow.haramAdditives,
    suspiciousAdditives: analysisRow.suspiciousAdditives,
    requiresHalalCert: productRow.requiresHalalCert,
    explanation: analysisRow.explanation,
  }
}

function sortedJson(values: string[]): string {
  return JSON.stringify([...values].sort())
}

/** True when two snapshots represent the same verdict (order-insensitive on lists). */
export function snapshotsEqual(a: RetestSnapshot, b: RetestSnapshot): boolean {
  return (
    a.isHalal === b.isHalal &&
    a.isUnknown === b.isUnknown &&
    a.requiresHalalCert === b.requiresHalalCert &&
    a.explanation === b.explanation &&
    sortedJson(a.haramIngredients) === sortedJson(b.haramIngredients) &&
    sortedJson(a.suspiciousIngredients) === sortedJson(b.suspiciousIngredients) &&
    sortedJson(a.haramLabels) === sortedJson(b.haramLabels) &&
    sortedJson(a.suspiciousLabels) === sortedJson(b.suspiciousLabels) &&
    sortedJson(a.haramAdditives) === sortedJson(b.haramAdditives) &&
    sortedJson(a.suspiciousAdditives) === sortedJson(b.suspiciousAdditives)
  )
}
