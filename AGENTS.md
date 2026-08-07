# AGENTS.md — actiondemo

Godot 4.7 3D action-game exploration project. Early-stage; editor-driven workflow, no CI or automated tests.

## Project stack

- **Engine:** Godot 4.7 (GL Compatibility renderer, D3D12 on Windows)
- **Physics:** Jolt Physics (`project.godot` `[physics]`)
- **Language:** GDScript only — no C#, no GDExtension

## Project layout

| Path | Purpose |
|------|---------|
| `action.tscn` | Main scene (root: `Node3D`). Entrypoint set in `project.godot`. |
| `scripts/` | GDScript files. Currently only `boy.gd` (CharacterBody3D stub). |
| `animation/` | FBX models + animations (Mixamo imports). `.fbx.import` files contain Godot import settings. |
| `.godot/` | Editor cache. Git-ignored. Never commit. |

## Conventions

- Line endings: LF (`.gitattributes` enforces `* text=auto eol=lf`)
- `.editorconfig`: UTF-8 only, root = true
- `.gitignore` excludes `.godot/` and `/android/`
- GDScript files must have a companion `.uid` file (Godot generates these)

## Code style

- **Minimize scope.** Keep changes to the smallest set of files necessary. If a task feels too large to complete within a controlled change surface, pause and discuss splitting it with the user before proceeding.
- **Never use `:=` for variable type inference.** Write `var foo = bar()` instead of `var foo := bar()`. However, if existing code already uses `:=`, treat it as intentional — do not rewrite it to `=`.

## Running the project

Open the project in the Godot 4.7 editor and press F5, or:

```
godot --path D:\workspc\actiondemo
```

No command-line build or test commands exist yet.

## Key scene structure (`action.tscn`)

- `ActionScene` (Node3D root)
  - `CSGBox3D` — floor/platform
  - `Boy` (CharacterBody3D, script: `scripts/boy.gd`)
    - `Visual` — FBX model instance (`animation/UAL1_Standard.fbx`)
    - `CollisionShape3D` — CapsuleShape3D
  - `Camera3D`
  - `DirectionalLight3D`

## Notes

- This is an experimental/learning project.
- The GL Compatibility renderer is intentional — it maximizes platform reach at the cost of advanced rendering features.
- Jolt Physics is enabled globally; assume all physics interactions use Jolt.
