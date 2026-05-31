import { z } from 'zod'

export const rankingSchema = z.object({
  periodo: z.enum(['semanal']).default('semanal'),
})

export type RankingDTO = z.infer<typeof rankingSchema>