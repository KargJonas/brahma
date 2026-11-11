import type { Register } from 'claude-code'

import { split } from './math'

type Rendered = { file: string; columns: number; rows: number } | { error: string }

// Draws the math in Claude's replies: display math as a picture (kitty graphics,
// via bin/tex2png), inline math as Unicode. Elsewhere the reply is left alone.
export const register: Register = on => {
  // One render per equation and width, shared by the redraws while a reply streams
  const renders = new Map<string, Promise<Rendered>>()

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    if (e.surface !== 'terminal' || e.props.isSummary) return next(e)

    const parts = split(e.props.text)
    if (!parts.some(p => p.kind === 'math')) {
      const text = parts[0]?.kind === 'text' ? parts[0].text : e.props.text
      return text === e.props.text ? next(e) : next({ ...e, props: { ...e.props, text } })
    }

    const maxColumns = Math.max(10, Math.min(255, (e.viewport?.columns ?? 80) - 4))
    const render = (tex: string): Promise<Rendered> => {
      const key = `${maxColumns}\0${tex}`
      let rendered = renders.get(key)
      if (!rendered) {
        rendered = $.process
          .run([`${$.plugin.root}/bin/tex2png`, String(maxColumns)], { stdin: tex, timeoutMs: 30_000 })
          .then(r => {
            const [file, columns, rows] = r.stdout.trim().split(' ')
            if (r.exitCode === 0 && file) return { file, columns: Number(columns), rows: Number(rows) }
            return { error: r.stderr.trim() || `tex2png exited ${r.exitCode}` }
          })
          .catch((err: unknown) => ({ error: String(err) }))
          .then(result => {
            if ('error' in result) renders.delete(key) // try again on the next draw
            return result
          })
        renders.set(key, rendered)
      }
      return rendered
    }

    const [first, ...rest] = parts
    const head = first?.kind === 'text' ? await next({ ...e, props: { ...e.props, text: first.text } }) : null
    const body = head ? rest : parts
    const pictures = await Promise.all(body.map(p => (p.kind === 'math' ? render(p.tex) : null)))

    const { Box, Markdown, Image } = $.ui.resolve(e)
    return (
      <Box flexDirection="column" gap={1}>
        {head}
        {body.map((p, k) => {
          const picture = pictures[k]
          return (
            <Box paddingLeft={2}>
              {p.kind === 'text' ? (
                <Markdown text={p.text} />
              ) : picture && 'file' in picture ? (
                <Image
                  source={{ file: picture.file, format: 'png' }}
                  columns={picture.columns}
                  rows={picture.rows}
                  alt={p.tex}
                />
              ) : (
                <Markdown text={'```latex\n' + p.tex + '\n```'} />
              )}
            </Box>
          )
        })}
      </Box>
    )
  })
}
