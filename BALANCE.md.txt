# 📊 Game Balance & Scaling Tables

This document contains the core datasets for **Titan’s Wake**. These values are intended to be used by the development team for engine integration and by the QA team for balance testing.

---

## 🛡️ 1. Player Progression (Shard Scaling)
*How the Relic Warrior evolves by collecting Titan Shards.*

| Resource | Stat Affected | Bonus per Shard | Max Cap | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Crimson Shard** | Attack Damage | +5% (Base) | None | Linear scaling for late-game power. |
| **Azure Shard** | Movement Speed | +7% (Base) | +70% (510 px/s) | Prevents player from breaking map bounds. |
| **Emerald Shard** | Max Health | +15 HP | None | Also grants an instant +15 HP heal. |
| **Prime Heart** | All Stats | +50% Total | — | Multiplies current stats; grants Infinite Ult. |

---

## 👾 2. Enemy Bestiary & Difficulty Scaling
*Base stats for minions. Enemy stats scale every 60 seconds to maintain the "Space Pressure" pillar.*

| Enemy Type | Base HP | Base Damage | Speed (px/s) | AI Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Shard-Seeker** | 20 | 5 | 400 | Steals uncollected Shards. |
| **Resonance Sentinel**| 150 | 20 | 120 | Repulsion Aura (Knockback). |
| **Void Leech** | 60 | 12 | 220 | Ranged Slow (Tether). |

> **Global Formula:** Every 60 seconds, enemies gain **+10% HP** and **+5% Damage**.

---

## 👑 3. Titan Boss Phase Thresholds
*Transition points for the final encounter at the 5-minute mark.*

| Phase | HP Threshold | Behavior | Key Challenge |
| :--- | :--- | :--- | :--- |
| **Phase 1** | 100% (5000 HP) | Stone Colossus | **Platforming:** Jump over shockwaves. |
| **Phase 2** | 70% (3500 HP) | Unchained Energy | **Agility:** Outrun the Resonance Beam. |
| **Phase 3** | 30% (1500 HP) | The Supernova | **DPS Check:** Spam Heavy Attack to finish. |

---

## 🌀 4. The Resonance Zone (Corruption)
*The expansion rate of the danger zone to fit the 5-minute timer.*

| Time Mark | Radius (Safe Zone) | Expansion Speed | Danger Level |
| :--- | :--- | :--- | :--- |
| **0:00 - 1:00** | 100% (15,128 px) | Slow | Low (Tutorial feel) |
| **1:00 - 3:00** | 60% | Medium | Moderate (Pressure starts) |
| **3:00 - 4:00** | 30% | Fast | High (Greed vs Safety kicks in) |
| **5:00** | 5% (Boss Area) | Static | Terminal (Final Boss Arena) |

---

## 📝 Developer Notes (QA Insights)
* **Boss HP:** Set to 5000 HP. If the player has ~50 Damage, it will require 100 hits. The "Infinite Ult" in Phase 3 is designed to make this feel epic.
* **Movement Speed:** Capped at +70% to ensure the player remains controllable and doesn't clip through environment colliders.