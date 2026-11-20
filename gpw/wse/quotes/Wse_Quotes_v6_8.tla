-------------------------- MODULE Wse_Quotes_v6_8 --------------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie Warsaw Stock Exchange Quotes  *)
(* v6.8                                                                    *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: a Delivery Flag of 16 to 255 says Message Buffer was transformed, *)
(* and one of 0 to 15 that it was not, so it is then read as it stands.    *)
(*                                                                         *)
(* Note: Message Buffer untransformed is as many Message as Number Msg     *)
(* Entries says, which is read beside the flag and handed to the choice:   *)
(* the count says how many the bytes hold, and transformed they hold a run *)
(* no reading of them states, so it is carried rather than written from    *)
(* the run.                                                                *)
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
(* Message Buffer                                                          *)
(***************************************************************************)

MessageBufferZlib ==
    [ transformed : SampleBytes ]

EncodeMessageBufferZlib(message) ==
    message.transformed

DecodeMessageBufferZlib(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroMessageBufferZlib ==
    [ transformed |-> << >> ]

(* Message Buffer at zero, then each field in turn at the values it is checked at *)
CheckedMessageBufferZlib ==
    { ZeroMessageBufferZlib }
        \cup { [ZeroMessageBufferZlib EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Quotes And Bbo 5 Message: 48 bytes                                      *)
(***************************************************************************)

QuotesAndBbo5Message ==
    [ symbolIndex         : Sample(4),
      sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      quoteLinkId         : Sample(4),
      askPrice            : Sample(4),
      askSize             : Sample(4),
      bidPrice            : Sample(4),
      bidSize             : Sample(4),
      systemId            : Sample(4),
      numberAskOrders     : Sample(2),
      numberBidOrders     : Sample(2),
      sourceTimeMicroSecs : Sample(2),
      typeOfAskPrice      : Sample(1),
      typeOfBidPrice      : Sample(1),
      quoteCondition      : Sample(1),
      quoteNumber         : Sample(1),
      priceScaleCode      : Sample(1),
      reserved1           : Sample(1) ]

EncodeQuotesAndBbo5Message(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.quoteLinkId
        \o message.askPrice
        \o message.askSize
        \o message.bidPrice
        \o message.bidSize
        \o message.systemId
        \o message.numberAskOrders
        \o message.numberBidOrders
        \o message.sourceTimeMicroSecs
        \o message.typeOfAskPrice
        \o message.typeOfBidPrice
        \o message.quoteCondition
        \o message.quoteNumber
        \o message.priceScaleCode
        \o message.reserved1

DecodeQuotesAndBbo5Message(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET quoteLinkId == ReadBytes(sourceTime.rest, 4) IN IF ~quoteLinkId.ok THEN Fail ELSE
    LET askPrice == ReadBytes(quoteLinkId.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askSize.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET systemId == ReadBytes(bidSize.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET numberAskOrders == ReadBytes(systemId.rest, 2) IN IF ~numberAskOrders.ok THEN Fail ELSE
    LET numberBidOrders == ReadBytes(numberAskOrders.rest, 2) IN IF ~numberBidOrders.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(numberBidOrders.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET typeOfAskPrice == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~typeOfAskPrice.ok THEN Fail ELSE
    LET typeOfBidPrice == ReadBytes(typeOfAskPrice.rest, 1) IN IF ~typeOfBidPrice.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(typeOfBidPrice.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET quoteNumber == ReadBytes(quoteCondition.rest, 1) IN IF ~quoteNumber.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(quoteNumber.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(priceScaleCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         quoteLinkId         |-> quoteLinkId.value,
         askPrice            |-> askPrice.value,
         askSize             |-> askSize.value,
         bidPrice            |-> bidPrice.value,
         bidSize             |-> bidSize.value,
         systemId            |-> systemId.value,
         numberAskOrders     |-> numberAskOrders.value,
         numberBidOrders     |-> numberBidOrders.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         typeOfAskPrice      |-> typeOfAskPrice.value,
         typeOfBidPrice      |-> typeOfBidPrice.value,
         quoteCondition      |-> quoteCondition.value,
         quoteNumber         |-> quoteNumber.value,
         priceScaleCode      |-> priceScaleCode.value,
         reserved1           |-> reserved1.value ], reserved1.rest)

ZeroQuotesAndBbo5Message ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      quoteLinkId         |-> [i \in 1 .. 4 |-> 0],
      askPrice            |-> [i \in 1 .. 4 |-> 0],
      askSize             |-> [i \in 1 .. 4 |-> 0],
      bidPrice            |-> [i \in 1 .. 4 |-> 0],
      bidSize             |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      numberAskOrders     |-> [i \in 1 .. 2 |-> 0],
      numberBidOrders     |-> [i \in 1 .. 2 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      typeOfAskPrice      |-> [i \in 1 .. 1 |-> 0],
      typeOfBidPrice      |-> [i \in 1 .. 1 |-> 0],
      quoteCondition      |-> [i \in 1 .. 1 |-> 0],
      quoteNumber         |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode      |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0] ]

(* Quotes And Bbo 5 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuotesAndBbo5Message ==
    { ZeroQuotesAndBbo5Message }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.quoteLinkId = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.numberAskOrders = one] : one \in Sample(2) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.numberBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.typeOfAskPrice = one] : one \in Sample(1) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.typeOfBidPrice = one] : one \in Sample(1) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.quoteNumber = one] : one \in Sample(1) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroQuotesAndBbo5Message EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Indication Of Interest Message: 160 bytes                               *)
(***************************************************************************)

IndicationOfInterestMessage ==
    [ symbolIndex         : Sample(4),
      sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      ioiutpid            : Sample(4),
      ioiQty              : Sample(4),
      price               : Sample(4),
      validityTime        : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      priceScaleCode      : Sample(1),
      ioiTransType        : Sample(1),
      firmId              : Sample(11),
      side                : Sample(1),
      settlementDate      : Sample(8),
      text                : Sample(100),
      tradeType           : Sample(1),
      reserved3           : Sample(3) ]

EncodeIndicationOfInterestMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.ioiutpid
        \o message.ioiQty
        \o message.price
        \o message.validityTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.priceScaleCode
        \o message.ioiTransType
        \o message.firmId
        \o message.side
        \o message.settlementDate
        \o message.text
        \o message.tradeType
        \o message.reserved3

DecodeIndicationOfInterestMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET ioiutpid == ReadBytes(sourceTime.rest, 4) IN IF ~ioiutpid.ok THEN Fail ELSE
    LET ioiQty == ReadBytes(ioiutpid.rest, 4) IN IF ~ioiQty.ok THEN Fail ELSE
    LET price == ReadBytes(ioiQty.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET validityTime == ReadBytes(price.rest, 4) IN IF ~validityTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(validityTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET ioiTransType == ReadBytes(priceScaleCode.rest, 1) IN IF ~ioiTransType.ok THEN Fail ELSE
    LET firmId == ReadBytes(ioiTransType.rest, 11) IN IF ~firmId.ok THEN Fail ELSE
    LET side == ReadBytes(firmId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(side.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    LET text == ReadBytes(settlementDate.rest, 100) IN IF ~text.ok THEN Fail ELSE
    LET tradeType == ReadBytes(text.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(tradeType.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         ioiutpid            |-> ioiutpid.value,
         ioiQty              |-> ioiQty.value,
         price               |-> price.value,
         validityTime        |-> validityTime.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         priceScaleCode      |-> priceScaleCode.value,
         ioiTransType        |-> ioiTransType.value,
         firmId              |-> firmId.value,
         side                |-> side.value,
         settlementDate      |-> settlementDate.value,
         text                |-> text.value,
         tradeType           |-> tradeType.value,
         reserved3           |-> reserved3.value ], reserved3.rest)

ZeroIndicationOfInterestMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      ioiutpid            |-> [i \in 1 .. 4 |-> 0],
      ioiQty              |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      validityTime        |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      priceScaleCode      |-> [i \in 1 .. 1 |-> 0],
      ioiTransType        |-> [i \in 1 .. 1 |-> 0],
      firmId              |-> [i \in 1 .. 11 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      settlementDate      |-> [i \in 1 .. 8 |-> 0],
      text                |-> [i \in 1 .. 100 |-> 0],
      tradeType           |-> [i \in 1 .. 1 |-> 0],
      reserved3           |-> [i \in 1 .. 3 |-> 0] ]

(* Indication Of Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicationOfInterestMessage ==
    { ZeroIndicationOfInterestMessage }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.ioiutpid = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.ioiQty = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.validityTime = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.ioiTransType = one] : one \in Sample(1) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.firmId = one] : one \in Sample(11) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.settlementDate = one] : one \in Sample(8) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.text = one] : one \in Sample(100) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

QuotesAndBbo5MessageCode == 140  \* 0x8c
IndicationOfInterestMessageCode == 142  \* 0x8e

Payload ==
    [ tag : {QuotesAndBbo5MessageCode}, body : QuotesAndBbo5Message ]
        \cup [ tag : {IndicationOfInterestMessageCode}, body : IndicationOfInterestMessage ]

EncodePayload(message) ==
    CASE message.tag = QuotesAndBbo5MessageCode -> EncodeQuotesAndBbo5Message(message.body)
      [] message.tag = IndicationOfInterestMessageCode -> EncodeIndicationOfInterestMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = QuotesAndBbo5MessageCode -> DecodeQuotesAndBbo5Message(bytes)
              [] tag = IndicationOfInterestMessageCode -> DecodeIndicationOfInterestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> QuotesAndBbo5MessageCode, body |-> ZeroQuotesAndBbo5Message]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> QuotesAndBbo5MessageCode, body |-> one] : one \in CheckedQuotesAndBbo5Message }
        \cup { [tag |-> IndicationOfInterestMessageCode, body |-> one] : one \in CheckedIndicationOfInterestMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> QuotesAndBbo5MessageCode, body |-> ZeroQuotesAndBbo5Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndicationOfInterestMessageCode, body |-> ZeroIndicationOfInterestMessage]] }

(***************************************************************************)
(* Message Buffer, selected by Delivery Flag                               *)
(***************************************************************************)

MessageBufferZlibCode == 16  \* 0x10
MessageBufferPlainCode == 0  \* 0x00

MessageBufferBody ==
    [ tag : 16 .. 255, body : MessageBufferZlib ]
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

EncodeMessageBufferBody(message) ==
    CASE message.tag \in 16 .. 255 -> EncodeMessageBufferZlib(message.body)
      [] message.tag \in 0 .. 15 -> EncodeMessageList(message.body)

(* How many Message a Message Buffer holds, which is what Number Msg Entries states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountMessageBufferBody(choice, stated) ==
    CASE choice.tag \in 16 .. 255 -> stated
      [] choice.tag \in 0 .. 15 -> Len(choice.body)

DecodeMessageBufferBody(tag, count, bytes) ==
    LET read ==
            CASE tag \in 16 .. 255 -> DecodeMessageBufferZlib(bytes)
              [] tag \in 0 .. 15 -> ReadMessageList(bytes, count)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferZlibCode, body |-> ZeroMessageBufferZlib]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> tag, body |-> one] : tag \in {16, 255}, one \in CheckedMessageBufferZlib }
        \cup { [tag |-> tag, body |-> one] : tag \in {0, 15}, one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetLength         : Sample(2),
      packetType           : Sample(2),
      packetSequenceNumber : Sample(4),
      sendTime             : Sample(4),
      serviceId            : Sample(2),
      numberMsgEntries     : 0 .. 255,
      messageBuffer        : MessageBufferBody ]

EncodePacket(message) ==
    message.packetLength
        \o message.packetType
        \o message.packetSequenceNumber
        \o message.sendTime
        \o message.serviceId
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o EncodeUIntBE(message.numberMsgEntries, 1)
        \o EncodeMessageBufferBody(message.messageBuffer)

DecodePacket(bytes) ==
    LET packetLength == ReadBytes(bytes, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET packetType == ReadBytes(packetLength.rest, 2) IN IF ~packetType.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetType.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(packetSequenceNumber.rest, 4) IN IF ~sendTime.ok THEN Fail ELSE
    LET serviceId == ReadBytes(sendTime.rest, 2) IN IF ~serviceId.ok THEN Fail ELSE
    LET deliveryFlag == ReadUIntBE(serviceId.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgEntries == ReadUIntBE(deliveryFlag.rest, 1) IN IF ~numberMsgEntries.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(deliveryFlag.value, numberMsgEntries.value, numberMsgEntries.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ packetLength         |-> packetLength.value,
         packetType           |-> packetType.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         sendTime             |-> sendTime.value,
         serviceId            |-> serviceId.value,
         numberMsgEntries     |-> numberMsgEntries.value,
         messageBuffer        |-> messageBuffer.value ], messageBuffer.rest)

ZeroPacket ==
    [ packetLength         |-> [i \in 1 .. 2 |-> 0],
      packetType           |-> [i \in 1 .. 2 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime             |-> [i \in 1 .. 4 |-> 0],
      serviceId            |-> [i \in 1 .. 2 |-> 0],
      numberMsgEntries     |-> 0,
      messageBuffer        |-> ZeroMessageBufferBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
(* Number Msg Entries is varied with the Message Buffer it counts, which is read as many as it says *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.serviceId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = CountMessageBufferBody(one, 0), !.messageBuffer = one] : one \in CheckedMessageBufferBody }

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

(* Every Message Buffer decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBufferZlib ==
    \A message \in CheckedMessageBufferZlib :
        LET read == DecodeMessageBufferZlib(EncodeMessageBufferZlib(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotes And Bbo 5 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotesAndBbo5Message ==
    \A message \in CheckedQuotesAndBbo5Message :
        LET read == DecodeQuotesAndBbo5Message(EncodeQuotesAndBbo5Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indication Of Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicationOfInterestMessage ==
    \A message \in CheckedIndicationOfInterestMessage :
        LET read == DecodeIndicationOfInterestMessage(EncodeIndicationOfInterestMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Buffer is selected by the Delivery Flag it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, CountMessageBufferBody(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
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
