# ASCEND: Infinite Stat Progression Concept

## Core Philosophy
To ensure the game "never ends" while maintaining a sense of meaningful progress, we decouple **Base Power** from **Visual Tiers**. The user should always see a bar filling up (short-term dopamine), but the long-term goal is "Ascension" (Prestige).

---

## 1. The Four Pillars (S.I.A.D.)
We clearly define the 4 main stats. Every task, habit, or workout must be assigned one primary attribute.

| Attribute | Represents | Associated Activities |
| :--- | :--- | :--- |
| **STRENGTH (STR)** | Power, Force, Intensity | Weightlifting, Calisthenics, HIIT, Protein intake |
| **AGILITY (AGI)** | Speed, Flow, Mobility | Running, Cycling, Yoga, Stretching, Steps count |
| **INTELLIGENCE (INT)** | Mind, Knowledge, Skill | Reading, Studying, Coding, Learning languages |
| **DISCIPLINE (DIS)** | Willpower, Routine, Stoicism | Cold showers, Meditation, Making bed, Hydration, Fasting |

---

## 2. The "Infinite" Math Model

### A. Leveling Curve (Soft Cap)
We use an exponential curve for levels 1-100. It gets harder to level up, but never impossible.
Formula: `XP_Required = 100 * (Level ^ 1.8)`

### B. The Tier System (The "No Ending" Mechanic)
What happens at Level 100? **Calculated Ascension.**
Instead of stopping, the stat "Evolves".

*   **Iron Tier** (Lv 1-100)
    *   *Reach Lv 100 -> Ascend to Bronze I*
*   **Bronze Tier** (Lv 1-100)
    *   *Reach Lv 100 -> Ascend to Silver I*
*   **...Gold, Platinum, Diamond, Ascended, Godlike**

**Why this works:**
1.  **Visual Reset**: Being Level 99 takes forever to reach Level 100. But once you Ascend, you are Level 1 (Bronze) again. You get fast level-ups again (dopamine hit), but your "Total Power" is higher.
2.  **Permanent Badges**: Tiers grant permanent badges/auras to the UI.

### C. "Total Power" Calculation
To compare players or show a total "Score":
`Total Score = (Tier_Multiplier * 1000) + (Current_Level * 10)`

---

## 3. The Visual "Spider" Graph (Radar Chart)
A static graph is boring. We make it **relative**.

### Visual Logic
The graph does not show absolute values from 0 to Infinity (which would mean the graph becomes a tiny dot as you scale).
Instead, the Graph scales to your **Highest Stat**.

*   **Scenario**:
    *   STR: Level 50
    *   INT: Level 25
*   **Graph Appearance**:
    *   STR vertex touches the max edge (100%).
    *   INT vertex is at 50% radius.
*   **Psychology**: This creates a "Spiky" uneven shape. The human brain craves symmetry. The user will naturally want to train INT to "round out" the graph.

---

## 4. Implementation Data Structure

```json
{
  "stats": {
    "strength": { "level": 12, "xp": 450, "xpReq": 800, "tier": 0 },
    "agility": { "level": 5, "xp": 100, "xpReq": 300, "tier": 0 },
    "intelligence": { "level": 22, "xp": 1200, "xpReq": 2500, "tier": 1 }, 
    "discipline": { "level": 45, "xp": 3000, "xpReq": 5000, "tier": 0 }
  }
}
```

## 5. Summary of Improvements
1.  **Infinite Scaling**: Tiers allow infinite growth without breaking numbers.
2.  **Self-Balancing**: Relative Graph visuals force users to train their weakest links.
3.  **Clear Categorization**: Every habit falls into one bucket.
