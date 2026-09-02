# data/ — read this before assuming anything here is an input

**Only `sample-data.tar.gz` is committed. Everything else in this folder is produced
locally by `task build` and is deliberately absent from a fresh clone.**

The archive is the single source of truth. The unpacked files, the NADAC download and the
warehouse are all derived from it, so committing them would add roughly 200 MB to the
repository to store what a 60 second command reproduces.

## What is here

| Path | Origin | In the repository | Safe to delete |
|---|---|---|---|
| `sample-data.tar.gz` | **Supplied with the brief. The only true input.** | **Yes** | **No. Keep this.** |
| `landing/` | Unpacked from the archive by `task data` | No | Yes |
| `external/nadac/` | Downloaded from `data.medicaid.gov` by `task ingest` | No | Yes |
| `warehouse/` | Built by `task ingest` and `task transform` | No | Yes |

## After a clone

```bash
task build      # unpacks the archive, ingests, transforms, tests
```

That takes about 60 seconds, of which roughly 50 is downloading NADAC from CMS, so the
first run needs an internet connection. The download is cached in `external/nadac/`
afterwards, which is why repeated local runs are fast and stay stable.

## Returning to the source state

```bash
task reset
```

Deletes `landing/`, `external/` and `warehouse/`, keeping `sample-data.tar.gz`, and clears
the dlt schema cache so the next build is genuinely clean. Doing it by hand is equivalent:

```bash
rm -rf data/landing data/external data/warehouse
task build
```

## Why a rebuild can differ from the figures in the top-level README

**NADAC is republished weekly.** A build fetches whatever CMS publishes at the URL in
`.env`, currently the 2026-08-26 file, so cost and margin figures can move. Row counts and
every claim-side figure are stable across rebuilds; the cost-derived ones are stable only
against the same NADAC snapshot.
