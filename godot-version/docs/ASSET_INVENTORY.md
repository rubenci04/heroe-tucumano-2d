# Asset Inventory

## Convención de estado

- `LEGACY_KEEP_REFERENCE`: conservar como fuente, manifiesto o recurso de consulta; no sustituir directamente.
- `LEGACY_REPLACE`: asset actual que tendrá equivalente V2, sin borrar ni mover el original.
- `V2_PENDING`: paquete futuro que deberá producirse dentro de `res://art_v2/`.

Este inventario clasifica **109 PNG**, **11 WAV** y **7 recursos/manifiestos de animación**. No evalúa calidad píxel por píxel.

## CHARACTER

| Elementos | Estado |
|---|---|
| `ciruja comiendo.png`, `ciruja_idle.png`, `ciruja_run0.png`–`ciruja_run5.png`, `ciruja_salto.png`–`ciruja_salto4.png`, `ciruja_cabezazo0.png`–`ciruja_cabezazo2.png`, `ciruja_disparo_naranja0.png`–`ciruja_disparo_naranja5.png`, `ciruja_disparo_cascote0.png`–`ciruja_disparo_cascote4.png`, `juntar_naranjas1.png`–`juntar_naranjas5.png`, `juntar_cascote1.png`–`juntar_cascote5.png` | `LEGACY_REPLACE` |
| `campeona empanadas.png`, `secuestro_campeona.png` | `LEGACY_REPLACE` |
| `animations/player.tres`, `animations/native_animation_manifest.json`, `animations/asset_library.tres` | `LEGACY_KEEP_REFERENCE` |
| `art_v2/characters/ciruja/`, `art_v2/characters/deca/`, `art_v2/characters/palermitano/`, `art_v2/characters/campeona/` | `V2_PENDING` |

## ENEMY

| Elementos | Estado |
|---|---|
| `hipster_run1.png`–`hipster_run3.png`, `hipster_salto.png`, `hipster_agua1.png`, `hipster_agua2.png` | `LEGACY_REPLACE` |
| `agente_run1.png`–`agente_run3.png`, `agente_salto.png`, `agente_disparo_bala1.png`, `agente_disparo_bala2.png` | `LEGACY_REPLACE` |
| `animations/hipster.tres`, `animations/agente.tres` | `LEGACY_KEEP_REFERENCE` |
| `art_v2/enemies/hipster/`, `art_v2/enemies/agente/` | `V2_PENDING` |

## BOSS

| Elementos | Estado |
|---|---|
| `grandote_run1.png`–`grandote_run3.png`, `grandote_salto.png`, `grandote_punch1.png`–`grandote_punch3.png` | `LEGACY_REPLACE` |
| `final_boss_run1.png`–`final_boss_run3.png`, `final_boss_salto1.png`, `final_boss_salto2.png`, `final_boss_punch1.png`, `final_boss_punch2.png`, `final_boss_joke1.png`, `final_boss_joke2.png`, `final_boss_cofee1.png`, `final_boss_cofee2.png` | `LEGACY_KEEP_REFERENCE` |
| `animations/grandote.tres`, `animations/boss.tres` | `LEGACY_KEEP_REFERENCE` |
| `art_v2/bosses/el_grandote/`, `art_v2/bosses/perro_familiar/`, `art_v2/bosses/luz_mala/`, `art_v2/bosses/mate_cocido/` | `V2_PENDING` |

## ENVIRONMENT

| Elementos | Estado |
|---|---|
| `acheral.png`, `fondo_arboleda.png`, `fondo_cerros.png`, `fusion_fondos.png`, `ingenio.png`, `leon_rouges.png`, `monteros.png`, `rio_seco.png`, `villa_quinteros.png`, `cañas.png`, `suelo_ruta.png`, `suelo_ruta2.png`, `puente.png` | `LEGACY_REPLACE` |
| `art_v2/environments/famailla_ruta_38/`, `art_v2/environments/ingenio/`, `art_v2/environments/cementerio_oeste/` | `V2_PENDING` |

## PROP

| Elementos | Estado |
|---|---|
| `achilata.png`, `arbol_naranjas.png`, `cartel_famailla.png`, `empanada.png`, `gruta_virgen.png`, `kiosco_coca.png`, `montaña_cascote.png`, `palmera.png`, `parada_colectivo.png`, `poste_luz.png`, `sanguche.png`, `sol.png`, `tesa.png` | `LEGACY_REPLACE` |
| `art_v2/props/naranjo/`, `art_v2/props/carteleria/`, `art_v2/props/puestos_locales/`, `art_v2/props/pickups/` | `V2_PENDING` |

## VEHICLE

| Elementos | Estado |
|---|---|
| `auto1.png`, `auto2.png`, `auto3.png`, `bus1.png`, `bus2.png`, `bus3.png`, `bus4.png`, `camion_limones.png`, `exprebus.png` | `LEGACY_REPLACE` |
| `art_v2/vehicles/autos/`, `art_v2/vehicles/colectivos/`, `art_v2/vehicles/camion_limones/` | `V2_PENDING` |

## UI

| Elementos | Estado |
|---|---|
| No hay PNG legacy dedicados exclusivamente a UI; el HUD actual es construido con controles de Godot. | `LEGACY_KEEP_REFERENCE` |
| `art_v2/ui/hud/`, `art_v2/ui/character_select/`, `art_v2/ui/dialogue/`, `art_v2/ui/result/` | `V2_PENDING` |

## EFFECT

| Elementos | Estado |
|---|---|
| `bala.png`, `botella_agua.png`, `cascote.png`, `cofee.png`, `naranja.png` | `LEGACY_REPLACE` |
| `art_v2/effects/projectiles/`, `art_v2/effects/impacts/`, `art_v2/effects/tucumanazo/`, `art_v2/effects/traffic/` | `V2_PENDING` |

## AUDIO

| Elementos | Estado |
|---|---|
| `audio/achilata.wav`, `audio/alerta.wav`, `audio/cabezazo.wav`, `audio/danio.wav`, `audio/disparo_cascote.wav`, `audio/disparo_naranja.wav`, `audio/empanada.wav`, `audio/golpe.wav`, `audio/salto.wav`, `audio/sanguche.wav`, `audio/victoria.wav` | `LEGACY_REPLACE` |
| `audio/source/audio_sfx_original.js`, `audio/source/sfx_recipes.json` | `LEGACY_KEEP_REFERENCE` |
| `art_v2/audio/`: música por estado, SFX finales y voces originales | `V2_PENDING` |
