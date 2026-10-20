# Round-Robin Arbiter (Verilog)

Parameterized (`N`) arbiter with rotating priority.

**Idea:** after granting requester *i*, the next search starts at *i+1* and wraps around. So a persistent requester waits at most `N-1` grants, never starved.

- `grant` is one-hot (all zeros when no request)
- Priority rotates only when a grant is issued

## Run (Icarus Verilog)
```
iverilog -g2005 -o sim tb/tb_rr_arbiter.v rtl/rr_arbiter.v && vvp sim
```
Expected: `RESULT: PASS`

## Verification
Self-checking testbench with a reference model. Checks one-hot grant, grant only to requesters, exact match with expected rotation, fairness (4 constant requesters -> 10/10/10/10 grants in 40 cycles), partial contention, and 2000 random cycles.

```
rtl/rr_arbiter.v      design
tb/tb_rr_arbiter.v    testbench
```
