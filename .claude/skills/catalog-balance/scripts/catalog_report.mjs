// Rodar com o cwd em server/ (precisa do pg e do .env de lá):
//   cd server; node ../.claude/skills/catalog-balance/scripts/catalog_report.mjs
import { createRequire } from 'node:module';
import path from 'node:path';

const require = createRequire(path.join(process.cwd(), 'package.json'));
const pg = require('pg');
process.loadEnvFile('.env');

const c = new pg.Client({ connectionString: process.env.DATABASE_URL });
await c.connect();
const q = async (s) => (await c.query(s)).rows;

const elements = await q(`select id, name from ecobeasts.elements order by id`);
const biomes = await q(`select id, name from ecobeasts.biomes order by id`);
const rarities = await q(`select id, name from ecobeasts.rarities order by id`);
const species = await q(`select s.id, s.name, s.evolves_from_species_id evo, r.name rarity, g.name growth
  from ecobeasts.species s join ecobeasts.rarities r on r.id = s.rarity_id
  join ecobeasts.growth_rates g on g.id = s.growth_rate_id order by s.id`);
const el = await q(`select se.species_id sid, e.name from ecobeasts.species_elements se
  join ecobeasts.elements e on e.id = se.element_id order by 1, se.slot`);
const st = await q(`select ss.species_id sid, st.slug, ss.base_value v from ecobeasts.species_stats ss
  join ecobeasts.stats st on st.id = ss.stat_id`);
const bi = await q(`select sb.species_id sid, b.name, sb.rate from ecobeasts.species_biomes sb
  join ecobeasts.biomes b on b.id = sb.biome_id order by 1, b.id`);
const day = await q(`select sd.species_id sid, d.name from ecobeasts.species_day_phases sd
  join ecobeasts.day_phases d on d.id = sd.day_phase_id order by 1, d.id`);
const sk = await q(`select ss.species_id sid, cat.name cat from ecobeasts.species_skills ss
  join ecobeasts.skills k on k.id = ss.skill_id
  join ecobeasts.skill_categories cat on cat.id = k.skill_category_id`);
const skillsByEl = await q(`select e.name el, cat.name cat, count(*)::int n from ecobeasts.skills k
  join ecobeasts.elements e on e.id = k.element_id
  join ecobeasts.skill_categories cat on cat.id = k.skill_category_id group by 1, 2`);
await c.end();

const by = (rows, id) => rows.filter((r) => r.sid === id);
const sp = species.map((s) => ({
  ...s,
  els: by(el, s.id).map((r) => r.name),
  stats: Object.fromEntries(by(st, s.id).map((r) => [r.slug, r.v])),
  biomes: by(bi, s.id),
  day: by(day, s.id).map((r) => r.name),
  supportShare: (() => {
    const all = by(sk, s.id);
    return all.length ? all.filter((r) => r.cat === 'Suporte').length / all.length : 0;
  })(),
}));
const byId = new Map(sp.map((s) => [s.id, s]));

// Primeira proposta de papel, pelos atributos da forma final; confira contra a spec da linha.
function role(s) {
  const t = s.stats;
  const off = Math.max(t.atk, t.sp_atk);
  const phys = (t.hp + t.def) / 2;
  const spec = (t.hp + t.sp_def) / 2;
  const bulk = Math.max(phys, spec);
  const side = Math.abs(t.atk - t.sp_atk) < 15 ? 'misto' : t.atk > t.sp_atk ? 'físico' : 'especial';
  const guard = Math.abs(t.def - t.sp_def) < 15 ? 'misto' : t.def > t.sp_def ? 'físico' : 'especial';
  const pace = t.spd >= 100 ? 'rápido' : t.spd <= 60 ? 'lento' : 'médio';
  if (bulk >= off + 15) return s.supportShare >= 0.4 ? 'Suporte' : `Guardião ${guard}`;
  if (bulk >= off - 10) return `Lutador ${side} ${pace}`;
  return `Atacante ${side} ${pace}`;
}

const lines = sp.filter((s) => s.evo == null).map((base) => {
  const forms = [base];
  for (let i = 0; i < forms.length; i++) forms.push(...sp.filter((s) => s.evo === forms[i].id));
  const finals = forms.filter((f) => !sp.some((s) => s.evo === f.id));
  return { base, forms, finals };
});

const out = [];
const p = (s = '') => out.push(s);
p('## Linhas');
p('| Linha | Formas | Elementos | Raridade | Papel (final) | Biomas da base | Partes do dia |');
p('|---|---|---|---|---|---|---|');
for (const L of lines) {
  const els = [...new Set(L.forms.flatMap((f) => f.els))].join(', ');
  const roles = L.finals.map((f) => `${f.name}: ${role(f)}`).join('; ');
  const bio = L.base.biomes.map((b) => `${b.name} ${b.rate}`).join(', ');
  const stages = [[L.base]];
  while (true) {
    const next = sp.filter((s) => stages.at(-1).some((f) => f.id === s.evo));
    if (!next.length) break;
    stages.push(next);
  }
  p(`| ${L.base.name} | ${stages.map((g) => g.map((f) => f.name).join(' ou ')).join(' → ')} | ${els} | ${L.base.rarity}/${L.base.growth} | ${roles} | ${bio} | ${L.base.day.join(', ')} |`);
}

p('\n## Elementos (linhas que têm o Elemento)');
p('| Elemento | Como 1º da base | Em alguma forma | Técnicas F/E/S |');
p('|---|---|---|---|');
for (const e of elements) {
  const primary = lines.filter((L) => L.base.els[0] === e.name).map((L) => L.base.name);
  const any = lines.filter((L) => L.forms.some((f) => f.els.includes(e.name))).map((L) => L.base.name);
  const n = (cat) => skillsByEl.find((r) => r.el === e.name && r.cat === cat)?.n ?? 0;
  p(`| ${e.name} | ${primary.length} ${primary.join(', ')} | ${any.length} ${any.join(', ')} | ${n('Física')}/${n('Especial')}/${n('Suporte')} |`);
}

p('\n## Papéis (formas finais)');
const roleCount = {};
for (const L of lines) for (const f of L.finals) (roleCount[role(f)] ??= []).push(f.name);
for (const [r, names] of Object.entries(roleCount).sort((a, b) => b[1].length - a[1].length)) p(`- ${r}: ${names.length} (${names.join(', ')})`);

p('\n## Biomas (linhas cuja base nasce lá, taxa da base)');
p('| Bioma | Linhas | Soma das taxas |');
p('|---|---|---|');
for (const b of biomes) {
  const here = lines.filter((L) => L.base.biomes.some((x) => x.name === b.name));
  const sum = here.reduce((a, L) => a + L.base.biomes.find((x) => x.name === b.name).rate, 0);
  p(`| ${b.name} | ${here.length} ${here.map((L) => L.base.name).join(', ')} | ${sum} |`);
}

p('\n## Raridade da base');
for (const r of rarities) {
  const here = lines.filter((L) => L.base.rarity === r.name).map((L) => L.base.name);
  p(`- ${r.name}: ${here.length} ${here.join(', ')}`);
}
p(`\nTotal: ${sp.length} espécies em ${lines.length} linhas; maior id ${Math.max(...sp.map((s) => s.id))}.`);
console.log(out.join('\n'));
