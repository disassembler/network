{---
title = "The Cost of Vibe Coding: How an LLM Inflated a Simple Haskell Project";
tags = [ "content" ];
uid = "vibe-coding-haskell-cost";
---}

The premise of this thought experiment was simple: write a Haskell program to
read an NFC UID from a serial port and display it as an ASCII QR code. This is,
by all accounts, a **run-of-a-mill, entry-level integration task** in most
language ecosystems.

The experiment had a critical ground rule: **The human engineer, fully capable
of reading the documentation, deliberately chose not to.** I benchmarked the LLM
(Gemini) by forcing it to serve as the sole source of knowledge, using only
compiler errors and the entire documentation copied directly from Hackage.

The result? Relying on the LLM to "vibe code"—to supply solutions and fixes
based on messy inputs—turned this simple project into a frustrating, protracted
debugging session.

This exercise proves a crucial point: **the LLM failed the benchmark of
autonomy, unable to efficiently resolve specialized problems without direct
human guidance.**

## The Unseen Complexity: LLM-Induced Friction

The complexity we encountered was **artificially created by the LLM's own
missteps** and persistent inability to provide idiomatic, version-compatible
code. The struggles were centered around predictable Haskell nuances that the AI
could not reliably navigate, despite having the entire documentation as input.

### The Problem of Plausible but Wrong Code

Even on simple structural issues, the AI's solutions were often *plausible* but
*wrong* for the current context. This forced the engineer to explicitly dictate
the fix, revealing the LLM's limitations:

* **Coaching Point 1 (Type Unification):** After the LLM failed to resolve the
    serial port type error with multiple attempts (`Just ()`, `void`), the
    engineer had to explicitly instruct: **"Stop storing the result in a
    variable (`_ <- hWithSerial ...`)"** to force the compiler to bypass the
    complex type binding.
* **Coaching Point 2 (Vector Types):** The LLM provided code using the boxed
    `Data.Vector` library. The engineer had to explicitly state: **"The library
    requires unboxed vectors; change the import to `Data.Vector.Unboxed`."**
* **Coaching Point 3 (Constructor Arguments):** The LLM provided the QR code
    constructor as `QRImage size _ dataVector`. The engineer had to instruct:
    **"The constructor requires four arguments; add the missing wildcard."**

## The Unsung Hero: GHC Error Outputs

The most telling aspect of this whole experiment is that the **Haskell compiler
(GHC) itself was the better teacher and debugger than the LLM.**

Every time the AI provided an incorrect fix, the GHC compiler instantly produced
a detailed, context-rich error message that often suggested the correct path
forward. The struggle was not in getting the compiler to tell us what was wrong;
it was in getting the LLM to process that precise information and produce an
**idiomatic, efficient fix.**

## Conclusion: The Sunk Cost of Time

The time spent coaxing the AI through these predictable failures was the most
critical factor. **This entire "entry-level" integration task consumed
approximately four hours.**

Had the engineer simply allocated **thirty minutes** to synthesizing the solution
from the documentation they already possessed, the vast majority of these errors—
the version clashes, the vector types, and the stubborn serial port type error—
would have been preemptively avoided, allowing the task to be completed in less
than one hour.

The LLM failed the core benchmark of autonomy. The senior engineer isn't replaced
by the LLM; they're the necessary editor and debugger, protecting the project from
the AI's most expensive mistake: **wasting time.**
