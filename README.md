# gettext-po2json

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
![GitHub all releases](https://img.shields.io/github/downloads/rgglez/gettext-po2json/total)
![GitHub issues](https://img.shields.io/github/issues/rgglez/gettext-po2json)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/rgglez/gettext-po2json)


This Perl script converts a [PO](https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html) file into a JSON JED-like file as produced by [gettext-parser](https://github.com/smhg/gettext-parser), suitable for [svelte-i18n-gettext](https://www.github.com/rgglez/svelte-i18n-gettext).

## Usage

```bash
perl po2json.pl --po messages.po --json messages.json --context app
```

- `--po` the source PO file.
- `--json` the destination JSON file.
- `--context` the default context if there's no one present. Optional.

## Dependencies

```bash
cpan install JSON::PP Locale::PO Getopt::Long File::Temp
```

- `JSON::PP`
- `Locale::PO`
- `Getopt::Long`
- `File::Temp`

## License

Copyright 2025 Rodolfo González González.

Licensed under [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) license. Read the [LICENSE](LICENSE) file.