/**
 * Parse and validate the incoming request body.
 */
export interface LookupRequest {
  barcode: string;
  force?: boolean;
  fetchAiIngredients?: boolean;
}

/**
 * Parses the JSON body and validates required fields.
 * Throws an error if validation fails.
 */
export function parseRequest(body: unknown): LookupRequest {
  if (typeof body !== "object" || body === null) {
    throw new Error("Invalid JSON body");
  }
  const { barcode, force, fetchAiIngredients } = body as {
    barcode?: unknown;
    force?: unknown;
    fetchAiIngredients?: unknown;
  };

  if (typeof barcode !== "string" || !barcode) {
    throw new Error("barcode is required and must be a non-empty string");
  }
  //
  return {
    barcode,
    force: !!force,
    fetchAiIngredients: !!fetchAiIngredients,
  };
}
