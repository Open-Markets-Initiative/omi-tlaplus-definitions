---------------------- MODULE Ebs_Spectrum_v12_0_Udp -----------------------
(***************************************************************************)
(* CME Group Spectrum Market Data v12.0                                    *)
(*                                                                         *)
(* Generated from the binary model. A field is the bytes it occupies; an   *)
(* integer is read only where a rule depends on one - a length, a count, a *)
(* message type - which are the dependencies the parse rules run on.       *)
(*                                                                         *)
(* TLC checks that every record decodes back to what was encoded, that a   *)
(* dispatch selects the message its type names, and that a derived length  *)
(* or count is written from what it describes.                             *)
(*                                                                         *)
(* Note: TLC evaluates integers in 32 bits, so a field wider than that has *)
(* no range it can enumerate; every field is checked as its bytes, which   *)
(* is exact at any width.                                                  *)
(*                                                                         *)
(* Note: Match Event Indicator is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(***************************************************************************)
EXTENDS Integers, Sequences

(***************************************************************************)
(* Wire primitives                                                         *)
(***************************************************************************)

Byte == 0 .. 255

(* An unsigned integer, least significant byte first. Read only where a rule *)
(* depends on the value: a length, a count, a message type. *)
RECURSIVE DecodeUIntLE(_)
DecodeUIntLE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE Head(bytes) + 256 * DecodeUIntLE(Tail(bytes))

RECURSIVE EncodeUIntLE(_, _)
EncodeUIntLE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE <<value % 256>> \o EncodeUIntLE(value \div 256, width - 1)

(* The same, most significant byte first, which is how a big endian protocol writes it *)
RECURSIVE DecodeUIntBE(_)
DecodeUIntBE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeUIntBE(SubSeq(bytes, 1, Len(bytes) - 1)) * 256 + bytes[Len(bytes)]

RECURSIVE EncodeUIntBE(_, _)
EncodeUIntBE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeUIntBE(value \div 256, width - 1) \o <<value % 256>>

(***************************************************************************)
(* A decoder yields the value it read and the bytes left, or fails         *)
(***************************************************************************)

Fail == [ok |-> FALSE]
Ok(value, rest) == [ok |-> TRUE, value |-> value, rest |-> rest]

(* The bytes a field of this width occupies, kept as they lie *)
ReadBytes(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, width), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a rule depends on, in the byte order the field states *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

ReadUIntBE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntBE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The bytes a field of no width of its own is checked at: none, one, and a short run *)
SampleBytes == { << >>, <<0>>, <<32, 255>> }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* Binary Packet Header: 12 bytes                                          *)
(***************************************************************************)

BinaryPacketHeader ==
    [ packetSequenceNumber : Sample(4),
      sendingTime          : Sample(8) ]

EncodeBinaryPacketHeader(message) ==
    message.packetSequenceNumber
        \o message.sendingTime

DecodeBinaryPacketHeader(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(packetSequenceNumber.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ packetSequenceNumber |-> packetSequenceNumber.value,
         sendingTime          |-> sendingTime.value ], sendingTime.rest)

ZeroBinaryPacketHeader ==
    [ packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendingTime          |-> [i \in 1 .. 8 |-> 0] ]

(* Binary Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedBinaryPacketHeader ==
    { ZeroBinaryPacketHeader }
        \cup { [ZeroBinaryPacketHeader EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroBinaryPacketHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Incremental Refresh Spectrum Group: 92 bytes                            *)
(***************************************************************************)

IncrementalRefreshSpectrumGroup ==
    [ mdEntryTypeSpectrumEntryType : Sample(1),
      financialInstrumentFullName  : Sample(35),
      symbol                       : Sample(20),
      instrumentGuid               : Sample(8),
      securityId                   : Sample(4),
      mdEntryPx                    : Sample(8),
      mdEntrySize                  : Sample(8),
      mdEntryTime                  : Sample(8) ]

EncodeIncrementalRefreshSpectrumGroup(message) ==
    message.mdEntryTypeSpectrumEntryType
        \o message.financialInstrumentFullName
        \o message.symbol
        \o message.instrumentGuid
        \o message.securityId
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryTime

DecodeIncrementalRefreshSpectrumGroup(bytes) ==
    LET mdEntryTypeSpectrumEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryTypeSpectrumEntryType.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(mdEntryTypeSpectrumEntryType.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET symbol == ReadBytes(financialInstrumentFullName.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(symbol.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(instrumentGuid.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(securityId.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryTime == ReadBytes(mdEntrySize.rest, 8) IN IF ~mdEntryTime.ok THEN Fail ELSE
    Ok([ mdEntryTypeSpectrumEntryType |-> mdEntryTypeSpectrumEntryType.value,
         financialInstrumentFullName  |-> financialInstrumentFullName.value,
         symbol                       |-> symbol.value,
         instrumentGuid               |-> instrumentGuid.value,
         securityId                   |-> securityId.value,
         mdEntryPx                    |-> mdEntryPx.value,
         mdEntrySize                  |-> mdEntrySize.value,
         mdEntryTime                  |-> mdEntryTime.value ], mdEntryTime.rest)

ZeroIncrementalRefreshSpectrumGroup ==
    [ mdEntryTypeSpectrumEntryType |-> [i \in 1 .. 1 |-> 0],
      financialInstrumentFullName  |-> [i \in 1 .. 35 |-> 0],
      symbol                       |-> [i \in 1 .. 20 |-> 0],
      instrumentGuid               |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 4 |-> 0],
      mdEntryPx                    |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                  |-> [i \in 1 .. 8 |-> 0],
      mdEntryTime                  |-> [i \in 1 .. 8 |-> 0] ]

(* Incremental Refresh Spectrum Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshSpectrumGroup ==
    { ZeroIncrementalRefreshSpectrumGroup }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.mdEntryTypeSpectrumEntryType = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSpectrumGroup EXCEPT !.mdEntryTime = one] : one \in Sample(8) }

(* A run of Incremental Refresh Spectrum Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshSpectrumGroupList(_)
EncodeIncrementalRefreshSpectrumGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshSpectrumGroup(Head(messages)) \o EncodeIncrementalRefreshSpectrumGroupList(Tail(messages))

(* As many Incremental Refresh Spectrum Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshSpectrumGroupList(_, _)
ReadIncrementalRefreshSpectrumGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshSpectrumGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshSpectrumGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Spectrum Group of each kind, for the lists that carry them *)
OneIncrementalRefreshSpectrumGroup == { ZeroIncrementalRefreshSpectrumGroup }

(***************************************************************************)
(* Incremental Refresh Spectrum Groups                                     *)
(***************************************************************************)

IncrementalRefreshSpectrumGroups ==
    [ blockLength                     : Sample(2),
      incrementalRefreshSpectrumGroup : SampleLists(OneIncrementalRefreshSpectrumGroup) ]

EncodeIncrementalRefreshSpectrumGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshSpectrumGroup), 1)
        \o EncodeIncrementalRefreshSpectrumGroupList(message.incrementalRefreshSpectrumGroup)

DecodeIncrementalRefreshSpectrumGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshSpectrumGroup == ReadIncrementalRefreshSpectrumGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshSpectrumGroup.ok THEN Fail ELSE
    Ok([ blockLength                     |-> blockLength.value,
         incrementalRefreshSpectrumGroup |-> incrementalRefreshSpectrumGroup.value ], incrementalRefreshSpectrumGroup.rest)

ZeroIncrementalRefreshSpectrumGroups ==
    [ blockLength                     |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshSpectrumGroup |-> << >> ]

(* Incremental Refresh Spectrum Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshSpectrumGroups ==
    { ZeroIncrementalRefreshSpectrumGroups }
        \cup { [ZeroIncrementalRefreshSpectrumGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshSpectrumGroups EXCEPT !.incrementalRefreshSpectrumGroup = one] : one \in SampleLists(OneIncrementalRefreshSpectrumGroup) }

(***************************************************************************)
(* Md Incremental Refresh Spectrum                                         *)
(***************************************************************************)

MdIncrementalRefreshSpectrum ==
    [ transactTime                     : Sample(8),
      matchEventIndicator              : Sample(1),
      incrementalRefreshSpectrumGroups : IncrementalRefreshSpectrumGroups ]

EncodeMdIncrementalRefreshSpectrum(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o EncodeIncrementalRefreshSpectrumGroups(message.incrementalRefreshSpectrumGroups)

DecodeMdIncrementalRefreshSpectrum(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET incrementalRefreshSpectrumGroups == DecodeIncrementalRefreshSpectrumGroups(matchEventIndicator.rest) IN IF ~incrementalRefreshSpectrumGroups.ok THEN Fail ELSE
    Ok([ transactTime                     |-> transactTime.value,
         matchEventIndicator              |-> matchEventIndicator.value,
         incrementalRefreshSpectrumGroups |-> incrementalRefreshSpectrumGroups.value ], incrementalRefreshSpectrumGroups.rest)

ZeroMdIncrementalRefreshSpectrum ==
    [ transactTime                     |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator              |-> [i \in 1 .. 1 |-> 0],
      incrementalRefreshSpectrumGroups |-> ZeroIncrementalRefreshSpectrumGroups ]

(* Md Incremental Refresh Spectrum at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshSpectrum ==
    { ZeroMdIncrementalRefreshSpectrum }
        \cup { [ZeroMdIncrementalRefreshSpectrum EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshSpectrum EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshSpectrum EXCEPT !.incrementalRefreshSpectrumGroups = one] : one \in CheckedIncrementalRefreshSpectrumGroups }

(***************************************************************************)
(* Incremental Refresh Ticker Group: 95 bytes                              *)
(***************************************************************************)

IncrementalRefreshTickerGroup ==
    [ mdEntryTypeTickerEntryType  : Sample(1),
      securityId                  : Sample(4),
      symbol                      : Sample(20),
      instrumentGuid              : Sample(8),
      financialInstrumentFullName : Sample(35),
      mdEntryPx                   : Sample(8),
      mdEntrySize                 : Sample(8),
      mdEntryTime                 : Sample(8),
      openCloseSettlFlag          : Sample(1),
      tradingSessionId            : Sample(1),
      aggressorSide               : Sample(1) ]

EncodeIncrementalRefreshTickerGroup(message) ==
    message.mdEntryTypeTickerEntryType
        \o message.securityId
        \o message.symbol
        \o message.instrumentGuid
        \o message.financialInstrumentFullName
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryTime
        \o message.openCloseSettlFlag
        \o message.tradingSessionId
        \o message.aggressorSide

DecodeIncrementalRefreshTickerGroup(bytes) ==
    LET mdEntryTypeTickerEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryTypeTickerEntryType.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdEntryTypeTickerEntryType.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityId.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(symbol.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(instrumentGuid.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(financialInstrumentFullName.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryTime == ReadBytes(mdEntrySize.rest, 8) IN IF ~mdEntryTime.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdEntryTime.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(tradingSessionId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    Ok([ mdEntryTypeTickerEntryType  |-> mdEntryTypeTickerEntryType.value,
         securityId                  |-> securityId.value,
         symbol                      |-> symbol.value,
         instrumentGuid              |-> instrumentGuid.value,
         financialInstrumentFullName |-> financialInstrumentFullName.value,
         mdEntryPx                   |-> mdEntryPx.value,
         mdEntrySize                 |-> mdEntrySize.value,
         mdEntryTime                 |-> mdEntryTime.value,
         openCloseSettlFlag          |-> openCloseSettlFlag.value,
         tradingSessionId            |-> tradingSessionId.value,
         aggressorSide               |-> aggressorSide.value ], aggressorSide.rest)

ZeroIncrementalRefreshTickerGroup ==
    [ mdEntryTypeTickerEntryType  |-> [i \in 1 .. 1 |-> 0],
      securityId                  |-> [i \in 1 .. 4 |-> 0],
      symbol                      |-> [i \in 1 .. 20 |-> 0],
      instrumentGuid              |-> [i \in 1 .. 8 |-> 0],
      financialInstrumentFullName |-> [i \in 1 .. 35 |-> 0],
      mdEntryPx                   |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                 |-> [i \in 1 .. 8 |-> 0],
      mdEntryTime                 |-> [i \in 1 .. 8 |-> 0],
      openCloseSettlFlag          |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId            |-> [i \in 1 .. 1 |-> 0],
      aggressorSide               |-> [i \in 1 .. 1 |-> 0] ]

(* Incremental Refresh Ticker Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshTickerGroup ==
    { ZeroIncrementalRefreshTickerGroup }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.mdEntryTypeTickerEntryType = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.mdEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshTickerGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }

(* A run of Incremental Refresh Ticker Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshTickerGroupList(_)
EncodeIncrementalRefreshTickerGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshTickerGroup(Head(messages)) \o EncodeIncrementalRefreshTickerGroupList(Tail(messages))

(* As many Incremental Refresh Ticker Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshTickerGroupList(_, _)
ReadIncrementalRefreshTickerGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshTickerGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshTickerGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Ticker Group of each kind, for the lists that carry them *)
OneIncrementalRefreshTickerGroup == { ZeroIncrementalRefreshTickerGroup }

(***************************************************************************)
(* Incremental Refresh Ticker Groups                                       *)
(***************************************************************************)

IncrementalRefreshTickerGroups ==
    [ blockLength                   : Sample(2),
      incrementalRefreshTickerGroup : SampleLists(OneIncrementalRefreshTickerGroup) ]

EncodeIncrementalRefreshTickerGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshTickerGroup), 1)
        \o EncodeIncrementalRefreshTickerGroupList(message.incrementalRefreshTickerGroup)

DecodeIncrementalRefreshTickerGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshTickerGroup == ReadIncrementalRefreshTickerGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshTickerGroup.ok THEN Fail ELSE
    Ok([ blockLength                   |-> blockLength.value,
         incrementalRefreshTickerGroup |-> incrementalRefreshTickerGroup.value ], incrementalRefreshTickerGroup.rest)

ZeroIncrementalRefreshTickerGroups ==
    [ blockLength                   |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshTickerGroup |-> << >> ]

(* Incremental Refresh Ticker Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshTickerGroups ==
    { ZeroIncrementalRefreshTickerGroups }
        \cup { [ZeroIncrementalRefreshTickerGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshTickerGroups EXCEPT !.incrementalRefreshTickerGroup = one] : one \in SampleLists(OneIncrementalRefreshTickerGroup) }

(***************************************************************************)
(* Md Incremental Refresh Ticker                                           *)
(***************************************************************************)

MdIncrementalRefreshTicker ==
    [ transactTime                   : Sample(8),
      matchEventIndicator            : Sample(1),
      incrementalRefreshTickerGroups : IncrementalRefreshTickerGroups ]

EncodeMdIncrementalRefreshTicker(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o EncodeIncrementalRefreshTickerGroups(message.incrementalRefreshTickerGroups)

DecodeMdIncrementalRefreshTicker(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET incrementalRefreshTickerGroups == DecodeIncrementalRefreshTickerGroups(matchEventIndicator.rest) IN IF ~incrementalRefreshTickerGroups.ok THEN Fail ELSE
    Ok([ transactTime                   |-> transactTime.value,
         matchEventIndicator            |-> matchEventIndicator.value,
         incrementalRefreshTickerGroups |-> incrementalRefreshTickerGroups.value ], incrementalRefreshTickerGroups.rest)

ZeroMdIncrementalRefreshTicker ==
    [ transactTime                   |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      incrementalRefreshTickerGroups |-> ZeroIncrementalRefreshTickerGroups ]

(* Md Incremental Refresh Ticker at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshTicker ==
    { ZeroMdIncrementalRefreshTicker }
        \cup { [ZeroMdIncrementalRefreshTicker EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshTicker EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshTicker EXCEPT !.incrementalRefreshTickerGroups = one] : one \in CheckedIncrementalRefreshTickerGroups }

(***************************************************************************)
(* Snapshot Refresh Spectrum Group: 25 bytes                               *)
(***************************************************************************)

SnapshotRefreshSpectrumGroup ==
    [ mdEntryTypeSpectrumEntryType : Sample(1),
      mdEntryPx                    : Sample(8),
      mdEntrySize                  : Sample(8),
      mdEntryTime                  : Sample(8) ]

EncodeSnapshotRefreshSpectrumGroup(message) ==
    message.mdEntryTypeSpectrumEntryType
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryTime

DecodeSnapshotRefreshSpectrumGroup(bytes) ==
    LET mdEntryTypeSpectrumEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryTypeSpectrumEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryTypeSpectrumEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryTime == ReadBytes(mdEntrySize.rest, 8) IN IF ~mdEntryTime.ok THEN Fail ELSE
    Ok([ mdEntryTypeSpectrumEntryType |-> mdEntryTypeSpectrumEntryType.value,
         mdEntryPx                    |-> mdEntryPx.value,
         mdEntrySize                  |-> mdEntrySize.value,
         mdEntryTime                  |-> mdEntryTime.value ], mdEntryTime.rest)

ZeroSnapshotRefreshSpectrumGroup ==
    [ mdEntryTypeSpectrumEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx                    |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                  |-> [i \in 1 .. 8 |-> 0],
      mdEntryTime                  |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Refresh Spectrum Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRefreshSpectrumGroup ==
    { ZeroSnapshotRefreshSpectrumGroup }
        \cup { [ZeroSnapshotRefreshSpectrumGroup EXCEPT !.mdEntryTypeSpectrumEntryType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRefreshSpectrumGroup EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshSpectrumGroup EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshSpectrumGroup EXCEPT !.mdEntryTime = one] : one \in Sample(8) }

(* A run of Snapshot Refresh Spectrum Group, written one after another *)
RECURSIVE EncodeSnapshotRefreshSpectrumGroupList(_)
EncodeSnapshotRefreshSpectrumGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotRefreshSpectrumGroup(Head(messages)) \o EncodeSnapshotRefreshSpectrumGroupList(Tail(messages))

(* As many Snapshot Refresh Spectrum Group as the field that counts them says *)
RECURSIVE ReadSnapshotRefreshSpectrumGroupList(_, _)
ReadSnapshotRefreshSpectrumGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotRefreshSpectrumGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotRefreshSpectrumGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Refresh Spectrum Group of each kind, for the lists that carry them *)
OneSnapshotRefreshSpectrumGroup == { ZeroSnapshotRefreshSpectrumGroup }

(***************************************************************************)
(* Snapshot Refresh Spectrum Groups                                        *)
(***************************************************************************)

SnapshotRefreshSpectrumGroups ==
    [ blockLength                  : Sample(2),
      snapshotRefreshSpectrumGroup : SampleLists(OneSnapshotRefreshSpectrumGroup) ]

EncodeSnapshotRefreshSpectrumGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snapshotRefreshSpectrumGroup), 1)
        \o EncodeSnapshotRefreshSpectrumGroupList(message.snapshotRefreshSpectrumGroup)

DecodeSnapshotRefreshSpectrumGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotRefreshSpectrumGroup == ReadSnapshotRefreshSpectrumGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotRefreshSpectrumGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         snapshotRefreshSpectrumGroup |-> snapshotRefreshSpectrumGroup.value ], snapshotRefreshSpectrumGroup.rest)

ZeroSnapshotRefreshSpectrumGroups ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      snapshotRefreshSpectrumGroup |-> << >> ]

(* Snapshot Refresh Spectrum Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRefreshSpectrumGroups ==
    { ZeroSnapshotRefreshSpectrumGroups }
        \cup { [ZeroSnapshotRefreshSpectrumGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotRefreshSpectrumGroups EXCEPT !.snapshotRefreshSpectrumGroup = one] : one \in SampleLists(OneSnapshotRefreshSpectrumGroup) }

(***************************************************************************)
(* Md Snapshot Refresh Spectrum                                            *)
(***************************************************************************)

MdSnapshotRefreshSpectrum ==
    [ transactTime                  : Sample(8),
      matchEventIndicator           : Sample(1),
      financialInstrumentFullName   : Sample(35),
      symbol                        : Sample(20),
      instrumentGuid                : Sample(8),
      securityId                    : Sample(4),
      snapshotRefreshSpectrumGroups : SnapshotRefreshSpectrumGroups ]

EncodeMdSnapshotRefreshSpectrum(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.financialInstrumentFullName
        \o message.symbol
        \o message.instrumentGuid
        \o message.securityId
        \o EncodeSnapshotRefreshSpectrumGroups(message.snapshotRefreshSpectrumGroups)

DecodeMdSnapshotRefreshSpectrum(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(matchEventIndicator.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET symbol == ReadBytes(financialInstrumentFullName.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(symbol.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(instrumentGuid.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET snapshotRefreshSpectrumGroups == DecodeSnapshotRefreshSpectrumGroups(securityId.rest) IN IF ~snapshotRefreshSpectrumGroups.ok THEN Fail ELSE
    Ok([ transactTime                  |-> transactTime.value,
         matchEventIndicator           |-> matchEventIndicator.value,
         financialInstrumentFullName   |-> financialInstrumentFullName.value,
         symbol                        |-> symbol.value,
         instrumentGuid                |-> instrumentGuid.value,
         securityId                    |-> securityId.value,
         snapshotRefreshSpectrumGroups |-> snapshotRefreshSpectrumGroups.value ], snapshotRefreshSpectrumGroups.rest)

ZeroMdSnapshotRefreshSpectrum ==
    [ transactTime                  |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator           |-> [i \in 1 .. 1 |-> 0],
      financialInstrumentFullName   |-> [i \in 1 .. 35 |-> 0],
      symbol                        |-> [i \in 1 .. 20 |-> 0],
      instrumentGuid                |-> [i \in 1 .. 8 |-> 0],
      securityId                    |-> [i \in 1 .. 4 |-> 0],
      snapshotRefreshSpectrumGroups |-> ZeroSnapshotRefreshSpectrumGroups ]

(* Md Snapshot Refresh Spectrum at zero, then each field in turn at the values it is checked at *)
CheckedMdSnapshotRefreshSpectrum ==
    { ZeroMdSnapshotRefreshSpectrum }
        \cup { [ZeroMdSnapshotRefreshSpectrum EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdSnapshotRefreshSpectrum EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdSnapshotRefreshSpectrum EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroMdSnapshotRefreshSpectrum EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroMdSnapshotRefreshSpectrum EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroMdSnapshotRefreshSpectrum EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMdSnapshotRefreshSpectrum EXCEPT !.snapshotRefreshSpectrumGroups = one] : one \in CheckedSnapshotRefreshSpectrumGroups }

(***************************************************************************)
(* Snapshot Refresh Ticker Group: 28 bytes                                 *)
(***************************************************************************)

SnapshotRefreshTickerGroup ==
    [ mdEntryTypeTickerEntryType : Sample(1),
      mdEntryPx                  : Sample(8),
      mdEntrySize                : Sample(8),
      mdEntryTime                : Sample(8),
      openCloseSettlFlag         : Sample(1),
      tradingSessionId           : Sample(1),
      aggressorSide              : Sample(1) ]

EncodeSnapshotRefreshTickerGroup(message) ==
    message.mdEntryTypeTickerEntryType
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdEntryTime
        \o message.openCloseSettlFlag
        \o message.tradingSessionId
        \o message.aggressorSide

DecodeSnapshotRefreshTickerGroup(bytes) ==
    LET mdEntryTypeTickerEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryTypeTickerEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryTypeTickerEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdEntryTime == ReadBytes(mdEntrySize.rest, 8) IN IF ~mdEntryTime.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdEntryTime.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(tradingSessionId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    Ok([ mdEntryTypeTickerEntryType |-> mdEntryTypeTickerEntryType.value,
         mdEntryPx                  |-> mdEntryPx.value,
         mdEntrySize                |-> mdEntrySize.value,
         mdEntryTime                |-> mdEntryTime.value,
         openCloseSettlFlag         |-> openCloseSettlFlag.value,
         tradingSessionId           |-> tradingSessionId.value,
         aggressorSide              |-> aggressorSide.value ], aggressorSide.rest)

ZeroSnapshotRefreshTickerGroup ==
    [ mdEntryTypeTickerEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx                  |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                |-> [i \in 1 .. 8 |-> 0],
      mdEntryTime                |-> [i \in 1 .. 8 |-> 0],
      openCloseSettlFlag         |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId           |-> [i \in 1 .. 1 |-> 0],
      aggressorSide              |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Refresh Ticker Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRefreshTickerGroup ==
    { ZeroSnapshotRefreshTickerGroup }
        \cup { [ZeroSnapshotRefreshTickerGroup EXCEPT !.mdEntryTypeTickerEntryType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRefreshTickerGroup EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshTickerGroup EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshTickerGroup EXCEPT !.mdEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshTickerGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRefreshTickerGroup EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRefreshTickerGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }

(* A run of Snapshot Refresh Ticker Group, written one after another *)
RECURSIVE EncodeSnapshotRefreshTickerGroupList(_)
EncodeSnapshotRefreshTickerGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotRefreshTickerGroup(Head(messages)) \o EncodeSnapshotRefreshTickerGroupList(Tail(messages))

(* As many Snapshot Refresh Ticker Group as the field that counts them says *)
RECURSIVE ReadSnapshotRefreshTickerGroupList(_, _)
ReadSnapshotRefreshTickerGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotRefreshTickerGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotRefreshTickerGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Refresh Ticker Group of each kind, for the lists that carry them *)
OneSnapshotRefreshTickerGroup == { ZeroSnapshotRefreshTickerGroup }

(***************************************************************************)
(* Snapshot Refresh Ticker Groups                                          *)
(***************************************************************************)

SnapshotRefreshTickerGroups ==
    [ blockLength                : Sample(2),
      snapshotRefreshTickerGroup : SampleLists(OneSnapshotRefreshTickerGroup) ]

EncodeSnapshotRefreshTickerGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snapshotRefreshTickerGroup), 1)
        \o EncodeSnapshotRefreshTickerGroupList(message.snapshotRefreshTickerGroup)

DecodeSnapshotRefreshTickerGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotRefreshTickerGroup == ReadSnapshotRefreshTickerGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotRefreshTickerGroup.ok THEN Fail ELSE
    Ok([ blockLength                |-> blockLength.value,
         snapshotRefreshTickerGroup |-> snapshotRefreshTickerGroup.value ], snapshotRefreshTickerGroup.rest)

ZeroSnapshotRefreshTickerGroups ==
    [ blockLength                |-> [i \in 1 .. 2 |-> 0],
      snapshotRefreshTickerGroup |-> << >> ]

(* Snapshot Refresh Ticker Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRefreshTickerGroups ==
    { ZeroSnapshotRefreshTickerGroups }
        \cup { [ZeroSnapshotRefreshTickerGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotRefreshTickerGroups EXCEPT !.snapshotRefreshTickerGroup = one] : one \in SampleLists(OneSnapshotRefreshTickerGroup) }

(***************************************************************************)
(* Md Snapshot Refresh Ticker                                              *)
(***************************************************************************)

MdSnapshotRefreshTicker ==
    [ transactTime                : Sample(8),
      matchEventIndicator         : Sample(1),
      financialInstrumentFullName : Sample(35),
      symbol                      : Sample(20),
      instrumentGuid              : Sample(8),
      securityId                  : Sample(4),
      snapshotRefreshTickerGroups : SnapshotRefreshTickerGroups ]

EncodeMdSnapshotRefreshTicker(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.financialInstrumentFullName
        \o message.symbol
        \o message.instrumentGuid
        \o message.securityId
        \o EncodeSnapshotRefreshTickerGroups(message.snapshotRefreshTickerGroups)

DecodeMdSnapshotRefreshTicker(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(matchEventIndicator.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET symbol == ReadBytes(financialInstrumentFullName.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(symbol.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(instrumentGuid.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET snapshotRefreshTickerGroups == DecodeSnapshotRefreshTickerGroups(securityId.rest) IN IF ~snapshotRefreshTickerGroups.ok THEN Fail ELSE
    Ok([ transactTime                |-> transactTime.value,
         matchEventIndicator         |-> matchEventIndicator.value,
         financialInstrumentFullName |-> financialInstrumentFullName.value,
         symbol                      |-> symbol.value,
         instrumentGuid              |-> instrumentGuid.value,
         securityId                  |-> securityId.value,
         snapshotRefreshTickerGroups |-> snapshotRefreshTickerGroups.value ], snapshotRefreshTickerGroups.rest)

ZeroMdSnapshotRefreshTicker ==
    [ transactTime                |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator         |-> [i \in 1 .. 1 |-> 0],
      financialInstrumentFullName |-> [i \in 1 .. 35 |-> 0],
      symbol                      |-> [i \in 1 .. 20 |-> 0],
      instrumentGuid              |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 4 |-> 0],
      snapshotRefreshTickerGroups |-> ZeroSnapshotRefreshTickerGroups ]

(* Md Snapshot Refresh Ticker at zero, then each field in turn at the values it is checked at *)
CheckedMdSnapshotRefreshTicker ==
    { ZeroMdSnapshotRefreshTicker }
        \cup { [ZeroMdSnapshotRefreshTicker EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdSnapshotRefreshTicker EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdSnapshotRefreshTicker EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroMdSnapshotRefreshTicker EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroMdSnapshotRefreshTicker EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroMdSnapshotRefreshTicker EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMdSnapshotRefreshTicker EXCEPT !.snapshotRefreshTickerGroups = one] : one \in CheckedSnapshotRefreshTickerGroups }

(***************************************************************************)
(* Global Day Roll: 9 bytes                                                *)
(***************************************************************************)

GlobalDayRoll ==
    [ transactTime         : Sample(8),
      securityTradingEvent : Sample(1) ]

EncodeGlobalDayRoll(message) ==
    message.transactTime
        \o message.securityTradingEvent

DecodeGlobalDayRoll(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(transactTime.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    Ok([ transactTime         |-> transactTime.value,
         securityTradingEvent |-> securityTradingEvent.value ], securityTradingEvent.rest)

ZeroGlobalDayRoll ==
    [ transactTime         |-> [i \in 1 .. 8 |-> 0],
      securityTradingEvent |-> [i \in 1 .. 1 |-> 0] ]

(* Global Day Roll at zero, then each field in turn at the values it is checked at *)
CheckedGlobalDayRoll ==
    { ZeroGlobalDayRoll }
        \cup { [ZeroGlobalDayRoll EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroGlobalDayRoll EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

AdminHeartbeatCode == 302  \* 0x12e
MdIncrementalRefreshSpectrumCode == 303  \* 0x12f
MdIncrementalRefreshTickerCode == 304  \* 0x130
MdSnapshotRefreshSpectrumCode == 305  \* 0x131
MdSnapshotRefreshTickerCode == 306  \* 0x132
GlobalDayRollCode == 307  \* 0x133

Payload ==
    [ tag : {AdminHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {MdIncrementalRefreshSpectrumCode}, body : MdIncrementalRefreshSpectrum ]
        \cup [ tag : {MdIncrementalRefreshTickerCode}, body : MdIncrementalRefreshTicker ]
        \cup [ tag : {MdSnapshotRefreshSpectrumCode}, body : MdSnapshotRefreshSpectrum ]
        \cup [ tag : {MdSnapshotRefreshTickerCode}, body : MdSnapshotRefreshTicker ]
        \cup [ tag : {GlobalDayRollCode}, body : GlobalDayRoll ]

EncodePayload(message) ==
    CASE message.tag = AdminHeartbeatCode -> << >>
      [] message.tag = MdIncrementalRefreshSpectrumCode -> EncodeMdIncrementalRefreshSpectrum(message.body)
      [] message.tag = MdIncrementalRefreshTickerCode -> EncodeMdIncrementalRefreshTicker(message.body)
      [] message.tag = MdSnapshotRefreshSpectrumCode -> EncodeMdSnapshotRefreshSpectrum(message.body)
      [] message.tag = MdSnapshotRefreshTickerCode -> EncodeMdSnapshotRefreshTicker(message.body)
      [] message.tag = GlobalDayRollCode -> EncodeGlobalDayRoll(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AdminHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = MdIncrementalRefreshSpectrumCode -> DecodeMdIncrementalRefreshSpectrum(bytes)
              [] tag = MdIncrementalRefreshTickerCode -> DecodeMdIncrementalRefreshTicker(bytes)
              [] tag = MdSnapshotRefreshSpectrumCode -> DecodeMdSnapshotRefreshSpectrum(bytes)
              [] tag = MdSnapshotRefreshTickerCode -> DecodeMdSnapshotRefreshTicker(bytes)
              [] tag = GlobalDayRollCode -> DecodeGlobalDayRoll(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> MdIncrementalRefreshSpectrumCode, body |-> one] : one \in CheckedMdIncrementalRefreshSpectrum }
        \cup { [tag |-> MdIncrementalRefreshTickerCode, body |-> one] : one \in CheckedMdIncrementalRefreshTicker }
        \cup { [tag |-> MdSnapshotRefreshSpectrumCode, body |-> one] : one \in CheckedMdSnapshotRefreshSpectrum }
        \cup { [tag |-> MdSnapshotRefreshTickerCode, body |-> one] : one \in CheckedMdSnapshotRefreshTicker }
        \cup { [tag |-> GlobalDayRollCode, body |-> one] : one \in CheckedGlobalDayRoll }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshSpectrumCode, body |-> ZeroMdIncrementalRefreshSpectrum]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshTickerCode, body |-> ZeroMdIncrementalRefreshTicker]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdSnapshotRefreshSpectrumCode, body |-> ZeroMdSnapshotRefreshSpectrum]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdSnapshotRefreshTickerCode, body |-> ZeroMdSnapshotRefreshTicker]],
      [ZeroMessage EXCEPT !.payload = [tag |-> GlobalDayRollCode, body |-> ZeroGlobalDayRoll]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ binaryPacketHeader : BinaryPacketHeader,
      message            : SampleLists(OneMessage) ]

EncodeUdpPacket(message) ==
    EncodeBinaryPacketHeader(message.binaryPacketHeader)
        \o EncodeMessageList(message.message)

DecodeUdpPacket(bytes) ==
    LET binaryPacketHeader == DecodeBinaryPacketHeader(bytes) IN IF ~binaryPacketHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(binaryPacketHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ binaryPacketHeader |-> binaryPacketHeader.value,
         message            |-> message.value ], message.rest)

ZeroUdpPacket ==
    [ binaryPacketHeader |-> ZeroBinaryPacketHeader,
      message            |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.binaryPacketHeader = one] : one \in CheckedBinaryPacketHeader }
        \cup { [ZeroUdpPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(***************************************************************************)
(* What TLC checks                                                         *)
(***************************************************************************)

(* An integer a rule depends on writes its width and reads back what was written *)
RoundTripUIntLE ==
    \A width \in 1 .. 3 :
        \A value \in {0, 1, 255, 256, 65535} :
            (value < 256 ^ width) =>
                /\ Len(EncodeUIntLE(value, width)) = width
                /\ DecodeUIntLE(EncodeUIntLE(value, width)) = value
                /\ Len(EncodeUIntBE(value, width)) = width
                /\ DecodeUIntBE(EncodeUIntBE(value, width)) = value
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte
                /\ \A i \in 1 .. width : EncodeUIntBE(value, width)[i] \in Byte

(* Every Binary Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBinaryPacketHeader ==
    \A message \in CheckedBinaryPacketHeader :
        LET read == DecodeBinaryPacketHeader(EncodeBinaryPacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Spectrum Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshSpectrumGroup ==
    \A message \in CheckedIncrementalRefreshSpectrumGroup :
        LET read == DecodeIncrementalRefreshSpectrumGroup(EncodeIncrementalRefreshSpectrumGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Spectrum Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshSpectrumGroups ==
    \A message \in CheckedIncrementalRefreshSpectrumGroups :
        LET read == DecodeIncrementalRefreshSpectrumGroups(EncodeIncrementalRefreshSpectrumGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Spectrum decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshSpectrum ==
    \A message \in CheckedMdIncrementalRefreshSpectrum :
        LET read == DecodeMdIncrementalRefreshSpectrum(EncodeMdIncrementalRefreshSpectrum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Ticker Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshTickerGroup ==
    \A message \in CheckedIncrementalRefreshTickerGroup :
        LET read == DecodeIncrementalRefreshTickerGroup(EncodeIncrementalRefreshTickerGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Ticker Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshTickerGroups ==
    \A message \in CheckedIncrementalRefreshTickerGroups :
        LET read == DecodeIncrementalRefreshTickerGroups(EncodeIncrementalRefreshTickerGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Ticker decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshTicker ==
    \A message \in CheckedMdIncrementalRefreshTicker :
        LET read == DecodeMdIncrementalRefreshTicker(EncodeMdIncrementalRefreshTicker(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Refresh Spectrum Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRefreshSpectrumGroup ==
    \A message \in CheckedSnapshotRefreshSpectrumGroup :
        LET read == DecodeSnapshotRefreshSpectrumGroup(EncodeSnapshotRefreshSpectrumGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Refresh Spectrum Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRefreshSpectrumGroups ==
    \A message \in CheckedSnapshotRefreshSpectrumGroups :
        LET read == DecodeSnapshotRefreshSpectrumGroups(EncodeSnapshotRefreshSpectrumGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Snapshot Refresh Spectrum decodes back to what was encoded, and leaves nothing over *)
RoundTripMdSnapshotRefreshSpectrum ==
    \A message \in CheckedMdSnapshotRefreshSpectrum :
        LET read == DecodeMdSnapshotRefreshSpectrum(EncodeMdSnapshotRefreshSpectrum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Refresh Ticker Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRefreshTickerGroup ==
    \A message \in CheckedSnapshotRefreshTickerGroup :
        LET read == DecodeSnapshotRefreshTickerGroup(EncodeSnapshotRefreshTickerGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Refresh Ticker Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRefreshTickerGroups ==
    \A message \in CheckedSnapshotRefreshTickerGroups :
        LET read == DecodeSnapshotRefreshTickerGroups(EncodeSnapshotRefreshTickerGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Snapshot Refresh Ticker decodes back to what was encoded, and leaves nothing over *)
RoundTripMdSnapshotRefreshTicker ==
    \A message \in CheckedMdSnapshotRefreshTicker :
        LET read == DecodeMdSnapshotRefreshTicker(EncodeMdSnapshotRefreshTicker(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Global Day Roll decodes back to what was encoded, and leaves nothing over *)
RoundTripGlobalDayRoll ==
    \A message \in CheckedGlobalDayRoll :
        LET read == DecodeGlobalDayRoll(EncodeGlobalDayRoll(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
