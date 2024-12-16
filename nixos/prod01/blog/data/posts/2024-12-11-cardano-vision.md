{---
title = "Cardano 2025 Vision";
tags = [ "content" ];
uid = "cardano-2025-vision";
---}

# Summary

Note: This is an initial draft the vision. Final vision will be distributed through Intersect channels.

The vision below has been identifed by the Product Committee as a short term vision to measure the priorities for funding development in 2025
for the Cardano ecosystem. As part of the Product Committees mandate, a wider vision for 2030 will be prepared in 2025 bringing in as many
community voices as is physically possible. This vision is primarily being used as rubric for the TSC/OSC/Product Committees to identify
what proposals should go forward for tendering.

# L1 Performance and Resource Usage

L1 Performance is key for being ready for incoming adoption. This allows Cardano to become the hub for all blockchains to communicate. This
can be done both through optimization of current code base, as well as exploring changes in the architecture to allow more parellelization.

## LSM - Reduce Memory of the Node

By integrating LSM into the node, we can reduce the total memory required to run the node without sacrificing performance. Initially the
integration is focusing on the UTxO set, which is a large portion of the ledger; however, other areas can be identified t further reduce
the RAM requirements.

## Optimizations in current code base

By optimizing the current code base, we can increase performance prior to Leios implementation being completed. We can measure the performance
increases of refactoring and addressing tech debt through the benchmarking framework. As the node becomes more performant, we allow the parameter
committee larger room to react to parameter change requests without degrading the performance of Cardano.

## Leios

Leios brings the scalability to the L1 on Cardano. This is done by parellelizing block creation with input blocks, that are then
endorsed by SPOs using endorsement blocks, that then the result of all those transactions in all those blocks are reflected in the ledger
of the ranking blocks.

### Formal Methods

Translating the Paper to a formal spec provides a blueprint for how Cardano node implementations can validate their implementation to
match the spec.

### Leios Simulations

Prototyping and Simulation of Leios validates that the Leios paper works in practice and identifies initial parameter values to target
in the final implementation. The io-sim framework allows us to simulate real-world networks and using the delta-q framework, we can identify
how nodes will behave as these blocks traverse a network graph that simulates the topology of Internet routing.

### Engineering Preparation for Leios

As Leios is prototyped, areas could be identified that refactoring the current node might make it simpler to adopt later spending time up front
this year, rather than following a waterfall model of paper -> prototype -> implementation. Examples might be in expanding the ability of the network
layer and mempool to prepare for multiple block types.

# Incoming Liquidity

Bringing liquidity from existing ecosystems is valuable because it allows a larger user base to participate on Cardano.

## Bitcoin DeFi

Bringing liquidity from Bitcoin into Cardano expands the user base significantly. Using Zero Knowledge Proofs we can make Cardano
the DeFi layer of Bitcoin in a decentralized manner where a bridge doesn't need to be trusted by the users to act honestly. By
doing this as an open standard, anyone can create their own applications that allow transfer of value from Bitcoin to Cardano.

## Babel Fees (Validation Zones)

As we start to interoperate with other chains and L2s, we need to have a way for users to create transactions on the L1 without currently holding
ADA. Validation Zones allow partial transactions to be accepted and combined from multiple parties where a marketplace can arbitrage the value
in ADA for a user to get ADA to spend the transaction and have the minimum ADA required without having to purchase ADA first through an exchange.
The Product Committee strongly recommends funding adding this functionality to core as well as funding the building of a decentralized open
marketplace for users to interact.

# L2 - Moving to the edges

As more transaction volume comes into Cardano, we need to utilize L2s to keep the traffic on the L1 down. Below are list of vision items the Product
Committee suggests to make move traffic from the L1 to the L2.

## Cardano as a Partner Chain

Cardano Node was developed from Shelley with the intention of having pluggable consensus mechanisms. With minimal effort, a weight based
BFT consensus mechanism similar to how substrate partner chains SDK works could be developed and allow builders to run their own independent
chains, and utilize the existing security of the L1 by having SPOs register to participate in running nodes on these partner chains. The beauty
of Cardano on Cardano is any existing applications running on Cardano, can move to a different cardano chain with different parameters, like
larger tx/block sizes, more/less frequent blocks without having to change any of their tooling.

## Partner Chain Bridges

One missing piece for moving L2 to the edges is bridges for transfer of value from one chain to another. The Product Committee strongly advises
prioritizing creating a decentralized open standard for how native assets are moved from one chain to another.

## Hydra

Hydra allows the creation of an L2 that initializes a head from some starting values, then closes the head with the results of what happened in the
transactions in hydra, without keeping any of the state in-between on the L1 if all the heads are in consensus of what happened.

### Marketing use cases (e.g. Hydra Doom and others)

Hydra doom was a major success in marketing Cardano and it's potential growth using L2's. This was done with a near zero marketing budget.
In 2024, hydra proved it could handle 1 million TPS through horizontal scaling of independent hydra heads. Identifying more use cases that
can help Cardano is something the Product Committee strongly endorses.

### Proposal Discussion Tool

One potential use case for hydra that has been suggested is a governance proposal discussion/voting tool. This is too much information
to be done on the L1, but by pushing it to the L2, the discussions can happen on hydra, be archived, and the results published back to
the main chain.

## Midgard

Midgard is an optimistic rollup solution as an L2 for Cardano. It's similar to hydra, except it provides a zero knowledge proof of what
happened on the L2 instead of relying on the trust that the heads are honest.

# Developer/User Experience

Developer and User experience is critical to the further adoption of Cardano. Through consultation with the community, we've identified
the following initiatives that the Product Committee recommends focusing on improving the developer and user experience.

## Cardano API generating libraries in other languages

Providing a simple way to generate CBOR transmitted over the wire in any language allows builders to build in any language without
the overhead of having to write a low-level CBOR library that needs to be constantly maintained. Using meta programming techniques,
these libraries should be able to be auto-generated from the haskell code in many languages including C, rust, go, wasm, etc...

It's recommended to work closely with the Lucid Evolution team to identify what needs their users have as that has been a very successful
library many in the community are using that works in nodejs ecosystems.

## Cardano API RPC for existing queries and transaction building

By expanding the existing cardano-submit-api to support queries and transaction building, builders can run a node with a tightly integrated
service that provides the queries they need to build any transaction with limited overhead. The goal is anything that can be done via the
existing CLI could also be done through an RPC endpoint as well.

## Custom Chain Indexers

Chain indexers for custom use cases are simple problem to solve that would solve many use cases, including supporting the Partner Chains
SDK, either in the existing substrate, or the proposed Cardano on Cardano implementations. With LSM moving information on disk and out of
memory, a light-weight chain indexer could be ran on minimal hardware requirements. It's vital any chain indexing solution be able to
monitor ledger events in addition to utxo changes so accurate stake pool distributions can be snapshotted for any epoch for the partner chains
framework.

## Polyglot Tracing/Logging/Monitoring Standard

By showing how Cardano Tracer can be used in languages other than Haskell, we can create a unified way for future nodes to emit the same
traces, and by extension benchmark them in comparison to the Haskell Implementation. This also allows the nodes to be monitored using the
existing community tooling if they emit the same traces used to generate the prometheus/EKG metrics.
