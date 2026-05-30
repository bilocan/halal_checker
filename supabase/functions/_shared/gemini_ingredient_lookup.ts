/**
 * Shared Gemini web ingredient lookup (Google Search grounding).
 * Used by lookup-product (Flutter app) and admin-gemini-ingredient-lookup (web admin).
 * Do not duplicate prompts or request shape elsewhere — extend this module and snapshot tests.
 */

export const GEMINI_URL_BASE =
  "https://generativelanguage.googleapis.com/v1beta/models";

/** Ingredient lookup — grounded web search; needs a search-capable model. */
export const GEMINI_LOOKUP_MODEL = "gemini-2.5-flash";

export const GEMINI_LOOKUP_MAX_OUTPUT_TOKENS = 2048;

export const GEMINI_LOOKUP_TEMPERATURE = 0.1;

export const GEMINI_LOOKUP_TOP_P = 0.95;

export const INGREDIENT_LOOKUP_SYSTEM = `You have a strict operational mode:
  INGREDIENT LOOKUP (STRICT DATABASE)
  Whenever the user provides a food product name, barcode, or an explicit request for product ingredients:
  1. Use your search tool to find the product. Return ingredients in their original language exactly as found — do not translate.
  2. Respond with ONLY the final comma-separated list of its ingredients.
  3. If the search tool yields absolutely no matching product data or no ingredients can be identified, respond with exactly one word: UNKNOWN.
  4. NEVER write explanations, apologies, introductions, markdown formatting, or any other text.
  `;

const REFUSAL_PREFIXES = [
  "unfortunately",
  "i cannot",
  "i can't",
  "i don't",
  "i do not",
  "sorry",
  "i'm unable",
  "i am unable",
  "i'm not able",
  "i am not able",
];

export function isRefusal(text: string): boolean {
  const lower = text.toLowerCase().trimStart();
  return REFUSAL_PREFIXES.some((p) => lower.startsWith(p));
}

export function buildIngredientLookupPrompt(
  name: string,
  barcode: string,
  brand: string,
): string {
  const brandPart = brand ? `, brand "${brand}"` : "";
  return `Find the complete ingredients list for "${name}"${brandPart}, ` +
    `EAN/GTIN barcode ${barcode}. Search Open Food Facts, manufacturer sites, and ` +
    `EU retailer product pages (Zutaten / ingredients).`;
}

/** Request body for Gemini generateContent (ingredient web lookup). Used by tests and callers. */
export interface GeminiIngredientLookupRequest {
  contents: Array<{ parts: Array<{ text: string }> }>;
  systemInstruction: { parts: Array<{ text: string }> };
  tools: Array<{ google_search: Record<string, never> }>;
  generationConfig: {
    maxOutputTokens: number;
    temperature: number;
    topP: number;
    thinkingConfig: { thinkingBudget: number };
  };
}

/** Builds the exact JSON body sent to Gemini (no network). */
export function buildGeminiIngredientLookupRequest(
  name: string,
  barcode: string,
  brand = "",
): GeminiIngredientLookupRequest {
  return {
    contents: [{
      parts: [{ text: buildIngredientLookupPrompt(name, barcode, brand) }],
    }],
    systemInstruction: { parts: [{ text: INGREDIENT_LOOKUP_SYSTEM }] },
    tools: [{ google_search: {} }],
    generationConfig: {
      maxOutputTokens: GEMINI_LOOKUP_MAX_OUTPUT_TOKENS,
      temperature: GEMINI_LOOKUP_TEMPERATURE,
      topP: GEMINI_LOOKUP_TOP_P,
      thinkingConfig: { thinkingBudget: 0 },
    },
  };
}

export function geminiIngredientLookupUrl(apiKey: string): string {
  return `${GEMINI_URL_BASE}/${GEMINI_LOOKUP_MODEL}:generateContent?key=${apiKey}`;
}

/** Parse model output into ingredient strings (comma/semicolon/newline lists). */
export function parseIngredientList(raw: string): string[] {
  let text = raw.trim().replace(/^```\w*\n?|```$/g, "").replace(/\*\*/g, "");
  if (!text || text.toUpperCase() === "UNKNOWN") return [];

  text = text.replace(
    /^(ingredients?|zutaten|inhaltsstoffe|contains)\s*:\s*/i,
    "",
  ).trim();

  const splitDelimited = (s: string): string[] => {
    const parts: string[] = [];
    let depth = 0;
    let current = "";
    for (const ch of s) {
      if (ch === "(") {
        depth++;
        current += ch;
      } else if (ch === ")") {
        depth--;
        current += ch;
      } else if ((ch === "," || ch === ";") && depth === 0) {
        const t = current.trim();
        if (t) parts.push(t);
        current = "";
      } else current += ch;
    }
    const t = current.trim();
    if (t) parts.push(t);
    return parts;
  };

  let parts = splitDelimited(text);
  if (parts.length <= 1 && /[\n\r]/.test(text)) {
    parts = text.split(/[\n\r]+/)
      .map((line) => line.replace(/^[-•*]\s*/, "").trim())
      .filter((line) =>
        line.length > 0 && !/^(ingredients?|zutaten)$/i.test(line)
      );
  }
  return parts;
}

export interface GeminiIngredientLookupGrounding {
  webSearchQueries: string[];
  groundingChunkCount: number;
}

export interface GeminiIngredientLookupResult {
  ingredients: string[];
  rawText: string;
  finishReason: string | null;
  grounding: GeminiIngredientLookupGrounding | null;
}

// deno-lint-ignore no-explicit-any
function parseGeminiResponse(ld: any): GeminiIngredientLookupResult {
  const candidate = ld.candidates?.[0];
  const text: string = (candidate?.content?.parts?.[0]?.text ?? "").trim();
  const grounding = candidate?.groundingMetadata;
  let groundingInfo: GeminiIngredientLookupGrounding | null = null;
  if (grounding) {
    groundingInfo = {
      webSearchQueries: grounding.webSearchQueries ?? [],
      groundingChunkCount: (grounding.groundingChunks ?? []).length,
    };
  }
  const ingredients = text && !isRefusal(text) ? parseIngredientList(text) : [];
  return {
    ingredients,
    rawText: text,
    finishReason: candidate?.finishReason ?? null,
    grounding: groundingInfo,
  };
}

function logLookupResult(
  barcode: string,
  name: string,
  brand: string,
  // deno-lint-ignore no-explicit-any
  ld: any,
  result: GeminiIngredientLookupResult,
): void {
  const usage = ld.usageMetadata;
  if (result.grounding) {
    console.log(
      `[${barcode}] Gemini ingredient lookup: grounding ` +
        `queries=${JSON.stringify(result.grounding.webSearchQueries)} ` +
        `chunks=${result.grounding.groundingChunkCount}`,
    );
  } else {
    console.log(
      `[${barcode}] Gemini ingredient lookup: no groundingMetadata (search may not have run)`,
    );
  }
  if (result.finishReason) {
    console.log(
      `[${barcode}] Gemini ingredient lookup: finishReason=${result.finishReason}`,
    );
  }
  console.log(
    `[${barcode}] Gemini ingredient lookup (${GEMINI_LOOKUP_MODEL}): ` +
      `"${name}"${brand ? ` brand="${brand}"` : ""} ` +
      `response="${result.rawText.slice(0, 120)}" ` +
      `prompt=${usage?.promptTokenCount ?? "?"} output=${
        usage?.candidatesTokenCount ?? "?"
      } thoughts=${usage?.thoughtsTokenCount ?? 0} total=${
        usage?.totalTokenCount ?? "?"
      } tokens`,
  );
  if (result.ingredients.length > 0) {
    console.log(
      `[${barcode}] Gemini ingredient lookup: found ${result.ingredients.length} ingredients`,
    );
  } else {
    console.log(
      `[${barcode}] Gemini ingredient lookup: no ingredients found (refusal, UNKNOWN, or unparseable)`,
    );
  }
}

/** Full lookup with parsed ingredients and debug fields (web admin probe). */
export async function geminiIngredientLookupDetailed(
  name: string,
  barcode: string,
  key: string,
  brand = "",
): Promise<GeminiIngredientLookupResult> {
  const empty: GeminiIngredientLookupResult = {
    ingredients: [],
    rawText: "",
    finishReason: null,
    grounding: null,
  };
  try {
    const res = await fetch(geminiIngredientLookupUrl(key), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(buildGeminiIngredientLookupRequest(name, barcode, brand)),
    });
    if (!res.ok) {
      const errBody = await res.text();
      console.error(
        `[${barcode}] Gemini ingredient lookup: HTTP ${res.status} — ${errBody}`,
      );
      return { ...empty, rawText: errBody.slice(0, 500) };
    }
    const ld = await res.json();
    const result = parseGeminiResponse(ld);
    logLookupResult(barcode, name, brand, ld, result);
    return result;
  } catch (e) {
    console.error(`[${barcode}] Gemini ingredient lookup: exception:`, e);
    return empty;
  }
}

/** Production lookup — ingredient list only (lookup-product / Flutter path). */
export async function geminiIngredientLookup(
  name: string,
  barcode: string,
  key: string,
  brand = "",
): Promise<string[]> {
  const result = await geminiIngredientLookupDetailed(name, barcode, key, brand);
  return result.ingredients;
}
