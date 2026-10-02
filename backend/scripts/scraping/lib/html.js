/** Utilidades de parseo HTML sin dependencias externas. */

const ENTITIES = {
  nbsp: ' ',
  amp: '&',
  lt: '<',
  gt: '>',
  quot: '"',
  apos: "'",
  reg: '®',
  deg: '°',
  mdash: '—',
  ndash: '–',
  hellip: '…',
  trade: '™',
  cent: '¢',
  euro: '€',
  pound: '£',
};

export function decodeEntities(s) {
  return s.replace(/&(#x?[0-9a-fA-F]+|[a-zA-Z]+);/g, (m, e) => {
    if (e[0] === '#') {
      const code =
        e[1] === 'x' || e[1] === 'X'
          ? parseInt(e.slice(2), 16)
          : parseInt(e.slice(1), 10);
      return Number.isFinite(code) ? String.fromCodePoint(code) : ' ';
    }
    return ENTITIES[e.toLowerCase()] ?? ' ';
  });
}

/** Quita scripts/estilos/tags y colapsa espacios. */
export function stripTags(html) {
  return decodeEntities(
    html
      .replace(/<script[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style[\s\S]*?<\/style>/gi, ' ')
      .replace(/<!--[\s\S]*?-->/g, ' ')
      .replace(/<br\s*\/?>/gi, ' ')
      .replace(/<[^>]+>/g, ' '),
  )
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Divide el HTML en tablas y devuelve filas como pares etiqueta→valor.
 * Filas con una sola celda (encabezados colspan) se devuelven como
 * { section: '...' } para conservar los títulos de sección.
 */
export function splitTables(html) {
  const tables = [];
  const tableRe = /<table[\s\S]*?<\/table>/gi;
  let tableMatch;
  while ((tableMatch = tableRe.exec(html)) !== null) {
    const rows = [];
    const rowRe = /<tr[\s\S]*?<\/tr>/gi;
    let rowMatch;
    while ((rowMatch = rowRe.exec(tableMatch[0])) !== null) {
      const cellRe = /<t[dh][^>]*>([\s\S]*?)<\/t[dh]>/gi;
      const cells = [];
      let cellMatch;
      while ((cellMatch = cellRe.exec(rowMatch[0])) !== null) {
        const text = stripTags(cellMatch[1]);
        if (text) cells.push(text);
      }
      if (cells.length === 1) rows.push({ section: cells[0] });
      else if (cells.length >= 2) rows.push({ label: cells[0], value: cells.slice(1).join(' ') });
    }
    if (rows.length) tables.push(rows);
  }
  return tables;
}

/** Todas las filas de todas las tablas, en orden. */
export function allRows(html) {
  return splitTables(html).flat();
}

/** Texto plano de toda la página. */
export function pageText(html) {
  return stripTags(html);
}

/** Primer <h1> como texto. */
export function firstH1(html) {
  const m = html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i);
  return m ? stripTags(m[1]) : null;
}
