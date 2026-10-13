-------------- MODULE LmeSelect_TradeStatisticsSnapshot_v4_18 --------------
(***************************************************************************)
(* The London Metal Exchange LMEsource TradeStatistics Refresh v4.18       *)
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
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Statistics Intraday Message: 42 bytes                             *)
(***************************************************************************)

TradeStatisticsIntradayMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      tradableInstrumentId : Sample(8),
      openPrice            : Sample(8),
      tradeHigh            : Sample(8),
      tradeLow             : Sample(8) ]

EncodeTradeStatisticsIntradayMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.openPrice
        \o message.tradeHigh
        \o message.tradeLow

DecodeTradeStatisticsIntradayMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET openPrice == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET tradeHigh == ReadBytes(openPrice.rest, 8) IN IF ~tradeHigh.ok THEN Fail ELSE
    LET tradeLow == ReadBytes(tradeHigh.rest, 8) IN IF ~tradeLow.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         openPrice            |-> openPrice.value,
         tradeHigh            |-> tradeHigh.value,
         tradeLow             |-> tradeLow.value ], tradeLow.rest)

ZeroTradeStatisticsIntradayMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      openPrice            |-> [i \in 1 .. 8 |-> 0],
      tradeHigh            |-> [i \in 1 .. 8 |-> 0],
      tradeLow             |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Statistics Intraday Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeStatisticsIntradayMessage ==
    { ZeroTradeStatisticsIntradayMessage }
        \cup { [ZeroTradeStatisticsIntradayMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroTradeStatisticsIntradayMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsIntradayMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsIntradayMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsIntradayMessage EXCEPT !.tradeHigh = one] : one \in Sample(8) }
        \cup { [ZeroTradeStatisticsIntradayMessage EXCEPT !.tradeLow = one] : one \in Sample(8) }

(***************************************************************************)
(* Refresh Complete Message: 4 bytes                                       *)
(***************************************************************************)

RefreshCompleteMessage ==
    [ lastSeqNum : Sample(4) ]

EncodeRefreshCompleteMessage(message) ==
    message.lastSeqNum

DecodeRefreshCompleteMessage(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroRefreshCompleteMessage ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Refresh Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshCompleteMessage ==
    { ZeroRefreshCompleteMessage }
        \cup { [ZeroRefreshCompleteMessage EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
TradeStatisticsIntradayMessageCode == 352  \* 0x160
RefreshCompleteMessageCode == 203  \* 0xcb

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {TradeStatisticsIntradayMessageCode}, body : TradeStatisticsIntradayMessage ]
        \cup [ tag : {RefreshCompleteMessageCode}, body : RefreshCompleteMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = TradeStatisticsIntradayMessageCode -> EncodeTradeStatisticsIntradayMessage(message.body)
      [] message.tag = RefreshCompleteMessageCode -> EncodeRefreshCompleteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = TradeStatisticsIntradayMessageCode -> DecodeTradeStatisticsIntradayMessage(bytes)
              [] tag = RefreshCompleteMessageCode -> DecodeRefreshCompleteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> TradeStatisticsIntradayMessageCode, body |-> one] : one \in CheckedTradeStatisticsIntradayMessage }
        \cup { [tag |-> RefreshCompleteMessageCode, body |-> one] : one \in CheckedRefreshCompleteMessage }

(***************************************************************************)
(* Messages                                                                *)
(***************************************************************************)

Messages ==
    [ msgSize : 0 .. 255,
      payload : Payload ]

EncodeMessages(message) ==
    EncodeUIntLE(message.msgSize, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

DecodeMessages(bytes) ==
    LET msgSize == ReadUIntLE(bytes, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgType == ReadUIntLE(msgSize.rest, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSize |-> msgSize.value,
         payload |-> payload.value ], payload.rest)

ZeroMessages ==
    [ msgSize |-> 0,
      payload |-> ZeroPayload ]

(* Messages at zero, then each field in turn at the values it is checked at *)
CheckedMessages ==
    { ZeroMessages }
        \cup { [ZeroMessages EXCEPT !.msgSize = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessages EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Messages, written one after another *)
RECURSIVE EncodeMessagesList(_)
EncodeMessagesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessages(Head(messages)) \o EncodeMessagesList(Tail(messages))

(* As many Messages as the field that counts them says *)
RECURSIVE ReadMessagesList(_, _)
ReadMessagesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessages(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessagesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Messages of each kind, for the lists that carry them *)
OneMessages ==
    { [ZeroMessages EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> TradeStatisticsIntradayMessageCode, body |-> ZeroTradeStatisticsIntradayMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> RefreshCompleteMessageCode, body |-> ZeroRefreshCompleteMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      messages : SampleLists(OneMessages) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.messages), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessagesList(message.messages)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET messages == ReadMessagesList(sendTime.rest, msgCount.value) IN IF ~messages.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         messages |-> messages.value ], messages.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      messages |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messages = one] : one \in SampleLists(OneMessages) }

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

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Statistics Intraday Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeStatisticsIntradayMessage ==
    \A message \in CheckedTradeStatisticsIntradayMessage :
        LET read == DecodeTradeStatisticsIntradayMessage(EncodeTradeStatisticsIntradayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshCompleteMessage ==
    \A message \in CheckedRefreshCompleteMessage :
        LET read == DecodeRefreshCompleteMessage(EncodeRefreshCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Messages decodes back to what was encoded, and leaves nothing over *)
RoundTripMessages ==
    \A message \in CheckedMessages :
        LET read == DecodeMessages(EncodeMessages(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
