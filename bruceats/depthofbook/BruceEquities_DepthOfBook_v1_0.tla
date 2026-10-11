------------------ MODULE BruceEquities_DepthOfBook_v1_0 -------------------
(***************************************************************************)
(* Bruce ATS Depth Of Book v1.0                                            *)
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
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ stockLocate : Sample(2),
      timestamp   : Sample(8),
      eventCode   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ stockLocate |-> stockLocate.value,
         timestamp   |-> timestamp.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ stockLocate |-> [i \in 1 .. 2 |-> 0],
      timestamp   |-> [i \in 1 .. 8 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory: 24 bytes                                               *)
(***************************************************************************)

StockDirectory ==
    [ stockLocate    : Sample(2),
      timestamp      : Sample(8),
      stock          : Sample(8),
      marketCategory : Sample(1),
      roundLotSize   : Sample(4),
      authenticity   : Sample(1) ]

EncodeStockDirectory(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.stock
        \o message.marketCategory
        \o message.roundLotSize
        \o message.authenticity

DecodeStockDirectory(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(marketCategory.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET authenticity == ReadBytes(roundLotSize.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         timestamp      |-> timestamp.value,
         stock          |-> stock.value,
         marketCategory |-> marketCategory.value,
         roundLotSize   |-> roundLotSize.value,
         authenticity   |-> authenticity.value ], authenticity.rest)

ZeroStockDirectory ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      marketCategory |-> [i \in 1 .. 1 |-> 0],
      roundLotSize   |-> [i \in 1 .. 4 |-> 0],
      authenticity   |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectory ==
    { ZeroStockDirectory }
        \cup { [ZeroStockDirectory EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectory EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectory EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectory EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectory EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectory EXCEPT !.authenticity = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action: 19 bytes                                          *)
(***************************************************************************)

StockTradingAction ==
    [ stockLocate  : Sample(2),
      timestamp    : Sample(8),
      stock        : Sample(8),
      tradingState : Sample(1) ]

EncodeStockTradingAction(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.stock
        \o message.tradingState

DecodeStockTradingAction(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET tradingState == ReadBytes(stock.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    Ok([ stockLocate  |-> stockLocate.value,
         timestamp    |-> timestamp.value,
         stock        |-> stock.value,
         tradingState |-> tradingState.value ], tradingState.rest)

ZeroStockTradingAction ==
    [ stockLocate  |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      stock        |-> [i \in 1 .. 8 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Trading Action at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingAction ==
    { ZeroStockTradingAction }
        \cup { [ZeroStockTradingAction EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroStockTradingAction EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingAction EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingAction EXCEPT !.tradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator: 19 bytes            *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicator ==
    [ stockLocate  : Sample(2),
      timestamp    : Sample(8),
      stock        : Sample(8),
      regShoAction : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicator(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.stock
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicator(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(stock.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ stockLocate  |-> stockLocate.value,
         timestamp    |-> timestamp.value,
         stock        |-> stock.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicator ==
    [ stockLocate  |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      stock        |-> [i \in 1 .. 8 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicator ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicator }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicator EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicator EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicator EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicator EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Quotation Message: 42 bytes                                             *)
(***************************************************************************)

QuotationMessage ==
    [ stockLocate    : Sample(2),
      timestamp      : Sample(8),
      stock          : Sample(8),
      bestBidPrice   : Sample(8),
      bestBidSize    : Sample(4),
      bestOfferPrice : Sample(8),
      bestOfferSize  : Sample(4) ]

EncodeQuotationMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.stock
        \o message.bestBidPrice
        \o message.bestBidSize
        \o message.bestOfferPrice
        \o message.bestOfferSize

DecodeQuotationMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(stock.rest, 8) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestOfferPrice == ReadBytes(bestBidSize.rest, 8) IN IF ~bestOfferPrice.ok THEN Fail ELSE
    LET bestOfferSize == ReadBytes(bestOfferPrice.rest, 4) IN IF ~bestOfferSize.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         timestamp      |-> timestamp.value,
         stock          |-> stock.value,
         bestBidPrice   |-> bestBidPrice.value,
         bestBidSize    |-> bestBidSize.value,
         bestOfferPrice |-> bestOfferPrice.value,
         bestOfferSize  |-> bestOfferSize.value ], bestOfferSize.rest)

ZeroQuotationMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      bestBidPrice   |-> [i \in 1 .. 8 |-> 0],
      bestBidSize    |-> [i \in 1 .. 4 |-> 0],
      bestOfferPrice |-> [i \in 1 .. 8 |-> 0],
      bestOfferSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedQuotationMessage ==
    { ZeroQuotationMessage }
        \cup { [ZeroQuotationMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroQuotationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.bestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.bestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotationMessage EXCEPT !.bestOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuotationMessage EXCEPT !.bestOfferSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryCode == 82  \* "R"
StockTradingActionCode == 72  \* "H"
RegShoShortSalePriceTestRestrictedIndicatorCode == 89  \* "Y"
QuotationMessageCode == 81  \* "Q"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryCode}, body : StockDirectory ]
        \cup [ tag : {StockTradingActionCode}, body : StockTradingAction ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorCode}, body : RegShoShortSalePriceTestRestrictedIndicator ]
        \cup [ tag : {QuotationMessageCode}, body : QuotationMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryCode -> EncodeStockDirectory(message.body)
      [] message.tag = StockTradingActionCode -> EncodeStockTradingAction(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorCode -> EncodeRegShoShortSalePriceTestRestrictedIndicator(message.body)
      [] message.tag = QuotationMessageCode -> EncodeQuotationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryCode -> DecodeStockDirectory(bytes)
              [] tag = StockTradingActionCode -> DecodeStockTradingAction(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorCode -> DecodeRegShoShortSalePriceTestRestrictedIndicator(bytes)
              [] tag = QuotationMessageCode -> DecodeQuotationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryCode, body |-> one] : one \in CheckedStockDirectory }
        \cup { [tag |-> StockTradingActionCode, body |-> one] : one \in CheckedStockTradingAction }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicator }
        \cup { [tag |-> QuotationMessageCode, body |-> one] : one \in CheckedQuotationMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
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
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoShortSalePriceTestRestrictedIndicatorCode, body |-> ZeroRegShoShortSalePriceTestRestrictedIndicator]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuotationMessageCode, body |-> ZeroQuotationMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
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

(* Every Reg Sho Short Sale Price Test Restricted Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicator ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicator :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicator(EncodeRegShoShortSalePriceTestRestrictedIndicator(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotationMessage ==
    \A message \in CheckedQuotationMessage :
        LET read == DecodeQuotationMessage(EncodeQuotationMessage(message))
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
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
