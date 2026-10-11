------------------ MODULE BzxEquities_SummaryDepth_v1_0_4 ------------------
(***************************************************************************)
(* Chicago Board Options Exchange Summary Depth v1.0.4                     *)
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
(* Note: Adap Flags is a bit field set, checked as its 1 byte rather than  *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Trade Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
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
(* Clear Quote Message: 17 bytes                                           *)
(***************************************************************************)

ClearQuoteMessage ==
    [ lastUpdateTimestamp : Sample(8),
      symbol              : Sample(8),
      reserved1           : Sample(1) ]

EncodeClearQuoteMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbol
        \o message.reserved1

DecodeClearQuoteMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(symbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp |-> lastUpdateTimestamp.value,
         symbol              |-> symbol.value,
         reserved1           |-> reserved1.value ], reserved1.rest)

ZeroClearQuoteMessage ==
    [ lastUpdateTimestamp |-> [i \in 1 .. 8 |-> 0],
      symbol              |-> [i \in 1 .. 8 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0] ]

(* Clear Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedClearQuoteMessage ==
    { ZeroClearQuoteMessage }
        \cup { [ZeroClearQuoteMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroClearQuoteMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroClearQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Cboe Market Status Message: 11 bytes                                    *)
(***************************************************************************)

CboeMarketStatusMessage ==
    [ timestamp        : Sample(8),
      reserved1        : Sample(1),
      marketStatus     : Sample(1),
      sessionIndicator : Sample(1) ]

EncodeCboeMarketStatusMessage(message) ==
    message.timestamp
        \o message.reserved1
        \o message.marketStatus
        \o message.sessionIndicator

DecodeCboeMarketStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(timestamp.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET marketStatus == ReadBytes(reserved1.rest, 1) IN IF ~marketStatus.ok THEN Fail ELSE
    LET sessionIndicator == ReadBytes(marketStatus.rest, 1) IN IF ~sessionIndicator.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         reserved1        |-> reserved1.value,
         marketStatus     |-> marketStatus.value,
         sessionIndicator |-> sessionIndicator.value ], sessionIndicator.rest)

ZeroCboeMarketStatusMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      marketStatus     |-> [i \in 1 .. 1 |-> 0],
      sessionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Cboe Market Status Message at zero, then each field in turn at the values it is checked at *)
CheckedCboeMarketStatusMessage ==
    { ZeroCboeMarketStatusMessage }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.marketStatus = one] : one \in Sample(1) }
        \cup { [ZeroCboeMarketStatusMessage EXCEPT !.sessionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Short Update Adap Block: 9 bytes                                        *)
(***************************************************************************)

ShortUpdateAdapBlock ==
    [ side          : Sample(1),
      priceShort    : Sample(4),
      quantityShort : Sample(4) ]

EncodeShortUpdateAdapBlock(message) ==
    message.side
        \o message.priceShort
        \o message.quantityShort

DecodeShortUpdateAdapBlock(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceShort == ReadBytes(side.rest, 4) IN IF ~priceShort.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(priceShort.rest, 4) IN IF ~quantityShort.ok THEN Fail ELSE
    Ok([ side          |-> side.value,
         priceShort    |-> priceShort.value,
         quantityShort |-> quantityShort.value ], quantityShort.rest)

ZeroShortUpdateAdapBlock ==
    [ side          |-> [i \in 1 .. 1 |-> 0],
      priceShort    |-> [i \in 1 .. 4 |-> 0],
      quantityShort |-> [i \in 1 .. 4 |-> 0] ]

(* Short Update Adap Block at zero, then each field in turn at the values it is checked at *)
CheckedShortUpdateAdapBlock ==
    { ZeroShortUpdateAdapBlock }
        \cup { [ZeroShortUpdateAdapBlock EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroShortUpdateAdapBlock EXCEPT !.priceShort = one] : one \in Sample(4) }
        \cup { [ZeroShortUpdateAdapBlock EXCEPT !.quantityShort = one] : one \in Sample(4) }

(***************************************************************************)
(* Long Update Adap Block: 17 bytes                                        *)
(***************************************************************************)

LongUpdateAdapBlock ==
    [ side         : Sample(1),
      priceLong    : Sample(8),
      quantityLong : Sample(8) ]

EncodeLongUpdateAdapBlock(message) ==
    message.side
        \o message.priceLong
        \o message.quantityLong

DecodeLongUpdateAdapBlock(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceLong == ReadBytes(side.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(priceLong.rest, 8) IN IF ~quantityLong.ok THEN Fail ELSE
    Ok([ side         |-> side.value,
         priceLong    |-> priceLong.value,
         quantityLong |-> quantityLong.value ], quantityLong.rest)

ZeroLongUpdateAdapBlock ==
    [ side         |-> [i \in 1 .. 1 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0],
      quantityLong |-> [i \in 1 .. 8 |-> 0] ]

(* Long Update Adap Block at zero, then each field in turn at the values it is checked at *)
CheckedLongUpdateAdapBlock ==
    { ZeroLongUpdateAdapBlock }
        \cup { [ZeroLongUpdateAdapBlock EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroLongUpdateAdapBlock EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroLongUpdateAdapBlock EXCEPT !.quantityLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Adap Update, selected by Adap Block Size                                *)
(***************************************************************************)

ShortUpdateAdapBlockCode == 10  \* 0x0a
LongUpdateAdapBlockCode == 18  \* 0x12

AdapUpdate ==
    [ tag : {ShortUpdateAdapBlockCode}, body : ShortUpdateAdapBlock ]
        \cup [ tag : {LongUpdateAdapBlockCode}, body : LongUpdateAdapBlock ]

EncodeAdapUpdate(message) ==
    CASE message.tag = ShortUpdateAdapBlockCode -> EncodeShortUpdateAdapBlock(message.body)
      [] message.tag = LongUpdateAdapBlockCode -> EncodeLongUpdateAdapBlock(message.body)

DecodeAdapUpdate(tag, bytes) ==
    LET read ==
            CASE tag = ShortUpdateAdapBlockCode -> DecodeShortUpdateAdapBlock(bytes)
              [] tag = LongUpdateAdapBlockCode -> DecodeLongUpdateAdapBlock(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAdapUpdate == [tag |-> ShortUpdateAdapBlockCode, body |-> ZeroShortUpdateAdapBlock]

(* Each Adap Update in turn, at the values the message it names is checked at *)
CheckedAdapUpdate ==
    { [tag |-> ShortUpdateAdapBlockCode, body |-> one] : one \in CheckedShortUpdateAdapBlock }
        \cup { [tag |-> LongUpdateAdapBlockCode, body |-> one] : one \in CheckedLongUpdateAdapBlock }

(***************************************************************************)
(* Adap Block                                                              *)
(***************************************************************************)

AdapBlock ==
    [ adapUpdate : AdapUpdate ]

EncodeAdapBlock(message) ==
    EncodeUIntLE(message.adapUpdate.tag, 1)
        \o EncodeAdapUpdate(message.adapUpdate)

DecodeAdapBlock(bytes) ==
    LET adapBlockSize == ReadUIntLE(bytes, 1) IN IF ~adapBlockSize.ok THEN Fail ELSE
    LET adapUpdate == DecodeAdapUpdate(adapBlockSize.value, adapBlockSize.rest) IN IF ~adapUpdate.ok THEN Fail ELSE
    Ok([ adapUpdate |-> adapUpdate.value ], adapUpdate.rest)

ZeroAdapBlock ==
    [ adapUpdate |-> ZeroAdapUpdate ]

(* Adap Block at zero, then each field in turn at the values it is checked at *)
CheckedAdapBlock ==
    { ZeroAdapBlock }
        \cup { [ZeroAdapBlock EXCEPT !.adapUpdate = one] : one \in CheckedAdapUpdate }

(* A run of Adap Block, written one after another *)
RECURSIVE EncodeAdapBlockList(_)
EncodeAdapBlockList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAdapBlock(Head(messages)) \o EncodeAdapBlockList(Tail(messages))

(* As many Adap Block as the field that counts them says *)
RECURSIVE ReadAdapBlockList(_, _)
ReadAdapBlockList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAdapBlock(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAdapBlockList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Adap Block of each kind, for the lists that carry them *)
OneAdapBlock ==
    { [ZeroAdapBlock EXCEPT !.adapUpdate = [tag |-> ShortUpdateAdapBlockCode, body |-> ZeroShortUpdateAdapBlock]],
      [ZeroAdapBlock EXCEPT !.adapUpdate = [tag |-> LongUpdateAdapBlockCode, body |-> ZeroLongUpdateAdapBlock]] }

(***************************************************************************)
(* Adap Message                                                            *)
(***************************************************************************)

AdapMessage ==
    [ lastUpdateTimestamp : Sample(8),
      symbol              : Sample(8),
      adapFlags           : Sample(1),
      reserved1           : Sample(1),
      adapBlock           : SampleLists(OneAdapBlock) ]

EncodeAdapMessage(message) ==
    message.lastUpdateTimestamp
        \o message.symbol
        \o message.adapFlags
        \o message.reserved1
        \o EncodeUIntLE(Len(message.adapBlock), 1)
        \o EncodeAdapBlockList(message.adapBlock)

DecodeAdapMessage(bytes) ==
    LET lastUpdateTimestamp == ReadBytes(bytes, 8) IN IF ~lastUpdateTimestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastUpdateTimestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET adapFlags == ReadBytes(symbol.rest, 1) IN IF ~adapFlags.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(adapFlags.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET adapBlocks == ReadUIntLE(reserved1.rest, 1) IN IF ~adapBlocks.ok THEN Fail ELSE
    LET adapBlock == ReadAdapBlockList(adapBlocks.rest, adapBlocks.value) IN IF ~adapBlock.ok THEN Fail ELSE
    Ok([ lastUpdateTimestamp |-> lastUpdateTimestamp.value,
         symbol              |-> symbol.value,
         adapFlags           |-> adapFlags.value,
         reserved1           |-> reserved1.value,
         adapBlock           |-> adapBlock.value ], adapBlock.rest)

ZeroAdapMessage ==
    [ lastUpdateTimestamp |-> [i \in 1 .. 8 |-> 0],
      symbol              |-> [i \in 1 .. 8 |-> 0],
      adapFlags           |-> [i \in 1 .. 1 |-> 0],
      reserved1           |-> [i \in 1 .. 1 |-> 0],
      adapBlock           |-> << >> ]

(* Adap Message at zero, then each field in turn at the values it is checked at *)
CheckedAdapMessage ==
    { ZeroAdapMessage }
        \cup { [ZeroAdapMessage EXCEPT !.lastUpdateTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroAdapMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroAdapMessage EXCEPT !.adapFlags = one] : one \in Sample(1) }
        \cup { [ZeroAdapMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroAdapMessage EXCEPT !.adapBlock = one] : one \in SampleLists(OneAdapBlock) }

(***************************************************************************)
(* Rpi Message: 18 bytes                                                   *)
(***************************************************************************)

RpiMessage ==
    [ timestamp              : Sample(8),
      symbol                 : Sample(8),
      reserved1              : Sample(1),
      retailPriceImprovement : Sample(1) ]

EncodeRpiMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.reserved1
        \o message.retailPriceImprovement

DecodeRpiMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(symbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET retailPriceImprovement == ReadBytes(reserved1.rest, 1) IN IF ~retailPriceImprovement.ok THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         symbol                 |-> symbol.value,
         reserved1              |-> reserved1.value,
         retailPriceImprovement |-> retailPriceImprovement.value ], retailPriceImprovement.rest)

ZeroRpiMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0],
      retailPriceImprovement |-> [i \in 1 .. 1 |-> 0] ]

(* Rpi Message at zero, then each field in turn at the values it is checked at *)
CheckedRpiMessage ==
    { ZeroRpiMessage }
        \cup { [ZeroRpiMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRpiMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroRpiMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroRpiMessage EXCEPT !.retailPriceImprovement = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 58 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ transactionTime              : Sample(8),
      symbol                       : Sample(8),
      reserved1                    : Sample(1),
      executionId                  : Sample(8),
      lastPrice                    : Sample(8),
      lastQuantity                 : Sample(8),
      cboeCumulativeExecutedVolume : Sample(8),
      reserved8                    : Sample(8),
      tradeFlags                   : Sample(1) ]

EncodeTradeMessage(message) ==
    message.transactionTime
        \o message.symbol
        \o message.reserved1
        \o message.executionId
        \o message.lastPrice
        \o message.lastQuantity
        \o message.cboeCumulativeExecutedVolume
        \o message.reserved8
        \o message.tradeFlags

DecodeTradeMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbol == ReadBytes(transactionTime.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(symbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET executionId == ReadBytes(reserved1.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(executionId.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastQuantity == ReadBytes(lastPrice.rest, 8) IN IF ~lastQuantity.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(lastQuantity.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(reserved8.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ transactionTime              |-> transactionTime.value,
         symbol                       |-> symbol.value,
         reserved1                    |-> reserved1.value,
         executionId                  |-> executionId.value,
         lastPrice                    |-> lastPrice.value,
         lastQuantity                 |-> lastQuantity.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         reserved8                    |-> reserved8.value,
         tradeFlags                   |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeMessage ==
    [ transactionTime              |-> [i \in 1 .. 8 |-> 0],
      symbol                       |-> [i \in 1 .. 8 |-> 0],
      reserved1                    |-> [i \in 1 .. 1 |-> 0],
      executionId                  |-> [i \in 1 .. 8 |-> 0],
      lastPrice                    |-> [i \in 1 .. 8 |-> 0],
      lastQuantity                 |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      reserved8                    |-> [i \in 1 .. 8 |-> 0],
      tradeFlags                   |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.lastQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Break Message: 42 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ transactionTime              : Sample(8),
      symbol                       : Sample(8),
      reserved1                    : Sample(1),
      executionId                  : Sample(8),
      cboeCumulativeExecutedVolume : Sample(8),
      reserved8                    : Sample(8),
      tradeBreakFlags              : Sample(1) ]

EncodeTradeBreakMessage(message) ==
    message.transactionTime
        \o message.symbol
        \o message.reserved1
        \o message.executionId
        \o message.cboeCumulativeExecutedVolume
        \o message.reserved8
        \o message.tradeBreakFlags

DecodeTradeBreakMessage(bytes) ==
    LET transactionTime == ReadBytes(bytes, 8) IN IF ~transactionTime.ok THEN Fail ELSE
    LET symbol == ReadBytes(transactionTime.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(symbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET executionId == ReadBytes(reserved1.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET cboeCumulativeExecutedVolume == ReadBytes(executionId.rest, 8) IN IF ~cboeCumulativeExecutedVolume.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(cboeCumulativeExecutedVolume.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET tradeBreakFlags == ReadBytes(reserved8.rest, 1) IN IF ~tradeBreakFlags.ok THEN Fail ELSE
    Ok([ transactionTime              |-> transactionTime.value,
         symbol                       |-> symbol.value,
         reserved1                    |-> reserved1.value,
         executionId                  |-> executionId.value,
         cboeCumulativeExecutedVolume |-> cboeCumulativeExecutedVolume.value,
         reserved8                    |-> reserved8.value,
         tradeBreakFlags              |-> tradeBreakFlags.value ], tradeBreakFlags.rest)

ZeroTradeBreakMessage ==
    [ transactionTime              |-> [i \in 1 .. 8 |-> 0],
      symbol                       |-> [i \in 1 .. 8 |-> 0],
      reserved1                    |-> [i \in 1 .. 1 |-> 0],
      executionId                  |-> [i \in 1 .. 8 |-> 0],
      cboeCumulativeExecutedVolume |-> [i \in 1 .. 8 |-> 0],
      reserved8                    |-> [i \in 1 .. 8 |-> 0],
      tradeBreakFlags              |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.transactionTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.cboeCumulativeExecutedVolume = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.tradeBreakFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Status Message: 19 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timestamp    : Sample(8),
      symbol       : Sample(8),
      reserved1    : Sample(1),
      haltStatus   : Sample(1),
      regShoAction : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.reserved1
        \o message.haltStatus
        \o message.regShoAction

DecodeTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(symbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET haltStatus == ReadBytes(reserved1.rest, 1) IN IF ~haltStatus.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(haltStatus.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         symbol       |-> symbol.value,
         reserved1    |-> reserved1.value,
         haltStatus   |-> haltStatus.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroTradingStatusMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> [i \in 1 .. 8 |-> 0],
      reserved1    |-> [i \in 1 .. 1 |-> 0],
      haltStatus   |-> [i \in 1 .. 1 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.haltStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

ClearQuoteMessageCode == 162  \* 0xa2
CboeMarketStatusMessageCode == 166  \* 0xa6
AdapMessageCode == 167  \* 0xa7
RpiMessageCode == 168  \* 0xa8
TradeMessageCode == 169  \* 0xa9
TradeBreakMessageCode == 170  \* 0xaa
TradingStatusMessageCode == 171  \* 0xab

Payload ==
    [ tag : {ClearQuoteMessageCode}, body : ClearQuoteMessage ]
        \cup [ tag : {CboeMarketStatusMessageCode}, body : CboeMarketStatusMessage ]
        \cup [ tag : {AdapMessageCode}, body : AdapMessage ]
        \cup [ tag : {RpiMessageCode}, body : RpiMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = ClearQuoteMessageCode -> EncodeClearQuoteMessage(message.body)
      [] message.tag = CboeMarketStatusMessageCode -> EncodeCboeMarketStatusMessage(message.body)
      [] message.tag = AdapMessageCode -> EncodeAdapMessage(message.body)
      [] message.tag = RpiMessageCode -> EncodeRpiMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = ClearQuoteMessageCode -> DecodeClearQuoteMessage(bytes)
              [] tag = CboeMarketStatusMessageCode -> DecodeCboeMarketStatusMessage(bytes)
              [] tag = AdapMessageCode -> DecodeAdapMessage(bytes)
              [] tag = RpiMessageCode -> DecodeRpiMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ClearQuoteMessageCode, body |-> ZeroClearQuoteMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ClearQuoteMessageCode, body |-> one] : one \in CheckedClearQuoteMessage }
        \cup { [tag |-> CboeMarketStatusMessageCode, body |-> one] : one \in CheckedCboeMarketStatusMessage }
        \cup { [tag |-> AdapMessageCode, body |-> one] : one \in CheckedAdapMessage }
        \cup { [tag |-> RpiMessageCode, body |-> one] : one \in CheckedRpiMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> ClearQuoteMessageCode, body |-> ZeroClearQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CboeMarketStatusMessageCode, body |-> ZeroCboeMarketStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdapMessageCode, body |-> ZeroAdapMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RpiMessageCode, body |-> ZeroRpiMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Clear Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearQuoteMessage ==
    \A message \in CheckedClearQuoteMessage :
        LET read == DecodeClearQuoteMessage(EncodeClearQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cboe Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCboeMarketStatusMessage ==
    \A message \in CheckedCboeMarketStatusMessage :
        LET read == DecodeCboeMarketStatusMessage(EncodeCboeMarketStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Update Adap Block decodes back to what was encoded, and leaves nothing over *)
RoundTripShortUpdateAdapBlock ==
    \A message \in CheckedShortUpdateAdapBlock :
        LET read == DecodeShortUpdateAdapBlock(EncodeShortUpdateAdapBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Update Adap Block decodes back to what was encoded, and leaves nothing over *)
RoundTripLongUpdateAdapBlock ==
    \A message \in CheckedLongUpdateAdapBlock :
        LET read == DecodeLongUpdateAdapBlock(EncodeLongUpdateAdapBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Adap Block decodes back to what was encoded, and leaves nothing over *)
RoundTripAdapBlock ==
    \A message \in CheckedAdapBlock :
        LET read == DecodeAdapBlock(EncodeAdapBlock(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Adap Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdapMessage ==
    \A message \in CheckedAdapMessage :
        LET read == DecodeAdapMessage(EncodeAdapMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rpi Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRpiMessage ==
    \A message \in CheckedRpiMessage :
        LET read == DecodeRpiMessage(EncodeRpiMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
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

(* A Adap Update is selected by the Adap Block Size it is written under *)
SelectsAdapUpdate ==
    \A message \in CheckedAdapUpdate :
        LET read == DecodeAdapUpdate(message.tag, EncodeAdapUpdate(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
