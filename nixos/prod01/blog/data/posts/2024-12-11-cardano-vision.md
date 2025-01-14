{---
title = "Cardano 2025 Vision and Roadmap";
tags = [ "content" ];
uid = "cardano-2025-vision-and-roadmap";
---}

# Vision

Note: This is an initial draft the vision presented by Sam Leathers and is a work in progress. Final vision will be distributed through Intersect channels.

Cardano envisions a future where it serves as a robust and scalable foundation for a decentralized global economy. This will be achieved by significantly
enhancing L1 performance through the Leios protocol and optimizing the current codebase, while simultaneously expanding the capabilities of L2 solutions
like Hydra and Midgard. By improving developer experience through enhanced APIs, robust tooling, and a focus on decentralization,
Cardano aims to empower developers to build innovative and impactful applications. Furthermore, the expansion of programmable assets,
including advanced features like account abstraction and regulated stablecoins, will unlock new possibilities for decentralized finance and beyond.
This vision emphasizes a strong commitment to research, community collaboration, and the long-term sustainability of the Cardano ecosystem.

The general themes of the community's short term vision, as analyzed through the community roadmap survey, is focused on increasing
scalability, increasing interoperability and increasing usability.

# Roadmap

## Scaling the L1 Engine

L1 Performance is key for being ready for incoming adoption. This allows Cardano to become the hub for all blockchains to communicate. This
can be done both through optimization of current code base, as well as exploring changes in the architecture to allow more parellelization.

### Leios

Leios brings the scalability to the L1 on Cardano. This is done by parellelizing block creation with input blocks, that are then
endorsed by SPOs using endorsement blocks, that then the result of all those transactions in all those blocks are reflected in the ledger
of the ranking blocks.

#### Formal Methods

Translating the Paper to a formal spec provides a blueprint for how Cardano node implementations can validate their implementation to
match the spec.

#### Leios Simulations

Prototyping and Simulation of Leios validates that the Leios paper works in practice and identifies initial parameter values to target
in the final implementation. The io-sim framework allows us to simulate real-world networks and using the delta-q framework, we can identify
how nodes will behave as these blocks traverse a network graph that simulates the topology of Internet routing.

#### Engineering Preparation for Leios

As Leios is prototyped, areas could be identified that refactoring the current node might make it simpler to adopt later spending time up front
this year, rather than following a waterfall model of paper -> prototype -> implementation. Examples might be in expanding the ability of the network
layer and mempool to prepare for multiple block types.

### Optimizations in current code base

By optimizing the current code base, we can increase performance prior to Leios implementation being completed. We can measure the performance
increases of refactoring and addressing tech debt through the benchmarking framework. As the node becomes more performant, we allow the parameter
committee larger room to react to parameter change requests without degrading the performance of Cardano.

### Anti-grinding

By introducing a small bit of work required to forge a block, settlement speed can be increased as well as provide more security against future
CPU-based grinding attacks where network leaders manipulate block additions to improve their chances of re-election.


### LSM - Reduce Memory of the Node

Making sure cardano will continue to be approachable and reduce costs for dApp developers and block producers to increase returns to Ada Holders.
By integrating LSM into the node, we can reduce the total memory required to run the node without sacrificing performance. Initially the
integration is focusing on the UTxO set, which is a large portion of the ledger; however, other areas can be identified t further reduce
the RAM requirements.

## Incoming Liquidity

Bringing liquidity from existing ecosystems is valuable because it allows a larger user base to participate on Cardano.

### Bitcoin DeFi

Bringing liquidity from Bitcoin into Cardano expands the user base significantly. Using Zero Knowledge Proofs we can make Cardano
the DeFi layer of Bitcoin in a decentralized manner where a bridge doesn't need to be trusted by the users to act honestly. By
doing this as an open standard, anyone can create their own applications that allow transfer of value from Bitcoin to Cardano.

### Babel Fees (Validation Zones)

As we start to interoperate with other chains and L2s, we need to have a way for users to create transactions on the L1 without currently holding
ADA. Validation Zones allow partial transactions to be accepted and combined from multiple parties where a marketplace can arbitrage the value
in ADA for a user to get ADA to spend the transaction and have the minimum ADA required without having to purchase ADA first through an exchange.
The Product Committee strongly recommends funding adding this functionality to core as well as funding the building of a decentralized open
marketplace for users to interact.

### Zero Knowledge Applications and Scaling

The EUTxO model is perfect for zero-knowledge proofs (ZKPs), as they allow you to perform complex, high-intensity computation off-chain and
produce a proof of that computation verifiable on-chain. For instance, you could execute a smart contract off-chain and then provide a proof
that the smart contract was executed in a given state. This proof can be verified on the network. Importantly, to utilize this method of
zero-knowledge scaling, to construct the proof you need to know in advance the state against which you are executing the computation.
Due to EUTxO’s transaction predictability, this is trivial, since the only input required to evaluate the computation is the transaction itself.

In contrast, because transactions on account-based models operate on the global state, while constructing transactions you do not have knowledge
of the relevant state required to construct the proof. Also, you don’t know what the state of the smart contract will look like by the time the
transaction is processed because other transactions that are processed in the block can impact that state. So for instance, if you create a proof
that a smart contract was executed on a given state, when you submit that proof to the network, the proof will likely be invalidated since by the
time your transaction is processed the state (that you used to construct the ZKP) would have already changed due to other transactions.

### Mithril Decentralization

Mithril can provide an easier bootstrap for the Cardano node and could potentially be used to provide trusted genesis ledger peer snapshots. There are
two current problems with mithril: centralization and participation. Both can be improved by bringing mithril closer to the node, and using the
nodes existing networking layer to provide communication channels for aggregating signatures.

## L2 - Expanding the functionality

As more transaction volume comes into Cardano, we need to utilize L2s to keep the traffic on the L1 down. Below are list of vision items the Product
Committee suggests to make move traffic from the L1 to the L2.

### Cardano as a Partner Chain

Specialized token that performs same role as Ada on Cardano

Cardano Node was developed from Shelley with the intention of having pluggable consensus mechanisms. With minimal effort, a weight based
BFT consensus mechanism similar to how substrate partner chains SDK works could be developed and allow builders to run their own independent
chains, and utilize the existing security of the L1 by having SPOs register to participate in running nodes on these partner chains. The beauty
of Cardano on Cardano is any existing applications running on Cardano, can move to a different cardano chain with different parameters, like
larger tx/block sizes, more/less frequent blocks without having to change any of their tooling.

Another advantage to the community of making Cardano a first class partner chain is newer implementations of the node can target market fit on a
partner chain prior to having complete compatibility for mainnet. Because a partner chain has it's own ledger, and is based on a simplified weighted
BFT consensus protocol, the complexity of creating a production node is much lower than being compliant with the existing node on mainnet.

### Partner Chain Bridges

One missing piece is to provide bridges for transfer of value from one chain to another. The Product Committee strongly advises
prioritizing creating a decentralized open standard for how native assets are moved from one chain to another.

This will require a CIP and some discovery activity

### Hydra

Hydra allows the creation of an L2 that initializes a head from some starting values, then closes the head with the results of what happened in the
transactions in hydra, without keeping any of the state in-between on the L1 if all the heads are in consensus of what happened.

#### Hydra Doom and other prototypes

Hydra doom was a major success in marketing Cardano and it's potential growth using L2's. This was done with a near zero marketing budget.
In 2024, hydra proved it could handle 1 million TPS through horizontal scaling of independent hydra heads. Identifying more use cases that
can help Cardano is something the Product Committee strongly endorses.

#### Governance Action Discussion Tool

One potential use case for hydra that has been suggested is a governance proposal discussion/voting tool. This is too much information
to be done on the L1, but by pushing it to the L2, the discussions can happen on hydra, be archived, and the results published back to
the main chain.

### Midgard

 Midgard introduces true trustless scalability to Cardano through the first optimistic rollup framework that fully inherits the security of
 Cardano’s Layer 1. By leveraging the EUTxO model, Midgard achieves permissionless operation, efficient fraud proofs, and censorship resistance,
 without relying on centralized sequencers or custodial multisigs. This unique design allows for scalable, low-cost transactions while maintaining
 Cardano's robust security and decentralization. By aggregating off-chain transactions into compact representations on-chain, Midgard ensures that
 increased activity directly benefits Cardano’s L1, enabling a sustainable and innovative ecosystem for decentralized applications.

### Finality (Peras)

Finality is important for the L2 to be able to transfer value from the L1 to the L2 or another L1 partner chain. Peras ensures finality with
Ouroboros Praos by having block producers communicate off-chain to identify how much stake has adopted a particular block, rolling back to
Praos rules if enough stake doesn't participate in a voting round. A design study has been contracted to be delivered in Q1 that will estimate
the impact of integration. If the impact is low, it may be possible to develop Peras and include it with the next Era; however, based on
community sentiment in the survey, it's identified that Leios is a much higher priority than Peras, and it's impact on Leios should be
ascertained before starting development.

## Developer/User Experience

Developer and User experience is critical to the further adoption of Cardano. Through consultation with the community, we've identified
the following initiatives that the Product Committee recommends focusing on improving the developer and user experience.

### Cardano API generating libraries in other languages

The glue binding the applications together (CBOR/Serialization)

Providing a simple way to generate CBOR transmitted over the wire in any language allows builders to build in any language without
the overhead of having to write a low-level CBOR library that needs to be constantly maintained. Using meta programming techniques,
these libraries should be able to be auto-generated from the haskell code in many languages including C, rust, go, wasm, etc...

It's recommended to work closely with the Lucid Evolution team to identify what needs their users have as that has been a very successful
library many in the community are using that works in nodejs ecosystems.

### Cardano API RPC for existing queries and transaction building

By expanding the existing cardano-submit-api to support queries and transaction building, builders can run a node with a tightly integrated
service that provides the queries they need to build any transaction with limited overhead. The goal is anything that can be done via the
existing CLI could also be done through an RPC endpoint as well.

### Custom Chain Indexers

Chain indexers for custom use cases are simple problem to solve that would solve many use cases, including supporting the Partner Chains
SDK, either in the existing substrate, or the proposed Cardano on Cardano implementations. With LSM moving information on disk and out of
memory, a light-weight chain indexer could be ran on minimal hardware requirements. It's vital any chain indexing solution be able to
monitor ledger events in addition to UTxO changes so accurate stake pool distributions can be snapshotted for any epoch for the partner chains
framework.

### Data API Service Decentralization

Data API Services are crucial to user development of applications on the blockchain; however being centralized results in a "gate keeper".
By decentralizing API services such as blockfrost, we can utilize our existing SPOs to volunteer to help provide services to end users and
be compensated for that service.

### Local Node Services

Too many users are trusting web browsers with their private keys, and trusting 3rd party services to give them accurate information about the
blockchain. With Cardano, we started with one wallet, Daedalus, that was a full node wallet and required no trust on the users part. We should
strive to get back to this point by creating standard ways for any wallet to interact with a full node. A standard could be created through
the CIP process for indexers to provide data from a full node wallet to a variety of wallets.

### Language Independent Tracing/Logging/Monitoring Standard

By showing how Cardano Tracer can be used in languages other than Haskell, we can create a unified way for future nodes to emit the same
traces, and by extension benchmark them in comparison to the Haskell Implementation. This also allows the nodes to be monitored using the
existing community tooling if they emit the same traces used to generate the prometheus/EKG metrics. This also can be used for collecting performance
metrics for software outside of the node, such as other dApp implementations.

### Programmable Assets

#### Account Abstraction Frameworks

By developing an account abstraction framework using Plutus to allow a new class of Programmable Assets on Cardano, use cases that cannot be satisfied
by native assets can be achieved on Cardano.

#### UTxO intent signatures

Currently decentralized exchanges require you to lock your funds in a contract they control to allow for swaps. A different way to achieve the same goal
is to have a way to signify intent allowing a swap to happen if certain conditions are met, but still retaining ownership of the tokens within a smart
contract account in the users wallet. The way this would work is by providing a signed message of intent for permission to spend the UTxO in the wallet
and perform a swap. When a batcher finds a match for your intent, it then uses that message to spend your UTxO.

#### Soul bound tokens

Using the account abstraction framework above, a token can be created that can never be transferred from the original holder. This can be used for decentralized
identity assets as an example.

#### Royalty tokens

A policy can be enforced on a programmable token that requires the original creator to be compensated any time the token is moved.

#### Regulated Stable Coins

A policy can require proof that a user is not on a blacklist before transferring a regulated stable coin. This can allow more regulated stable coins such
as the Wyoming Stable Coin to be able to launch on the Cardano ecosystem.

