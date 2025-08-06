# mdbx

[libmdbx](https://libmdbx.dqdkfa.ru/) interface for Crystal

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  mdbx:
    github: mentalblood0/mdbx
```

2. Run `shards install`

## Usage

See [spec/mdbx_spec.cr](./spec/mdbx_spec.cr)

## Testing

Basic tests:

```bash
crystal spec --error-trace --tag '~leakage' --order random --fail-fast
rm /tmp/mdbx /tmp/mdbx-lck
```

Leakage test:

```bash
crystal spec --error-trace --tag 'leakage' --release
rm /tmp/mdbx /tmp/mdbx-lck
```

Leakage test just runs CRUD operations indefinitely long until program is interrupted, so any stable memory leaks in CRUD interface implementation should lead to RAM lack and program termination by OS
