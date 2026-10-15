# Forgelink

A small Android utility for personal use. It copies daily data from **Health Connect** (weight, steps) and **Kalorické tabulky** (kcal, protein, carbs, fat, fiber) into the nutrition coach's existing Google Sheet. It writes values only, into the matching date row, and never touches manual columns, formulas or formatting.

Status: project scaffold. Implementation follows [docs/implementation_plan.md](docs/implementation_plan.md).

Forgelink reuses proven pieces of [Forgetrack](../Forgetrack) (Health Connect reading, the Kalorické tabulky client, Google Sheets access) without depending on it.
