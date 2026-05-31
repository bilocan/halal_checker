export const OFF_BASE = 'https://world.openfoodfacts.org/api/v0/product'
export const OBF_BASE = 'https://world.openbeautyfacts.org/api/v0/product'
export const OPF_BASE = 'https://world.openproductsfacts.org/api/v0/product'

export function optImg(url?: string): string | null {
  if (!url) return null
  return url.replace('.100.', '.400.').replace('.200.', '.400.').replace('.300.', '.400.')
}

// deno-lint-ignore no-explicit-any
export function resolveImg(pd: any, directField: string, selectedKey: string): string | null {
  const direct = optImg(pd[directField])
  if (direct) return direct
  const sel = pd['selected_images']
  if (sel && typeof sel === 'object') {
    const section = sel[selectedKey]
    if (section?.display && typeof section.display === 'object') {
      const first = Object.values(section.display)[0]
      if (typeof first === 'string') return optImg(first)
    }
  }
  return null
}

// deno-lint-ignore no-explicit-any
export async function fetchFromFoodApi(barcode: string, baseUrl: string): Promise<any | null> {
  try {
    const res = await fetch(`${baseUrl}/${barcode}.json`)
    if (!res.ok) return null
    const data = await res.json()
    if (data.status === 0) return null
    return data.product
  } catch {
    return null
  }
}

// deno-lint-ignore no-explicit-any
export function extractIngredientsText(pd: any): string {
  let text: string = (pd['ingredients_text'] ?? '').trim()
  if (!text) {
    for (const lang of ['en', 'nl', 'de', 'fr', 'tr', 'es', 'it', 'sr', 'hu', 'cs']) {
      const t = (pd[`ingredients_text_${lang}`] ?? '').trim()
      if (t) { text = t; break }
    }
  }
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
  return text.toLowerCase()
}

// deno-lint-ignore no-explicit-any
export async function fetchOpenFactsProduct(
  barcode: string,
): Promise<{ pd: any; isNonFood: boolean } | null> {
  let pd = await fetchFromFoodApi(barcode, OFF_BASE)
  let isNonFood = false
  if (!pd) {
    pd = await fetchFromFoodApi(barcode, OBF_BASE)
    if (pd) isNonFood = true
  }
  if (!pd) {
    pd = await fetchFromFoodApi(barcode, OPF_BASE)
    if (pd) isNonFood = true
  }
  if (!pd) return null

  if (!isNonFood && !extractIngredientsText(pd)) {
    const obfPd = await fetchFromFoodApi(barcode, OBF_BASE)
    if (obfPd) {
      isNonFood = true
      pd = obfPd
    } else {
      const opfPd = await fetchFromFoodApi(barcode, OPF_BASE)
      if (opfPd) {
        isNonFood = true
        pd = opfPd
      }
    }
  }
  return { pd, isNonFood }
}

// deno-lint-ignore no-explicit-any
export function parseOffProductName(pd: any): string {
  return (pd.product_name?.trim() || pd.product_name_en?.trim() ||
    pd.abbreviated_product_name?.trim() || 'Unknown Product')
}

// deno-lint-ignore no-explicit-any
export function parseOffBrand(pd: any): string {
  return (pd.brands?.trim() || pd.brand_owner?.trim() || '')
    .split(',')[0]?.trim() ?? ''
}

// deno-lint-ignore no-explicit-any
export function parseOffIngredientList(pd: any): string[] {
  const text = extractIngredientsText(pd)
  return text
    .split(/[,;]/)
    .map((s: string) => s.trim())
    .filter((s: string) => s.length > 0)
}

// deno-lint-ignore no-explicit-any
export function parseOffTags(pd: any): {
  brand: string; quantity: string
  categoriesTags: string[]; additivesTags: string[]
  allergensTags: string[]; tracesTags: string[]
} {
  return {
    brand:          parseOffBrand(pd),
    quantity:       typeof pd.quantity === 'string' ? pd.quantity.trim() : '',
    categoriesTags: Array.isArray(pd.categories_tags) ? pd.categories_tags as string[] : [],
    additivesTags:  Array.isArray(pd.additives_tags)  ? pd.additives_tags  as string[] : [],
    allergensTags:  Array.isArray(pd.allergens_tags)  ? pd.allergens_tags  as string[] : [],
    tracesTags:     Array.isArray(pd.traces_tags)     ? pd.traces_tags     as string[] : [],
  }
}

// deno-lint-ignore no-explicit-any
export function parseOffLabels(pd: any): string[] {
  const labelSet = new Set<string>()
  const addLabels = (v: unknown) => {
    if (!v) return
    const parts = typeof v === 'string' ? v.split(/[,;]/) : (v as string[])
    parts.forEach((p: string) => {
      const n = p.trim().toLowerCase()
      if (n) labelSet.add(n)
    })
  }
  addLabels(pd.labels)
  addLabels(pd.labels_tags)
  addLabels(pd.labels_hierarchy)
  addLabels(pd.labels_en)
  return [...labelSet]
}
