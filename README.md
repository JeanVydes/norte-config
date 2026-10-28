# Norte Code configuration

My Norte Code configuration, kept in git: the two catalogue files it reads, plus
the settings I want on a machine that has never seen it before.

## What lives here

| File | What it is |
|---|---|
| `config.json` | Settings: approvals, retry, compaction, MCP servers, the default provider and model. |
| `providers.json` | Who serves models, and over which wire. |
| `models.json` | A flat list of models, each naming its `provider_id`. |

The two catalogue files are read from the configuration directory
(`~/.config/norte-code/`, or `$XDG_CONFIG_HOME/norte-code/`). Norte Code does not
fetch them: they are files I own, and this repository is where they are versioned.

## Install

```sh
./install.sh
```

It copies the three files into the configuration directory and backs up whatever
was there. Pass `--dry-run` to see what it would do.

## Keys are not here

The files name environment variables, never values:

```json
"environment_keys": ["RIVER_API_KEY"]
```

The keys themselves live in the shell environment — outside this tree, outside
git, never in a commit. A provider whose variables are unset is a provider whose
requests fail with a message naming the variable, which is what I want to read
rather than a key pasted into a file that gets pushed.

## The providers

| Provider | Wire | Where requests go |
|---|---|---|
| `deepseek` | OpenAI chat | `https://api.deepseek.com` |
| `exa` | OpenAI chat | `https://api.experientiallabs.ai/v1` |
| `liquid` | OpenAI chat | `https://api.liquid.ai/openai/v1` |
| `river` | OpenAI chat | `https://api.river.ai/v1` |

`api` is the full base URL: the host joins the wire's path onto it, so a base
that does not end in a slash is left intact.

## Adding a model

Append to `models.json`. Every fact is an enum, so a name that is not in the
closed set is refused where the file is read, naming the file, the line and
every value it accepts:

```json
{
  "id": "deepseek-v4-pro",
  "provider_id": "deepseek",
  "name": "DeepSeek V4 Pro",
  "limit": { "context": 1048576, "output": 393216 },
  "modalities": { "input": ["text"], "output": ["text"] },
  "supported_params": ["tools", "structured_output", "temperature"],
  "reasoning": { "supported_efforts": ["none", "low", "high", "max"] }
}
```

`id` is what the vendor expects in a request and may carry slashes —
`river/deepseek-ai/DeepSeek-V4.1-Flash` is a model of the `river` provider.
`canonical_slug` and `name` default to the id when they are left out.

A single entry cannot be verified by reading it: `norte-code models` lists what
the catalogue loaded and prints `(deprecated)` beside a model whose `status`
says so.

## Verified

Every file here was loaded by the host before it was committed:

```sh
norte-code models
```

10 models from the two files, with the limits, tools and efforts each entry
declares, and no `unknown config key` warning.
