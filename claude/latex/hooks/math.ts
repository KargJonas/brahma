// Splits a reply's markdown into prose and display math, and turns inline math
// into Unicode, since a picture cannot sit inside a wrapped line.

export type Part = { kind: 'text'; text: string } | { kind: 'math'; tex: string }

// Display math is `$$…$$` anywhere, or `\[…\]` opening a line. Inline math is
// `$…$` (pandoc's rule: no space inside the dollars, no digit after the closing
// one, so "$5 and $10" stays text) or `\(…\)`. Code fences and spans are left alone.
export function split(markdown: string): Part[] {
  const parts: Part[] = []
  const push = (text: string) => {
    const last = parts.at(-1)
    if (last?.kind === 'text') last.text += text
    else parts.push({ kind: 'text', text })
  }

  let fence: string | null = null
  let prose = ''
  const take = () => {
    for (const p of display(prose)) {
      if (p.kind === 'math') parts.push(p)
      else push(inline(p.text))
    }
    prose = ''
  }

  const lines = markdown.split('\n')
  lines.forEach((line, k) => {
    const text = k < lines.length - 1 ? line + '\n' : line
    const marker = line.match(/^\s*(`{3,}|~{3,})/)?.[1]
    if (fence) {
      push(text)
      if (marker && marker[0] === fence[0] && marker.length >= fence.length) fence = null
    } else if (marker) {
      take()
      push(text)
      fence = marker
    } else prose += text
  })
  take()
  return parts.filter(p => p.kind === 'math' || p.text.trim())
}

function display(text: string): Part[] {
  const parts: Part[] = []
  const re = /\$\$([\s\S]+?)\$\$|(?<=^[ \t]*)\\\[([\s\S]+?)\\\]/gm
  let at = 0
  for (const m of text.matchAll(re)) {
    const tex = (m[1] ?? m[2] ?? '').trim()
    if (!tex || inCodeSpan(text, m.index)) continue
    parts.push({ kind: 'text', text: text.slice(at, m.index) })
    parts.push({ kind: 'math', tex })
    at = m.index + m[0].length
  }
  parts.push({ kind: 'text', text: text.slice(at) })
  return parts
}

function inCodeSpan(text: string, index: number): boolean {
  const before = text.slice(text.lastIndexOf('\n\n', index) + 1, index)
  return (before.match(/`/g)?.length ?? 0) % 2 === 1
}

export function inline(text: string): string {
  // Code spans first, so dollars inside them survive
  return text.replace(
    /(`+)[\s\S]*?\1|\\\((.+?)\\\)|(?<![\\$\w])\$(?![\s$])((?:\\\$|[^$\n])+?)(?<!\s)\$(?![\d$])/g,
    (all, ticks, paren, dollar) => (ticks ? all : unicode(paren ?? dollar)),
  )
}

// A small LaTeX-to-Unicode converter: symbols, sub/superscripts, fractions,
// roots, accents and math alphabets. Anything it does not know is kept as written.
export function unicode(tex: string): string {
  let i = 0

  const group = (): string => {
    // tex[i] === '{'
    let depth = 0
    const start = i + 1
    for (; i < tex.length; i++) {
      if (tex[i] === '\\') i++
      else if (tex[i] === '{') depth++
      else if (tex[i] === '}' && --depth === 0) return tex.slice(start, i++)
    }
    return tex.slice(start)
  }

  const rawArg = (): string => {
    while (tex[i] === ' ') i++
    if (tex[i] === '{') return group()
    if (tex[i] === '\\') {
      const name = tex.slice(i).match(/^\\([a-zA-Z]+|.)/)?.[0] ?? '\\'
      i += name.length
      return name
    }
    return tex[i++] ?? ''
  }
  const arg = () => unicode(rawArg())

  let out = ''
  while (i < tex.length) {
    const c = tex[i]!
    if (c === '\\') {
      const name = tex.slice(i + 1).match(/^[a-zA-Z]+/)?.[0]
      if (!name) {
        const s = tex[i + 1] ?? ''
        i += 2
        out += { ',': ' ', ';': ' ', ':': ' ', ' ': ' ', '!': '', '\\': ' ', '|': '‖' }[s] ?? s
        continue
      }
      i += name.length + 1
      if (name in SYMBOLS) out += SYMBOLS[name]
      else if (name in OPERATORS) out += name
      else if (FRACS.has(name)) {
        const a = arg()
        const b = arg()
        out += `${wrap(a)}/${wrap(b)}`
      } else if (name === 'binom') {
        out += `C(${arg()}, ${arg()})`
      } else if (name === 'sqrt') {
        let n = ''
        if (tex[i] === '[') {
          const end = tex.indexOf(']', i)
          n = tex.slice(i + 1, end)
          i = end + 1
        }
        const root = { '': '√', '2': '√', '3': '∛', '4': '∜' }[n] ?? `${script(n, SUP, '')}√`
        out += root + wrap(arg())
      } else if (TEXT.has(name)) out += rawArg()
      else if (name in ALPHABETS) out += [...arg()].map(ALPHABETS[name]!).join('')
      else if (PLAIN.has(name)) out += arg()
      else if (name in ACCENTS) {
        const a = arg()
        out += a + ACCENTS[name]
      } else if (SIZING.has(name)) {
        if (tex[i] === '.') i++
      } else out += `\\${name}`
    } else if (c === '^' || c === '_') {
      i++
      const a = arg()
      out += script(a, c === '^' ? SUP : SUB, c)
    } else if (c === '{') out += unicode(group())
    else if (c === '}') i++
    else if (c === "'") {
      out += '′'
      i++
    } else {
      out += c
      i++
    }
  }
  return out
}

const wrap = (s: string) => ([...s].length > 1 && !/^\(.*\)$/.test(s) ? `(${s})` : s)

function script(s: string, map: Record<string, string>, mark: string): string {
  const chars = [...s]
  if (chars.every(ch => ch in map)) return chars.map(ch => map[ch]).join('')
  return chars.length > 1 ? `${mark}(${s})` : mark + s
}

const SUP: Record<string, string> = Object.fromEntries(
  [...'0123456789+-=()abcdefghijklmnoprstuvwxyzABDEGHIJKLMNOPRTUVWβγδθιφχ′* ']
    .map((ch, k) => [ch, [...'⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻᴬᴮᴰᴱᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᴿᵀᵁⱽᵂᵝᵞᵟᶿᶥᵠᵡ′* '][k]!]),
)

const SUB: Record<string, string> = Object.fromEntries(
  [...'0123456789+-=()aehijklmnoprstuvxβγρφχ ']
    .map((ch, k) => [ch, [...'₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎ₐₑₕᵢⱼₖₗₘₙₒₚᵣₛₜᵤᵥₓᵦᵧᵨᵩᵪ '][k]!]),
)

// Math alphabets by code point offset, with the letters Unicode placed earlier
function alphabet(upper: number, lower: number | null, holes: Record<string, string>) {
  return (ch: string) => {
    if (ch in holes) return holes[ch]!
    const c = ch.codePointAt(0)!
    if (c >= 65 && c <= 90) return String.fromCodePoint(upper + c - 65)
    if (lower !== null && c >= 97 && c <= 122) return String.fromCodePoint(lower + c - 97)
    return ch
  }
}

const ALPHABETS: Record<string, (ch: string) => string> = {
  mathbb: alphabet(0x1d538, 0x1d552, { C: 'ℂ', H: 'ℍ', N: 'ℕ', P: 'ℙ', Q: 'ℚ', R: 'ℝ', Z: 'ℤ' }),
  mathcal: alphabet(0x1d49c, null, { B: 'ℬ', E: 'ℰ', F: 'ℱ', H: 'ℋ', I: 'ℐ', L: 'ℒ', M: 'ℳ', R: 'ℛ' }),
  mathscr: alphabet(0x1d49c, null, { B: 'ℬ', E: 'ℰ', F: 'ℱ', H: 'ℋ', I: 'ℐ', L: 'ℒ', M: 'ℳ', R: 'ℛ' }),
  mathfrak: alphabet(0x1d504, 0x1d51e, { C: 'ℭ', H: 'ℌ', I: 'ℑ', R: 'ℜ', Z: 'ℨ' }),
}

const FRACS = new Set(['frac', 'dfrac', 'tfrac', 'cfrac'])
const TEXT = new Set(['text', 'textrm', 'textit', 'textbf', 'mbox', 'operatorname'])
const PLAIN = new Set(['mathrm', 'mathbf', 'mathit', 'mathsf', 'mathtt', 'boldsymbol', 'bm', 'displaystyle', 'textstyle'])
const SIZING = new Set(['left', 'right', 'big', 'Big', 'bigg', 'Bigg', 'bigl', 'bigr', 'Bigl', 'Bigr', 'middle', 'limits', 'nolimits'])
const OPERATORS = Object.fromEntries(
  'sin cos tan cot sec csc arcsin arccos arctan sinh cosh tanh log ln lg exp lim liminf limsup max min sup inf det dim ker deg arg gcd lcm Pr hom mod'
    .split(' ')
    .map(n => [n, n]),
)

const ACCENTS: Record<string, string> = {
  hat: '̂', widehat: '̂', bar: '̄', overline: '̅', vec: '⃗',
  tilde: '̃', widetilde: '̃', dot: '̇', ddot: '̈', underline: '̲',
}

const SYMBOLS: Record<string, string> = {
  alpha: 'α', beta: 'β', gamma: 'γ', delta: 'δ', epsilon: 'ϵ', varepsilon: 'ε', zeta: 'ζ', eta: 'η',
  theta: 'θ', vartheta: 'ϑ', iota: 'ι', kappa: 'κ', lambda: 'λ', mu: 'μ', nu: 'ν', xi: 'ξ', pi: 'π',
  varpi: 'ϖ', rho: 'ρ', varrho: 'ϱ', sigma: 'σ', varsigma: 'ς', tau: 'τ', upsilon: 'υ', phi: 'ϕ',
  varphi: 'φ', chi: 'χ', psi: 'ψ', omega: 'ω',
  Gamma: 'Γ', Delta: 'Δ', Theta: 'Θ', Lambda: 'Λ', Xi: 'Ξ', Pi: 'Π', Sigma: 'Σ', Upsilon: 'Υ',
  Phi: 'Φ', Psi: 'Ψ', Omega: 'Ω',
  sum: '∑', prod: '∏', coprod: '∐', int: '∫', iint: '∬', iiint: '∭', oint: '∮', partial: '∂',
  nabla: '∇', infty: '∞', pm: '±', mp: '∓', times: '×', div: '÷', cdot: '·', cdotp: '·', ast: '∗',
  star: '⋆', circ: '∘', bullet: '•', cdots: '⋯', ldots: '…', dots: '…', vdots: '⋮', ddots: '⋱',
  leq: '≤', le: '≤', geq: '≥', ge: '≥', neq: '≠', ne: '≠', approx: '≈', equiv: '≡', sim: '∼',
  simeq: '≃', cong: '≅', propto: '∝', ll: '≪', gg: '≫', prec: '≺', succ: '≻', coloneqq: '≔',
  in: '∈', notin: '∉', ni: '∋', subset: '⊂', subseteq: '⊆', supset: '⊃', supseteq: '⊇',
  cup: '∪', cap: '∩', bigcup: '⋃', bigcap: '⋂', setminus: '∖', emptyset: '∅', varnothing: '∅',
  forall: '∀', exists: '∃', nexists: '∄', neg: '¬', lnot: '¬', land: '∧', wedge: '∧', lor: '∨',
  vee: '∨', oplus: '⊕', otimes: '⊗', bigoplus: '⨁', bigotimes: '⨂', top: '⊤', bot: '⊥', perp: '⊥',
  vdash: '⊢', models: '⊨', to: '→', rightarrow: '→', leftarrow: '←', gets: '←', leftrightarrow: '↔',
  Rightarrow: '⇒', Leftarrow: '⇐', Leftrightarrow: '⇔', implies: '⟹', impliedby: '⟸', iff: '⟺',
  mapsto: '↦', longrightarrow: '⟶', longmapsto: '⟼', uparrow: '↑', downarrow: '↓', hookrightarrow: '↪',
  langle: '⟨', rangle: '⟩', lceil: '⌈', rceil: '⌉', lfloor: '⌊', rfloor: '⌋', lbrace: '{', rbrace: '}',
  vert: '|', lvert: '|', rvert: '|', Vert: '‖', lVert: '‖', rVert: '‖', mid: '∣', parallel: '∥',
  angle: '∠', triangle: '△', square: '□', dagger: '†', hbar: 'ℏ', ell: 'ℓ', Re: 'ℜ', Im: 'ℑ',
  aleph: 'ℵ', prime: '′', colon: ':', quad: '  ', qquad: '    ', checkmark: '✓',
}
