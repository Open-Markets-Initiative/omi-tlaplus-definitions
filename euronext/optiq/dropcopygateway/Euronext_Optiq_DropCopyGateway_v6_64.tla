--------------- MODULE Euronext_Optiq_DropCopyGateway_v6_64 ----------------
(***************************************************************************)
(* Euronext Drop Copy Gateway v6.64                                        *)
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
(* Note: Phase Qualifier is a bit field set, checked as its 2 bytes rather *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Ack Qualifiers is a bit field set, checked as its 1 byte rather   *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Dark Execution Instruction is a bit field set, checked as its 1   *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Execution Instruction is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Mi Fid Indicators is a bit field set, checked as its 1 byte       *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Trade Qualifier Optional is a bit field set, checked as its 1     *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Trading Session is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Open Close is a bit field set, checked as its 2 bytes rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Mi Fid Indicators Optional is a bit field set, checked as its 1   *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Trade Qualifier is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Execution Instruction Optional is a bit field set, checked as its *)
(* 1 byte rather than bit by bit.                                          *)
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
(* Dc Market Status Change Message: 79 bytes                               *)
(***************************************************************************)

DcMarketStatusChangeMessage ==
    [ msgSeqNum                       : Sample(4),
      produceTime                     : Sample(8),
      consumeTime                     : Sample(8),
      emm                             : Sample(1),
      eventId                         : Sample(8),
      phaseId                         : Sample(1),
      tradingGroupState               : Sample(1),
      instrumentState                 : Sample(1),
      changeType                      : Sample(1),
      symbolIndex                     : Sample(4),
      eventTime                       : Sample(8),
      bookState                       : Sample(1),
      statusReason                    : Sample(1),
      phaseQualifier                  : Sample(2),
      tradingPeriod                   : Sample(1),
      tradingSide                     : Sample(1),
      priceLimits                     : Sample(1),
      quoteSpreadMultiplier           : Sample(1),
      orderEntryQualifier             : Sample(1),
      session                         : Sample(1),
      scheduledEvent                  : Sample(1),
      scheduledEventTime              : Sample(8),
      tradingGroupOrderEntryQualifier : Sample(1),
      instrumentOrderEntryQualifier   : Sample(1),
      phaseTime                       : Sample(8),
      contractSymbolIndex             : Sample(4),
      priceLimitStyle                 : Sample(1) ]

EncodeDcMarketStatusChangeMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.emm
        \o message.eventId
        \o message.phaseId
        \o message.tradingGroupState
        \o message.instrumentState
        \o message.changeType
        \o message.symbolIndex
        \o message.eventTime
        \o message.bookState
        \o message.statusReason
        \o message.phaseQualifier
        \o message.tradingPeriod
        \o message.tradingSide
        \o message.priceLimits
        \o message.quoteSpreadMultiplier
        \o message.orderEntryQualifier
        \o message.session
        \o message.scheduledEvent
        \o message.scheduledEventTime
        \o message.tradingGroupOrderEntryQualifier
        \o message.instrumentOrderEntryQualifier
        \o message.phaseTime
        \o message.contractSymbolIndex
        \o message.priceLimitStyle

DecodeDcMarketStatusChangeMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET emm == ReadBytes(consumeTime.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventId == ReadBytes(emm.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET phaseId == ReadBytes(eventId.rest, 1) IN IF ~phaseId.ok THEN Fail ELSE
    LET tradingGroupState == ReadBytes(phaseId.rest, 1) IN IF ~tradingGroupState.ok THEN Fail ELSE
    LET instrumentState == ReadBytes(tradingGroupState.rest, 1) IN IF ~instrumentState.ok THEN Fail ELSE
    LET changeType == ReadBytes(instrumentState.rest, 1) IN IF ~changeType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(changeType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET eventTime == ReadBytes(symbolIndex.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET bookState == ReadBytes(eventTime.rest, 1) IN IF ~bookState.ok THEN Fail ELSE
    LET statusReason == ReadBytes(bookState.rest, 1) IN IF ~statusReason.ok THEN Fail ELSE
    LET phaseQualifier == ReadBytes(statusReason.rest, 2) IN IF ~phaseQualifier.ok THEN Fail ELSE
    LET tradingPeriod == ReadBytes(phaseQualifier.rest, 1) IN IF ~tradingPeriod.ok THEN Fail ELSE
    LET tradingSide == ReadBytes(tradingPeriod.rest, 1) IN IF ~tradingSide.ok THEN Fail ELSE
    LET priceLimits == ReadBytes(tradingSide.rest, 1) IN IF ~priceLimits.ok THEN Fail ELSE
    LET quoteSpreadMultiplier == ReadBytes(priceLimits.rest, 1) IN IF ~quoteSpreadMultiplier.ok THEN Fail ELSE
    LET orderEntryQualifier == ReadBytes(quoteSpreadMultiplier.rest, 1) IN IF ~orderEntryQualifier.ok THEN Fail ELSE
    LET session == ReadBytes(orderEntryQualifier.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET scheduledEvent == ReadBytes(session.rest, 1) IN IF ~scheduledEvent.ok THEN Fail ELSE
    LET scheduledEventTime == ReadBytes(scheduledEvent.rest, 8) IN IF ~scheduledEventTime.ok THEN Fail ELSE
    LET tradingGroupOrderEntryQualifier == ReadBytes(scheduledEventTime.rest, 1) IN IF ~tradingGroupOrderEntryQualifier.ok THEN Fail ELSE
    LET instrumentOrderEntryQualifier == ReadBytes(tradingGroupOrderEntryQualifier.rest, 1) IN IF ~instrumentOrderEntryQualifier.ok THEN Fail ELSE
    LET phaseTime == ReadBytes(instrumentOrderEntryQualifier.rest, 8) IN IF ~phaseTime.ok THEN Fail ELSE
    LET contractSymbolIndex == ReadBytes(phaseTime.rest, 4) IN IF ~contractSymbolIndex.ok THEN Fail ELSE
    LET priceLimitStyle == ReadBytes(contractSymbolIndex.rest, 1) IN IF ~priceLimitStyle.ok THEN Fail ELSE
    Ok([ msgSeqNum                       |-> msgSeqNum.value,
         produceTime                     |-> produceTime.value,
         consumeTime                     |-> consumeTime.value,
         emm                             |-> emm.value,
         eventId                         |-> eventId.value,
         phaseId                         |-> phaseId.value,
         tradingGroupState               |-> tradingGroupState.value,
         instrumentState                 |-> instrumentState.value,
         changeType                      |-> changeType.value,
         symbolIndex                     |-> symbolIndex.value,
         eventTime                       |-> eventTime.value,
         bookState                       |-> bookState.value,
         statusReason                    |-> statusReason.value,
         phaseQualifier                  |-> phaseQualifier.value,
         tradingPeriod                   |-> tradingPeriod.value,
         tradingSide                     |-> tradingSide.value,
         priceLimits                     |-> priceLimits.value,
         quoteSpreadMultiplier           |-> quoteSpreadMultiplier.value,
         orderEntryQualifier             |-> orderEntryQualifier.value,
         session                         |-> session.value,
         scheduledEvent                  |-> scheduledEvent.value,
         scheduledEventTime              |-> scheduledEventTime.value,
         tradingGroupOrderEntryQualifier |-> tradingGroupOrderEntryQualifier.value,
         instrumentOrderEntryQualifier   |-> instrumentOrderEntryQualifier.value,
         phaseTime                       |-> phaseTime.value,
         contractSymbolIndex             |-> contractSymbolIndex.value,
         priceLimitStyle                 |-> priceLimitStyle.value ], priceLimitStyle.rest)

ZeroDcMarketStatusChangeMessage ==
    [ msgSeqNum                       |-> [i \in 1 .. 4 |-> 0],
      produceTime                     |-> [i \in 1 .. 8 |-> 0],
      consumeTime                     |-> [i \in 1 .. 8 |-> 0],
      emm                             |-> [i \in 1 .. 1 |-> 0],
      eventId                         |-> [i \in 1 .. 8 |-> 0],
      phaseId                         |-> [i \in 1 .. 1 |-> 0],
      tradingGroupState               |-> [i \in 1 .. 1 |-> 0],
      instrumentState                 |-> [i \in 1 .. 1 |-> 0],
      changeType                      |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                     |-> [i \in 1 .. 4 |-> 0],
      eventTime                       |-> [i \in 1 .. 8 |-> 0],
      bookState                       |-> [i \in 1 .. 1 |-> 0],
      statusReason                    |-> [i \in 1 .. 1 |-> 0],
      phaseQualifier                  |-> [i \in 1 .. 2 |-> 0],
      tradingPeriod                   |-> [i \in 1 .. 1 |-> 0],
      tradingSide                     |-> [i \in 1 .. 1 |-> 0],
      priceLimits                     |-> [i \in 1 .. 1 |-> 0],
      quoteSpreadMultiplier           |-> [i \in 1 .. 1 |-> 0],
      orderEntryQualifier             |-> [i \in 1 .. 1 |-> 0],
      session                         |-> [i \in 1 .. 1 |-> 0],
      scheduledEvent                  |-> [i \in 1 .. 1 |-> 0],
      scheduledEventTime              |-> [i \in 1 .. 8 |-> 0],
      tradingGroupOrderEntryQualifier |-> [i \in 1 .. 1 |-> 0],
      instrumentOrderEntryQualifier   |-> [i \in 1 .. 1 |-> 0],
      phaseTime                       |-> [i \in 1 .. 8 |-> 0],
      contractSymbolIndex             |-> [i \in 1 .. 4 |-> 0],
      priceLimitStyle                 |-> [i \in 1 .. 1 |-> 0] ]

(* Dc Market Status Change Message at zero, then each field in turn at the values it is checked at *)
CheckedDcMarketStatusChangeMessage ==
    { ZeroDcMarketStatusChangeMessage }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.phaseId = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.tradingGroupState = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.instrumentState = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.changeType = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.bookState = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.statusReason = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.phaseQualifier = one] : one \in Sample(2) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.tradingPeriod = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.tradingSide = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.priceLimits = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.quoteSpreadMultiplier = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.orderEntryQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.scheduledEvent = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.scheduledEventTime = one] : one \in Sample(8) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.tradingGroupOrderEntryQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.instrumentOrderEntryQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.phaseTime = one] : one \in Sample(8) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.contractSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcMarketStatusChangeMessage EXCEPT !.priceLimitStyle = one] : one \in Sample(1) }

(***************************************************************************)
(* Dc Price Update Message: 67 bytes                                       *)
(***************************************************************************)

DcPriceUpdateMessage ==
    [ msgSeqNum        : Sample(4),
      produceTime      : Sample(8),
      consumeTime      : Sample(8),
      emm              : Sample(1),
      eventId          : Sample(8),
      eventTime        : Sample(8),
      priceType        : Sample(1),
      symbolIndex      : Sample(4),
      priceOptional    : Sample(8),
      quantityOptional : Sample(8),
      imbalanceQty     : Sample(8),
      imbalanceQtySide : Sample(1) ]

EncodeDcPriceUpdateMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.emm
        \o message.eventId
        \o message.eventTime
        \o message.priceType
        \o message.symbolIndex
        \o message.priceOptional
        \o message.quantityOptional
        \o message.imbalanceQty
        \o message.imbalanceQtySide

DecodeDcPriceUpdateMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET emm == ReadBytes(consumeTime.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventId == ReadBytes(emm.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET eventTime == ReadBytes(eventId.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    LET priceType == ReadBytes(eventTime.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(priceType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(symbolIndex.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET quantityOptional == ReadBytes(priceOptional.rest, 8) IN IF ~quantityOptional.ok THEN Fail ELSE
    LET imbalanceQty == ReadBytes(quantityOptional.rest, 8) IN IF ~imbalanceQty.ok THEN Fail ELSE
    LET imbalanceQtySide == ReadBytes(imbalanceQty.rest, 1) IN IF ~imbalanceQtySide.ok THEN Fail ELSE
    Ok([ msgSeqNum        |-> msgSeqNum.value,
         produceTime      |-> produceTime.value,
         consumeTime      |-> consumeTime.value,
         emm              |-> emm.value,
         eventId          |-> eventId.value,
         eventTime        |-> eventTime.value,
         priceType        |-> priceType.value,
         symbolIndex      |-> symbolIndex.value,
         priceOptional    |-> priceOptional.value,
         quantityOptional |-> quantityOptional.value,
         imbalanceQty     |-> imbalanceQty.value,
         imbalanceQtySide |-> imbalanceQtySide.value ], imbalanceQtySide.rest)

ZeroDcPriceUpdateMessage ==
    [ msgSeqNum        |-> [i \in 1 .. 4 |-> 0],
      produceTime      |-> [i \in 1 .. 8 |-> 0],
      consumeTime      |-> [i \in 1 .. 8 |-> 0],
      emm              |-> [i \in 1 .. 1 |-> 0],
      eventId          |-> [i \in 1 .. 8 |-> 0],
      eventTime        |-> [i \in 1 .. 8 |-> 0],
      priceType        |-> [i \in 1 .. 1 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      priceOptional    |-> [i \in 1 .. 8 |-> 0],
      quantityOptional |-> [i \in 1 .. 8 |-> 0],
      imbalanceQty     |-> [i \in 1 .. 8 |-> 0],
      imbalanceQtySide |-> [i \in 1 .. 1 |-> 0] ]

(* Dc Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedDcPriceUpdateMessage ==
    { ZeroDcPriceUpdateMessage }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.eventTime = one] : one \in Sample(8) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.quantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.imbalanceQty = one] : one \in Sample(8) }
        \cup { [ZeroDcPriceUpdateMessage EXCEPT !.imbalanceQtySide = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Order Free Text Section Group: 18 bytes                            *)
(***************************************************************************)

LongOrderFreeTextSectionGroup ==
    [ freeText : Sample(18) ]

EncodeLongOrderFreeTextSectionGroup(message) ==
    message.freeText

DecodeLongOrderFreeTextSectionGroup(bytes) ==
    LET freeText == ReadBytes(bytes, 18) IN IF ~freeText.ok THEN Fail ELSE
    Ok([ freeText |-> freeText.value ], freeText.rest)

ZeroLongOrderFreeTextSectionGroup ==
    [ freeText |-> [i \in 1 .. 18 |-> 0] ]

(* Long Order Free Text Section Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderFreeTextSectionGroup ==
    { ZeroLongOrderFreeTextSectionGroup }
        \cup { [ZeroLongOrderFreeTextSectionGroup EXCEPT !.freeText = one] : one \in Sample(18) }

(* A run of Long Order Free Text Section Group, written one after another *)
RECURSIVE EncodeLongOrderFreeTextSectionGroupList(_)
EncodeLongOrderFreeTextSectionGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderFreeTextSectionGroup(Head(messages)) \o EncodeLongOrderFreeTextSectionGroupList(Tail(messages))

(* As many Long Order Free Text Section Group as the field that counts them says *)
RECURSIVE ReadLongOrderFreeTextSectionGroupList(_, _)
ReadLongOrderFreeTextSectionGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderFreeTextSectionGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderFreeTextSectionGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Free Text Section Group of each kind, for the lists that carry them *)
OneLongOrderFreeTextSectionGroup == { ZeroLongOrderFreeTextSectionGroup }

(***************************************************************************)
(* Long Order Free Text Section Groups                                     *)
(***************************************************************************)

LongOrderFreeTextSectionGroups ==
    [ blockLengthShort              : Sample(1),
      longOrderFreeTextSectionGroup : SampleLists(OneLongOrderFreeTextSectionGroup) ]

EncodeLongOrderFreeTextSectionGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderFreeTextSectionGroup), 1)
        \o EncodeLongOrderFreeTextSectionGroupList(message.longOrderFreeTextSectionGroup)

DecodeLongOrderFreeTextSectionGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderFreeTextSectionGroup == ReadLongOrderFreeTextSectionGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderFreeTextSectionGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort              |-> blockLengthShort.value,
         longOrderFreeTextSectionGroup |-> longOrderFreeTextSectionGroup.value ], longOrderFreeTextSectionGroup.rest)

ZeroLongOrderFreeTextSectionGroups ==
    [ blockLengthShort              |-> [i \in 1 .. 1 |-> 0],
      longOrderFreeTextSectionGroup |-> << >> ]

(* Long Order Free Text Section Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderFreeTextSectionGroups ==
    { ZeroLongOrderFreeTextSectionGroups }
        \cup { [ZeroLongOrderFreeTextSectionGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderFreeTextSectionGroups EXCEPT !.longOrderFreeTextSectionGroup = one] : one \in SampleLists(OneLongOrderFreeTextSectionGroup) }

(***************************************************************************)
(* Long Order Optional Fields Group: 34 bytes                              *)
(***************************************************************************)

LongOrderOptionalFieldsGroup ==
    [ stopPx                   : Sample(8),
      pegOffset                : Sample(1),
      undisclosedPrice         : Sample(8),
      disclosedQty             : Sample(8),
      orderExpirationTime      : Sample(4),
      orderExpirationDate      : Sample(2),
      tradingSession           : Sample(1),
      stopTriggeredTimeInForce : Sample(1),
      undisclosedIcebergType   : Sample(1) ]

EncodeLongOrderOptionalFieldsGroup(message) ==
    message.stopPx
        \o message.pegOffset
        \o message.undisclosedPrice
        \o message.disclosedQty
        \o message.orderExpirationTime
        \o message.orderExpirationDate
        \o message.tradingSession
        \o message.stopTriggeredTimeInForce
        \o message.undisclosedIcebergType

DecodeLongOrderOptionalFieldsGroup(bytes) ==
    LET stopPx == ReadBytes(bytes, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET pegOffset == ReadBytes(stopPx.rest, 1) IN IF ~pegOffset.ok THEN Fail ELSE
    LET undisclosedPrice == ReadBytes(pegOffset.rest, 8) IN IF ~undisclosedPrice.ok THEN Fail ELSE
    LET disclosedQty == ReadBytes(undisclosedPrice.rest, 8) IN IF ~disclosedQty.ok THEN Fail ELSE
    LET orderExpirationTime == ReadBytes(disclosedQty.rest, 4) IN IF ~orderExpirationTime.ok THEN Fail ELSE
    LET orderExpirationDate == ReadBytes(orderExpirationTime.rest, 2) IN IF ~orderExpirationDate.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(orderExpirationDate.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    LET stopTriggeredTimeInForce == ReadBytes(tradingSession.rest, 1) IN IF ~stopTriggeredTimeInForce.ok THEN Fail ELSE
    LET undisclosedIcebergType == ReadBytes(stopTriggeredTimeInForce.rest, 1) IN IF ~undisclosedIcebergType.ok THEN Fail ELSE
    Ok([ stopPx                   |-> stopPx.value,
         pegOffset                |-> pegOffset.value,
         undisclosedPrice         |-> undisclosedPrice.value,
         disclosedQty             |-> disclosedQty.value,
         orderExpirationTime      |-> orderExpirationTime.value,
         orderExpirationDate      |-> orderExpirationDate.value,
         tradingSession           |-> tradingSession.value,
         stopTriggeredTimeInForce |-> stopTriggeredTimeInForce.value,
         undisclosedIcebergType   |-> undisclosedIcebergType.value ], undisclosedIcebergType.rest)

ZeroLongOrderOptionalFieldsGroup ==
    [ stopPx                   |-> [i \in 1 .. 8 |-> 0],
      pegOffset                |-> [i \in 1 .. 1 |-> 0],
      undisclosedPrice         |-> [i \in 1 .. 8 |-> 0],
      disclosedQty             |-> [i \in 1 .. 8 |-> 0],
      orderExpirationTime      |-> [i \in 1 .. 4 |-> 0],
      orderExpirationDate      |-> [i \in 1 .. 2 |-> 0],
      tradingSession           |-> [i \in 1 .. 1 |-> 0],
      stopTriggeredTimeInForce |-> [i \in 1 .. 1 |-> 0],
      undisclosedIcebergType   |-> [i \in 1 .. 1 |-> 0] ]

(* Long Order Optional Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderOptionalFieldsGroup ==
    { ZeroLongOrderOptionalFieldsGroup }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.pegOffset = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.undisclosedPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.disclosedQty = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.orderExpirationTime = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.orderExpirationDate = one] : one \in Sample(2) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.tradingSession = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.stopTriggeredTimeInForce = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderOptionalFieldsGroup EXCEPT !.undisclosedIcebergType = one] : one \in Sample(1) }

(* A run of Long Order Optional Fields Group, written one after another *)
RECURSIVE EncodeLongOrderOptionalFieldsGroupList(_)
EncodeLongOrderOptionalFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderOptionalFieldsGroup(Head(messages)) \o EncodeLongOrderOptionalFieldsGroupList(Tail(messages))

(* As many Long Order Optional Fields Group as the field that counts them says *)
RECURSIVE ReadLongOrderOptionalFieldsGroupList(_, _)
ReadLongOrderOptionalFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderOptionalFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderOptionalFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Optional Fields Group of each kind, for the lists that carry them *)
OneLongOrderOptionalFieldsGroup == { ZeroLongOrderOptionalFieldsGroup }

(***************************************************************************)
(* Long Order Optional Fields Groups                                       *)
(***************************************************************************)

LongOrderOptionalFieldsGroups ==
    [ blockLengthShort             : Sample(1),
      longOrderOptionalFieldsGroup : SampleLists(OneLongOrderOptionalFieldsGroup) ]

EncodeLongOrderOptionalFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderOptionalFieldsGroup), 1)
        \o EncodeLongOrderOptionalFieldsGroupList(message.longOrderOptionalFieldsGroup)

DecodeLongOrderOptionalFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderOptionalFieldsGroup == ReadLongOrderOptionalFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderOptionalFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort             |-> blockLengthShort.value,
         longOrderOptionalFieldsGroup |-> longOrderOptionalFieldsGroup.value ], longOrderOptionalFieldsGroup.rest)

ZeroLongOrderOptionalFieldsGroups ==
    [ blockLengthShort             |-> [i \in 1 .. 1 |-> 0],
      longOrderOptionalFieldsGroup |-> << >> ]

(* Long Order Optional Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderOptionalFieldsGroups ==
    { ZeroLongOrderOptionalFieldsGroups }
        \cup { [ZeroLongOrderOptionalFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderOptionalFieldsGroups EXCEPT !.longOrderOptionalFieldsGroup = one] : one \in SampleLists(OneLongOrderOptionalFieldsGroup) }

(***************************************************************************)
(* Long Order Clearing Fields Group: 33 bytes                              *)
(***************************************************************************)

LongOrderClearingFieldsGroup ==
    [ clearingFirmIdOptional      : Sample(8),
      clientId                    : Sample(8),
      accountNumber               : Sample(12),
      technicalOrigin             : Sample(1),
      openClose                   : Sample(2),
      clearingInstructionOptional : Sample(2) ]

EncodeLongOrderClearingFieldsGroup(message) ==
    message.clearingFirmIdOptional
        \o message.clientId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstructionOptional

DecodeLongOrderClearingFieldsGroup(bytes) ==
    LET clearingFirmIdOptional == ReadBytes(bytes, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET clientId == ReadBytes(clearingFirmIdOptional.rest, 8) IN IF ~clientId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(clientId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstructionOptional == ReadBytes(openClose.rest, 2) IN IF ~clearingInstructionOptional.ok THEN Fail ELSE
    Ok([ clearingFirmIdOptional      |-> clearingFirmIdOptional.value,
         clientId                    |-> clientId.value,
         accountNumber               |-> accountNumber.value,
         technicalOrigin             |-> technicalOrigin.value,
         openClose                   |-> openClose.value,
         clearingInstructionOptional |-> clearingInstructionOptional.value ], clearingInstructionOptional.rest)

ZeroLongOrderClearingFieldsGroup ==
    [ clearingFirmIdOptional      |-> [i \in 1 .. 8 |-> 0],
      clientId                    |-> [i \in 1 .. 8 |-> 0],
      accountNumber               |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin             |-> [i \in 1 .. 1 |-> 0],
      openClose                   |-> [i \in 1 .. 2 |-> 0],
      clearingInstructionOptional |-> [i \in 1 .. 2 |-> 0] ]

(* Long Order Clearing Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderClearingFieldsGroup ==
    { ZeroLongOrderClearingFieldsGroup }
        \cup { [ZeroLongOrderClearingFieldsGroup EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderClearingFieldsGroup EXCEPT !.clientId = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderClearingFieldsGroup EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroLongOrderClearingFieldsGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderClearingFieldsGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroLongOrderClearingFieldsGroup EXCEPT !.clearingInstructionOptional = one] : one \in Sample(2) }

(* A run of Long Order Clearing Fields Group, written one after another *)
RECURSIVE EncodeLongOrderClearingFieldsGroupList(_)
EncodeLongOrderClearingFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderClearingFieldsGroup(Head(messages)) \o EncodeLongOrderClearingFieldsGroupList(Tail(messages))

(* As many Long Order Clearing Fields Group as the field that counts them says *)
RECURSIVE ReadLongOrderClearingFieldsGroupList(_, _)
ReadLongOrderClearingFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderClearingFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderClearingFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Clearing Fields Group of each kind, for the lists that carry them *)
OneLongOrderClearingFieldsGroup == { ZeroLongOrderClearingFieldsGroup }

(***************************************************************************)
(* Long Order Clearing Fields Groups                                       *)
(***************************************************************************)

LongOrderClearingFieldsGroups ==
    [ blockLengthShort             : Sample(1),
      longOrderClearingFieldsGroup : SampleLists(OneLongOrderClearingFieldsGroup) ]

EncodeLongOrderClearingFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderClearingFieldsGroup), 1)
        \o EncodeLongOrderClearingFieldsGroupList(message.longOrderClearingFieldsGroup)

DecodeLongOrderClearingFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderClearingFieldsGroup == ReadLongOrderClearingFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderClearingFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort             |-> blockLengthShort.value,
         longOrderClearingFieldsGroup |-> longOrderClearingFieldsGroup.value ], longOrderClearingFieldsGroup.rest)

ZeroLongOrderClearingFieldsGroups ==
    [ blockLengthShort             |-> [i \in 1 .. 1 |-> 0],
      longOrderClearingFieldsGroup |-> << >> ]

(* Long Order Clearing Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderClearingFieldsGroups ==
    { ZeroLongOrderClearingFieldsGroups }
        \cup { [ZeroLongOrderClearingFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderClearingFieldsGroups EXCEPT !.longOrderClearingFieldsGroup = one] : one \in SampleLists(OneLongOrderClearingFieldsGroup) }

(***************************************************************************)
(* Long Order Non Modifiable Opt Fields Group: 10 bytes                    *)
(***************************************************************************)

LongOrderNonModifiableOptFieldsGroup ==
    [ tradingCapacityOptional : Sample(1),
      minimumOrderQuantity    : Sample(8),
      accountTypeCross        : Sample(1) ]

EncodeLongOrderNonModifiableOptFieldsGroup(message) ==
    message.tradingCapacityOptional
        \o message.minimumOrderQuantity
        \o message.accountTypeCross

DecodeLongOrderNonModifiableOptFieldsGroup(bytes) ==
    LET tradingCapacityOptional == ReadBytes(bytes, 1) IN IF ~tradingCapacityOptional.ok THEN Fail ELSE
    LET minimumOrderQuantity == ReadBytes(tradingCapacityOptional.rest, 8) IN IF ~minimumOrderQuantity.ok THEN Fail ELSE
    LET accountTypeCross == ReadBytes(minimumOrderQuantity.rest, 1) IN IF ~accountTypeCross.ok THEN Fail ELSE
    Ok([ tradingCapacityOptional |-> tradingCapacityOptional.value,
         minimumOrderQuantity    |-> minimumOrderQuantity.value,
         accountTypeCross        |-> accountTypeCross.value ], accountTypeCross.rest)

ZeroLongOrderNonModifiableOptFieldsGroup ==
    [ tradingCapacityOptional |-> [i \in 1 .. 1 |-> 0],
      minimumOrderQuantity    |-> [i \in 1 .. 8 |-> 0],
      accountTypeCross        |-> [i \in 1 .. 1 |-> 0] ]

(* Long Order Non Modifiable Opt Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderNonModifiableOptFieldsGroup ==
    { ZeroLongOrderNonModifiableOptFieldsGroup }
        \cup { [ZeroLongOrderNonModifiableOptFieldsGroup EXCEPT !.tradingCapacityOptional = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderNonModifiableOptFieldsGroup EXCEPT !.minimumOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderNonModifiableOptFieldsGroup EXCEPT !.accountTypeCross = one] : one \in Sample(1) }

(* A run of Long Order Non Modifiable Opt Fields Group, written one after another *)
RECURSIVE EncodeLongOrderNonModifiableOptFieldsGroupList(_)
EncodeLongOrderNonModifiableOptFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderNonModifiableOptFieldsGroup(Head(messages)) \o EncodeLongOrderNonModifiableOptFieldsGroupList(Tail(messages))

(* As many Long Order Non Modifiable Opt Fields Group as the field that counts them says *)
RECURSIVE ReadLongOrderNonModifiableOptFieldsGroupList(_, _)
ReadLongOrderNonModifiableOptFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderNonModifiableOptFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderNonModifiableOptFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Non Modifiable Opt Fields Group of each kind, for the lists that carry them *)
OneLongOrderNonModifiableOptFieldsGroup == { ZeroLongOrderNonModifiableOptFieldsGroup }

(***************************************************************************)
(* Long Order Non Modifiable Opt Fields Groups                             *)
(***************************************************************************)

LongOrderNonModifiableOptFieldsGroups ==
    [ blockLengthShort                     : Sample(1),
      longOrderNonModifiableOptFieldsGroup : SampleLists(OneLongOrderNonModifiableOptFieldsGroup) ]

EncodeLongOrderNonModifiableOptFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderNonModifiableOptFieldsGroup), 1)
        \o EncodeLongOrderNonModifiableOptFieldsGroupList(message.longOrderNonModifiableOptFieldsGroup)

DecodeLongOrderNonModifiableOptFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderNonModifiableOptFieldsGroup == ReadLongOrderNonModifiableOptFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderNonModifiableOptFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                     |-> blockLengthShort.value,
         longOrderNonModifiableOptFieldsGroup |-> longOrderNonModifiableOptFieldsGroup.value ], longOrderNonModifiableOptFieldsGroup.rest)

ZeroLongOrderNonModifiableOptFieldsGroups ==
    [ blockLengthShort                     |-> [i \in 1 .. 1 |-> 0],
      longOrderNonModifiableOptFieldsGroup |-> << >> ]

(* Long Order Non Modifiable Opt Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderNonModifiableOptFieldsGroups ==
    { ZeroLongOrderNonModifiableOptFieldsGroups }
        \cup { [ZeroLongOrderNonModifiableOptFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderNonModifiableOptFieldsGroups EXCEPT !.longOrderNonModifiableOptFieldsGroup = one] : one \in SampleLists(OneLongOrderNonModifiableOptFieldsGroup) }

(***************************************************************************)
(* Long Order Non Modifiable Short Codes Group: 16 bytes                   *)
(***************************************************************************)

LongOrderNonModifiableShortCodesGroup ==
    [ originalClientIdShortCode         : Sample(4),
      originalExecWFirmShortCode        : Sample(4),
      originalInvestDecisWFirmShortCode : Sample(4),
      originalNonExecBrokerShortCode    : Sample(4) ]

EncodeLongOrderNonModifiableShortCodesGroup(message) ==
    message.originalClientIdShortCode
        \o message.originalExecWFirmShortCode
        \o message.originalInvestDecisWFirmShortCode
        \o message.originalNonExecBrokerShortCode

DecodeLongOrderNonModifiableShortCodesGroup(bytes) ==
    LET originalClientIdShortCode == ReadBytes(bytes, 4) IN IF ~originalClientIdShortCode.ok THEN Fail ELSE
    LET originalExecWFirmShortCode == ReadBytes(originalClientIdShortCode.rest, 4) IN IF ~originalExecWFirmShortCode.ok THEN Fail ELSE
    LET originalInvestDecisWFirmShortCode == ReadBytes(originalExecWFirmShortCode.rest, 4) IN IF ~originalInvestDecisWFirmShortCode.ok THEN Fail ELSE
    LET originalNonExecBrokerShortCode == ReadBytes(originalInvestDecisWFirmShortCode.rest, 4) IN IF ~originalNonExecBrokerShortCode.ok THEN Fail ELSE
    Ok([ originalClientIdShortCode         |-> originalClientIdShortCode.value,
         originalExecWFirmShortCode        |-> originalExecWFirmShortCode.value,
         originalInvestDecisWFirmShortCode |-> originalInvestDecisWFirmShortCode.value,
         originalNonExecBrokerShortCode    |-> originalNonExecBrokerShortCode.value ], originalNonExecBrokerShortCode.rest)

ZeroLongOrderNonModifiableShortCodesGroup ==
    [ originalClientIdShortCode         |-> [i \in 1 .. 4 |-> 0],
      originalExecWFirmShortCode        |-> [i \in 1 .. 4 |-> 0],
      originalInvestDecisWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      originalNonExecBrokerShortCode    |-> [i \in 1 .. 4 |-> 0] ]

(* Long Order Non Modifiable Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderNonModifiableShortCodesGroup ==
    { ZeroLongOrderNonModifiableShortCodesGroup }
        \cup { [ZeroLongOrderNonModifiableShortCodesGroup EXCEPT !.originalClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderNonModifiableShortCodesGroup EXCEPT !.originalExecWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderNonModifiableShortCodesGroup EXCEPT !.originalInvestDecisWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderNonModifiableShortCodesGroup EXCEPT !.originalNonExecBrokerShortCode = one] : one \in Sample(4) }

(* A run of Long Order Non Modifiable Short Codes Group, written one after another *)
RECURSIVE EncodeLongOrderNonModifiableShortCodesGroupList(_)
EncodeLongOrderNonModifiableShortCodesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderNonModifiableShortCodesGroup(Head(messages)) \o EncodeLongOrderNonModifiableShortCodesGroupList(Tail(messages))

(* As many Long Order Non Modifiable Short Codes Group as the field that counts them says *)
RECURSIVE ReadLongOrderNonModifiableShortCodesGroupList(_, _)
ReadLongOrderNonModifiableShortCodesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderNonModifiableShortCodesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderNonModifiableShortCodesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Non Modifiable Short Codes Group of each kind, for the lists that carry them *)
OneLongOrderNonModifiableShortCodesGroup == { ZeroLongOrderNonModifiableShortCodesGroup }

(***************************************************************************)
(* Long Order Non Modifiable Short Codes Groups                            *)
(***************************************************************************)

LongOrderNonModifiableShortCodesGroups ==
    [ blockLengthShort                      : Sample(1),
      longOrderNonModifiableShortCodesGroup : SampleLists(OneLongOrderNonModifiableShortCodesGroup) ]

EncodeLongOrderNonModifiableShortCodesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderNonModifiableShortCodesGroup), 1)
        \o EncodeLongOrderNonModifiableShortCodesGroupList(message.longOrderNonModifiableShortCodesGroup)

DecodeLongOrderNonModifiableShortCodesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderNonModifiableShortCodesGroup == ReadLongOrderNonModifiableShortCodesGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderNonModifiableShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                      |-> blockLengthShort.value,
         longOrderNonModifiableShortCodesGroup |-> longOrderNonModifiableShortCodesGroup.value ], longOrderNonModifiableShortCodesGroup.rest)

ZeroLongOrderNonModifiableShortCodesGroups ==
    [ blockLengthShort                      |-> [i \in 1 .. 1 |-> 0],
      longOrderNonModifiableShortCodesGroup |-> << >> ]

(* Long Order Non Modifiable Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderNonModifiableShortCodesGroups ==
    { ZeroLongOrderNonModifiableShortCodesGroups }
        \cup { [ZeroLongOrderNonModifiableShortCodesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderNonModifiableShortCodesGroups EXCEPT !.longOrderNonModifiableShortCodesGroup = one] : one \in SampleLists(OneLongOrderNonModifiableShortCodesGroup) }

(***************************************************************************)
(* Long Order Modifiable Short Codes Group: 8 bytes                        *)
(***************************************************************************)

LongOrderModifiableShortCodesGroup ==
    [ eventClientIdShortCode  : Sample(4),
      eventExecWFirmShortCode : Sample(4) ]

EncodeLongOrderModifiableShortCodesGroup(message) ==
    message.eventClientIdShortCode
        \o message.eventExecWFirmShortCode

DecodeLongOrderModifiableShortCodesGroup(bytes) ==
    LET eventClientIdShortCode == ReadBytes(bytes, 4) IN IF ~eventClientIdShortCode.ok THEN Fail ELSE
    LET eventExecWFirmShortCode == ReadBytes(eventClientIdShortCode.rest, 4) IN IF ~eventExecWFirmShortCode.ok THEN Fail ELSE
    Ok([ eventClientIdShortCode  |-> eventClientIdShortCode.value,
         eventExecWFirmShortCode |-> eventExecWFirmShortCode.value ], eventExecWFirmShortCode.rest)

ZeroLongOrderModifiableShortCodesGroup ==
    [ eventClientIdShortCode  |-> [i \in 1 .. 4 |-> 0],
      eventExecWFirmShortCode |-> [i \in 1 .. 4 |-> 0] ]

(* Long Order Modifiable Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderModifiableShortCodesGroup ==
    { ZeroLongOrderModifiableShortCodesGroup }
        \cup { [ZeroLongOrderModifiableShortCodesGroup EXCEPT !.eventClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderModifiableShortCodesGroup EXCEPT !.eventExecWFirmShortCode = one] : one \in Sample(4) }

(* A run of Long Order Modifiable Short Codes Group, written one after another *)
RECURSIVE EncodeLongOrderModifiableShortCodesGroupList(_)
EncodeLongOrderModifiableShortCodesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderModifiableShortCodesGroup(Head(messages)) \o EncodeLongOrderModifiableShortCodesGroupList(Tail(messages))

(* As many Long Order Modifiable Short Codes Group as the field that counts them says *)
RECURSIVE ReadLongOrderModifiableShortCodesGroupList(_, _)
ReadLongOrderModifiableShortCodesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderModifiableShortCodesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderModifiableShortCodesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Modifiable Short Codes Group of each kind, for the lists that carry them *)
OneLongOrderModifiableShortCodesGroup == { ZeroLongOrderModifiableShortCodesGroup }

(***************************************************************************)
(* Long Order Modifiable Short Codes Groups                                *)
(***************************************************************************)

LongOrderModifiableShortCodesGroups ==
    [ blockLengthShort                   : Sample(1),
      longOrderModifiableShortCodesGroup : SampleLists(OneLongOrderModifiableShortCodesGroup) ]

EncodeLongOrderModifiableShortCodesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderModifiableShortCodesGroup), 1)
        \o EncodeLongOrderModifiableShortCodesGroupList(message.longOrderModifiableShortCodesGroup)

DecodeLongOrderModifiableShortCodesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderModifiableShortCodesGroup == ReadLongOrderModifiableShortCodesGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderModifiableShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                   |-> blockLengthShort.value,
         longOrderModifiableShortCodesGroup |-> longOrderModifiableShortCodesGroup.value ], longOrderModifiableShortCodesGroup.rest)

ZeroLongOrderModifiableShortCodesGroups ==
    [ blockLengthShort                   |-> [i \in 1 .. 1 |-> 0],
      longOrderModifiableShortCodesGroup |-> << >> ]

(* Long Order Modifiable Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderModifiableShortCodesGroups ==
    { ZeroLongOrderModifiableShortCodesGroups }
        \cup { [ZeroLongOrderModifiableShortCodesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderModifiableShortCodesGroups EXCEPT !.longOrderModifiableShortCodesGroup = one] : one \in SampleLists(OneLongOrderModifiableShortCodesGroup) }

(***************************************************************************)
(* Long Order Commercial Fields Group: 41 bytes                            *)
(***************************************************************************)

LongOrderCommercialFieldsGroup ==
    [ marketPhaseFlag   : Sample(1),
      marginTradingFlag : Sample(1),
      accessFlag        : Sample(1),
      traderId          : Sample(16),
      senderLocationId  : Sample(11),
      deskId            : Sample(11) ]

EncodeLongOrderCommercialFieldsGroup(message) ==
    message.marketPhaseFlag
        \o message.marginTradingFlag
        \o message.accessFlag
        \o message.traderId
        \o message.senderLocationId
        \o message.deskId

DecodeLongOrderCommercialFieldsGroup(bytes) ==
    LET marketPhaseFlag == ReadBytes(bytes, 1) IN IF ~marketPhaseFlag.ok THEN Fail ELSE
    LET marginTradingFlag == ReadBytes(marketPhaseFlag.rest, 1) IN IF ~marginTradingFlag.ok THEN Fail ELSE
    LET accessFlag == ReadBytes(marginTradingFlag.rest, 1) IN IF ~accessFlag.ok THEN Fail ELSE
    LET traderId == ReadBytes(accessFlag.rest, 16) IN IF ~traderId.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(traderId.rest, 11) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET deskId == ReadBytes(senderLocationId.rest, 11) IN IF ~deskId.ok THEN Fail ELSE
    Ok([ marketPhaseFlag   |-> marketPhaseFlag.value,
         marginTradingFlag |-> marginTradingFlag.value,
         accessFlag        |-> accessFlag.value,
         traderId          |-> traderId.value,
         senderLocationId  |-> senderLocationId.value,
         deskId            |-> deskId.value ], deskId.rest)

ZeroLongOrderCommercialFieldsGroup ==
    [ marketPhaseFlag   |-> [i \in 1 .. 1 |-> 0],
      marginTradingFlag |-> [i \in 1 .. 1 |-> 0],
      accessFlag        |-> [i \in 1 .. 1 |-> 0],
      traderId          |-> [i \in 1 .. 16 |-> 0],
      senderLocationId  |-> [i \in 1 .. 11 |-> 0],
      deskId            |-> [i \in 1 .. 11 |-> 0] ]

(* Long Order Commercial Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderCommercialFieldsGroup ==
    { ZeroLongOrderCommercialFieldsGroup }
        \cup { [ZeroLongOrderCommercialFieldsGroup EXCEPT !.marketPhaseFlag = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderCommercialFieldsGroup EXCEPT !.marginTradingFlag = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderCommercialFieldsGroup EXCEPT !.accessFlag = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderCommercialFieldsGroup EXCEPT !.traderId = one] : one \in Sample(16) }
        \cup { [ZeroLongOrderCommercialFieldsGroup EXCEPT !.senderLocationId = one] : one \in Sample(11) }
        \cup { [ZeroLongOrderCommercialFieldsGroup EXCEPT !.deskId = one] : one \in Sample(11) }

(* A run of Long Order Commercial Fields Group, written one after another *)
RECURSIVE EncodeLongOrderCommercialFieldsGroupList(_)
EncodeLongOrderCommercialFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderCommercialFieldsGroup(Head(messages)) \o EncodeLongOrderCommercialFieldsGroupList(Tail(messages))

(* As many Long Order Commercial Fields Group as the field that counts them says *)
RECURSIVE ReadLongOrderCommercialFieldsGroupList(_, _)
ReadLongOrderCommercialFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderCommercialFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderCommercialFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Commercial Fields Group of each kind, for the lists that carry them *)
OneLongOrderCommercialFieldsGroup == { ZeroLongOrderCommercialFieldsGroup }

(***************************************************************************)
(* Long Order Commercial Fields Groups                                     *)
(***************************************************************************)

LongOrderCommercialFieldsGroups ==
    [ blockLengthShort               : Sample(1),
      longOrderCommercialFieldsGroup : SampleLists(OneLongOrderCommercialFieldsGroup) ]

EncodeLongOrderCommercialFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderCommercialFieldsGroup), 1)
        \o EncodeLongOrderCommercialFieldsGroupList(message.longOrderCommercialFieldsGroup)

DecodeLongOrderCommercialFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderCommercialFieldsGroup == ReadLongOrderCommercialFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderCommercialFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort               |-> blockLengthShort.value,
         longOrderCommercialFieldsGroup |-> longOrderCommercialFieldsGroup.value ], longOrderCommercialFieldsGroup.rest)

ZeroLongOrderCommercialFieldsGroups ==
    [ blockLengthShort               |-> [i \in 1 .. 1 |-> 0],
      longOrderCommercialFieldsGroup |-> << >> ]

(* Long Order Commercial Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderCommercialFieldsGroups ==
    { ZeroLongOrderCommercialFieldsGroups }
        \cup { [ZeroLongOrderCommercialFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderCommercialFieldsGroups EXCEPT !.longOrderCommercialFieldsGroup = one] : one \in SampleLists(OneLongOrderCommercialFieldsGroup) }

(***************************************************************************)
(* Long Order Modifiable Commercial Investor Field Group: 16 bytes         *)
(***************************************************************************)

LongOrderModifiableCommercialInvestorFieldGroup ==
    [ eventInvestorId : Sample(16) ]

EncodeLongOrderModifiableCommercialInvestorFieldGroup(message) ==
    message.eventInvestorId

DecodeLongOrderModifiableCommercialInvestorFieldGroup(bytes) ==
    LET eventInvestorId == ReadBytes(bytes, 16) IN IF ~eventInvestorId.ok THEN Fail ELSE
    Ok([ eventInvestorId |-> eventInvestorId.value ], eventInvestorId.rest)

ZeroLongOrderModifiableCommercialInvestorFieldGroup ==
    [ eventInvestorId |-> [i \in 1 .. 16 |-> 0] ]

(* Long Order Modifiable Commercial Investor Field Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderModifiableCommercialInvestorFieldGroup ==
    { ZeroLongOrderModifiableCommercialInvestorFieldGroup }
        \cup { [ZeroLongOrderModifiableCommercialInvestorFieldGroup EXCEPT !.eventInvestorId = one] : one \in Sample(16) }

(* A run of Long Order Modifiable Commercial Investor Field Group, written one after another *)
RECURSIVE EncodeLongOrderModifiableCommercialInvestorFieldGroupList(_)
EncodeLongOrderModifiableCommercialInvestorFieldGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderModifiableCommercialInvestorFieldGroup(Head(messages)) \o EncodeLongOrderModifiableCommercialInvestorFieldGroupList(Tail(messages))

(* As many Long Order Modifiable Commercial Investor Field Group as the field that counts them says *)
RECURSIVE ReadLongOrderModifiableCommercialInvestorFieldGroupList(_, _)
ReadLongOrderModifiableCommercialInvestorFieldGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderModifiableCommercialInvestorFieldGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderModifiableCommercialInvestorFieldGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Modifiable Commercial Investor Field Group of each kind, for the lists that carry them *)
OneLongOrderModifiableCommercialInvestorFieldGroup == { ZeroLongOrderModifiableCommercialInvestorFieldGroup }

(***************************************************************************)
(* Long Order Modifiable Commercial Investor Field Groups                  *)
(***************************************************************************)

LongOrderModifiableCommercialInvestorFieldGroups ==
    [ blockLengthShort                                : Sample(1),
      longOrderModifiableCommercialInvestorFieldGroup : SampleLists(OneLongOrderModifiableCommercialInvestorFieldGroup) ]

EncodeLongOrderModifiableCommercialInvestorFieldGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderModifiableCommercialInvestorFieldGroup), 1)
        \o EncodeLongOrderModifiableCommercialInvestorFieldGroupList(message.longOrderModifiableCommercialInvestorFieldGroup)

DecodeLongOrderModifiableCommercialInvestorFieldGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderModifiableCommercialInvestorFieldGroup == ReadLongOrderModifiableCommercialInvestorFieldGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderModifiableCommercialInvestorFieldGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                |-> blockLengthShort.value,
         longOrderModifiableCommercialInvestorFieldGroup |-> longOrderModifiableCommercialInvestorFieldGroup.value ], longOrderModifiableCommercialInvestorFieldGroup.rest)

ZeroLongOrderModifiableCommercialInvestorFieldGroups ==
    [ blockLengthShort                                |-> [i \in 1 .. 1 |-> 0],
      longOrderModifiableCommercialInvestorFieldGroup |-> << >> ]

(* Long Order Modifiable Commercial Investor Field Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderModifiableCommercialInvestorFieldGroups ==
    { ZeroLongOrderModifiableCommercialInvestorFieldGroups }
        \cup { [ZeroLongOrderModifiableCommercialInvestorFieldGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderModifiableCommercialInvestorFieldGroups EXCEPT !.longOrderModifiableCommercialInvestorFieldGroup = one] : one \in SampleLists(OneLongOrderModifiableCommercialInvestorFieldGroup) }

(***************************************************************************)
(* Long Order Non Modifiable Commercial Investor Field Group: 16 bytes     *)
(***************************************************************************)

LongOrderNonModifiableCommercialInvestorFieldGroup ==
    [ originalInvestorId : Sample(16) ]

EncodeLongOrderNonModifiableCommercialInvestorFieldGroup(message) ==
    message.originalInvestorId

DecodeLongOrderNonModifiableCommercialInvestorFieldGroup(bytes) ==
    LET originalInvestorId == ReadBytes(bytes, 16) IN IF ~originalInvestorId.ok THEN Fail ELSE
    Ok([ originalInvestorId |-> originalInvestorId.value ], originalInvestorId.rest)

ZeroLongOrderNonModifiableCommercialInvestorFieldGroup ==
    [ originalInvestorId |-> [i \in 1 .. 16 |-> 0] ]

(* Long Order Non Modifiable Commercial Investor Field Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderNonModifiableCommercialInvestorFieldGroup ==
    { ZeroLongOrderNonModifiableCommercialInvestorFieldGroup }
        \cup { [ZeroLongOrderNonModifiableCommercialInvestorFieldGroup EXCEPT !.originalInvestorId = one] : one \in Sample(16) }

(* A run of Long Order Non Modifiable Commercial Investor Field Group, written one after another *)
RECURSIVE EncodeLongOrderNonModifiableCommercialInvestorFieldGroupList(_)
EncodeLongOrderNonModifiableCommercialInvestorFieldGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderNonModifiableCommercialInvestorFieldGroup(Head(messages)) \o EncodeLongOrderNonModifiableCommercialInvestorFieldGroupList(Tail(messages))

(* As many Long Order Non Modifiable Commercial Investor Field Group as the field that counts them says *)
RECURSIVE ReadLongOrderNonModifiableCommercialInvestorFieldGroupList(_, _)
ReadLongOrderNonModifiableCommercialInvestorFieldGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderNonModifiableCommercialInvestorFieldGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderNonModifiableCommercialInvestorFieldGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Non Modifiable Commercial Investor Field Group of each kind, for the lists that carry them *)
OneLongOrderNonModifiableCommercialInvestorFieldGroup == { ZeroLongOrderNonModifiableCommercialInvestorFieldGroup }

(***************************************************************************)
(* Long Order Non Modifiable Commercial Investor Field Groups              *)
(***************************************************************************)

LongOrderNonModifiableCommercialInvestorFieldGroups ==
    [ blockLengthShort                                   : Sample(1),
      longOrderNonModifiableCommercialInvestorFieldGroup : SampleLists(OneLongOrderNonModifiableCommercialInvestorFieldGroup) ]

EncodeLongOrderNonModifiableCommercialInvestorFieldGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderNonModifiableCommercialInvestorFieldGroup), 1)
        \o EncodeLongOrderNonModifiableCommercialInvestorFieldGroupList(message.longOrderNonModifiableCommercialInvestorFieldGroup)

DecodeLongOrderNonModifiableCommercialInvestorFieldGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderNonModifiableCommercialInvestorFieldGroup == ReadLongOrderNonModifiableCommercialInvestorFieldGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderNonModifiableCommercialInvestorFieldGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                   |-> blockLengthShort.value,
         longOrderNonModifiableCommercialInvestorFieldGroup |-> longOrderNonModifiableCommercialInvestorFieldGroup.value ], longOrderNonModifiableCommercialInvestorFieldGroup.rest)

ZeroLongOrderNonModifiableCommercialInvestorFieldGroups ==
    [ blockLengthShort                                   |-> [i \in 1 .. 1 |-> 0],
      longOrderNonModifiableCommercialInvestorFieldGroup |-> << >> ]

(* Long Order Non Modifiable Commercial Investor Field Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderNonModifiableCommercialInvestorFieldGroups ==
    { ZeroLongOrderNonModifiableCommercialInvestorFieldGroups }
        \cup { [ZeroLongOrderNonModifiableCommercialInvestorFieldGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderNonModifiableCommercialInvestorFieldGroups EXCEPT !.longOrderNonModifiableCommercialInvestorFieldGroup = one] : one \in SampleLists(OneLongOrderNonModifiableCommercialInvestorFieldGroup) }

(***************************************************************************)
(* Long Order Extended Clearing Account Group: 16 bytes                    *)
(***************************************************************************)

LongOrderExtendedClearingAccountGroup ==
    [ clearingAccount : Sample(16) ]

EncodeLongOrderExtendedClearingAccountGroup(message) ==
    message.clearingAccount

DecodeLongOrderExtendedClearingAccountGroup(bytes) ==
    LET clearingAccount == ReadBytes(bytes, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    Ok([ clearingAccount |-> clearingAccount.value ], clearingAccount.rest)

ZeroLongOrderExtendedClearingAccountGroup ==
    [ clearingAccount |-> [i \in 1 .. 16 |-> 0] ]

(* Long Order Extended Clearing Account Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderExtendedClearingAccountGroup ==
    { ZeroLongOrderExtendedClearingAccountGroup }
        \cup { [ZeroLongOrderExtendedClearingAccountGroup EXCEPT !.clearingAccount = one] : one \in Sample(16) }

(* A run of Long Order Extended Clearing Account Group, written one after another *)
RECURSIVE EncodeLongOrderExtendedClearingAccountGroupList(_)
EncodeLongOrderExtendedClearingAccountGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderExtendedClearingAccountGroup(Head(messages)) \o EncodeLongOrderExtendedClearingAccountGroupList(Tail(messages))

(* As many Long Order Extended Clearing Account Group as the field that counts them says *)
RECURSIVE ReadLongOrderExtendedClearingAccountGroupList(_, _)
ReadLongOrderExtendedClearingAccountGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderExtendedClearingAccountGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderExtendedClearingAccountGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Extended Clearing Account Group of each kind, for the lists that carry them *)
OneLongOrderExtendedClearingAccountGroup == { ZeroLongOrderExtendedClearingAccountGroup }

(***************************************************************************)
(* Long Order Extended Clearing Account Groups                             *)
(***************************************************************************)

LongOrderExtendedClearingAccountGroups ==
    [ blockLengthShort                      : Sample(1),
      longOrderExtendedClearingAccountGroup : SampleLists(OneLongOrderExtendedClearingAccountGroup) ]

EncodeLongOrderExtendedClearingAccountGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderExtendedClearingAccountGroup), 1)
        \o EncodeLongOrderExtendedClearingAccountGroupList(message.longOrderExtendedClearingAccountGroup)

DecodeLongOrderExtendedClearingAccountGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderExtendedClearingAccountGroup == ReadLongOrderExtendedClearingAccountGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderExtendedClearingAccountGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                      |-> blockLengthShort.value,
         longOrderExtendedClearingAccountGroup |-> longOrderExtendedClearingAccountGroup.value ], longOrderExtendedClearingAccountGroup.rest)

ZeroLongOrderExtendedClearingAccountGroups ==
    [ blockLengthShort                      |-> [i \in 1 .. 1 |-> 0],
      longOrderExtendedClearingAccountGroup |-> << >> ]

(* Long Order Extended Clearing Account Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderExtendedClearingAccountGroups ==
    { ZeroLongOrderExtendedClearingAccountGroups }
        \cup { [ZeroLongOrderExtendedClearingAccountGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderExtendedClearingAccountGroups EXCEPT !.longOrderExtendedClearingAccountGroup = one] : one \in SampleLists(OneLongOrderExtendedClearingAccountGroup) }

(***************************************************************************)
(* Long Order Strategy Fields Group: 41 bytes                              *)
(***************************************************************************)

LongOrderStrategyFieldsGroup ==
    [ legLastPx             : Sample(8),
      legLastQty            : Sample(8),
      legInstrumentId       : Sample(4),
      legSide               : Sample(1),
      executionIdOptional   : Sample(4),
      tradeUniqueIdentifier : Sample(16) ]

EncodeLongOrderStrategyFieldsGroup(message) ==
    message.legLastPx
        \o message.legLastQty
        \o message.legInstrumentId
        \o message.legSide
        \o message.executionIdOptional
        \o message.tradeUniqueIdentifier

DecodeLongOrderStrategyFieldsGroup(bytes) ==
    LET legLastPx == ReadBytes(bytes, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 8) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(legLastQty.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legInstrumentId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET executionIdOptional == ReadBytes(legSide.rest, 4) IN IF ~executionIdOptional.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(executionIdOptional.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    Ok([ legLastPx             |-> legLastPx.value,
         legLastQty            |-> legLastQty.value,
         legInstrumentId       |-> legInstrumentId.value,
         legSide               |-> legSide.value,
         executionIdOptional   |-> executionIdOptional.value,
         tradeUniqueIdentifier |-> tradeUniqueIdentifier.value ], tradeUniqueIdentifier.rest)

ZeroLongOrderStrategyFieldsGroup ==
    [ legLastPx             |-> [i \in 1 .. 8 |-> 0],
      legLastQty            |-> [i \in 1 .. 8 |-> 0],
      legInstrumentId       |-> [i \in 1 .. 4 |-> 0],
      legSide               |-> [i \in 1 .. 1 |-> 0],
      executionIdOptional   |-> [i \in 1 .. 4 |-> 0],
      tradeUniqueIdentifier |-> [i \in 1 .. 16 |-> 0] ]

(* Long Order Strategy Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderStrategyFieldsGroup ==
    { ZeroLongOrderStrategyFieldsGroup }
        \cup { [ZeroLongOrderStrategyFieldsGroup EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderStrategyFieldsGroup EXCEPT !.legLastQty = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderStrategyFieldsGroup EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderStrategyFieldsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderStrategyFieldsGroup EXCEPT !.executionIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderStrategyFieldsGroup EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }

(* A run of Long Order Strategy Fields Group, written one after another *)
RECURSIVE EncodeLongOrderStrategyFieldsGroupList(_)
EncodeLongOrderStrategyFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderStrategyFieldsGroup(Head(messages)) \o EncodeLongOrderStrategyFieldsGroupList(Tail(messages))

(* As many Long Order Strategy Fields Group as the field that counts them says *)
RECURSIVE ReadLongOrderStrategyFieldsGroupList(_, _)
ReadLongOrderStrategyFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderStrategyFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderStrategyFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Strategy Fields Group of each kind, for the lists that carry them *)
OneLongOrderStrategyFieldsGroup == { ZeroLongOrderStrategyFieldsGroup }

(***************************************************************************)
(* Long Order Strategy Fields Groups                                       *)
(***************************************************************************)

LongOrderStrategyFieldsGroups ==
    [ blockLengthShort             : Sample(1),
      longOrderStrategyFieldsGroup : SampleLists(OneLongOrderStrategyFieldsGroup) ]

EncodeLongOrderStrategyFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderStrategyFieldsGroup), 1)
        \o EncodeLongOrderStrategyFieldsGroupList(message.longOrderStrategyFieldsGroup)

DecodeLongOrderStrategyFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderStrategyFieldsGroup == ReadLongOrderStrategyFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderStrategyFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort             |-> blockLengthShort.value,
         longOrderStrategyFieldsGroup |-> longOrderStrategyFieldsGroup.value ], longOrderStrategyFieldsGroup.rest)

ZeroLongOrderStrategyFieldsGroups ==
    [ blockLengthShort             |-> [i \in 1 .. 1 |-> 0],
      longOrderStrategyFieldsGroup |-> << >> ]

(* Long Order Strategy Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderStrategyFieldsGroups ==
    { ZeroLongOrderStrategyFieldsGroups }
        \cup { [ZeroLongOrderStrategyFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderStrategyFieldsGroups EXCEPT !.longOrderStrategyFieldsGroup = one] : one \in SampleLists(OneLongOrderStrategyFieldsGroup) }

(***************************************************************************)
(* Long Order Optional Fields Derivatives Group: 17 bytes                  *)
(***************************************************************************)

LongOrderOptionalFieldsDerivativesGroup ==
    [ evaluatedPrice       : Sample(8),
      messagePriceNotation : Sample(1),
      finalSymbolIndex     : Sample(4),
      finalExecutionId     : Sample(4) ]

EncodeLongOrderOptionalFieldsDerivativesGroup(message) ==
    message.evaluatedPrice
        \o message.messagePriceNotation
        \o message.finalSymbolIndex
        \o message.finalExecutionId

DecodeLongOrderOptionalFieldsDerivativesGroup(bytes) ==
    LET evaluatedPrice == ReadBytes(bytes, 8) IN IF ~evaluatedPrice.ok THEN Fail ELSE
    LET messagePriceNotation == ReadBytes(evaluatedPrice.rest, 1) IN IF ~messagePriceNotation.ok THEN Fail ELSE
    LET finalSymbolIndex == ReadBytes(messagePriceNotation.rest, 4) IN IF ~finalSymbolIndex.ok THEN Fail ELSE
    LET finalExecutionId == ReadBytes(finalSymbolIndex.rest, 4) IN IF ~finalExecutionId.ok THEN Fail ELSE
    Ok([ evaluatedPrice       |-> evaluatedPrice.value,
         messagePriceNotation |-> messagePriceNotation.value,
         finalSymbolIndex     |-> finalSymbolIndex.value,
         finalExecutionId     |-> finalExecutionId.value ], finalExecutionId.rest)

ZeroLongOrderOptionalFieldsDerivativesGroup ==
    [ evaluatedPrice       |-> [i \in 1 .. 8 |-> 0],
      messagePriceNotation |-> [i \in 1 .. 1 |-> 0],
      finalSymbolIndex     |-> [i \in 1 .. 4 |-> 0],
      finalExecutionId     |-> [i \in 1 .. 4 |-> 0] ]

(* Long Order Optional Fields Derivatives Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderOptionalFieldsDerivativesGroup ==
    { ZeroLongOrderOptionalFieldsDerivativesGroup }
        \cup { [ZeroLongOrderOptionalFieldsDerivativesGroup EXCEPT !.evaluatedPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderOptionalFieldsDerivativesGroup EXCEPT !.messagePriceNotation = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderOptionalFieldsDerivativesGroup EXCEPT !.finalSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderOptionalFieldsDerivativesGroup EXCEPT !.finalExecutionId = one] : one \in Sample(4) }

(* A run of Long Order Optional Fields Derivatives Group, written one after another *)
RECURSIVE EncodeLongOrderOptionalFieldsDerivativesGroupList(_)
EncodeLongOrderOptionalFieldsDerivativesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderOptionalFieldsDerivativesGroup(Head(messages)) \o EncodeLongOrderOptionalFieldsDerivativesGroupList(Tail(messages))

(* As many Long Order Optional Fields Derivatives Group as the field that counts them says *)
RECURSIVE ReadLongOrderOptionalFieldsDerivativesGroupList(_, _)
ReadLongOrderOptionalFieldsDerivativesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderOptionalFieldsDerivativesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderOptionalFieldsDerivativesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Optional Fields Derivatives Group of each kind, for the lists that carry them *)
OneLongOrderOptionalFieldsDerivativesGroup == { ZeroLongOrderOptionalFieldsDerivativesGroup }

(***************************************************************************)
(* Long Order Optional Fields Derivatives Groups                           *)
(***************************************************************************)

LongOrderOptionalFieldsDerivativesGroups ==
    [ blockLengthShort                        : Sample(1),
      longOrderOptionalFieldsDerivativesGroup : SampleLists(OneLongOrderOptionalFieldsDerivativesGroup) ]

EncodeLongOrderOptionalFieldsDerivativesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderOptionalFieldsDerivativesGroup), 1)
        \o EncodeLongOrderOptionalFieldsDerivativesGroupList(message.longOrderOptionalFieldsDerivativesGroup)

DecodeLongOrderOptionalFieldsDerivativesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderOptionalFieldsDerivativesGroup == ReadLongOrderOptionalFieldsDerivativesGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderOptionalFieldsDerivativesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                        |-> blockLengthShort.value,
         longOrderOptionalFieldsDerivativesGroup |-> longOrderOptionalFieldsDerivativesGroup.value ], longOrderOptionalFieldsDerivativesGroup.rest)

ZeroLongOrderOptionalFieldsDerivativesGroups ==
    [ blockLengthShort                        |-> [i \in 1 .. 1 |-> 0],
      longOrderOptionalFieldsDerivativesGroup |-> << >> ]

(* Long Order Optional Fields Derivatives Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderOptionalFieldsDerivativesGroups ==
    { ZeroLongOrderOptionalFieldsDerivativesGroups }
        \cup { [ZeroLongOrderOptionalFieldsDerivativesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderOptionalFieldsDerivativesGroups EXCEPT !.longOrderOptionalFieldsDerivativesGroup = one] : one \in SampleLists(OneLongOrderOptionalFieldsDerivativesGroup) }

(***************************************************************************)
(* Long Order Additional Infos Group: 16 bytes                             *)
(***************************************************************************)

LongOrderAdditionalInfosGroup ==
    [ longClientId : Sample(16) ]

EncodeLongOrderAdditionalInfosGroup(message) ==
    message.longClientId

DecodeLongOrderAdditionalInfosGroup(bytes) ==
    LET longClientId == ReadBytes(bytes, 16) IN IF ~longClientId.ok THEN Fail ELSE
    Ok([ longClientId |-> longClientId.value ], longClientId.rest)

ZeroLongOrderAdditionalInfosGroup ==
    [ longClientId |-> [i \in 1 .. 16 |-> 0] ]

(* Long Order Additional Infos Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderAdditionalInfosGroup ==
    { ZeroLongOrderAdditionalInfosGroup }
        \cup { [ZeroLongOrderAdditionalInfosGroup EXCEPT !.longClientId = one] : one \in Sample(16) }

(* A run of Long Order Additional Infos Group, written one after another *)
RECURSIVE EncodeLongOrderAdditionalInfosGroupList(_)
EncodeLongOrderAdditionalInfosGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderAdditionalInfosGroup(Head(messages)) \o EncodeLongOrderAdditionalInfosGroupList(Tail(messages))

(* As many Long Order Additional Infos Group as the field that counts them says *)
RECURSIVE ReadLongOrderAdditionalInfosGroupList(_, _)
ReadLongOrderAdditionalInfosGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderAdditionalInfosGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderAdditionalInfosGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Additional Infos Group of each kind, for the lists that carry them *)
OneLongOrderAdditionalInfosGroup == { ZeroLongOrderAdditionalInfosGroup }

(***************************************************************************)
(* Long Order Additional Infos Groups                                      *)
(***************************************************************************)

LongOrderAdditionalInfosGroups ==
    [ blockLengthShort              : Sample(1),
      longOrderAdditionalInfosGroup : SampleLists(OneLongOrderAdditionalInfosGroup) ]

EncodeLongOrderAdditionalInfosGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderAdditionalInfosGroup), 1)
        \o EncodeLongOrderAdditionalInfosGroupList(message.longOrderAdditionalInfosGroup)

DecodeLongOrderAdditionalInfosGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderAdditionalInfosGroup == ReadLongOrderAdditionalInfosGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderAdditionalInfosGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort              |-> blockLengthShort.value,
         longOrderAdditionalInfosGroup |-> longOrderAdditionalInfosGroup.value ], longOrderAdditionalInfosGroup.rest)

ZeroLongOrderAdditionalInfosGroups ==
    [ blockLengthShort              |-> [i \in 1 .. 1 |-> 0],
      longOrderAdditionalInfosGroup |-> << >> ]

(* Long Order Additional Infos Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderAdditionalInfosGroups ==
    { ZeroLongOrderAdditionalInfosGroups }
        \cup { [ZeroLongOrderAdditionalInfosGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderAdditionalInfosGroups EXCEPT !.longOrderAdditionalInfosGroup = one] : one \in SampleLists(OneLongOrderAdditionalInfosGroup) }

(***************************************************************************)
(* Long Order Short Codes Details Non Modifiable Group: 3 bytes            *)
(***************************************************************************)

LongOrderShortCodesDetailsNonModifiableGroup ==
    [ originalShortCodeType  : Sample(1),
      shortCodeRole          : Sample(1),
      shortCodeRoleQualifier : Sample(1) ]

EncodeLongOrderShortCodesDetailsNonModifiableGroup(message) ==
    message.originalShortCodeType
        \o message.shortCodeRole
        \o message.shortCodeRoleQualifier

DecodeLongOrderShortCodesDetailsNonModifiableGroup(bytes) ==
    LET originalShortCodeType == ReadBytes(bytes, 1) IN IF ~originalShortCodeType.ok THEN Fail ELSE
    LET shortCodeRole == ReadBytes(originalShortCodeType.rest, 1) IN IF ~shortCodeRole.ok THEN Fail ELSE
    LET shortCodeRoleQualifier == ReadBytes(shortCodeRole.rest, 1) IN IF ~shortCodeRoleQualifier.ok THEN Fail ELSE
    Ok([ originalShortCodeType  |-> originalShortCodeType.value,
         shortCodeRole          |-> shortCodeRole.value,
         shortCodeRoleQualifier |-> shortCodeRoleQualifier.value ], shortCodeRoleQualifier.rest)

ZeroLongOrderShortCodesDetailsNonModifiableGroup ==
    [ originalShortCodeType  |-> [i \in 1 .. 1 |-> 0],
      shortCodeRole          |-> [i \in 1 .. 1 |-> 0],
      shortCodeRoleQualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Long Order Short Codes Details Non Modifiable Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderShortCodesDetailsNonModifiableGroup ==
    { ZeroLongOrderShortCodesDetailsNonModifiableGroup }
        \cup { [ZeroLongOrderShortCodesDetailsNonModifiableGroup EXCEPT !.originalShortCodeType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderShortCodesDetailsNonModifiableGroup EXCEPT !.shortCodeRole = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderShortCodesDetailsNonModifiableGroup EXCEPT !.shortCodeRoleQualifier = one] : one \in Sample(1) }

(* A run of Long Order Short Codes Details Non Modifiable Group, written one after another *)
RECURSIVE EncodeLongOrderShortCodesDetailsNonModifiableGroupList(_)
EncodeLongOrderShortCodesDetailsNonModifiableGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderShortCodesDetailsNonModifiableGroup(Head(messages)) \o EncodeLongOrderShortCodesDetailsNonModifiableGroupList(Tail(messages))

(* As many Long Order Short Codes Details Non Modifiable Group as the field that counts them says *)
RECURSIVE ReadLongOrderShortCodesDetailsNonModifiableGroupList(_, _)
ReadLongOrderShortCodesDetailsNonModifiableGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderShortCodesDetailsNonModifiableGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderShortCodesDetailsNonModifiableGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Short Codes Details Non Modifiable Group of each kind, for the lists that carry them *)
OneLongOrderShortCodesDetailsNonModifiableGroup == { ZeroLongOrderShortCodesDetailsNonModifiableGroup }

(***************************************************************************)
(* Long Order Short Codes Details Non Modifiable Groups                    *)
(***************************************************************************)

LongOrderShortCodesDetailsNonModifiableGroups ==
    [ blockLengthShort                             : Sample(1),
      longOrderShortCodesDetailsNonModifiableGroup : SampleLists(OneLongOrderShortCodesDetailsNonModifiableGroup) ]

EncodeLongOrderShortCodesDetailsNonModifiableGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderShortCodesDetailsNonModifiableGroup), 1)
        \o EncodeLongOrderShortCodesDetailsNonModifiableGroupList(message.longOrderShortCodesDetailsNonModifiableGroup)

DecodeLongOrderShortCodesDetailsNonModifiableGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderShortCodesDetailsNonModifiableGroup == ReadLongOrderShortCodesDetailsNonModifiableGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderShortCodesDetailsNonModifiableGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                             |-> blockLengthShort.value,
         longOrderShortCodesDetailsNonModifiableGroup |-> longOrderShortCodesDetailsNonModifiableGroup.value ], longOrderShortCodesDetailsNonModifiableGroup.rest)

ZeroLongOrderShortCodesDetailsNonModifiableGroups ==
    [ blockLengthShort                             |-> [i \in 1 .. 1 |-> 0],
      longOrderShortCodesDetailsNonModifiableGroup |-> << >> ]

(* Long Order Short Codes Details Non Modifiable Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderShortCodesDetailsNonModifiableGroups ==
    { ZeroLongOrderShortCodesDetailsNonModifiableGroups }
        \cup { [ZeroLongOrderShortCodesDetailsNonModifiableGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderShortCodesDetailsNonModifiableGroups EXCEPT !.longOrderShortCodesDetailsNonModifiableGroup = one] : one \in SampleLists(OneLongOrderShortCodesDetailsNonModifiableGroup) }

(***************************************************************************)
(* Long Order Short Codes Details Modifiable Group: 3 bytes                *)
(***************************************************************************)

LongOrderShortCodesDetailsModifiableGroup ==
    [ eventShortCodeType     : Sample(1),
      shortCodeRole          : Sample(1),
      shortCodeRoleQualifier : Sample(1) ]

EncodeLongOrderShortCodesDetailsModifiableGroup(message) ==
    message.eventShortCodeType
        \o message.shortCodeRole
        \o message.shortCodeRoleQualifier

DecodeLongOrderShortCodesDetailsModifiableGroup(bytes) ==
    LET eventShortCodeType == ReadBytes(bytes, 1) IN IF ~eventShortCodeType.ok THEN Fail ELSE
    LET shortCodeRole == ReadBytes(eventShortCodeType.rest, 1) IN IF ~shortCodeRole.ok THEN Fail ELSE
    LET shortCodeRoleQualifier == ReadBytes(shortCodeRole.rest, 1) IN IF ~shortCodeRoleQualifier.ok THEN Fail ELSE
    Ok([ eventShortCodeType     |-> eventShortCodeType.value,
         shortCodeRole          |-> shortCodeRole.value,
         shortCodeRoleQualifier |-> shortCodeRoleQualifier.value ], shortCodeRoleQualifier.rest)

ZeroLongOrderShortCodesDetailsModifiableGroup ==
    [ eventShortCodeType     |-> [i \in 1 .. 1 |-> 0],
      shortCodeRole          |-> [i \in 1 .. 1 |-> 0],
      shortCodeRoleQualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Long Order Short Codes Details Modifiable Group at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderShortCodesDetailsModifiableGroup ==
    { ZeroLongOrderShortCodesDetailsModifiableGroup }
        \cup { [ZeroLongOrderShortCodesDetailsModifiableGroup EXCEPT !.eventShortCodeType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderShortCodesDetailsModifiableGroup EXCEPT !.shortCodeRole = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderShortCodesDetailsModifiableGroup EXCEPT !.shortCodeRoleQualifier = one] : one \in Sample(1) }

(* A run of Long Order Short Codes Details Modifiable Group, written one after another *)
RECURSIVE EncodeLongOrderShortCodesDetailsModifiableGroupList(_)
EncodeLongOrderShortCodesDetailsModifiableGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongOrderShortCodesDetailsModifiableGroup(Head(messages)) \o EncodeLongOrderShortCodesDetailsModifiableGroupList(Tail(messages))

(* As many Long Order Short Codes Details Modifiable Group as the field that counts them says *)
RECURSIVE ReadLongOrderShortCodesDetailsModifiableGroupList(_, _)
ReadLongOrderShortCodesDetailsModifiableGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongOrderShortCodesDetailsModifiableGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongOrderShortCodesDetailsModifiableGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Order Short Codes Details Modifiable Group of each kind, for the lists that carry them *)
OneLongOrderShortCodesDetailsModifiableGroup == { ZeroLongOrderShortCodesDetailsModifiableGroup }

(***************************************************************************)
(* Long Order Short Codes Details Modifiable Groups                        *)
(***************************************************************************)

LongOrderShortCodesDetailsModifiableGroups ==
    [ blockLengthShort                          : Sample(1),
      longOrderShortCodesDetailsModifiableGroup : SampleLists(OneLongOrderShortCodesDetailsModifiableGroup) ]

EncodeLongOrderShortCodesDetailsModifiableGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.longOrderShortCodesDetailsModifiableGroup), 1)
        \o EncodeLongOrderShortCodesDetailsModifiableGroupList(message.longOrderShortCodesDetailsModifiableGroup)

DecodeLongOrderShortCodesDetailsModifiableGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET longOrderShortCodesDetailsModifiableGroup == ReadLongOrderShortCodesDetailsModifiableGroupList(numInGroup.rest, numInGroup.value) IN IF ~longOrderShortCodesDetailsModifiableGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                          |-> blockLengthShort.value,
         longOrderShortCodesDetailsModifiableGroup |-> longOrderShortCodesDetailsModifiableGroup.value ], longOrderShortCodesDetailsModifiableGroup.rest)

ZeroLongOrderShortCodesDetailsModifiableGroups ==
    [ blockLengthShort                          |-> [i \in 1 .. 1 |-> 0],
      longOrderShortCodesDetailsModifiableGroup |-> << >> ]

(* Long Order Short Codes Details Modifiable Groups at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderShortCodesDetailsModifiableGroups ==
    { ZeroLongOrderShortCodesDetailsModifiableGroups }
        \cup { [ZeroLongOrderShortCodesDetailsModifiableGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderShortCodesDetailsModifiableGroups EXCEPT !.longOrderShortCodesDetailsModifiableGroup = one] : one \in SampleLists(OneLongOrderShortCodesDetailsModifiableGroup) }

(***************************************************************************)
(* Long Order Message                                                      *)
(***************************************************************************)

LongOrderMessage ==
    [ msgSeqNum                                           : Sample(4),
      produceTime                                         : Sample(8),
      consumeTime                                         : Sample(8),
      orderEventType                                      : Sample(1),
      accountTypeInternal                                 : Sample(1),
      ackPhase                                            : Sample(1),
      ackQualifiers                                       : Sample(1),
      ackType                                             : Sample(1),
      bookInOptional                                      : Sample(8),
      bookOutTimeOptional                                 : Sample(8),
      clientOrderIdOptional                               : Sample(8),
      darkExecutionInstruction                            : Sample(1),
      emm                                                 : Sample(1),
      eventId                                             : Sample(8),
      executionInstruction                                : Sample(1),
      firmId                                              : Sample(8),
      indicativeAuctionPrice                              : Sample(8),
      indicativeAuctionVolume                             : Sample(8),
      oeSessionId                                         : Sample(8),
      lpRoleOptional                                      : Sample(1),
      miFidIndicators                                     : Sample(1),
      oeginFromMemberOptional                             : Sample(8),
      oegoutTimeToMeOptional                              : Sample(8),
      orderId                                             : Sample(8),
      orderPriority                                       : Sample(8),
      orderPx                                             : Sample(8),
      orderQty                                            : Sample(8),
      orderSide                                           : Sample(1),
      orderType                                           : Sample(1),
      origClientOrderId                                   : Sample(8),
      stpid                                               : Sample(2),
      symbolIndex                                         : Sample(4),
      timeInForce                                         : Sample(1),
      displayedQty                                        : Sample(8),
      crossOrderIndicator                                 : Sample(1),
      counterpartFirmId                                   : Sample(8),
      executionIdOptional                                 : Sample(4),
      executionPhaseOptional                              : Sample(1),
      lastSharesOptional                                  : Sample(8),
      lastTradedPxOptional                                : Sample(8),
      leavesQty                                           : Sample(8),
      tradeQualifierOptional                              : Sample(1),
      tradeTime                                           : Sample(8),
      tradeType                                           : Sample(1),
      killReason                                          : Sample(2),
      breachedCollarPrice                                 : Sample(8),
      collarRejType                                       : Sample(1),
      rejectedMessage                                     : Sample(1),
      errorCodeOptional                                   : Sample(2),
      stopQueuePriority                                   : Sample(8),
      counterpartyReasonType                              : Sample(1),
      quoteIndicator                                      : Sample(1),
      lisTransactionId                                    : Sample(4),
      wholesaleTradeType                                  : Sample(1),
      escbMembership                                      : Sample(1),
      tradeUniqueIdentifier                               : Sample(16),
      orderTolerablePrice                                 : Sample(8),
      orderSweepReason                                    : Sample(1),
      longOrderFreeTextSectionGroups                      : LongOrderFreeTextSectionGroups,
      longOrderOptionalFieldsGroups                       : LongOrderOptionalFieldsGroups,
      longOrderClearingFieldsGroups                       : LongOrderClearingFieldsGroups,
      longOrderNonModifiableOptFieldsGroups               : LongOrderNonModifiableOptFieldsGroups,
      longOrderNonModifiableShortCodesGroups              : LongOrderNonModifiableShortCodesGroups,
      longOrderModifiableShortCodesGroups                 : LongOrderModifiableShortCodesGroups,
      longOrderCommercialFieldsGroups                     : LongOrderCommercialFieldsGroups,
      longOrderModifiableCommercialInvestorFieldGroups    : LongOrderModifiableCommercialInvestorFieldGroups,
      longOrderNonModifiableCommercialInvestorFieldGroups : LongOrderNonModifiableCommercialInvestorFieldGroups,
      longOrderExtendedClearingAccountGroups              : LongOrderExtendedClearingAccountGroups,
      longOrderStrategyFieldsGroups                       : LongOrderStrategyFieldsGroups,
      longOrderOptionalFieldsDerivativesGroups            : LongOrderOptionalFieldsDerivativesGroups,
      longOrderAdditionalInfosGroups                      : LongOrderAdditionalInfosGroups,
      longOrderShortCodesDetailsNonModifiableGroups       : LongOrderShortCodesDetailsNonModifiableGroups,
      longOrderShortCodesDetailsModifiableGroups          : LongOrderShortCodesDetailsModifiableGroups ]

EncodeLongOrderMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.orderEventType
        \o message.accountTypeInternal
        \o message.ackPhase
        \o message.ackQualifiers
        \o message.ackType
        \o message.bookInOptional
        \o message.bookOutTimeOptional
        \o message.clientOrderIdOptional
        \o message.darkExecutionInstruction
        \o message.emm
        \o message.eventId
        \o message.executionInstruction
        \o message.firmId
        \o message.indicativeAuctionPrice
        \o message.indicativeAuctionVolume
        \o message.oeSessionId
        \o message.lpRoleOptional
        \o message.miFidIndicators
        \o message.oeginFromMemberOptional
        \o message.oegoutTimeToMeOptional
        \o message.orderId
        \o message.orderPriority
        \o message.orderPx
        \o message.orderQty
        \o message.orderSide
        \o message.orderType
        \o message.origClientOrderId
        \o message.stpid
        \o message.symbolIndex
        \o message.timeInForce
        \o message.displayedQty
        \o message.crossOrderIndicator
        \o message.counterpartFirmId
        \o message.executionIdOptional
        \o message.executionPhaseOptional
        \o message.lastSharesOptional
        \o message.lastTradedPxOptional
        \o message.leavesQty
        \o message.tradeQualifierOptional
        \o message.tradeTime
        \o message.tradeType
        \o message.killReason
        \o message.breachedCollarPrice
        \o message.collarRejType
        \o message.rejectedMessage
        \o message.errorCodeOptional
        \o message.stopQueuePriority
        \o message.counterpartyReasonType
        \o message.quoteIndicator
        \o message.lisTransactionId
        \o message.wholesaleTradeType
        \o message.escbMembership
        \o message.tradeUniqueIdentifier
        \o message.orderTolerablePrice
        \o message.orderSweepReason
        \o EncodeLongOrderFreeTextSectionGroups(message.longOrderFreeTextSectionGroups)
        \o EncodeLongOrderOptionalFieldsGroups(message.longOrderOptionalFieldsGroups)
        \o EncodeLongOrderClearingFieldsGroups(message.longOrderClearingFieldsGroups)
        \o EncodeLongOrderNonModifiableOptFieldsGroups(message.longOrderNonModifiableOptFieldsGroups)
        \o EncodeLongOrderNonModifiableShortCodesGroups(message.longOrderNonModifiableShortCodesGroups)
        \o EncodeLongOrderModifiableShortCodesGroups(message.longOrderModifiableShortCodesGroups)
        \o EncodeLongOrderCommercialFieldsGroups(message.longOrderCommercialFieldsGroups)
        \o EncodeLongOrderModifiableCommercialInvestorFieldGroups(message.longOrderModifiableCommercialInvestorFieldGroups)
        \o EncodeLongOrderNonModifiableCommercialInvestorFieldGroups(message.longOrderNonModifiableCommercialInvestorFieldGroups)
        \o EncodeLongOrderExtendedClearingAccountGroups(message.longOrderExtendedClearingAccountGroups)
        \o EncodeLongOrderStrategyFieldsGroups(message.longOrderStrategyFieldsGroups)
        \o EncodeLongOrderOptionalFieldsDerivativesGroups(message.longOrderOptionalFieldsDerivativesGroups)
        \o EncodeLongOrderAdditionalInfosGroups(message.longOrderAdditionalInfosGroups)
        \o EncodeLongOrderShortCodesDetailsNonModifiableGroups(message.longOrderShortCodesDetailsNonModifiableGroups)
        \o EncodeLongOrderShortCodesDetailsModifiableGroups(message.longOrderShortCodesDetailsModifiableGroups)

DecodeLongOrderMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(consumeTime.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET accountTypeInternal == ReadBytes(orderEventType.rest, 1) IN IF ~accountTypeInternal.ok THEN Fail ELSE
    LET ackPhase == ReadBytes(accountTypeInternal.rest, 1) IN IF ~ackPhase.ok THEN Fail ELSE
    LET ackQualifiers == ReadBytes(ackPhase.rest, 1) IN IF ~ackQualifiers.ok THEN Fail ELSE
    LET ackType == ReadBytes(ackQualifiers.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(ackType.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookInOptional.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET darkExecutionInstruction == ReadBytes(clientOrderIdOptional.rest, 1) IN IF ~darkExecutionInstruction.ok THEN Fail ELSE
    LET emm == ReadBytes(darkExecutionInstruction.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventId == ReadBytes(emm.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET executionInstruction == ReadBytes(eventId.rest, 1) IN IF ~executionInstruction.ok THEN Fail ELSE
    LET firmId == ReadBytes(executionInstruction.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET indicativeAuctionPrice == ReadBytes(firmId.rest, 8) IN IF ~indicativeAuctionPrice.ok THEN Fail ELSE
    LET indicativeAuctionVolume == ReadBytes(indicativeAuctionPrice.rest, 8) IN IF ~indicativeAuctionVolume.ok THEN Fail ELSE
    LET oeSessionId == ReadBytes(indicativeAuctionVolume.rest, 8) IN IF ~oeSessionId.ok THEN Fail ELSE
    LET lpRoleOptional == ReadBytes(oeSessionId.rest, 1) IN IF ~lpRoleOptional.ok THEN Fail ELSE
    LET miFidIndicators == ReadBytes(lpRoleOptional.rest, 1) IN IF ~miFidIndicators.ok THEN Fail ELSE
    LET oeginFromMemberOptional == ReadBytes(miFidIndicators.rest, 8) IN IF ~oeginFromMemberOptional.ok THEN Fail ELSE
    LET oegoutTimeToMeOptional == ReadBytes(oeginFromMemberOptional.rest, 8) IN IF ~oegoutTimeToMeOptional.ok THEN Fail ELSE
    LET orderId == ReadBytes(oegoutTimeToMeOptional.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderPriority == ReadBytes(orderId.rest, 8) IN IF ~orderPriority.ok THEN Fail ELSE
    LET orderPx == ReadBytes(orderPriority.rest, 8) IN IF ~orderPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderQty.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderSide.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(orderType.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    LET stpid == ReadBytes(origClientOrderId.rest, 2) IN IF ~stpid.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(stpid.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbolIndex.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET displayedQty == ReadBytes(timeInForce.rest, 8) IN IF ~displayedQty.ok THEN Fail ELSE
    LET crossOrderIndicator == ReadBytes(displayedQty.rest, 1) IN IF ~crossOrderIndicator.ok THEN Fail ELSE
    LET counterpartFirmId == ReadBytes(crossOrderIndicator.rest, 8) IN IF ~counterpartFirmId.ok THEN Fail ELSE
    LET executionIdOptional == ReadBytes(counterpartFirmId.rest, 4) IN IF ~executionIdOptional.ok THEN Fail ELSE
    LET executionPhaseOptional == ReadBytes(executionIdOptional.rest, 1) IN IF ~executionPhaseOptional.ok THEN Fail ELSE
    LET lastSharesOptional == ReadBytes(executionPhaseOptional.rest, 8) IN IF ~lastSharesOptional.ok THEN Fail ELSE
    LET lastTradedPxOptional == ReadBytes(lastSharesOptional.rest, 8) IN IF ~lastTradedPxOptional.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastTradedPxOptional.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET tradeQualifierOptional == ReadBytes(leavesQty.rest, 1) IN IF ~tradeQualifierOptional.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(tradeQualifierOptional.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET tradeType == ReadBytes(tradeTime.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET killReason == ReadBytes(tradeType.rest, 2) IN IF ~killReason.ok THEN Fail ELSE
    LET breachedCollarPrice == ReadBytes(killReason.rest, 8) IN IF ~breachedCollarPrice.ok THEN Fail ELSE
    LET collarRejType == ReadBytes(breachedCollarPrice.rest, 1) IN IF ~collarRejType.ok THEN Fail ELSE
    LET rejectedMessage == ReadBytes(collarRejType.rest, 1) IN IF ~rejectedMessage.ok THEN Fail ELSE
    LET errorCodeOptional == ReadBytes(rejectedMessage.rest, 2) IN IF ~errorCodeOptional.ok THEN Fail ELSE
    LET stopQueuePriority == ReadBytes(errorCodeOptional.rest, 8) IN IF ~stopQueuePriority.ok THEN Fail ELSE
    LET counterpartyReasonType == ReadBytes(stopQueuePriority.rest, 1) IN IF ~counterpartyReasonType.ok THEN Fail ELSE
    LET quoteIndicator == ReadBytes(counterpartyReasonType.rest, 1) IN IF ~quoteIndicator.ok THEN Fail ELSE
    LET lisTransactionId == ReadBytes(quoteIndicator.rest, 4) IN IF ~lisTransactionId.ok THEN Fail ELSE
    LET wholesaleTradeType == ReadBytes(lisTransactionId.rest, 1) IN IF ~wholesaleTradeType.ok THEN Fail ELSE
    LET escbMembership == ReadBytes(wholesaleTradeType.rest, 1) IN IF ~escbMembership.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(escbMembership.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    LET orderTolerablePrice == ReadBytes(tradeUniqueIdentifier.rest, 8) IN IF ~orderTolerablePrice.ok THEN Fail ELSE
    LET orderSweepReason == ReadBytes(orderTolerablePrice.rest, 1) IN IF ~orderSweepReason.ok THEN Fail ELSE
    LET longOrderFreeTextSectionGroups == DecodeLongOrderFreeTextSectionGroups(orderSweepReason.rest) IN IF ~longOrderFreeTextSectionGroups.ok THEN Fail ELSE
    LET longOrderOptionalFieldsGroups == DecodeLongOrderOptionalFieldsGroups(longOrderFreeTextSectionGroups.rest) IN IF ~longOrderOptionalFieldsGroups.ok THEN Fail ELSE
    LET longOrderClearingFieldsGroups == DecodeLongOrderClearingFieldsGroups(longOrderOptionalFieldsGroups.rest) IN IF ~longOrderClearingFieldsGroups.ok THEN Fail ELSE
    LET longOrderNonModifiableOptFieldsGroups == DecodeLongOrderNonModifiableOptFieldsGroups(longOrderClearingFieldsGroups.rest) IN IF ~longOrderNonModifiableOptFieldsGroups.ok THEN Fail ELSE
    LET longOrderNonModifiableShortCodesGroups == DecodeLongOrderNonModifiableShortCodesGroups(longOrderNonModifiableOptFieldsGroups.rest) IN IF ~longOrderNonModifiableShortCodesGroups.ok THEN Fail ELSE
    LET longOrderModifiableShortCodesGroups == DecodeLongOrderModifiableShortCodesGroups(longOrderNonModifiableShortCodesGroups.rest) IN IF ~longOrderModifiableShortCodesGroups.ok THEN Fail ELSE
    LET longOrderCommercialFieldsGroups == DecodeLongOrderCommercialFieldsGroups(longOrderModifiableShortCodesGroups.rest) IN IF ~longOrderCommercialFieldsGroups.ok THEN Fail ELSE
    LET longOrderModifiableCommercialInvestorFieldGroups == DecodeLongOrderModifiableCommercialInvestorFieldGroups(longOrderCommercialFieldsGroups.rest) IN IF ~longOrderModifiableCommercialInvestorFieldGroups.ok THEN Fail ELSE
    LET longOrderNonModifiableCommercialInvestorFieldGroups == DecodeLongOrderNonModifiableCommercialInvestorFieldGroups(longOrderModifiableCommercialInvestorFieldGroups.rest) IN IF ~longOrderNonModifiableCommercialInvestorFieldGroups.ok THEN Fail ELSE
    LET longOrderExtendedClearingAccountGroups == DecodeLongOrderExtendedClearingAccountGroups(longOrderNonModifiableCommercialInvestorFieldGroups.rest) IN IF ~longOrderExtendedClearingAccountGroups.ok THEN Fail ELSE
    LET longOrderStrategyFieldsGroups == DecodeLongOrderStrategyFieldsGroups(longOrderExtendedClearingAccountGroups.rest) IN IF ~longOrderStrategyFieldsGroups.ok THEN Fail ELSE
    LET longOrderOptionalFieldsDerivativesGroups == DecodeLongOrderOptionalFieldsDerivativesGroups(longOrderStrategyFieldsGroups.rest) IN IF ~longOrderOptionalFieldsDerivativesGroups.ok THEN Fail ELSE
    LET longOrderAdditionalInfosGroups == DecodeLongOrderAdditionalInfosGroups(longOrderOptionalFieldsDerivativesGroups.rest) IN IF ~longOrderAdditionalInfosGroups.ok THEN Fail ELSE
    LET longOrderShortCodesDetailsNonModifiableGroups == DecodeLongOrderShortCodesDetailsNonModifiableGroups(longOrderAdditionalInfosGroups.rest) IN IF ~longOrderShortCodesDetailsNonModifiableGroups.ok THEN Fail ELSE
    LET longOrderShortCodesDetailsModifiableGroups == DecodeLongOrderShortCodesDetailsModifiableGroups(longOrderShortCodesDetailsNonModifiableGroups.rest) IN IF ~longOrderShortCodesDetailsModifiableGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                                           |-> msgSeqNum.value,
         produceTime                                         |-> produceTime.value,
         consumeTime                                         |-> consumeTime.value,
         orderEventType                                      |-> orderEventType.value,
         accountTypeInternal                                 |-> accountTypeInternal.value,
         ackPhase                                            |-> ackPhase.value,
         ackQualifiers                                       |-> ackQualifiers.value,
         ackType                                             |-> ackType.value,
         bookInOptional                                      |-> bookInOptional.value,
         bookOutTimeOptional                                 |-> bookOutTimeOptional.value,
         clientOrderIdOptional                               |-> clientOrderIdOptional.value,
         darkExecutionInstruction                            |-> darkExecutionInstruction.value,
         emm                                                 |-> emm.value,
         eventId                                             |-> eventId.value,
         executionInstruction                                |-> executionInstruction.value,
         firmId                                              |-> firmId.value,
         indicativeAuctionPrice                              |-> indicativeAuctionPrice.value,
         indicativeAuctionVolume                             |-> indicativeAuctionVolume.value,
         oeSessionId                                         |-> oeSessionId.value,
         lpRoleOptional                                      |-> lpRoleOptional.value,
         miFidIndicators                                     |-> miFidIndicators.value,
         oeginFromMemberOptional                             |-> oeginFromMemberOptional.value,
         oegoutTimeToMeOptional                              |-> oegoutTimeToMeOptional.value,
         orderId                                             |-> orderId.value,
         orderPriority                                       |-> orderPriority.value,
         orderPx                                             |-> orderPx.value,
         orderQty                                            |-> orderQty.value,
         orderSide                                           |-> orderSide.value,
         orderType                                           |-> orderType.value,
         origClientOrderId                                   |-> origClientOrderId.value,
         stpid                                               |-> stpid.value,
         symbolIndex                                         |-> symbolIndex.value,
         timeInForce                                         |-> timeInForce.value,
         displayedQty                                        |-> displayedQty.value,
         crossOrderIndicator                                 |-> crossOrderIndicator.value,
         counterpartFirmId                                   |-> counterpartFirmId.value,
         executionIdOptional                                 |-> executionIdOptional.value,
         executionPhaseOptional                              |-> executionPhaseOptional.value,
         lastSharesOptional                                  |-> lastSharesOptional.value,
         lastTradedPxOptional                                |-> lastTradedPxOptional.value,
         leavesQty                                           |-> leavesQty.value,
         tradeQualifierOptional                              |-> tradeQualifierOptional.value,
         tradeTime                                           |-> tradeTime.value,
         tradeType                                           |-> tradeType.value,
         killReason                                          |-> killReason.value,
         breachedCollarPrice                                 |-> breachedCollarPrice.value,
         collarRejType                                       |-> collarRejType.value,
         rejectedMessage                                     |-> rejectedMessage.value,
         errorCodeOptional                                   |-> errorCodeOptional.value,
         stopQueuePriority                                   |-> stopQueuePriority.value,
         counterpartyReasonType                              |-> counterpartyReasonType.value,
         quoteIndicator                                      |-> quoteIndicator.value,
         lisTransactionId                                    |-> lisTransactionId.value,
         wholesaleTradeType                                  |-> wholesaleTradeType.value,
         escbMembership                                      |-> escbMembership.value,
         tradeUniqueIdentifier                               |-> tradeUniqueIdentifier.value,
         orderTolerablePrice                                 |-> orderTolerablePrice.value,
         orderSweepReason                                    |-> orderSweepReason.value,
         longOrderFreeTextSectionGroups                      |-> longOrderFreeTextSectionGroups.value,
         longOrderOptionalFieldsGroups                       |-> longOrderOptionalFieldsGroups.value,
         longOrderClearingFieldsGroups                       |-> longOrderClearingFieldsGroups.value,
         longOrderNonModifiableOptFieldsGroups               |-> longOrderNonModifiableOptFieldsGroups.value,
         longOrderNonModifiableShortCodesGroups              |-> longOrderNonModifiableShortCodesGroups.value,
         longOrderModifiableShortCodesGroups                 |-> longOrderModifiableShortCodesGroups.value,
         longOrderCommercialFieldsGroups                     |-> longOrderCommercialFieldsGroups.value,
         longOrderModifiableCommercialInvestorFieldGroups    |-> longOrderModifiableCommercialInvestorFieldGroups.value,
         longOrderNonModifiableCommercialInvestorFieldGroups |-> longOrderNonModifiableCommercialInvestorFieldGroups.value,
         longOrderExtendedClearingAccountGroups              |-> longOrderExtendedClearingAccountGroups.value,
         longOrderStrategyFieldsGroups                       |-> longOrderStrategyFieldsGroups.value,
         longOrderOptionalFieldsDerivativesGroups            |-> longOrderOptionalFieldsDerivativesGroups.value,
         longOrderAdditionalInfosGroups                      |-> longOrderAdditionalInfosGroups.value,
         longOrderShortCodesDetailsNonModifiableGroups       |-> longOrderShortCodesDetailsNonModifiableGroups.value,
         longOrderShortCodesDetailsModifiableGroups          |-> longOrderShortCodesDetailsModifiableGroups.value ], longOrderShortCodesDetailsModifiableGroups.rest)

ZeroLongOrderMessage ==
    [ msgSeqNum                                           |-> [i \in 1 .. 4 |-> 0],
      produceTime                                         |-> [i \in 1 .. 8 |-> 0],
      consumeTime                                         |-> [i \in 1 .. 8 |-> 0],
      orderEventType                                      |-> [i \in 1 .. 1 |-> 0],
      accountTypeInternal                                 |-> [i \in 1 .. 1 |-> 0],
      ackPhase                                            |-> [i \in 1 .. 1 |-> 0],
      ackQualifiers                                       |-> [i \in 1 .. 1 |-> 0],
      ackType                                             |-> [i \in 1 .. 1 |-> 0],
      bookInOptional                                      |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional                                 |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional                               |-> [i \in 1 .. 8 |-> 0],
      darkExecutionInstruction                            |-> [i \in 1 .. 1 |-> 0],
      emm                                                 |-> [i \in 1 .. 1 |-> 0],
      eventId                                             |-> [i \in 1 .. 8 |-> 0],
      executionInstruction                                |-> [i \in 1 .. 1 |-> 0],
      firmId                                              |-> [i \in 1 .. 8 |-> 0],
      indicativeAuctionPrice                              |-> [i \in 1 .. 8 |-> 0],
      indicativeAuctionVolume                             |-> [i \in 1 .. 8 |-> 0],
      oeSessionId                                         |-> [i \in 1 .. 8 |-> 0],
      lpRoleOptional                                      |-> [i \in 1 .. 1 |-> 0],
      miFidIndicators                                     |-> [i \in 1 .. 1 |-> 0],
      oeginFromMemberOptional                             |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMeOptional                              |-> [i \in 1 .. 8 |-> 0],
      orderId                                             |-> [i \in 1 .. 8 |-> 0],
      orderPriority                                       |-> [i \in 1 .. 8 |-> 0],
      orderPx                                             |-> [i \in 1 .. 8 |-> 0],
      orderQty                                            |-> [i \in 1 .. 8 |-> 0],
      orderSide                                           |-> [i \in 1 .. 1 |-> 0],
      orderType                                           |-> [i \in 1 .. 1 |-> 0],
      origClientOrderId                                   |-> [i \in 1 .. 8 |-> 0],
      stpid                                               |-> [i \in 1 .. 2 |-> 0],
      symbolIndex                                         |-> [i \in 1 .. 4 |-> 0],
      timeInForce                                         |-> [i \in 1 .. 1 |-> 0],
      displayedQty                                        |-> [i \in 1 .. 8 |-> 0],
      crossOrderIndicator                                 |-> [i \in 1 .. 1 |-> 0],
      counterpartFirmId                                   |-> [i \in 1 .. 8 |-> 0],
      executionIdOptional                                 |-> [i \in 1 .. 4 |-> 0],
      executionPhaseOptional                              |-> [i \in 1 .. 1 |-> 0],
      lastSharesOptional                                  |-> [i \in 1 .. 8 |-> 0],
      lastTradedPxOptional                                |-> [i \in 1 .. 8 |-> 0],
      leavesQty                                           |-> [i \in 1 .. 8 |-> 0],
      tradeQualifierOptional                              |-> [i \in 1 .. 1 |-> 0],
      tradeTime                                           |-> [i \in 1 .. 8 |-> 0],
      tradeType                                           |-> [i \in 1 .. 1 |-> 0],
      killReason                                          |-> [i \in 1 .. 2 |-> 0],
      breachedCollarPrice                                 |-> [i \in 1 .. 8 |-> 0],
      collarRejType                                       |-> [i \in 1 .. 1 |-> 0],
      rejectedMessage                                     |-> [i \in 1 .. 1 |-> 0],
      errorCodeOptional                                   |-> [i \in 1 .. 2 |-> 0],
      stopQueuePriority                                   |-> [i \in 1 .. 8 |-> 0],
      counterpartyReasonType                              |-> [i \in 1 .. 1 |-> 0],
      quoteIndicator                                      |-> [i \in 1 .. 1 |-> 0],
      lisTransactionId                                    |-> [i \in 1 .. 4 |-> 0],
      wholesaleTradeType                                  |-> [i \in 1 .. 1 |-> 0],
      escbMembership                                      |-> [i \in 1 .. 1 |-> 0],
      tradeUniqueIdentifier                               |-> [i \in 1 .. 16 |-> 0],
      orderTolerablePrice                                 |-> [i \in 1 .. 8 |-> 0],
      orderSweepReason                                    |-> [i \in 1 .. 1 |-> 0],
      longOrderFreeTextSectionGroups                      |-> ZeroLongOrderFreeTextSectionGroups,
      longOrderOptionalFieldsGroups                       |-> ZeroLongOrderOptionalFieldsGroups,
      longOrderClearingFieldsGroups                       |-> ZeroLongOrderClearingFieldsGroups,
      longOrderNonModifiableOptFieldsGroups               |-> ZeroLongOrderNonModifiableOptFieldsGroups,
      longOrderNonModifiableShortCodesGroups              |-> ZeroLongOrderNonModifiableShortCodesGroups,
      longOrderModifiableShortCodesGroups                 |-> ZeroLongOrderModifiableShortCodesGroups,
      longOrderCommercialFieldsGroups                     |-> ZeroLongOrderCommercialFieldsGroups,
      longOrderModifiableCommercialInvestorFieldGroups    |-> ZeroLongOrderModifiableCommercialInvestorFieldGroups,
      longOrderNonModifiableCommercialInvestorFieldGroups |-> ZeroLongOrderNonModifiableCommercialInvestorFieldGroups,
      longOrderExtendedClearingAccountGroups              |-> ZeroLongOrderExtendedClearingAccountGroups,
      longOrderStrategyFieldsGroups                       |-> ZeroLongOrderStrategyFieldsGroups,
      longOrderOptionalFieldsDerivativesGroups            |-> ZeroLongOrderOptionalFieldsDerivativesGroups,
      longOrderAdditionalInfosGroups                      |-> ZeroLongOrderAdditionalInfosGroups,
      longOrderShortCodesDetailsNonModifiableGroups       |-> ZeroLongOrderShortCodesDetailsNonModifiableGroups,
      longOrderShortCodesDetailsModifiableGroups          |-> ZeroLongOrderShortCodesDetailsModifiableGroups ]

(* Long Order Message at zero, then each field in turn at the values it is checked at *)
CheckedLongOrderMessage ==
    { ZeroLongOrderMessage }
        \cup { [ZeroLongOrderMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.accountTypeInternal = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.ackPhase = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.ackQualifiers = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.darkExecutionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.executionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.indicativeAuctionPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.indicativeAuctionVolume = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.oeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.lpRoleOptional = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.miFidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.oeginFromMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.oegoutTimeToMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderPriority = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderPx = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.stpid = one] : one \in Sample(2) }
        \cup { [ZeroLongOrderMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.displayedQty = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.crossOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.counterpartFirmId = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.executionIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderMessage EXCEPT !.executionPhaseOptional = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.lastSharesOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.lastTradedPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.tradeQualifierOptional = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.killReason = one] : one \in Sample(2) }
        \cup { [ZeroLongOrderMessage EXCEPT !.breachedCollarPrice = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.collarRejType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.rejectedMessage = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.errorCodeOptional = one] : one \in Sample(2) }
        \cup { [ZeroLongOrderMessage EXCEPT !.stopQueuePriority = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.counterpartyReasonType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.quoteIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.lisTransactionId = one] : one \in Sample(4) }
        \cup { [ZeroLongOrderMessage EXCEPT !.wholesaleTradeType = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.escbMembership = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderTolerablePrice = one] : one \in Sample(8) }
        \cup { [ZeroLongOrderMessage EXCEPT !.orderSweepReason = one] : one \in Sample(1) }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderFreeTextSectionGroups = one] : one \in CheckedLongOrderFreeTextSectionGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderOptionalFieldsGroups = one] : one \in CheckedLongOrderOptionalFieldsGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderClearingFieldsGroups = one] : one \in CheckedLongOrderClearingFieldsGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderNonModifiableOptFieldsGroups = one] : one \in CheckedLongOrderNonModifiableOptFieldsGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderNonModifiableShortCodesGroups = one] : one \in CheckedLongOrderNonModifiableShortCodesGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderModifiableShortCodesGroups = one] : one \in CheckedLongOrderModifiableShortCodesGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderCommercialFieldsGroups = one] : one \in CheckedLongOrderCommercialFieldsGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderModifiableCommercialInvestorFieldGroups = one] : one \in CheckedLongOrderModifiableCommercialInvestorFieldGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderNonModifiableCommercialInvestorFieldGroups = one] : one \in CheckedLongOrderNonModifiableCommercialInvestorFieldGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderExtendedClearingAccountGroups = one] : one \in CheckedLongOrderExtendedClearingAccountGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderStrategyFieldsGroups = one] : one \in CheckedLongOrderStrategyFieldsGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderOptionalFieldsDerivativesGroups = one] : one \in CheckedLongOrderOptionalFieldsDerivativesGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderAdditionalInfosGroups = one] : one \in CheckedLongOrderAdditionalInfosGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderShortCodesDetailsNonModifiableGroups = one] : one \in CheckedLongOrderShortCodesDetailsNonModifiableGroups }
        \cup { [ZeroLongOrderMessage EXCEPT !.longOrderShortCodesDetailsModifiableGroups = one] : one \in CheckedLongOrderShortCodesDetailsModifiableGroups }

(***************************************************************************)
(* D C Short Order Reject Message Modifiable Short Codes Group: 8 bytes    *)
(***************************************************************************)

DCShortOrderRejectMessageModifiableShortCodesGroup ==
    [ eventClientIdShortCode  : Sample(4),
      eventExecWFirmShortCode : Sample(4) ]

EncodeDCShortOrderRejectMessageModifiableShortCodesGroup(message) ==
    message.eventClientIdShortCode
        \o message.eventExecWFirmShortCode

DecodeDCShortOrderRejectMessageModifiableShortCodesGroup(bytes) ==
    LET eventClientIdShortCode == ReadBytes(bytes, 4) IN IF ~eventClientIdShortCode.ok THEN Fail ELSE
    LET eventExecWFirmShortCode == ReadBytes(eventClientIdShortCode.rest, 4) IN IF ~eventExecWFirmShortCode.ok THEN Fail ELSE
    Ok([ eventClientIdShortCode  |-> eventClientIdShortCode.value,
         eventExecWFirmShortCode |-> eventExecWFirmShortCode.value ], eventExecWFirmShortCode.rest)

ZeroDCShortOrderRejectMessageModifiableShortCodesGroup ==
    [ eventClientIdShortCode  |-> [i \in 1 .. 4 |-> 0],
      eventExecWFirmShortCode |-> [i \in 1 .. 4 |-> 0] ]

(* D C Short Order Reject Message Modifiable Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedDCShortOrderRejectMessageModifiableShortCodesGroup ==
    { ZeroDCShortOrderRejectMessageModifiableShortCodesGroup }
        \cup { [ZeroDCShortOrderRejectMessageModifiableShortCodesGroup EXCEPT !.eventClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCShortOrderRejectMessageModifiableShortCodesGroup EXCEPT !.eventExecWFirmShortCode = one] : one \in Sample(4) }

(* A run of D C Short Order Reject Message Modifiable Short Codes Group, written one after another *)
RECURSIVE EncodeDCShortOrderRejectMessageModifiableShortCodesGroupList(_)
EncodeDCShortOrderRejectMessageModifiableShortCodesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCShortOrderRejectMessageModifiableShortCodesGroup(Head(messages)) \o EncodeDCShortOrderRejectMessageModifiableShortCodesGroupList(Tail(messages))

(* As many D C Short Order Reject Message Modifiable Short Codes Group as the field that counts them says *)
RECURSIVE ReadDCShortOrderRejectMessageModifiableShortCodesGroupList(_, _)
ReadDCShortOrderRejectMessageModifiableShortCodesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCShortOrderRejectMessageModifiableShortCodesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCShortOrderRejectMessageModifiableShortCodesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Short Order Reject Message Modifiable Short Codes Group of each kind, for the lists that carry them *)
OneDCShortOrderRejectMessageModifiableShortCodesGroup == { ZeroDCShortOrderRejectMessageModifiableShortCodesGroup }

(***************************************************************************)
(* D C Short Order Reject Message Modifiable Short Codes Groups            *)
(***************************************************************************)

DCShortOrderRejectMessageModifiableShortCodesGroups ==
    [ blockLengthShort                                   : Sample(1),
      dCShortOrderRejectMessageModifiableShortCodesGroup : SampleLists(OneDCShortOrderRejectMessageModifiableShortCodesGroup) ]

EncodeDCShortOrderRejectMessageModifiableShortCodesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCShortOrderRejectMessageModifiableShortCodesGroup), 1)
        \o EncodeDCShortOrderRejectMessageModifiableShortCodesGroupList(message.dCShortOrderRejectMessageModifiableShortCodesGroup)

DecodeDCShortOrderRejectMessageModifiableShortCodesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCShortOrderRejectMessageModifiableShortCodesGroup == ReadDCShortOrderRejectMessageModifiableShortCodesGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCShortOrderRejectMessageModifiableShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                   |-> blockLengthShort.value,
         dCShortOrderRejectMessageModifiableShortCodesGroup |-> dCShortOrderRejectMessageModifiableShortCodesGroup.value ], dCShortOrderRejectMessageModifiableShortCodesGroup.rest)

ZeroDCShortOrderRejectMessageModifiableShortCodesGroups ==
    [ blockLengthShort                                   |-> [i \in 1 .. 1 |-> 0],
      dCShortOrderRejectMessageModifiableShortCodesGroup |-> << >> ]

(* D C Short Order Reject Message Modifiable Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCShortOrderRejectMessageModifiableShortCodesGroups ==
    { ZeroDCShortOrderRejectMessageModifiableShortCodesGroups }
        \cup { [ZeroDCShortOrderRejectMessageModifiableShortCodesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCShortOrderRejectMessageModifiableShortCodesGroups EXCEPT !.dCShortOrderRejectMessageModifiableShortCodesGroup = one] : one \in SampleLists(OneDCShortOrderRejectMessageModifiableShortCodesGroup) }

(***************************************************************************)
(* D C Short Order Reject Message Short Codes Details Modifiable Group: 3  *)
(* bytes                                                                   *)
(***************************************************************************)

DCShortOrderRejectMessageShortCodesDetailsModifiableGroup ==
    [ eventShortCodeType     : Sample(1),
      shortCodeRole          : Sample(1),
      shortCodeRoleQualifier : Sample(1) ]

EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroup(message) ==
    message.eventShortCodeType
        \o message.shortCodeRole
        \o message.shortCodeRoleQualifier

DecodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroup(bytes) ==
    LET eventShortCodeType == ReadBytes(bytes, 1) IN IF ~eventShortCodeType.ok THEN Fail ELSE
    LET shortCodeRole == ReadBytes(eventShortCodeType.rest, 1) IN IF ~shortCodeRole.ok THEN Fail ELSE
    LET shortCodeRoleQualifier == ReadBytes(shortCodeRole.rest, 1) IN IF ~shortCodeRoleQualifier.ok THEN Fail ELSE
    Ok([ eventShortCodeType     |-> eventShortCodeType.value,
         shortCodeRole          |-> shortCodeRole.value,
         shortCodeRoleQualifier |-> shortCodeRoleQualifier.value ], shortCodeRoleQualifier.rest)

ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroup ==
    [ eventShortCodeType     |-> [i \in 1 .. 1 |-> 0],
      shortCodeRole          |-> [i \in 1 .. 1 |-> 0],
      shortCodeRoleQualifier |-> [i \in 1 .. 1 |-> 0] ]

(* D C Short Order Reject Message Short Codes Details Modifiable Group at zero, then each field in turn at the values it is checked at *)
CheckedDCShortOrderRejectMessageShortCodesDetailsModifiableGroup ==
    { ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroup }
        \cup { [ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroup EXCEPT !.eventShortCodeType = one] : one \in Sample(1) }
        \cup { [ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroup EXCEPT !.shortCodeRole = one] : one \in Sample(1) }
        \cup { [ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroup EXCEPT !.shortCodeRoleQualifier = one] : one \in Sample(1) }

(* A run of D C Short Order Reject Message Short Codes Details Modifiable Group, written one after another *)
RECURSIVE EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(_)
EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroup(Head(messages)) \o EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(Tail(messages))

(* As many D C Short Order Reject Message Short Codes Details Modifiable Group as the field that counts them says *)
RECURSIVE ReadDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(_, _)
ReadDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Short Order Reject Message Short Codes Details Modifiable Group of each kind, for the lists that carry them *)
OneDCShortOrderRejectMessageShortCodesDetailsModifiableGroup == { ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroup }

(***************************************************************************)
(* D C Short Order Reject Message Short Codes Details Modifiable Groups    *)
(***************************************************************************)

DCShortOrderRejectMessageShortCodesDetailsModifiableGroups ==
    [ blockLengthShort                                          : Sample(1),
      dCShortOrderRejectMessageShortCodesDetailsModifiableGroup : SampleLists(OneDCShortOrderRejectMessageShortCodesDetailsModifiableGroup) ]

EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCShortOrderRejectMessageShortCodesDetailsModifiableGroup), 1)
        \o EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(message.dCShortOrderRejectMessageShortCodesDetailsModifiableGroup)

DecodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCShortOrderRejectMessageShortCodesDetailsModifiableGroup == ReadDCShortOrderRejectMessageShortCodesDetailsModifiableGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCShortOrderRejectMessageShortCodesDetailsModifiableGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                          |-> blockLengthShort.value,
         dCShortOrderRejectMessageShortCodesDetailsModifiableGroup |-> dCShortOrderRejectMessageShortCodesDetailsModifiableGroup.value ], dCShortOrderRejectMessageShortCodesDetailsModifiableGroup.rest)

ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroups ==
    [ blockLengthShort                                          |-> [i \in 1 .. 1 |-> 0],
      dCShortOrderRejectMessageShortCodesDetailsModifiableGroup |-> << >> ]

(* D C Short Order Reject Message Short Codes Details Modifiable Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCShortOrderRejectMessageShortCodesDetailsModifiableGroups ==
    { ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroups }
        \cup { [ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroups EXCEPT !.dCShortOrderRejectMessageShortCodesDetailsModifiableGroup = one] : one \in SampleLists(OneDCShortOrderRejectMessageShortCodesDetailsModifiableGroup) }

(***************************************************************************)
(* Dc Short Order Reject Message                                           *)
(***************************************************************************)

DcShortOrderRejectMessage ==
    [ msgSeqNum                                                  : Sample(4),
      produceTime                                                : Sample(8),
      consumeTime                                                : Sample(8),
      orderEventType                                             : Sample(1),
      bookIn                                                     : Sample(8),
      bookOutTime                                                : Sample(8),
      clientOrderId                                              : Sample(8),
      emm                                                        : Sample(1),
      eventId                                                    : Sample(8),
      firmId                                                     : Sample(8),
      oeginFromMemberOptional                                    : Sample(8),
      oegoutTimeToMe                                             : Sample(8),
      orderId                                                    : Sample(8),
      symbolIndex                                                : Sample(4),
      breachedCollarPrice                                        : Sample(8),
      collarRejType                                              : Sample(1),
      rejectedMessage                                            : Sample(1),
      errorCode                                                  : Sample(2),
      miFidIndicatorsOptional                                    : Sample(1),
      oeSessionIdOptional                                        : Sample(8),
      orderSideOptional                                          : Sample(1),
      timeInForceOptional                                        : Sample(1),
      dCShortOrderRejectMessageModifiableShortCodesGroups        : DCShortOrderRejectMessageModifiableShortCodesGroups,
      dCShortOrderRejectMessageShortCodesDetailsModifiableGroups : DCShortOrderRejectMessageShortCodesDetailsModifiableGroups ]

EncodeDcShortOrderRejectMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.orderEventType
        \o message.bookIn
        \o message.bookOutTime
        \o message.clientOrderId
        \o message.emm
        \o message.eventId
        \o message.firmId
        \o message.oeginFromMemberOptional
        \o message.oegoutTimeToMe
        \o message.orderId
        \o message.symbolIndex
        \o message.breachedCollarPrice
        \o message.collarRejType
        \o message.rejectedMessage
        \o message.errorCode
        \o message.miFidIndicatorsOptional
        \o message.oeSessionIdOptional
        \o message.orderSideOptional
        \o message.timeInForceOptional
        \o EncodeDCShortOrderRejectMessageModifiableShortCodesGroups(message.dCShortOrderRejectMessageModifiableShortCodesGroups)
        \o EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroups(message.dCShortOrderRejectMessageShortCodesDetailsModifiableGroups)

DecodeDcShortOrderRejectMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(consumeTime.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET bookIn == ReadBytes(orderEventType.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(bookOutTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET emm == ReadBytes(clientOrderId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventId == ReadBytes(emm.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET firmId == ReadBytes(eventId.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oeginFromMemberOptional == ReadBytes(firmId.rest, 8) IN IF ~oeginFromMemberOptional.ok THEN Fail ELSE
    LET oegoutTimeToMe == ReadBytes(oeginFromMemberOptional.rest, 8) IN IF ~oegoutTimeToMe.ok THEN Fail ELSE
    LET orderId == ReadBytes(oegoutTimeToMe.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(orderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET breachedCollarPrice == ReadBytes(symbolIndex.rest, 8) IN IF ~breachedCollarPrice.ok THEN Fail ELSE
    LET collarRejType == ReadBytes(breachedCollarPrice.rest, 1) IN IF ~collarRejType.ok THEN Fail ELSE
    LET rejectedMessage == ReadBytes(collarRejType.rest, 1) IN IF ~rejectedMessage.ok THEN Fail ELSE
    LET errorCode == ReadBytes(rejectedMessage.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET miFidIndicatorsOptional == ReadBytes(errorCode.rest, 1) IN IF ~miFidIndicatorsOptional.ok THEN Fail ELSE
    LET oeSessionIdOptional == ReadBytes(miFidIndicatorsOptional.rest, 8) IN IF ~oeSessionIdOptional.ok THEN Fail ELSE
    LET orderSideOptional == ReadBytes(oeSessionIdOptional.rest, 1) IN IF ~orderSideOptional.ok THEN Fail ELSE
    LET timeInForceOptional == ReadBytes(orderSideOptional.rest, 1) IN IF ~timeInForceOptional.ok THEN Fail ELSE
    LET dCShortOrderRejectMessageModifiableShortCodesGroups == DecodeDCShortOrderRejectMessageModifiableShortCodesGroups(timeInForceOptional.rest) IN IF ~dCShortOrderRejectMessageModifiableShortCodesGroups.ok THEN Fail ELSE
    LET dCShortOrderRejectMessageShortCodesDetailsModifiableGroups == DecodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroups(dCShortOrderRejectMessageModifiableShortCodesGroups.rest) IN IF ~dCShortOrderRejectMessageShortCodesDetailsModifiableGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                                                  |-> msgSeqNum.value,
         produceTime                                                |-> produceTime.value,
         consumeTime                                                |-> consumeTime.value,
         orderEventType                                             |-> orderEventType.value,
         bookIn                                                     |-> bookIn.value,
         bookOutTime                                                |-> bookOutTime.value,
         clientOrderId                                              |-> clientOrderId.value,
         emm                                                        |-> emm.value,
         eventId                                                    |-> eventId.value,
         firmId                                                     |-> firmId.value,
         oeginFromMemberOptional                                    |-> oeginFromMemberOptional.value,
         oegoutTimeToMe                                             |-> oegoutTimeToMe.value,
         orderId                                                    |-> orderId.value,
         symbolIndex                                                |-> symbolIndex.value,
         breachedCollarPrice                                        |-> breachedCollarPrice.value,
         collarRejType                                              |-> collarRejType.value,
         rejectedMessage                                            |-> rejectedMessage.value,
         errorCode                                                  |-> errorCode.value,
         miFidIndicatorsOptional                                    |-> miFidIndicatorsOptional.value,
         oeSessionIdOptional                                        |-> oeSessionIdOptional.value,
         orderSideOptional                                          |-> orderSideOptional.value,
         timeInForceOptional                                        |-> timeInForceOptional.value,
         dCShortOrderRejectMessageModifiableShortCodesGroups        |-> dCShortOrderRejectMessageModifiableShortCodesGroups.value,
         dCShortOrderRejectMessageShortCodesDetailsModifiableGroups |-> dCShortOrderRejectMessageShortCodesDetailsModifiableGroups.value ], dCShortOrderRejectMessageShortCodesDetailsModifiableGroups.rest)

ZeroDcShortOrderRejectMessage ==
    [ msgSeqNum                                                  |-> [i \in 1 .. 4 |-> 0],
      produceTime                                                |-> [i \in 1 .. 8 |-> 0],
      consumeTime                                                |-> [i \in 1 .. 8 |-> 0],
      orderEventType                                             |-> [i \in 1 .. 1 |-> 0],
      bookIn                                                     |-> [i \in 1 .. 8 |-> 0],
      bookOutTime                                                |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                                              |-> [i \in 1 .. 8 |-> 0],
      emm                                                        |-> [i \in 1 .. 1 |-> 0],
      eventId                                                    |-> [i \in 1 .. 8 |-> 0],
      firmId                                                     |-> [i \in 1 .. 8 |-> 0],
      oeginFromMemberOptional                                    |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMe                                             |-> [i \in 1 .. 8 |-> 0],
      orderId                                                    |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                                                |-> [i \in 1 .. 4 |-> 0],
      breachedCollarPrice                                        |-> [i \in 1 .. 8 |-> 0],
      collarRejType                                              |-> [i \in 1 .. 1 |-> 0],
      rejectedMessage                                            |-> [i \in 1 .. 1 |-> 0],
      errorCode                                                  |-> [i \in 1 .. 2 |-> 0],
      miFidIndicatorsOptional                                    |-> [i \in 1 .. 1 |-> 0],
      oeSessionIdOptional                                        |-> [i \in 1 .. 8 |-> 0],
      orderSideOptional                                          |-> [i \in 1 .. 1 |-> 0],
      timeInForceOptional                                        |-> [i \in 1 .. 1 |-> 0],
      dCShortOrderRejectMessageModifiableShortCodesGroups        |-> ZeroDCShortOrderRejectMessageModifiableShortCodesGroups,
      dCShortOrderRejectMessageShortCodesDetailsModifiableGroups |-> ZeroDCShortOrderRejectMessageShortCodesDetailsModifiableGroups ]

(* Dc Short Order Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedDcShortOrderRejectMessage ==
    { ZeroDcShortOrderRejectMessage }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.oeginFromMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.oegoutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.breachedCollarPrice = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.collarRejType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.rejectedMessage = one] : one \in Sample(1) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.miFidIndicatorsOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.oeSessionIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.orderSideOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.timeInForceOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.dCShortOrderRejectMessageModifiableShortCodesGroups = one] : one \in CheckedDCShortOrderRejectMessageModifiableShortCodesGroups }
        \cup { [ZeroDcShortOrderRejectMessage EXCEPT !.dCShortOrderRejectMessageShortCodesDetailsModifiableGroups = one] : one \in CheckedDCShortOrderRejectMessageShortCodesDetailsModifiableGroups }

(***************************************************************************)
(* Dc Short Trade Cancellation Message: 77 bytes                           *)
(***************************************************************************)

DcShortTradeCancellationMessage ==
    [ msgSeqNum             : Sample(4),
      produceTime           : Sample(8),
      consumeTime           : Sample(8),
      executionId           : Sample(4),
      emm                   : Sample(1),
      eventId               : Sample(8),
      symbolIndex           : Sample(4),
      bookIn                : Sample(8),
      lastTradedPx          : Sample(8),
      lastShares            : Sample(8),
      tradeUniqueIdentifier : Sample(16) ]

EncodeDcShortTradeCancellationMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.executionId
        \o message.emm
        \o message.eventId
        \o message.symbolIndex
        \o message.bookIn
        \o message.lastTradedPx
        \o message.lastShares
        \o message.tradeUniqueIdentifier

DecodeDcShortTradeCancellationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET executionId == ReadBytes(consumeTime.rest, 4) IN IF ~executionId.ok THEN Fail ELSE
    LET emm == ReadBytes(executionId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventId == ReadBytes(emm.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(eventId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET bookIn == ReadBytes(symbolIndex.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET lastTradedPx == ReadBytes(bookIn.rest, 8) IN IF ~lastTradedPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastTradedPx.rest, 8) IN IF ~lastShares.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(lastShares.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    Ok([ msgSeqNum             |-> msgSeqNum.value,
         produceTime           |-> produceTime.value,
         consumeTime           |-> consumeTime.value,
         executionId           |-> executionId.value,
         emm                   |-> emm.value,
         eventId               |-> eventId.value,
         symbolIndex           |-> symbolIndex.value,
         bookIn                |-> bookIn.value,
         lastTradedPx          |-> lastTradedPx.value,
         lastShares            |-> lastShares.value,
         tradeUniqueIdentifier |-> tradeUniqueIdentifier.value ], tradeUniqueIdentifier.rest)

ZeroDcShortTradeCancellationMessage ==
    [ msgSeqNum             |-> [i \in 1 .. 4 |-> 0],
      produceTime           |-> [i \in 1 .. 8 |-> 0],
      consumeTime           |-> [i \in 1 .. 8 |-> 0],
      executionId           |-> [i \in 1 .. 4 |-> 0],
      emm                   |-> [i \in 1 .. 1 |-> 0],
      eventId               |-> [i \in 1 .. 8 |-> 0],
      symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      bookIn                |-> [i \in 1 .. 8 |-> 0],
      lastTradedPx          |-> [i \in 1 .. 8 |-> 0],
      lastShares            |-> [i \in 1 .. 8 |-> 0],
      tradeUniqueIdentifier |-> [i \in 1 .. 16 |-> 0] ]

(* Dc Short Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedDcShortTradeCancellationMessage ==
    { ZeroDcShortTradeCancellationMessage }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.executionId = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.lastTradedPx = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.lastShares = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeCancellationMessage EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }

(***************************************************************************)
(* D C Static Collars Message Static Collarsrep Group: 9 bytes             *)
(***************************************************************************)

DCStaticCollarsMessageStaticCollarsrepGroup ==
    [ updateType : Sample(1),
      price      : Sample(8) ]

EncodeDCStaticCollarsMessageStaticCollarsrepGroup(message) ==
    message.updateType
        \o message.price

DecodeDCStaticCollarsMessageStaticCollarsrepGroup(bytes) ==
    LET updateType == ReadBytes(bytes, 1) IN IF ~updateType.ok THEN Fail ELSE
    LET price == ReadBytes(updateType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ updateType |-> updateType.value,
         price      |-> price.value ], price.rest)

ZeroDCStaticCollarsMessageStaticCollarsrepGroup ==
    [ updateType |-> [i \in 1 .. 1 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0] ]

(* D C Static Collars Message Static Collarsrep Group at zero, then each field in turn at the values it is checked at *)
CheckedDCStaticCollarsMessageStaticCollarsrepGroup ==
    { ZeroDCStaticCollarsMessageStaticCollarsrepGroup }
        \cup { [ZeroDCStaticCollarsMessageStaticCollarsrepGroup EXCEPT !.updateType = one] : one \in Sample(1) }
        \cup { [ZeroDCStaticCollarsMessageStaticCollarsrepGroup EXCEPT !.price = one] : one \in Sample(8) }

(* A run of D C Static Collars Message Static Collarsrep Group, written one after another *)
RECURSIVE EncodeDCStaticCollarsMessageStaticCollarsrepGroupList(_)
EncodeDCStaticCollarsMessageStaticCollarsrepGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCStaticCollarsMessageStaticCollarsrepGroup(Head(messages)) \o EncodeDCStaticCollarsMessageStaticCollarsrepGroupList(Tail(messages))

(* As many D C Static Collars Message Static Collarsrep Group as the field that counts them says *)
RECURSIVE ReadDCStaticCollarsMessageStaticCollarsrepGroupList(_, _)
ReadDCStaticCollarsMessageStaticCollarsrepGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCStaticCollarsMessageStaticCollarsrepGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCStaticCollarsMessageStaticCollarsrepGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Static Collars Message Static Collarsrep Group of each kind, for the lists that carry them *)
OneDCStaticCollarsMessageStaticCollarsrepGroup == { ZeroDCStaticCollarsMessageStaticCollarsrepGroup }

(***************************************************************************)
(* D C Static Collars Message Static Collarsrep Groups                     *)
(***************************************************************************)

DCStaticCollarsMessageStaticCollarsrepGroups ==
    [ blockLengthShort                            : Sample(1),
      dCStaticCollarsMessageStaticCollarsrepGroup : SampleLists(OneDCStaticCollarsMessageStaticCollarsrepGroup) ]

EncodeDCStaticCollarsMessageStaticCollarsrepGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCStaticCollarsMessageStaticCollarsrepGroup), 1)
        \o EncodeDCStaticCollarsMessageStaticCollarsrepGroupList(message.dCStaticCollarsMessageStaticCollarsrepGroup)

DecodeDCStaticCollarsMessageStaticCollarsrepGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCStaticCollarsMessageStaticCollarsrepGroup == ReadDCStaticCollarsMessageStaticCollarsrepGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCStaticCollarsMessageStaticCollarsrepGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                            |-> blockLengthShort.value,
         dCStaticCollarsMessageStaticCollarsrepGroup |-> dCStaticCollarsMessageStaticCollarsrepGroup.value ], dCStaticCollarsMessageStaticCollarsrepGroup.rest)

ZeroDCStaticCollarsMessageStaticCollarsrepGroups ==
    [ blockLengthShort                            |-> [i \in 1 .. 1 |-> 0],
      dCStaticCollarsMessageStaticCollarsrepGroup |-> << >> ]

(* D C Static Collars Message Static Collarsrep Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCStaticCollarsMessageStaticCollarsrepGroups ==
    { ZeroDCStaticCollarsMessageStaticCollarsrepGroups }
        \cup { [ZeroDCStaticCollarsMessageStaticCollarsrepGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCStaticCollarsMessageStaticCollarsrepGroups EXCEPT !.dCStaticCollarsMessageStaticCollarsrepGroup = one] : one \in SampleLists(OneDCStaticCollarsMessageStaticCollarsrepGroup) }

(***************************************************************************)
(* Dc Static Collars Message                                               *)
(***************************************************************************)

DcStaticCollarsMessage ==
    [ msgSeqNum                                    : Sample(4),
      produceTime                                  : Sample(8),
      consumeTime                                  : Sample(8),
      symbolIndex                                  : Sample(4),
      emm                                          : Sample(1),
      dCStaticCollarsMessageStaticCollarsrepGroups : DCStaticCollarsMessageStaticCollarsrepGroups ]

EncodeDcStaticCollarsMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.symbolIndex
        \o message.emm
        \o EncodeDCStaticCollarsMessageStaticCollarsrepGroups(message.dCStaticCollarsMessageStaticCollarsrepGroups)

DecodeDcStaticCollarsMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(consumeTime.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET dCStaticCollarsMessageStaticCollarsrepGroups == DecodeDCStaticCollarsMessageStaticCollarsrepGroups(emm.rest) IN IF ~dCStaticCollarsMessageStaticCollarsrepGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                                    |-> msgSeqNum.value,
         produceTime                                  |-> produceTime.value,
         consumeTime                                  |-> consumeTime.value,
         symbolIndex                                  |-> symbolIndex.value,
         emm                                          |-> emm.value,
         dCStaticCollarsMessageStaticCollarsrepGroups |-> dCStaticCollarsMessageStaticCollarsrepGroups.value ], dCStaticCollarsMessageStaticCollarsrepGroups.rest)

ZeroDcStaticCollarsMessage ==
    [ msgSeqNum                                    |-> [i \in 1 .. 4 |-> 0],
      produceTime                                  |-> [i \in 1 .. 8 |-> 0],
      consumeTime                                  |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                                  |-> [i \in 1 .. 4 |-> 0],
      emm                                          |-> [i \in 1 .. 1 |-> 0],
      dCStaticCollarsMessageStaticCollarsrepGroups |-> ZeroDCStaticCollarsMessageStaticCollarsrepGroups ]

(* Dc Static Collars Message at zero, then each field in turn at the values it is checked at *)
CheckedDcStaticCollarsMessage ==
    { ZeroDcStaticCollarsMessage }
        \cup { [ZeroDcStaticCollarsMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcStaticCollarsMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcStaticCollarsMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcStaticCollarsMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcStaticCollarsMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcStaticCollarsMessage EXCEPT !.dCStaticCollarsMessageStaticCollarsrepGroups = one] : one \in CheckedDCStaticCollarsMessageStaticCollarsrepGroups }

(***************************************************************************)
(* Trade Bust Notification Short Codes Details Non Modifiable Group: 3     *)
(* bytes                                                                   *)
(***************************************************************************)

TradeBustNotificationShortCodesDetailsNonModifiableGroup ==
    [ originalShortCodeType  : Sample(1),
      shortCodeRole          : Sample(1),
      shortCodeRoleQualifier : Sample(1) ]

EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroup(message) ==
    message.originalShortCodeType
        \o message.shortCodeRole
        \o message.shortCodeRoleQualifier

DecodeTradeBustNotificationShortCodesDetailsNonModifiableGroup(bytes) ==
    LET originalShortCodeType == ReadBytes(bytes, 1) IN IF ~originalShortCodeType.ok THEN Fail ELSE
    LET shortCodeRole == ReadBytes(originalShortCodeType.rest, 1) IN IF ~shortCodeRole.ok THEN Fail ELSE
    LET shortCodeRoleQualifier == ReadBytes(shortCodeRole.rest, 1) IN IF ~shortCodeRoleQualifier.ok THEN Fail ELSE
    Ok([ originalShortCodeType  |-> originalShortCodeType.value,
         shortCodeRole          |-> shortCodeRole.value,
         shortCodeRoleQualifier |-> shortCodeRoleQualifier.value ], shortCodeRoleQualifier.rest)

ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroup ==
    [ originalShortCodeType  |-> [i \in 1 .. 1 |-> 0],
      shortCodeRole          |-> [i \in 1 .. 1 |-> 0],
      shortCodeRoleQualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Bust Notification Short Codes Details Non Modifiable Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustNotificationShortCodesDetailsNonModifiableGroup ==
    { ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroup }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroup EXCEPT !.originalShortCodeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroup EXCEPT !.shortCodeRole = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroup EXCEPT !.shortCodeRoleQualifier = one] : one \in Sample(1) }

(* A run of Trade Bust Notification Short Codes Details Non Modifiable Group, written one after another *)
RECURSIVE EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroupList(_)
EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroup(Head(messages)) \o EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroupList(Tail(messages))

(* As many Trade Bust Notification Short Codes Details Non Modifiable Group as the field that counts them says *)
RECURSIVE ReadTradeBustNotificationShortCodesDetailsNonModifiableGroupList(_, _)
ReadTradeBustNotificationShortCodesDetailsNonModifiableGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBustNotificationShortCodesDetailsNonModifiableGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBustNotificationShortCodesDetailsNonModifiableGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Bust Notification Short Codes Details Non Modifiable Group of each kind, for the lists that carry them *)
OneTradeBustNotificationShortCodesDetailsNonModifiableGroup == { ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroup }

(***************************************************************************)
(* Trade Bust Notification Short Codes Details Non Modifiable Groups       *)
(***************************************************************************)

TradeBustNotificationShortCodesDetailsNonModifiableGroups ==
    [ blockLengthShort                                         : Sample(1),
      tradeBustNotificationShortCodesDetailsNonModifiableGroup : SampleLists(OneTradeBustNotificationShortCodesDetailsNonModifiableGroup) ]

EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.tradeBustNotificationShortCodesDetailsNonModifiableGroup), 1)
        \o EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroupList(message.tradeBustNotificationShortCodesDetailsNonModifiableGroup)

DecodeTradeBustNotificationShortCodesDetailsNonModifiableGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET tradeBustNotificationShortCodesDetailsNonModifiableGroup == ReadTradeBustNotificationShortCodesDetailsNonModifiableGroupList(numInGroup.rest, numInGroup.value) IN IF ~tradeBustNotificationShortCodesDetailsNonModifiableGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                         |-> blockLengthShort.value,
         tradeBustNotificationShortCodesDetailsNonModifiableGroup |-> tradeBustNotificationShortCodesDetailsNonModifiableGroup.value ], tradeBustNotificationShortCodesDetailsNonModifiableGroup.rest)

ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroups ==
    [ blockLengthShort                                         |-> [i \in 1 .. 1 |-> 0],
      tradeBustNotificationShortCodesDetailsNonModifiableGroup |-> << >> ]

(* Trade Bust Notification Short Codes Details Non Modifiable Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustNotificationShortCodesDetailsNonModifiableGroups ==
    { ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroups }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroups EXCEPT !.tradeBustNotificationShortCodesDetailsNonModifiableGroup = one] : one \in SampleLists(OneTradeBustNotificationShortCodesDetailsNonModifiableGroup) }

(***************************************************************************)
(* Trade Bust Notification Short Codes Details Modifiable Group: 3 bytes   *)
(***************************************************************************)

TradeBustNotificationShortCodesDetailsModifiableGroup ==
    [ eventShortCodeType     : Sample(1),
      shortCodeRole          : Sample(1),
      shortCodeRoleQualifier : Sample(1) ]

EncodeTradeBustNotificationShortCodesDetailsModifiableGroup(message) ==
    message.eventShortCodeType
        \o message.shortCodeRole
        \o message.shortCodeRoleQualifier

DecodeTradeBustNotificationShortCodesDetailsModifiableGroup(bytes) ==
    LET eventShortCodeType == ReadBytes(bytes, 1) IN IF ~eventShortCodeType.ok THEN Fail ELSE
    LET shortCodeRole == ReadBytes(eventShortCodeType.rest, 1) IN IF ~shortCodeRole.ok THEN Fail ELSE
    LET shortCodeRoleQualifier == ReadBytes(shortCodeRole.rest, 1) IN IF ~shortCodeRoleQualifier.ok THEN Fail ELSE
    Ok([ eventShortCodeType     |-> eventShortCodeType.value,
         shortCodeRole          |-> shortCodeRole.value,
         shortCodeRoleQualifier |-> shortCodeRoleQualifier.value ], shortCodeRoleQualifier.rest)

ZeroTradeBustNotificationShortCodesDetailsModifiableGroup ==
    [ eventShortCodeType     |-> [i \in 1 .. 1 |-> 0],
      shortCodeRole          |-> [i \in 1 .. 1 |-> 0],
      shortCodeRoleQualifier |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Bust Notification Short Codes Details Modifiable Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustNotificationShortCodesDetailsModifiableGroup ==
    { ZeroTradeBustNotificationShortCodesDetailsModifiableGroup }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsModifiableGroup EXCEPT !.eventShortCodeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsModifiableGroup EXCEPT !.shortCodeRole = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsModifiableGroup EXCEPT !.shortCodeRoleQualifier = one] : one \in Sample(1) }

(* A run of Trade Bust Notification Short Codes Details Modifiable Group, written one after another *)
RECURSIVE EncodeTradeBustNotificationShortCodesDetailsModifiableGroupList(_)
EncodeTradeBustNotificationShortCodesDetailsModifiableGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBustNotificationShortCodesDetailsModifiableGroup(Head(messages)) \o EncodeTradeBustNotificationShortCodesDetailsModifiableGroupList(Tail(messages))

(* As many Trade Bust Notification Short Codes Details Modifiable Group as the field that counts them says *)
RECURSIVE ReadTradeBustNotificationShortCodesDetailsModifiableGroupList(_, _)
ReadTradeBustNotificationShortCodesDetailsModifiableGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBustNotificationShortCodesDetailsModifiableGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBustNotificationShortCodesDetailsModifiableGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Bust Notification Short Codes Details Modifiable Group of each kind, for the lists that carry them *)
OneTradeBustNotificationShortCodesDetailsModifiableGroup == { ZeroTradeBustNotificationShortCodesDetailsModifiableGroup }

(***************************************************************************)
(* Trade Bust Notification Short Codes Details Modifiable Groups           *)
(***************************************************************************)

TradeBustNotificationShortCodesDetailsModifiableGroups ==
    [ blockLengthShort                                      : Sample(1),
      tradeBustNotificationShortCodesDetailsModifiableGroup : SampleLists(OneTradeBustNotificationShortCodesDetailsModifiableGroup) ]

EncodeTradeBustNotificationShortCodesDetailsModifiableGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.tradeBustNotificationShortCodesDetailsModifiableGroup), 1)
        \o EncodeTradeBustNotificationShortCodesDetailsModifiableGroupList(message.tradeBustNotificationShortCodesDetailsModifiableGroup)

DecodeTradeBustNotificationShortCodesDetailsModifiableGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET tradeBustNotificationShortCodesDetailsModifiableGroup == ReadTradeBustNotificationShortCodesDetailsModifiableGroupList(numInGroup.rest, numInGroup.value) IN IF ~tradeBustNotificationShortCodesDetailsModifiableGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                      |-> blockLengthShort.value,
         tradeBustNotificationShortCodesDetailsModifiableGroup |-> tradeBustNotificationShortCodesDetailsModifiableGroup.value ], tradeBustNotificationShortCodesDetailsModifiableGroup.rest)

ZeroTradeBustNotificationShortCodesDetailsModifiableGroups ==
    [ blockLengthShort                                      |-> [i \in 1 .. 1 |-> 0],
      tradeBustNotificationShortCodesDetailsModifiableGroup |-> << >> ]

(* Trade Bust Notification Short Codes Details Modifiable Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustNotificationShortCodesDetailsModifiableGroups ==
    { ZeroTradeBustNotificationShortCodesDetailsModifiableGroups }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsModifiableGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationShortCodesDetailsModifiableGroups EXCEPT !.tradeBustNotificationShortCodesDetailsModifiableGroup = one] : one \in SampleLists(OneTradeBustNotificationShortCodesDetailsModifiableGroup) }

(***************************************************************************)
(* Trade Bust Notification Message                                         *)
(***************************************************************************)

TradeBustNotificationMessage ==
    [ msgSeqNum                                                 : Sample(4),
      produceTime                                               : Sample(8),
      consumeTime                                               : Sample(8),
      firmId                                                    : Sample(8),
      oeSessionId                                               : Sample(8),
      orderSide                                                 : Sample(1),
      bookOutTime                                               : Sample(8),
      bookInTime                                                : Sample(8),
      symbolIndex                                               : Sample(4),
      emm                                                       : Sample(1),
      executionId                                               : Sample(4),
      lastShares                                                : Sample(8),
      lastTradedPx                                              : Sample(8),
      orderId                                                   : Sample(8),
      miFidIndicators                                           : Sample(1),
      clearingFirmId                                            : Sample(8),
      tradingCapacity                                           : Sample(1),
      oeginFromMember                                           : Sample(8),
      executionPhase                                            : Sample(1),
      tradeQualifier                                            : Sample(1),
      counterpartFirmId                                         : Sample(8),
      orderType                                                 : Sample(1),
      timeInForceOptional                                       : Sample(1),
      clearingInstructionOptional                               : Sample(2),
      technicalOrigin                                           : Sample(1),
      freeText                                                  : Sample(18),
      accountNumber                                             : Sample(12),
      accountType                                               : Sample(1),
      lpRoleOptional                                            : Sample(1),
      openClose                                                 : Sample(2),
      originalInvestDecisWFirmShortCode                         : Sample(4),
      originalNonExecBrokerShortCode                            : Sample(4),
      eventClientIdShortCode                                    : Sample(4),
      eventExecWFirmShortCode                                   : Sample(4),
      originalClientIdShortCode                                 : Sample(4),
      originalExecWFirmShortCode                                : Sample(4),
      clearingAccount                                           : Sample(16),
      lisTransactionId                                          : Sample(4),
      parentExecId                                              : Sample(4),
      parentSymbolIndex                                         : Sample(4),
      tradeUniqueIdentifier                                     : Sample(16),
      parentTradeUniqueIdentifier                               : Sample(16),
      tradeBustNotificationShortCodesDetailsNonModifiableGroups : TradeBustNotificationShortCodesDetailsNonModifiableGroups,
      tradeBustNotificationShortCodesDetailsModifiableGroups    : TradeBustNotificationShortCodesDetailsModifiableGroups ]

EncodeTradeBustNotificationMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.firmId
        \o message.oeSessionId
        \o message.orderSide
        \o message.bookOutTime
        \o message.bookInTime
        \o message.symbolIndex
        \o message.emm
        \o message.executionId
        \o message.lastShares
        \o message.lastTradedPx
        \o message.orderId
        \o message.miFidIndicators
        \o message.clearingFirmId
        \o message.tradingCapacity
        \o message.oeginFromMember
        \o message.executionPhase
        \o message.tradeQualifier
        \o message.counterpartFirmId
        \o message.orderType
        \o message.timeInForceOptional
        \o message.clearingInstructionOptional
        \o message.technicalOrigin
        \o message.freeText
        \o message.accountNumber
        \o message.accountType
        \o message.lpRoleOptional
        \o message.openClose
        \o message.originalInvestDecisWFirmShortCode
        \o message.originalNonExecBrokerShortCode
        \o message.eventClientIdShortCode
        \o message.eventExecWFirmShortCode
        \o message.originalClientIdShortCode
        \o message.originalExecWFirmShortCode
        \o message.clearingAccount
        \o message.lisTransactionId
        \o message.parentExecId
        \o message.parentSymbolIndex
        \o message.tradeUniqueIdentifier
        \o message.parentTradeUniqueIdentifier
        \o EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroups(message.tradeBustNotificationShortCodesDetailsNonModifiableGroups)
        \o EncodeTradeBustNotificationShortCodesDetailsModifiableGroups(message.tradeBustNotificationShortCodesDetailsModifiableGroups)

DecodeTradeBustNotificationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET firmId == ReadBytes(consumeTime.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oeSessionId == ReadBytes(firmId.rest, 8) IN IF ~oeSessionId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(oeSessionId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(orderSide.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET bookInTime == ReadBytes(bookOutTime.rest, 8) IN IF ~bookInTime.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(bookInTime.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET executionId == ReadBytes(emm.rest, 4) IN IF ~executionId.ok THEN Fail ELSE
    LET lastShares == ReadBytes(executionId.rest, 8) IN IF ~lastShares.ok THEN Fail ELSE
    LET lastTradedPx == ReadBytes(lastShares.rest, 8) IN IF ~lastTradedPx.ok THEN Fail ELSE
    LET orderId == ReadBytes(lastTradedPx.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET miFidIndicators == ReadBytes(orderId.rest, 1) IN IF ~miFidIndicators.ok THEN Fail ELSE
    LET clearingFirmId == ReadBytes(miFidIndicators.rest, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(clearingFirmId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET oeginFromMember == ReadBytes(tradingCapacity.rest, 8) IN IF ~oeginFromMember.ok THEN Fail ELSE
    LET executionPhase == ReadBytes(oeginFromMember.rest, 1) IN IF ~executionPhase.ok THEN Fail ELSE
    LET tradeQualifier == ReadBytes(executionPhase.rest, 1) IN IF ~tradeQualifier.ok THEN Fail ELSE
    LET counterpartFirmId == ReadBytes(tradeQualifier.rest, 8) IN IF ~counterpartFirmId.ok THEN Fail ELSE
    LET orderType == ReadBytes(counterpartFirmId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET timeInForceOptional == ReadBytes(orderType.rest, 1) IN IF ~timeInForceOptional.ok THEN Fail ELSE
    LET clearingInstructionOptional == ReadBytes(timeInForceOptional.rest, 2) IN IF ~clearingInstructionOptional.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(clearingInstructionOptional.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET freeText == ReadBytes(technicalOrigin.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(freeText.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET accountType == ReadBytes(accountNumber.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET lpRoleOptional == ReadBytes(accountType.rest, 1) IN IF ~lpRoleOptional.ok THEN Fail ELSE
    LET openClose == ReadBytes(lpRoleOptional.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET originalInvestDecisWFirmShortCode == ReadBytes(openClose.rest, 4) IN IF ~originalInvestDecisWFirmShortCode.ok THEN Fail ELSE
    LET originalNonExecBrokerShortCode == ReadBytes(originalInvestDecisWFirmShortCode.rest, 4) IN IF ~originalNonExecBrokerShortCode.ok THEN Fail ELSE
    LET eventClientIdShortCode == ReadBytes(originalNonExecBrokerShortCode.rest, 4) IN IF ~eventClientIdShortCode.ok THEN Fail ELSE
    LET eventExecWFirmShortCode == ReadBytes(eventClientIdShortCode.rest, 4) IN IF ~eventExecWFirmShortCode.ok THEN Fail ELSE
    LET originalClientIdShortCode == ReadBytes(eventExecWFirmShortCode.rest, 4) IN IF ~originalClientIdShortCode.ok THEN Fail ELSE
    LET originalExecWFirmShortCode == ReadBytes(originalClientIdShortCode.rest, 4) IN IF ~originalExecWFirmShortCode.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(originalExecWFirmShortCode.rest, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET lisTransactionId == ReadBytes(clearingAccount.rest, 4) IN IF ~lisTransactionId.ok THEN Fail ELSE
    LET parentExecId == ReadBytes(lisTransactionId.rest, 4) IN IF ~parentExecId.ok THEN Fail ELSE
    LET parentSymbolIndex == ReadBytes(parentExecId.rest, 4) IN IF ~parentSymbolIndex.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(parentSymbolIndex.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    LET parentTradeUniqueIdentifier == ReadBytes(tradeUniqueIdentifier.rest, 16) IN IF ~parentTradeUniqueIdentifier.ok THEN Fail ELSE
    LET tradeBustNotificationShortCodesDetailsNonModifiableGroups == DecodeTradeBustNotificationShortCodesDetailsNonModifiableGroups(parentTradeUniqueIdentifier.rest) IN IF ~tradeBustNotificationShortCodesDetailsNonModifiableGroups.ok THEN Fail ELSE
    LET tradeBustNotificationShortCodesDetailsModifiableGroups == DecodeTradeBustNotificationShortCodesDetailsModifiableGroups(tradeBustNotificationShortCodesDetailsNonModifiableGroups.rest) IN IF ~tradeBustNotificationShortCodesDetailsModifiableGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                                                 |-> msgSeqNum.value,
         produceTime                                               |-> produceTime.value,
         consumeTime                                               |-> consumeTime.value,
         firmId                                                    |-> firmId.value,
         oeSessionId                                               |-> oeSessionId.value,
         orderSide                                                 |-> orderSide.value,
         bookOutTime                                               |-> bookOutTime.value,
         bookInTime                                                |-> bookInTime.value,
         symbolIndex                                               |-> symbolIndex.value,
         emm                                                       |-> emm.value,
         executionId                                               |-> executionId.value,
         lastShares                                                |-> lastShares.value,
         lastTradedPx                                              |-> lastTradedPx.value,
         orderId                                                   |-> orderId.value,
         miFidIndicators                                           |-> miFidIndicators.value,
         clearingFirmId                                            |-> clearingFirmId.value,
         tradingCapacity                                           |-> tradingCapacity.value,
         oeginFromMember                                           |-> oeginFromMember.value,
         executionPhase                                            |-> executionPhase.value,
         tradeQualifier                                            |-> tradeQualifier.value,
         counterpartFirmId                                         |-> counterpartFirmId.value,
         orderType                                                 |-> orderType.value,
         timeInForceOptional                                       |-> timeInForceOptional.value,
         clearingInstructionOptional                               |-> clearingInstructionOptional.value,
         technicalOrigin                                           |-> technicalOrigin.value,
         freeText                                                  |-> freeText.value,
         accountNumber                                             |-> accountNumber.value,
         accountType                                               |-> accountType.value,
         lpRoleOptional                                            |-> lpRoleOptional.value,
         openClose                                                 |-> openClose.value,
         originalInvestDecisWFirmShortCode                         |-> originalInvestDecisWFirmShortCode.value,
         originalNonExecBrokerShortCode                            |-> originalNonExecBrokerShortCode.value,
         eventClientIdShortCode                                    |-> eventClientIdShortCode.value,
         eventExecWFirmShortCode                                   |-> eventExecWFirmShortCode.value,
         originalClientIdShortCode                                 |-> originalClientIdShortCode.value,
         originalExecWFirmShortCode                                |-> originalExecWFirmShortCode.value,
         clearingAccount                                           |-> clearingAccount.value,
         lisTransactionId                                          |-> lisTransactionId.value,
         parentExecId                                              |-> parentExecId.value,
         parentSymbolIndex                                         |-> parentSymbolIndex.value,
         tradeUniqueIdentifier                                     |-> tradeUniqueIdentifier.value,
         parentTradeUniqueIdentifier                               |-> parentTradeUniqueIdentifier.value,
         tradeBustNotificationShortCodesDetailsNonModifiableGroups |-> tradeBustNotificationShortCodesDetailsNonModifiableGroups.value,
         tradeBustNotificationShortCodesDetailsModifiableGroups    |-> tradeBustNotificationShortCodesDetailsModifiableGroups.value ], tradeBustNotificationShortCodesDetailsModifiableGroups.rest)

ZeroTradeBustNotificationMessage ==
    [ msgSeqNum                                                 |-> [i \in 1 .. 4 |-> 0],
      produceTime                                               |-> [i \in 1 .. 8 |-> 0],
      consumeTime                                               |-> [i \in 1 .. 8 |-> 0],
      firmId                                                    |-> [i \in 1 .. 8 |-> 0],
      oeSessionId                                               |-> [i \in 1 .. 8 |-> 0],
      orderSide                                                 |-> [i \in 1 .. 1 |-> 0],
      bookOutTime                                               |-> [i \in 1 .. 8 |-> 0],
      bookInTime                                                |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                                               |-> [i \in 1 .. 4 |-> 0],
      emm                                                       |-> [i \in 1 .. 1 |-> 0],
      executionId                                               |-> [i \in 1 .. 4 |-> 0],
      lastShares                                                |-> [i \in 1 .. 8 |-> 0],
      lastTradedPx                                              |-> [i \in 1 .. 8 |-> 0],
      orderId                                                   |-> [i \in 1 .. 8 |-> 0],
      miFidIndicators                                           |-> [i \in 1 .. 1 |-> 0],
      clearingFirmId                                            |-> [i \in 1 .. 8 |-> 0],
      tradingCapacity                                           |-> [i \in 1 .. 1 |-> 0],
      oeginFromMember                                           |-> [i \in 1 .. 8 |-> 0],
      executionPhase                                            |-> [i \in 1 .. 1 |-> 0],
      tradeQualifier                                            |-> [i \in 1 .. 1 |-> 0],
      counterpartFirmId                                         |-> [i \in 1 .. 8 |-> 0],
      orderType                                                 |-> [i \in 1 .. 1 |-> 0],
      timeInForceOptional                                       |-> [i \in 1 .. 1 |-> 0],
      clearingInstructionOptional                               |-> [i \in 1 .. 2 |-> 0],
      technicalOrigin                                           |-> [i \in 1 .. 1 |-> 0],
      freeText                                                  |-> [i \in 1 .. 18 |-> 0],
      accountNumber                                             |-> [i \in 1 .. 12 |-> 0],
      accountType                                               |-> [i \in 1 .. 1 |-> 0],
      lpRoleOptional                                            |-> [i \in 1 .. 1 |-> 0],
      openClose                                                 |-> [i \in 1 .. 2 |-> 0],
      originalInvestDecisWFirmShortCode                         |-> [i \in 1 .. 4 |-> 0],
      originalNonExecBrokerShortCode                            |-> [i \in 1 .. 4 |-> 0],
      eventClientIdShortCode                                    |-> [i \in 1 .. 4 |-> 0],
      eventExecWFirmShortCode                                   |-> [i \in 1 .. 4 |-> 0],
      originalClientIdShortCode                                 |-> [i \in 1 .. 4 |-> 0],
      originalExecWFirmShortCode                                |-> [i \in 1 .. 4 |-> 0],
      clearingAccount                                           |-> [i \in 1 .. 16 |-> 0],
      lisTransactionId                                          |-> [i \in 1 .. 4 |-> 0],
      parentExecId                                              |-> [i \in 1 .. 4 |-> 0],
      parentSymbolIndex                                         |-> [i \in 1 .. 4 |-> 0],
      tradeUniqueIdentifier                                     |-> [i \in 1 .. 16 |-> 0],
      parentTradeUniqueIdentifier                               |-> [i \in 1 .. 16 |-> 0],
      tradeBustNotificationShortCodesDetailsNonModifiableGroups |-> ZeroTradeBustNotificationShortCodesDetailsNonModifiableGroups,
      tradeBustNotificationShortCodesDetailsModifiableGroups    |-> ZeroTradeBustNotificationShortCodesDetailsModifiableGroups ]

(* Trade Bust Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustNotificationMessage ==
    { ZeroTradeBustNotificationMessage }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.oeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.bookInTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.executionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.lastShares = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.lastTradedPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.miFidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.oeginFromMember = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.executionPhase = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.tradeQualifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.counterpartFirmId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.timeInForceOptional = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.clearingInstructionOptional = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.lpRoleOptional = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.originalInvestDecisWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.originalNonExecBrokerShortCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.eventClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.eventExecWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.originalClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.originalExecWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.clearingAccount = one] : one \in Sample(16) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.lisTransactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.parentExecId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.parentSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.parentTradeUniqueIdentifier = one] : one \in Sample(16) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.tradeBustNotificationShortCodesDetailsNonModifiableGroups = one] : one \in CheckedTradeBustNotificationShortCodesDetailsNonModifiableGroups }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.tradeBustNotificationShortCodesDetailsModifiableGroups = one] : one \in CheckedTradeBustNotificationShortCodesDetailsModifiableGroups }

(***************************************************************************)
(* D C Quote Message Bid Quoterep Group: 68 bytes                          *)
(***************************************************************************)

DCQuoteMessageBidQuoterepGroup ==
    [ bidSize           : Sample(8),
      bidPx             : Sample(8),
      bidQuotePriority  : Sample(8),
      bidOrderId        : Sample(8),
      buyRevisionFlag   : Sample(1),
      bidErrorCode      : Sample(2),
      bidOeSessionId    : Sample(8),
      rfeAnswerOptional : Sample(1),
      bidLeavesQuantity : Sample(8),
      bidPreviousSize   : Sample(8),
      bidPreviousPx     : Sample(8) ]

EncodeDCQuoteMessageBidQuoterepGroup(message) ==
    message.bidSize
        \o message.bidPx
        \o message.bidQuotePriority
        \o message.bidOrderId
        \o message.buyRevisionFlag
        \o message.bidErrorCode
        \o message.bidOeSessionId
        \o message.rfeAnswerOptional
        \o message.bidLeavesQuantity
        \o message.bidPreviousSize
        \o message.bidPreviousPx

DecodeDCQuoteMessageBidQuoterepGroup(bytes) ==
    LET bidSize == ReadBytes(bytes, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPx == ReadBytes(bidSize.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidQuotePriority == ReadBytes(bidPx.rest, 8) IN IF ~bidQuotePriority.ok THEN Fail ELSE
    LET bidOrderId == ReadBytes(bidQuotePriority.rest, 8) IN IF ~bidOrderId.ok THEN Fail ELSE
    LET buyRevisionFlag == ReadBytes(bidOrderId.rest, 1) IN IF ~buyRevisionFlag.ok THEN Fail ELSE
    LET bidErrorCode == ReadBytes(buyRevisionFlag.rest, 2) IN IF ~bidErrorCode.ok THEN Fail ELSE
    LET bidOeSessionId == ReadBytes(bidErrorCode.rest, 8) IN IF ~bidOeSessionId.ok THEN Fail ELSE
    LET rfeAnswerOptional == ReadBytes(bidOeSessionId.rest, 1) IN IF ~rfeAnswerOptional.ok THEN Fail ELSE
    LET bidLeavesQuantity == ReadBytes(rfeAnswerOptional.rest, 8) IN IF ~bidLeavesQuantity.ok THEN Fail ELSE
    LET bidPreviousSize == ReadBytes(bidLeavesQuantity.rest, 8) IN IF ~bidPreviousSize.ok THEN Fail ELSE
    LET bidPreviousPx == ReadBytes(bidPreviousSize.rest, 8) IN IF ~bidPreviousPx.ok THEN Fail ELSE
    Ok([ bidSize           |-> bidSize.value,
         bidPx             |-> bidPx.value,
         bidQuotePriority  |-> bidQuotePriority.value,
         bidOrderId        |-> bidOrderId.value,
         buyRevisionFlag   |-> buyRevisionFlag.value,
         bidErrorCode      |-> bidErrorCode.value,
         bidOeSessionId    |-> bidOeSessionId.value,
         rfeAnswerOptional |-> rfeAnswerOptional.value,
         bidLeavesQuantity |-> bidLeavesQuantity.value,
         bidPreviousSize   |-> bidPreviousSize.value,
         bidPreviousPx     |-> bidPreviousPx.value ], bidPreviousPx.rest)

ZeroDCQuoteMessageBidQuoterepGroup ==
    [ bidSize           |-> [i \in 1 .. 8 |-> 0],
      bidPx             |-> [i \in 1 .. 8 |-> 0],
      bidQuotePriority  |-> [i \in 1 .. 8 |-> 0],
      bidOrderId        |-> [i \in 1 .. 8 |-> 0],
      buyRevisionFlag   |-> [i \in 1 .. 1 |-> 0],
      bidErrorCode      |-> [i \in 1 .. 2 |-> 0],
      bidOeSessionId    |-> [i \in 1 .. 8 |-> 0],
      rfeAnswerOptional |-> [i \in 1 .. 1 |-> 0],
      bidLeavesQuantity |-> [i \in 1 .. 8 |-> 0],
      bidPreviousSize   |-> [i \in 1 .. 8 |-> 0],
      bidPreviousPx     |-> [i \in 1 .. 8 |-> 0] ]

(* D C Quote Message Bid Quoterep Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageBidQuoterepGroup ==
    { ZeroDCQuoteMessageBidQuoterepGroup }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidQuotePriority = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.buyRevisionFlag = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidErrorCode = one] : one \in Sample(2) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidOeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.rfeAnswerOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidLeavesQuantity = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidPreviousSize = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroup EXCEPT !.bidPreviousPx = one] : one \in Sample(8) }

(* A run of D C Quote Message Bid Quoterep Group, written one after another *)
RECURSIVE EncodeDCQuoteMessageBidQuoterepGroupList(_)
EncodeDCQuoteMessageBidQuoterepGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteMessageBidQuoterepGroup(Head(messages)) \o EncodeDCQuoteMessageBidQuoterepGroupList(Tail(messages))

(* As many D C Quote Message Bid Quoterep Group as the field that counts them says *)
RECURSIVE ReadDCQuoteMessageBidQuoterepGroupList(_, _)
ReadDCQuoteMessageBidQuoterepGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteMessageBidQuoterepGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteMessageBidQuoterepGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Message Bid Quoterep Group of each kind, for the lists that carry them *)
OneDCQuoteMessageBidQuoterepGroup == { ZeroDCQuoteMessageBidQuoterepGroup }

(***************************************************************************)
(* D C Quote Message Bid Quoterep Groups                                   *)
(***************************************************************************)

DCQuoteMessageBidQuoterepGroups ==
    [ blockLengthShort               : Sample(1),
      dCQuoteMessageBidQuoterepGroup : SampleLists(OneDCQuoteMessageBidQuoterepGroup) ]

EncodeDCQuoteMessageBidQuoterepGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteMessageBidQuoterepGroup), 1)
        \o EncodeDCQuoteMessageBidQuoterepGroupList(message.dCQuoteMessageBidQuoterepGroup)

DecodeDCQuoteMessageBidQuoterepGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteMessageBidQuoterepGroup == ReadDCQuoteMessageBidQuoterepGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteMessageBidQuoterepGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort               |-> blockLengthShort.value,
         dCQuoteMessageBidQuoterepGroup |-> dCQuoteMessageBidQuoterepGroup.value ], dCQuoteMessageBidQuoterepGroup.rest)

ZeroDCQuoteMessageBidQuoterepGroups ==
    [ blockLengthShort               |-> [i \in 1 .. 1 |-> 0],
      dCQuoteMessageBidQuoterepGroup |-> << >> ]

(* D C Quote Message Bid Quoterep Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageBidQuoterepGroups ==
    { ZeroDCQuoteMessageBidQuoterepGroups }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageBidQuoterepGroups EXCEPT !.dCQuoteMessageBidQuoterepGroup = one] : one \in SampleLists(OneDCQuoteMessageBidQuoterepGroup) }

(***************************************************************************)
(* D C Quote Message Offer Quoterep Group: 68 bytes                        *)
(***************************************************************************)

DCQuoteMessageOfferQuoterepGroup ==
    [ offerSize           : Sample(8),
      offerPx             : Sample(8),
      offerQuotePriority  : Sample(8),
      offerOrderId        : Sample(8),
      sellRevisionFlag    : Sample(1),
      offerErrorCode      : Sample(2),
      offerOeSessionId    : Sample(8),
      rfeAnswerOptional   : Sample(1),
      offerLeavesQuantity : Sample(8),
      offerPreviousSize   : Sample(8),
      offerPreviousPx     : Sample(8) ]

EncodeDCQuoteMessageOfferQuoterepGroup(message) ==
    message.offerSize
        \o message.offerPx
        \o message.offerQuotePriority
        \o message.offerOrderId
        \o message.sellRevisionFlag
        \o message.offerErrorCode
        \o message.offerOeSessionId
        \o message.rfeAnswerOptional
        \o message.offerLeavesQuantity
        \o message.offerPreviousSize
        \o message.offerPreviousPx

DecodeDCQuoteMessageOfferQuoterepGroup(bytes) ==
    LET offerSize == ReadBytes(bytes, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(offerSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerQuotePriority == ReadBytes(offerPx.rest, 8) IN IF ~offerQuotePriority.ok THEN Fail ELSE
    LET offerOrderId == ReadBytes(offerQuotePriority.rest, 8) IN IF ~offerOrderId.ok THEN Fail ELSE
    LET sellRevisionFlag == ReadBytes(offerOrderId.rest, 1) IN IF ~sellRevisionFlag.ok THEN Fail ELSE
    LET offerErrorCode == ReadBytes(sellRevisionFlag.rest, 2) IN IF ~offerErrorCode.ok THEN Fail ELSE
    LET offerOeSessionId == ReadBytes(offerErrorCode.rest, 8) IN IF ~offerOeSessionId.ok THEN Fail ELSE
    LET rfeAnswerOptional == ReadBytes(offerOeSessionId.rest, 1) IN IF ~rfeAnswerOptional.ok THEN Fail ELSE
    LET offerLeavesQuantity == ReadBytes(rfeAnswerOptional.rest, 8) IN IF ~offerLeavesQuantity.ok THEN Fail ELSE
    LET offerPreviousSize == ReadBytes(offerLeavesQuantity.rest, 8) IN IF ~offerPreviousSize.ok THEN Fail ELSE
    LET offerPreviousPx == ReadBytes(offerPreviousSize.rest, 8) IN IF ~offerPreviousPx.ok THEN Fail ELSE
    Ok([ offerSize           |-> offerSize.value,
         offerPx             |-> offerPx.value,
         offerQuotePriority  |-> offerQuotePriority.value,
         offerOrderId        |-> offerOrderId.value,
         sellRevisionFlag    |-> sellRevisionFlag.value,
         offerErrorCode      |-> offerErrorCode.value,
         offerOeSessionId    |-> offerOeSessionId.value,
         rfeAnswerOptional   |-> rfeAnswerOptional.value,
         offerLeavesQuantity |-> offerLeavesQuantity.value,
         offerPreviousSize   |-> offerPreviousSize.value,
         offerPreviousPx     |-> offerPreviousPx.value ], offerPreviousPx.rest)

ZeroDCQuoteMessageOfferQuoterepGroup ==
    [ offerSize           |-> [i \in 1 .. 8 |-> 0],
      offerPx             |-> [i \in 1 .. 8 |-> 0],
      offerQuotePriority  |-> [i \in 1 .. 8 |-> 0],
      offerOrderId        |-> [i \in 1 .. 8 |-> 0],
      sellRevisionFlag    |-> [i \in 1 .. 1 |-> 0],
      offerErrorCode      |-> [i \in 1 .. 2 |-> 0],
      offerOeSessionId    |-> [i \in 1 .. 8 |-> 0],
      rfeAnswerOptional   |-> [i \in 1 .. 1 |-> 0],
      offerLeavesQuantity |-> [i \in 1 .. 8 |-> 0],
      offerPreviousSize   |-> [i \in 1 .. 8 |-> 0],
      offerPreviousPx     |-> [i \in 1 .. 8 |-> 0] ]

(* D C Quote Message Offer Quoterep Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageOfferQuoterepGroup ==
    { ZeroDCQuoteMessageOfferQuoterepGroup }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerQuotePriority = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.sellRevisionFlag = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerErrorCode = one] : one \in Sample(2) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerOeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.rfeAnswerOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerLeavesQuantity = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerPreviousSize = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroup EXCEPT !.offerPreviousPx = one] : one \in Sample(8) }

(* A run of D C Quote Message Offer Quoterep Group, written one after another *)
RECURSIVE EncodeDCQuoteMessageOfferQuoterepGroupList(_)
EncodeDCQuoteMessageOfferQuoterepGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteMessageOfferQuoterepGroup(Head(messages)) \o EncodeDCQuoteMessageOfferQuoterepGroupList(Tail(messages))

(* As many D C Quote Message Offer Quoterep Group as the field that counts them says *)
RECURSIVE ReadDCQuoteMessageOfferQuoterepGroupList(_, _)
ReadDCQuoteMessageOfferQuoterepGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteMessageOfferQuoterepGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteMessageOfferQuoterepGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Message Offer Quoterep Group of each kind, for the lists that carry them *)
OneDCQuoteMessageOfferQuoterepGroup == { ZeroDCQuoteMessageOfferQuoterepGroup }

(***************************************************************************)
(* D C Quote Message Offer Quoterep Groups                                 *)
(***************************************************************************)

DCQuoteMessageOfferQuoterepGroups ==
    [ blockLengthShort                 : Sample(1),
      dCQuoteMessageOfferQuoterepGroup : SampleLists(OneDCQuoteMessageOfferQuoterepGroup) ]

EncodeDCQuoteMessageOfferQuoterepGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteMessageOfferQuoterepGroup), 1)
        \o EncodeDCQuoteMessageOfferQuoterepGroupList(message.dCQuoteMessageOfferQuoterepGroup)

DecodeDCQuoteMessageOfferQuoterepGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteMessageOfferQuoterepGroup == ReadDCQuoteMessageOfferQuoterepGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteMessageOfferQuoterepGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                 |-> blockLengthShort.value,
         dCQuoteMessageOfferQuoterepGroup |-> dCQuoteMessageOfferQuoterepGroup.value ], dCQuoteMessageOfferQuoterepGroup.rest)

ZeroDCQuoteMessageOfferQuoterepGroups ==
    [ blockLengthShort                 |-> [i \in 1 .. 1 |-> 0],
      dCQuoteMessageOfferQuoterepGroup |-> << >> ]

(* D C Quote Message Offer Quoterep Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageOfferQuoterepGroups ==
    { ZeroDCQuoteMessageOfferQuoterepGroups }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageOfferQuoterepGroups EXCEPT !.dCQuoteMessageOfferQuoterepGroup = one] : one \in SampleLists(OneDCQuoteMessageOfferQuoterepGroup) }

(***************************************************************************)
(* D C Quote Message Clearing Dataset Group: 51 bytes                      *)
(***************************************************************************)

DCQuoteMessageClearingDatasetGroup ==
    [ clearingFirmIdOptional      : Sample(8),
      clientId                    : Sample(8),
      accountNumber               : Sample(12),
      technicalOrigin             : Sample(1),
      openClose                   : Sample(2),
      clearingInstructionOptional : Sample(2),
      freeText                    : Sample(18) ]

EncodeDCQuoteMessageClearingDatasetGroup(message) ==
    message.clearingFirmIdOptional
        \o message.clientId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstructionOptional
        \o message.freeText

DecodeDCQuoteMessageClearingDatasetGroup(bytes) ==
    LET clearingFirmIdOptional == ReadBytes(bytes, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET clientId == ReadBytes(clearingFirmIdOptional.rest, 8) IN IF ~clientId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(clientId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstructionOptional == ReadBytes(openClose.rest, 2) IN IF ~clearingInstructionOptional.ok THEN Fail ELSE
    LET freeText == ReadBytes(clearingInstructionOptional.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    Ok([ clearingFirmIdOptional      |-> clearingFirmIdOptional.value,
         clientId                    |-> clientId.value,
         accountNumber               |-> accountNumber.value,
         technicalOrigin             |-> technicalOrigin.value,
         openClose                   |-> openClose.value,
         clearingInstructionOptional |-> clearingInstructionOptional.value,
         freeText                    |-> freeText.value ], freeText.rest)

ZeroDCQuoteMessageClearingDatasetGroup ==
    [ clearingFirmIdOptional      |-> [i \in 1 .. 8 |-> 0],
      clientId                    |-> [i \in 1 .. 8 |-> 0],
      accountNumber               |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin             |-> [i \in 1 .. 1 |-> 0],
      openClose                   |-> [i \in 1 .. 2 |-> 0],
      clearingInstructionOptional |-> [i \in 1 .. 2 |-> 0],
      freeText                    |-> [i \in 1 .. 18 |-> 0] ]

(* D C Quote Message Clearing Dataset Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageClearingDatasetGroup ==
    { ZeroDCQuoteMessageClearingDatasetGroup }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroup EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroup EXCEPT !.clientId = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroup EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroup EXCEPT !.clearingInstructionOptional = one] : one \in Sample(2) }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroup EXCEPT !.freeText = one] : one \in Sample(18) }

(* A run of D C Quote Message Clearing Dataset Group, written one after another *)
RECURSIVE EncodeDCQuoteMessageClearingDatasetGroupList(_)
EncodeDCQuoteMessageClearingDatasetGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteMessageClearingDatasetGroup(Head(messages)) \o EncodeDCQuoteMessageClearingDatasetGroupList(Tail(messages))

(* As many D C Quote Message Clearing Dataset Group as the field that counts them says *)
RECURSIVE ReadDCQuoteMessageClearingDatasetGroupList(_, _)
ReadDCQuoteMessageClearingDatasetGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteMessageClearingDatasetGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteMessageClearingDatasetGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Message Clearing Dataset Group of each kind, for the lists that carry them *)
OneDCQuoteMessageClearingDatasetGroup == { ZeroDCQuoteMessageClearingDatasetGroup }

(***************************************************************************)
(* D C Quote Message Clearing Dataset Groups                               *)
(***************************************************************************)

DCQuoteMessageClearingDatasetGroups ==
    [ blockLengthShort                   : Sample(1),
      dCQuoteMessageClearingDatasetGroup : SampleLists(OneDCQuoteMessageClearingDatasetGroup) ]

EncodeDCQuoteMessageClearingDatasetGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteMessageClearingDatasetGroup), 1)
        \o EncodeDCQuoteMessageClearingDatasetGroupList(message.dCQuoteMessageClearingDatasetGroup)

DecodeDCQuoteMessageClearingDatasetGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteMessageClearingDatasetGroup == ReadDCQuoteMessageClearingDatasetGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteMessageClearingDatasetGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                   |-> blockLengthShort.value,
         dCQuoteMessageClearingDatasetGroup |-> dCQuoteMessageClearingDatasetGroup.value ], dCQuoteMessageClearingDatasetGroup.rest)

ZeroDCQuoteMessageClearingDatasetGroups ==
    [ blockLengthShort                   |-> [i \in 1 .. 1 |-> 0],
      dCQuoteMessageClearingDatasetGroup |-> << >> ]

(* D C Quote Message Clearing Dataset Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageClearingDatasetGroups ==
    { ZeroDCQuoteMessageClearingDatasetGroups }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageClearingDatasetGroups EXCEPT !.dCQuoteMessageClearingDatasetGroup = one] : one \in SampleLists(OneDCQuoteMessageClearingDatasetGroup) }

(***************************************************************************)
(* D C Quote Message Non Modifiable Short Codes Group: 16 bytes            *)
(***************************************************************************)

DCQuoteMessageNonModifiableShortCodesGroup ==
    [ originalClientIdShortCode         : Sample(4),
      originalExecWFirmShortCode        : Sample(4),
      originalInvestDecisWFirmShortCode : Sample(4),
      originalNonExecBrokerShortCode    : Sample(4) ]

EncodeDCQuoteMessageNonModifiableShortCodesGroup(message) ==
    message.originalClientIdShortCode
        \o message.originalExecWFirmShortCode
        \o message.originalInvestDecisWFirmShortCode
        \o message.originalNonExecBrokerShortCode

DecodeDCQuoteMessageNonModifiableShortCodesGroup(bytes) ==
    LET originalClientIdShortCode == ReadBytes(bytes, 4) IN IF ~originalClientIdShortCode.ok THEN Fail ELSE
    LET originalExecWFirmShortCode == ReadBytes(originalClientIdShortCode.rest, 4) IN IF ~originalExecWFirmShortCode.ok THEN Fail ELSE
    LET originalInvestDecisWFirmShortCode == ReadBytes(originalExecWFirmShortCode.rest, 4) IN IF ~originalInvestDecisWFirmShortCode.ok THEN Fail ELSE
    LET originalNonExecBrokerShortCode == ReadBytes(originalInvestDecisWFirmShortCode.rest, 4) IN IF ~originalNonExecBrokerShortCode.ok THEN Fail ELSE
    Ok([ originalClientIdShortCode         |-> originalClientIdShortCode.value,
         originalExecWFirmShortCode        |-> originalExecWFirmShortCode.value,
         originalInvestDecisWFirmShortCode |-> originalInvestDecisWFirmShortCode.value,
         originalNonExecBrokerShortCode    |-> originalNonExecBrokerShortCode.value ], originalNonExecBrokerShortCode.rest)

ZeroDCQuoteMessageNonModifiableShortCodesGroup ==
    [ originalClientIdShortCode         |-> [i \in 1 .. 4 |-> 0],
      originalExecWFirmShortCode        |-> [i \in 1 .. 4 |-> 0],
      originalInvestDecisWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      originalNonExecBrokerShortCode    |-> [i \in 1 .. 4 |-> 0] ]

(* D C Quote Message Non Modifiable Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageNonModifiableShortCodesGroup ==
    { ZeroDCQuoteMessageNonModifiableShortCodesGroup }
        \cup { [ZeroDCQuoteMessageNonModifiableShortCodesGroup EXCEPT !.originalClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCQuoteMessageNonModifiableShortCodesGroup EXCEPT !.originalExecWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCQuoteMessageNonModifiableShortCodesGroup EXCEPT !.originalInvestDecisWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCQuoteMessageNonModifiableShortCodesGroup EXCEPT !.originalNonExecBrokerShortCode = one] : one \in Sample(4) }

(* A run of D C Quote Message Non Modifiable Short Codes Group, written one after another *)
RECURSIVE EncodeDCQuoteMessageNonModifiableShortCodesGroupList(_)
EncodeDCQuoteMessageNonModifiableShortCodesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteMessageNonModifiableShortCodesGroup(Head(messages)) \o EncodeDCQuoteMessageNonModifiableShortCodesGroupList(Tail(messages))

(* As many D C Quote Message Non Modifiable Short Codes Group as the field that counts them says *)
RECURSIVE ReadDCQuoteMessageNonModifiableShortCodesGroupList(_, _)
ReadDCQuoteMessageNonModifiableShortCodesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteMessageNonModifiableShortCodesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteMessageNonModifiableShortCodesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Message Non Modifiable Short Codes Group of each kind, for the lists that carry them *)
OneDCQuoteMessageNonModifiableShortCodesGroup == { ZeroDCQuoteMessageNonModifiableShortCodesGroup }

(***************************************************************************)
(* D C Quote Message Non Modifiable Short Codes Groups                     *)
(***************************************************************************)

DCQuoteMessageNonModifiableShortCodesGroups ==
    [ blockLengthShort                           : Sample(1),
      dCQuoteMessageNonModifiableShortCodesGroup : SampleLists(OneDCQuoteMessageNonModifiableShortCodesGroup) ]

EncodeDCQuoteMessageNonModifiableShortCodesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteMessageNonModifiableShortCodesGroup), 1)
        \o EncodeDCQuoteMessageNonModifiableShortCodesGroupList(message.dCQuoteMessageNonModifiableShortCodesGroup)

DecodeDCQuoteMessageNonModifiableShortCodesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteMessageNonModifiableShortCodesGroup == ReadDCQuoteMessageNonModifiableShortCodesGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteMessageNonModifiableShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                           |-> blockLengthShort.value,
         dCQuoteMessageNonModifiableShortCodesGroup |-> dCQuoteMessageNonModifiableShortCodesGroup.value ], dCQuoteMessageNonModifiableShortCodesGroup.rest)

ZeroDCQuoteMessageNonModifiableShortCodesGroups ==
    [ blockLengthShort                           |-> [i \in 1 .. 1 |-> 0],
      dCQuoteMessageNonModifiableShortCodesGroup |-> << >> ]

(* D C Quote Message Non Modifiable Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageNonModifiableShortCodesGroups ==
    { ZeroDCQuoteMessageNonModifiableShortCodesGroups }
        \cup { [ZeroDCQuoteMessageNonModifiableShortCodesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageNonModifiableShortCodesGroups EXCEPT !.dCQuoteMessageNonModifiableShortCodesGroup = one] : one \in SampleLists(OneDCQuoteMessageNonModifiableShortCodesGroup) }

(***************************************************************************)
(* D C Quote Message Modifiable Short Codes Group: 8 bytes                 *)
(***************************************************************************)

DCQuoteMessageModifiableShortCodesGroup ==
    [ eventClientIdShortCode  : Sample(4),
      eventExecWFirmShortCode : Sample(4) ]

EncodeDCQuoteMessageModifiableShortCodesGroup(message) ==
    message.eventClientIdShortCode
        \o message.eventExecWFirmShortCode

DecodeDCQuoteMessageModifiableShortCodesGroup(bytes) ==
    LET eventClientIdShortCode == ReadBytes(bytes, 4) IN IF ~eventClientIdShortCode.ok THEN Fail ELSE
    LET eventExecWFirmShortCode == ReadBytes(eventClientIdShortCode.rest, 4) IN IF ~eventExecWFirmShortCode.ok THEN Fail ELSE
    Ok([ eventClientIdShortCode  |-> eventClientIdShortCode.value,
         eventExecWFirmShortCode |-> eventExecWFirmShortCode.value ], eventExecWFirmShortCode.rest)

ZeroDCQuoteMessageModifiableShortCodesGroup ==
    [ eventClientIdShortCode  |-> [i \in 1 .. 4 |-> 0],
      eventExecWFirmShortCode |-> [i \in 1 .. 4 |-> 0] ]

(* D C Quote Message Modifiable Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageModifiableShortCodesGroup ==
    { ZeroDCQuoteMessageModifiableShortCodesGroup }
        \cup { [ZeroDCQuoteMessageModifiableShortCodesGroup EXCEPT !.eventClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCQuoteMessageModifiableShortCodesGroup EXCEPT !.eventExecWFirmShortCode = one] : one \in Sample(4) }

(* A run of D C Quote Message Modifiable Short Codes Group, written one after another *)
RECURSIVE EncodeDCQuoteMessageModifiableShortCodesGroupList(_)
EncodeDCQuoteMessageModifiableShortCodesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteMessageModifiableShortCodesGroup(Head(messages)) \o EncodeDCQuoteMessageModifiableShortCodesGroupList(Tail(messages))

(* As many D C Quote Message Modifiable Short Codes Group as the field that counts them says *)
RECURSIVE ReadDCQuoteMessageModifiableShortCodesGroupList(_, _)
ReadDCQuoteMessageModifiableShortCodesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteMessageModifiableShortCodesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteMessageModifiableShortCodesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Message Modifiable Short Codes Group of each kind, for the lists that carry them *)
OneDCQuoteMessageModifiableShortCodesGroup == { ZeroDCQuoteMessageModifiableShortCodesGroup }

(***************************************************************************)
(* D C Quote Message Modifiable Short Codes Groups                         *)
(***************************************************************************)

DCQuoteMessageModifiableShortCodesGroups ==
    [ blockLengthShort                        : Sample(1),
      dCQuoteMessageModifiableShortCodesGroup : SampleLists(OneDCQuoteMessageModifiableShortCodesGroup) ]

EncodeDCQuoteMessageModifiableShortCodesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteMessageModifiableShortCodesGroup), 1)
        \o EncodeDCQuoteMessageModifiableShortCodesGroupList(message.dCQuoteMessageModifiableShortCodesGroup)

DecodeDCQuoteMessageModifiableShortCodesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteMessageModifiableShortCodesGroup == ReadDCQuoteMessageModifiableShortCodesGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteMessageModifiableShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                        |-> blockLengthShort.value,
         dCQuoteMessageModifiableShortCodesGroup |-> dCQuoteMessageModifiableShortCodesGroup.value ], dCQuoteMessageModifiableShortCodesGroup.rest)

ZeroDCQuoteMessageModifiableShortCodesGroups ==
    [ blockLengthShort                        |-> [i \in 1 .. 1 |-> 0],
      dCQuoteMessageModifiableShortCodesGroup |-> << >> ]

(* D C Quote Message Modifiable Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteMessageModifiableShortCodesGroups ==
    { ZeroDCQuoteMessageModifiableShortCodesGroups }
        \cup { [ZeroDCQuoteMessageModifiableShortCodesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteMessageModifiableShortCodesGroups EXCEPT !.dCQuoteMessageModifiableShortCodesGroup = one] : one \in SampleLists(OneDCQuoteMessageModifiableShortCodesGroup) }

(***************************************************************************)
(* Dc Quote Message                                                        *)
(***************************************************************************)

DcQuoteMessage ==
    [ msgSeqNum                                   : Sample(4),
      produceTime                                 : Sample(8),
      consumeTime                                 : Sample(8),
      bookIn                                      : Sample(8),
      bookOutTime                                 : Sample(8),
      symbolIndex                                 : Sample(4),
      emm                                         : Sample(1),
      eventId                                     : Sample(8),
      clientOrderId                               : Sample(8),
      tradingCapacity                             : Sample(1),
      accountType                                 : Sample(1),
      lpRole                                      : Sample(1),
      miFidIndicators                             : Sample(1),
      rfeAnswer                                   : Sample(1),
      firmId                                      : Sample(8),
      executionInstructionOptional                : Sample(1),
      stpid                                       : Sample(2),
      dCQuoteMessageBidQuoterepGroups             : DCQuoteMessageBidQuoterepGroups,
      dCQuoteMessageOfferQuoterepGroups           : DCQuoteMessageOfferQuoterepGroups,
      dCQuoteMessageClearingDatasetGroups         : DCQuoteMessageClearingDatasetGroups,
      dCQuoteMessageNonModifiableShortCodesGroups : DCQuoteMessageNonModifiableShortCodesGroups,
      dCQuoteMessageModifiableShortCodesGroups    : DCQuoteMessageModifiableShortCodesGroups ]

EncodeDcQuoteMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.bookIn
        \o message.bookOutTime
        \o message.symbolIndex
        \o message.emm
        \o message.eventId
        \o message.clientOrderId
        \o message.tradingCapacity
        \o message.accountType
        \o message.lpRole
        \o message.miFidIndicators
        \o message.rfeAnswer
        \o message.firmId
        \o message.executionInstructionOptional
        \o message.stpid
        \o EncodeDCQuoteMessageBidQuoterepGroups(message.dCQuoteMessageBidQuoterepGroups)
        \o EncodeDCQuoteMessageOfferQuoterepGroups(message.dCQuoteMessageOfferQuoterepGroups)
        \o EncodeDCQuoteMessageClearingDatasetGroups(message.dCQuoteMessageClearingDatasetGroups)
        \o EncodeDCQuoteMessageNonModifiableShortCodesGroups(message.dCQuoteMessageNonModifiableShortCodesGroups)
        \o EncodeDCQuoteMessageModifiableShortCodesGroups(message.dCQuoteMessageModifiableShortCodesGroups)

DecodeDcQuoteMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET bookIn == ReadBytes(consumeTime.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(bookOutTime.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventId == ReadBytes(emm.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(eventId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(clientOrderId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET accountType == ReadBytes(tradingCapacity.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET lpRole == ReadBytes(accountType.rest, 1) IN IF ~lpRole.ok THEN Fail ELSE
    LET miFidIndicators == ReadBytes(lpRole.rest, 1) IN IF ~miFidIndicators.ok THEN Fail ELSE
    LET rfeAnswer == ReadBytes(miFidIndicators.rest, 1) IN IF ~rfeAnswer.ok THEN Fail ELSE
    LET firmId == ReadBytes(rfeAnswer.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET executionInstructionOptional == ReadBytes(firmId.rest, 1) IN IF ~executionInstructionOptional.ok THEN Fail ELSE
    LET stpid == ReadBytes(executionInstructionOptional.rest, 2) IN IF ~stpid.ok THEN Fail ELSE
    LET dCQuoteMessageBidQuoterepGroups == DecodeDCQuoteMessageBidQuoterepGroups(stpid.rest) IN IF ~dCQuoteMessageBidQuoterepGroups.ok THEN Fail ELSE
    LET dCQuoteMessageOfferQuoterepGroups == DecodeDCQuoteMessageOfferQuoterepGroups(dCQuoteMessageBidQuoterepGroups.rest) IN IF ~dCQuoteMessageOfferQuoterepGroups.ok THEN Fail ELSE
    LET dCQuoteMessageClearingDatasetGroups == DecodeDCQuoteMessageClearingDatasetGroups(dCQuoteMessageOfferQuoterepGroups.rest) IN IF ~dCQuoteMessageClearingDatasetGroups.ok THEN Fail ELSE
    LET dCQuoteMessageNonModifiableShortCodesGroups == DecodeDCQuoteMessageNonModifiableShortCodesGroups(dCQuoteMessageClearingDatasetGroups.rest) IN IF ~dCQuoteMessageNonModifiableShortCodesGroups.ok THEN Fail ELSE
    LET dCQuoteMessageModifiableShortCodesGroups == DecodeDCQuoteMessageModifiableShortCodesGroups(dCQuoteMessageNonModifiableShortCodesGroups.rest) IN IF ~dCQuoteMessageModifiableShortCodesGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                                   |-> msgSeqNum.value,
         produceTime                                 |-> produceTime.value,
         consumeTime                                 |-> consumeTime.value,
         bookIn                                      |-> bookIn.value,
         bookOutTime                                 |-> bookOutTime.value,
         symbolIndex                                 |-> symbolIndex.value,
         emm                                         |-> emm.value,
         eventId                                     |-> eventId.value,
         clientOrderId                               |-> clientOrderId.value,
         tradingCapacity                             |-> tradingCapacity.value,
         accountType                                 |-> accountType.value,
         lpRole                                      |-> lpRole.value,
         miFidIndicators                             |-> miFidIndicators.value,
         rfeAnswer                                   |-> rfeAnswer.value,
         firmId                                      |-> firmId.value,
         executionInstructionOptional                |-> executionInstructionOptional.value,
         stpid                                       |-> stpid.value,
         dCQuoteMessageBidQuoterepGroups             |-> dCQuoteMessageBidQuoterepGroups.value,
         dCQuoteMessageOfferQuoterepGroups           |-> dCQuoteMessageOfferQuoterepGroups.value,
         dCQuoteMessageClearingDatasetGroups         |-> dCQuoteMessageClearingDatasetGroups.value,
         dCQuoteMessageNonModifiableShortCodesGroups |-> dCQuoteMessageNonModifiableShortCodesGroups.value,
         dCQuoteMessageModifiableShortCodesGroups    |-> dCQuoteMessageModifiableShortCodesGroups.value ], dCQuoteMessageModifiableShortCodesGroups.rest)

ZeroDcQuoteMessage ==
    [ msgSeqNum                                   |-> [i \in 1 .. 4 |-> 0],
      produceTime                                 |-> [i \in 1 .. 8 |-> 0],
      consumeTime                                 |-> [i \in 1 .. 8 |-> 0],
      bookIn                                      |-> [i \in 1 .. 8 |-> 0],
      bookOutTime                                 |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                                 |-> [i \in 1 .. 4 |-> 0],
      emm                                         |-> [i \in 1 .. 1 |-> 0],
      eventId                                     |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                               |-> [i \in 1 .. 8 |-> 0],
      tradingCapacity                             |-> [i \in 1 .. 1 |-> 0],
      accountType                                 |-> [i \in 1 .. 1 |-> 0],
      lpRole                                      |-> [i \in 1 .. 1 |-> 0],
      miFidIndicators                             |-> [i \in 1 .. 1 |-> 0],
      rfeAnswer                                   |-> [i \in 1 .. 1 |-> 0],
      firmId                                      |-> [i \in 1 .. 8 |-> 0],
      executionInstructionOptional                |-> [i \in 1 .. 1 |-> 0],
      stpid                                       |-> [i \in 1 .. 2 |-> 0],
      dCQuoteMessageBidQuoterepGroups             |-> ZeroDCQuoteMessageBidQuoterepGroups,
      dCQuoteMessageOfferQuoterepGroups           |-> ZeroDCQuoteMessageOfferQuoterepGroups,
      dCQuoteMessageClearingDatasetGroups         |-> ZeroDCQuoteMessageClearingDatasetGroups,
      dCQuoteMessageNonModifiableShortCodesGroups |-> ZeroDCQuoteMessageNonModifiableShortCodesGroups,
      dCQuoteMessageModifiableShortCodesGroups    |-> ZeroDCQuoteMessageModifiableShortCodesGroups ]

(* Dc Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedDcQuoteMessage ==
    { ZeroDcQuoteMessage }
        \cup { [ZeroDcQuoteMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.lpRole = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.miFidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.rfeAnswer = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.executionInstructionOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.stpid = one] : one \in Sample(2) }
        \cup { [ZeroDcQuoteMessage EXCEPT !.dCQuoteMessageBidQuoterepGroups = one] : one \in CheckedDCQuoteMessageBidQuoterepGroups }
        \cup { [ZeroDcQuoteMessage EXCEPT !.dCQuoteMessageOfferQuoterepGroups = one] : one \in CheckedDCQuoteMessageOfferQuoterepGroups }
        \cup { [ZeroDcQuoteMessage EXCEPT !.dCQuoteMessageClearingDatasetGroups = one] : one \in CheckedDCQuoteMessageClearingDatasetGroups }
        \cup { [ZeroDcQuoteMessage EXCEPT !.dCQuoteMessageNonModifiableShortCodesGroups = one] : one \in CheckedDCQuoteMessageNonModifiableShortCodesGroups }
        \cup { [ZeroDcQuoteMessage EXCEPT !.dCQuoteMessageModifiableShortCodesGroups = one] : one \in CheckedDCQuoteMessageModifiableShortCodesGroups }

(***************************************************************************)
(* Dcafqrfe Message: 59 bytes                                              *)
(***************************************************************************)

DcafqrfeMessage ==
    [ msgSeqNum    : Sample(4),
      produceTime  : Sample(8),
      consumeTime  : Sample(8),
      afqReason    : Sample(1),
      bookOutTime  : Sample(8),
      emm          : Sample(1),
      eventId      : Sample(8),
      symbolIndex  : Sample(4),
      firmId       : Sample(8),
      afqIndicator : Sample(1),
      oeSessionId  : Sample(8) ]

EncodeDcafqrfeMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.afqReason
        \o message.bookOutTime
        \o message.emm
        \o message.eventId
        \o message.symbolIndex
        \o message.firmId
        \o message.afqIndicator
        \o message.oeSessionId

DecodeDcafqrfeMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET afqReason == ReadBytes(consumeTime.rest, 1) IN IF ~afqReason.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(afqReason.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET emm == ReadBytes(bookOutTime.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET eventId == ReadBytes(emm.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(eventId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET firmId == ReadBytes(symbolIndex.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET afqIndicator == ReadBytes(firmId.rest, 1) IN IF ~afqIndicator.ok THEN Fail ELSE
    LET oeSessionId == ReadBytes(afqIndicator.rest, 8) IN IF ~oeSessionId.ok THEN Fail ELSE
    Ok([ msgSeqNum    |-> msgSeqNum.value,
         produceTime  |-> produceTime.value,
         consumeTime  |-> consumeTime.value,
         afqReason    |-> afqReason.value,
         bookOutTime  |-> bookOutTime.value,
         emm          |-> emm.value,
         eventId      |-> eventId.value,
         symbolIndex  |-> symbolIndex.value,
         firmId       |-> firmId.value,
         afqIndicator |-> afqIndicator.value,
         oeSessionId  |-> oeSessionId.value ], oeSessionId.rest)

ZeroDcafqrfeMessage ==
    [ msgSeqNum    |-> [i \in 1 .. 4 |-> 0],
      produceTime  |-> [i \in 1 .. 8 |-> 0],
      consumeTime  |-> [i \in 1 .. 8 |-> 0],
      afqReason    |-> [i \in 1 .. 1 |-> 0],
      bookOutTime  |-> [i \in 1 .. 8 |-> 0],
      emm          |-> [i \in 1 .. 1 |-> 0],
      eventId      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex  |-> [i \in 1 .. 4 |-> 0],
      firmId       |-> [i \in 1 .. 8 |-> 0],
      afqIndicator |-> [i \in 1 .. 1 |-> 0],
      oeSessionId  |-> [i \in 1 .. 8 |-> 0] ]

(* Dcafqrfe Message at zero, then each field in turn at the values it is checked at *)
CheckedDcafqrfeMessage ==
    { ZeroDcafqrfeMessage }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.afqReason = one] : one \in Sample(1) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.afqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDcafqrfeMessage EXCEPT !.oeSessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Dc Declaration New Message: 221 bytes                                   *)
(***************************************************************************)

DcDeclarationNewMessage ==
    [ msgSeqNum              : Sample(4),
      produceTime            : Sample(8),
      consumeTime            : Sample(8),
      messageSendingTime     : Sample(8),
      bookIn                 : Sample(8),
      bookOutTime            : Sample(8),
      oeginFromMember        : Sample(8),
      oegoutTimeToMe         : Sample(8),
      eventId                : Sample(8),
      declarationEventType   : Sample(1),
      firmId                 : Sample(8),
      oeSessionId            : Sample(8),
      accountType            : Sample(1),
      clientOrderId          : Sample(8),
      emm                    : Sample(1),
      declarationId          : Sample(8),
      declarationStatus      : Sample(1),
      priceOptional          : Sample(8),
      quantityOptional       : Sample(8),
      side                   : Sample(1),
      symbolIndex            : Sample(4),
      operationType          : Sample(1),
      crossOrderIndicator    : Sample(1),
      enteringCounterparty   : Sample(8),
      traderId               : Sample(16),
      investorId             : Sample(16),
      freeText               : Sample(18),
      principalCode          : Sample(8),
      clearingFirmIdOptional : Sample(8),
      clearingAccount        : Sample(16),
      settlementPeriod       : Sample(1),
      settlementFlag         : Sample(1),
      guaranteeFlag          : Sample(1),
      transactionPriceType   : Sample(1) ]

EncodeDcDeclarationNewMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.messageSendingTime
        \o message.bookIn
        \o message.bookOutTime
        \o message.oeginFromMember
        \o message.oegoutTimeToMe
        \o message.eventId
        \o message.declarationEventType
        \o message.firmId
        \o message.oeSessionId
        \o message.accountType
        \o message.clientOrderId
        \o message.emm
        \o message.declarationId
        \o message.declarationStatus
        \o message.priceOptional
        \o message.quantityOptional
        \o message.side
        \o message.symbolIndex
        \o message.operationType
        \o message.crossOrderIndicator
        \o message.enteringCounterparty
        \o message.traderId
        \o message.investorId
        \o message.freeText
        \o message.principalCode
        \o message.clearingFirmIdOptional
        \o message.clearingAccount
        \o message.settlementPeriod
        \o message.settlementFlag
        \o message.guaranteeFlag
        \o message.transactionPriceType

DecodeDcDeclarationNewMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET messageSendingTime == ReadBytes(consumeTime.rest, 8) IN IF ~messageSendingTime.ok THEN Fail ELSE
    LET bookIn == ReadBytes(messageSendingTime.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET oeginFromMember == ReadBytes(bookOutTime.rest, 8) IN IF ~oeginFromMember.ok THEN Fail ELSE
    LET oegoutTimeToMe == ReadBytes(oeginFromMember.rest, 8) IN IF ~oegoutTimeToMe.ok THEN Fail ELSE
    LET eventId == ReadBytes(oegoutTimeToMe.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET declarationEventType == ReadBytes(eventId.rest, 1) IN IF ~declarationEventType.ok THEN Fail ELSE
    LET firmId == ReadBytes(declarationEventType.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oeSessionId == ReadBytes(firmId.rest, 8) IN IF ~oeSessionId.ok THEN Fail ELSE
    LET accountType == ReadBytes(oeSessionId.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(accountType.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET emm == ReadBytes(clientOrderId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET declarationId == ReadBytes(emm.rest, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET declarationStatus == ReadBytes(declarationId.rest, 1) IN IF ~declarationStatus.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(declarationStatus.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET quantityOptional == ReadBytes(priceOptional.rest, 8) IN IF ~quantityOptional.ok THEN Fail ELSE
    LET side == ReadBytes(quantityOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(side.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET operationType == ReadBytes(symbolIndex.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET crossOrderIndicator == ReadBytes(operationType.rest, 1) IN IF ~crossOrderIndicator.ok THEN Fail ELSE
    LET enteringCounterparty == ReadBytes(crossOrderIndicator.rest, 8) IN IF ~enteringCounterparty.ok THEN Fail ELSE
    LET traderId == ReadBytes(enteringCounterparty.rest, 16) IN IF ~traderId.ok THEN Fail ELSE
    LET investorId == ReadBytes(traderId.rest, 16) IN IF ~investorId.ok THEN Fail ELSE
    LET freeText == ReadBytes(investorId.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET principalCode == ReadBytes(freeText.rest, 8) IN IF ~principalCode.ok THEN Fail ELSE
    LET clearingFirmIdOptional == ReadBytes(principalCode.rest, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirmIdOptional.rest, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(clearingAccount.rest, 1) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET settlementFlag == ReadBytes(settlementPeriod.rest, 1) IN IF ~settlementFlag.ok THEN Fail ELSE
    LET guaranteeFlag == ReadBytes(settlementFlag.rest, 1) IN IF ~guaranteeFlag.ok THEN Fail ELSE
    LET transactionPriceType == ReadBytes(guaranteeFlag.rest, 1) IN IF ~transactionPriceType.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         produceTime            |-> produceTime.value,
         consumeTime            |-> consumeTime.value,
         messageSendingTime     |-> messageSendingTime.value,
         bookIn                 |-> bookIn.value,
         bookOutTime            |-> bookOutTime.value,
         oeginFromMember        |-> oeginFromMember.value,
         oegoutTimeToMe         |-> oegoutTimeToMe.value,
         eventId                |-> eventId.value,
         declarationEventType   |-> declarationEventType.value,
         firmId                 |-> firmId.value,
         oeSessionId            |-> oeSessionId.value,
         accountType            |-> accountType.value,
         clientOrderId          |-> clientOrderId.value,
         emm                    |-> emm.value,
         declarationId          |-> declarationId.value,
         declarationStatus      |-> declarationStatus.value,
         priceOptional          |-> priceOptional.value,
         quantityOptional       |-> quantityOptional.value,
         side                   |-> side.value,
         symbolIndex            |-> symbolIndex.value,
         operationType          |-> operationType.value,
         crossOrderIndicator    |-> crossOrderIndicator.value,
         enteringCounterparty   |-> enteringCounterparty.value,
         traderId               |-> traderId.value,
         investorId             |-> investorId.value,
         freeText               |-> freeText.value,
         principalCode          |-> principalCode.value,
         clearingFirmIdOptional |-> clearingFirmIdOptional.value,
         clearingAccount        |-> clearingAccount.value,
         settlementPeriod       |-> settlementPeriod.value,
         settlementFlag         |-> settlementFlag.value,
         guaranteeFlag          |-> guaranteeFlag.value,
         transactionPriceType   |-> transactionPriceType.value ], transactionPriceType.rest)

ZeroDcDeclarationNewMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      produceTime            |-> [i \in 1 .. 8 |-> 0],
      consumeTime            |-> [i \in 1 .. 8 |-> 0],
      messageSendingTime     |-> [i \in 1 .. 8 |-> 0],
      bookIn                 |-> [i \in 1 .. 8 |-> 0],
      bookOutTime            |-> [i \in 1 .. 8 |-> 0],
      oeginFromMember        |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMe         |-> [i \in 1 .. 8 |-> 0],
      eventId                |-> [i \in 1 .. 8 |-> 0],
      declarationEventType   |-> [i \in 1 .. 1 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      oeSessionId            |-> [i \in 1 .. 8 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      clientOrderId          |-> [i \in 1 .. 8 |-> 0],
      emm                    |-> [i \in 1 .. 1 |-> 0],
      declarationId          |-> [i \in 1 .. 8 |-> 0],
      declarationStatus      |-> [i \in 1 .. 1 |-> 0],
      priceOptional          |-> [i \in 1 .. 8 |-> 0],
      quantityOptional       |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      operationType          |-> [i \in 1 .. 1 |-> 0],
      crossOrderIndicator    |-> [i \in 1 .. 1 |-> 0],
      enteringCounterparty   |-> [i \in 1 .. 8 |-> 0],
      traderId               |-> [i \in 1 .. 16 |-> 0],
      investorId             |-> [i \in 1 .. 16 |-> 0],
      freeText               |-> [i \in 1 .. 18 |-> 0],
      principalCode          |-> [i \in 1 .. 8 |-> 0],
      clearingFirmIdOptional |-> [i \in 1 .. 8 |-> 0],
      clearingAccount        |-> [i \in 1 .. 16 |-> 0],
      settlementPeriod       |-> [i \in 1 .. 1 |-> 0],
      settlementFlag         |-> [i \in 1 .. 1 |-> 0],
      guaranteeFlag          |-> [i \in 1 .. 1 |-> 0],
      transactionPriceType   |-> [i \in 1 .. 1 |-> 0] ]

(* Dc Declaration New Message at zero, then each field in turn at the values it is checked at *)
CheckedDcDeclarationNewMessage ==
    { ZeroDcDeclarationNewMessage }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.messageSendingTime = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.oeginFromMember = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.oegoutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.declarationEventType = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.oeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.declarationStatus = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.quantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.crossOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.enteringCounterparty = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.traderId = one] : one \in Sample(16) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.investorId = one] : one \in Sample(16) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.principalCode = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.clearingAccount = one] : one \in Sample(16) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.settlementPeriod = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.settlementFlag = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.guaranteeFlag = one] : one \in Sample(1) }
        \cup { [ZeroDcDeclarationNewMessage EXCEPT !.transactionPriceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Dc Short Declaration Reject Message: 102 bytes                          *)
(***************************************************************************)

DcShortDeclarationRejectMessage ==
    [ msgSeqNum            : Sample(4),
      produceTime          : Sample(8),
      consumeTime          : Sample(8),
      messageSendingTime   : Sample(8),
      bookIn               : Sample(8),
      bookOutTime          : Sample(8),
      oeginFromMember      : Sample(8),
      oegoutTimeToMe       : Sample(8),
      eventId              : Sample(8),
      declarationEventType : Sample(1),
      firmId               : Sample(8),
      clientOrderId        : Sample(8),
      emm                  : Sample(1),
      declarationId        : Sample(8),
      symbolIndex          : Sample(4),
      errorCode            : Sample(2),
      rejectedMessageId    : Sample(2) ]

EncodeDcShortDeclarationRejectMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.messageSendingTime
        \o message.bookIn
        \o message.bookOutTime
        \o message.oeginFromMember
        \o message.oegoutTimeToMe
        \o message.eventId
        \o message.declarationEventType
        \o message.firmId
        \o message.clientOrderId
        \o message.emm
        \o message.declarationId
        \o message.symbolIndex
        \o message.errorCode
        \o message.rejectedMessageId

DecodeDcShortDeclarationRejectMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET messageSendingTime == ReadBytes(consumeTime.rest, 8) IN IF ~messageSendingTime.ok THEN Fail ELSE
    LET bookIn == ReadBytes(messageSendingTime.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET oeginFromMember == ReadBytes(bookOutTime.rest, 8) IN IF ~oeginFromMember.ok THEN Fail ELSE
    LET oegoutTimeToMe == ReadBytes(oeginFromMember.rest, 8) IN IF ~oegoutTimeToMe.ok THEN Fail ELSE
    LET eventId == ReadBytes(oegoutTimeToMe.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET declarationEventType == ReadBytes(eventId.rest, 1) IN IF ~declarationEventType.ok THEN Fail ELSE
    LET firmId == ReadBytes(declarationEventType.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(firmId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET emm == ReadBytes(clientOrderId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET declarationId == ReadBytes(emm.rest, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(declarationId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET errorCode == ReadBytes(symbolIndex.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET rejectedMessageId == ReadBytes(errorCode.rest, 2) IN IF ~rejectedMessageId.ok THEN Fail ELSE
    Ok([ msgSeqNum            |-> msgSeqNum.value,
         produceTime          |-> produceTime.value,
         consumeTime          |-> consumeTime.value,
         messageSendingTime   |-> messageSendingTime.value,
         bookIn               |-> bookIn.value,
         bookOutTime          |-> bookOutTime.value,
         oeginFromMember      |-> oeginFromMember.value,
         oegoutTimeToMe       |-> oegoutTimeToMe.value,
         eventId              |-> eventId.value,
         declarationEventType |-> declarationEventType.value,
         firmId               |-> firmId.value,
         clientOrderId        |-> clientOrderId.value,
         emm                  |-> emm.value,
         declarationId        |-> declarationId.value,
         symbolIndex          |-> symbolIndex.value,
         errorCode            |-> errorCode.value,
         rejectedMessageId    |-> rejectedMessageId.value ], rejectedMessageId.rest)

ZeroDcShortDeclarationRejectMessage ==
    [ msgSeqNum            |-> [i \in 1 .. 4 |-> 0],
      produceTime          |-> [i \in 1 .. 8 |-> 0],
      consumeTime          |-> [i \in 1 .. 8 |-> 0],
      messageSendingTime   |-> [i \in 1 .. 8 |-> 0],
      bookIn               |-> [i \in 1 .. 8 |-> 0],
      bookOutTime          |-> [i \in 1 .. 8 |-> 0],
      oeginFromMember      |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMe       |-> [i \in 1 .. 8 |-> 0],
      eventId              |-> [i \in 1 .. 8 |-> 0],
      declarationEventType |-> [i \in 1 .. 1 |-> 0],
      firmId               |-> [i \in 1 .. 8 |-> 0],
      clientOrderId        |-> [i \in 1 .. 8 |-> 0],
      emm                  |-> [i \in 1 .. 1 |-> 0],
      declarationId        |-> [i \in 1 .. 8 |-> 0],
      symbolIndex          |-> [i \in 1 .. 4 |-> 0],
      errorCode            |-> [i \in 1 .. 2 |-> 0],
      rejectedMessageId    |-> [i \in 1 .. 2 |-> 0] ]

(* Dc Short Declaration Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedDcShortDeclarationRejectMessage ==
    { ZeroDcShortDeclarationRejectMessage }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.messageSendingTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.oeginFromMember = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.oegoutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.declarationEventType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroDcShortDeclarationRejectMessage EXCEPT !.rejectedMessageId = one] : one \in Sample(2) }

(***************************************************************************)
(* Dc Short Declaration Cancel Message: 107 bytes                          *)
(***************************************************************************)

DcShortDeclarationCancelMessage ==
    [ msgSeqNum             : Sample(4),
      produceTime           : Sample(8),
      consumeTime           : Sample(8),
      messageSendingTime    : Sample(8),
      bookIn                : Sample(8),
      bookOutTime           : Sample(8),
      oeginFromMember       : Sample(8),
      oegoutTimeToMe        : Sample(8),
      eventId               : Sample(8),
      declarationEventType  : Sample(1),
      firmId                : Sample(8),
      oeSessionId           : Sample(8),
      clientOrderId         : Sample(8),
      emm                   : Sample(1),
      declarationId         : Sample(8),
      symbolIndex           : Sample(4),
      declarationKillReason : Sample(1) ]

EncodeDcShortDeclarationCancelMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.messageSendingTime
        \o message.bookIn
        \o message.bookOutTime
        \o message.oeginFromMember
        \o message.oegoutTimeToMe
        \o message.eventId
        \o message.declarationEventType
        \o message.firmId
        \o message.oeSessionId
        \o message.clientOrderId
        \o message.emm
        \o message.declarationId
        \o message.symbolIndex
        \o message.declarationKillReason

DecodeDcShortDeclarationCancelMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET messageSendingTime == ReadBytes(consumeTime.rest, 8) IN IF ~messageSendingTime.ok THEN Fail ELSE
    LET bookIn == ReadBytes(messageSendingTime.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET oeginFromMember == ReadBytes(bookOutTime.rest, 8) IN IF ~oeginFromMember.ok THEN Fail ELSE
    LET oegoutTimeToMe == ReadBytes(oeginFromMember.rest, 8) IN IF ~oegoutTimeToMe.ok THEN Fail ELSE
    LET eventId == ReadBytes(oegoutTimeToMe.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET declarationEventType == ReadBytes(eventId.rest, 1) IN IF ~declarationEventType.ok THEN Fail ELSE
    LET firmId == ReadBytes(declarationEventType.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oeSessionId == ReadBytes(firmId.rest, 8) IN IF ~oeSessionId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(oeSessionId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET emm == ReadBytes(clientOrderId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET declarationId == ReadBytes(emm.rest, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(declarationId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET declarationKillReason == ReadBytes(symbolIndex.rest, 1) IN IF ~declarationKillReason.ok THEN Fail ELSE
    Ok([ msgSeqNum             |-> msgSeqNum.value,
         produceTime           |-> produceTime.value,
         consumeTime           |-> consumeTime.value,
         messageSendingTime    |-> messageSendingTime.value,
         bookIn                |-> bookIn.value,
         bookOutTime           |-> bookOutTime.value,
         oeginFromMember       |-> oeginFromMember.value,
         oegoutTimeToMe        |-> oegoutTimeToMe.value,
         eventId               |-> eventId.value,
         declarationEventType  |-> declarationEventType.value,
         firmId                |-> firmId.value,
         oeSessionId           |-> oeSessionId.value,
         clientOrderId         |-> clientOrderId.value,
         emm                   |-> emm.value,
         declarationId         |-> declarationId.value,
         symbolIndex           |-> symbolIndex.value,
         declarationKillReason |-> declarationKillReason.value ], declarationKillReason.rest)

ZeroDcShortDeclarationCancelMessage ==
    [ msgSeqNum             |-> [i \in 1 .. 4 |-> 0],
      produceTime           |-> [i \in 1 .. 8 |-> 0],
      consumeTime           |-> [i \in 1 .. 8 |-> 0],
      messageSendingTime    |-> [i \in 1 .. 8 |-> 0],
      bookIn                |-> [i \in 1 .. 8 |-> 0],
      bookOutTime           |-> [i \in 1 .. 8 |-> 0],
      oeginFromMember       |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMe        |-> [i \in 1 .. 8 |-> 0],
      eventId               |-> [i \in 1 .. 8 |-> 0],
      declarationEventType  |-> [i \in 1 .. 1 |-> 0],
      firmId                |-> [i \in 1 .. 8 |-> 0],
      oeSessionId           |-> [i \in 1 .. 8 |-> 0],
      clientOrderId         |-> [i \in 1 .. 8 |-> 0],
      emm                   |-> [i \in 1 .. 1 |-> 0],
      declarationId         |-> [i \in 1 .. 8 |-> 0],
      symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      declarationKillReason |-> [i \in 1 .. 1 |-> 0] ]

(* Dc Short Declaration Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedDcShortDeclarationCancelMessage ==
    { ZeroDcShortDeclarationCancelMessage }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.messageSendingTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.oeginFromMember = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.oegoutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.declarationEventType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.oeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcShortDeclarationCancelMessage EXCEPT !.declarationKillReason = one] : one \in Sample(1) }

(***************************************************************************)
(* D C Short Trade Declaration Message Short Trade Declarations Group: 139 *)
(* bytes                                                                   *)
(***************************************************************************)

DCShortTradeDeclarationMessageShortTradeDeclarationsGroup ==
    [ declarationId          : Sample(8),
      priceOptional          : Sample(8),
      quantityOptional       : Sample(8),
      operationType          : Sample(1),
      side                   : Sample(1),
      firmId                 : Sample(8),
      oePartitionId          : Sample(2),
      logicalAccessId        : Sample(4),
      bookIn                 : Sample(8),
      traderId               : Sample(16),
      investorId             : Sample(16),
      principalCode          : Sample(8),
      clearingFirmIdOptional : Sample(8),
      clearingAccount        : Sample(16),
      accountType            : Sample(1),
      clientOrderId          : Sample(8),
      freeText               : Sample(18) ]

EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroup(message) ==
    message.declarationId
        \o message.priceOptional
        \o message.quantityOptional
        \o message.operationType
        \o message.side
        \o message.firmId
        \o message.oePartitionId
        \o message.logicalAccessId
        \o message.bookIn
        \o message.traderId
        \o message.investorId
        \o message.principalCode
        \o message.clearingFirmIdOptional
        \o message.clearingAccount
        \o message.accountType
        \o message.clientOrderId
        \o message.freeText

DecodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroup(bytes) ==
    LET declarationId == ReadBytes(bytes, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(declarationId.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET quantityOptional == ReadBytes(priceOptional.rest, 8) IN IF ~quantityOptional.ok THEN Fail ELSE
    LET operationType == ReadBytes(quantityOptional.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET side == ReadBytes(operationType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET firmId == ReadBytes(side.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oePartitionId == ReadBytes(firmId.rest, 2) IN IF ~oePartitionId.ok THEN Fail ELSE
    LET logicalAccessId == ReadBytes(oePartitionId.rest, 4) IN IF ~logicalAccessId.ok THEN Fail ELSE
    LET bookIn == ReadBytes(logicalAccessId.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET traderId == ReadBytes(bookIn.rest, 16) IN IF ~traderId.ok THEN Fail ELSE
    LET investorId == ReadBytes(traderId.rest, 16) IN IF ~investorId.ok THEN Fail ELSE
    LET principalCode == ReadBytes(investorId.rest, 8) IN IF ~principalCode.ok THEN Fail ELSE
    LET clearingFirmIdOptional == ReadBytes(principalCode.rest, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirmIdOptional.rest, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingAccount.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(accountType.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET freeText == ReadBytes(clientOrderId.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    Ok([ declarationId          |-> declarationId.value,
         priceOptional          |-> priceOptional.value,
         quantityOptional       |-> quantityOptional.value,
         operationType          |-> operationType.value,
         side                   |-> side.value,
         firmId                 |-> firmId.value,
         oePartitionId          |-> oePartitionId.value,
         logicalAccessId        |-> logicalAccessId.value,
         bookIn                 |-> bookIn.value,
         traderId               |-> traderId.value,
         investorId             |-> investorId.value,
         principalCode          |-> principalCode.value,
         clearingFirmIdOptional |-> clearingFirmIdOptional.value,
         clearingAccount        |-> clearingAccount.value,
         accountType            |-> accountType.value,
         clientOrderId          |-> clientOrderId.value,
         freeText               |-> freeText.value ], freeText.rest)

ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup ==
    [ declarationId          |-> [i \in 1 .. 8 |-> 0],
      priceOptional          |-> [i \in 1 .. 8 |-> 0],
      quantityOptional       |-> [i \in 1 .. 8 |-> 0],
      operationType          |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      oePartitionId          |-> [i \in 1 .. 2 |-> 0],
      logicalAccessId        |-> [i \in 1 .. 4 |-> 0],
      bookIn                 |-> [i \in 1 .. 8 |-> 0],
      traderId               |-> [i \in 1 .. 16 |-> 0],
      investorId             |-> [i \in 1 .. 16 |-> 0],
      principalCode          |-> [i \in 1 .. 8 |-> 0],
      clearingFirmIdOptional |-> [i \in 1 .. 8 |-> 0],
      clearingAccount        |-> [i \in 1 .. 16 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      clientOrderId          |-> [i \in 1 .. 8 |-> 0],
      freeText               |-> [i \in 1 .. 18 |-> 0] ]

(* D C Short Trade Declaration Message Short Trade Declarations Group at zero, then each field in turn at the values it is checked at *)
CheckedDCShortTradeDeclarationMessageShortTradeDeclarationsGroup ==
    { ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.quantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.oePartitionId = one] : one \in Sample(2) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.logicalAccessId = one] : one \in Sample(4) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.traderId = one] : one \in Sample(16) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.investorId = one] : one \in Sample(16) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.principalCode = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.clearingAccount = one] : one \in Sample(16) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup EXCEPT !.freeText = one] : one \in Sample(18) }

(* A run of D C Short Trade Declaration Message Short Trade Declarations Group, written one after another *)
RECURSIVE EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(_)
EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroup(Head(messages)) \o EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(Tail(messages))

(* As many D C Short Trade Declaration Message Short Trade Declarations Group as the field that counts them says *)
RECURSIVE ReadDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(_, _)
ReadDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Short Trade Declaration Message Short Trade Declarations Group of each kind, for the lists that carry them *)
OneDCShortTradeDeclarationMessageShortTradeDeclarationsGroup == { ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroup }

(***************************************************************************)
(* D C Short Trade Declaration Message Short Trade Declarations Groups     *)
(***************************************************************************)

DCShortTradeDeclarationMessageShortTradeDeclarationsGroups ==
    [ blockLengthShort                                          : Sample(1),
      dCShortTradeDeclarationMessageShortTradeDeclarationsGroup : SampleLists(OneDCShortTradeDeclarationMessageShortTradeDeclarationsGroup) ]

EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCShortTradeDeclarationMessageShortTradeDeclarationsGroup), 1)
        \o EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(message.dCShortTradeDeclarationMessageShortTradeDeclarationsGroup)

DecodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCShortTradeDeclarationMessageShortTradeDeclarationsGroup == ReadDCShortTradeDeclarationMessageShortTradeDeclarationsGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCShortTradeDeclarationMessageShortTradeDeclarationsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                          |-> blockLengthShort.value,
         dCShortTradeDeclarationMessageShortTradeDeclarationsGroup |-> dCShortTradeDeclarationMessageShortTradeDeclarationsGroup.value ], dCShortTradeDeclarationMessageShortTradeDeclarationsGroup.rest)

ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroups ==
    [ blockLengthShort                                          |-> [i \in 1 .. 1 |-> 0],
      dCShortTradeDeclarationMessageShortTradeDeclarationsGroup |-> << >> ]

(* D C Short Trade Declaration Message Short Trade Declarations Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCShortTradeDeclarationMessageShortTradeDeclarationsGroups ==
    { ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroups }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroups EXCEPT !.dCShortTradeDeclarationMessageShortTradeDeclarationsGroup = one] : one \in SampleLists(OneDCShortTradeDeclarationMessageShortTradeDeclarationsGroup) }

(***************************************************************************)
(* Dc Short Trade Declaration Message                                      *)
(***************************************************************************)

DcShortTradeDeclarationMessage ==
    [ msgSeqNum                                                  : Sample(4),
      produceTime                                                : Sample(8),
      consumeTime                                                : Sample(8),
      eventId                                                    : Sample(8),
      emm                                                        : Sample(1),
      symbolIndex                                                : Sample(4),
      executionId                                                : Sample(4),
      crossOrderIndicator                                        : Sample(1),
      tradeTime                                                  : Sample(8),
      publicationTime                                            : Sample(8),
      sessionOptional                                            : Sample(1),
      tradeType                                                  : Sample(1),
      settlementPeriodOptional                                   : Sample(1),
      settlementFlagOptional                                     : Sample(1),
      guaranteeFlagOptional                                      : Sample(1),
      dCShortTradeDeclarationMessageShortTradeDeclarationsGroups : DCShortTradeDeclarationMessageShortTradeDeclarationsGroups ]

EncodeDcShortTradeDeclarationMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.eventId
        \o message.emm
        \o message.symbolIndex
        \o message.executionId
        \o message.crossOrderIndicator
        \o message.tradeTime
        \o message.publicationTime
        \o message.sessionOptional
        \o message.tradeType
        \o message.settlementPeriodOptional
        \o message.settlementFlagOptional
        \o message.guaranteeFlagOptional
        \o EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroups(message.dCShortTradeDeclarationMessageShortTradeDeclarationsGroups)

DecodeDcShortTradeDeclarationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET eventId == ReadBytes(consumeTime.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET emm == ReadBytes(eventId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(emm.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET executionId == ReadBytes(symbolIndex.rest, 4) IN IF ~executionId.ok THEN Fail ELSE
    LET crossOrderIndicator == ReadBytes(executionId.rest, 1) IN IF ~crossOrderIndicator.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(crossOrderIndicator.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET publicationTime == ReadBytes(tradeTime.rest, 8) IN IF ~publicationTime.ok THEN Fail ELSE
    LET sessionOptional == ReadBytes(publicationTime.rest, 1) IN IF ~sessionOptional.ok THEN Fail ELSE
    LET tradeType == ReadBytes(sessionOptional.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET settlementPeriodOptional == ReadBytes(tradeType.rest, 1) IN IF ~settlementPeriodOptional.ok THEN Fail ELSE
    LET settlementFlagOptional == ReadBytes(settlementPeriodOptional.rest, 1) IN IF ~settlementFlagOptional.ok THEN Fail ELSE
    LET guaranteeFlagOptional == ReadBytes(settlementFlagOptional.rest, 1) IN IF ~guaranteeFlagOptional.ok THEN Fail ELSE
    LET dCShortTradeDeclarationMessageShortTradeDeclarationsGroups == DecodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroups(guaranteeFlagOptional.rest) IN IF ~dCShortTradeDeclarationMessageShortTradeDeclarationsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                                                  |-> msgSeqNum.value,
         produceTime                                                |-> produceTime.value,
         consumeTime                                                |-> consumeTime.value,
         eventId                                                    |-> eventId.value,
         emm                                                        |-> emm.value,
         symbolIndex                                                |-> symbolIndex.value,
         executionId                                                |-> executionId.value,
         crossOrderIndicator                                        |-> crossOrderIndicator.value,
         tradeTime                                                  |-> tradeTime.value,
         publicationTime                                            |-> publicationTime.value,
         sessionOptional                                            |-> sessionOptional.value,
         tradeType                                                  |-> tradeType.value,
         settlementPeriodOptional                                   |-> settlementPeriodOptional.value,
         settlementFlagOptional                                     |-> settlementFlagOptional.value,
         guaranteeFlagOptional                                      |-> guaranteeFlagOptional.value,
         dCShortTradeDeclarationMessageShortTradeDeclarationsGroups |-> dCShortTradeDeclarationMessageShortTradeDeclarationsGroups.value ], dCShortTradeDeclarationMessageShortTradeDeclarationsGroups.rest)

ZeroDcShortTradeDeclarationMessage ==
    [ msgSeqNum                                                  |-> [i \in 1 .. 4 |-> 0],
      produceTime                                                |-> [i \in 1 .. 8 |-> 0],
      consumeTime                                                |-> [i \in 1 .. 8 |-> 0],
      eventId                                                    |-> [i \in 1 .. 8 |-> 0],
      emm                                                        |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                                                |-> [i \in 1 .. 4 |-> 0],
      executionId                                                |-> [i \in 1 .. 4 |-> 0],
      crossOrderIndicator                                        |-> [i \in 1 .. 1 |-> 0],
      tradeTime                                                  |-> [i \in 1 .. 8 |-> 0],
      publicationTime                                            |-> [i \in 1 .. 8 |-> 0],
      sessionOptional                                            |-> [i \in 1 .. 1 |-> 0],
      tradeType                                                  |-> [i \in 1 .. 1 |-> 0],
      settlementPeriodOptional                                   |-> [i \in 1 .. 1 |-> 0],
      settlementFlagOptional                                     |-> [i \in 1 .. 1 |-> 0],
      guaranteeFlagOptional                                      |-> [i \in 1 .. 1 |-> 0],
      dCShortTradeDeclarationMessageShortTradeDeclarationsGroups |-> ZeroDCShortTradeDeclarationMessageShortTradeDeclarationsGroups ]

(* Dc Short Trade Declaration Message at zero, then each field in turn at the values it is checked at *)
CheckedDcShortTradeDeclarationMessage ==
    { ZeroDcShortTradeDeclarationMessage }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.executionId = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.crossOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.publicationTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.sessionOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.settlementPeriodOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.settlementFlagOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.guaranteeFlagOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationMessage EXCEPT !.dCShortTradeDeclarationMessageShortTradeDeclarationsGroups = one] : one \in CheckedDCShortTradeDeclarationMessageShortTradeDeclarationsGroups }

(***************************************************************************)
(* Dc Short Trade Declaration Cancellation Message: 61 bytes               *)
(***************************************************************************)

DcShortTradeDeclarationCancellationMessage ==
    [ msgSeqNum   : Sample(4),
      produceTime : Sample(8),
      consumeTime : Sample(8),
      bookIn      : Sample(8),
      eventId     : Sample(8),
      emm         : Sample(1),
      executionId : Sample(4),
      symbolIndex : Sample(4),
      price       : Sample(8),
      quantity    : Sample(8) ]

EncodeDcShortTradeDeclarationCancellationMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.bookIn
        \o message.eventId
        \o message.emm
        \o message.executionId
        \o message.symbolIndex
        \o message.price
        \o message.quantity

DecodeDcShortTradeDeclarationCancellationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET bookIn == ReadBytes(consumeTime.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET eventId == ReadBytes(bookIn.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET emm == ReadBytes(eventId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET executionId == ReadBytes(emm.rest, 4) IN IF ~executionId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(executionId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET price == ReadBytes(symbolIndex.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         produceTime |-> produceTime.value,
         consumeTime |-> consumeTime.value,
         bookIn      |-> bookIn.value,
         eventId     |-> eventId.value,
         emm         |-> emm.value,
         executionId |-> executionId.value,
         symbolIndex |-> symbolIndex.value,
         price       |-> price.value,
         quantity    |-> quantity.value ], quantity.rest)

ZeroDcShortTradeDeclarationCancellationMessage ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      produceTime |-> [i \in 1 .. 8 |-> 0],
      consumeTime |-> [i \in 1 .. 8 |-> 0],
      bookIn      |-> [i \in 1 .. 8 |-> 0],
      eventId     |-> [i \in 1 .. 8 |-> 0],
      emm         |-> [i \in 1 .. 1 |-> 0],
      executionId |-> [i \in 1 .. 4 |-> 0],
      symbolIndex |-> [i \in 1 .. 4 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      quantity    |-> [i \in 1 .. 8 |-> 0] ]

(* Dc Short Trade Declaration Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedDcShortTradeDeclarationCancellationMessage ==
    { ZeroDcShortTradeDeclarationCancellationMessage }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.executionId = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDcShortTradeDeclarationCancellationMessage EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Dc Trade Bust Declaration Message: 208 bytes                            *)
(***************************************************************************)

DcTradeBustDeclarationMessage ==
    [ msgSeqNum              : Sample(4),
      produceTime            : Sample(8),
      consumeTime            : Sample(8),
      messageSendingTime     : Sample(8),
      bookIn                 : Sample(8),
      bookOutTime            : Sample(8),
      oeginFromMember        : Sample(8),
      oegoutTimeToMe         : Sample(8),
      eventId                : Sample(8),
      declarationEventType   : Sample(1),
      firmId                 : Sample(8),
      oeSessionId            : Sample(8),
      accountType            : Sample(1),
      clientOrderId          : Sample(8),
      emm                    : Sample(1),
      declarationId          : Sample(8),
      declarationStatus      : Sample(1),
      priceOptional          : Sample(8),
      quantityOptional       : Sample(8),
      side                   : Sample(1),
      symbolIndex            : Sample(4),
      operationType          : Sample(1),
      enteringCounterparty   : Sample(8),
      traderId               : Sample(16),
      investorId             : Sample(16),
      freeText               : Sample(18),
      clearingFirmIdOptional : Sample(8),
      clearingAccount        : Sample(16) ]

EncodeDcTradeBustDeclarationMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.messageSendingTime
        \o message.bookIn
        \o message.bookOutTime
        \o message.oeginFromMember
        \o message.oegoutTimeToMe
        \o message.eventId
        \o message.declarationEventType
        \o message.firmId
        \o message.oeSessionId
        \o message.accountType
        \o message.clientOrderId
        \o message.emm
        \o message.declarationId
        \o message.declarationStatus
        \o message.priceOptional
        \o message.quantityOptional
        \o message.side
        \o message.symbolIndex
        \o message.operationType
        \o message.enteringCounterparty
        \o message.traderId
        \o message.investorId
        \o message.freeText
        \o message.clearingFirmIdOptional
        \o message.clearingAccount

DecodeDcTradeBustDeclarationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET messageSendingTime == ReadBytes(consumeTime.rest, 8) IN IF ~messageSendingTime.ok THEN Fail ELSE
    LET bookIn == ReadBytes(messageSendingTime.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET oeginFromMember == ReadBytes(bookOutTime.rest, 8) IN IF ~oeginFromMember.ok THEN Fail ELSE
    LET oegoutTimeToMe == ReadBytes(oeginFromMember.rest, 8) IN IF ~oegoutTimeToMe.ok THEN Fail ELSE
    LET eventId == ReadBytes(oegoutTimeToMe.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET declarationEventType == ReadBytes(eventId.rest, 1) IN IF ~declarationEventType.ok THEN Fail ELSE
    LET firmId == ReadBytes(declarationEventType.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oeSessionId == ReadBytes(firmId.rest, 8) IN IF ~oeSessionId.ok THEN Fail ELSE
    LET accountType == ReadBytes(oeSessionId.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(accountType.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET emm == ReadBytes(clientOrderId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET declarationId == ReadBytes(emm.rest, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET declarationStatus == ReadBytes(declarationId.rest, 1) IN IF ~declarationStatus.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(declarationStatus.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET quantityOptional == ReadBytes(priceOptional.rest, 8) IN IF ~quantityOptional.ok THEN Fail ELSE
    LET side == ReadBytes(quantityOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(side.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET operationType == ReadBytes(symbolIndex.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET enteringCounterparty == ReadBytes(operationType.rest, 8) IN IF ~enteringCounterparty.ok THEN Fail ELSE
    LET traderId == ReadBytes(enteringCounterparty.rest, 16) IN IF ~traderId.ok THEN Fail ELSE
    LET investorId == ReadBytes(traderId.rest, 16) IN IF ~investorId.ok THEN Fail ELSE
    LET freeText == ReadBytes(investorId.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET clearingFirmIdOptional == ReadBytes(freeText.rest, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirmIdOptional.rest, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         produceTime            |-> produceTime.value,
         consumeTime            |-> consumeTime.value,
         messageSendingTime     |-> messageSendingTime.value,
         bookIn                 |-> bookIn.value,
         bookOutTime            |-> bookOutTime.value,
         oeginFromMember        |-> oeginFromMember.value,
         oegoutTimeToMe         |-> oegoutTimeToMe.value,
         eventId                |-> eventId.value,
         declarationEventType   |-> declarationEventType.value,
         firmId                 |-> firmId.value,
         oeSessionId            |-> oeSessionId.value,
         accountType            |-> accountType.value,
         clientOrderId          |-> clientOrderId.value,
         emm                    |-> emm.value,
         declarationId          |-> declarationId.value,
         declarationStatus      |-> declarationStatus.value,
         priceOptional          |-> priceOptional.value,
         quantityOptional       |-> quantityOptional.value,
         side                   |-> side.value,
         symbolIndex            |-> symbolIndex.value,
         operationType          |-> operationType.value,
         enteringCounterparty   |-> enteringCounterparty.value,
         traderId               |-> traderId.value,
         investorId             |-> investorId.value,
         freeText               |-> freeText.value,
         clearingFirmIdOptional |-> clearingFirmIdOptional.value,
         clearingAccount        |-> clearingAccount.value ], clearingAccount.rest)

ZeroDcTradeBustDeclarationMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      produceTime            |-> [i \in 1 .. 8 |-> 0],
      consumeTime            |-> [i \in 1 .. 8 |-> 0],
      messageSendingTime     |-> [i \in 1 .. 8 |-> 0],
      bookIn                 |-> [i \in 1 .. 8 |-> 0],
      bookOutTime            |-> [i \in 1 .. 8 |-> 0],
      oeginFromMember        |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMe         |-> [i \in 1 .. 8 |-> 0],
      eventId                |-> [i \in 1 .. 8 |-> 0],
      declarationEventType   |-> [i \in 1 .. 1 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      oeSessionId            |-> [i \in 1 .. 8 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      clientOrderId          |-> [i \in 1 .. 8 |-> 0],
      emm                    |-> [i \in 1 .. 1 |-> 0],
      declarationId          |-> [i \in 1 .. 8 |-> 0],
      declarationStatus      |-> [i \in 1 .. 1 |-> 0],
      priceOptional          |-> [i \in 1 .. 8 |-> 0],
      quantityOptional       |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      operationType          |-> [i \in 1 .. 1 |-> 0],
      enteringCounterparty   |-> [i \in 1 .. 8 |-> 0],
      traderId               |-> [i \in 1 .. 16 |-> 0],
      investorId             |-> [i \in 1 .. 16 |-> 0],
      freeText               |-> [i \in 1 .. 18 |-> 0],
      clearingFirmIdOptional |-> [i \in 1 .. 8 |-> 0],
      clearingAccount        |-> [i \in 1 .. 16 |-> 0] ]

(* Dc Trade Bust Declaration Message at zero, then each field in turn at the values it is checked at *)
CheckedDcTradeBustDeclarationMessage ==
    { ZeroDcTradeBustDeclarationMessage }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.messageSendingTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.oeginFromMember = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.oegoutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.declarationEventType = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.oeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.declarationStatus = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.quantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.enteringCounterparty = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.traderId = one] : one \in Sample(16) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.investorId = one] : one \in Sample(16) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeBustDeclarationMessage EXCEPT !.clearingAccount = one] : one \in Sample(16) }

(***************************************************************************)
(* D C Trade Message Matched Orders Group: 140 bytes                       *)
(***************************************************************************)

DCTradeMessageMatchedOrdersGroup ==
    [ orderId                     : Sample(8),
      orderSide                   : Sample(1),
      orderType                   : Sample(1),
      timeInForce                 : Sample(1),
      orderPx                     : Sample(8),
      clientId                    : Sample(8),
      technicalOrigin             : Sample(1),
      openClose                   : Sample(2),
      clientOrderId               : Sample(8),
      firmId                      : Sample(8),
      oePartitionIdOptional       : Sample(2),
      logicalAccessIdOptional     : Sample(4),
      bookInOptional              : Sample(8),
      tradeQualifierOptional      : Sample(1),
      accountTypeInternalOptional : Sample(1),
      lpRoleOptional              : Sample(1),
      clearingAccount             : Sample(16),
      freeText                    : Sample(18),
      clearingFirmIdOptional      : Sample(8),
      traderId                    : Sample(16),
      originalInvestorId          : Sample(16),
      crossOrderIndicatorOptional : Sample(1),
      clearingInstruction         : Sample(2) ]

EncodeDCTradeMessageMatchedOrdersGroup(message) ==
    message.orderId
        \o message.orderSide
        \o message.orderType
        \o message.timeInForce
        \o message.orderPx
        \o message.clientId
        \o message.technicalOrigin
        \o message.openClose
        \o message.clientOrderId
        \o message.firmId
        \o message.oePartitionIdOptional
        \o message.logicalAccessIdOptional
        \o message.bookInOptional
        \o message.tradeQualifierOptional
        \o message.accountTypeInternalOptional
        \o message.lpRoleOptional
        \o message.clearingAccount
        \o message.freeText
        \o message.clearingFirmIdOptional
        \o message.traderId
        \o message.originalInvestorId
        \o message.crossOrderIndicatorOptional
        \o message.clearingInstruction

DecodeDCTradeMessageMatchedOrdersGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderSide.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderPx == ReadBytes(timeInForce.rest, 8) IN IF ~orderPx.ok THEN Fail ELSE
    LET clientId == ReadBytes(orderPx.rest, 8) IN IF ~clientId.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(clientId.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(openClose.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET firmId == ReadBytes(clientOrderId.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oePartitionIdOptional == ReadBytes(firmId.rest, 2) IN IF ~oePartitionIdOptional.ok THEN Fail ELSE
    LET logicalAccessIdOptional == ReadBytes(oePartitionIdOptional.rest, 4) IN IF ~logicalAccessIdOptional.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(logicalAccessIdOptional.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET tradeQualifierOptional == ReadBytes(bookInOptional.rest, 1) IN IF ~tradeQualifierOptional.ok THEN Fail ELSE
    LET accountTypeInternalOptional == ReadBytes(tradeQualifierOptional.rest, 1) IN IF ~accountTypeInternalOptional.ok THEN Fail ELSE
    LET lpRoleOptional == ReadBytes(accountTypeInternalOptional.rest, 1) IN IF ~lpRoleOptional.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(lpRoleOptional.rest, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET freeText == ReadBytes(clearingAccount.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET clearingFirmIdOptional == ReadBytes(freeText.rest, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(clearingFirmIdOptional.rest, 16) IN IF ~traderId.ok THEN Fail ELSE
    LET originalInvestorId == ReadBytes(traderId.rest, 16) IN IF ~originalInvestorId.ok THEN Fail ELSE
    LET crossOrderIndicatorOptional == ReadBytes(originalInvestorId.rest, 1) IN IF ~crossOrderIndicatorOptional.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(crossOrderIndicatorOptional.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    Ok([ orderId                     |-> orderId.value,
         orderSide                   |-> orderSide.value,
         orderType                   |-> orderType.value,
         timeInForce                 |-> timeInForce.value,
         orderPx                     |-> orderPx.value,
         clientId                    |-> clientId.value,
         technicalOrigin             |-> technicalOrigin.value,
         openClose                   |-> openClose.value,
         clientOrderId               |-> clientOrderId.value,
         firmId                      |-> firmId.value,
         oePartitionIdOptional       |-> oePartitionIdOptional.value,
         logicalAccessIdOptional     |-> logicalAccessIdOptional.value,
         bookInOptional              |-> bookInOptional.value,
         tradeQualifierOptional      |-> tradeQualifierOptional.value,
         accountTypeInternalOptional |-> accountTypeInternalOptional.value,
         lpRoleOptional              |-> lpRoleOptional.value,
         clearingAccount             |-> clearingAccount.value,
         freeText                    |-> freeText.value,
         clearingFirmIdOptional      |-> clearingFirmIdOptional.value,
         traderId                    |-> traderId.value,
         originalInvestorId          |-> originalInvestorId.value,
         crossOrderIndicatorOptional |-> crossOrderIndicatorOptional.value,
         clearingInstruction         |-> clearingInstruction.value ], clearingInstruction.rest)

ZeroDCTradeMessageMatchedOrdersGroup ==
    [ orderId                     |-> [i \in 1 .. 8 |-> 0],
      orderSide                   |-> [i \in 1 .. 1 |-> 0],
      orderType                   |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      orderPx                     |-> [i \in 1 .. 8 |-> 0],
      clientId                    |-> [i \in 1 .. 8 |-> 0],
      technicalOrigin             |-> [i \in 1 .. 1 |-> 0],
      openClose                   |-> [i \in 1 .. 2 |-> 0],
      clientOrderId               |-> [i \in 1 .. 8 |-> 0],
      firmId                      |-> [i \in 1 .. 8 |-> 0],
      oePartitionIdOptional       |-> [i \in 1 .. 2 |-> 0],
      logicalAccessIdOptional     |-> [i \in 1 .. 4 |-> 0],
      bookInOptional              |-> [i \in 1 .. 8 |-> 0],
      tradeQualifierOptional      |-> [i \in 1 .. 1 |-> 0],
      accountTypeInternalOptional |-> [i \in 1 .. 1 |-> 0],
      lpRoleOptional              |-> [i \in 1 .. 1 |-> 0],
      clearingAccount             |-> [i \in 1 .. 16 |-> 0],
      freeText                    |-> [i \in 1 .. 18 |-> 0],
      clearingFirmIdOptional      |-> [i \in 1 .. 8 |-> 0],
      traderId                    |-> [i \in 1 .. 16 |-> 0],
      originalInvestorId          |-> [i \in 1 .. 16 |-> 0],
      crossOrderIndicatorOptional |-> [i \in 1 .. 1 |-> 0],
      clearingInstruction         |-> [i \in 1 .. 2 |-> 0] ]

(* D C Trade Message Matched Orders Group at zero, then each field in turn at the values it is checked at *)
CheckedDCTradeMessageMatchedOrdersGroup ==
    { ZeroDCTradeMessageMatchedOrdersGroup }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.orderPx = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.clientId = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.oePartitionIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.logicalAccessIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.tradeQualifierOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.accountTypeInternalOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.lpRoleOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.clearingAccount = one] : one \in Sample(16) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.traderId = one] : one \in Sample(16) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.originalInvestorId = one] : one \in Sample(16) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.crossOrderIndicatorOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroup EXCEPT !.clearingInstruction = one] : one \in Sample(2) }

(* A run of D C Trade Message Matched Orders Group, written one after another *)
RECURSIVE EncodeDCTradeMessageMatchedOrdersGroupList(_)
EncodeDCTradeMessageMatchedOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCTradeMessageMatchedOrdersGroup(Head(messages)) \o EncodeDCTradeMessageMatchedOrdersGroupList(Tail(messages))

(* As many D C Trade Message Matched Orders Group as the field that counts them says *)
RECURSIVE ReadDCTradeMessageMatchedOrdersGroupList(_, _)
ReadDCTradeMessageMatchedOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCTradeMessageMatchedOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCTradeMessageMatchedOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Trade Message Matched Orders Group of each kind, for the lists that carry them *)
OneDCTradeMessageMatchedOrdersGroup == { ZeroDCTradeMessageMatchedOrdersGroup }

(***************************************************************************)
(* D C Trade Message Matched Orders Groups                                 *)
(***************************************************************************)

DCTradeMessageMatchedOrdersGroups ==
    [ blockLengthShort                 : Sample(1),
      dCTradeMessageMatchedOrdersGroup : SampleLists(OneDCTradeMessageMatchedOrdersGroup) ]

EncodeDCTradeMessageMatchedOrdersGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCTradeMessageMatchedOrdersGroup), 1)
        \o EncodeDCTradeMessageMatchedOrdersGroupList(message.dCTradeMessageMatchedOrdersGroup)

DecodeDCTradeMessageMatchedOrdersGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCTradeMessageMatchedOrdersGroup == ReadDCTradeMessageMatchedOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCTradeMessageMatchedOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                 |-> blockLengthShort.value,
         dCTradeMessageMatchedOrdersGroup |-> dCTradeMessageMatchedOrdersGroup.value ], dCTradeMessageMatchedOrdersGroup.rest)

ZeroDCTradeMessageMatchedOrdersGroups ==
    [ blockLengthShort                 |-> [i \in 1 .. 1 |-> 0],
      dCTradeMessageMatchedOrdersGroup |-> << >> ]

(* D C Trade Message Matched Orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCTradeMessageMatchedOrdersGroups ==
    { ZeroDCTradeMessageMatchedOrdersGroups }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedOrdersGroups EXCEPT !.dCTradeMessageMatchedOrdersGroup = one] : one \in SampleLists(OneDCTradeMessageMatchedOrdersGroup) }

(***************************************************************************)
(* D C Trade Message Matched Declarations Group: 124 bytes                 *)
(***************************************************************************)

DCTradeMessageMatchedDeclarationsGroup ==
    [ declarationId               : Sample(8),
      side                        : Sample(1),
      operationType               : Sample(1),
      firmId                      : Sample(8),
      oePartitionIdOptional       : Sample(2),
      logicalAccessIdOptional     : Sample(4),
      bookInOptional              : Sample(8),
      accountTypeOptional         : Sample(1),
      clientOrderId               : Sample(8),
      freeText                    : Sample(18),
      clearingFirmIdOptional      : Sample(8),
      clearingAccount             : Sample(16),
      principalCode               : Sample(8),
      crossOrderIndicatorOptional : Sample(1),
      traderId                    : Sample(16),
      investorId                  : Sample(16) ]

EncodeDCTradeMessageMatchedDeclarationsGroup(message) ==
    message.declarationId
        \o message.side
        \o message.operationType
        \o message.firmId
        \o message.oePartitionIdOptional
        \o message.logicalAccessIdOptional
        \o message.bookInOptional
        \o message.accountTypeOptional
        \o message.clientOrderId
        \o message.freeText
        \o message.clearingFirmIdOptional
        \o message.clearingAccount
        \o message.principalCode
        \o message.crossOrderIndicatorOptional
        \o message.traderId
        \o message.investorId

DecodeDCTradeMessageMatchedDeclarationsGroup(bytes) ==
    LET declarationId == ReadBytes(bytes, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET side == ReadBytes(declarationId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET operationType == ReadBytes(side.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET firmId == ReadBytes(operationType.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oePartitionIdOptional == ReadBytes(firmId.rest, 2) IN IF ~oePartitionIdOptional.ok THEN Fail ELSE
    LET logicalAccessIdOptional == ReadBytes(oePartitionIdOptional.rest, 4) IN IF ~logicalAccessIdOptional.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(logicalAccessIdOptional.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET accountTypeOptional == ReadBytes(bookInOptional.rest, 1) IN IF ~accountTypeOptional.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(accountTypeOptional.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET freeText == ReadBytes(clientOrderId.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET clearingFirmIdOptional == ReadBytes(freeText.rest, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirmIdOptional.rest, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET principalCode == ReadBytes(clearingAccount.rest, 8) IN IF ~principalCode.ok THEN Fail ELSE
    LET crossOrderIndicatorOptional == ReadBytes(principalCode.rest, 1) IN IF ~crossOrderIndicatorOptional.ok THEN Fail ELSE
    LET traderId == ReadBytes(crossOrderIndicatorOptional.rest, 16) IN IF ~traderId.ok THEN Fail ELSE
    LET investorId == ReadBytes(traderId.rest, 16) IN IF ~investorId.ok THEN Fail ELSE
    Ok([ declarationId               |-> declarationId.value,
         side                        |-> side.value,
         operationType               |-> operationType.value,
         firmId                      |-> firmId.value,
         oePartitionIdOptional       |-> oePartitionIdOptional.value,
         logicalAccessIdOptional     |-> logicalAccessIdOptional.value,
         bookInOptional              |-> bookInOptional.value,
         accountTypeOptional         |-> accountTypeOptional.value,
         clientOrderId               |-> clientOrderId.value,
         freeText                    |-> freeText.value,
         clearingFirmIdOptional      |-> clearingFirmIdOptional.value,
         clearingAccount             |-> clearingAccount.value,
         principalCode               |-> principalCode.value,
         crossOrderIndicatorOptional |-> crossOrderIndicatorOptional.value,
         traderId                    |-> traderId.value,
         investorId                  |-> investorId.value ], investorId.rest)

ZeroDCTradeMessageMatchedDeclarationsGroup ==
    [ declarationId               |-> [i \in 1 .. 8 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      operationType               |-> [i \in 1 .. 1 |-> 0],
      firmId                      |-> [i \in 1 .. 8 |-> 0],
      oePartitionIdOptional       |-> [i \in 1 .. 2 |-> 0],
      logicalAccessIdOptional     |-> [i \in 1 .. 4 |-> 0],
      bookInOptional              |-> [i \in 1 .. 8 |-> 0],
      accountTypeOptional         |-> [i \in 1 .. 1 |-> 0],
      clientOrderId               |-> [i \in 1 .. 8 |-> 0],
      freeText                    |-> [i \in 1 .. 18 |-> 0],
      clearingFirmIdOptional      |-> [i \in 1 .. 8 |-> 0],
      clearingAccount             |-> [i \in 1 .. 16 |-> 0],
      principalCode               |-> [i \in 1 .. 8 |-> 0],
      crossOrderIndicatorOptional |-> [i \in 1 .. 1 |-> 0],
      traderId                    |-> [i \in 1 .. 16 |-> 0],
      investorId                  |-> [i \in 1 .. 16 |-> 0] ]

(* D C Trade Message Matched Declarations Group at zero, then each field in turn at the values it is checked at *)
CheckedDCTradeMessageMatchedDeclarationsGroup ==
    { ZeroDCTradeMessageMatchedDeclarationsGroup }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.oePartitionIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.logicalAccessIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.accountTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.clearingAccount = one] : one \in Sample(16) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.principalCode = one] : one \in Sample(8) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.crossOrderIndicatorOptional = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.traderId = one] : one \in Sample(16) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroup EXCEPT !.investorId = one] : one \in Sample(16) }

(* A run of D C Trade Message Matched Declarations Group, written one after another *)
RECURSIVE EncodeDCTradeMessageMatchedDeclarationsGroupList(_)
EncodeDCTradeMessageMatchedDeclarationsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCTradeMessageMatchedDeclarationsGroup(Head(messages)) \o EncodeDCTradeMessageMatchedDeclarationsGroupList(Tail(messages))

(* As many D C Trade Message Matched Declarations Group as the field that counts them says *)
RECURSIVE ReadDCTradeMessageMatchedDeclarationsGroupList(_, _)
ReadDCTradeMessageMatchedDeclarationsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCTradeMessageMatchedDeclarationsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCTradeMessageMatchedDeclarationsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Trade Message Matched Declarations Group of each kind, for the lists that carry them *)
OneDCTradeMessageMatchedDeclarationsGroup == { ZeroDCTradeMessageMatchedDeclarationsGroup }

(***************************************************************************)
(* D C Trade Message Matched Declarations Groups                           *)
(***************************************************************************)

DCTradeMessageMatchedDeclarationsGroups ==
    [ blockLengthShort                       : Sample(1),
      dCTradeMessageMatchedDeclarationsGroup : SampleLists(OneDCTradeMessageMatchedDeclarationsGroup) ]

EncodeDCTradeMessageMatchedDeclarationsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCTradeMessageMatchedDeclarationsGroup), 1)
        \o EncodeDCTradeMessageMatchedDeclarationsGroupList(message.dCTradeMessageMatchedDeclarationsGroup)

DecodeDCTradeMessageMatchedDeclarationsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCTradeMessageMatchedDeclarationsGroup == ReadDCTradeMessageMatchedDeclarationsGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCTradeMessageMatchedDeclarationsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                       |-> blockLengthShort.value,
         dCTradeMessageMatchedDeclarationsGroup |-> dCTradeMessageMatchedDeclarationsGroup.value ], dCTradeMessageMatchedDeclarationsGroup.rest)

ZeroDCTradeMessageMatchedDeclarationsGroups ==
    [ blockLengthShort                       |-> [i \in 1 .. 1 |-> 0],
      dCTradeMessageMatchedDeclarationsGroup |-> << >> ]

(* D C Trade Message Matched Declarations Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCTradeMessageMatchedDeclarationsGroups ==
    { ZeroDCTradeMessageMatchedDeclarationsGroups }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCTradeMessageMatchedDeclarationsGroups EXCEPT !.dCTradeMessageMatchedDeclarationsGroup = one] : one \in SampleLists(OneDCTradeMessageMatchedDeclarationsGroup) }

(***************************************************************************)
(* Dc Trade Message                                                        *)
(***************************************************************************)

DcTradeMessage ==
    [ msgSeqNum                               : Sample(4),
      produceTime                             : Sample(8),
      consumeTime                             : Sample(8),
      eventId                                 : Sample(8),
      executionId                             : Sample(4),
      quantity                                : Sample(8),
      priceOptional                           : Sample(8),
      tradeTime                               : Sample(8),
      publicationTime                         : Sample(8),
      sessionOptional                         : Sample(1),
      execPhase                               : Sample(1),
      transparencyIndicator                   : Sample(1),
      tradeQualifier                          : Sample(1),
      settlementPeriodOptional                : Sample(1),
      settlementFlagOptional                  : Sample(1),
      guaranteeFlagOptional                   : Sample(1),
      counterpartyReasonType                  : Sample(1),
      symbolIndex                             : Sample(4),
      emm                                     : Sample(1),
      tradeType                               : Sample(1),
      dCTradeMessageMatchedOrdersGroups       : DCTradeMessageMatchedOrdersGroups,
      dCTradeMessageMatchedDeclarationsGroups : DCTradeMessageMatchedDeclarationsGroups ]

EncodeDcTradeMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.eventId
        \o message.executionId
        \o message.quantity
        \o message.priceOptional
        \o message.tradeTime
        \o message.publicationTime
        \o message.sessionOptional
        \o message.execPhase
        \o message.transparencyIndicator
        \o message.tradeQualifier
        \o message.settlementPeriodOptional
        \o message.settlementFlagOptional
        \o message.guaranteeFlagOptional
        \o message.counterpartyReasonType
        \o message.symbolIndex
        \o message.emm
        \o message.tradeType
        \o EncodeDCTradeMessageMatchedOrdersGroups(message.dCTradeMessageMatchedOrdersGroups)
        \o EncodeDCTradeMessageMatchedDeclarationsGroups(message.dCTradeMessageMatchedDeclarationsGroups)

DecodeDcTradeMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET eventId == ReadBytes(consumeTime.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET executionId == ReadBytes(eventId.rest, 4) IN IF ~executionId.ok THEN Fail ELSE
    LET quantity == ReadBytes(executionId.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(quantity.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(priceOptional.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET publicationTime == ReadBytes(tradeTime.rest, 8) IN IF ~publicationTime.ok THEN Fail ELSE
    LET sessionOptional == ReadBytes(publicationTime.rest, 1) IN IF ~sessionOptional.ok THEN Fail ELSE
    LET execPhase == ReadBytes(sessionOptional.rest, 1) IN IF ~execPhase.ok THEN Fail ELSE
    LET transparencyIndicator == ReadBytes(execPhase.rest, 1) IN IF ~transparencyIndicator.ok THEN Fail ELSE
    LET tradeQualifier == ReadBytes(transparencyIndicator.rest, 1) IN IF ~tradeQualifier.ok THEN Fail ELSE
    LET settlementPeriodOptional == ReadBytes(tradeQualifier.rest, 1) IN IF ~settlementPeriodOptional.ok THEN Fail ELSE
    LET settlementFlagOptional == ReadBytes(settlementPeriodOptional.rest, 1) IN IF ~settlementFlagOptional.ok THEN Fail ELSE
    LET guaranteeFlagOptional == ReadBytes(settlementFlagOptional.rest, 1) IN IF ~guaranteeFlagOptional.ok THEN Fail ELSE
    LET counterpartyReasonType == ReadBytes(guaranteeFlagOptional.rest, 1) IN IF ~counterpartyReasonType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(counterpartyReasonType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET tradeType == ReadBytes(emm.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET dCTradeMessageMatchedOrdersGroups == DecodeDCTradeMessageMatchedOrdersGroups(tradeType.rest) IN IF ~dCTradeMessageMatchedOrdersGroups.ok THEN Fail ELSE
    LET dCTradeMessageMatchedDeclarationsGroups == DecodeDCTradeMessageMatchedDeclarationsGroups(dCTradeMessageMatchedOrdersGroups.rest) IN IF ~dCTradeMessageMatchedDeclarationsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                               |-> msgSeqNum.value,
         produceTime                             |-> produceTime.value,
         consumeTime                             |-> consumeTime.value,
         eventId                                 |-> eventId.value,
         executionId                             |-> executionId.value,
         quantity                                |-> quantity.value,
         priceOptional                           |-> priceOptional.value,
         tradeTime                               |-> tradeTime.value,
         publicationTime                         |-> publicationTime.value,
         sessionOptional                         |-> sessionOptional.value,
         execPhase                               |-> execPhase.value,
         transparencyIndicator                   |-> transparencyIndicator.value,
         tradeQualifier                          |-> tradeQualifier.value,
         settlementPeriodOptional                |-> settlementPeriodOptional.value,
         settlementFlagOptional                  |-> settlementFlagOptional.value,
         guaranteeFlagOptional                   |-> guaranteeFlagOptional.value,
         counterpartyReasonType                  |-> counterpartyReasonType.value,
         symbolIndex                             |-> symbolIndex.value,
         emm                                     |-> emm.value,
         tradeType                               |-> tradeType.value,
         dCTradeMessageMatchedOrdersGroups       |-> dCTradeMessageMatchedOrdersGroups.value,
         dCTradeMessageMatchedDeclarationsGroups |-> dCTradeMessageMatchedDeclarationsGroups.value ], dCTradeMessageMatchedDeclarationsGroups.rest)

ZeroDcTradeMessage ==
    [ msgSeqNum                               |-> [i \in 1 .. 4 |-> 0],
      produceTime                             |-> [i \in 1 .. 8 |-> 0],
      consumeTime                             |-> [i \in 1 .. 8 |-> 0],
      eventId                                 |-> [i \in 1 .. 8 |-> 0],
      executionId                             |-> [i \in 1 .. 4 |-> 0],
      quantity                                |-> [i \in 1 .. 8 |-> 0],
      priceOptional                           |-> [i \in 1 .. 8 |-> 0],
      tradeTime                               |-> [i \in 1 .. 8 |-> 0],
      publicationTime                         |-> [i \in 1 .. 8 |-> 0],
      sessionOptional                         |-> [i \in 1 .. 1 |-> 0],
      execPhase                               |-> [i \in 1 .. 1 |-> 0],
      transparencyIndicator                   |-> [i \in 1 .. 1 |-> 0],
      tradeQualifier                          |-> [i \in 1 .. 1 |-> 0],
      settlementPeriodOptional                |-> [i \in 1 .. 1 |-> 0],
      settlementFlagOptional                  |-> [i \in 1 .. 1 |-> 0],
      guaranteeFlagOptional                   |-> [i \in 1 .. 1 |-> 0],
      counterpartyReasonType                  |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                             |-> [i \in 1 .. 4 |-> 0],
      emm                                     |-> [i \in 1 .. 1 |-> 0],
      tradeType                               |-> [i \in 1 .. 1 |-> 0],
      dCTradeMessageMatchedOrdersGroups       |-> ZeroDCTradeMessageMatchedOrdersGroups,
      dCTradeMessageMatchedDeclarationsGroups |-> ZeroDCTradeMessageMatchedDeclarationsGroups ]

(* Dc Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedDcTradeMessage ==
    { ZeroDcTradeMessage }
        \cup { [ZeroDcTradeMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcTradeMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeMessage EXCEPT !.executionId = one] : one \in Sample(4) }
        \cup { [ZeroDcTradeMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeMessage EXCEPT !.publicationTime = one] : one \in Sample(8) }
        \cup { [ZeroDcTradeMessage EXCEPT !.sessionOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.execPhase = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.transparencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.tradeQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.settlementPeriodOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.settlementFlagOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.guaranteeFlagOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.counterpartyReasonType = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcTradeMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroDcTradeMessage EXCEPT !.dCTradeMessageMatchedOrdersGroups = one] : one \in CheckedDCTradeMessageMatchedOrdersGroups }
        \cup { [ZeroDcTradeMessage EXCEPT !.dCTradeMessageMatchedDeclarationsGroups = one] : one \in CheckedDCTradeMessageMatchedDeclarationsGroups }

(***************************************************************************)
(* Dc Short Declaration Fill Message: 228 bytes                            *)
(***************************************************************************)

DcShortDeclarationFillMessage ==
    [ msgSeqNum                : Sample(4),
      produceTime              : Sample(8),
      consumeTime              : Sample(8),
      messageSendingTime       : Sample(8),
      bookIn                   : Sample(8),
      bookOutTime              : Sample(8),
      oeginFromMember          : Sample(8),
      oegoutTimeToMe           : Sample(8),
      operationType            : Sample(1),
      declarationEventType     : Sample(1),
      declarationStatus        : Sample(1),
      eventId                  : Sample(8),
      emm                      : Sample(1),
      symbolIndex              : Sample(4),
      declarationId            : Sample(8),
      price                    : Sample(8),
      quantity                 : Sample(8),
      side                     : Sample(1),
      crossOrderIndicator      : Sample(1),
      tradeTime                : Sample(8),
      enteringCounterparty     : Sample(8),
      sessionOptional          : Sample(1),
      tradeType                : Sample(1),
      firmId                   : Sample(8),
      oePartitionId            : Sample(2),
      logicalAccessId          : Sample(4),
      traderId                 : Sample(16),
      investorId               : Sample(16),
      principalCode            : Sample(8),
      clearingFirmIdOptional   : Sample(8),
      clearingAccount          : Sample(16),
      accountType              : Sample(1),
      clientOrderId            : Sample(8),
      freeText                 : Sample(18),
      settlementPeriodOptional : Sample(1),
      settlementFlagOptional   : Sample(1),
      guaranteeFlagOptional    : Sample(1) ]

EncodeDcShortDeclarationFillMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.messageSendingTime
        \o message.bookIn
        \o message.bookOutTime
        \o message.oeginFromMember
        \o message.oegoutTimeToMe
        \o message.operationType
        \o message.declarationEventType
        \o message.declarationStatus
        \o message.eventId
        \o message.emm
        \o message.symbolIndex
        \o message.declarationId
        \o message.price
        \o message.quantity
        \o message.side
        \o message.crossOrderIndicator
        \o message.tradeTime
        \o message.enteringCounterparty
        \o message.sessionOptional
        \o message.tradeType
        \o message.firmId
        \o message.oePartitionId
        \o message.logicalAccessId
        \o message.traderId
        \o message.investorId
        \o message.principalCode
        \o message.clearingFirmIdOptional
        \o message.clearingAccount
        \o message.accountType
        \o message.clientOrderId
        \o message.freeText
        \o message.settlementPeriodOptional
        \o message.settlementFlagOptional
        \o message.guaranteeFlagOptional

DecodeDcShortDeclarationFillMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET messageSendingTime == ReadBytes(consumeTime.rest, 8) IN IF ~messageSendingTime.ok THEN Fail ELSE
    LET bookIn == ReadBytes(messageSendingTime.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET oeginFromMember == ReadBytes(bookOutTime.rest, 8) IN IF ~oeginFromMember.ok THEN Fail ELSE
    LET oegoutTimeToMe == ReadBytes(oeginFromMember.rest, 8) IN IF ~oegoutTimeToMe.ok THEN Fail ELSE
    LET operationType == ReadBytes(oegoutTimeToMe.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET declarationEventType == ReadBytes(operationType.rest, 1) IN IF ~declarationEventType.ok THEN Fail ELSE
    LET declarationStatus == ReadBytes(declarationEventType.rest, 1) IN IF ~declarationStatus.ok THEN Fail ELSE
    LET eventId == ReadBytes(declarationStatus.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET emm == ReadBytes(eventId.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(emm.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET declarationId == ReadBytes(symbolIndex.rest, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET price == ReadBytes(declarationId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET crossOrderIndicator == ReadBytes(side.rest, 1) IN IF ~crossOrderIndicator.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(crossOrderIndicator.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET enteringCounterparty == ReadBytes(tradeTime.rest, 8) IN IF ~enteringCounterparty.ok THEN Fail ELSE
    LET sessionOptional == ReadBytes(enteringCounterparty.rest, 1) IN IF ~sessionOptional.ok THEN Fail ELSE
    LET tradeType == ReadBytes(sessionOptional.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET firmId == ReadBytes(tradeType.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET oePartitionId == ReadBytes(firmId.rest, 2) IN IF ~oePartitionId.ok THEN Fail ELSE
    LET logicalAccessId == ReadBytes(oePartitionId.rest, 4) IN IF ~logicalAccessId.ok THEN Fail ELSE
    LET traderId == ReadBytes(logicalAccessId.rest, 16) IN IF ~traderId.ok THEN Fail ELSE
    LET investorId == ReadBytes(traderId.rest, 16) IN IF ~investorId.ok THEN Fail ELSE
    LET principalCode == ReadBytes(investorId.rest, 8) IN IF ~principalCode.ok THEN Fail ELSE
    LET clearingFirmIdOptional == ReadBytes(principalCode.rest, 8) IN IF ~clearingFirmIdOptional.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(clearingFirmIdOptional.rest, 16) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingAccount.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(accountType.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET freeText == ReadBytes(clientOrderId.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET settlementPeriodOptional == ReadBytes(freeText.rest, 1) IN IF ~settlementPeriodOptional.ok THEN Fail ELSE
    LET settlementFlagOptional == ReadBytes(settlementPeriodOptional.rest, 1) IN IF ~settlementFlagOptional.ok THEN Fail ELSE
    LET guaranteeFlagOptional == ReadBytes(settlementFlagOptional.rest, 1) IN IF ~guaranteeFlagOptional.ok THEN Fail ELSE
    Ok([ msgSeqNum                |-> msgSeqNum.value,
         produceTime              |-> produceTime.value,
         consumeTime              |-> consumeTime.value,
         messageSendingTime       |-> messageSendingTime.value,
         bookIn                   |-> bookIn.value,
         bookOutTime              |-> bookOutTime.value,
         oeginFromMember          |-> oeginFromMember.value,
         oegoutTimeToMe           |-> oegoutTimeToMe.value,
         operationType            |-> operationType.value,
         declarationEventType     |-> declarationEventType.value,
         declarationStatus        |-> declarationStatus.value,
         eventId                  |-> eventId.value,
         emm                      |-> emm.value,
         symbolIndex              |-> symbolIndex.value,
         declarationId            |-> declarationId.value,
         price                    |-> price.value,
         quantity                 |-> quantity.value,
         side                     |-> side.value,
         crossOrderIndicator      |-> crossOrderIndicator.value,
         tradeTime                |-> tradeTime.value,
         enteringCounterparty     |-> enteringCounterparty.value,
         sessionOptional          |-> sessionOptional.value,
         tradeType                |-> tradeType.value,
         firmId                   |-> firmId.value,
         oePartitionId            |-> oePartitionId.value,
         logicalAccessId          |-> logicalAccessId.value,
         traderId                 |-> traderId.value,
         investorId               |-> investorId.value,
         principalCode            |-> principalCode.value,
         clearingFirmIdOptional   |-> clearingFirmIdOptional.value,
         clearingAccount          |-> clearingAccount.value,
         accountType              |-> accountType.value,
         clientOrderId            |-> clientOrderId.value,
         freeText                 |-> freeText.value,
         settlementPeriodOptional |-> settlementPeriodOptional.value,
         settlementFlagOptional   |-> settlementFlagOptional.value,
         guaranteeFlagOptional    |-> guaranteeFlagOptional.value ], guaranteeFlagOptional.rest)

ZeroDcShortDeclarationFillMessage ==
    [ msgSeqNum                |-> [i \in 1 .. 4 |-> 0],
      produceTime              |-> [i \in 1 .. 8 |-> 0],
      consumeTime              |-> [i \in 1 .. 8 |-> 0],
      messageSendingTime       |-> [i \in 1 .. 8 |-> 0],
      bookIn                   |-> [i \in 1 .. 8 |-> 0],
      bookOutTime              |-> [i \in 1 .. 8 |-> 0],
      oeginFromMember          |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMe           |-> [i \in 1 .. 8 |-> 0],
      operationType            |-> [i \in 1 .. 1 |-> 0],
      declarationEventType     |-> [i \in 1 .. 1 |-> 0],
      declarationStatus        |-> [i \in 1 .. 1 |-> 0],
      eventId                  |-> [i \in 1 .. 8 |-> 0],
      emm                      |-> [i \in 1 .. 1 |-> 0],
      symbolIndex              |-> [i \in 1 .. 4 |-> 0],
      declarationId            |-> [i \in 1 .. 8 |-> 0],
      price                    |-> [i \in 1 .. 8 |-> 0],
      quantity                 |-> [i \in 1 .. 8 |-> 0],
      side                     |-> [i \in 1 .. 1 |-> 0],
      crossOrderIndicator      |-> [i \in 1 .. 1 |-> 0],
      tradeTime                |-> [i \in 1 .. 8 |-> 0],
      enteringCounterparty     |-> [i \in 1 .. 8 |-> 0],
      sessionOptional          |-> [i \in 1 .. 1 |-> 0],
      tradeType                |-> [i \in 1 .. 1 |-> 0],
      firmId                   |-> [i \in 1 .. 8 |-> 0],
      oePartitionId            |-> [i \in 1 .. 2 |-> 0],
      logicalAccessId          |-> [i \in 1 .. 4 |-> 0],
      traderId                 |-> [i \in 1 .. 16 |-> 0],
      investorId               |-> [i \in 1 .. 16 |-> 0],
      principalCode            |-> [i \in 1 .. 8 |-> 0],
      clearingFirmIdOptional   |-> [i \in 1 .. 8 |-> 0],
      clearingAccount          |-> [i \in 1 .. 16 |-> 0],
      accountType              |-> [i \in 1 .. 1 |-> 0],
      clientOrderId            |-> [i \in 1 .. 8 |-> 0],
      freeText                 |-> [i \in 1 .. 18 |-> 0],
      settlementPeriodOptional |-> [i \in 1 .. 1 |-> 0],
      settlementFlagOptional   |-> [i \in 1 .. 1 |-> 0],
      guaranteeFlagOptional    |-> [i \in 1 .. 1 |-> 0] ]

(* Dc Short Declaration Fill Message at zero, then each field in turn at the values it is checked at *)
CheckedDcShortDeclarationFillMessage ==
    { ZeroDcShortDeclarationFillMessage }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.messageSendingTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.oeginFromMember = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.oegoutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.declarationEventType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.declarationStatus = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.crossOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.enteringCounterparty = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.sessionOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.oePartitionId = one] : one \in Sample(2) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.logicalAccessId = one] : one \in Sample(4) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.traderId = one] : one \in Sample(16) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.investorId = one] : one \in Sample(16) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.principalCode = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.clearingFirmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.clearingAccount = one] : one \in Sample(16) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.settlementPeriodOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.settlementFlagOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcShortDeclarationFillMessage EXCEPT !.guaranteeFlagOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* D C Quote Request Message Non Modifiable Short Codes Group: 16 bytes    *)
(***************************************************************************)

DCQuoteRequestMessageNonModifiableShortCodesGroup ==
    [ originalClientIdShortCode         : Sample(4),
      originalExecWFirmShortCode        : Sample(4),
      originalInvestDecisWFirmShortCode : Sample(4),
      originalNonExecBrokerShortCode    : Sample(4) ]

EncodeDCQuoteRequestMessageNonModifiableShortCodesGroup(message) ==
    message.originalClientIdShortCode
        \o message.originalExecWFirmShortCode
        \o message.originalInvestDecisWFirmShortCode
        \o message.originalNonExecBrokerShortCode

DecodeDCQuoteRequestMessageNonModifiableShortCodesGroup(bytes) ==
    LET originalClientIdShortCode == ReadBytes(bytes, 4) IN IF ~originalClientIdShortCode.ok THEN Fail ELSE
    LET originalExecWFirmShortCode == ReadBytes(originalClientIdShortCode.rest, 4) IN IF ~originalExecWFirmShortCode.ok THEN Fail ELSE
    LET originalInvestDecisWFirmShortCode == ReadBytes(originalExecWFirmShortCode.rest, 4) IN IF ~originalInvestDecisWFirmShortCode.ok THEN Fail ELSE
    LET originalNonExecBrokerShortCode == ReadBytes(originalInvestDecisWFirmShortCode.rest, 4) IN IF ~originalNonExecBrokerShortCode.ok THEN Fail ELSE
    Ok([ originalClientIdShortCode         |-> originalClientIdShortCode.value,
         originalExecWFirmShortCode        |-> originalExecWFirmShortCode.value,
         originalInvestDecisWFirmShortCode |-> originalInvestDecisWFirmShortCode.value,
         originalNonExecBrokerShortCode    |-> originalNonExecBrokerShortCode.value ], originalNonExecBrokerShortCode.rest)

ZeroDCQuoteRequestMessageNonModifiableShortCodesGroup ==
    [ originalClientIdShortCode         |-> [i \in 1 .. 4 |-> 0],
      originalExecWFirmShortCode        |-> [i \in 1 .. 4 |-> 0],
      originalInvestDecisWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      originalNonExecBrokerShortCode    |-> [i \in 1 .. 4 |-> 0] ]

(* D C Quote Request Message Non Modifiable Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteRequestMessageNonModifiableShortCodesGroup ==
    { ZeroDCQuoteRequestMessageNonModifiableShortCodesGroup }
        \cup { [ZeroDCQuoteRequestMessageNonModifiableShortCodesGroup EXCEPT !.originalClientIdShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCQuoteRequestMessageNonModifiableShortCodesGroup EXCEPT !.originalExecWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCQuoteRequestMessageNonModifiableShortCodesGroup EXCEPT !.originalInvestDecisWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDCQuoteRequestMessageNonModifiableShortCodesGroup EXCEPT !.originalNonExecBrokerShortCode = one] : one \in Sample(4) }

(* A run of D C Quote Request Message Non Modifiable Short Codes Group, written one after another *)
RECURSIVE EncodeDCQuoteRequestMessageNonModifiableShortCodesGroupList(_)
EncodeDCQuoteRequestMessageNonModifiableShortCodesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteRequestMessageNonModifiableShortCodesGroup(Head(messages)) \o EncodeDCQuoteRequestMessageNonModifiableShortCodesGroupList(Tail(messages))

(* As many D C Quote Request Message Non Modifiable Short Codes Group as the field that counts them says *)
RECURSIVE ReadDCQuoteRequestMessageNonModifiableShortCodesGroupList(_, _)
ReadDCQuoteRequestMessageNonModifiableShortCodesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteRequestMessageNonModifiableShortCodesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteRequestMessageNonModifiableShortCodesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Request Message Non Modifiable Short Codes Group of each kind, for the lists that carry them *)
OneDCQuoteRequestMessageNonModifiableShortCodesGroup == { ZeroDCQuoteRequestMessageNonModifiableShortCodesGroup }

(***************************************************************************)
(* D C Quote Request Message Non Modifiable Short Codes Groups             *)
(***************************************************************************)

DCQuoteRequestMessageNonModifiableShortCodesGroups ==
    [ blockLengthShort                                  : Sample(1),
      dCQuoteRequestMessageNonModifiableShortCodesGroup : SampleLists(OneDCQuoteRequestMessageNonModifiableShortCodesGroup) ]

EncodeDCQuoteRequestMessageNonModifiableShortCodesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteRequestMessageNonModifiableShortCodesGroup), 1)
        \o EncodeDCQuoteRequestMessageNonModifiableShortCodesGroupList(message.dCQuoteRequestMessageNonModifiableShortCodesGroup)

DecodeDCQuoteRequestMessageNonModifiableShortCodesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteRequestMessageNonModifiableShortCodesGroup == ReadDCQuoteRequestMessageNonModifiableShortCodesGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteRequestMessageNonModifiableShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                  |-> blockLengthShort.value,
         dCQuoteRequestMessageNonModifiableShortCodesGroup |-> dCQuoteRequestMessageNonModifiableShortCodesGroup.value ], dCQuoteRequestMessageNonModifiableShortCodesGroup.rest)

ZeroDCQuoteRequestMessageNonModifiableShortCodesGroups ==
    [ blockLengthShort                                  |-> [i \in 1 .. 1 |-> 0],
      dCQuoteRequestMessageNonModifiableShortCodesGroup |-> << >> ]

(* D C Quote Request Message Non Modifiable Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteRequestMessageNonModifiableShortCodesGroups ==
    { ZeroDCQuoteRequestMessageNonModifiableShortCodesGroups }
        \cup { [ZeroDCQuoteRequestMessageNonModifiableShortCodesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteRequestMessageNonModifiableShortCodesGroups EXCEPT !.dCQuoteRequestMessageNonModifiableShortCodesGroup = one] : one \in SampleLists(OneDCQuoteRequestMessageNonModifiableShortCodesGroup) }

(***************************************************************************)
(* D C Quote Request Message Short Codes Details Non Modifiable Group: 3   *)
(* bytes                                                                   *)
(***************************************************************************)

DCQuoteRequestMessageShortCodesDetailsNonModifiableGroup ==
    [ originalShortCodeType  : Sample(1),
      shortCodeRole          : Sample(1),
      shortCodeRoleQualifier : Sample(1) ]

EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup(message) ==
    message.originalShortCodeType
        \o message.shortCodeRole
        \o message.shortCodeRoleQualifier

DecodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup(bytes) ==
    LET originalShortCodeType == ReadBytes(bytes, 1) IN IF ~originalShortCodeType.ok THEN Fail ELSE
    LET shortCodeRole == ReadBytes(originalShortCodeType.rest, 1) IN IF ~shortCodeRole.ok THEN Fail ELSE
    LET shortCodeRoleQualifier == ReadBytes(shortCodeRole.rest, 1) IN IF ~shortCodeRoleQualifier.ok THEN Fail ELSE
    Ok([ originalShortCodeType  |-> originalShortCodeType.value,
         shortCodeRole          |-> shortCodeRole.value,
         shortCodeRoleQualifier |-> shortCodeRoleQualifier.value ], shortCodeRoleQualifier.rest)

ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup ==
    [ originalShortCodeType  |-> [i \in 1 .. 1 |-> 0],
      shortCodeRole          |-> [i \in 1 .. 1 |-> 0],
      shortCodeRoleQualifier |-> [i \in 1 .. 1 |-> 0] ]

(* D C Quote Request Message Short Codes Details Non Modifiable Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup ==
    { ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup }
        \cup { [ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup EXCEPT !.originalShortCodeType = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup EXCEPT !.shortCodeRole = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup EXCEPT !.shortCodeRoleQualifier = one] : one \in Sample(1) }

(* A run of D C Quote Request Message Short Codes Details Non Modifiable Group, written one after another *)
RECURSIVE EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(_)
EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup(Head(messages)) \o EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(Tail(messages))

(* As many D C Quote Request Message Short Codes Details Non Modifiable Group as the field that counts them says *)
RECURSIVE ReadDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(_, _)
ReadDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Request Message Short Codes Details Non Modifiable Group of each kind, for the lists that carry them *)
OneDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup == { ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup }

(***************************************************************************)
(* D C Quote Request Message Short Codes Details Non Modifiable Groups     *)
(***************************************************************************)

DCQuoteRequestMessageShortCodesDetailsNonModifiableGroups ==
    [ blockLengthShort                                         : Sample(1),
      dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup : SampleLists(OneDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup) ]

EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup), 1)
        \o EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(message.dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup)

DecodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup == ReadDCQuoteRequestMessageShortCodesDetailsNonModifiableGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                                         |-> blockLengthShort.value,
         dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup |-> dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup.value ], dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup.rest)

ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups ==
    [ blockLengthShort                                         |-> [i \in 1 .. 1 |-> 0],
      dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup |-> << >> ]

(* D C Quote Request Message Short Codes Details Non Modifiable Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups ==
    { ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups }
        \cup { [ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups EXCEPT !.dCQuoteRequestMessageShortCodesDetailsNonModifiableGroup = one] : one \in SampleLists(OneDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup) }

(***************************************************************************)
(* D C Quote Request Message Rf Q Optional Fields Group: 11 bytes          *)
(***************************************************************************)

DCQuoteRequestMessageRfQOptionalFieldsGroup ==
    [ limitMatchingPrice : Sample(8),
      minimumNumberOfLPs : Sample(1),
      expirationDelay    : Sample(2) ]

EncodeDCQuoteRequestMessageRfQOptionalFieldsGroup(message) ==
    message.limitMatchingPrice
        \o message.minimumNumberOfLPs
        \o message.expirationDelay

DecodeDCQuoteRequestMessageRfQOptionalFieldsGroup(bytes) ==
    LET limitMatchingPrice == ReadBytes(bytes, 8) IN IF ~limitMatchingPrice.ok THEN Fail ELSE
    LET minimumNumberOfLPs == ReadBytes(limitMatchingPrice.rest, 1) IN IF ~minimumNumberOfLPs.ok THEN Fail ELSE
    LET expirationDelay == ReadBytes(minimumNumberOfLPs.rest, 2) IN IF ~expirationDelay.ok THEN Fail ELSE
    Ok([ limitMatchingPrice |-> limitMatchingPrice.value,
         minimumNumberOfLPs |-> minimumNumberOfLPs.value,
         expirationDelay    |-> expirationDelay.value ], expirationDelay.rest)

ZeroDCQuoteRequestMessageRfQOptionalFieldsGroup ==
    [ limitMatchingPrice |-> [i \in 1 .. 8 |-> 0],
      minimumNumberOfLPs |-> [i \in 1 .. 1 |-> 0],
      expirationDelay    |-> [i \in 1 .. 2 |-> 0] ]

(* D C Quote Request Message Rf Q Optional Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteRequestMessageRfQOptionalFieldsGroup ==
    { ZeroDCQuoteRequestMessageRfQOptionalFieldsGroup }
        \cup { [ZeroDCQuoteRequestMessageRfQOptionalFieldsGroup EXCEPT !.limitMatchingPrice = one] : one \in Sample(8) }
        \cup { [ZeroDCQuoteRequestMessageRfQOptionalFieldsGroup EXCEPT !.minimumNumberOfLPs = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteRequestMessageRfQOptionalFieldsGroup EXCEPT !.expirationDelay = one] : one \in Sample(2) }

(* A run of D C Quote Request Message Rf Q Optional Fields Group, written one after another *)
RECURSIVE EncodeDCQuoteRequestMessageRfQOptionalFieldsGroupList(_)
EncodeDCQuoteRequestMessageRfQOptionalFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDCQuoteRequestMessageRfQOptionalFieldsGroup(Head(messages)) \o EncodeDCQuoteRequestMessageRfQOptionalFieldsGroupList(Tail(messages))

(* As many D C Quote Request Message Rf Q Optional Fields Group as the field that counts them says *)
RECURSIVE ReadDCQuoteRequestMessageRfQOptionalFieldsGroupList(_, _)
ReadDCQuoteRequestMessageRfQOptionalFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDCQuoteRequestMessageRfQOptionalFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDCQuoteRequestMessageRfQOptionalFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One D C Quote Request Message Rf Q Optional Fields Group of each kind, for the lists that carry them *)
OneDCQuoteRequestMessageRfQOptionalFieldsGroup == { ZeroDCQuoteRequestMessageRfQOptionalFieldsGroup }

(***************************************************************************)
(* D C Quote Request Message Rf Q Optional Fields Groups                   *)
(***************************************************************************)

DCQuoteRequestMessageRfQOptionalFieldsGroups ==
    [ blockLengthShort                            : Sample(1),
      dCQuoteRequestMessageRfQOptionalFieldsGroup : SampleLists(OneDCQuoteRequestMessageRfQOptionalFieldsGroup) ]

EncodeDCQuoteRequestMessageRfQOptionalFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.dCQuoteRequestMessageRfQOptionalFieldsGroup), 1)
        \o EncodeDCQuoteRequestMessageRfQOptionalFieldsGroupList(message.dCQuoteRequestMessageRfQOptionalFieldsGroup)

DecodeDCQuoteRequestMessageRfQOptionalFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET dCQuoteRequestMessageRfQOptionalFieldsGroup == ReadDCQuoteRequestMessageRfQOptionalFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~dCQuoteRequestMessageRfQOptionalFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                            |-> blockLengthShort.value,
         dCQuoteRequestMessageRfQOptionalFieldsGroup |-> dCQuoteRequestMessageRfQOptionalFieldsGroup.value ], dCQuoteRequestMessageRfQOptionalFieldsGroup.rest)

ZeroDCQuoteRequestMessageRfQOptionalFieldsGroups ==
    [ blockLengthShort                            |-> [i \in 1 .. 1 |-> 0],
      dCQuoteRequestMessageRfQOptionalFieldsGroup |-> << >> ]

(* D C Quote Request Message Rf Q Optional Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedDCQuoteRequestMessageRfQOptionalFieldsGroups ==
    { ZeroDCQuoteRequestMessageRfQOptionalFieldsGroups }
        \cup { [ZeroDCQuoteRequestMessageRfQOptionalFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroDCQuoteRequestMessageRfQOptionalFieldsGroups EXCEPT !.dCQuoteRequestMessageRfQOptionalFieldsGroup = one] : one \in SampleLists(OneDCQuoteRequestMessageRfQOptionalFieldsGroup) }

(***************************************************************************)
(* Dc Quote Request Message                                                *)
(***************************************************************************)

DcQuoteRequestMessage ==
    [ msgSeqNum                                                 : Sample(4),
      produceTime                                               : Sample(8),
      consumeTime                                               : Sample(8),
      eventId                                                   : Sample(8),
      bookIn                                                    : Sample(8),
      bookOutTime                                               : Sample(8),
      clientOrderId                                             : Sample(8),
      darkExecutionInstruction                                  : Sample(1),
      emm                                                       : Sample(1),
      endClient                                                 : Sample(11),
      firmId                                                    : Sample(8),
      firmIdPublication                                         : Sample(1),
      oeSessionId                                               : Sample(8),
      oeginFromMember                                           : Sample(8),
      oegoutTimeToMe                                            : Sample(8),
      orderId                                                   : Sample(8),
      orderQty                                                  : Sample(8),
      orderSideOptional                                         : Sample(1),
      rfqStatus                                                 : Sample(1),
      symbolIndex                                               : Sample(4),
      minOrderQty                                               : Sample(8),
      sequenceTime                                              : Sample(8),
      rfqType                                                   : Sample(1),
      dCQuoteRequestMessageNonModifiableShortCodesGroups        : DCQuoteRequestMessageNonModifiableShortCodesGroups,
      dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups : DCQuoteRequestMessageShortCodesDetailsNonModifiableGroups,
      dCQuoteRequestMessageRfQOptionalFieldsGroups              : DCQuoteRequestMessageRfQOptionalFieldsGroups ]

EncodeDcQuoteRequestMessage(message) ==
    message.msgSeqNum
        \o message.produceTime
        \o message.consumeTime
        \o message.eventId
        \o message.bookIn
        \o message.bookOutTime
        \o message.clientOrderId
        \o message.darkExecutionInstruction
        \o message.emm
        \o message.endClient
        \o message.firmId
        \o message.firmIdPublication
        \o message.oeSessionId
        \o message.oeginFromMember
        \o message.oegoutTimeToMe
        \o message.orderId
        \o message.orderQty
        \o message.orderSideOptional
        \o message.rfqStatus
        \o message.symbolIndex
        \o message.minOrderQty
        \o message.sequenceTime
        \o message.rfqType
        \o EncodeDCQuoteRequestMessageNonModifiableShortCodesGroups(message.dCQuoteRequestMessageNonModifiableShortCodesGroups)
        \o EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups(message.dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups)
        \o EncodeDCQuoteRequestMessageRfQOptionalFieldsGroups(message.dCQuoteRequestMessageRfQOptionalFieldsGroups)

DecodeDcQuoteRequestMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET produceTime == ReadBytes(msgSeqNum.rest, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET eventId == ReadBytes(consumeTime.rest, 8) IN IF ~eventId.ok THEN Fail ELSE
    LET bookIn == ReadBytes(eventId.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(bookOutTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET darkExecutionInstruction == ReadBytes(clientOrderId.rest, 1) IN IF ~darkExecutionInstruction.ok THEN Fail ELSE
    LET emm == ReadBytes(darkExecutionInstruction.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET endClient == ReadBytes(emm.rest, 11) IN IF ~endClient.ok THEN Fail ELSE
    LET firmId == ReadBytes(endClient.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET firmIdPublication == ReadBytes(firmId.rest, 1) IN IF ~firmIdPublication.ok THEN Fail ELSE
    LET oeSessionId == ReadBytes(firmIdPublication.rest, 8) IN IF ~oeSessionId.ok THEN Fail ELSE
    LET oeginFromMember == ReadBytes(oeSessionId.rest, 8) IN IF ~oeginFromMember.ok THEN Fail ELSE
    LET oegoutTimeToMe == ReadBytes(oeginFromMember.rest, 8) IN IF ~oegoutTimeToMe.ok THEN Fail ELSE
    LET orderId == ReadBytes(oegoutTimeToMe.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET orderSideOptional == ReadBytes(orderQty.rest, 1) IN IF ~orderSideOptional.ok THEN Fail ELSE
    LET rfqStatus == ReadBytes(orderSideOptional.rest, 1) IN IF ~rfqStatus.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(rfqStatus.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET minOrderQty == ReadBytes(symbolIndex.rest, 8) IN IF ~minOrderQty.ok THEN Fail ELSE
    LET sequenceTime == ReadBytes(minOrderQty.rest, 8) IN IF ~sequenceTime.ok THEN Fail ELSE
    LET rfqType == ReadBytes(sequenceTime.rest, 1) IN IF ~rfqType.ok THEN Fail ELSE
    LET dCQuoteRequestMessageNonModifiableShortCodesGroups == DecodeDCQuoteRequestMessageNonModifiableShortCodesGroups(rfqType.rest) IN IF ~dCQuoteRequestMessageNonModifiableShortCodesGroups.ok THEN Fail ELSE
    LET dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups == DecodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups(dCQuoteRequestMessageNonModifiableShortCodesGroups.rest) IN IF ~dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups.ok THEN Fail ELSE
    LET dCQuoteRequestMessageRfQOptionalFieldsGroups == DecodeDCQuoteRequestMessageRfQOptionalFieldsGroups(dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups.rest) IN IF ~dCQuoteRequestMessageRfQOptionalFieldsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                                                 |-> msgSeqNum.value,
         produceTime                                               |-> produceTime.value,
         consumeTime                                               |-> consumeTime.value,
         eventId                                                   |-> eventId.value,
         bookIn                                                    |-> bookIn.value,
         bookOutTime                                               |-> bookOutTime.value,
         clientOrderId                                             |-> clientOrderId.value,
         darkExecutionInstruction                                  |-> darkExecutionInstruction.value,
         emm                                                       |-> emm.value,
         endClient                                                 |-> endClient.value,
         firmId                                                    |-> firmId.value,
         firmIdPublication                                         |-> firmIdPublication.value,
         oeSessionId                                               |-> oeSessionId.value,
         oeginFromMember                                           |-> oeginFromMember.value,
         oegoutTimeToMe                                            |-> oegoutTimeToMe.value,
         orderId                                                   |-> orderId.value,
         orderQty                                                  |-> orderQty.value,
         orderSideOptional                                         |-> orderSideOptional.value,
         rfqStatus                                                 |-> rfqStatus.value,
         symbolIndex                                               |-> symbolIndex.value,
         minOrderQty                                               |-> minOrderQty.value,
         sequenceTime                                              |-> sequenceTime.value,
         rfqType                                                   |-> rfqType.value,
         dCQuoteRequestMessageNonModifiableShortCodesGroups        |-> dCQuoteRequestMessageNonModifiableShortCodesGroups.value,
         dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups |-> dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups.value,
         dCQuoteRequestMessageRfQOptionalFieldsGroups              |-> dCQuoteRequestMessageRfQOptionalFieldsGroups.value ], dCQuoteRequestMessageRfQOptionalFieldsGroups.rest)

ZeroDcQuoteRequestMessage ==
    [ msgSeqNum                                                 |-> [i \in 1 .. 4 |-> 0],
      produceTime                                               |-> [i \in 1 .. 8 |-> 0],
      consumeTime                                               |-> [i \in 1 .. 8 |-> 0],
      eventId                                                   |-> [i \in 1 .. 8 |-> 0],
      bookIn                                                    |-> [i \in 1 .. 8 |-> 0],
      bookOutTime                                               |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                                             |-> [i \in 1 .. 8 |-> 0],
      darkExecutionInstruction                                  |-> [i \in 1 .. 1 |-> 0],
      emm                                                       |-> [i \in 1 .. 1 |-> 0],
      endClient                                                 |-> [i \in 1 .. 11 |-> 0],
      firmId                                                    |-> [i \in 1 .. 8 |-> 0],
      firmIdPublication                                         |-> [i \in 1 .. 1 |-> 0],
      oeSessionId                                               |-> [i \in 1 .. 8 |-> 0],
      oeginFromMember                                           |-> [i \in 1 .. 8 |-> 0],
      oegoutTimeToMe                                            |-> [i \in 1 .. 8 |-> 0],
      orderId                                                   |-> [i \in 1 .. 8 |-> 0],
      orderQty                                                  |-> [i \in 1 .. 8 |-> 0],
      orderSideOptional                                         |-> [i \in 1 .. 1 |-> 0],
      rfqStatus                                                 |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                                               |-> [i \in 1 .. 4 |-> 0],
      minOrderQty                                               |-> [i \in 1 .. 8 |-> 0],
      sequenceTime                                              |-> [i \in 1 .. 8 |-> 0],
      rfqType                                                   |-> [i \in 1 .. 1 |-> 0],
      dCQuoteRequestMessageNonModifiableShortCodesGroups        |-> ZeroDCQuoteRequestMessageNonModifiableShortCodesGroups,
      dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups |-> ZeroDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups,
      dCQuoteRequestMessageRfQOptionalFieldsGroups              |-> ZeroDCQuoteRequestMessageRfQOptionalFieldsGroups ]

(* Dc Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedDcQuoteRequestMessage ==
    { ZeroDcQuoteRequestMessage }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.eventId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.darkExecutionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.endClient = one] : one \in Sample(11) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.firmIdPublication = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.oeSessionId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.oeginFromMember = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.oegoutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.orderSideOptional = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.rfqStatus = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.minOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.sequenceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.rfqType = one] : one \in Sample(1) }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.dCQuoteRequestMessageNonModifiableShortCodesGroups = one] : one \in CheckedDCQuoteRequestMessageNonModifiableShortCodesGroups }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.dCQuoteRequestMessageShortCodesDetailsNonModifiableGroups = one] : one \in CheckedDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups }
        \cup { [ZeroDcQuoteRequestMessage EXCEPT !.dCQuoteRequestMessageRfQOptionalFieldsGroups = one] : one \in CheckedDCQuoteRequestMessageRfQOptionalFieldsGroups }

(***************************************************************************)
(* Dc Clear Book Message: 38 bytes                                         *)
(***************************************************************************)

DcClearBookMessage ==
    [ produceTime     : Sample(8),
      consumeTime     : Sample(8),
      sequenceTime    : Sample(8),
      bookInTime      : Sample(8),
      symbolIndex     : Sample(4),
      emm             : Sample(1),
      clearBookOrigin : Sample(1) ]

EncodeDcClearBookMessage(message) ==
    message.produceTime
        \o message.consumeTime
        \o message.sequenceTime
        \o message.bookInTime
        \o message.symbolIndex
        \o message.emm
        \o message.clearBookOrigin

DecodeDcClearBookMessage(bytes) ==
    LET produceTime == ReadBytes(bytes, 8) IN IF ~produceTime.ok THEN Fail ELSE
    LET consumeTime == ReadBytes(produceTime.rest, 8) IN IF ~consumeTime.ok THEN Fail ELSE
    LET sequenceTime == ReadBytes(consumeTime.rest, 8) IN IF ~sequenceTime.ok THEN Fail ELSE
    LET bookInTime == ReadBytes(sequenceTime.rest, 8) IN IF ~bookInTime.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(bookInTime.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET clearBookOrigin == ReadBytes(emm.rest, 1) IN IF ~clearBookOrigin.ok THEN Fail ELSE
    Ok([ produceTime     |-> produceTime.value,
         consumeTime     |-> consumeTime.value,
         sequenceTime    |-> sequenceTime.value,
         bookInTime      |-> bookInTime.value,
         symbolIndex     |-> symbolIndex.value,
         emm             |-> emm.value,
         clearBookOrigin |-> clearBookOrigin.value ], clearBookOrigin.rest)

ZeroDcClearBookMessage ==
    [ produceTime     |-> [i \in 1 .. 8 |-> 0],
      consumeTime     |-> [i \in 1 .. 8 |-> 0],
      sequenceTime    |-> [i \in 1 .. 8 |-> 0],
      bookInTime      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      emm             |-> [i \in 1 .. 1 |-> 0],
      clearBookOrigin |-> [i \in 1 .. 1 |-> 0] ]

(* Dc Clear Book Message at zero, then each field in turn at the values it is checked at *)
CheckedDcClearBookMessage ==
    { ZeroDcClearBookMessage }
        \cup { [ZeroDcClearBookMessage EXCEPT !.produceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcClearBookMessage EXCEPT !.consumeTime = one] : one \in Sample(8) }
        \cup { [ZeroDcClearBookMessage EXCEPT !.sequenceTime = one] : one \in Sample(8) }
        \cup { [ZeroDcClearBookMessage EXCEPT !.bookInTime = one] : one \in Sample(8) }
        \cup { [ZeroDcClearBookMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDcClearBookMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDcClearBookMessage EXCEPT !.clearBookOrigin = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

DcMarketStatusChangeMessageCode == 16001  \* 0x3e81
DcPriceUpdateMessageCode == 16003  \* 0x3e83
LongOrderMessageCode == 16006  \* 0x3e86
DcShortOrderRejectMessageCode == 16010  \* 0x3e8a
DcShortTradeCancellationMessageCode == 16016  \* 0x3e90
DcStaticCollarsMessageCode == 16018  \* 0x3e92
TradeBustNotificationMessageCode == 16021  \* 0x3e95
DcQuoteMessageCode == 16050  \* 0x3eb2
DcafqrfeMessageCode == 16051  \* 0x3eb3
DcDeclarationNewMessageCode == 16052  \* 0x3eb4
DcShortDeclarationRejectMessageCode == 16053  \* 0x3eb5
DcShortDeclarationCancelMessageCode == 16054  \* 0x3eb6
DcShortTradeDeclarationMessageCode == 16055  \* 0x3eb7
DcShortTradeDeclarationCancellationMessageCode == 16056  \* 0x3eb8
DcTradeBustDeclarationMessageCode == 16057  \* 0x3eb9
DcTradeMessageCode == 16058  \* 0x3eba
DcShortDeclarationFillMessageCode == 16059  \* 0x3ebb
DcQuoteRequestMessageCode == 16060  \* 0x3ebc
DcClearBookMessageCode == 16061  \* 0x3ebd

Payload ==
    [ tag : {DcMarketStatusChangeMessageCode}, body : DcMarketStatusChangeMessage ]
        \cup [ tag : {DcPriceUpdateMessageCode}, body : DcPriceUpdateMessage ]
        \cup [ tag : {LongOrderMessageCode}, body : LongOrderMessage ]
        \cup [ tag : {DcShortOrderRejectMessageCode}, body : DcShortOrderRejectMessage ]
        \cup [ tag : {DcShortTradeCancellationMessageCode}, body : DcShortTradeCancellationMessage ]
        \cup [ tag : {DcStaticCollarsMessageCode}, body : DcStaticCollarsMessage ]
        \cup [ tag : {TradeBustNotificationMessageCode}, body : TradeBustNotificationMessage ]
        \cup [ tag : {DcQuoteMessageCode}, body : DcQuoteMessage ]
        \cup [ tag : {DcafqrfeMessageCode}, body : DcafqrfeMessage ]
        \cup [ tag : {DcDeclarationNewMessageCode}, body : DcDeclarationNewMessage ]
        \cup [ tag : {DcShortDeclarationRejectMessageCode}, body : DcShortDeclarationRejectMessage ]
        \cup [ tag : {DcShortDeclarationCancelMessageCode}, body : DcShortDeclarationCancelMessage ]
        \cup [ tag : {DcShortTradeDeclarationMessageCode}, body : DcShortTradeDeclarationMessage ]
        \cup [ tag : {DcShortTradeDeclarationCancellationMessageCode}, body : DcShortTradeDeclarationCancellationMessage ]
        \cup [ tag : {DcTradeBustDeclarationMessageCode}, body : DcTradeBustDeclarationMessage ]
        \cup [ tag : {DcTradeMessageCode}, body : DcTradeMessage ]
        \cup [ tag : {DcShortDeclarationFillMessageCode}, body : DcShortDeclarationFillMessage ]
        \cup [ tag : {DcQuoteRequestMessageCode}, body : DcQuoteRequestMessage ]
        \cup [ tag : {DcClearBookMessageCode}, body : DcClearBookMessage ]

EncodePayload(message) ==
    CASE message.tag = DcMarketStatusChangeMessageCode -> EncodeDcMarketStatusChangeMessage(message.body)
      [] message.tag = DcPriceUpdateMessageCode -> EncodeDcPriceUpdateMessage(message.body)
      [] message.tag = LongOrderMessageCode -> EncodeLongOrderMessage(message.body)
      [] message.tag = DcShortOrderRejectMessageCode -> EncodeDcShortOrderRejectMessage(message.body)
      [] message.tag = DcShortTradeCancellationMessageCode -> EncodeDcShortTradeCancellationMessage(message.body)
      [] message.tag = DcStaticCollarsMessageCode -> EncodeDcStaticCollarsMessage(message.body)
      [] message.tag = TradeBustNotificationMessageCode -> EncodeTradeBustNotificationMessage(message.body)
      [] message.tag = DcQuoteMessageCode -> EncodeDcQuoteMessage(message.body)
      [] message.tag = DcafqrfeMessageCode -> EncodeDcafqrfeMessage(message.body)
      [] message.tag = DcDeclarationNewMessageCode -> EncodeDcDeclarationNewMessage(message.body)
      [] message.tag = DcShortDeclarationRejectMessageCode -> EncodeDcShortDeclarationRejectMessage(message.body)
      [] message.tag = DcShortDeclarationCancelMessageCode -> EncodeDcShortDeclarationCancelMessage(message.body)
      [] message.tag = DcShortTradeDeclarationMessageCode -> EncodeDcShortTradeDeclarationMessage(message.body)
      [] message.tag = DcShortTradeDeclarationCancellationMessageCode -> EncodeDcShortTradeDeclarationCancellationMessage(message.body)
      [] message.tag = DcTradeBustDeclarationMessageCode -> EncodeDcTradeBustDeclarationMessage(message.body)
      [] message.tag = DcTradeMessageCode -> EncodeDcTradeMessage(message.body)
      [] message.tag = DcShortDeclarationFillMessageCode -> EncodeDcShortDeclarationFillMessage(message.body)
      [] message.tag = DcQuoteRequestMessageCode -> EncodeDcQuoteRequestMessage(message.body)
      [] message.tag = DcClearBookMessageCode -> EncodeDcClearBookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = DcMarketStatusChangeMessageCode -> DecodeDcMarketStatusChangeMessage(bytes)
              [] tag = DcPriceUpdateMessageCode -> DecodeDcPriceUpdateMessage(bytes)
              [] tag = LongOrderMessageCode -> DecodeLongOrderMessage(bytes)
              [] tag = DcShortOrderRejectMessageCode -> DecodeDcShortOrderRejectMessage(bytes)
              [] tag = DcShortTradeCancellationMessageCode -> DecodeDcShortTradeCancellationMessage(bytes)
              [] tag = DcStaticCollarsMessageCode -> DecodeDcStaticCollarsMessage(bytes)
              [] tag = TradeBustNotificationMessageCode -> DecodeTradeBustNotificationMessage(bytes)
              [] tag = DcQuoteMessageCode -> DecodeDcQuoteMessage(bytes)
              [] tag = DcafqrfeMessageCode -> DecodeDcafqrfeMessage(bytes)
              [] tag = DcDeclarationNewMessageCode -> DecodeDcDeclarationNewMessage(bytes)
              [] tag = DcShortDeclarationRejectMessageCode -> DecodeDcShortDeclarationRejectMessage(bytes)
              [] tag = DcShortDeclarationCancelMessageCode -> DecodeDcShortDeclarationCancelMessage(bytes)
              [] tag = DcShortTradeDeclarationMessageCode -> DecodeDcShortTradeDeclarationMessage(bytes)
              [] tag = DcShortTradeDeclarationCancellationMessageCode -> DecodeDcShortTradeDeclarationCancellationMessage(bytes)
              [] tag = DcTradeBustDeclarationMessageCode -> DecodeDcTradeBustDeclarationMessage(bytes)
              [] tag = DcTradeMessageCode -> DecodeDcTradeMessage(bytes)
              [] tag = DcShortDeclarationFillMessageCode -> DecodeDcShortDeclarationFillMessage(bytes)
              [] tag = DcQuoteRequestMessageCode -> DecodeDcQuoteRequestMessage(bytes)
              [] tag = DcClearBookMessageCode -> DecodeDcClearBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> DcMarketStatusChangeMessageCode, body |-> ZeroDcMarketStatusChangeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> DcMarketStatusChangeMessageCode, body |-> one] : one \in CheckedDcMarketStatusChangeMessage }
        \cup { [tag |-> DcPriceUpdateMessageCode, body |-> one] : one \in CheckedDcPriceUpdateMessage }
        \cup { [tag |-> LongOrderMessageCode, body |-> one] : one \in CheckedLongOrderMessage }
        \cup { [tag |-> DcShortOrderRejectMessageCode, body |-> one] : one \in CheckedDcShortOrderRejectMessage }
        \cup { [tag |-> DcShortTradeCancellationMessageCode, body |-> one] : one \in CheckedDcShortTradeCancellationMessage }
        \cup { [tag |-> DcStaticCollarsMessageCode, body |-> one] : one \in CheckedDcStaticCollarsMessage }
        \cup { [tag |-> TradeBustNotificationMessageCode, body |-> one] : one \in CheckedTradeBustNotificationMessage }
        \cup { [tag |-> DcQuoteMessageCode, body |-> one] : one \in CheckedDcQuoteMessage }
        \cup { [tag |-> DcafqrfeMessageCode, body |-> one] : one \in CheckedDcafqrfeMessage }
        \cup { [tag |-> DcDeclarationNewMessageCode, body |-> one] : one \in CheckedDcDeclarationNewMessage }
        \cup { [tag |-> DcShortDeclarationRejectMessageCode, body |-> one] : one \in CheckedDcShortDeclarationRejectMessage }
        \cup { [tag |-> DcShortDeclarationCancelMessageCode, body |-> one] : one \in CheckedDcShortDeclarationCancelMessage }
        \cup { [tag |-> DcShortTradeDeclarationMessageCode, body |-> one] : one \in CheckedDcShortTradeDeclarationMessage }
        \cup { [tag |-> DcShortTradeDeclarationCancellationMessageCode, body |-> one] : one \in CheckedDcShortTradeDeclarationCancellationMessage }
        \cup { [tag |-> DcTradeBustDeclarationMessageCode, body |-> one] : one \in CheckedDcTradeBustDeclarationMessage }
        \cup { [tag |-> DcTradeMessageCode, body |-> one] : one \in CheckedDcTradeMessage }
        \cup { [tag |-> DcShortDeclarationFillMessageCode, body |-> one] : one \in CheckedDcShortDeclarationFillMessage }
        \cup { [tag |-> DcQuoteRequestMessageCode, body |-> one] : one \in CheckedDcQuoteRequestMessage }
        \cup { [tag |-> DcClearBookMessageCode, body |-> one] : one \in CheckedDcClearBookMessage }

(***************************************************************************)
(* Message, framed by Frame                                                *)
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

(* Frame counts the bytes it frames, so it is written from them *)
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> DcMarketStatusChangeMessageCode, body |-> ZeroDcMarketStatusChangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcPriceUpdateMessageCode, body |-> ZeroDcPriceUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LongOrderMessageCode, body |-> ZeroLongOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcShortOrderRejectMessageCode, body |-> ZeroDcShortOrderRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcShortTradeCancellationMessageCode, body |-> ZeroDcShortTradeCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcStaticCollarsMessageCode, body |-> ZeroDcStaticCollarsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustNotificationMessageCode, body |-> ZeroTradeBustNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcQuoteMessageCode, body |-> ZeroDcQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcafqrfeMessageCode, body |-> ZeroDcafqrfeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcDeclarationNewMessageCode, body |-> ZeroDcDeclarationNewMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcShortDeclarationRejectMessageCode, body |-> ZeroDcShortDeclarationRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcShortDeclarationCancelMessageCode, body |-> ZeroDcShortDeclarationCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcShortTradeDeclarationMessageCode, body |-> ZeroDcShortTradeDeclarationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcShortTradeDeclarationCancellationMessageCode, body |-> ZeroDcShortTradeDeclarationCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcTradeBustDeclarationMessageCode, body |-> ZeroDcTradeBustDeclarationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcTradeMessageCode, body |-> ZeroDcTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcShortDeclarationFillMessageCode, body |-> ZeroDcShortDeclarationFillMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcQuoteRequestMessageCode, body |-> ZeroDcQuoteRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DcClearBookMessageCode, body |-> ZeroDcClearBookMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Dc Market Status Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcMarketStatusChangeMessage ==
    \A message \in CheckedDcMarketStatusChangeMessage :
        LET read == DecodeDcMarketStatusChangeMessage(EncodeDcMarketStatusChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcPriceUpdateMessage ==
    \A message \in CheckedDcPriceUpdateMessage :
        LET read == DecodeDcPriceUpdateMessage(EncodeDcPriceUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Free Text Section Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderFreeTextSectionGroup ==
    \A message \in CheckedLongOrderFreeTextSectionGroup :
        LET read == DecodeLongOrderFreeTextSectionGroup(EncodeLongOrderFreeTextSectionGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Free Text Section Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderFreeTextSectionGroups ==
    \A message \in CheckedLongOrderFreeTextSectionGroups :
        LET read == DecodeLongOrderFreeTextSectionGroups(EncodeLongOrderFreeTextSectionGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Optional Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderOptionalFieldsGroup ==
    \A message \in CheckedLongOrderOptionalFieldsGroup :
        LET read == DecodeLongOrderOptionalFieldsGroup(EncodeLongOrderOptionalFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Optional Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderOptionalFieldsGroups ==
    \A message \in CheckedLongOrderOptionalFieldsGroups :
        LET read == DecodeLongOrderOptionalFieldsGroups(EncodeLongOrderOptionalFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Clearing Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderClearingFieldsGroup ==
    \A message \in CheckedLongOrderClearingFieldsGroup :
        LET read == DecodeLongOrderClearingFieldsGroup(EncodeLongOrderClearingFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Clearing Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderClearingFieldsGroups ==
    \A message \in CheckedLongOrderClearingFieldsGroups :
        LET read == DecodeLongOrderClearingFieldsGroups(EncodeLongOrderClearingFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Non Modifiable Opt Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderNonModifiableOptFieldsGroup ==
    \A message \in CheckedLongOrderNonModifiableOptFieldsGroup :
        LET read == DecodeLongOrderNonModifiableOptFieldsGroup(EncodeLongOrderNonModifiableOptFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Non Modifiable Opt Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderNonModifiableOptFieldsGroups ==
    \A message \in CheckedLongOrderNonModifiableOptFieldsGroups :
        LET read == DecodeLongOrderNonModifiableOptFieldsGroups(EncodeLongOrderNonModifiableOptFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Non Modifiable Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderNonModifiableShortCodesGroup ==
    \A message \in CheckedLongOrderNonModifiableShortCodesGroup :
        LET read == DecodeLongOrderNonModifiableShortCodesGroup(EncodeLongOrderNonModifiableShortCodesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Non Modifiable Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderNonModifiableShortCodesGroups ==
    \A message \in CheckedLongOrderNonModifiableShortCodesGroups :
        LET read == DecodeLongOrderNonModifiableShortCodesGroups(EncodeLongOrderNonModifiableShortCodesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Modifiable Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderModifiableShortCodesGroup ==
    \A message \in CheckedLongOrderModifiableShortCodesGroup :
        LET read == DecodeLongOrderModifiableShortCodesGroup(EncodeLongOrderModifiableShortCodesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Modifiable Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderModifiableShortCodesGroups ==
    \A message \in CheckedLongOrderModifiableShortCodesGroups :
        LET read == DecodeLongOrderModifiableShortCodesGroups(EncodeLongOrderModifiableShortCodesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Commercial Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderCommercialFieldsGroup ==
    \A message \in CheckedLongOrderCommercialFieldsGroup :
        LET read == DecodeLongOrderCommercialFieldsGroup(EncodeLongOrderCommercialFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Commercial Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderCommercialFieldsGroups ==
    \A message \in CheckedLongOrderCommercialFieldsGroups :
        LET read == DecodeLongOrderCommercialFieldsGroups(EncodeLongOrderCommercialFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Modifiable Commercial Investor Field Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderModifiableCommercialInvestorFieldGroup ==
    \A message \in CheckedLongOrderModifiableCommercialInvestorFieldGroup :
        LET read == DecodeLongOrderModifiableCommercialInvestorFieldGroup(EncodeLongOrderModifiableCommercialInvestorFieldGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Modifiable Commercial Investor Field Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderModifiableCommercialInvestorFieldGroups ==
    \A message \in CheckedLongOrderModifiableCommercialInvestorFieldGroups :
        LET read == DecodeLongOrderModifiableCommercialInvestorFieldGroups(EncodeLongOrderModifiableCommercialInvestorFieldGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Non Modifiable Commercial Investor Field Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderNonModifiableCommercialInvestorFieldGroup ==
    \A message \in CheckedLongOrderNonModifiableCommercialInvestorFieldGroup :
        LET read == DecodeLongOrderNonModifiableCommercialInvestorFieldGroup(EncodeLongOrderNonModifiableCommercialInvestorFieldGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Non Modifiable Commercial Investor Field Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderNonModifiableCommercialInvestorFieldGroups ==
    \A message \in CheckedLongOrderNonModifiableCommercialInvestorFieldGroups :
        LET read == DecodeLongOrderNonModifiableCommercialInvestorFieldGroups(EncodeLongOrderNonModifiableCommercialInvestorFieldGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Extended Clearing Account Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderExtendedClearingAccountGroup ==
    \A message \in CheckedLongOrderExtendedClearingAccountGroup :
        LET read == DecodeLongOrderExtendedClearingAccountGroup(EncodeLongOrderExtendedClearingAccountGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Extended Clearing Account Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderExtendedClearingAccountGroups ==
    \A message \in CheckedLongOrderExtendedClearingAccountGroups :
        LET read == DecodeLongOrderExtendedClearingAccountGroups(EncodeLongOrderExtendedClearingAccountGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Strategy Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderStrategyFieldsGroup ==
    \A message \in CheckedLongOrderStrategyFieldsGroup :
        LET read == DecodeLongOrderStrategyFieldsGroup(EncodeLongOrderStrategyFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Strategy Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderStrategyFieldsGroups ==
    \A message \in CheckedLongOrderStrategyFieldsGroups :
        LET read == DecodeLongOrderStrategyFieldsGroups(EncodeLongOrderStrategyFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Optional Fields Derivatives Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderOptionalFieldsDerivativesGroup ==
    \A message \in CheckedLongOrderOptionalFieldsDerivativesGroup :
        LET read == DecodeLongOrderOptionalFieldsDerivativesGroup(EncodeLongOrderOptionalFieldsDerivativesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Optional Fields Derivatives Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderOptionalFieldsDerivativesGroups ==
    \A message \in CheckedLongOrderOptionalFieldsDerivativesGroups :
        LET read == DecodeLongOrderOptionalFieldsDerivativesGroups(EncodeLongOrderOptionalFieldsDerivativesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Additional Infos Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderAdditionalInfosGroup ==
    \A message \in CheckedLongOrderAdditionalInfosGroup :
        LET read == DecodeLongOrderAdditionalInfosGroup(EncodeLongOrderAdditionalInfosGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Additional Infos Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderAdditionalInfosGroups ==
    \A message \in CheckedLongOrderAdditionalInfosGroups :
        LET read == DecodeLongOrderAdditionalInfosGroups(EncodeLongOrderAdditionalInfosGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Short Codes Details Non Modifiable Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderShortCodesDetailsNonModifiableGroup ==
    \A message \in CheckedLongOrderShortCodesDetailsNonModifiableGroup :
        LET read == DecodeLongOrderShortCodesDetailsNonModifiableGroup(EncodeLongOrderShortCodesDetailsNonModifiableGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Short Codes Details Non Modifiable Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderShortCodesDetailsNonModifiableGroups ==
    \A message \in CheckedLongOrderShortCodesDetailsNonModifiableGroups :
        LET read == DecodeLongOrderShortCodesDetailsNonModifiableGroups(EncodeLongOrderShortCodesDetailsNonModifiableGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Short Codes Details Modifiable Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderShortCodesDetailsModifiableGroup ==
    \A message \in CheckedLongOrderShortCodesDetailsModifiableGroup :
        LET read == DecodeLongOrderShortCodesDetailsModifiableGroup(EncodeLongOrderShortCodesDetailsModifiableGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Short Codes Details Modifiable Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderShortCodesDetailsModifiableGroups ==
    \A message \in CheckedLongOrderShortCodesDetailsModifiableGroups :
        LET read == DecodeLongOrderShortCodesDetailsModifiableGroups(EncodeLongOrderShortCodesDetailsModifiableGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLongOrderMessage ==
    \A message \in CheckedLongOrderMessage :
        LET read == DecodeLongOrderMessage(EncodeLongOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Short Order Reject Message Modifiable Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCShortOrderRejectMessageModifiableShortCodesGroup ==
    \A message \in CheckedDCShortOrderRejectMessageModifiableShortCodesGroup :
        LET read == DecodeDCShortOrderRejectMessageModifiableShortCodesGroup(EncodeDCShortOrderRejectMessageModifiableShortCodesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Short Order Reject Message Modifiable Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCShortOrderRejectMessageModifiableShortCodesGroups ==
    \A message \in CheckedDCShortOrderRejectMessageModifiableShortCodesGroups :
        LET read == DecodeDCShortOrderRejectMessageModifiableShortCodesGroups(EncodeDCShortOrderRejectMessageModifiableShortCodesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Short Order Reject Message Short Codes Details Modifiable Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCShortOrderRejectMessageShortCodesDetailsModifiableGroup ==
    \A message \in CheckedDCShortOrderRejectMessageShortCodesDetailsModifiableGroup :
        LET read == DecodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroup(EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Short Order Reject Message Short Codes Details Modifiable Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCShortOrderRejectMessageShortCodesDetailsModifiableGroups ==
    \A message \in CheckedDCShortOrderRejectMessageShortCodesDetailsModifiableGroups :
        LET read == DecodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroups(EncodeDCShortOrderRejectMessageShortCodesDetailsModifiableGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Short Order Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcShortOrderRejectMessage ==
    \A message \in CheckedDcShortOrderRejectMessage :
        LET read == DecodeDcShortOrderRejectMessage(EncodeDcShortOrderRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Short Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcShortTradeCancellationMessage ==
    \A message \in CheckedDcShortTradeCancellationMessage :
        LET read == DecodeDcShortTradeCancellationMessage(EncodeDcShortTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Static Collars Message Static Collarsrep Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCStaticCollarsMessageStaticCollarsrepGroup ==
    \A message \in CheckedDCStaticCollarsMessageStaticCollarsrepGroup :
        LET read == DecodeDCStaticCollarsMessageStaticCollarsrepGroup(EncodeDCStaticCollarsMessageStaticCollarsrepGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Static Collars Message Static Collarsrep Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCStaticCollarsMessageStaticCollarsrepGroups ==
    \A message \in CheckedDCStaticCollarsMessageStaticCollarsrepGroups :
        LET read == DecodeDCStaticCollarsMessageStaticCollarsrepGroups(EncodeDCStaticCollarsMessageStaticCollarsrepGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Static Collars Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcStaticCollarsMessage ==
    \A message \in CheckedDcStaticCollarsMessage :
        LET read == DecodeDcStaticCollarsMessage(EncodeDcStaticCollarsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Notification Short Codes Details Non Modifiable Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustNotificationShortCodesDetailsNonModifiableGroup ==
    \A message \in CheckedTradeBustNotificationShortCodesDetailsNonModifiableGroup :
        LET read == DecodeTradeBustNotificationShortCodesDetailsNonModifiableGroup(EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Notification Short Codes Details Non Modifiable Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustNotificationShortCodesDetailsNonModifiableGroups ==
    \A message \in CheckedTradeBustNotificationShortCodesDetailsNonModifiableGroups :
        LET read == DecodeTradeBustNotificationShortCodesDetailsNonModifiableGroups(EncodeTradeBustNotificationShortCodesDetailsNonModifiableGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Notification Short Codes Details Modifiable Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustNotificationShortCodesDetailsModifiableGroup ==
    \A message \in CheckedTradeBustNotificationShortCodesDetailsModifiableGroup :
        LET read == DecodeTradeBustNotificationShortCodesDetailsModifiableGroup(EncodeTradeBustNotificationShortCodesDetailsModifiableGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Notification Short Codes Details Modifiable Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustNotificationShortCodesDetailsModifiableGroups ==
    \A message \in CheckedTradeBustNotificationShortCodesDetailsModifiableGroups :
        LET read == DecodeTradeBustNotificationShortCodesDetailsModifiableGroups(EncodeTradeBustNotificationShortCodesDetailsModifiableGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustNotificationMessage ==
    \A message \in CheckedTradeBustNotificationMessage :
        LET read == DecodeTradeBustNotificationMessage(EncodeTradeBustNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Bid Quoterep Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageBidQuoterepGroup ==
    \A message \in CheckedDCQuoteMessageBidQuoterepGroup :
        LET read == DecodeDCQuoteMessageBidQuoterepGroup(EncodeDCQuoteMessageBidQuoterepGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Bid Quoterep Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageBidQuoterepGroups ==
    \A message \in CheckedDCQuoteMessageBidQuoterepGroups :
        LET read == DecodeDCQuoteMessageBidQuoterepGroups(EncodeDCQuoteMessageBidQuoterepGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Offer Quoterep Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageOfferQuoterepGroup ==
    \A message \in CheckedDCQuoteMessageOfferQuoterepGroup :
        LET read == DecodeDCQuoteMessageOfferQuoterepGroup(EncodeDCQuoteMessageOfferQuoterepGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Offer Quoterep Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageOfferQuoterepGroups ==
    \A message \in CheckedDCQuoteMessageOfferQuoterepGroups :
        LET read == DecodeDCQuoteMessageOfferQuoterepGroups(EncodeDCQuoteMessageOfferQuoterepGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Clearing Dataset Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageClearingDatasetGroup ==
    \A message \in CheckedDCQuoteMessageClearingDatasetGroup :
        LET read == DecodeDCQuoteMessageClearingDatasetGroup(EncodeDCQuoteMessageClearingDatasetGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Clearing Dataset Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageClearingDatasetGroups ==
    \A message \in CheckedDCQuoteMessageClearingDatasetGroups :
        LET read == DecodeDCQuoteMessageClearingDatasetGroups(EncodeDCQuoteMessageClearingDatasetGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Non Modifiable Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageNonModifiableShortCodesGroup ==
    \A message \in CheckedDCQuoteMessageNonModifiableShortCodesGroup :
        LET read == DecodeDCQuoteMessageNonModifiableShortCodesGroup(EncodeDCQuoteMessageNonModifiableShortCodesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Non Modifiable Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageNonModifiableShortCodesGroups ==
    \A message \in CheckedDCQuoteMessageNonModifiableShortCodesGroups :
        LET read == DecodeDCQuoteMessageNonModifiableShortCodesGroups(EncodeDCQuoteMessageNonModifiableShortCodesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Modifiable Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageModifiableShortCodesGroup ==
    \A message \in CheckedDCQuoteMessageModifiableShortCodesGroup :
        LET read == DecodeDCQuoteMessageModifiableShortCodesGroup(EncodeDCQuoteMessageModifiableShortCodesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Message Modifiable Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteMessageModifiableShortCodesGroups ==
    \A message \in CheckedDCQuoteMessageModifiableShortCodesGroups :
        LET read == DecodeDCQuoteMessageModifiableShortCodesGroups(EncodeDCQuoteMessageModifiableShortCodesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcQuoteMessage ==
    \A message \in CheckedDcQuoteMessage :
        LET read == DecodeDcQuoteMessage(EncodeDcQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dcafqrfe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcafqrfeMessage ==
    \A message \in CheckedDcafqrfeMessage :
        LET read == DecodeDcafqrfeMessage(EncodeDcafqrfeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Declaration New Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcDeclarationNewMessage ==
    \A message \in CheckedDcDeclarationNewMessage :
        LET read == DecodeDcDeclarationNewMessage(EncodeDcDeclarationNewMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Short Declaration Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcShortDeclarationRejectMessage ==
    \A message \in CheckedDcShortDeclarationRejectMessage :
        LET read == DecodeDcShortDeclarationRejectMessage(EncodeDcShortDeclarationRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Short Declaration Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcShortDeclarationCancelMessage ==
    \A message \in CheckedDcShortDeclarationCancelMessage :
        LET read == DecodeDcShortDeclarationCancelMessage(EncodeDcShortDeclarationCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Short Trade Declaration Message Short Trade Declarations Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCShortTradeDeclarationMessageShortTradeDeclarationsGroup ==
    \A message \in CheckedDCShortTradeDeclarationMessageShortTradeDeclarationsGroup :
        LET read == DecodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroup(EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Short Trade Declaration Message Short Trade Declarations Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCShortTradeDeclarationMessageShortTradeDeclarationsGroups ==
    \A message \in CheckedDCShortTradeDeclarationMessageShortTradeDeclarationsGroups :
        LET read == DecodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroups(EncodeDCShortTradeDeclarationMessageShortTradeDeclarationsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Short Trade Declaration Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcShortTradeDeclarationMessage ==
    \A message \in CheckedDcShortTradeDeclarationMessage :
        LET read == DecodeDcShortTradeDeclarationMessage(EncodeDcShortTradeDeclarationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Short Trade Declaration Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcShortTradeDeclarationCancellationMessage ==
    \A message \in CheckedDcShortTradeDeclarationCancellationMessage :
        LET read == DecodeDcShortTradeDeclarationCancellationMessage(EncodeDcShortTradeDeclarationCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Trade Bust Declaration Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcTradeBustDeclarationMessage ==
    \A message \in CheckedDcTradeBustDeclarationMessage :
        LET read == DecodeDcTradeBustDeclarationMessage(EncodeDcTradeBustDeclarationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Trade Message Matched Orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCTradeMessageMatchedOrdersGroup ==
    \A message \in CheckedDCTradeMessageMatchedOrdersGroup :
        LET read == DecodeDCTradeMessageMatchedOrdersGroup(EncodeDCTradeMessageMatchedOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Trade Message Matched Orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCTradeMessageMatchedOrdersGroups ==
    \A message \in CheckedDCTradeMessageMatchedOrdersGroups :
        LET read == DecodeDCTradeMessageMatchedOrdersGroups(EncodeDCTradeMessageMatchedOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Trade Message Matched Declarations Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCTradeMessageMatchedDeclarationsGroup ==
    \A message \in CheckedDCTradeMessageMatchedDeclarationsGroup :
        LET read == DecodeDCTradeMessageMatchedDeclarationsGroup(EncodeDCTradeMessageMatchedDeclarationsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Trade Message Matched Declarations Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCTradeMessageMatchedDeclarationsGroups ==
    \A message \in CheckedDCTradeMessageMatchedDeclarationsGroups :
        LET read == DecodeDCTradeMessageMatchedDeclarationsGroups(EncodeDCTradeMessageMatchedDeclarationsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcTradeMessage ==
    \A message \in CheckedDcTradeMessage :
        LET read == DecodeDcTradeMessage(EncodeDcTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Short Declaration Fill Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcShortDeclarationFillMessage ==
    \A message \in CheckedDcShortDeclarationFillMessage :
        LET read == DecodeDcShortDeclarationFillMessage(EncodeDcShortDeclarationFillMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Request Message Non Modifiable Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteRequestMessageNonModifiableShortCodesGroup ==
    \A message \in CheckedDCQuoteRequestMessageNonModifiableShortCodesGroup :
        LET read == DecodeDCQuoteRequestMessageNonModifiableShortCodesGroup(EncodeDCQuoteRequestMessageNonModifiableShortCodesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Request Message Non Modifiable Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteRequestMessageNonModifiableShortCodesGroups ==
    \A message \in CheckedDCQuoteRequestMessageNonModifiableShortCodesGroups :
        LET read == DecodeDCQuoteRequestMessageNonModifiableShortCodesGroups(EncodeDCQuoteRequestMessageNonModifiableShortCodesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Request Message Short Codes Details Non Modifiable Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup ==
    \A message \in CheckedDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup :
        LET read == DecodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup(EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Request Message Short Codes Details Non Modifiable Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups ==
    \A message \in CheckedDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups :
        LET read == DecodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups(EncodeDCQuoteRequestMessageShortCodesDetailsNonModifiableGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Request Message Rf Q Optional Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteRequestMessageRfQOptionalFieldsGroup ==
    \A message \in CheckedDCQuoteRequestMessageRfQOptionalFieldsGroup :
        LET read == DecodeDCQuoteRequestMessageRfQOptionalFieldsGroup(EncodeDCQuoteRequestMessageRfQOptionalFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D C Quote Request Message Rf Q Optional Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDCQuoteRequestMessageRfQOptionalFieldsGroups ==
    \A message \in CheckedDCQuoteRequestMessageRfQOptionalFieldsGroups :
        LET read == DecodeDCQuoteRequestMessageRfQOptionalFieldsGroups(EncodeDCQuoteRequestMessageRfQOptionalFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcQuoteRequestMessage ==
    \A message \in CheckedDcQuoteRequestMessage :
        LET read == DecodeDcQuoteRequestMessage(EncodeDcQuoteRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dc Clear Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDcClearBookMessage ==
    \A message \in CheckedDcClearBookMessage :
        LET read == DecodeDcClearBookMessage(EncodeDcClearBookMessage(message))
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

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Frame is written from the bytes it frames *)
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
