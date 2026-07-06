<!-- User-facing release note bullets for the next version.
     Add one `- bullet` per item. Remove HTML comments before merging.
     Copy wording to de.md, tr.md, and ar.md when the change is user-visible. -->

- **Fewer false suspicious flags on named flavors** — hyphenated flavor names like Vanille-Aroma are no longer flagged as generic unspecified flavoring.

- **More additives flagged as suspicious** — added detection for 19 more E-numbers (emulsifiers like polysorbates, sorbitan esters, and polyglycerol esters, plus lanolin and L-cystine) across 7 languages.

- **Suspicious additives/labels no longer shown as flat "not halal"** — products flagged only through a suspicious additive or label (e.g. an emulsifier that may be animal-derived) now correctly show as suspicious instead of not halal.

- **More accurate certificate checks** — fixed a bug where a cross-language keyword mix-up could wrongly flag a product as needing halal certification; Analysis Transparency now shows which keyword and language triggered a flag.

- **Fixed certificate-required badge** — products confirmed as animal-derived now correctly show `Needs halal certificate` instead of `Suspicious` when an unrelated suspicious ingredient, label, or additive is also flagged.
