# 📄 Game Design Document: Titan’s Wake

## 🎯 1. High Concept
A fast-paced arena survival game where the player, as the **Relic Warrior**, must harvest power from **Titan Shards** to evolve their weapon. All while a lethal **Resonance Zone** expands, leading to a final climatic battle against an ancient Titan that awakens after 5 minutes.

---

## 🎨 2. Visual Style & Setting

### **The Setting: The Shattered Sanctum**
* **Description:** A massive floating platform suspended in a cosmic void or high above the clouds. This ancient sanctuary was built to imprison a slumbering Titan. The arena is littered with monolithic ruins, broken magical altars, and deep fissures emitting mystical light.
* **Visual Style:** **Dark Fantasy** meets **Ancient Monumentalism**. 
    * *Phase 1 Color Palette:* Cold slate grays and dim lighting.
    * *Progression:* As the Resonance grows, the atmosphere shifts to high-tension vibrant violets or pulsating golden ambers.

### **The Boss: The Dormant Titan**
* **Identity:** A mountain-sized ancient entity anchored at the center of the arena, encased in stone and celestial chains.
* **Visual Detail:** Remains motionless until the 5-minute mark. Energy pulses through its cracks. Upon awakening, the shell shatters to reveal a core of pure radiant energy.

### **The Influence Zone (Void Resonance)**
* **Effect:** A translucent expanding dome that distorts space. Inside the dome, the world becomes monochromatic with "glitch effects," signaling the breakdown of reality.

---

## ⚔️ 3. Player Progression (Stats & Orbs)

### **The Relic Warrior**
The player is a last guardian created by an ancient order. Their physiology allows them to harness **Titan Shards**, which fuel the **Arm-Gun Transformation**—a bio-mechanical weapon that evolves visually and mechanically as it absorbs energy.

### **Shard Types & Stat Bonuses**
* 🔴 **Crimson Shard (Red):** Focuses on **Offense**. Grants **+5% Base Attack Damage**.
* 🔵 **Azure Shard (Blue):** Focuses on **Agility**. Grants **+7% Movement Speed** (Capped at +70%).
* 🟢 **Emerald Shard (Green):** Focuses on **Survivability**. Grants **+15 Max Health** and an instant minor heal.

### **The Top Orb: "The Prime Heart"**
* **Spawn:** Appears at the **4:00 mark** in a randomized, high-danger location deep within the Resonance.
* **Effects:** +50% boost to all current stats and grants **Infinite Charges** for the Heavy Attack (Ultimate).
* **Narrative Tie-in:** Collecting shards destabilizes the Titan. The Prime Heart is the final trigger that forces the Boss to awaken.

---

## 👾 4. Enemies & AI (Bestiary)

* **The Shard-Seeker:** Fast, low-HP scavengers. They ignore the player to "eat" uncollected Shards, forcing a race for resources.
* **The Resonance Sentinel:** Slow, high-HP tanks with a **Repulsion Aura** that pushes the player away. They block paths and guard Shard clusters.
* **The Void Leech:** Ranged disruptors at the edge of the safe zone. They fire tethers that **slow the player's movement**, making the expanding zone more lethal.

**Spawn Logic:**
* **Scaling:** Difficulty ramps up every 60s (+10% Health & increased spawn rate).
* **Corrupted State:** Minions inside the Resonance zone gain **+20% Attack Speed**.

---

## 👊 5. Boss Mechanics (The Titan’s Judgment)

| Phase | HP Range | Name | Key Mechanics |
| :--- | :--- | :--- | :--- |
| **Phase 1** | 100% - 70% | **Stone Colossus** | Heavy physical AoE. *Seismic Slam* (shockwaves) and *Debris Rain*. |
| **Phase 2** | 70% - 30% | **Unchained Energy** | Sheds armor. Spawns stronger minions. *Resonance Beam* (laser) and *Shard Recall* (stat drain). |
| **Phase 3** | < 30% | **The Supernova** | Smallest safe zone. *Overdrive Barrage* (rapid projectiles) and a map-wiping *Final Resonance* charge. |

---

## 🗺️ 6. Level Layout: The Arena

### **Technical Specs**
* **Shape:** Circular/Octagonal platform.
* **Radius:** ~15,128 px.
* **Center:** The Titan’s sleeping area (The Altar).

### **Environment & Props**
* **Architecture:** Broken stone pillars, ancient statues, and collapsed ruins.
* **Details:** Runic floor carvings and glowing energy cracks that mirror the Titan's state.
* **Navigation:** Players start at the center but are forced toward the edges to find Shards as the Resonance expands from the Titan outward.

### **Tilemap Design**
* Use stone debris piles and monolithic remains to create natural "bottlenecks" where **Resonance Sentinels** can trap the player.