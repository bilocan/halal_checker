// Run with: deno test supabase/functions/lookup-product/ai_test.ts

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseIngredientList } from "./ai.ts";

Deno.test("parseIngredientList: comma-separated", () => {
  assertEquals(
    parseIngredientList("water, sugar, salt"),
    ["water", "sugar", "salt"],
  );
});

Deno.test("parseIngredientList: strips label prefix and markdown", () => {
  assertEquals(
    parseIngredientList("**Ingredients:** water, **gelatin**"),
    ["water", "gelatin"],
  );
});

Deno.test("parseIngredientList: UNKNOWN returns empty", () => {
  assertEquals(parseIngredientList("UNKNOWN"), []);
  assertEquals(parseIngredientList("  unknown  "), []);
});

Deno.test("parseIngredientList: newline bullets", () => {
  assertEquals(
    parseIngredientList("Ingredients:\n- water\n- salt"),
    ["water", "salt"],
  );
});
