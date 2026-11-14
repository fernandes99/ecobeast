export interface AppearanceInput {
  bodyTypeId: number;
  skinPaletteId: number;
  parts: { partId: number; paletteId: number | null }[];
}

export interface AppearanceCatalog {
  bodies: { id: number; name: string }[];
  slots: {
    id: number;
    name: string;
    paletteKind: string | null;
    required: boolean;
  }[];
  parts: {
    id: number;
    name: string;
    slotId: number;
    bodyTypeId: number | null;
  }[];
  palettes: { id: number; kind: string }[];
}

/** A mensagem do primeiro erro da aparência, ou `null` se ela vale. */
export function appearanceError(
  input: AppearanceInput,
  catalog: AppearanceCatalog,
): string | null {
  const body = catalog.bodies.find(({ id }) => id === input.bodyTypeId);
  if (!body) return 'Esse corpo não existe.';
  const skin = catalog.palettes.find(({ id }) => id === input.skinPaletteId);
  if (skin?.kind !== 'skin') return 'Essa cor de pele não existe.';

  const slotOf = (slotId: number) =>
    catalog.slots.find(({ id }) => id === slotId)!;
  const worn = new Set<number>();
  for (const { partId } of input.parts) {
    const part = catalog.parts.find(({ id }) => id === partId);
    if (!part) return `A peça ${partId} não existe.`;
    if (part.bodyTypeId !== null && part.bodyTypeId !== body.id) {
      return `A peça ${part.name} não serve no corpo ${body.name}.`;
    }
    if (worn.has(part.slotId)) {
      return `Duas peças no mesmo lugar: ${slotOf(part.slotId).name}.`;
    }
    worn.add(part.slotId);
  }

  const missing = catalog.slots.find(
    ({ id, required }) => required && !worn.has(id),
  );
  if (missing) return `Escolha um ${missing.name}.`;

  for (const { partId, paletteId } of input.parts) {
    const slot = slotOf(catalog.parts.find(({ id }) => id === partId)!.slotId);
    if (paletteId === null) {
      if (slot.paletteKind !== null) {
        return `Escolha uma cor para ${slot.name}.`;
      }
      continue;
    }
    const palette = catalog.palettes.find(({ id }) => id === paletteId);
    if (slot.paletteKind === null || palette?.kind !== slot.paletteKind) {
      return `A cor ${paletteId} não serve para ${slot.name}.`;
    }
  }
  return null;
}
