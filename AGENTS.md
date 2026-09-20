# AGENTS.md

Godot 4.7 game (GDScript), "An Heroic Journey of Azhar". No CLI build/test/lint —
verify changes by running the game through the `godot_ai` MCP addon.

## Running / verifying

- Main scene (`project.godot` `run/main_scene`) is `res://scenes/prueba_fisicas/prueba_fisicas.tscn`,
  a physics sandbox — **not** a playable level. To test gameplay run a level instead:
  `project_run(mode="custom", scene="res://scenes/villa/villa.tscn")`.
  Levels: `scenes/{villa,bosque,desierto,nieve}/*.tscn`.
- There are no unit tests. Verify at runtime with `game_eval` (GDScript in the running
  game), `game_manage` (`get_node_info`, `input_sequence`, `input_action`), and `logs_read`.
- Simulating input: `_unhandled_input`/`_input` handlers only react to real events
  (`Input.parse_input_event`), **not** `Input.action_press`. Use `input_sequence` for
  frame-accurate action input; `is_action_just_pressed` can be missed by ad-hoc eval timing.
- The game window must be focused/advancing for eval; a parser error in eval code parks
  the game in a debugger `break` — stop the project and relaunch to recover.

## Conventions

- Everything is in Spanish: identifiers, node names, signals, input actions, comments, and
  commit messages. Follow it.
- Commits use Conventional Commits in Spanish, e.g. `feat(personaje): ...`.
- GDScript indentation is tabs; mixing tabs and spaces is a parse error (applies to
  `game_eval` code strings too).
- `.godot/` is gitignored (generated) — never edit it. EOL is normalized to LF
  (`.gitattributes`); `unique_id` attributes in `.tscn` are Godot-generated, don't hand-edit.

## Architecture

- Autoloads (`project.godot`): `Transicion` (scene fades), `DialogueManager`
  (dialogue_manager addon), `_mcp_game_helper` (godot_ai addon).
- Every level instances `res://scenes/personaje/personaje.tscn` as a node named exactly
  `Personaje`. `scripts/transicion.gd` repositions the node found by that literal name, and
  `scripts/zona_transicion.gd` triggers on group `personaje` — preserve both when editing levels.
- Scene transitions: `Area2D` with `scripts/zona_transicion.gd` (`escena_destino`,
  `punto_entrada`); destination markers live under `PuntosEntrada/<DesdeX>` in each level.
- Dialogue: `scripts/npc_dialogo.gd` calls `DialogueManager.show_dialogue_balloon(resource, cue)`;
  dialogue sources are `.dialogue` files under `dialogues/`.

## Enemies / combat

- Generic enemy behavior lives in `scenes/enemigos/enemigo.gd` (a `CharacterBody2D`):
  pursues the `Personaje` within `radio_deteccion`, deals `dano_contacto` on touch, takes
  damage via `recibir_dano`, and `morir()` frees the node after a fade. Tune per enemy with
  `@export` (`vida_maxima`, `velocidad`, `radio_deteccion`, `dano_contacto`, `cadencia_dano`,
  `empuje`).
- Enemy scenes: `slime.tscn`, `cactus.tscn`, `flama_invierno.tscn`. `slime.gd` only
  `extends "res://scenes/enemigos/enemigo.gd"`; new enemies attach `enemigo.gd` directly.
  Every enemy scene needs the child nodes the script `@onready`s: `AnimatedSprite2D` (set
  `autoplay`), `CollisionShape2D`, `ZonaContacto` (Area2D + `CollisionShape2D`),
  `SpriteMuerte` (Sprite2D, `visible = false`) and `TimerDano` (Timer, `one_shot = true`).
- Collision layers: enemies are on `collision_layer = 2` so the player's `Hitbox`
  (`collision_mask = 2`) can hit them; their `ZonaContacto` (mask 1) detects the player.
- Levels place enemies under a `Enemigos` Node2D and instance `res://scenes/ui/hud.tscn`
  (heart HUD via `scripts/hud_corazones.gd`, driven by the `Personaje.vida_cambiada` signal).
  The player exposes `recibir_dano`/`vida_maxima` and reloads the scene on death.

## Player animation

- `Personaje` uses an `AnimatedSprite2D` with `scenes/personaje/sprite_frames_personaje.tres`;
  `scenes/personaje/personaje.gd` drives it.
- Animation names are directional: `caminar-<dir>`, `idle-<dir>`, `atacar-<dir>` where `<dir>`
  is `arriba|abajo|izquierda|derecha`. `atacar-*` are single-frame poses held for
  `attack_duration`. The old non-directional `idle`/`atacar` no longer exist.
- Adding/renaming animations means editing the `.tres` (in the editor) **and** updating
  `personaje.gd`; keep them in sync.
- Custom input actions (in `project.godot`): `mover_arriba/abajo/izquierda/derecha`,
  `interactuar` (E), `atacar` (Space + left mouse).
