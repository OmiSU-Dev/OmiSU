# Command Metadata

Read this before adding or changing commands in `bin/`.

Commands in `bin/` can declare CLI metadata in comments near the top of the
file. `bin/omisu` scans the first 80 lines, and tests expect command metadata
to remain valid.

Supported metadata keys:

- `# omisu:group=...` - override the command group inferred from the filename
- `# omisu:name=...` - override the command name inferred from the filename
- `# omisu:summary=...` - short help text
- `# omisu:args=...` - usage arguments
- `# omisu:examples=...` - examples separated with ` | `
- `# omisu:alias=...` / `# omisu:aliases=...` - alternate routes
- `# omisu:hidden=true` - hide from default command listings
- `# omisu:requires-sudo=true` - mark commands that require sudo

Only use `omisu:examples` where there are args that need explaining.

Prefer explicit metadata for user-facing commands. Keep routes consistent with
the filename unless there is a deliberate alias or compatibility route.

Example:

```bash
# omisu:summary=Take a screenshot
# omisu:args=[smart|region|windows|fullscreen] [slurp|copy]
# omisu:examples=omisu screenshot | omisu capture screenshot region
```
