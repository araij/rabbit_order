<!-- vim: set et sw=4 : -->

# Global Instructions

## Quota Use

- Prioritize quota savings over speed; use subagents only when expected to reduce total quota usage, including delegation overhead.
- Keep reads and tool output focused; batch independent read-only checks, script automatable workflows, and avoid frequent polling.
- Run the narrowest relevant tests; repeat or broaden checks only when changes, failures, or new evidence justify it.
- Never sacrifice root-cause resolution to save quota.

## Information Sources

- For paper research, use only full-text-accessible papers from top venues or with sufficient citation counts; never judge by title/abstract alone. Ask if important papers are inaccessible.

## Coding

- Strive for simplicity at every level. Leverage existing software, language features, and clean abstractions.
- Consider security, licensing, and maintainability when adopting new OSS.
- Write code for human readers. Put design details and reasons in code comments when not obvious from the code.
- Keep README limited to essential user-facing usage. Edit existing ones only when usage changes. 

## Style

Apply these conventions to newly authored content unless otherwise specified.

- Write documents in English.
- Avoid positive/negative pairings (e.g., "not X but Y") unless it is truly necessary.
- Use snake\_case for file and directory names.
- Use only widely established abbreviations, e.g., app, dev, and env.
- Use straight quotes (" and ').
- In Japanese text, use full-width `，` and `．` for punctuation and insert a half-width space between ASCII words/numbers and full-width characters, unless adjacent to a full-width symbol that already provides spacing, e.g. `one，two（three）`.

### Markdown

- In Japanese prose, wrap only between paragraphs, except for Markdown-required line breaks.
- Cite sources like this: `Foo was proposed in 2021[🔗](https://example.com/about/ "accessed 2026-09-07")`.
