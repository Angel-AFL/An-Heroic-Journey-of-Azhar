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
  (`Input.parse_input_event`), **not** `Input.action_press`. `input_sequence`/`input_action`
  use `Input.action_press`, so they drive `Input.is_action_pressed` in `_process`/`_physics_process`
  but will **not** trigger `_unhandled_input` handlers (e.g. opening an NPC dialogue with
  `interactuar`). For those, send a real key with `input_key` (`E` = `interactuar`); use
  `input_sequence` for movement over time. `is_action_just_pressed` can be missed by ad-hoc
  eval timing.
- Verifying an interaction `Area2D`: teleporting the player by setting `global_position` does
  not reliably emit `body_entered`; walk the player into the zone with `input_sequence` instead.
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

- Autoloads (`project.godot`): `Transicion` (scene fades), `Monedero` (global coin
  total), `Mejoras` (permanent upgrades: extra max hearts), `Sonido` (SFX pool, see Audio
  below), `DialogueManager` (dialogue_manager addon), `_mcp_game_helper` (godot_ai addon).
- Every level instances `res://scenes/personaje/personaje.tscn` as a node named exactly
  `Personaje`. `scripts/transicion.gd` repositions the node found by that literal name, and
  `scripts/zona_transicion.gd` triggers on group `personaje` — preserve both when editing levels.
- Scene transitions: `Area2D` with `scripts/zona_transicion.gd` (`escena_destino`,
  `punto_entrada`); destination markers live under `PuntosEntrada/<DesdeX>` in each level.
- Dialogue: `scripts/npc_dialogo.gd` calls `DialogueManager.show_dialogue_balloon(resource, cue)`;
  dialogue sources are `.dialogue` files under `dialogues/`.

## Dialogue / merchants

- The default balloon is `scenes/ui/dialogue_balloon.tscn` + `scripts/dialogue_balloon.gd`
  (registered in `dialogue_manager/runtime/balloon_path`). Its `ResponsesMenu` sets
  `hide_failed_responses = true`, so response options whose `[if ... /]` is false are
  **hidden** instead of shown as disabled/dark buttons. Keep that flag if you don't want
  greyed-out options.
- The balloon picks the portrait by the dialogue line's character name via the `RETRATOS`
  map in `scripts/dialogue_balloon.gd` (`"Miguel"` → `Villager/Faceset.png`), falling back to
  `RETRATO_POR_DEFECTO` (Comerciante). Add an entry there for each new speaking character; the
  portrait node is `%Faceset` (the `CharacterLabel` text already comes from the character name).
- Dialogue Manager supports `if`/`else` blocks and responses nested by tab indentation, so a
  response body can branch and offer follow-up options (see `dialogues/joel_dialogue.dialogue`).
- `scripts/comerciante.gd` (on `scenes/npcs/joel_npc.tscn`) registers the `Comerciante` state
  context: `al_maximo()`, `precio_actual()`, `puede_comprar()` and `comprar_corazon()`, backed
  by `Mejoras.corazones_extra` and the `Monedero` autoload. `joel_dialogue.dialogue` uses them:
  the single option `¿Puedes hacerme más fuerte?` states the price and offers the purchase as a
  second step when affordable.

## NPCs

- Base behavior lives in `scripts/npc_dialogo.gd` (on a `CharacterBody2D`/`Node2D`): when the
  player (group `personaje`) is inside `ZonaInteraccion` (an `Area2D` + `CollisionShape2D`,
  e.g. radius 11) it opens `@export var dialogo` (`DialogueResource`) from `cue_inicio`
  (default `start`) on `interactuar`. The scene must provide that `ZonaInteraccion` child.
- `scripts/comerciante.gd` extends it (Joel, `scenes/npcs/joel_npc.tscn`) and registers the
  `Comerciante` state context (see Dialogue / merchants above).
- `scripts/guardia.gd` extends it (Miguel, `scenes/npcs/miguel_npc.tscn`): paces vertically
  between its spawn `position` and `position.y + recorrido` at `velocidad`, playing
  `caminar_abajo`/`caminar_arriba` from its own `SpriteFrames` (underscore names — unlike the
  player's hyphenated ones), and stops while a dialogue is active (`_dialogo_activo`).
  Exports: `velocidad`, `recorrido`.
- NPCs are placed directly in the level scene (e.g. `Miguel` in `scenes/villa/villa.tscn`).

## Enemies / combat

- Generic enemy behavior lives in `scenes/enemigos/enemigo.gd` (a `CharacterBody2D`):
  pursues the `Personaje` within `radio_deteccion`, deals `dano_contacto` on touch, takes
  damage via `recibir_dano`, and `morir()` frees the node after a fade. Tune per enemy with
  `@export` (`vida_maxima`, `velocidad`, `radio_deteccion`, `dano_contacto`, `cadencia_dano`,
  `empuje`). On death it also drops `monedas_al_morir` coins (see Coins below).
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

## Coins / currency

- `scripts/monedero.gd` is the `Monedero` autoload: a global in-memory coin total that
  persists across scene changes (not saved to disk). API: `total`, signal `cambiado(total)`,
  `agregar(cantidad)`, `gastar(cantidad)`, `reiniciar()`.
- `scenes/items/moneda.tscn` (`scripts/moneda.gd`) is a pickup `Area2D` (`Sprite2D` +
  `CollisionShape2D`, `collision_layer = 0`); on `body_entered` from group `personaje` it
  calls `Monedero.agregar(valor)`, plays `res://audio/moneda.wav` via `Sonido.reproducir`
  (see Audio below) and frees itself. The drop is controlled per enemy by
  `monedas_al_morir` and `escena_moneda` in `enemigo.gd` (slime/flama drop 1, cactus 2).
- Reference the autoload from scripts via `const MonederoTipo = preload("res://scripts/monedero.gd")`
  then `get_node("/root/Monedero") as MonederoTipo`: the editor does not register a
  freshly-added autoload as a global identifier until the project reloads.
- HUD: `scenes/ui/hud.tscn` shows the count via `scripts/hud_monedas.gd` (node `Monedas`),
  subscribed to `Monedero.cambiado`. The HUD is instanced in every level (villa, bosque,
  desierto, nieve).
- Because levels reload on transition and only the total persists, enemies respawn and coins
  can be farmed.

## Audio

- `scripts/sonido.gd` is the `Sonido` autoload: a pool of 8 `AudioStreamPlayer` on the `SFX`
  bus. API: `reproducir(stream, volumen_db = 0.0)` reuses the first idle player. Because it
  is global, the sound keeps playing after the node that triggered it (e.g. a coin) frees
  itself — don't add a per-node `AudioStreamPlayer` for one-shot SFX.
- `default_bus_layout.tres` defines buses `Master` + `SFX` (project setting
  `audio/buses/default_bus_layout` points there by default). Route new SFX through `SFX` so
  effect volume stays separate from music.
- Reference the autoload the same way as `Monedero`: `const SonidoTipo = preload("res://scripts/sonido.gd")`
  then `get_node("/root/Sonido") as SonidoTipo`.
- Supported native formats: WAV (`AudioStreamWAV`, short SFX), OGG Vorbis (`AudioStreamOggVorbis`,
  music/loops), MP3 (`AudioStreamMP3`). No native FLAC/AAC.

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
