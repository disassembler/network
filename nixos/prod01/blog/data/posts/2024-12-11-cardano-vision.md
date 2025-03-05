{---
title = "Cardano 2025 Vision and Roadmap";
tags = [ "content" ];
uid = "cardano-2025-vision-and-roadmap";
---}

# Vision

Cardano envisions a future where it serves as the robust and
scalable foundation for a decentralized global economy. This will
be achieved by significantly enhancing L1 performance through
the Leios protocol and optimizing the current codebase, while
simultaneously expanding the capabilities of L2 solutions
like Hydra and Midgard. By improving developer experience
through enhanced APIs, robust tooling, and a focus on
decentralization, Cardano aims to empower developers to
build innovative and impactful applications. Furthermore,
the expansion of programmable assets, including advanced
features like account abstraction and regulated stablecoins,
will unlock new possibilities for decentralized finance
and beyond. This vision emphasizes a strong commitment
to research, community collaboration, and the long-term
sustainability of the Cardano ecosystem.

The general themes of the community's short-term vision, as
analyzed through the community roadmap survey, focus on
increasing scalability, interoperability, and usability.

## Roadmap

### Scaling the L1 Engine

L1 performance is crucial for widespread adoption and
enabling Cardano to become a central hub for blockchain
communication. This will be achieved through a combination
of codebase optimization and architectural enhancements
to increase parallelization.

#### Leios

Leios is a groundbreaking innovation designed to
significantly enhance Cardano's scalability and
transaction throughput. It introduces a novel approach
to block creation, moving away from the traditional
sequential model.

* Leios leverages a parallel block
  creation process. Instead of a single linear chain
  of blocks, it introduces multiple "input blocks"
  that are independently created and endorsed by
  Stake Pool Operators (SPOs). These endorsements
  are then aggregated into "endorsement blocks,"
  and finally, a "ranking block" determines the final
  order and validity of transactions across all input
  blocks.
* This parallel approach has the
  potential to dramatically increase transaction
  throughput while maintaining the security and
  decentralization of the Cardano blockchain.

The roadmap for 2025 includes several key steps to achieve
in preparation for the development and implementation of Leios:

  * Develop formal specifications to guide node
    implementations and ensure correctness.
  * Conduct extensive simulations to validate
    the theoretical design of Leios in real-world
    network conditions and identify optimal parameters.
  * Refactor the Cardano node to facilitate
    the integration of Leios and ensure smooth
    and efficient operation.


#### Optimizations

* Optimize the current codebase and address technical debt to
  improve performance. This will enable more flexible parameter
  adjustments by the parameter committee, allowing for increased
  scalability without requiring a hard fork.

* Enhance Mithril's decentralization by integrating
  it more closely with the node and utilizing
  existing networking layers.

#### Anti-grinding

* Introduce measures to mitigate CPU-based grinding
  attacks, improving settlement speed and network security.

#### LSM Integration

* Reduce memory requirements for nodes by integrating
  Log-Structured Merge (LSM) trees, initially
  focusing on the UTxO set.

### Incoming Liquidity

* Increasing liquidity from other ecosystems is vital
  for expanding Cardano's user base.
    * Utilize zero-knowledge proofs to enable Cardano
      to serve as a decentralized DeFi layer for Bitcoin.
    * Babel Fees (Validation Zones) facilitate
      transactions on the L1 for users without initial
      ADA holdings through a decentralized marketplace
      that allows partial transactions to be accepted
      and combined from multiple parties, where a
      marketplace can arbitrage the value in ADA for a
      user to get ADA to spend the transaction and
      have the minimum ADA required without having
      to purchase ADA first through an exchange.

### L2 Expansion

To accommodate increasing transaction volume,
Cardano will focus on expanding the capabilities
of L2 solutions.

#### Cardano as a Partner Chain

Enable the creation of independent chains with
customizable parameters, leveraging Cardano's
security while offering greater flexibility.

#### Partner Chain Bridges

Develop a decentralized open standard for seamless
value transfer between partner chains.

#### Hydra

Explore new use cases for Hydra, such as governance
tools, and continue to enhance its scalability
and performance.

* Build upon the success of Hydra Doom by identifying
  and developing further use cases that can leverage
  Hydra's scalability to benefit the Cardano ecosystem.

* Explore the use of Hydra as a platform for decentralized
  governance discussions and voting, addressing
  the challenges of managing large volumes of
  information on the L1.

#### Midgard

Midgard is Cardano’s first optimistic rollup framework,
leveraging the EUTxO model to achieve permissionless
operation, efficient fraud proofs, and censorship
resistance, without relying on centralized sequencers
or custodial multisigs. This unique design enables
high-throughput, low-fee transactions while maintaining
Cardano's robust security and decentralization.
By aggregating off-chain transactions into compact
representations on-chain, Midgard ensures that
increased activity directly benefits Cardano’s L1,
enabling a sustainable and innovative ecosystem
for decentralized applications.

#### Finality (Peras)

Peras is an enhancement to the Ouroboros Praos protocol that aims
to accelerate transaction settlement times. In the current Praos protocol,
new blocks are added probabilistically, and the longest chain of blocks is
generally considered the valid one. Peras introduces a novel approach
by incorporating a voting mechanism among Stake Pool Operators (SPOs).

SPOs can vote to endorse specific blocks, effectively increasing their weight
within the chain. This "voting" mechanism allows for a faster consensus on the
most valid chain, leading to quicker transaction finality. Faster transaction
finality can significantly improve the user experience and enable
more efficient and timely transactions.

### Developer/User Experience

Improving developer and user experience is crucial
for driving broader adoption.

* Generate libraries in various languages to
  simplify blockchain interaction for developers.
* Expand RPC capabilities to support queries
  and transaction building, enabling seamless
  integration with node services.
* Empower developers to create custom chain
  indexers for specific needs, such as supporting
  partner chains.
* Decentralize data API services to reduce
  reliance on centralized providers and empower
  SPOs.
* Promote the use of local nodes and develop
  standards for wallet interaction with full nodes.
* Establish a unified standard for tracing,
  logging, and monitoring across different
  node implementations.

### Programmable Assets

Expanding the capabilities of programmable
  assets will unlock new possibilities for
  decentralized applications.

* Develop frameworks that enable a new class
  of programmable assets beyond native tokens.
* UTxO intent signatures enhance decentralized exchange
  interactions by allowing users to signify their intent
  to spend UTxOs under specific conditions, facilitating
  swaps while maintaining user ownership of their funds.
* Explore the use of soul-bound tokens for
  decentralized identity and other applications.
* Implement royalty mechanisms to support
  creators and incentivize innovation.
* Enable the issuance of regulated stablecoins
  on Cardano through policy-based mechanisms.

**Note:** This vision and  roadmap represents a high-level overview
and will be further refined and iterated upon based
on ongoing research, community feedback, and
technological advancements. It is based on the results of the TSC survey.
The initial author of this roadmap is Sam Leathers, Chair for
the Intersect Product Committee.

### Diverse Node Implementations

Foster the development of Cardano node
implementations in multiple programming
languages, enhancing robustness, security,
and community participation.
