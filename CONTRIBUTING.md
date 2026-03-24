# Contributing to pacman-statusline

Thanks for your interest in contributing!

## Testing locally

Pipe sample JSON into the script to test without Claude Code running:

```bash
echo '{
  "model": { "display_name": "Claude Opus 4.6" },
  "context_window": {
    "context_window_size": 200000,
    "current_usage": {
      "input_tokens": 80000,
      "cache_creation_input_tokens": 10000,
      "cache_read_input_tokens": 5000
    }
  },
  "cwd": "/home/user/project",
  "transcript_path": ""
}' | bash pacline.sh
```

Adjust `input_tokens` to test different usage levels:
- **Low usage** (< 50%): yellow Pac-Man, no ghost
- **Medium** (50-69%): orange Pac-Man, ghost appears
- **High** (70-89%): red Pac-Man, ghost closing in
- **Critical** (90%+): purple Pac-Man, ghost right behind

## Code style

- Follow existing bash conventions in the script
- Keep it fast — this runs on every Claude Code message
- Test on both GNU (Linux) and BSD (macOS) date/stat if touching date logic

## Submitting changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the sample JSON above
5. Open a pull request

## JSON input reference

Claude Code sends the following fields (relevant subset):

| Field | Type | Description |
|-------|------|-------------|
| `model.display_name` | string | Current model name |
| `context_window.context_window_size` | number | Max tokens |
| `context_window.current_usage.input_tokens` | number | Input tokens used |
| `context_window.current_usage.cache_creation_input_tokens` | number | Cache creation tokens |
| `context_window.current_usage.cache_read_input_tokens` | number | Cache read tokens |
| `cwd` | string | Current working directory |
| `transcript_path` | string | Path to session transcript |
