------------------- MODULE BmvMarketData_Product33_v1_1 --------------------
(***************************************************************************)
(* Bolsa Mexicana de Valores Bmv Market Data Product 33 v1.1               *)
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
(* Big Picture Message: 37 bytes                                           *)
(***************************************************************************)

BigPictureMessage ==
    [ origin            : Sample(1),
      trades            : Sample(4),
      volume            : Sample(8),
      tradedValue       : Sample(8),
      marketShareAmount : Sample(4),
      marketShareTrades : Sample(4),
      market            : Sample(1),
      sector            : Sample(1),
      instrumentNumber  : Sample(4),
      indices           : Sample(2) ]

EncodeBigPictureMessage(message) ==
    message.origin
        \o message.trades
        \o message.volume
        \o message.tradedValue
        \o message.marketShareAmount
        \o message.marketShareTrades
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodeBigPictureMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET trades == ReadBytes(origin.rest, 4) IN IF ~trades.ok THEN Fail ELSE
    LET volume == ReadBytes(trades.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradedValue == ReadBytes(volume.rest, 8) IN IF ~tradedValue.ok THEN Fail ELSE
    LET marketShareAmount == ReadBytes(tradedValue.rest, 4) IN IF ~marketShareAmount.ok THEN Fail ELSE
    LET marketShareTrades == ReadBytes(marketShareAmount.rest, 4) IN IF ~marketShareTrades.ok THEN Fail ELSE
    LET market == ReadBytes(marketShareTrades.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin            |-> origin.value,
         trades            |-> trades.value,
         volume            |-> volume.value,
         tradedValue       |-> tradedValue.value,
         marketShareAmount |-> marketShareAmount.value,
         marketShareTrades |-> marketShareTrades.value,
         market            |-> market.value,
         sector            |-> sector.value,
         instrumentNumber  |-> instrumentNumber.value,
         indices           |-> indices.value ], indices.rest)

ZeroBigPictureMessage ==
    [ origin            |-> [i \in 1 .. 1 |-> 0],
      trades            |-> [i \in 1 .. 4 |-> 0],
      volume            |-> [i \in 1 .. 8 |-> 0],
      tradedValue       |-> [i \in 1 .. 8 |-> 0],
      marketShareAmount |-> [i \in 1 .. 4 |-> 0],
      marketShareTrades |-> [i \in 1 .. 4 |-> 0],
      market            |-> [i \in 1 .. 1 |-> 0],
      sector            |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      indices           |-> [i \in 1 .. 2 |-> 0] ]

(* Big Picture Message at zero, then each field in turn at the values it is checked at *)
CheckedBigPictureMessage ==
    { ZeroBigPictureMessage }
        \cup { [ZeroBigPictureMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroBigPictureMessage EXCEPT !.trades = one] : one \in Sample(4) }
        \cup { [ZeroBigPictureMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroBigPictureMessage EXCEPT !.tradedValue = one] : one \in Sample(8) }
        \cup { [ZeroBigPictureMessage EXCEPT !.marketShareAmount = one] : one \in Sample(4) }
        \cup { [ZeroBigPictureMessage EXCEPT !.marketShareTrades = one] : one \in Sample(4) }
        \cup { [ZeroBigPictureMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroBigPictureMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroBigPictureMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroBigPictureMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Effective Spread Message: 33 bytes                                      *)
(***************************************************************************)

EffectiveSpreadMessage ==
    [ origin           : Sample(1),
      esMxn            : Sample(4),
      esBasisPoints    : Sample(4),
      esMxnBid         : Sample(4),
      esBasisPointsBid : Sample(4),
      esMxnAsk         : Sample(4),
      esBasisPointsAsk : Sample(4),
      market           : Sample(1),
      sector           : Sample(1),
      instrumentNumber : Sample(4),
      indices          : Sample(2) ]

EncodeEffectiveSpreadMessage(message) ==
    message.origin
        \o message.esMxn
        \o message.esBasisPoints
        \o message.esMxnBid
        \o message.esBasisPointsBid
        \o message.esMxnAsk
        \o message.esBasisPointsAsk
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodeEffectiveSpreadMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET esMxn == ReadBytes(origin.rest, 4) IN IF ~esMxn.ok THEN Fail ELSE
    LET esBasisPoints == ReadBytes(esMxn.rest, 4) IN IF ~esBasisPoints.ok THEN Fail ELSE
    LET esMxnBid == ReadBytes(esBasisPoints.rest, 4) IN IF ~esMxnBid.ok THEN Fail ELSE
    LET esBasisPointsBid == ReadBytes(esMxnBid.rest, 4) IN IF ~esBasisPointsBid.ok THEN Fail ELSE
    LET esMxnAsk == ReadBytes(esBasisPointsBid.rest, 4) IN IF ~esMxnAsk.ok THEN Fail ELSE
    LET esBasisPointsAsk == ReadBytes(esMxnAsk.rest, 4) IN IF ~esBasisPointsAsk.ok THEN Fail ELSE
    LET market == ReadBytes(esBasisPointsAsk.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin           |-> origin.value,
         esMxn            |-> esMxn.value,
         esBasisPoints    |-> esBasisPoints.value,
         esMxnBid         |-> esMxnBid.value,
         esBasisPointsBid |-> esBasisPointsBid.value,
         esMxnAsk         |-> esMxnAsk.value,
         esBasisPointsAsk |-> esBasisPointsAsk.value,
         market           |-> market.value,
         sector           |-> sector.value,
         instrumentNumber |-> instrumentNumber.value,
         indices          |-> indices.value ], indices.rest)

ZeroEffectiveSpreadMessage ==
    [ origin           |-> [i \in 1 .. 1 |-> 0],
      esMxn            |-> [i \in 1 .. 4 |-> 0],
      esBasisPoints    |-> [i \in 1 .. 4 |-> 0],
      esMxnBid         |-> [i \in 1 .. 4 |-> 0],
      esBasisPointsBid |-> [i \in 1 .. 4 |-> 0],
      esMxnAsk         |-> [i \in 1 .. 4 |-> 0],
      esBasisPointsAsk |-> [i \in 1 .. 4 |-> 0],
      market           |-> [i \in 1 .. 1 |-> 0],
      sector           |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber |-> [i \in 1 .. 4 |-> 0],
      indices          |-> [i \in 1 .. 2 |-> 0] ]

(* Effective Spread Message at zero, then each field in turn at the values it is checked at *)
CheckedEffectiveSpreadMessage ==
    { ZeroEffectiveSpreadMessage }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.esMxn = one] : one \in Sample(4) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.esBasisPoints = one] : one \in Sample(4) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.esMxnBid = one] : one \in Sample(4) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.esBasisPointsBid = one] : one \in Sample(4) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.esMxnAsk = one] : one \in Sample(4) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.esBasisPointsAsk = one] : one \in Sample(4) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroEffectiveSpreadMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Spread Quality Message: 21 bytes                                        *)
(***************************************************************************)

SpreadQualityMessage ==
    [ origin                : Sample(1),
      timeBestSpread        : Sample(4),
      timeTieBestSpread     : Sample(4),
      timeWithoutBestSpread : Sample(4),
      market                : Sample(1),
      sector                : Sample(1),
      instrumentNumber      : Sample(4),
      indices               : Sample(2) ]

EncodeSpreadQualityMessage(message) ==
    message.origin
        \o message.timeBestSpread
        \o message.timeTieBestSpread
        \o message.timeWithoutBestSpread
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodeSpreadQualityMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET timeBestSpread == ReadBytes(origin.rest, 4) IN IF ~timeBestSpread.ok THEN Fail ELSE
    LET timeTieBestSpread == ReadBytes(timeBestSpread.rest, 4) IN IF ~timeTieBestSpread.ok THEN Fail ELSE
    LET timeWithoutBestSpread == ReadBytes(timeTieBestSpread.rest, 4) IN IF ~timeWithoutBestSpread.ok THEN Fail ELSE
    LET market == ReadBytes(timeWithoutBestSpread.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin                |-> origin.value,
         timeBestSpread        |-> timeBestSpread.value,
         timeTieBestSpread     |-> timeTieBestSpread.value,
         timeWithoutBestSpread |-> timeWithoutBestSpread.value,
         market                |-> market.value,
         sector                |-> sector.value,
         instrumentNumber      |-> instrumentNumber.value,
         indices               |-> indices.value ], indices.rest)

ZeroSpreadQualityMessage ==
    [ origin                |-> [i \in 1 .. 1 |-> 0],
      timeBestSpread        |-> [i \in 1 .. 4 |-> 0],
      timeTieBestSpread     |-> [i \in 1 .. 4 |-> 0],
      timeWithoutBestSpread |-> [i \in 1 .. 4 |-> 0],
      market                |-> [i \in 1 .. 1 |-> 0],
      sector                |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber      |-> [i \in 1 .. 4 |-> 0],
      indices               |-> [i \in 1 .. 2 |-> 0] ]

(* Spread Quality Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadQualityMessage ==
    { ZeroSpreadQualityMessage }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.timeBestSpread = one] : one \in Sample(4) }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.timeTieBestSpread = one] : one \in Sample(4) }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.timeWithoutBestSpread = one] : one \in Sample(4) }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadQualityMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Spread Message: 25 bytes                                                *)
(***************************************************************************)

SpreadMessage ==
    [ origin            : Sample(1),
      spreadMxn         : Sample(4),
      spreadBasisPoints : Sample(4),
      spreadAverage     : Sample(4),
      numberOfSpreads   : Sample(4),
      market            : Sample(1),
      sector            : Sample(1),
      instrumentNumber  : Sample(4),
      indices           : Sample(2) ]

EncodeSpreadMessage(message) ==
    message.origin
        \o message.spreadMxn
        \o message.spreadBasisPoints
        \o message.spreadAverage
        \o message.numberOfSpreads
        \o message.market
        \o message.sector
        \o message.instrumentNumber
        \o message.indices

DecodeSpreadMessage(bytes) ==
    LET origin == ReadBytes(bytes, 1) IN IF ~origin.ok THEN Fail ELSE
    LET spreadMxn == ReadBytes(origin.rest, 4) IN IF ~spreadMxn.ok THEN Fail ELSE
    LET spreadBasisPoints == ReadBytes(spreadMxn.rest, 4) IN IF ~spreadBasisPoints.ok THEN Fail ELSE
    LET spreadAverage == ReadBytes(spreadBasisPoints.rest, 4) IN IF ~spreadAverage.ok THEN Fail ELSE
    LET numberOfSpreads == ReadBytes(spreadAverage.rest, 4) IN IF ~numberOfSpreads.ok THEN Fail ELSE
    LET market == ReadBytes(numberOfSpreads.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET sector == ReadBytes(market.rest, 1) IN IF ~sector.ok THEN Fail ELSE
    LET instrumentNumber == ReadBytes(sector.rest, 4) IN IF ~instrumentNumber.ok THEN Fail ELSE
    LET indices == ReadBytes(instrumentNumber.rest, 2) IN IF ~indices.ok THEN Fail ELSE
    Ok([ origin            |-> origin.value,
         spreadMxn         |-> spreadMxn.value,
         spreadBasisPoints |-> spreadBasisPoints.value,
         spreadAverage     |-> spreadAverage.value,
         numberOfSpreads   |-> numberOfSpreads.value,
         market            |-> market.value,
         sector            |-> sector.value,
         instrumentNumber  |-> instrumentNumber.value,
         indices           |-> indices.value ], indices.rest)

ZeroSpreadMessage ==
    [ origin            |-> [i \in 1 .. 1 |-> 0],
      spreadMxn         |-> [i \in 1 .. 4 |-> 0],
      spreadBasisPoints |-> [i \in 1 .. 4 |-> 0],
      spreadAverage     |-> [i \in 1 .. 4 |-> 0],
      numberOfSpreads   |-> [i \in 1 .. 4 |-> 0],
      market            |-> [i \in 1 .. 1 |-> 0],
      sector            |-> [i \in 1 .. 1 |-> 0],
      instrumentNumber  |-> [i \in 1 .. 4 |-> 0],
      indices           |-> [i \in 1 .. 2 |-> 0] ]

(* Spread Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadMessage ==
    { ZeroSpreadMessage }
        \cup { [ZeroSpreadMessage EXCEPT !.origin = one] : one \in Sample(1) }
        \cup { [ZeroSpreadMessage EXCEPT !.spreadMxn = one] : one \in Sample(4) }
        \cup { [ZeroSpreadMessage EXCEPT !.spreadBasisPoints = one] : one \in Sample(4) }
        \cup { [ZeroSpreadMessage EXCEPT !.spreadAverage = one] : one \in Sample(4) }
        \cup { [ZeroSpreadMessage EXCEPT !.numberOfSpreads = one] : one \in Sample(4) }
        \cup { [ZeroSpreadMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroSpreadMessage EXCEPT !.sector = one] : one \in Sample(1) }
        \cup { [ZeroSpreadMessage EXCEPT !.instrumentNumber = one] : one \in Sample(4) }
        \cup { [ZeroSpreadMessage EXCEPT !.indices = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

BigPictureMessageCode == 39  \* 0x27
EffectiveSpreadMessageCode == 61  \* 0x3d
SpreadQualityMessageCode == 123  \* 0x7b
SpreadMessageCode == 59  \* 0x3b

Payload ==
    [ tag : {BigPictureMessageCode}, body : BigPictureMessage ]
        \cup [ tag : {EffectiveSpreadMessageCode}, body : EffectiveSpreadMessage ]
        \cup [ tag : {SpreadQualityMessageCode}, body : SpreadQualityMessage ]
        \cup [ tag : {SpreadMessageCode}, body : SpreadMessage ]

EncodePayload(message) ==
    CASE message.tag = BigPictureMessageCode -> EncodeBigPictureMessage(message.body)
      [] message.tag = EffectiveSpreadMessageCode -> EncodeEffectiveSpreadMessage(message.body)
      [] message.tag = SpreadQualityMessageCode -> EncodeSpreadQualityMessage(message.body)
      [] message.tag = SpreadMessageCode -> EncodeSpreadMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = BigPictureMessageCode -> DecodeBigPictureMessage(bytes)
              [] tag = EffectiveSpreadMessageCode -> DecodeEffectiveSpreadMessage(bytes)
              [] tag = SpreadQualityMessageCode -> DecodeSpreadQualityMessage(bytes)
              [] tag = SpreadMessageCode -> DecodeSpreadMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> BigPictureMessageCode, body |-> ZeroBigPictureMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> BigPictureMessageCode, body |-> one] : one \in CheckedBigPictureMessage }
        \cup { [tag |-> EffectiveSpreadMessageCode, body |-> one] : one \in CheckedEffectiveSpreadMessage }
        \cup { [tag |-> SpreadQualityMessageCode, body |-> one] : one \in CheckedSpreadQualityMessage }
        \cup { [tag |-> SpreadMessageCode, body |-> one] : one \in CheckedSpreadMessage }

(***************************************************************************)
(* Message Block, framed by Message Length                                 *)
(***************************************************************************)

MessageBlock ==
    [ payload : Payload ]

EncodeMessageBlockBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessageBlock(message) ==
    LET body == EncodeMessageBlockBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBlockBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessageBlock(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBlockBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessageBlock ==
    [ payload |-> ZeroPayload ]

(* Message Block at zero, then each field in turn at the values it is checked at *)
CheckedMessageBlock ==
    { ZeroMessageBlock }
        \cup { [ZeroMessageBlock EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message Block, written one after another *)
RECURSIVE EncodeMessageBlockList(_)
EncodeMessageBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessageBlock(Head(messages)) \o EncodeMessageBlockList(Tail(messages))

(* As many Message Block as the field that counts them says *)
RECURSIVE ReadMessageBlockList(_, _)
ReadMessageBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessageBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message Block of each kind, for the lists that carry them *)
OneMessageBlock ==
    { [ZeroMessageBlock EXCEPT !.payload = [tag |-> BigPictureMessageCode, body |-> ZeroBigPictureMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> EffectiveSpreadMessageCode, body |-> ZeroEffectiveSpreadMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> SpreadQualityMessageCode, body |-> ZeroSpreadQualityMessage]],
      [ZeroMessageBlock EXCEPT !.payload = [tag |-> SpreadMessageCode, body |-> ZeroSpreadMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      session         : Sample(1),
      sequenceNumber  : Sample(4),
      datetime        : Sample(8),
      messageBlock    : SampleLists(OneMessageBlock) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntBE(Len(message.messageBlock), 1)
        \o message.marketDataGroup
        \o message.session
        \o message.sequenceNumber
        \o message.datetime
        \o EncodeMessageBlockList(message.messageBlock)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET totalMessages == ReadUIntBE(length.rest, 1) IN IF ~totalMessages.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(totalMessages.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET session == ReadBytes(marketDataGroup.rest, 1) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET datetime == ReadBytes(sequenceNumber.rest, 8) IN IF ~datetime.ok THEN Fail ELSE
    LET messageBlock == ReadMessageBlockList(datetime.rest, totalMessages.value) IN IF ~messageBlock.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         session         |-> session.value,
         sequenceNumber  |-> sequenceNumber.value,
         datetime        |-> datetime.value,
         messageBlock    |-> messageBlock.value ], messageBlock.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      session         |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      datetime        |-> [i \in 1 .. 8 |-> 0],
      messageBlock    |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.datetime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messageBlock = one] : one \in SampleLists(OneMessageBlock) }

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

(* Every Big Picture Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBigPictureMessage ==
    \A message \in CheckedBigPictureMessage :
        LET read == DecodeBigPictureMessage(EncodeBigPictureMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Effective Spread Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEffectiveSpreadMessage ==
    \A message \in CheckedEffectiveSpreadMessage :
        LET read == DecodeEffectiveSpreadMessage(EncodeEffectiveSpreadMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Quality Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadQualityMessage ==
    \A message \in CheckedSpreadQualityMessage :
        LET read == DecodeSpreadQualityMessage(EncodeSpreadQualityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadMessage ==
    \A message \in CheckedSpreadMessage :
        LET read == DecodeSpreadMessage(EncodeSpreadMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Block decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET read == DecodeMessageBlock(EncodeMessageBlock(message))
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

(* Message Length is written from the bytes it frames *)
FramesMessageBlock ==
    \A message \in CheckedMessageBlock :
        LET bytes == EncodeMessageBlock(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
