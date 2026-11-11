import { expect, test } from 'claude-code/testing'

import { inline, split, unicode } from './math'

test('inline math becomes Unicode', async () => {
  expect(unicode('\\alpha^2 + \\beta_{ij} \\leq \\infty')).toBe('α² + βᵢⱼ ≤ ∞')
  expect(unicode('\\frac{a+b}{2}')).toBe('(a+b)/2')
  expect(unicode('\\sqrt{x^2+1}')).toBe('√(x²+1)')
  expect(unicode('\\mathbb{R}^n \\to \\mathbb{R}')).toBe('ℝⁿ → ℝ')
  expect(unicode('\\sum_{i=1}^{n} x_i')).toBe('∑ᵢ₌₁ⁿ xᵢ')
  expect(unicode('x^{q}')).toBe('x^q')
  expect(unicode('\\text{if } x > 0')).toBe('if  x > 0')
})

test('dollars that are money or code stay as written', async () => {
  expect(inline('costs $5 and $10')).toBe('costs $5 and $10')
  expect(inline('run `echo $HOME$PATH` with $x^2$')).toBe('run `echo $HOME$PATH` with x²')
  expect(inline('as \\(\\pi r^2\\) says')).toBe('as π r² says')
})

test('display math splits the reply, fenced code does not', async () => {
  const parts = split('Energy:\n\n$$E = mc^2$$\n\nwhere $c$ is light.\n\n```sh\necho $$x$$\n```')
  expect(parts).toEqual([
    { kind: 'text', text: 'Energy:\n\n' },
    { kind: 'math', tex: 'E = mc^2' },
    { kind: 'text', text: '\n\nwhere c is light.\n\n```sh\necho $$x$$\n```' },
  ])
  expect(split('\\[\n\\int_0^1 x\\,dx\n\\]')).toEqual([{ kind: 'math', tex: '\\int_0^1 x\\,dx' }])
})

const MESSAGE = { plugin: 'latex', component: 'AssistantMessage', requestId: 'm1', surface: 'terminal' } as const

test('display math is drawn as a picture under the reply', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  on('process.run', () => ({ value: { exitCode: 0, stdout: '/c/e.png 12 2\n', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }))

  const ui = await $.ui.mount({ ...MESSAGE, props: { text: 'So\n\n$$E=mc^2$$', isFirstOfReply: true } })
  const image = await ui.find({ type: 'Image' })
  expect(image?.props).toMatchObject({ source: { file: '/c/e.png', format: 'png' }, columns: 12, rows: 2 })
  expect((await ui.find({ type: 'Text' }))?.text).toBe('engine')
  await ui.unmount()
})

test('a reply without math is left to the engine', async ($, on) => {
  let seen = ''
  on('ui.render', ($, e) => {
    if (e.component === 'AssistantMessage') seen = e.props.text
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })

  const ui = await $.ui.mount({ ...MESSAGE, props: { text: 'plain $x_1$ text', isFirstOfReply: true } })
  expect(seen).toBe('plain x₁ text')
  await ui.unmount()
})
