import { HARAM_CATEGORIES, HALAL_CATEGORIES, NON_FOOD_CATEGORIES } from './categories.ts'

export function normalizeStoredLabels(labelsRaw: unknown): string[] {
  if (!Array.isArray(labelsRaw)) return []
  return labelsRaw
    .map((x: unknown) => String(x).trim().toLowerCase())
    .filter((s) => s.length > 0)
}

export function classifyOffCategories(
  rawCategories: string[],
  isNonFood: boolean,
): { isNonFood: boolean; haramCategory: string | null; isHalalByCategory: boolean } {
  let nonFood = isNonFood
  if (!nonFood && rawCategories.some(c => NON_FOOD_CATEGORIES.has(c.toLowerCase()))) {
    nonFood = true
  }
  const haramCategory = nonFood
    ? null
    : (rawCategories.find(c => HARAM_CATEGORIES.has(c.toLowerCase())) ?? null)
  const isHalalByCategory = !nonFood && !haramCategory &&
    rawCategories.some(c => HALAL_CATEGORIES.has(c.toLowerCase()))
  return { isNonFood: nonFood, haramCategory, isHalalByCategory }
}
