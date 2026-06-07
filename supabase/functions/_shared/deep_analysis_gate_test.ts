import {
  assertEquals,
} from 'https://deno.land/std@0.224.0/assert/mod.ts'
import {
  isDeepAnalysisEnabledDbValue,
} from './deep_analysis_gate.ts'

Deno.test('isDeepAnalysisEnabledDbValue — true only for exact string', () => {
  assertEquals(isDeepAnalysisEnabledDbValue('true'), true)
  assertEquals(isDeepAnalysisEnabledDbValue('false'), false)
  assertEquals(isDeepAnalysisEnabledDbValue(null), false)
  assertEquals(isDeepAnalysisEnabledDbValue(undefined), false)
})
