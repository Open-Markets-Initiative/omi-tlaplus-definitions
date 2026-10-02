----------------- MODULE PsxEquities_TotalView_v3_2_Server -----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) TotalView Itch v3.2                                            *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ text : Sample(1) ]

EncodeDebugPacket(message) ==
    message.text

DecodeDebugPacket(bytes) ==
    LET text == ReadBytes(bytes, 1) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroDebugPacket ==
    [ text |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.text = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ session        : Sample(10),
      sequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.session
        \o message.sequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 20) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.sequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Seconds Message: 5 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ second : Sample(5) ]

EncodeSecondsMessage(message) ==
    message.second

DecodeSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 5) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroSecondsMessage ==
    [ second |-> [i \in 1 .. 5 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.second = one] : one \in Sample(5) }

(***************************************************************************)
(* Milliseconds Message: 3 bytes                                           *)
(***************************************************************************)

MillisecondsMessage ==
    [ millisecond : Sample(3) ]

EncodeMillisecondsMessage(message) ==
    message.millisecond

DecodeMillisecondsMessage(bytes) ==
    LET millisecond == ReadBytes(bytes, 3) IN IF ~millisecond.ok THEN Fail ELSE
    Ok([ millisecond |-> millisecond.value ], millisecond.rest)

ZeroMillisecondsMessage ==
    [ millisecond |-> [i \in 1 .. 3 |-> 0] ]

(* Milliseconds Message at zero, then each field in turn at the values it is checked at *)
CheckedMillisecondsMessage ==
    { ZeroMillisecondsMessage }
        \cup { [ZeroMillisecondsMessage EXCEPT !.millisecond = one] : one \in Sample(3) }

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
(* Add Order Message: 37 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ orderReferenceNumber : Sample(12),
      buySellIndicator     : Sample(1),
      shares               : Sample(6),
      stock                : Sample(8),
      price                : Sample(10) ]

EncodeAddOrderMessage(message) ==
    message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price

DecodeAddOrderMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 10) IN IF ~price.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value ], price.rest)

ZeroAddOrderMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 6 |-> 0],
      stock                |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(10) }

(***************************************************************************)
(* Add Order Mpid Attribution Message: 41 bytes                            *)
(***************************************************************************)

AddOrderMpidAttributionMessage ==
    [ orderReferenceNumber : Sample(12),
      buySellIndicator     : Sample(1),
      shares               : Sample(6),
      stock                : Sample(8),
      price                : Sample(10),
      attribution          : Sample(4) ]

EncodeAddOrderMpidAttributionMessage(message) ==
    message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price
        \o message.attribution

DecodeAddOrderMpidAttributionMessage(bytes) ==
    LET orderReferenceNumber == ReadBytes(bytes, 12) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 10) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 4) IN IF ~attribution.ok THEN Fail ELSE
    Ok([ orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         attribution          |-> attribution.value ], attribution.rest)

ZeroAddOrderMpidAttributionMessage ==
    [ orderReferenceNumber |-> [i \in 1 .. 12 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 6 |-> 0],
      stock                |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 10 |-> 0],
      attribution          |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Mpid Attribution Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMpidAttributionMessage ==
    { ZeroAddOrderMpidAttributionMessage }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(12) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.price = one] : one \in Sample(10) }
        \cup { [ZeroAddOrderMpidAttributionMessage EXCEPT !.attribution = one] : one \in Sample(4) }

(***************************************************************************)
(* Stock Directory Message: 17 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ stock                    : Sample(8),
      marketCategory           : Sample(1),
      financialStatusIndicator : Sample(1),
      roundLotSize             : Sample(6),
      roundLotsOnly            : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.stock
        \o message.marketCategory
        \o message.financialStatusIndicator
        \o message.roundLotSize
        \o message.roundLotsOnly

DecodeStockDirectoryMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 6) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    Ok([ stock                    |-> stock.value,
         marketCategory           |-> marketCategory.value,
         financialStatusIndicator |-> financialStatusIndicator.value,
         roundLotSize             |-> roundLotSize.value,
         roundLotsOnly            |-> roundLotsOnly.value ], roundLotsOnly.rest)

ZeroStockDirectoryMessage ==
    [ stock                    |-> [i \in 1 .. 8 |-> 0],
      marketCategory           |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator |-> [i \in 1 .. 1 |-> 0],
      roundLotSize             |-> [i \in 1 .. 6 |-> 0],
      roundLotsOnly            |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action Message: 14 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ stock        : Sample(8),
      tradingState : Sample(1),
      reserved     : Sample(1),
      reason       : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.stock
        \o message.tradingState
        \o message.reserved
        \o message.reason

DecodeStockTradingActionMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET tradingState == ReadBytes(stock.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingState.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET reason == ReadBytes(reserved.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ stock        |-> stock.value,
         tradingState |-> tradingState.value,
         reserved     |-> reserved.value,
         reason       |-> reason.value ], reason.rest)

ZeroStockTradingActionMessage ==
    [ stock        |-> [i \in 1 .. 8 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0],
      reserved     |-> [i \in 1 .. 1 |-> 0],
      reason       |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Reg Sho Restriction Message: 9 bytes                                    *)
(***************************************************************************)

RegShoRestrictionMessage ==
    [ stock        : Sample(8),
      regShoAction : Sample(1) ]

EncodeRegShoRestrictionMessage(message) ==
    message.stock
        \o message.regShoAction

DecodeRegShoRestrictionMessage(bytes) ==
    LET stock == ReadBytes(bytes, 8) IN IF ~stock.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(stock.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ stock        |-> stock.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoRestrictionMessage ==
    [ stock        |-> [i \in 1 .. 8 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoRestrictionMessage ==
    { ZeroRegShoRestrictionMessage }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Snapshot Message: 20 bytes                                       *)
(***************************************************************************)

EndOfSnapshotMessage ==
    [ itchSequenceNumber : Sample(20) ]

EncodeEndOfSnapshotMessage(message) ==
    message.itchSequenceNumber

DecodeEndOfSnapshotMessage(bytes) ==
    LET itchSequenceNumber == ReadBytes(bytes, 20) IN IF ~itchSequenceNumber.ok THEN Fail ELSE
    Ok([ itchSequenceNumber |-> itchSequenceNumber.value ], itchSequenceNumber.rest)

ZeroEndOfSnapshotMessage ==
    [ itchSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* End Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshotMessage ==
    { ZeroEndOfSnapshotMessage }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.itchSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Sequenced Message, selected by Message Type                             *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
MillisecondsMessageCode == 77  \* "M"
SystemEventMessageCode == 83  \* "S"
AddOrderMessageCode == 65  \* "A"
AddOrderMpidAttributionMessageCode == 70  \* "F"
StockDirectoryMessageCode == 82  \* "R"
StockTradingActionMessageCode == 72  \* "H"
RegShoRestrictionMessageCode == 89  \* "Y"
EndOfSnapshotMessageCode == 71  \* "G"

SequencedMessage ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {MillisecondsMessageCode}, body : MillisecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AddOrderMpidAttributionMessageCode}, body : AddOrderMpidAttributionMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {RegShoRestrictionMessageCode}, body : RegShoRestrictionMessage ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = MillisecondsMessageCode -> EncodeMillisecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AddOrderMpidAttributionMessageCode -> EncodeAddOrderMpidAttributionMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = RegShoRestrictionMessageCode -> EncodeRegShoRestrictionMessage(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = MillisecondsMessageCode -> DecodeMillisecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AddOrderMpidAttributionMessageCode -> DecodeAddOrderMpidAttributionMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = RegShoRestrictionMessageCode -> DecodeRegShoRestrictionMessage(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> MillisecondsMessageCode, body |-> one] : one \in CheckedMillisecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AddOrderMpidAttributionMessageCode, body |-> one] : one \in CheckedAddOrderMpidAttributionMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> RegShoRestrictionMessageCode, body |-> one] : one \in CheckedRegShoRestrictionMessage }
        \cup { [tag |-> EndOfSnapshotMessageCode, body |-> one] : one \in CheckedEndOfSnapshotMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(messageType.value, messageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverPayload : ServerPayload,
      soupLf        : Sample(1) ]

EncodeServerPacket(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)
        \o message.soupLf

DecodeServerPacket(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    LET soupLf == ReadBytes(serverPayload.rest, 1) IN IF ~soupLf.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value,
         soupLf        |-> soupLf.value ], soupLf.rest)

ZeroServerPacket ==
    [ serverPayload |-> ZeroServerPayload,
      soupLf        |-> [i \in 1 .. 1 |-> 0] ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }
        \cup { [ZeroServerPacket EXCEPT !.soupLf = one] : one \in Sample(1) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Milliseconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMillisecondsMessage ==
    \A message \in CheckedMillisecondsMessage :
        LET read == DecodeMillisecondsMessage(EncodeMillisecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Mpid Attribution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMpidAttributionMessage ==
    \A message \in CheckedAddOrderMpidAttributionMessage :
        LET read == DecodeAddOrderMpidAttributionMessage(EncodeAddOrderMpidAttributionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingActionMessage ==
    \A message \in CheckedStockTradingActionMessage :
        LET read == DecodeStockTradingActionMessage(EncodeStockTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Restriction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoRestrictionMessage ==
    \A message \in CheckedRegShoRestrictionMessage :
        LET read == DecodeRegShoRestrictionMessage(EncodeRegShoRestrictionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSnapshotMessage ==
    \A message \in CheckedEndOfSnapshotMessage :
        LET read == DecodeEndOfSnapshotMessage(EncodeEndOfSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
