----------------------- MODULE NsmEquities_Nois_v2_2 -----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Net Order Imbalance Snapshot v2.2                              *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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

(* The integer a rule depends on *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* System Event Message: 1 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET eventCode == ReadBytes(bytes, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory: 20 bytes                                               *)
(***************************************************************************)

StockDirectory ==
    [ symbol              : Sample(8),
      marketCategory      : Sample(1),
      rfu                 : Sample(1),
      roundLotSize        : Sample(6),
      roundLotsOnly       : Sample(1),
      issueClassification : Sample(1),
      issueSubType        : Sample(2) ]

EncodeStockDirectory(message) ==
    message.symbol
        \o message.marketCategory
        \o message.rfu
        \o message.roundLotSize
        \o message.roundLotsOnly
        \o message.issueClassification
        \o message.issueSubType

DecodeStockDirectory(bytes) ==
    LET symbol == ReadBytes(bytes, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(symbol.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET rfu == ReadBytes(marketCategory.rest, 1) IN IF ~rfu.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(rfu.rest, 6) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    LET issueClassification == ReadBytes(roundLotsOnly.rest, 1) IN IF ~issueClassification.ok THEN Fail ELSE
    LET issueSubType == ReadBytes(issueClassification.rest, 2) IN IF ~issueSubType.ok THEN Fail ELSE
    Ok([ symbol              |-> symbol.value,
         marketCategory      |-> marketCategory.value,
         rfu                 |-> rfu.value,
         roundLotSize        |-> roundLotSize.value,
         roundLotsOnly       |-> roundLotsOnly.value,
         issueClassification |-> issueClassification.value,
         issueSubType        |-> issueSubType.value ], issueSubType.rest)

ZeroStockDirectory ==
    [ symbol              |-> [i \in 1 .. 8 |-> 0],
      marketCategory      |-> [i \in 1 .. 1 |-> 0],
      rfu                 |-> [i \in 1 .. 1 |-> 0],
      roundLotSize        |-> [i \in 1 .. 6 |-> 0],
      roundLotsOnly       |-> [i \in 1 .. 1 |-> 0],
      issueClassification |-> [i \in 1 .. 1 |-> 0],
      issueSubType        |-> [i \in 1 .. 2 |-> 0] ]

(* Stock Directory at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectory ==
    { ZeroStockDirectory }
        \cup { [ZeroStockDirectory EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectory EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectory EXCEPT !.rfu = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectory EXCEPT !.roundLotSize = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectory EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectory EXCEPT !.issueClassification = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectory EXCEPT !.issueSubType = one] : one \in Sample(2) }

(***************************************************************************)
(* Stock Trading Action: 10 bytes                                          *)
(***************************************************************************)

StockTradingAction ==
    [ symbol       : Sample(8),
      tradingState : Sample(1),
      reason       : Sample(1) ]

EncodeStockTradingAction(message) ==
    message.symbol
        \o message.tradingState
        \o message.reason

DecodeStockTradingAction(bytes) ==
    LET symbol == ReadBytes(bytes, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET tradingState == ReadBytes(symbol.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET reason == ReadBytes(tradingState.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ symbol       |-> symbol.value,
         tradingState |-> tradingState.value,
         reason       |-> reason.value ], reason.rest)

ZeroStockTradingAction ==
    [ symbol       |-> [i \in 1 .. 8 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0],
      reason       |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Trading Action at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingAction ==
    { ZeroStockTradingAction }
        \cup { [ZeroStockTradingAction EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingAction EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingAction EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Nois Message: 39 bytes                                                  *)
(***************************************************************************)

NoisMessage ==
    [ imbalanceShares       : Sample(9),
      imbalanceDirection    : Sample(1),
      symbol                : Sample(8),
      nearPrice             : Sample(10),
      currentReferencePrice : Sample(10),
      crossType             : Sample(1) ]

EncodeNoisMessage(message) ==
    message.imbalanceShares
        \o message.imbalanceDirection
        \o message.symbol
        \o message.nearPrice
        \o message.currentReferencePrice
        \o message.crossType

DecodeNoisMessage(bytes) ==
    LET imbalanceShares == ReadBytes(bytes, 9) IN IF ~imbalanceShares.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceShares.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET symbol == ReadBytes(imbalanceDirection.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET nearPrice == ReadBytes(symbol.rest, 10) IN IF ~nearPrice.ok THEN Fail ELSE
    LET currentReferencePrice == ReadBytes(nearPrice.rest, 10) IN IF ~currentReferencePrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(currentReferencePrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    Ok([ imbalanceShares       |-> imbalanceShares.value,
         imbalanceDirection    |-> imbalanceDirection.value,
         symbol                |-> symbol.value,
         nearPrice             |-> nearPrice.value,
         currentReferencePrice |-> currentReferencePrice.value,
         crossType             |-> crossType.value ], crossType.rest)

ZeroNoisMessage ==
    [ imbalanceShares       |-> [i \in 1 .. 9 |-> 0],
      imbalanceDirection    |-> [i \in 1 .. 1 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      nearPrice             |-> [i \in 1 .. 10 |-> 0],
      currentReferencePrice |-> [i \in 1 .. 10 |-> 0],
      crossType             |-> [i \in 1 .. 1 |-> 0] ]

(* Nois Message at zero, then each field in turn at the values it is checked at *)
CheckedNoisMessage ==
    { ZeroNoisMessage }
        \cup { [ZeroNoisMessage EXCEPT !.imbalanceShares = one] : one \in Sample(9) }
        \cup { [ZeroNoisMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNoisMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroNoisMessage EXCEPT !.nearPrice = one] : one \in Sample(10) }
        \cup { [ZeroNoisMessage EXCEPT !.currentReferencePrice = one] : one \in Sample(10) }
        \cup { [ZeroNoisMessage EXCEPT !.crossType = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryCode == 82  \* "R"
StockTradingActionCode == 72  \* "H"
NoisMessageCode == 73  \* "I"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryCode}, body : StockDirectory ]
        \cup [ tag : {StockTradingActionCode}, body : StockTradingAction ]
        \cup [ tag : {NoisMessageCode}, body : NoisMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryCode -> EncodeStockDirectory(message.body)
      [] message.tag = StockTradingActionCode -> EncodeStockTradingAction(message.body)
      [] message.tag = NoisMessageCode -> EncodeNoisMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryCode -> DecodeStockDirectory(bytes)
              [] tag = StockTradingActionCode -> DecodeStockTradingAction(bytes)
              [] tag = NoisMessageCode -> DecodeNoisMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryCode, body |-> one] : one \in CheckedStockDirectory }
        \cup { [tag |-> StockTradingActionCode, body |-> one] : one \in CheckedStockTradingAction }
        \cup { [tag |-> NoisMessageCode, body |-> one] : one \in CheckedNoisMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ timestamp : Sample(8),
      payload   : Payload ]

EncodeMessageBody(message) ==
    message.timestamp
        \o EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntLE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         payload   |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      payload   |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryCode, body |-> ZeroStockDirectory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockTradingActionCode, body |-> ZeroStockTradingAction]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NoisMessageCode, body |-> ZeroNoisMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(4),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntLE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
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
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Directory decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectory ==
    \A message \in CheckedStockDirectory :
        LET read == DecodeStockDirectory(EncodeStockDirectory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Trading Action decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingAction ==
    \A message \in CheckedStockTradingAction :
        LET read == DecodeStockTradingAction(EncodeStockTradingAction(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nois Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNoisMessage ==
    \A message \in CheckedNoisMessage :
        LET read == DecodeNoisMessage(EncodeNoisMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in Payload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in Message :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
