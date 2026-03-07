{---
title = "Ouroboros Tachys: L1-Secured Partner Chains for Cardano";
tags = [ "cardano" "partner_chains" "consensus" "tachys" ];
uid = "tachys-l1-secured-partner-chains";
---}

CIP-0177 proposes Ouroboros Tachys, a faster consensus variant for Cardano
partner chains. This post explores how Tachys' public slot leader schedule
could enable L1-secured partner chains where your existing ADA delegation
helps secure multiple chains, and successful partner chains reward the ADA
holders who support them through their pools.
>>>

The recent proposal of [CIP-0177: Ouroboros Tachýs][cip-177] introduces a
faster variant of Ouroboros Praos designed for Cardano partner chains. While
the CIP focuses on the consensus protocol itself, it opens up an exciting
opportunity: **using Cardano's existing stake distribution to secure partner
chains**—creating a direct economic relationship where ADA holders, SPOs, and
partner chains all benefit together.

In this post, I'll explore how Tachys could enable truly "L1-secured" partner
chains, where your existing Cardano stake helps secure new chains, and
successful partner chains reward the ADA holders who support them.

## What is Ouroboros Tachys?

Ouroboros Tachýs (Greek for "swift" or "rapid") makes one key change to how
Cardano's Praos consensus works:

**The Change:** Replace Praos' *private* slot leader schedule with a *public*
slot leader schedule

**The Benefit:** ~4x higher block production rate, meaning:
- 4x higher transaction throughput
- Much faster transaction finality
- Target of 10x total performance improvement

**The Trade-off:** Less DDoS resistance (which matters less for smaller
networks)

### Why This Matters

Here's the simple insight: Cardano mainnet could produce blocks 4 times faster
than it currently does, but it deliberately leaves gaps between blocks for
security. These "quiet periods" help the network stay secure even with
attackers.

With a **public schedule** where everyone knows which pool produces each
block, we can eliminate these gaps:
- Every slot gets assigned to exactly one pool
- Assignment is weighted by stake (just like mainnet)
- Everyone knows the schedule in advance
- Blocks can be produced back-to-back with no gaps

For smaller networks with fewer pools, losing the DDoS protection is
acceptable—and the 4x speed boost is incredibly valuable.

## The Missing Link: Economics

As currently proposed, Tachys partner chains would work like this:

1. Launch a separate blockchain using Cardano's code
2. Find pools to run it (separate from mainnet pools)
3. Build up stake on the new chain from scratch
4. Run faster with custom parameters

**The problem?** No connection between mainnet and the partner chain. Your ADA
delegation on mainnet doesn't help secure partner chains, and successful
partner chains don't benefit mainnet ADA holders.

## A Better Way: L1-Secured Partner Chains

Here's the innovation: **What if partner chains used Cardano mainnet's stake
distribution to determine who produces blocks?**

### How It Works (In Plain English)

**Step 1: Pool Registration**

An SPO who wants to help secure a partner chain registers through a smart
contract on Cardano mainnet. They specify:
- Which partner chain they want to support
- Network connection details
- A small registration fee

**Step 2: The Indexer Watches**

A service monitors Cardano mainnet to see:
- Which pools have registered for each partner chain
- How much ADA is delegated to each registered pool
- The epoch schedule information

**Step 3: Computing the Schedule**

Using the Tachys algorithm from CIP-0177, the service computes who produces
blocks on the partner chain:
- Takes mainnet stake distribution
- Filters to only pools that registered
- Creates a deterministic schedule weighted by stake
- Each slot assigned to one pool

**Step 4: Partner Chain Runs**

Registered pools:
- Check the schedule to see when they're assigned
- Produce blocks during their slots
- Earn transaction fees from the partner chain
- Use the same infrastructure they already run

### The Flow

```
┌──────────────────────────────────────────┐
│        Cardano Mainnet (L1)              │
│                                          │
│  ADA Holder → Delegates to Pool X        │
│  Pool X → Registers for Partner Chain    │
│                                          │
│  Registry Contract tracks:               │
│  - Which pools are participating         │
│  - Registration status                   │
└────────────────┬─────────────────────────┘
                 │
                 │ Indexer Service
                 │ - Reads stake distribution
                 │ - Computes block schedule
                 │
                 ▼
┌──────────────────────────────────────────┐
│        Partner Chain (Tachys)            │
│                                          │
│  Pool X produces blocks                  │
│  Earns partner chain transaction fees    │
│  Shares fees with delegators             │
└──────────────────────────────────────────┘
```

## Who Benefits and How?

### For ADA Holders (The Delegators)

**Your delegation now secures multiple chains:**
- You delegate to a pool on mainnet (as usual)
- That pool can register to help secure partner chains
- Your delegated ADA helps determine their weight on partner chains
- Pool earns extra fees from partner chains
- Pool shares those fees with you (their delegators)

**Example:**
You delegate 10,000 ADA to "SuperPool" on mainnet. SuperPool registers for
three partner chains:
- Gaming Chain: Fast blocks for in-game transactions
- DeFi Chain: High-performance DEX and lending
- Government Chain: Record keeping for a national registry

Your 10,000 ADA delegation now helps secure all three chains, and SuperPool
earns transaction fees from all three to share with you—all without you doing
anything extra.

### For Stake Pool Operators (SPOs)

**Additional revenue without additional stake:**
- Leverage your existing mainnet delegation
- Small registration fee per partner chain
- Earn transaction fees from each chain you support
- Same infrastructure you already run
- Participate in multiple partner chains simultaneously

**The appeal:**
- Mainnet: ~5% annual rewards from protocol
- Partner chains: Transaction fees (could be significant for active chains)
- Total: Diversified income stream

### For Partner Chain Builders

**Instant security from day one:**
- No need to convince people to buy your token
- No need to convince pools to bootstrap your chain
- Leverage Cardano's billions in staked ADA immediately
- Pay pools through transaction fees
- Inherit Cardano's decentralization and security

**The cost:**
- Small rewards to attract pools to register
- Transaction fees go to securing the chain
- But no cold start problem, no token needed for security

### For Cardano Ecosystem

**Direct economic alignment:**
- Partner chain success = More fees for SPOs
- More fees for SPOs = Better rewards for ADA holders
- Better rewards = More ADA staked on mainnet
- More staked ADA = More secure partner chains

**Network effects:**
- Every new partner chain increases value of ADA delegation
- Successful applications can run on partner chains without congesting mainnet
- Cardano becomes a family of chains, not just one chain

## Following the Money: How Rewards Flow

Let's trace a concrete example:

**Gaming Chain launches:**

1. **Setup:** Gaming Chain pays registration incentives to attract 50 SPOs to
   register
2. **Operation:** Gaming Chain processes 100 TPS of in-game transactions with
   small fees
3. **Revenue:** Transaction fees accumulate in Gaming Chain treasury
4. **Distribution:** Every epoch, fees are distributed to registered SPOs
   weighted by their mainnet stake
5. **Sharing:** SPOs share these partner chain rewards with their delegators
   (just like mainnet rewards)

**Your view as a delegator:**

```
Mainnet Rewards (Epoch 500):
  Protocol rewards: 50 ADA

Partner Chain Rewards (Epoch 500):
  Gaming Chain fees: 8 ADA
  DeFi Chain fees: 12 ADA

Total: 70 ADA (40% boost from partner chains!)
```

**The pool's incentive:**
- More mainnet delegation = More weight on partner chains
- More weight = More partner chain fees
- More total rewards = Attracts more delegators
- More delegators = Even more weight

This creates a powerful flywheel where everyone benefits from partner chain
success.

## Governance and Treasury: Funding the Ecosystem

Here's where it gets really interesting: **Cardano's governance can directly
fund partner chain development**.

### Multi-Asset Treasury

Cardano's treasury will support multiple asset types, not just ADA. This
means:

**Partner chains can "donate" to Cardano treasury:**
- Partner chain issues native token
- Donates portion to Cardano treasury (via bridge)
- Creates multi-asset treasury holdings

**Example:**
- Gaming Chain launches with GAME token
- 10% of GAME supply donated to Cardano treasury
- Gaming Chain succeeds, GAME appreciates
- Cardano treasury holds valuable GAME tokens

### Governance Funding Flow

Now the real magic happens with Cardano governance:

**Funding Partner Chain Projects:**

1. Developer wants to build on Gaming Chain
2. Submits proposal to Cardano governance
3. Requests funding in GAME tokens (not ADA!)
4. ADA holders vote on proposal
5. If approved, developer receives GAME from treasury
6. Builds application on Gaming Chain

**Why this matters:**

- **For Cardano:** Treasury diversifies beyond just ADA
- **For partner chains:** Direct access to Cardano's governance and community
- **For developers:** Can get funded by Cardano governance to build on partner
  chains
- **For ADA holders:** Governance voting power extends to entire ecosystem

### The Donation Mechanism

The mechanics are straightforward:

**Partner Chain Side:**
- Partner chain has treasury smart contract
- Accumulates native tokens through initial allocation
- Bridges tokens to Cardano mainnet
- Deposits to Cardano treasury via donation transaction

**Cardano Side:**
- Treasury contract accepts multi-asset donations
- Governance proposals can request specific assets
- ADA holders vote to allocate treasury assets
- Creates closed-loop ecosystem funding

### Example Scenario

**Year 1: Partner Chain Launch**
- DeFi Chain launches with DEFI token
- Donates 100M DEFI tokens to Cardano treasury
- DEFI trades at $0.10 = $10M donation

**Year 2: Ecosystem Development**
- Developer proposes building advanced DEX on DeFi Chain
- Requests 5M DEFI ($500k at current price) from treasury
- Cardano governance votes, proposal passes
- Developer builds successful DEX

**Year 3: Value Appreciation**
- DEX drives adoption, DEFI appreciates to $0.50
- Remaining 95M DEFI in treasury now worth $47.5M
- New proposals can request DEFI funding
- Cardano treasury has grown through partner chain success

**The virtuous cycle:**
- Partner chains donate tokens to gain legitimacy and funding
- Cardano governance funds development on partner chains
- Successful development increases partner chain value
- Increased value makes treasury holdings more valuable
- Enables more funding for more development

## Real-World Use Cases

### High-Frequency Trading DeFi

**The Need:** DEX needs sub-second finality for active trading

**The Solution:**
- Partner chain with 1-second blocks
- Registered pools from mainnet secure it
- Traders pay transaction fees in TRADE token
- Fees flow to registered SPOs
- SPOs share with their mainnet delegators
- TRADE tokens donated to Cardano treasury
- Governance funds DeFi tool development using TRADE

### Government Records

**The Need:** National land registry needs blockchain but must comply with
regulations

**The Solution:**
- Government launches permitted partner chain
- Selects specific Cardano SPOs to register (trust requirements)
- Those SPOs' mainnet stake determines schedule
- Registration fees paid in GOV token
- GOV donated to Cardano treasury
- Governance funds GovTech development using GOV tokens

### Gaming Ecosystem

**The Need:** Game needs high TPS with ultra-low fees

**The Solution:**
- Gaming partner chain with aggressive parameters
- Open registration for any mainnet SPO
- In-game fees paid in GAME token
- SPOs earn GAME, share with delegators
- GAME treasury donation creates funding pool
- Governance funds game development and tools using GAME

## The Incentive Flywheel

This model creates compounding network effects:

```
More Partner Chains
      ↓
More Transaction Fees for SPOs
      ↓
Better Returns for ADA Delegators
      ↓
More ADA Staked on Mainnet
      ↓
More Secure Partner Chains
      ↓
More Successful Applications
      ↓
More Treasury Donations
      ↓
More Development Funding
      ↓
More Partner Chains (loop)
```

**Every participant is aligned:**
- ADA holders want partner chains to succeed (more rewards)
- SPOs want partner chains to succeed (more fees)
- Partner chains want strong SPO participation (security)
- Developers want treasury funding (build on partner chains)
- Cardano governance wants treasury growth (more funding power)

## Implementation Path

### Phase 1: Core Protocol (2025)
- Implement Tachys consensus in Cardano node
- Make node configurable for different consensus modes
- Launch basic partner chain testnet

### Phase 2: L1 Integration (2025-2026)
- Build registry smart contract on mainnet
- Create indexer service for stake tracking
- Enable mainnet pools to register for testnet
- Test schedule computation and block production

### Phase 3: Economics (2026)
- Implement fee distribution to registered pools
- Build bridge for partner chain → mainnet value transfer
- Enable treasury donation mechanism
- Test multi-asset governance proposals

### Phase 4: Production (2026+)
- Launch first L1-secured partner chain
- Onboard SPOs and validate economics
- Support governance funding for partner chain projects
- Scale to multiple partner chains

## Open Questions

### How to distribute partner chain rewards fairly?

**Options:**
- Proportional to mainnet stake (larger pools get more)
- Flat per registered pool (more egalitarian)
- Hybrid: Base rate + stake bonus
- Let each partner chain decide

### What if a pool misbehaves on a partner chain?

**Detection is easy** (public schedule makes wrong blocks obvious), but
enforcement is hard:
- Slash registration deposit? (May not be enough)
- Reputation/blacklist system? (No direct penalty)
- Let partner chains handle it?

### Can pools participate in multiple partner chains?

**Likely yes, but considerations:**
- Infrastructure requirements (bandwidth, storage, CPU)
- Timing conflicts (same slot, different chains?)
- Dilution of effort and quality

### How to prevent hostile partner chains?

**Registry contract could have requirements:**
- Minimum registration incentives
- Security audit proof
- Community governance approval
- Reputation requirements for pools

## Comparison with Alternatives

### vs. Traditional L2s (Rollups)

**L1-Secured Partner Chains:**
- ✓ Full smart contract capability
- ✓ Lower latency (no batching)
- ✓ Direct economic benefit to ADA holders
- ✗ Requires bridge for settlement
- ✗ Less trustless than ZK rollups

### vs. Independent Sidechains

**L1-Secured Partner Chains:**
- ✓ Instant security from mainnet stake
- ✓ No token needed for security
- ✓ Economic alignment with Cardano
- ✗ Must attract mainnet pools to register
- ✗ Dependent on mainnet for schedule

### vs. Other L1 Blockchains

**L1-Secured Partner Chains:**
- ✓ Immediate bootstrap (no cold start)
- ✓ Shared security model
- ✓ Cardano tooling compatibility
- ✗ Less sovereignty
- ✗ Must coordinate with mainnet epochs

## Why This Matters for Cardano

This isn't just about scaling—it's about **alignment**.

**Today:** Partner chains are satellites that might drift away
- Independent security
- Independent economics
- No direct benefit to ADA holders

**With L1-secured model:** Partner chains are family members
- Shared security through mainnet stake
- Shared economics through fee sharing
- Direct benefit to every ADA holder who delegates
- Treasury growth through donations
- Governance power extending to entire ecosystem

**The result:**
- More valuable to hold and stake ADA
- More revenue opportunities for pools
- More options for developers
- More use cases without mainnet congestion
- Stronger network effects across the entire family of chains

## Conclusion

Ouroboros Tachys enables something remarkable: a family of fast, customizable
blockchains secured by Cardano's mainnet stake, with direct economic benefits
flowing to everyone who participates.

**For you as an ADA holder:**
- Your delegation helps secure multiple chains
- You earn rewards from all of them
- No extra work, just better returns

**For the Cardano ecosystem:**
- Partner chains extend capabilities without mainnet congestion
- Treasury grows through partner chain donations
- Governance can fund cross-chain development
- Success compounds through network effects

**The vision:**
"Cardano on Cardano" isn't just code reuse—it's true economic and security
alignment. Partner chains become extensions of Cardano, not competitors. Every
successful application on a partner chain enriches the entire ecosystem.

This is how Cardano scales: not by making mainnet do everything, but by
creating a family of specialized chains that all benefit from—and contribute
to—the security and success of Cardano's L1.

---

## Resources

- [CIP-0177: Ouroboros Tachýs][cip-177]
- [CIP-0133: BLS12-381 Multi-Scalar Multiplication][cip-133]
- [CPS-0017: Settlement Speed][cps-017]
- [CPS-0018: Greater Transaction Throughput][cps-018]

[cip-177]: https://github.com/cardano-foundation/CIPs/pull/1149
[cip-133]: https://github.com/cardano-foundation/CIPs/tree/master/CIP-0133
[cps-017]: https://github.com/cardano-foundation/CIPs/tree/master/CPS-0017
[cps-018]: https://github.com/cardano-foundation/CIPs/tree/master/CPS-0018

## Acknowledgements

Thanks to Duncan Coutts and Philipp Kant for CIP-0177, and to the Cardano
community for ongoing discussions about scaling and partner chain
architecture.

*Questions or feedback? Find me on [X/Twitter](https://twitter.com/disassembler)
or the CIP-0177 discussion thread.*
