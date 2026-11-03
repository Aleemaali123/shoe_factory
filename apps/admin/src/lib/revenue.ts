export function formatChange(change: number | null) {
  if (change === null) return '—'
  const rounded = Math.round(change)
  if (rounded === 0) return '0%'
  return rounded > 0 ? `+${rounded}%` : `${rounded}%`
}

export function changeTone(change: number | null) {
  if (change === null || Math.round(change) === 0) return 'flat'
  return change > 0 ? 'up' : 'down'
}
