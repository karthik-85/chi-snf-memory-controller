QoS             = RF[3:0]        // 4 bits
TgtID           = RF[10:4]       // 7 bits
SrcID           = RF[17:11]      // 7 bits
TxnID           = RF[29:18]      // 12 bits
ReturnNID/       
StashNID        = RF[36:30]      // 7 bits  — MBZ for our transactions
StashNIDValid/
others          = RF[37]         // 1 bit   — MBZ
ReturnTxnID/
others          = RF[49:38]      // 12 bits — MBZ
Opcode          = RF[56:50]      // 7 bits
MultiReq        = RF[57]         // 1 bit
NumReq/Size     = RF[63:58]      // 6 bits  — Size = RF[60:58], RF[63:61] = 3'b0
Addr            = RF[115:64]     // 52 bits
PAS             = RF[118:116]    // 3 bits
LikelyShared    = RF[119]        // 1 bit
AllowRetry      = RF[120]        // 1 bit
Order           = RF[122:121]    // 2 bits
PCrdType        = RF[126:123]    // 4 bits
MemAttr         = RF[130:127]    // 4 bits
SnpAttr         = RF[131]        // 1 bit   — MBZ
PGroupID/others = RF[139:132]    // 8 bits  — MBZ
Excl/others     = RF[140]        // 1 bit   — MBZ
ExpCompAck      = RF[141]        // 1 bit
TagOp           = RF[143:142]    // 2 bits
TraceTag        = RF[144]        // 1 bit
MPAM            = RF[159:145]    // 15 bits — MBZ
PBHA            = RF[163:160]    // 4 bits  — MBZ
MECID           = RF[179:164]    // 16 bits — MBZ
SecSID          = RF[180]        // 1 bit   — MBZ
RSVDC           = RF[212:181]    // 32 bits — MBZ