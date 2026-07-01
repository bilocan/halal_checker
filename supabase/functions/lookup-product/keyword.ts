export type KeywordEntry = [string, string, ...string[]]

export const HARAM_ENTRIES: KeywordEntry[] = [
  ['alcohol',    'Contains alcohol or alcohol-derived ingredient',
   'alcohol', 'alkohol', 'alcool', 'alcol', 'alkol', 'álcool'],
  ['ethanol',    'Contains alcohol or alcohol-derived ingredient',
   'ethanol', 'äthanol', 'éthanol', 'etanolo', 'etanol', 'e1510', 'e-1510'],
  ['wine',       'Contains alcohol or alcohol-derived ingredient',
   'wine', 'wein', 'vin', 'vino', 'şarap', 'wijn', 'vinho'],
  ['beer',       'Contains alcohol or alcohol-derived ingredient',
   'beer', 'bier', 'bière', 'birra', 'cerveza', 'bira', 'cerveja',
   'budweiser', 'heineken', 'corona', 'stella artois', 'carlsberg'],
  ['cognac',    'Contains cognac (alcoholic spirit)',   'cognac', 'kognak'],
  ['brandy',    'Contains brandy (alcoholic spirit)',   'brandy', 'branntwein', 'brandewijn'],
  ['whisky',    'Contains whisky (alcoholic spirit)',   'whisky', 'whiskey', 'whiskie', 'viski'],
  ['vodka',     'Contains vodka (alcoholic spirit)',    'vodka', 'wodka'],
  ['rum',       'Contains rum (alcoholic spirit)',      'rum', 'rhum', 'ron'],
  ['gin',       'Contains gin (alcoholic spirit)',      'gin'],
  ['liqueur',   'Contains liqueur (alcoholic)',         'liqueur', 'likör', 'licor', 'likeur', 'liquore'],
  ['schnapps',  'Contains schnapps (alcoholic spirit)', 'schnapps', 'schnaps'],
  ['champagne', 'Contains champagne (alcoholic)',       'champagne', 'sekt', 'cava', 'spumante'],
  ['prosecco',  'Contains prosecco (alcoholic)',        'prosecco'],
  ['bourbon',   'Contains bourbon (alcoholic spirit)',  'bourbon'],
  ['sake',      'Contains sake (alcoholic)',            'sake', 'saké'],
  ['pork',       'Contains pork or pork-derived ingredient',
   'pork', 'schwein', 'schweinefleisch', 'porc', 'maiale', 'cerdo',
   'domuz', 'varkens', 'varkensvlees', 'porco',
   'свинско', 'свински', 'свинска', 'свинско месо', 'свинска месо'],
  ['lard',       'Contains pork fat',
   'lard', 'schmalz', 'schweineschmalz', 'saindoux', 'strutto',
   'manteca de cerdo', 'domuz yağı', 'banha'],
  ['bacon',      'Contains pork product',
   'bacon', 'speck', 'lardons', 'pancetta', 'domuz pastırması'],
  ['ham',        'Contains pork product',
   'ham', 'schinken', 'jambon', 'prosciutto', 'jamón', 'presunto'],
  ['pepperoni',  'Contains pork product',   'pepperoni'],
  ['salami',     'Contains pork product',   'salami', 'salame'],
  ['chorizo',    'Contains pork product',   'chorizo'],
  ['prosciutto', 'Contains pork product',   'prosciutto'],
  ['carmine',    'Carmine/cochineal is insect-derived',
   'carmine', 'karmin', 'carmín', 'karmín', 'carmin'],
  ['cochineal',  'Carmine/cochineal is insect-derived',
   'cochineal', 'cochenille', 'cocciniglia', 'cochinilla', 'koşnil'],
  ['e120', 'Carmine/cochineal color, animal-derived', 'e120', 'e-120'],
  ['e542', 'Bone phosphate, animal-derived','e542', 'e-542'],
  ['e904', 'Shellac, animal-derived',       'e904', 'e-904'],
]

export const SUSPICIOUS_ENTRIES: KeywordEntry[] = [
  ['gelatin', 'Gelatin source often unspecified — predominantly pork-derived in Western products',
   'gelatin', 'gelatine', 'gelatina', 'jelatin', 'gélatine', 'želatina', 'zselatin'],
  ['e441', 'Gelatin (E441), source often unspecified — predominantly pork-derived',
   'e441', 'e-441'],
  ['e920', 'L-cysteine may be animal-derived',          'e920', 'e-920'],
  ['e322', 'Lecithin may be animal-derived',            'e322', 'e-322'],
  ['e471', 'Mono- and diglycerides may be animal-derived','e471','e-471'],
  ['e472', 'Emulsifiers may be animal-derived',         'e472', 'e-472'],
  ['e473', 'Sucrose esters may be animal-derived',      'e473', 'e-473'],
  ['e927', 'Glycine may be animal-derived',             'e927', 'e-927'],
  ['e422', 'Glycerol may be animal-derived',           'e422', 'e-422'],
  ['e481', 'Sodium stearoyl lactylate may be animal-derived', 'e481', 'e-481'],
  ['e482', 'Calcium stearoyl lactylate may be animal-derived', 'e482', 'e-482'],
  ['e570', 'Fatty acids (E570) may be animal-derived', 'e570', 'e-570'],
  ['e572', 'Magnesium stearate may be animal-derived', 'e572', 'e-572'],
  ['e631', 'Disodium inosinate (E631) may be derived from fish or meat', 'e631', 'e-631'],
  ['e635', 'Disodium ribonucleotides (E635) may be derived from fish or meat', 'e635', 'e-635'],
  ['e474', 'Sucroglycerides (E474) may be animal-derived', 'e474', 'e-474',
   'sucroglycerides', 'zuckerglyceride', 'şeker gliseridleri',
   'sucroglycérides', 'sucrogliceridi', 'sucroglicéridos', 'sucroglyceriden'],
  ['e475', 'Polyglycerol esters of fatty acids (E475) may be animal-derived', 'e475', 'e-475',
   'polyglycerol esters of fatty acids', 'polyglycerinester von speisefettsäuren',
   'yağ asitlerinin poligliserol esterleri', 'esters polyglycériques d\'acides gras',
   'esteri poliglicerici degli acidi grassi', 'ésteres poliglicéridos de ácidos grasos',
   'polyglycerolesters van vetzuren'],
  ['e476', 'Polyglycerol polyricinoleate (E476) may be animal-derived', 'e476', 'e-476',
   'polyglycerol polyricinoleate', 'polyglycerinpolyricinoleat', 'poligliserol poliricinoleat',
   'polyricinoléate de polyglycérol', 'poliricinoleato di poliglicerolo',
   'poliricinoleato de poliglicerol', 'polyglycerolpolyricinoleaat'],
  ['e477', 'Propylene glycol esters of fatty acids (E477) may be animal-derived', 'e477', 'e-477',
   'propylene glycol esters of fatty acids', 'propylenglycolester von speisefettsäuren',
   'yağ asitlerinin propilen glikol esterleri', 'esters de propylène glycol d\'acides gras',
   'esteri del glicole propilenico degli acidi grassi',
   'ésteres de propano-1,2-diol de ácidos grasos', 'propaan-1,2-diolesters van vetzuren'],
  ['e478', 'Lactylated fatty acid esters (E478) may be animal-derived', 'e478', 'e-478'],
  ['e483', 'Stearyl tartrate (E483) may be animal-derived', 'e483', 'e-483',
   'stearyl tartrate', 'stearyltartrat', 'stearil tartarat', 'tartrate de stéaryle',
   'tartrato di stearile', 'tartrato de estearilo', 'stearyltartraat'],
  ['e430', 'Polyoxyethylene stearate (E430) may be animal-derived', 'e430', 'e-430',
   'polyoxyethylene stearate', 'polyoxyethylenstearat', 'polioksietilen stearat',
   'stéarate de polyoxyéthylène', 'stearato di poliossietilene',
   'estearato de polioxietileno', 'polyoxyethyleenstearaat'],
  ['e431', 'Polyoxyethylene stearate (E431) may be animal-derived', 'e431', 'e-431',
   'polyoxyethylene stearate', 'polyoxyethylenstearat', 'polioksietilen stearat',
   'stéarate de polyoxyéthylène', 'stearato di poliossietilene',
   'estearato de polioxietileno', 'polyoxyethyleenstearaat'],
  ['e432', 'Polysorbate 20 (E432) may be animal-derived', 'e432', 'e-432',
   'polysorbate 20', 'polysorbat 20', 'polisorbat 20', 'polisorbato 20', 'polysorbaat 20'],
  ['e433', 'Polysorbate 80 (E433) may be animal-derived', 'e433', 'e-433',
   'polysorbate 80', 'polysorbat 80', 'polisorbat 80', 'polisorbato 80', 'polysorbaat 80'],
  ['e434', 'Polysorbate 40 (E434) may be animal-derived', 'e434', 'e-434',
   'polysorbate 40', 'polysorbat 40', 'polisorbat 40', 'polisorbato 40', 'polysorbaat 40'],
  ['e435', 'Polysorbate 60 (E435) may be animal-derived', 'e435', 'e-435',
   'polysorbate 60', 'polysorbat 60', 'polisorbat 60', 'polisorbato 60', 'polysorbaat 60'],
  ['e436', 'Polysorbate 65 (E436) may be animal-derived', 'e436', 'e-436',
   'polysorbate 65', 'polysorbat 65', 'polisorbat 65', 'polisorbato 65', 'polysorbaat 65'],
  ['e491', 'Sorbitan monostearate (E491) may be animal-derived', 'e491', 'e-491',
   'sorbitan monostearate', 'sorbitanmonostearat', 'sorbitan monostearat',
   'monostéarate de sorbitane', 'sorbitan monostearato', 'monoestearato de sorbitán',
   'sorbitaanmonostearaat'],
  ['e492', 'Sorbitan tristearate (E492) may be animal-derived', 'e492', 'e-492',
   'sorbitan tristearate', 'sorbitantristearat', 'sorbitan tristearat',
   'tristéarate de sorbitane', 'sorbitan tristearato', 'triestearato de sorbitán',
   'sorbitaantristearaat'],
  ['e493', 'Sorbitan monolaurate (E493) may be animal-derived', 'e493', 'e-493',
   'sorbitan monolaurate', 'sorbitanmonolaurat', 'sorbitan monolaurat',
   'monolaurate de sorbitane', 'sorbitan monolaurato', 'monolaurato de sorbitán',
   'sorbitaanmonolauraat'],
  ['e494', 'Sorbitan monooleate (E494) may be animal-derived', 'e494', 'e-494',
   'sorbitan monooleate', 'sorbitanmonooleat', 'sorbitan monooleat',
   'monooléate de sorbitane', 'sorbitan monooleato', 'monooleato de sorbitán',
   'sorbitaanmono-oleaat'],
  ['e495', 'Sorbitan monopalmitate (E495) may be animal-derived', 'e495', 'e-495',
   'sorbitan monopalmitate', 'sorbitanmonopalmitat', 'sorbitan monopalmitat',
   'monopalmitate de sorbitane', 'sorbitan monopalmitato', 'monopalmitato de sorbitán',
   'sorbitaanmonopalmitaat'],
  ['e921', 'L-cystine (E921) may be animal-derived, related to L-cysteine', 'e921', 'e-921',
   'l-cystine', 'l-cystin', 'l-sistin', 'l-cistina'],
  ['e913', 'Lanolin (E913) is derived from sheep wool grease', 'e913', 'e-913',
   'lanolin', 'wollwachs', 'lanoline', 'lanolina'],
  ['rennet', 'Rennet may be animal-derived',
   'rennet', 'lab', 'labferment', 'présure', 'caglio', 'cuajo',
   'peynir mayası', 'stremsel'],
  ['whey', 'Whey is a dairy ingredient — source verification recommended.',
   'whey', 'molke', 'lactosérum', 'siero di latte',
   'suero de leche', 'peynir suyu', 'wei'],
  ['l-cysteine', 'L-cysteine may be animal-derived',
   'l-cysteine', 'l-cystein', 'l-cystéine', 'l-cisteina', 'l-sistein'],
  ['natural flavour', 'Natural flavour may include animal-derived extracts or be extracted with alcohol.',
   'natural flavour', 'natural flavor', 'natürliches aroma',
   'natürliche aromen', 'arôme naturel', 'aroma naturale',
   'aroma natural', 'doğal aroma', 'natuurlijk aroma'],
  ['flavouring', 'Aroma / flavouring — source may be animal-derived or extracted with alcohol.',
   'flavouring', 'flavoring', 'aroma', 'arôme', 'smaakstof'],
  ['enzymes', 'Enzymes may be extracted from animal sources',
   'enzymes', 'enzyme', 'enzimi', 'enzimas', 'enzim', 'enzymen'],
  ['glycerol', 'Glycerol may be animal-derived',
   'glycerol', 'glycerin', 'glycérol', 'glicerina', 'gliserin', 'glycerine'],
  ['manteca', 'Fat source unspecified — likely animal fat if not labelled "vegetal" or "de cacao"',
   'manteca', 'manteca animal'],
]

/** E-number codes (e.g. "e441", "e-441") are language-neutral — never tagged. */
const E_NUMBER_VARIANT = /^e-?\d+$/i

/**
 * Source language of each HARAM_ENTRIES / SUSPICIOUS_ENTRIES variant string, keyed by the
 * exact (lowercase) variant text. Used only for match-transparency display (e.g. "matched
 * via German term 'ente'") — never for matching logic. E-number variants are omitted; look
 * them up via `E_NUMBER_VARIANT` instead of this map (they carry no language).
 */
const VARIANT_LANGUAGE: Record<string, string> = {
  // — alcohol —
  alcohol: 'en', alkohol: 'de', alcool: 'fr', alcol: 'it', alkol: 'tr', álcool: 'pt',
  ethanol: 'en', äthanol: 'de', éthanol: 'fr', etanolo: 'it', etanol: 'es',
  wine: 'en', wein: 'de', vin: 'fr', vino: 'it', şarap: 'tr', wijn: 'nl', vinho: 'pt',
  beer: 'en', bier: 'de', bière: 'fr', birra: 'it', cerveza: 'es', bira: 'tr', cerveja: 'pt',
  budweiser: 'en', heineken: 'en', corona: 'en', 'stella artois': 'en', carlsberg: 'en',
  cognac: 'fr', kognak: 'de',
  brandy: 'en', branntwein: 'de', brandewijn: 'nl',
  whisky: 'en', whiskey: 'en', whiskie: 'en', viski: 'tr',
  vodka: 'en', wodka: 'de',
  rum: 'en', rhum: 'fr', ron: 'es',
  gin: 'en',
  liqueur: 'fr', likör: 'de', licor: 'es', likeur: 'nl', liquore: 'it',
  schnapps: 'en', schnaps: 'de',
  champagne: 'fr', sekt: 'de', cava: 'es', spumante: 'it',
  prosecco: 'it',
  bourbon: 'en',
  sake: 'en', saké: 'fr',
  // — pork family —
  pork: 'en', schwein: 'de', schweinefleisch: 'de', porc: 'fr', maiale: 'it', cerdo: 'es',
  domuz: 'tr', varkens: 'nl', varkensvlees: 'nl', porco: 'pt',
  свинско: 'bg', свински: 'bg', свинска: 'bg', 'свинско месо': 'bg', 'свинска месо': 'bg',
  lard: 'en', schmalz: 'de', schweineschmalz: 'de', saindoux: 'fr', strutto: 'it',
  'manteca de cerdo': 'es', 'domuz yağı': 'tr', banha: 'pt',
  bacon: 'en', speck: 'de', lardons: 'fr', pancetta: 'it', 'domuz pastırması': 'tr',
  ham: 'en', schinken: 'de', jambon: 'fr', prosciutto: 'it', jamón: 'es', presunto: 'pt',
  pepperoni: 'it', salami: 'it', salame: 'it', chorizo: 'es',
  // — carmine / cochineal —
  carmine: 'en', karmin: 'de', carmín: 'es', karmín: 'cs', carmin: 'fr',
  cochineal: 'en', cochenille: 'fr', cocciniglia: 'it', cochinilla: 'es', koşnil: 'tr',
  // — gelatin —
  gelatin: 'en', gelatine: 'de', gelatina: 'it', jelatin: 'tr', gélatine: 'fr',
  želatina: 'sr', zselatin: 'hu',
  // — E-number word variants (E474–E495) —
  sucroglycerides: 'en', zuckerglyceride: 'de', 'şeker gliseridleri': 'tr',
  sucroglycérides: 'fr', sucrogliceridi: 'it', sucroglicéridos: 'es', sucroglyceriden: 'nl',
  'polyglycerol esters of fatty acids': 'en', 'polyglycerinester von speisefettsäuren': 'de',
  'yağ asitlerinin poligliserol esterleri': 'tr', "esters polyglycériques d'acides gras": 'fr',
  'esteri poliglicerici degli acidi grassi': 'it', 'ésteres poliglicéridos de ácidos grasos': 'es',
  'polyglycerolesters van vetzuren': 'nl',
  'polyglycerol polyricinoleate': 'en', polyglycerinpolyricinoleat: 'de',
  'poligliserol poliricinoleat': 'tr', 'polyricinoléate de polyglycérol': 'fr',
  'poliricinoleato di poliglicerolo': 'it', 'poliricinoleato de poliglicerol': 'es',
  polyglycerolpolyricinoleaat: 'nl',
  'propylene glycol esters of fatty acids': 'en', 'propylenglycolester von speisefettsäuren': 'de',
  'yağ asitlerinin propilen glikol esterleri': 'tr', "esters de propylène glycol d'acides gras": 'fr',
  'esteri del glicole propilenico degli acidi grassi': 'it',
  'ésteres de propano-1,2-diol de ácidos grasos': 'es', 'propaan-1,2-diolesters van vetzuren': 'nl',
  'stearyl tartrate': 'en', stearyltartrat: 'de', 'stearil tartarat': 'tr',
  'tartrate de stéaryle': 'fr', 'tartrato di stearile': 'it', 'tartrato de estearilo': 'es',
  stearyltartraat: 'nl',
  'polyoxyethylene stearate': 'en', polyoxyethylenstearat: 'de', 'polioksietilen stearat': 'tr',
  'stéarate de polyoxyéthylène': 'fr', 'stearato di poliossietilene': 'it',
  'estearato de polioxietileno': 'es', polyoxyethyleenstearaat: 'nl',
  'polysorbate 20': 'en', 'polysorbat 20': 'de', 'polisorbat 20': 'tr', 'polisorbato 20': 'it',
  'polysorbaat 20': 'nl',
  'polysorbate 80': 'en', 'polysorbat 80': 'de', 'polisorbat 80': 'tr', 'polisorbato 80': 'it',
  'polysorbaat 80': 'nl',
  'polysorbate 40': 'en', 'polysorbat 40': 'de', 'polisorbat 40': 'tr', 'polisorbato 40': 'it',
  'polysorbaat 40': 'nl',
  'polysorbate 60': 'en', 'polysorbat 60': 'de', 'polisorbat 60': 'tr', 'polisorbato 60': 'it',
  'polysorbaat 60': 'nl',
  'polysorbate 65': 'en', 'polysorbat 65': 'de', 'polisorbat 65': 'tr', 'polisorbato 65': 'it',
  'polysorbaat 65': 'nl',
  'sorbitan monostearate': 'en', sorbitanmonostearat: 'de', 'sorbitan monostearat': 'tr',
  'monostéarate de sorbitane': 'fr', 'sorbitan monostearato': 'it', 'monoestearato de sorbitán': 'es',
  sorbitaanmonostearaat: 'nl',
  'sorbitan tristearate': 'en', sorbitantristearat: 'de', 'sorbitan tristearat': 'tr',
  'tristéarate de sorbitane': 'fr', 'sorbitan tristearato': 'it', 'triestearato de sorbitán': 'es',
  sorbitaantristearaat: 'nl',
  'sorbitan monolaurate': 'en', sorbitanmonolaurat: 'de', 'sorbitan monolaurat': 'tr',
  'monolaurate de sorbitane': 'fr', 'sorbitan monolaurato': 'it', 'monolaurato de sorbitán': 'es',
  sorbitaanmonolauraat: 'nl',
  'sorbitan monooleate': 'en', sorbitanmonooleat: 'de', 'sorbitan monooleat': 'tr',
  'monooléate de sorbitane': 'fr', 'sorbitan monooleato': 'it', 'monooleato de sorbitán': 'es',
  'sorbitaanmono-oleaat': 'nl',
  'sorbitan monopalmitate': 'en', sorbitanmonopalmitat: 'de', 'sorbitan monopalmitat': 'tr',
  'monopalmitate de sorbitane': 'fr', 'sorbitan monopalmitato': 'it', 'monopalmitato de sorbitán': 'es',
  sorbitaanmonopalmitaat: 'nl',
  'l-cystine': 'en', 'l-cystin': 'de', 'l-sistin': 'tr', 'l-cistina': 'it',
  // — lanolin / rennet / whey / cysteine —
  lanolin: 'en', wollwachs: 'de', lanoline: 'fr', lanolina: 'it',
  rennet: 'en', lab: 'de', labferment: 'de', présure: 'fr', caglio: 'it', cuajo: 'es',
  'peynir mayası': 'tr', stremsel: 'nl',
  whey: 'en', molke: 'de', lactosérum: 'fr', 'siero di latte': 'it', 'suero de leche': 'es',
  'peynir suyu': 'tr', wei: 'nl',
  'l-cysteine': 'en', 'l-cystein': 'de', 'l-cystéine': 'fr', 'l-cisteina': 'it', 'l-sistein': 'tr',
  // — flavourings / enzymes / glycerol / manteca —
  'natural flavour': 'en', 'natural flavor': 'en', 'natürliches aroma': 'de',
  'natürliche aromen': 'de', 'arôme naturel': 'fr', 'aroma naturale': 'it', 'aroma natural': 'es',
  'doğal aroma': 'tr', 'natuurlijk aroma': 'nl',
  flavouring: 'en', flavoring: 'en', aroma: 'de', arôme: 'fr', smaakstof: 'nl',
  enzymes: 'en', enzyme: 'de', enzimi: 'it', enzimas: 'es', enzim: 'tr', enzymen: 'nl',
  glycerol: 'en', glycerin: 'de', glycérol: 'fr', glicerina: 'it', gliserin: 'tr',
  glycerine: 'nl',
  manteca: 'es', 'manteca animal': 'es',
}

/** Source language of a matched variant — `null` for E-number codes (language-neutral). */
function variantLanguage(variant: string): string | null {
  if (E_NUMBER_VARIANT.test(variant)) return null
  return VARIANT_LANGUAGE[variant] ?? null
}

const ALCOHOL_FAMILY = new Set([
  'alcohol','alkohol','alcool','alcol','alkol','álcool',
  'ethanol','äthanol','éthanol','etanolo','etanol',
])

const FATTY_ALCOHOL_PREFIX = /\b(cetyl|stearyl|behenyl|lauryl|myristyl|arachidyl|oleyl|cetostearyl|lanolin|isostearyl|octyldodecyl|decyl)\s+/i

// Plant-derived "manteca" phrases — not suspicious (cocoa butter, shea butter, etc.).
// Uses wPre/wPost instead of \b because trailing non-ASCII chars (é in karité) are not \w.
const SAFE_MANTECA_CONTEXT = /(?<![a-zA-Z\dÀ-ɏß])manteca\s+(?:de\s+(?:cacao|kar[ií]t[eé]|coco)|vegetal)(?![a-zA-Z\dÀ-ɏß])/i

// EU marketing labels that allow trace alcohol up to <0,5% — not halal-safe.
const EU_ALCOHOL_FREE_LABEL = /\b(?:alkoholfrei|alkohol[-\s]?frei|alcool[-\s]?frei|alcohol[-\s]?free|alcoholfree|alcoholvrij|alkols[üu]z|analcolic[oa]|non[-\s]?alcoholic)\b/i

const ALCOHOL_PERCENT_CONTEXT = /(?:alkoholgehalt|alcohol\s+content|teneur\s+en\s+alcool|contenuto\s+alcolico|gehalt\s+an\s+alkohol|contenido\s+de\s+alcohol|\b(?:alkohol|alcohol|alcool|alcol|alkol|ethanol|éthanol|äthanol)\b)/i

function isEuAlcoholFreeLabel(text: string): boolean {
  return EU_ALCOHOL_FREE_LABEL.test(text)
}

function isExplicitZeroPercent(whole: number, fracDigits: string | undefined): boolean {
  if (whole !== 0) return false
  if (!fracDigits || fracDigits.length === 0) return true
  return fracDigits.replace(/0/g, '') === ''
}

function hasDeclaredNonZeroAlcohol(text: string): boolean {
  const lower = text.toLowerCase()
  const percentRe = /(?:[<≤]\s*)?(\d+)(?:([.,])(\d+))?\s*%\s*(?:vol\.?|abv)?/gi
  let m: RegExpExecArray | null
  while ((m = percentRe.exec(lower)) !== null) {
    const whole = parseInt(m[1], 10)
    const frac = m[3]
    if (isExplicitZeroPercent(whole, frac)) continue
    if (ALCOHOL_PERCENT_CONTEXT.test(lower)) return true
  }
  return /\b(?!0(?:[.,]0+)?\s*%)(\d+(?:[.,]\d+)?)\s*%\s*(?:alkohol|alcohol|alcool|alcol|alkol|ethanol|äthanol|éthanol)\b/i.test(lower)
}

// Pre-negation words across all supported languages (EN/DE/FR/NL/IT/ES/TR/CS/SR/HU).
// Used to suppress false positives like "enthält keine Zutaten vom Schwein".
const NEGATION_WORDS = /\b(?:keine?|nicht|ohne|frei\s+von|sans|pas|geen|zonder|vrij\s+van|no|not|without|free\s+from|free\s+of|senza|sin|içermez|içermemektedir|icermez|icermemektedir|neobsahuje|bez|nema|nem|mentes)\b/i

// Post-negation: absence markers after the keyword (EN/DE/TR trailing forms).
const POST_NEGATION_WORDS = /(?:[-](?:free|frei)\b|\b(?:free|frei|yoktur|yok|bulunmamaktadır|bulunmamaktadir|bulunmaz|içermez|içermemektedir|icermez|icermemektedir)\b|e?frei\b)/i

// Microbial / vegetable / fermentation-produced rennet — explicit non-animal source.
const HALAL_RENNET_SOURCE = /\b(?:mikrobiel\w*|mikrobial|mikrobiyal|microbial|microbien\w*|microbienne|microbico|microbiano|microbiële|pflanzlich\w*|vegetable|vegetal|végétal\w*|vegetarisch\w*|plant\w*|non-animal|fermentation\s+produced)\s+(?:lab(?:ferment)?|rennet|présure|caglio|cuajo|stremsel|peynir\s+mayası|sirilo|oltóanyag|syřidlo)\b|\b(?:fermentation[- ]?produced\s+)?chymosin\b|\bfpc\b/i

function isHalalRennetSource(chunk: string): boolean {
  return HALAL_RENNET_SOURCE.test(chunk)
}

function escape(s: string) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') }

// Unicode-aware word boundaries covering basic Latin + extended Latin (À-ɏ, U+00C0-U+024F).
// ß (U+00DF) is added explicitly to guard against case-folding edge cases.
// Mirrors IngredientKeywords.wPre / wPost in the Dart client.
const wPre = '(?<![a-zA-Z\\dÀ-ɏß])'
const wPost = '(?![a-zA-Z\\dÀ-ɏß])'

// Variants that commonly appear as the tail of a hyphenated German/French compound
// (e.g. "Vanille-Aroma", "Erdbeer-Aroma"). They must not match when immediately
// preceded by a hyphen; other keywords (alcohol, pork, …) still match after a
// hyphen so that OFF-style slugs like "contains-alcohol" are caught correctly.
const COMPOUND_TAIL_VARIANTS = new Set(['aroma', 'arôme', 'smaakstof'])
const wPreNoHyphen = '(?<![a-zA-Z\\dÀ-ɏß-])'

function isZeroPercentAlcoholDeclaration(text: string, variant: string): boolean {
  const v = escape(variant)
  return new RegExp(
    `\\b0(?:[.,]0+)?\\s*%\\s*${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))|\\b${v}(?:\\b|(?![a-zA-Z\\dÀ-ɏß]))\\s*(?:\\(?\\s*)?0(?:[.,]0+)?\\s*%`,
    'i',
  ).test(text)
}

function matchesVariant(ingredient: string, variant: string): boolean {
  if (variant.includes(' ')) return ingredient.includes(variant)
  if (ALCOHOL_FAMILY.has(variant)) {
    if (FATTY_ALCOHOL_PREFIX.test(ingredient)) return false
    if (isZeroPercentAlcoholDeclaration(ingredient, variant)) return false
    if (isEuAlcoholFreeLabel(ingredient)) return true
    if (hasDeclaredNonZeroAlcohol(ingredient)) return true
    return new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').test(ingredient)
  }
  if (variant === 'manteca' && SAFE_MANTECA_CONTEXT.test(ingredient)) return false
  if (COMPOUND_TAIL_VARIANTS.has(variant)) {
    return new RegExp(`${wPreNoHyphen}${escape(variant)}${wPost}`, 'i').test(ingredient)
  }
  return new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').test(ingredient)
}

// True when the matched variant is preceded or followed by a negation marker in
// the same ingredient chunk, e.g. "enthält keine Zutaten vom Schwein" or
// "domuz yağı ve katkıları yoktur" → negated.
function isNegated(chunk: string, variant: string, canonical?: string): boolean {
  const lower = chunk.toLowerCase()
  let start: number
  let end: number
  if (variant.includes(' ')) {
    const v = variant.toLowerCase()
    start = lower.indexOf(v)
    if (start < 0) return false
    end = start + v.length
  } else {
    const m = new RegExp(`${wPre}${escape(variant)}${wPost}`, 'i').exec(lower)
    if (!m) return false
    start = m.index
    end = m.index + m[0].length
  }
  if (NEGATION_WORDS.test(lower.substring(0, start))) return true
  if (
    canonical === 'alcohol' ||
    canonical === 'ethanol' ||
    ALCOHOL_FAMILY.has(variant)
  ) {
    return false
  }
  return POST_NEGATION_WORDS.test(lower.substring(end))
}

import type { IngredientAnalysisSource } from './ingredientResolution.ts'
import {
  combineMatchSourceKeys,
  isAnalyzableScript,
} from './ingredientResolution.ts'
import { buildSuspiciousExplanation } from './flavouringVerdict.ts'

export interface KeywordResult {
  isHalal: boolean
  isUnknown: boolean
  haram: string[]
  suspicious: string[]
  warnings: Record<string, string>
  /** Flagged ingredient → suspicious canonical (e.g. flavouring, natural flavour). */
  canonicals?: Record<string, string>
  explanation: string
  /** Which ingredient source(s) produced keyword matches (primary, off_en, off_taxonomy, …). */
  keywordMatchSource?: string
  /** Flagged ingredient token → source key that matched it. */
  keywordMatchOrigins?: Record<string, string>
  /** Flagged ingredient token → source language of the matched keyword variant (e.g. "de"). Omitted for language-neutral matches (E-numbers). */
  keywordMatchLanguages?: Record<string, string>
  /** OFF language field used when display text was not keyword-analyzable. */
  analyzeLang?: string | null
}

interface SinglePassResult {
  haram: string[]
  suspicious: string[]
  warnings: Record<string, string>
  canonicals: Record<string, string>
  origins: Record<string, string>
  languages: Record<string, string>
}

function keywordSinglePass(
  ingredients: string[],
  sourceKey: string,
  allHaram: KeywordEntry[],
  allSuspicious: KeywordEntry[],
): SinglePassResult {
  const warnings: Record<string, string> = {}
  const canonicals: Record<string, string> = {}
  const haram: string[] = []
  const suspicious: string[] = []
  const origins: Record<string, string> = {}
  const languages: Record<string, string> = {}

  for (const ing of ingredients) {
    const lower = ing.toLowerCase()
    let foundHaram = false
    for (const entry of allHaram) {
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (matchedVariant && !isNegated(lower, matchedVariant, entry[0])) {
        warnings[ing] = entry[1]
        haram.push(ing)
        origins[ing] = sourceKey
        const lang = variantLanguage(matchedVariant)
        if (lang) languages[ing] = lang
        foundHaram = true
        break
      }
    }
    if (foundHaram) continue
    for (const entry of allSuspicious) {
      const matchedVariant = (entry.slice(2) as string[]).find(v => matchesVariant(lower, v))
      if (
        matchedVariant &&
        entry[0] === 'rennet' &&
        isHalalRennetSource(lower)
      ) {
        continue
      }
      if (matchedVariant && !isNegated(lower, matchedVariant, entry[0])) {
        warnings[ing] = entry[1]
        canonicals[ing] = entry[0]
        suspicious.push(ing)
        origins[ing] = sourceKey
        const lang = variantLanguage(matchedVariant)
        if (lang) languages[ing] = lang
        break
      }
    }
  }

  return { haram, suspicious, warnings, canonicals, origins, languages }
}

function buildKeywordExplanation(
  haram: string[],
  suspicious: string[],
  canonicals: Record<string, string>,
  isUnknown: boolean,
  isUnanalyzableLanguage: boolean,
  labels: string[],
  productName: string,
): string {
  if (haram.length > 0) {
    return `This product contains ingredient(s) that are not permissible: ${haram.join(', ')}. Assessed by keyword matching.`
  }
  if (suspicious.length > 0) {
    return buildSuspiciousExplanation(suspicious, canonicals, labels, productName)
  }
  if (isUnanalyzableLanguage) {
    return 'Ingredients are in a language we cannot analyze. Halal status cannot be determined — check the packaging directly.'
  }
  if (isUnknown) {
    return 'No ingredient data found. Halal status cannot be determined — check the packaging directly.'
  }
  return 'No haram or suspicious ingredients detected. Assessed by keyword matching.'
}

export function keywordAnalysis(
  ingredients: string[],
  extraHaram: KeywordEntry[] = [],
  extraSuspicious: KeywordEntry[] = [],
): KeywordResult {
  return keywordAnalysisFromSources(
    ingredients.length > 0 ? [{ key: 'primary', ingredients }] : [],
    ingredients,
    null,
    extraHaram,
    extraSuspicious,
  )
}

/** Multi-source keyword pass with language-fallback transparency. */
export function keywordAnalysisFromSources(
  sources: IngredientAnalysisSource[],
  displayIngredients: string[],
  analyzeLang: string | null,
  extraHaram: KeywordEntry[] = [],
  extraSuspicious: KeywordEntry[] = [],
): KeywordResult {
  const allHaram = [...HARAM_ENTRIES, ...extraHaram]
  const allSuspicious = [...SUSPICIOUS_ENTRIES, ...extraSuspicious]

  const haram: string[] = []
  const suspicious: string[] = []
  const warnings: Record<string, string> = {}
  const canonicals: Record<string, string> = {}
  const matchOrigins: Record<string, string> = {}
  const matchLanguages: Record<string, string> = {}
  const matchedSourceKeys: string[] = []

  const seenHaram = new Set<string>()
  const seenSuspicious = new Set<string>()

  for (const source of sources) {
    const pass = keywordSinglePass(
      source.ingredients,
      source.key,
      allHaram,
      allSuspicious,
    )
    if (pass.haram.length > 0 || pass.suspicious.length > 0) {
      matchedSourceKeys.push(source.key)
    }
    for (const ing of pass.haram) {
      const key = ing.toLowerCase()
      if (!seenHaram.has(key)) {
        seenHaram.add(key)
        haram.push(ing)
      }
      matchOrigins[ing] = pass.origins[ing] ?? source.key
      warnings[ing] = pass.warnings[ing] ?? warnings[ing] ?? ''
      if (pass.languages[ing]) matchLanguages[ing] = pass.languages[ing]
    }
    for (const ing of pass.suspicious) {
      const key = ing.toLowerCase()
      if (!seenSuspicious.has(key)) {
        seenSuspicious.add(key)
        suspicious.push(ing)
      }
      matchOrigins[ing] = pass.origins[ing] ?? source.key
      warnings[ing] = pass.warnings[ing] ?? warnings[ing] ?? ''
      if (pass.canonicals[ing]) canonicals[ing] = pass.canonicals[ing]
      if (pass.languages[ing]) matchLanguages[ing] = pass.languages[ing]
    }
  }

  const primaryText = displayIngredients.join(', ')
  const hasLangFallback = sources.some(
    s => s.key.startsWith('off_') && s.key !== 'off_taxonomy' && s.ingredients.length > 0,
  )

  // Primary label unreadable and no translated OFF text — unknown even when
  // taxonomy IDs exist but matched nothing (e.g. bg:pork + en:water only).
  const isUnanalyzableLanguage = displayIngredients.length > 0 &&
    haram.length === 0 &&
    suspicious.length === 0 &&
    !isAnalyzableScript(primaryText) &&
    !hasLangFallback

  const isUnknown = displayIngredients.length === 0 || isUnanalyzableLanguage
  const explanation = buildKeywordExplanation(
    haram,
    suspicious,
    canonicals,
    displayIngredients.length === 0,
    isUnanalyzableLanguage,
    [],
    '',
  )

  const keywordMatchSource = isUnanalyzableLanguage
    ? 'unanalyzable'
    : combineMatchSourceKeys(matchedSourceKeys)

  return {
    isHalal: !isUnknown && haram.length === 0 && suspicious.length === 0,
    isUnknown,
    haram,
    suspicious,
    warnings,
    canonicals: Object.keys(canonicals).length > 0 ? canonicals : undefined,
    explanation,
    keywordMatchSource,
    keywordMatchOrigins: Object.keys(matchOrigins).length > 0 ? matchOrigins : undefined,
    keywordMatchLanguages: Object.keys(matchLanguages).length > 0 ? matchLanguages : undefined,
    analyzeLang,
  }
}
