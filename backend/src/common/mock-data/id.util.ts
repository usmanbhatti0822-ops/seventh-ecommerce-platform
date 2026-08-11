/**
 * Small helpers shared by the in-memory demo stores under `common/mock-data`.
 * Kept dependency-free on purpose — these are used at module-load time to
 * build seed arrays, before Nest's DI container exists.
 */

let counter = 0;

/** Generates a short, readable, collision-free id for records created at runtime (e.g. `notif_m3x1k`). */
export function generateMockId(prefix: string): string {
  counter += 1;
  return `${prefix}_${Date.now().toString(36)}${counter.toString(36)}`;
}

/** ISO timestamp `n` days in the past, relative to now — used to make seed data look freshly generated. */
export function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString();
}

/** ISO timestamp `n` days in the future, relative to now. */
export function daysFromNow(n: number): string {
  return daysAgo(-n);
}
