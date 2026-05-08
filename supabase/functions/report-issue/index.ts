import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

const RESULT_LABELS: Record<string, string> = {
  halal: '✅ Halal',
  haram: '❌ Not Halal',
  non_food: 'ℹ️ Non-Food',
  unknown: '❓ Unknown',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const { barcode, productName, currentResult, expectedResult, note } =
      await req.json();

    if (!barcode || !currentResult || !expectedResult) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
      );
    }

    const githubToken = Deno.env.get('GITHUB_TOKEN');
    if (!githubToken) {
      return new Response(
        JSON.stringify({ error: 'GitHub token not configured' }),
        { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
      );
    }

    const currentLabel = RESULT_LABELS[currentResult] ?? currentResult;
    const expectedLabel = RESULT_LABELS[expectedResult] ?? expectedResult;
    const title = `[Bug Report] Barcode ${barcode} — expected ${expectedLabel}, got ${currentLabel}`;

    const body = [
      '## Wrong Result Report',
      '',
      `| Field | Value |`,
      `|---|---|`,
      `| **Barcode** | \`${barcode}\` |`,
      `| **Product** | ${productName ?? 'Unknown'} |`,
      `| **Current result** | ${currentLabel} |`,
      `| **Expected result** | ${expectedLabel} |`,
      note ? `| **Note** | ${note} |` : null,
      '',
      '---',
      '',
      '### For the developer (Claude)',
      '',
      '1. Add `' + barcode + '` to `test_data/seed_barcodes.txt` if not already present',
      '2. Write a failing test in `test/services/product_service_test.dart`:',
      '```dart',
      `// barcode ${barcode} should return ${expectedResult}`,
      '```',
      '3. Fix the pipeline so the test passes',
      '4. Commit test + fix together',
      '',
      '*Reported via HalalScan app*',
    ]
      .filter((l) => l !== null)
      .join('\n');

    const response = await fetch(
      'https://api.github.com/repos/bilocan/halal_checker/issues',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${githubToken}`,
          Accept: 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
          'User-Agent': 'HalalScan-App',
        },
        body: JSON.stringify({
          title,
          body,
          labels: ['bug', 'user-report'],
        }),
      },
    );

    if (!response.ok) {
      const err = await response.text();
      console.error('GitHub API error:', err);
      return new Response(
        JSON.stringify({ error: 'Failed to create GitHub issue' }),
        { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
      );
    }

    const issue = await response.json();
    return new Response(
      JSON.stringify({ issueUrl: issue.html_url, issueNumber: issue.number }),
      { status: 200, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('report-issue error:', e);
    return new Response(
      JSON.stringify({ error: 'Internal error' }),
      { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } },
    );
  }
});
