# Taxi Rank Fare Escrow

A Solidity smart contract that holds a commuter's taxi fare in escrow and only
releases it to the driver once both the commuter and the driver confirm the
trip is complete. Built as part of the Africa's Blockchain Club (ABC) prep
track, using Cyfrin Updraft's Blockchain Basics and Solidity courses.

## The problem

At a taxi rank, there's no neutral record of whether a fare was actually paid,
or whether a trip was completed as agreed. Disputes come down to one person's
word against another's. This contract makes the fare, the trip status, and
the release of funds all visible and verifiable on-chain, instead of relying
on trust alone.

## How it works (in plain terms)

1. A commuter starts a trip by depositing the fare into the contract and
   naming the driver's wallet address. The funds are locked in the contract,
   not sent to anyone yet.
2. Once the trip is done, the commuter and the driver each confirm it
   separately.
3. When both sides have confirmed, the contract releases the fare to the
   driver automatically.
4. If something goes wrong, the trip is marked as disputed rather than
   letting funds move — this project keeps dispute *resolution* out of scope
   for now and focuses on getting the core escrow flow right.

## Design decisions

- **Two-sided confirmation** rather than a single "trip complete" flag, so
  neither party can unilaterally release or withhold funds.
- **Funds locked in the contract itself** (not a third-party wallet), so the
  balance held for any trip is publicly checkable at any time.
- **Minimal state machine** (`Created → Completed` or `Created → Disputed`)
  to keep the first working version explainable end-to-end, with room to
  add richer dispute handling later.

## Project status

This is being built in small daily iterations while learning Solidity, not
written all at once. See commit history for the actual build order.

- [x] Day 1 — repo scaffold, trip creation + fare deposit
- [x] Day 2 — confirmation logic + automatic release on double confirmation
- [ ] Day 3 — dispute state
- [ ] Day 4 — basic tests
- [ ] Day 5 — testnet deployment, polish

## Tech

- Solidity
- Tested/deployed via [Ethereum Toolset](https://www.ethereumtoolset.com/) (testnet only)

## Author

Anele Zinhle Dhludhla — WeThinkCode_