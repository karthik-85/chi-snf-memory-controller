## Module Overview

`chi_req_decoder` is the entry point of the CHI Slave Node (SN-F), 
responsible for receiving and decoding incoming request flits from 
the Home Node (HN) on the REQ channel.

It implements a credit-based flow control mechanism, sending an 
initial burst of 4 credits to the HN after reset and returning one 
credit for every flit received. This ensures the HN never overflows 
the decoder with requests.

On receiving a valid flit, the module unpacks all CHI REQ channel 
fields — including TxnID, address, size, opcode, and memory 
attributes — and drives them as individual outputs to the downstream 
Flow Controller. It also decodes the opcode to assert req_is_read or 
req_is_write flags, telling the rest of the SN-F what type of memory 
operation is required.

##  Test Scenarios

## Functional tests

1) READNOSNP with different addresses
2) READNOSNP with different sizes
3) WRITENOSNPFULL
4) WRITENOSNPPTL
5) Invalid OPCODE

## Corner cases

1) Address at zero
2) Address at maximum value
3) TxnID at zero
4) TxnID at maximum (12'hFFF)
5) Size at minimum (3'b000 = 1 byte)
6) Size at maximum (3'b110 = 64 bytes)
7) All zeros flit — what happens?

## Credit tests

1) Verify 4 credits sent after reset
2) Verify credit returned after each flit
3) Verify no credit sent during idle

## Testcases for above cases

TC001 - ReadNoSnp with addr=0 (minimum)
TC002 - ReadNoSnp with addr=max (52'hFFFFFFFFFFFFF)
TC003 - ReadNoSnp with TxnID=0 (minimum)
TC004 - ReadNoSnp with TxnID=12'hFFF (maximum)
TC005 - ReadNoSnp with size=3'b000 (1 byte minimum)
TC006 - ReadNoSnp with size=3'b110 (64 bytes maximum)
TC007 - WriteNoSnpFull basic transaction
TC008 - WriteNoSnpPtl basic transaction
TC009 - All zeros flit - req_valid should be 0
TC010 - Invalid opcode - req_valid should be 0
TC011 - Back to back ReadNoSnp transactions
TC012 - Back to back WriteNoSnpFull transactions
TC013 - ReadNoSnp followed immediately by WriteNoSnpFull
TC014 - Multiple TxnIDs in sequence verify each decoded correctly
TC015 - Verify 4 credits sent after reset
TC016 - Verify credit returned after each flit
TC017 - Verify no credit sent during idle

## Assertions

1) req_valid should be high only when req_is_read or req_is_write are high and should stay low all other time. req_is_read and req_is_write should not be high at the same time.

2) Just after reset reqlcrdv should stay high for same number of cycles as number of credits. It should get asserted the cycle after reqflitv arrives and stay high for one cycle. reqlcrdv should stay low as idle behavior.

3) If a valid ReadNoSnp flit arrives on cycle N, 
req_is_read must be high on cycle N+1.

4) req_valid goes high exactly one cycle after rxreqflitv 
is high and returns to low the following cycle.

## Coverage Plan

### Opcode Coverage
COV001 - ReadNoSnp opcode seen at least once
COV002 - WriteNoSnpFull opcode seen at least once
COV003 - WriteNoSnpPtl opcode seen at least once
COV004 - Invalid/unknown opcode seen at least once

### Size Coverage
COV005 - Size = 3'b000 (1 byte) seen at least once
COV006 - Size = 3'b001 (2 bytes) seen at least once
COV007 - Size = 3'b010 (4 bytes) seen at least once
COV008 - Size = 3'b011 (8 bytes) seen at least once
COV009 - Size = 3'b100 (16 bytes) seen at least once
COV010 - Size = 3'b101 (32 bytes) seen at least once
COV011 - Size = 3'b110 (64 bytes) seen at least once

### Address Coverage
COV012 - Address = 0 (minimum) seen at least once
COV013 - Address in low range (0 to 52'hFFF) seen
COV014 - Address in mid range seen
COV015 - Address at maximum (52'hFFFFFFFFFFFFF) seen
COV016 - Aligned address seen at least once
COV017 - Unaligned address seen at least once

### TxnID Coverage
COV018 - TxnID = 0 (minimum) seen at least once
COV019 - TxnID = 12'hFFF (maximum) seen at least once
COV020 - At least 5 unique TxnIDs seen in one simulation run

### Transaction Sequence Coverage
COV021 - ReadNoSnp followed immediately by WriteNoSnpFull
COV022 - WriteNoSnpFull followed immediately by ReadNoSnp
COV023 - Back to back same transaction type seen
COV024 - Idle gap between two transactions seen
COV025 - Minimum 3 consecutive transactions without idle


## Exit Criteria

chi_req_decoder is considered fully verified when all of the 
following conditions are met:

### Test Scenarios
- All TC001 through TC017 passing with zero failures
- No X or Z values observed on any output during valid operation
- All tests passing consistently across multiple simulation runs

### Assertions
- All A001 through A010 assertions written and enabled
- Zero assertion violations across all test scenarios
- Assertions verified to fire correctly when violations are 
  deliberately injected

### Coverage
- All COV001 through COV025 coverage points hit at least once
- 100% opcode coverage closed
- 100% size coverage closed
- Address corner cases COV012 and COV015 hit
- Transaction sequence coverage COV021 through COV025 closed

### Code Quality
- All signal names consistent between RTL and testbench
- Module compiles with zero warnings in ModelSim
- All TODOs removed from RTL and testbench
- README updated with final module status

### Documentation
- reqflit_map.md accurate and up to date
- Verification plan complete and all TCs marked pass/fail
- Git history shows clean meaningful commit messages

