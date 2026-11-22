export function now_ms() { return Math.round(performance.now()); }
export function case_name() { return process.env.YB_CASE ?? ""; }
