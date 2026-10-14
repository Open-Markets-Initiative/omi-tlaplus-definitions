------------------ MODULE Cme_Globex_Streamlined_v5_9_Udp ------------------
(***************************************************************************)
(* CME Group Streamlined Market Data v5.9                                  *)
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
(*                                                                         *)
(* Note: Settl Price Type is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
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
(* Admin Login: 1 bytes                                                    *)
(***************************************************************************)

AdminLogin ==
    [ heartBtInt : Sample(1) ]

EncodeAdminLogin(message) ==
    message.heartBtInt

DecodeAdminLogin(bytes) ==
    LET heartBtInt == ReadBytes(bytes, 1) IN IF ~heartBtInt.ok THEN Fail ELSE
    Ok([ heartBtInt |-> heartBtInt.value ], heartBtInt.rest)

ZeroAdminLogin ==
    [ heartBtInt |-> [i \in 1 .. 1 |-> 0] ]

(* Admin Login at zero, then each field in turn at the values it is checked at *)
CheckedAdminLogin ==
    { ZeroAdminLogin }
        \cup { [ZeroAdminLogin EXCEPT !.heartBtInt = one] : one \in Sample(1) }

(***************************************************************************)
(* Admin Logout: 180 bytes                                                 *)
(***************************************************************************)

AdminLogout ==
    [ text : Sample(180) ]

EncodeAdminLogout(message) ==
    message.text

DecodeAdminLogout(bytes) ==
    LET text == ReadBytes(bytes, 180) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroAdminLogout ==
    [ text |-> [i \in 1 .. 180 |-> 0] ]

(* Admin Logout at zero, then each field in turn at the values it is checked at *)
CheckedAdminLogout ==
    { ZeroAdminLogout }
        \cup { [ZeroAdminLogout EXCEPT !.text = one] : one \in Sample(180) }

(***************************************************************************)
(* Md Entry Px Decimal Optional: 9 bytes                                   *)
(***************************************************************************)

MdEntryPxDecimalOptional ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeMdEntryPxDecimalOptional(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeMdEntryPxDecimalOptional(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroMdEntryPxDecimalOptional ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Px Decimal Optional at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPxDecimalOptional ==
    { ZeroMdEntryPxDecimalOptional }
        \cup { [ZeroMdEntryPxDecimalOptional EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntryPxDecimalOptional EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Cal Fut Px Optional: 9 bytes                                            *)
(***************************************************************************)

CalFutPxOptional ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeCalFutPxOptional(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeCalFutPxOptional(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroCalFutPxOptional ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Cal Fut Px Optional at zero, then each field in turn at the values it is checked at *)
CheckedCalFutPxOptional ==
    { ZeroCalFutPxOptional }
        \cup { [ZeroCalFutPxOptional EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroCalFutPxOptional EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Coupon Rate Optional: 5 bytes                                           *)
(***************************************************************************)

CouponRateOptional ==
    [ mantissa32       : Sample(4),
      exponentOptional : Sample(1) ]

EncodeCouponRateOptional(message) ==
    message.mantissa32
        \o message.exponentOptional

DecodeCouponRateOptional(bytes) ==
    LET mantissa32 == ReadBytes(bytes, 4) IN IF ~mantissa32.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa32.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa32       |-> mantissa32.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroCouponRateOptional ==
    [ mantissa32       |-> [i \in 1 .. 4 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Coupon Rate Optional at zero, then each field in turn at the values it is checked at *)
CheckedCouponRateOptional ==
    { ZeroCouponRateOptional }
        \cup { [ZeroCouponRateOptional EXCEPT !.mantissa32 = one] : one \in Sample(4) }
        \cup { [ZeroCouponRateOptional EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Fair Coupon Pct: 9 bytes                                                *)
(***************************************************************************)

FairCouponPct ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeFairCouponPct(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeFairCouponPct(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroFairCouponPct ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Fair Coupon Pct at zero, then each field in turn at the values it is checked at *)
CheckedFairCouponPct ==
    { ZeroFairCouponPct }
        \cup { [ZeroFairCouponPct EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFairCouponPct EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Purchase Rate: 9 bytes                                              *)
(***************************************************************************)

LegPurchaseRate ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeLegPurchaseRate(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeLegPurchaseRate(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroLegPurchaseRate ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Purchase Rate at zero, then each field in turn at the values it is checked at *)
CheckedLegPurchaseRate ==
    { ZeroLegPurchaseRate }
        \cup { [ZeroLegPurchaseRate EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroLegPurchaseRate EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Fixed Npv: 9 bytes                                                      *)
(***************************************************************************)

FixedNpv ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeFixedNpv(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeFixedNpv(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroFixedNpv ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Fixed Npv at zero, then each field in turn at the values it is checked at *)
CheckedFixedNpv ==
    { ZeroFixedNpv }
        \cup { [ZeroFixedNpv EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFixedNpv EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Float Npv: 9 bytes                                                      *)
(***************************************************************************)

FloatNpv ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeFloatNpv(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeFloatNpv(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroFloatNpv ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Float Npv at zero, then each field in turn at the values it is checked at *)
CheckedFloatNpv ==
    { ZeroFloatNpv }
        \cup { [ZeroFloatNpv EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFloatNpv EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Npv: 9 bytes                                                            *)
(***************************************************************************)

Npv ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeNpv(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeNpv(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroNpv ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Npv at zero, then each field in turn at the values it is checked at *)
CheckedNpv ==
    { ZeroNpv }
        \cup { [ZeroNpv EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroNpv EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Accrued Coupons: 9 bytes                                                *)
(***************************************************************************)

AccruedCoupons ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeAccruedCoupons(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeAccruedCoupons(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroAccruedCoupons ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Accrued Coupons at zero, then each field in turn at the values it is checked at *)
CheckedAccruedCoupons ==
    { ZeroAccruedCoupons }
        \cup { [ZeroAccruedCoupons EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroAccruedCoupons EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Daily Incremental Eris Pai: 9 bytes                                     *)
(***************************************************************************)

DailyIncrementalErisPai ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeDailyIncrementalErisPai(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeDailyIncrementalErisPai(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroDailyIncrementalErisPai ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Daily Incremental Eris Pai at zero, then each field in turn at the values it is checked at *)
CheckedDailyIncrementalErisPai ==
    { ZeroDailyIncrementalErisPai }
        \cup { [ZeroDailyIncrementalErisPai EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroDailyIncrementalErisPai EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Eris Pai: 9 bytes                                                       *)
(***************************************************************************)

ErisPai ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeErisPai(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeErisPai(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroErisPai ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Eris Pai at zero, then each field in turn at the values it is checked at *)
CheckedErisPai ==
    { ZeroErisPai }
        \cup { [ZeroErisPai EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroErisPai EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Fed Funds Rate: 9 bytes                                                 *)
(***************************************************************************)

FedFundsRate ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeFedFundsRate(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeFedFundsRate(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroFedFundsRate ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Fed Funds Rate at zero, then each field in turn at the values it is checked at *)
CheckedFedFundsRate ==
    { ZeroFedFundsRate }
        \cup { [ZeroFedFundsRate EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFedFundsRate EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Price Increment Optional: 9 bytes                                   *)
(***************************************************************************)

MinPriceIncrementOptional ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeMinPriceIncrementOptional(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeMinPriceIncrementOptional(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroMinPriceIncrementOptional ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Min Price Increment Optional at zero, then each field in turn at the values it is checked at *)
CheckedMinPriceIncrementOptional ==
    { ZeroMinPriceIncrementOptional }
        \cup { [ZeroMinPriceIncrementOptional EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMinPriceIncrementOptional EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Fixed Payment: 9 bytes                                                  *)
(***************************************************************************)

FixedPayment ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeFixedPayment(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeFixedPayment(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroFixedPayment ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Fixed Payment at zero, then each field in turn at the values it is checked at *)
CheckedFixedPayment ==
    { ZeroFixedPayment }
        \cup { [ZeroFixedPayment EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFixedPayment EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Floating Payment: 9 bytes                                               *)
(***************************************************************************)

FloatingPayment ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeFloatingPayment(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeFloatingPayment(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroFloatingPayment ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Floating Payment at zero, then each field in turn at the values it is checked at *)
CheckedFloatingPayment ==
    { ZeroFloatingPayment }
        \cup { [ZeroFloatingPayment EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFloatingPayment EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Next Fixed Payment Amount: 9 bytes                                      *)
(***************************************************************************)

NextFixedPaymentAmount ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeNextFixedPaymentAmount(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeNextFixedPaymentAmount(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroNextFixedPaymentAmount ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Next Fixed Payment Amount at zero, then each field in turn at the values it is checked at *)
CheckedNextFixedPaymentAmount ==
    { ZeroNextFixedPaymentAmount }
        \cup { [ZeroNextFixedPaymentAmount EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroNextFixedPaymentAmount EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Next Floating Payment Amount: 9 bytes                                   *)
(***************************************************************************)

NextFloatingPaymentAmount ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeNextFloatingPaymentAmount(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeNextFloatingPaymentAmount(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroNextFloatingPaymentAmount ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Next Floating Payment Amount at zero, then each field in turn at the values it is checked at *)
CheckedNextFloatingPaymentAmount ==
    { ZeroNextFloatingPaymentAmount }
        \cup { [ZeroNextFloatingPaymentAmount EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroNextFloatingPaymentAmount EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Previous Eris Pai: 9 bytes                                              *)
(***************************************************************************)

PreviousErisPai ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodePreviousErisPai(message) ==
    message.mantissa
        \o message.exponentOptional

DecodePreviousErisPai(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroPreviousErisPai ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Previous Eris Pai at zero, then each field in turn at the values it is checked at *)
CheckedPreviousErisPai ==
    { ZeroPreviousErisPai }
        \cup { [ZeroPreviousErisPai EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroPreviousErisPai EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Contract Multiplier: 9 bytes                                        *)
(***************************************************************************)

LegContractMultiplier ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeLegContractMultiplier(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeLegContractMultiplier(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroLegContractMultiplier ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Contract Multiplier at zero, then each field in turn at the values it is checked at *)
CheckedLegContractMultiplier ==
    { ZeroLegContractMultiplier }
        \cup { [ZeroLegContractMultiplier EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroLegContractMultiplier EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* P V 01: 9 bytes                                                         *)
(***************************************************************************)

PV01 ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodePV01(message) ==
    message.mantissa
        \o message.exponentOptional

DecodePV01(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroPV01 ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* P V 01 at zero, then each field in turn at the values it is checked at *)
CheckedPV01 ==
    { ZeroPV01 }
        \cup { [ZeroPV01 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroPV01 EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* D V 01: 9 bytes                                                         *)
(***************************************************************************)

DV01 ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeDV01(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeDV01(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroDV01 ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* D V 01 at zero, then each field in turn at the values it is checked at *)
CheckedDV01 ==
    { ZeroDV01 }
        \cup { [ZeroDV01 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroDV01 EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Settlement Npv: 9 bytes                                                 *)
(***************************************************************************)

SettlementNpv ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeSettlementNpv(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeSettlementNpv(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroSettlementNpv ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Settlement Npv at zero, then each field in turn at the values it is checked at *)
CheckedSettlementNpv ==
    { ZeroSettlementNpv }
        \cup { [ZeroSettlementNpv EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroSettlementNpv EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Final Settlement Futures Price: 9 bytes                                 *)
(***************************************************************************)

FinalSettlementFuturesPrice ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeFinalSettlementFuturesPrice(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeFinalSettlementFuturesPrice(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroFinalSettlementFuturesPrice ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Final Settlement Futures Price at zero, then each field in turn at the values it is checked at *)
CheckedFinalSettlementFuturesPrice ==
    { ZeroFinalSettlementFuturesPrice }
        \cup { [ZeroFinalSettlementFuturesPrice EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroFinalSettlementFuturesPrice EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Eris Security Alt Id Group: 27 bytes                                    *)
(***************************************************************************)

ErisSecurityAltIdGroup ==
    [ securityAltId50             : Sample(26),
      securityAltIdSourceOptional : Sample(1) ]

EncodeErisSecurityAltIdGroup(message) ==
    message.securityAltId50
        \o message.securityAltIdSourceOptional

DecodeErisSecurityAltIdGroup(bytes) ==
    LET securityAltId50 == ReadBytes(bytes, 26) IN IF ~securityAltId50.ok THEN Fail ELSE
    LET securityAltIdSourceOptional == ReadBytes(securityAltId50.rest, 1) IN IF ~securityAltIdSourceOptional.ok THEN Fail ELSE
    Ok([ securityAltId50             |-> securityAltId50.value,
         securityAltIdSourceOptional |-> securityAltIdSourceOptional.value ], securityAltIdSourceOptional.rest)

ZeroErisSecurityAltIdGroup ==
    [ securityAltId50             |-> [i \in 1 .. 26 |-> 0],
      securityAltIdSourceOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Eris Security Alt Id Group at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroup ==
    { ZeroErisSecurityAltIdGroup }
        \cup { [ZeroErisSecurityAltIdGroup EXCEPT !.securityAltId50 = one] : one \in Sample(26) }
        \cup { [ZeroErisSecurityAltIdGroup EXCEPT !.securityAltIdSourceOptional = one] : one \in Sample(1) }

(* A run of Eris Security Alt Id Group, written one after another *)
RECURSIVE EncodeErisSecurityAltIdGroupList(_)
EncodeErisSecurityAltIdGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisSecurityAltIdGroup(Head(messages)) \o EncodeErisSecurityAltIdGroupList(Tail(messages))

(* As many Eris Security Alt Id Group as the field that counts them says *)
RECURSIVE ReadErisSecurityAltIdGroupList(_, _)
ReadErisSecurityAltIdGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisSecurityAltIdGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisSecurityAltIdGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Security Alt Id Group of each kind, for the lists that carry them *)
OneErisSecurityAltIdGroup == { ZeroErisSecurityAltIdGroup }

(***************************************************************************)
(* Eris Security Alt Id Groups                                             *)
(***************************************************************************)

ErisSecurityAltIdGroups ==
    [ blockLength            : Sample(2),
      erisSecurityAltIdGroup : SampleLists(OneErisSecurityAltIdGroup) ]

EncodeErisSecurityAltIdGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisSecurityAltIdGroup), 1)
        \o EncodeErisSecurityAltIdGroupList(message.erisSecurityAltIdGroup)

DecodeErisSecurityAltIdGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisSecurityAltIdGroup == ReadErisSecurityAltIdGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~erisSecurityAltIdGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         erisSecurityAltIdGroup |-> erisSecurityAltIdGroup.value ], erisSecurityAltIdGroup.rest)

ZeroErisSecurityAltIdGroups ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      erisSecurityAltIdGroup |-> << >> ]

(* Eris Security Alt Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroups ==
    { ZeroErisSecurityAltIdGroups }
        \cup { [ZeroErisSecurityAltIdGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisSecurityAltIdGroups EXCEPT !.erisSecurityAltIdGroup = one] : one \in SampleLists(OneErisSecurityAltIdGroup) }

(***************************************************************************)
(* Incremental Refresh Eris Related Instruments Group: 77 bytes            *)
(***************************************************************************)

IncrementalRefreshErisRelatedInstrumentsGroup ==
    [ relatedInstrumentType : Sample(1),
      relatedSymbol         : Sample(50),
      relatedSecurityGroup  : Sample(26) ]

EncodeIncrementalRefreshErisRelatedInstrumentsGroup(message) ==
    message.relatedInstrumentType
        \o message.relatedSymbol
        \o message.relatedSecurityGroup

DecodeIncrementalRefreshErisRelatedInstrumentsGroup(bytes) ==
    LET relatedInstrumentType == ReadBytes(bytes, 1) IN IF ~relatedInstrumentType.ok THEN Fail ELSE
    LET relatedSymbol == ReadBytes(relatedInstrumentType.rest, 50) IN IF ~relatedSymbol.ok THEN Fail ELSE
    LET relatedSecurityGroup == ReadBytes(relatedSymbol.rest, 26) IN IF ~relatedSecurityGroup.ok THEN Fail ELSE
    Ok([ relatedInstrumentType |-> relatedInstrumentType.value,
         relatedSymbol         |-> relatedSymbol.value,
         relatedSecurityGroup  |-> relatedSecurityGroup.value ], relatedSecurityGroup.rest)

ZeroIncrementalRefreshErisRelatedInstrumentsGroup ==
    [ relatedInstrumentType |-> [i \in 1 .. 1 |-> 0],
      relatedSymbol         |-> [i \in 1 .. 50 |-> 0],
      relatedSecurityGroup  |-> [i \in 1 .. 26 |-> 0] ]

(* Incremental Refresh Eris Related Instruments Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshErisRelatedInstrumentsGroup ==
    { ZeroIncrementalRefreshErisRelatedInstrumentsGroup }
        \cup { [ZeroIncrementalRefreshErisRelatedInstrumentsGroup EXCEPT !.relatedInstrumentType = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshErisRelatedInstrumentsGroup EXCEPT !.relatedSymbol = one] : one \in Sample(50) }
        \cup { [ZeroIncrementalRefreshErisRelatedInstrumentsGroup EXCEPT !.relatedSecurityGroup = one] : one \in Sample(26) }

(* A run of Incremental Refresh Eris Related Instruments Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshErisRelatedInstrumentsGroupList(_)
EncodeIncrementalRefreshErisRelatedInstrumentsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshErisRelatedInstrumentsGroup(Head(messages)) \o EncodeIncrementalRefreshErisRelatedInstrumentsGroupList(Tail(messages))

(* As many Incremental Refresh Eris Related Instruments Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshErisRelatedInstrumentsGroupList(_, _)
ReadIncrementalRefreshErisRelatedInstrumentsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshErisRelatedInstrumentsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshErisRelatedInstrumentsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Eris Related Instruments Group of each kind, for the lists that carry them *)
OneIncrementalRefreshErisRelatedInstrumentsGroup == { ZeroIncrementalRefreshErisRelatedInstrumentsGroup }

(***************************************************************************)
(* Incremental Refresh Eris Related Instruments Groups                     *)
(***************************************************************************)

IncrementalRefreshErisRelatedInstrumentsGroups ==
    [ blockLength                                   : Sample(2),
      incrementalRefreshErisRelatedInstrumentsGroup : SampleLists(OneIncrementalRefreshErisRelatedInstrumentsGroup) ]

EncodeIncrementalRefreshErisRelatedInstrumentsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshErisRelatedInstrumentsGroup), 1)
        \o EncodeIncrementalRefreshErisRelatedInstrumentsGroupList(message.incrementalRefreshErisRelatedInstrumentsGroup)

DecodeIncrementalRefreshErisRelatedInstrumentsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET incrementalRefreshErisRelatedInstrumentsGroup == ReadIncrementalRefreshErisRelatedInstrumentsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~incrementalRefreshErisRelatedInstrumentsGroup.ok THEN Fail ELSE
    Ok([ blockLength                                   |-> blockLength.value,
         incrementalRefreshErisRelatedInstrumentsGroup |-> incrementalRefreshErisRelatedInstrumentsGroup.value ], incrementalRefreshErisRelatedInstrumentsGroup.rest)

ZeroIncrementalRefreshErisRelatedInstrumentsGroups ==
    [ blockLength                                   |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshErisRelatedInstrumentsGroup |-> << >> ]

(* Incremental Refresh Eris Related Instruments Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshErisRelatedInstrumentsGroups ==
    { ZeroIncrementalRefreshErisRelatedInstrumentsGroups }
        \cup { [ZeroIncrementalRefreshErisRelatedInstrumentsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshErisRelatedInstrumentsGroups EXCEPT !.incrementalRefreshErisRelatedInstrumentsGroup = one] : one \in SampleLists(OneIncrementalRefreshErisRelatedInstrumentsGroup) }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup ==
    [ eventTypeOptional : Sample(1),
      eventTimeOptional : Sample(8) ]

EncodeEventsGroup(message) ==
    message.eventTypeOptional
        \o message.eventTimeOptional

DecodeEventsGroup(bytes) ==
    LET eventTypeOptional == ReadBytes(bytes, 1) IN IF ~eventTypeOptional.ok THEN Fail ELSE
    LET eventTimeOptional == ReadBytes(eventTypeOptional.rest, 8) IN IF ~eventTimeOptional.ok THEN Fail ELSE
    Ok([ eventTypeOptional |-> eventTypeOptional.value,
         eventTimeOptional |-> eventTimeOptional.value ], eventTimeOptional.rest)

ZeroEventsGroup ==
    [ eventTypeOptional |-> [i \in 1 .. 1 |-> 0],
      eventTimeOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup ==
    { ZeroEventsGroup }
        \cup { [ZeroEventsGroup EXCEPT !.eventTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup EXCEPT !.eventTimeOptional = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroupList(_)
EncodeEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup(Head(messages)) \o EncodeEventsGroupList(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroupList(_, _)
ReadEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup == { ZeroEventsGroup }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup) ]

EncodeEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroupList(message.eventsGroup)

DecodeEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups ==
    { ZeroEventsGroups }
        \cup { [ZeroEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup) }

(***************************************************************************)
(* Eris Reference Data Group                                               *)
(***************************************************************************)

ErisReferenceDataGroup ==
    [ mdUpdateActionChar                             : Sample(1),
      mdEntryType                                    : Sample(1),
      rptSeq                                         : Sample(4),
      mdEntryPxDecimalOptional                       : MdEntryPxDecimalOptional,
      openCloseSettlFlag                             : Sample(1),
      settlPriceType                                 : Sample(1),
      calFutPxOptional                               : CalFutPxOptional,
      referenceId50                                  : Sample(50),
      mdEntrySizeOptional                            : Sample(8),
      symbol                                         : Sample(50),
      securityGroup26                                : Sample(26),
      productOptional                                : Sample(1),
      securityType                                   : Sample(9),
      securityExchange                               : Sample(4),
      maturityDate                                   : Sample(2),
      couponRateOptional                             : CouponRateOptional,
      tradeDate                                      : Sample(2),
      fairCouponPct                                  : FairCouponPct,
      legPurchaseRate                                : LegPurchaseRate,
      fixedNpv                                       : FixedNpv,
      floatNpv                                       : FloatNpv,
      npv                                            : Npv,
      accruedCoupons                                 : AccruedCoupons,
      dailyIncrementalErisPai                        : DailyIncrementalErisPai,
      erisPai                                        : ErisPai,
      fedFundsRate                                   : FedFundsRate,
      minPriceIncrementOptional                      : MinPriceIncrementOptional,
      fixedPayment                                   : FixedPayment,
      floatingPayment                                : FloatingPayment,
      nextFixedPaymentDate                           : Sample(2),
      nextFixedPaymentAmount                         : NextFixedPaymentAmount,
      nextFloatingPaymentAmount                      : NextFloatingPaymentAmount,
      tradingReferenceDate                           : Sample(2),
      previousErisPai                                : PreviousErisPai,
      fedFundsDate                                   : Sample(2),
      accrualDays                                    : Sample(4),
      nominal                                        : Sample(8),
      legCreditRating                                : Sample(6),
      legContractMultiplier                          : LegContractMultiplier,
      nextFloatingPaymentDate                        : Sample(2),
      pV01                                           : PV01,
      dV01                                           : DV01,
      settlementNpv                                  : SettlementNpv,
      finalSettlementFuturesPrice                    : FinalSettlementFuturesPrice,
      securityDescription                            : Sample(30),
      erisSecurityAltIdGroups                        : ErisSecurityAltIdGroups,
      incrementalRefreshErisRelatedInstrumentsGroups : IncrementalRefreshErisRelatedInstrumentsGroups,
      eventsGroups                                   : EventsGroups ]

EncodeErisReferenceDataGroup(message) ==
    message.mdUpdateActionChar
        \o message.mdEntryType
        \o message.rptSeq
        \o EncodeMdEntryPxDecimalOptional(message.mdEntryPxDecimalOptional)
        \o message.openCloseSettlFlag
        \o message.settlPriceType
        \o EncodeCalFutPxOptional(message.calFutPxOptional)
        \o message.referenceId50
        \o message.mdEntrySizeOptional
        \o message.symbol
        \o message.securityGroup26
        \o message.productOptional
        \o message.securityType
        \o message.securityExchange
        \o message.maturityDate
        \o EncodeCouponRateOptional(message.couponRateOptional)
        \o message.tradeDate
        \o EncodeFairCouponPct(message.fairCouponPct)
        \o EncodeLegPurchaseRate(message.legPurchaseRate)
        \o EncodeFixedNpv(message.fixedNpv)
        \o EncodeFloatNpv(message.floatNpv)
        \o EncodeNpv(message.npv)
        \o EncodeAccruedCoupons(message.accruedCoupons)
        \o EncodeDailyIncrementalErisPai(message.dailyIncrementalErisPai)
        \o EncodeErisPai(message.erisPai)
        \o EncodeFedFundsRate(message.fedFundsRate)
        \o EncodeMinPriceIncrementOptional(message.minPriceIncrementOptional)
        \o EncodeFixedPayment(message.fixedPayment)
        \o EncodeFloatingPayment(message.floatingPayment)
        \o message.nextFixedPaymentDate
        \o EncodeNextFixedPaymentAmount(message.nextFixedPaymentAmount)
        \o EncodeNextFloatingPaymentAmount(message.nextFloatingPaymentAmount)
        \o message.tradingReferenceDate
        \o EncodePreviousErisPai(message.previousErisPai)
        \o message.fedFundsDate
        \o message.accrualDays
        \o message.nominal
        \o message.legCreditRating
        \o EncodeLegContractMultiplier(message.legContractMultiplier)
        \o message.nextFloatingPaymentDate
        \o EncodePV01(message.pV01)
        \o EncodeDV01(message.dV01)
        \o EncodeSettlementNpv(message.settlementNpv)
        \o EncodeFinalSettlementFuturesPrice(message.finalSettlementFuturesPrice)
        \o message.securityDescription
        \o EncodeErisSecurityAltIdGroups(message.erisSecurityAltIdGroups)
        \o EncodeIncrementalRefreshErisRelatedInstrumentsGroups(message.incrementalRefreshErisRelatedInstrumentsGroups)
        \o EncodeEventsGroups(message.eventsGroups)

DecodeErisReferenceDataGroup(bytes) ==
    LET mdUpdateActionChar == ReadBytes(bytes, 1) IN IF ~mdUpdateActionChar.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateActionChar.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryType.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPxDecimalOptional == DecodeMdEntryPxDecimalOptional(rptSeq.rest) IN IF ~mdEntryPxDecimalOptional.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdEntryPxDecimalOptional.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET calFutPxOptional == DecodeCalFutPxOptional(settlPriceType.rest) IN IF ~calFutPxOptional.ok THEN Fail ELSE
    LET referenceId50 == ReadBytes(calFutPxOptional.rest, 50) IN IF ~referenceId50.ok THEN Fail ELSE
    LET mdEntrySizeOptional == ReadBytes(referenceId50.rest, 8) IN IF ~mdEntrySizeOptional.ok THEN Fail ELSE
    LET symbol == ReadBytes(mdEntrySizeOptional.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup26 == ReadBytes(symbol.rest, 26) IN IF ~securityGroup26.ok THEN Fail ELSE
    LET productOptional == ReadBytes(securityGroup26.rest, 1) IN IF ~productOptional.ok THEN Fail ELSE
    LET securityType == ReadBytes(productOptional.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityType.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityExchange.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET couponRateOptional == DecodeCouponRateOptional(maturityDate.rest) IN IF ~couponRateOptional.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(couponRateOptional.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET fairCouponPct == DecodeFairCouponPct(tradeDate.rest) IN IF ~fairCouponPct.ok THEN Fail ELSE
    LET legPurchaseRate == DecodeLegPurchaseRate(fairCouponPct.rest) IN IF ~legPurchaseRate.ok THEN Fail ELSE
    LET fixedNpv == DecodeFixedNpv(legPurchaseRate.rest) IN IF ~fixedNpv.ok THEN Fail ELSE
    LET floatNpv == DecodeFloatNpv(fixedNpv.rest) IN IF ~floatNpv.ok THEN Fail ELSE
    LET npv == DecodeNpv(floatNpv.rest) IN IF ~npv.ok THEN Fail ELSE
    LET accruedCoupons == DecodeAccruedCoupons(npv.rest) IN IF ~accruedCoupons.ok THEN Fail ELSE
    LET dailyIncrementalErisPai == DecodeDailyIncrementalErisPai(accruedCoupons.rest) IN IF ~dailyIncrementalErisPai.ok THEN Fail ELSE
    LET erisPai == DecodeErisPai(dailyIncrementalErisPai.rest) IN IF ~erisPai.ok THEN Fail ELSE
    LET fedFundsRate == DecodeFedFundsRate(erisPai.rest) IN IF ~fedFundsRate.ok THEN Fail ELSE
    LET minPriceIncrementOptional == DecodeMinPriceIncrementOptional(fedFundsRate.rest) IN IF ~minPriceIncrementOptional.ok THEN Fail ELSE
    LET fixedPayment == DecodeFixedPayment(minPriceIncrementOptional.rest) IN IF ~fixedPayment.ok THEN Fail ELSE
    LET floatingPayment == DecodeFloatingPayment(fixedPayment.rest) IN IF ~floatingPayment.ok THEN Fail ELSE
    LET nextFixedPaymentDate == ReadBytes(floatingPayment.rest, 2) IN IF ~nextFixedPaymentDate.ok THEN Fail ELSE
    LET nextFixedPaymentAmount == DecodeNextFixedPaymentAmount(nextFixedPaymentDate.rest) IN IF ~nextFixedPaymentAmount.ok THEN Fail ELSE
    LET nextFloatingPaymentAmount == DecodeNextFloatingPaymentAmount(nextFixedPaymentAmount.rest) IN IF ~nextFloatingPaymentAmount.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(nextFloatingPaymentAmount.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET previousErisPai == DecodePreviousErisPai(tradingReferenceDate.rest) IN IF ~previousErisPai.ok THEN Fail ELSE
    LET fedFundsDate == ReadBytes(previousErisPai.rest, 2) IN IF ~fedFundsDate.ok THEN Fail ELSE
    LET accrualDays == ReadBytes(fedFundsDate.rest, 4) IN IF ~accrualDays.ok THEN Fail ELSE
    LET nominal == ReadBytes(accrualDays.rest, 8) IN IF ~nominal.ok THEN Fail ELSE
    LET legCreditRating == ReadBytes(nominal.rest, 6) IN IF ~legCreditRating.ok THEN Fail ELSE
    LET legContractMultiplier == DecodeLegContractMultiplier(legCreditRating.rest) IN IF ~legContractMultiplier.ok THEN Fail ELSE
    LET nextFloatingPaymentDate == ReadBytes(legContractMultiplier.rest, 2) IN IF ~nextFloatingPaymentDate.ok THEN Fail ELSE
    LET pV01 == DecodePV01(nextFloatingPaymentDate.rest) IN IF ~pV01.ok THEN Fail ELSE
    LET dV01 == DecodeDV01(pV01.rest) IN IF ~dV01.ok THEN Fail ELSE
    LET settlementNpv == DecodeSettlementNpv(dV01.rest) IN IF ~settlementNpv.ok THEN Fail ELSE
    LET finalSettlementFuturesPrice == DecodeFinalSettlementFuturesPrice(settlementNpv.rest) IN IF ~finalSettlementFuturesPrice.ok THEN Fail ELSE
    LET securityDescription == ReadBytes(finalSettlementFuturesPrice.rest, 30) IN IF ~securityDescription.ok THEN Fail ELSE
    LET erisSecurityAltIdGroups == DecodeErisSecurityAltIdGroups(securityDescription.rest) IN IF ~erisSecurityAltIdGroups.ok THEN Fail ELSE
    LET incrementalRefreshErisRelatedInstrumentsGroups == DecodeIncrementalRefreshErisRelatedInstrumentsGroups(erisSecurityAltIdGroups.rest) IN IF ~incrementalRefreshErisRelatedInstrumentsGroups.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups(incrementalRefreshErisRelatedInstrumentsGroups.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    Ok([ mdUpdateActionChar                             |-> mdUpdateActionChar.value,
         mdEntryType                                    |-> mdEntryType.value,
         rptSeq                                         |-> rptSeq.value,
         mdEntryPxDecimalOptional                       |-> mdEntryPxDecimalOptional.value,
         openCloseSettlFlag                             |-> openCloseSettlFlag.value,
         settlPriceType                                 |-> settlPriceType.value,
         calFutPxOptional                               |-> calFutPxOptional.value,
         referenceId50                                  |-> referenceId50.value,
         mdEntrySizeOptional                            |-> mdEntrySizeOptional.value,
         symbol                                         |-> symbol.value,
         securityGroup26                                |-> securityGroup26.value,
         productOptional                                |-> productOptional.value,
         securityType                                   |-> securityType.value,
         securityExchange                               |-> securityExchange.value,
         maturityDate                                   |-> maturityDate.value,
         couponRateOptional                             |-> couponRateOptional.value,
         tradeDate                                      |-> tradeDate.value,
         fairCouponPct                                  |-> fairCouponPct.value,
         legPurchaseRate                                |-> legPurchaseRate.value,
         fixedNpv                                       |-> fixedNpv.value,
         floatNpv                                       |-> floatNpv.value,
         npv                                            |-> npv.value,
         accruedCoupons                                 |-> accruedCoupons.value,
         dailyIncrementalErisPai                        |-> dailyIncrementalErisPai.value,
         erisPai                                        |-> erisPai.value,
         fedFundsRate                                   |-> fedFundsRate.value,
         minPriceIncrementOptional                      |-> minPriceIncrementOptional.value,
         fixedPayment                                   |-> fixedPayment.value,
         floatingPayment                                |-> floatingPayment.value,
         nextFixedPaymentDate                           |-> nextFixedPaymentDate.value,
         nextFixedPaymentAmount                         |-> nextFixedPaymentAmount.value,
         nextFloatingPaymentAmount                      |-> nextFloatingPaymentAmount.value,
         tradingReferenceDate                           |-> tradingReferenceDate.value,
         previousErisPai                                |-> previousErisPai.value,
         fedFundsDate                                   |-> fedFundsDate.value,
         accrualDays                                    |-> accrualDays.value,
         nominal                                        |-> nominal.value,
         legCreditRating                                |-> legCreditRating.value,
         legContractMultiplier                          |-> legContractMultiplier.value,
         nextFloatingPaymentDate                        |-> nextFloatingPaymentDate.value,
         pV01                                           |-> pV01.value,
         dV01                                           |-> dV01.value,
         settlementNpv                                  |-> settlementNpv.value,
         finalSettlementFuturesPrice                    |-> finalSettlementFuturesPrice.value,
         securityDescription                            |-> securityDescription.value,
         erisSecurityAltIdGroups                        |-> erisSecurityAltIdGroups.value,
         incrementalRefreshErisRelatedInstrumentsGroups |-> incrementalRefreshErisRelatedInstrumentsGroups.value,
         eventsGroups                                   |-> eventsGroups.value ], eventsGroups.rest)

ZeroErisReferenceDataGroup ==
    [ mdUpdateActionChar                             |-> [i \in 1 .. 1 |-> 0],
      mdEntryType                                    |-> [i \in 1 .. 1 |-> 0],
      rptSeq                                         |-> [i \in 1 .. 4 |-> 0],
      mdEntryPxDecimalOptional                       |-> ZeroMdEntryPxDecimalOptional,
      openCloseSettlFlag                             |-> [i \in 1 .. 1 |-> 0],
      settlPriceType                                 |-> [i \in 1 .. 1 |-> 0],
      calFutPxOptional                               |-> ZeroCalFutPxOptional,
      referenceId50                                  |-> [i \in 1 .. 50 |-> 0],
      mdEntrySizeOptional                            |-> [i \in 1 .. 8 |-> 0],
      symbol                                         |-> [i \in 1 .. 50 |-> 0],
      securityGroup26                                |-> [i \in 1 .. 26 |-> 0],
      productOptional                                |-> [i \in 1 .. 1 |-> 0],
      securityType                                   |-> [i \in 1 .. 9 |-> 0],
      securityExchange                               |-> [i \in 1 .. 4 |-> 0],
      maturityDate                                   |-> [i \in 1 .. 2 |-> 0],
      couponRateOptional                             |-> ZeroCouponRateOptional,
      tradeDate                                      |-> [i \in 1 .. 2 |-> 0],
      fairCouponPct                                  |-> ZeroFairCouponPct,
      legPurchaseRate                                |-> ZeroLegPurchaseRate,
      fixedNpv                                       |-> ZeroFixedNpv,
      floatNpv                                       |-> ZeroFloatNpv,
      npv                                            |-> ZeroNpv,
      accruedCoupons                                 |-> ZeroAccruedCoupons,
      dailyIncrementalErisPai                        |-> ZeroDailyIncrementalErisPai,
      erisPai                                        |-> ZeroErisPai,
      fedFundsRate                                   |-> ZeroFedFundsRate,
      minPriceIncrementOptional                      |-> ZeroMinPriceIncrementOptional,
      fixedPayment                                   |-> ZeroFixedPayment,
      floatingPayment                                |-> ZeroFloatingPayment,
      nextFixedPaymentDate                           |-> [i \in 1 .. 2 |-> 0],
      nextFixedPaymentAmount                         |-> ZeroNextFixedPaymentAmount,
      nextFloatingPaymentAmount                      |-> ZeroNextFloatingPaymentAmount,
      tradingReferenceDate                           |-> [i \in 1 .. 2 |-> 0],
      previousErisPai                                |-> ZeroPreviousErisPai,
      fedFundsDate                                   |-> [i \in 1 .. 2 |-> 0],
      accrualDays                                    |-> [i \in 1 .. 4 |-> 0],
      nominal                                        |-> [i \in 1 .. 8 |-> 0],
      legCreditRating                                |-> [i \in 1 .. 6 |-> 0],
      legContractMultiplier                          |-> ZeroLegContractMultiplier,
      nextFloatingPaymentDate                        |-> [i \in 1 .. 2 |-> 0],
      pV01                                           |-> ZeroPV01,
      dV01                                           |-> ZeroDV01,
      settlementNpv                                  |-> ZeroSettlementNpv,
      finalSettlementFuturesPrice                    |-> ZeroFinalSettlementFuturesPrice,
      securityDescription                            |-> [i \in 1 .. 30 |-> 0],
      erisSecurityAltIdGroups                        |-> ZeroErisSecurityAltIdGroups,
      incrementalRefreshErisRelatedInstrumentsGroups |-> ZeroIncrementalRefreshErisRelatedInstrumentsGroups,
      eventsGroups                                   |-> ZeroEventsGroups ]

(* Eris Reference Data Group at zero, then each field in turn at the values it is checked at *)
CheckedErisReferenceDataGroup ==
    { ZeroErisReferenceDataGroup }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.mdUpdateActionChar = one] : one \in Sample(1) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.mdEntryPxDecimalOptional = one] : one \in CheckedMdEntryPxDecimalOptional }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.calFutPxOptional = one] : one \in CheckedCalFutPxOptional }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.referenceId50 = one] : one \in Sample(50) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.mdEntrySizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.securityGroup26 = one] : one \in Sample(26) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.productOptional = one] : one \in Sample(1) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.couponRateOptional = one] : one \in CheckedCouponRateOptional }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.fairCouponPct = one] : one \in CheckedFairCouponPct }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.legPurchaseRate = one] : one \in CheckedLegPurchaseRate }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.fixedNpv = one] : one \in CheckedFixedNpv }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.floatNpv = one] : one \in CheckedFloatNpv }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.npv = one] : one \in CheckedNpv }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.accruedCoupons = one] : one \in CheckedAccruedCoupons }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.dailyIncrementalErisPai = one] : one \in CheckedDailyIncrementalErisPai }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.erisPai = one] : one \in CheckedErisPai }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.fedFundsRate = one] : one \in CheckedFedFundsRate }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.minPriceIncrementOptional = one] : one \in CheckedMinPriceIncrementOptional }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.fixedPayment = one] : one \in CheckedFixedPayment }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.floatingPayment = one] : one \in CheckedFloatingPayment }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.nextFixedPaymentDate = one] : one \in Sample(2) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.nextFixedPaymentAmount = one] : one \in CheckedNextFixedPaymentAmount }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.nextFloatingPaymentAmount = one] : one \in CheckedNextFloatingPaymentAmount }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.previousErisPai = one] : one \in CheckedPreviousErisPai }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.fedFundsDate = one] : one \in Sample(2) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.accrualDays = one] : one \in Sample(4) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.nominal = one] : one \in Sample(8) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.legCreditRating = one] : one \in Sample(6) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.legContractMultiplier = one] : one \in CheckedLegContractMultiplier }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.nextFloatingPaymentDate = one] : one \in Sample(2) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.pV01 = one] : one \in CheckedPV01 }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.dV01 = one] : one \in CheckedDV01 }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.settlementNpv = one] : one \in CheckedSettlementNpv }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.finalSettlementFuturesPrice = one] : one \in CheckedFinalSettlementFuturesPrice }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.securityDescription = one] : one \in Sample(30) }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.erisSecurityAltIdGroups = one] : one \in CheckedErisSecurityAltIdGroups }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.incrementalRefreshErisRelatedInstrumentsGroups = one] : one \in CheckedIncrementalRefreshErisRelatedInstrumentsGroups }
        \cup { [ZeroErisReferenceDataGroup EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups }

(* A run of Eris Reference Data Group, written one after another *)
RECURSIVE EncodeErisReferenceDataGroupList(_)
EncodeErisReferenceDataGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisReferenceDataGroup(Head(messages)) \o EncodeErisReferenceDataGroupList(Tail(messages))

(* As many Eris Reference Data Group as the field that counts them says *)
RECURSIVE ReadErisReferenceDataGroupList(_, _)
ReadErisReferenceDataGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisReferenceDataGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisReferenceDataGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Reference Data Group of each kind, for the lists that carry them *)
OneErisReferenceDataGroup == { ZeroErisReferenceDataGroup }

(***************************************************************************)
(* Eris Reference Data Groups                                              *)
(***************************************************************************)

ErisReferenceDataGroups ==
    [ blockLength            : Sample(2),
      erisReferenceDataGroup : SampleLists(OneErisReferenceDataGroup) ]

EncodeErisReferenceDataGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisReferenceDataGroup), 1)
        \o EncodeErisReferenceDataGroupList(message.erisReferenceDataGroup)

DecodeErisReferenceDataGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisReferenceDataGroup == ReadErisReferenceDataGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~erisReferenceDataGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         erisReferenceDataGroup |-> erisReferenceDataGroup.value ], erisReferenceDataGroup.rest)

ZeroErisReferenceDataGroups ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      erisReferenceDataGroup |-> << >> ]

(* Eris Reference Data Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisReferenceDataGroups ==
    { ZeroErisReferenceDataGroups }
        \cup { [ZeroErisReferenceDataGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisReferenceDataGroups EXCEPT !.erisReferenceDataGroup = one] : one \in SampleLists(OneErisReferenceDataGroup) }

(***************************************************************************)
(* Md Incremental Refresh Eris Reference Data And Daily Statistics         *)
(***************************************************************************)

MdIncrementalRefreshErisReferenceDataAndDailyStatistics ==
    [ transactTime               : Sample(8),
      matchEventIndicator        : Sample(1),
      batchTotalMessagesOptional : Sample(2),
      erisReferenceDataGroups    : ErisReferenceDataGroups ]

EncodeMdIncrementalRefreshErisReferenceDataAndDailyStatistics(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.batchTotalMessagesOptional
        \o EncodeErisReferenceDataGroups(message.erisReferenceDataGroups)

DecodeMdIncrementalRefreshErisReferenceDataAndDailyStatistics(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessagesOptional == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessagesOptional.ok THEN Fail ELSE
    LET erisReferenceDataGroups == DecodeErisReferenceDataGroups(batchTotalMessagesOptional.rest) IN IF ~erisReferenceDataGroups.ok THEN Fail ELSE
    Ok([ transactTime               |-> transactTime.value,
         matchEventIndicator        |-> matchEventIndicator.value,
         batchTotalMessagesOptional |-> batchTotalMessagesOptional.value,
         erisReferenceDataGroups    |-> erisReferenceDataGroups.value ], erisReferenceDataGroups.rest)

ZeroMdIncrementalRefreshErisReferenceDataAndDailyStatistics ==
    [ transactTime               |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator        |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessagesOptional |-> [i \in 1 .. 2 |-> 0],
      erisReferenceDataGroups    |-> ZeroErisReferenceDataGroups ]

(* Md Incremental Refresh Eris Reference Data And Daily Statistics at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshErisReferenceDataAndDailyStatistics ==
    { ZeroMdIncrementalRefreshErisReferenceDataAndDailyStatistics }
        \cup { [ZeroMdIncrementalRefreshErisReferenceDataAndDailyStatistics EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshErisReferenceDataAndDailyStatistics EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshErisReferenceDataAndDailyStatistics EXCEPT !.batchTotalMessagesOptional = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshErisReferenceDataAndDailyStatistics EXCEPT !.erisReferenceDataGroups = one] : one \in CheckedErisReferenceDataGroups }

(***************************************************************************)
(* News Indices Related Sym Group: 50 bytes                                *)
(***************************************************************************)

NewsIndicesRelatedSymGroup ==
    [ symbol : Sample(50) ]

EncodeNewsIndicesRelatedSymGroup(message) ==
    message.symbol

DecodeNewsIndicesRelatedSymGroup(bytes) ==
    LET symbol == ReadBytes(bytes, 50) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value ], symbol.rest)

ZeroNewsIndicesRelatedSymGroup ==
    [ symbol |-> [i \in 1 .. 50 |-> 0] ]

(* News Indices Related Sym Group at zero, then each field in turn at the values it is checked at *)
CheckedNewsIndicesRelatedSymGroup ==
    { ZeroNewsIndicesRelatedSymGroup }
        \cup { [ZeroNewsIndicesRelatedSymGroup EXCEPT !.symbol = one] : one \in Sample(50) }

(* A run of News Indices Related Sym Group, written one after another *)
RECURSIVE EncodeNewsIndicesRelatedSymGroupList(_)
EncodeNewsIndicesRelatedSymGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewsIndicesRelatedSymGroup(Head(messages)) \o EncodeNewsIndicesRelatedSymGroupList(Tail(messages))

(* As many News Indices Related Sym Group as the field that counts them says *)
RECURSIVE ReadNewsIndicesRelatedSymGroupList(_, _)
ReadNewsIndicesRelatedSymGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewsIndicesRelatedSymGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewsIndicesRelatedSymGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One News Indices Related Sym Group of each kind, for the lists that carry them *)
OneNewsIndicesRelatedSymGroup == { ZeroNewsIndicesRelatedSymGroup }

(***************************************************************************)
(* News Indices Related Sym Groups                                         *)
(***************************************************************************)

NewsIndicesRelatedSymGroups ==
    [ blockLength                : Sample(2),
      newsIndicesRelatedSymGroup : SampleLists(OneNewsIndicesRelatedSymGroup) ]

EncodeNewsIndicesRelatedSymGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.newsIndicesRelatedSymGroup), 1)
        \o EncodeNewsIndicesRelatedSymGroupList(message.newsIndicesRelatedSymGroup)

DecodeNewsIndicesRelatedSymGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET newsIndicesRelatedSymGroup == ReadNewsIndicesRelatedSymGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~newsIndicesRelatedSymGroup.ok THEN Fail ELSE
    Ok([ blockLength                |-> blockLength.value,
         newsIndicesRelatedSymGroup |-> newsIndicesRelatedSymGroup.value ], newsIndicesRelatedSymGroup.rest)

ZeroNewsIndicesRelatedSymGroups ==
    [ blockLength                |-> [i \in 1 .. 2 |-> 0],
      newsIndicesRelatedSymGroup |-> << >> ]

(* News Indices Related Sym Groups at zero, then each field in turn at the values it is checked at *)
CheckedNewsIndicesRelatedSymGroups ==
    { ZeroNewsIndicesRelatedSymGroups }
        \cup { [ZeroNewsIndicesRelatedSymGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroNewsIndicesRelatedSymGroups EXCEPT !.newsIndicesRelatedSymGroup = one] : one \in SampleLists(OneNewsIndicesRelatedSymGroup) }

(***************************************************************************)
(* Lines Of Text Group: 500 bytes                                          *)
(***************************************************************************)

LinesOfTextGroup ==
    [ text500 : Sample(500) ]

EncodeLinesOfTextGroup(message) ==
    message.text500

DecodeLinesOfTextGroup(bytes) ==
    LET text500 == ReadBytes(bytes, 500) IN IF ~text500.ok THEN Fail ELSE
    Ok([ text500 |-> text500.value ], text500.rest)

ZeroLinesOfTextGroup ==
    [ text500 |-> [i \in 1 .. 500 |-> 0] ]

(* Lines Of Text Group at zero, then each field in turn at the values it is checked at *)
CheckedLinesOfTextGroup ==
    { ZeroLinesOfTextGroup }
        \cup { [ZeroLinesOfTextGroup EXCEPT !.text500 = one] : one \in Sample(500) }

(* A run of Lines Of Text Group, written one after another *)
RECURSIVE EncodeLinesOfTextGroupList(_)
EncodeLinesOfTextGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLinesOfTextGroup(Head(messages)) \o EncodeLinesOfTextGroupList(Tail(messages))

(* As many Lines Of Text Group as the field that counts them says *)
RECURSIVE ReadLinesOfTextGroupList(_, _)
ReadLinesOfTextGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLinesOfTextGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLinesOfTextGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Lines Of Text Group of each kind, for the lists that carry them *)
OneLinesOfTextGroup == { ZeroLinesOfTextGroup }

(***************************************************************************)
(* Lines Of Text Groups                                                    *)
(***************************************************************************)

LinesOfTextGroups ==
    [ blockLength      : Sample(2),
      linesOfTextGroup : SampleLists(OneLinesOfTextGroup) ]

EncodeLinesOfTextGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.linesOfTextGroup), 1)
        \o EncodeLinesOfTextGroupList(message.linesOfTextGroup)

DecodeLinesOfTextGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET linesOfTextGroup == ReadLinesOfTextGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~linesOfTextGroup.ok THEN Fail ELSE
    Ok([ blockLength      |-> blockLength.value,
         linesOfTextGroup |-> linesOfTextGroup.value ], linesOfTextGroup.rest)

ZeroLinesOfTextGroups ==
    [ blockLength      |-> [i \in 1 .. 2 |-> 0],
      linesOfTextGroup |-> << >> ]

(* Lines Of Text Groups at zero, then each field in turn at the values it is checked at *)
CheckedLinesOfTextGroups ==
    { ZeroLinesOfTextGroups }
        \cup { [ZeroLinesOfTextGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLinesOfTextGroups EXCEPT !.linesOfTextGroup = one] : one \in SampleLists(OneLinesOfTextGroup) }

(***************************************************************************)
(* Md News Indices                                                         *)
(***************************************************************************)

MdNewsIndices ==
    [ headline                    : Sample(50),
      origTime                    : Sample(8),
      mdFeedType                  : Sample(2),
      newsIndicesRelatedSymGroups : NewsIndicesRelatedSymGroups,
      linesOfTextGroups           : LinesOfTextGroups ]

EncodeMdNewsIndices(message) ==
    message.headline
        \o message.origTime
        \o message.mdFeedType
        \o EncodeNewsIndicesRelatedSymGroups(message.newsIndicesRelatedSymGroups)
        \o EncodeLinesOfTextGroups(message.linesOfTextGroups)

DecodeMdNewsIndices(bytes) ==
    LET headline == ReadBytes(bytes, 50) IN IF ~headline.ok THEN Fail ELSE
    LET origTime == ReadBytes(headline.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET mdFeedType == ReadBytes(origTime.rest, 2) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET newsIndicesRelatedSymGroups == DecodeNewsIndicesRelatedSymGroups(mdFeedType.rest) IN IF ~newsIndicesRelatedSymGroups.ok THEN Fail ELSE
    LET linesOfTextGroups == DecodeLinesOfTextGroups(newsIndicesRelatedSymGroups.rest) IN IF ~linesOfTextGroups.ok THEN Fail ELSE
    Ok([ headline                    |-> headline.value,
         origTime                    |-> origTime.value,
         mdFeedType                  |-> mdFeedType.value,
         newsIndicesRelatedSymGroups |-> newsIndicesRelatedSymGroups.value,
         linesOfTextGroups           |-> linesOfTextGroups.value ], linesOfTextGroups.rest)

ZeroMdNewsIndices ==
    [ headline                    |-> [i \in 1 .. 50 |-> 0],
      origTime                    |-> [i \in 1 .. 8 |-> 0],
      mdFeedType                  |-> [i \in 1 .. 2 |-> 0],
      newsIndicesRelatedSymGroups |-> ZeroNewsIndicesRelatedSymGroups,
      linesOfTextGroups           |-> ZeroLinesOfTextGroups ]

(* Md News Indices at zero, then each field in turn at the values it is checked at *)
CheckedMdNewsIndices ==
    { ZeroMdNewsIndices }
        \cup { [ZeroMdNewsIndices EXCEPT !.headline = one] : one \in Sample(50) }
        \cup { [ZeroMdNewsIndices EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroMdNewsIndices EXCEPT !.mdFeedType = one] : one \in Sample(2) }
        \cup { [ZeroMdNewsIndices EXCEPT !.newsIndicesRelatedSymGroups = one] : one \in CheckedNewsIndicesRelatedSymGroups }
        \cup { [ZeroMdNewsIndices EXCEPT !.linesOfTextGroups = one] : one \in CheckedLinesOfTextGroups }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear ==
    { ZeroMaturityMonthYear }
        \cup { [ZeroMaturityMonthYear EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear ==
    { ZeroUnderlyingMaturityMonthYear }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Blocks Underlyings Group: 68 bytes                                *)
(***************************************************************************)

TradeBlocksUnderlyingsGroup ==
    [ underlyingSymbol                  : Sample(50),
      underlyingMaturityMonthYear       : UnderlyingMaturityMonthYear,
      underlyingSecurityType            : Sample(9),
      underlyingSecurityExchangeString4 : Sample(4) ]

EncodeTradeBlocksUnderlyingsGroup(message) ==
    message.underlyingSymbol
        \o EncodeUnderlyingMaturityMonthYear(message.underlyingMaturityMonthYear)
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchangeString4

DecodeTradeBlocksUnderlyingsGroup(bytes) ==
    LET underlyingSymbol == ReadBytes(bytes, 50) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear(underlyingSymbol.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingMaturityMonthYear.rest, 9) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchangeString4 == ReadBytes(underlyingSecurityType.rest, 4) IN IF ~underlyingSecurityExchangeString4.ok THEN Fail ELSE
    Ok([ underlyingSymbol                  |-> underlyingSymbol.value,
         underlyingMaturityMonthYear       |-> underlyingMaturityMonthYear.value,
         underlyingSecurityType            |-> underlyingSecurityType.value,
         underlyingSecurityExchangeString4 |-> underlyingSecurityExchangeString4.value ], underlyingSecurityExchangeString4.rest)

ZeroTradeBlocksUnderlyingsGroup ==
    [ underlyingSymbol                  |-> [i \in 1 .. 50 |-> 0],
      underlyingMaturityMonthYear       |-> ZeroUnderlyingMaturityMonthYear,
      underlyingSecurityType            |-> [i \in 1 .. 9 |-> 0],
      underlyingSecurityExchangeString4 |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Blocks Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksUnderlyingsGroup ==
    { ZeroTradeBlocksUnderlyingsGroup }
        \cup { [ZeroTradeBlocksUnderlyingsGroup EXCEPT !.underlyingSymbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksUnderlyingsGroup EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear }
        \cup { [ZeroTradeBlocksUnderlyingsGroup EXCEPT !.underlyingSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksUnderlyingsGroup EXCEPT !.underlyingSecurityExchangeString4 = one] : one \in Sample(4) }

(* A run of Trade Blocks Underlyings Group, written one after another *)
RECURSIVE EncodeTradeBlocksUnderlyingsGroupList(_)
EncodeTradeBlocksUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksUnderlyingsGroup(Head(messages)) \o EncodeTradeBlocksUnderlyingsGroupList(Tail(messages))

(* As many Trade Blocks Underlyings Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksUnderlyingsGroupList(_, _)
ReadTradeBlocksUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Underlyings Group of each kind, for the lists that carry them *)
OneTradeBlocksUnderlyingsGroup == { ZeroTradeBlocksUnderlyingsGroup }

(***************************************************************************)
(* Trade Blocks Underlyings Groups                                         *)
(***************************************************************************)

TradeBlocksUnderlyingsGroups ==
    [ blockLength                 : Sample(2),
      tradeBlocksUnderlyingsGroup : SampleLists(OneTradeBlocksUnderlyingsGroup) ]

EncodeTradeBlocksUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksUnderlyingsGroup), 1)
        \o EncodeTradeBlocksUnderlyingsGroupList(message.tradeBlocksUnderlyingsGroup)

DecodeTradeBlocksUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksUnderlyingsGroup == ReadTradeBlocksUnderlyingsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         tradeBlocksUnderlyingsGroup |-> tradeBlocksUnderlyingsGroup.value ], tradeBlocksUnderlyingsGroup.rest)

ZeroTradeBlocksUnderlyingsGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksUnderlyingsGroup |-> << >> ]

(* Trade Blocks Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksUnderlyingsGroups ==
    { ZeroTradeBlocksUnderlyingsGroups }
        \cup { [ZeroTradeBlocksUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksUnderlyingsGroups EXCEPT !.tradeBlocksUnderlyingsGroup = one] : one \in SampleLists(OneTradeBlocksUnderlyingsGroup) }

(***************************************************************************)
(* Trade Blocks Party Ids Group: 52 bytes                                  *)
(***************************************************************************)

TradeBlocksPartyIdsGroup ==
    [ partyId   : Sample(50),
      partyRole : Sample(2) ]

EncodeTradeBlocksPartyIdsGroup(message) ==
    message.partyId
        \o message.partyRole

DecodeTradeBlocksPartyIdsGroup(bytes) ==
    LET partyId == ReadBytes(bytes, 50) IN IF ~partyId.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyId.rest, 2) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId   |-> partyId.value,
         partyRole |-> partyRole.value ], partyRole.rest)

ZeroTradeBlocksPartyIdsGroup ==
    [ partyId   |-> [i \in 1 .. 50 |-> 0],
      partyRole |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Blocks Party Ids Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksPartyIdsGroup ==
    { ZeroTradeBlocksPartyIdsGroup }
        \cup { [ZeroTradeBlocksPartyIdsGroup EXCEPT !.partyId = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksPartyIdsGroup EXCEPT !.partyRole = one] : one \in Sample(2) }

(* A run of Trade Blocks Party Ids Group, written one after another *)
RECURSIVE EncodeTradeBlocksPartyIdsGroupList(_)
EncodeTradeBlocksPartyIdsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksPartyIdsGroup(Head(messages)) \o EncodeTradeBlocksPartyIdsGroupList(Tail(messages))

(* As many Trade Blocks Party Ids Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksPartyIdsGroupList(_, _)
ReadTradeBlocksPartyIdsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksPartyIdsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksPartyIdsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Party Ids Group of each kind, for the lists that carry them *)
OneTradeBlocksPartyIdsGroup == { ZeroTradeBlocksPartyIdsGroup }

(***************************************************************************)
(* Trade Blocks Party Ids Groups                                           *)
(***************************************************************************)

TradeBlocksPartyIdsGroups ==
    [ blockLength              : Sample(2),
      tradeBlocksPartyIdsGroup : SampleLists(OneTradeBlocksPartyIdsGroup) ]

EncodeTradeBlocksPartyIdsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksPartyIdsGroup), 1)
        \o EncodeTradeBlocksPartyIdsGroupList(message.tradeBlocksPartyIdsGroup)

DecodeTradeBlocksPartyIdsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksPartyIdsGroup == ReadTradeBlocksPartyIdsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksPartyIdsGroup.ok THEN Fail ELSE
    Ok([ blockLength              |-> blockLength.value,
         tradeBlocksPartyIdsGroup |-> tradeBlocksPartyIdsGroup.value ], tradeBlocksPartyIdsGroup.rest)

ZeroTradeBlocksPartyIdsGroups ==
    [ blockLength              |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksPartyIdsGroup |-> << >> ]

(* Trade Blocks Party Ids Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksPartyIdsGroups ==
    { ZeroTradeBlocksPartyIdsGroups }
        \cup { [ZeroTradeBlocksPartyIdsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksPartyIdsGroups EXCEPT !.tradeBlocksPartyIdsGroup = one] : one \in SampleLists(OneTradeBlocksPartyIdsGroup) }

(***************************************************************************)
(* Leg Maturity Month Year: 5 bytes                                        *)
(***************************************************************************)

LegMaturityMonthYear ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeLegMaturityMonthYear(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeLegMaturityMonthYear(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroLegMaturityMonthYear ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedLegMaturityMonthYear ==
    { ZeroLegMaturityMonthYear }
        \cup { [ZeroLegMaturityMonthYear EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLegMaturityMonthYear EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroLegMaturityMonthYear EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroLegMaturityMonthYear EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Blocks Original Legs Group: 135 bytes                             *)
(***************************************************************************)

TradeBlocksOriginalLegsGroup ==
    [ legSymbol                    : Sample(50),
      legSecurityId                : Sample(8),
      legSecurityGroup             : Sample(12),
      legId                        : Sample(17),
      legSecurityType              : Sample(9),
      legMaturityMonthYear         : LegMaturityMonthYear,
      legMaturityDate              : Sample(2),
      legStrikePricePricenull      : Sample(8),
      legUnitOfMeasure             : Sample(5),
      legUnitOfMeasureQtyPricenull : Sample(8),
      legSecurityExchange          : Sample(4),
      legRatioQtyUInt16Null        : Sample(2),
      legSide                      : Sample(1),
      legPutOrCall                 : Sample(1),
      legUnitOfMeasureCurrency     : Sample(3) ]

EncodeTradeBlocksOriginalLegsGroup(message) ==
    message.legSymbol
        \o message.legSecurityId
        \o message.legSecurityGroup
        \o message.legId
        \o message.legSecurityType
        \o EncodeLegMaturityMonthYear(message.legMaturityMonthYear)
        \o message.legMaturityDate
        \o message.legStrikePricePricenull
        \o message.legUnitOfMeasure
        \o message.legUnitOfMeasureQtyPricenull
        \o message.legSecurityExchange
        \o message.legRatioQtyUInt16Null
        \o message.legSide
        \o message.legPutOrCall
        \o message.legUnitOfMeasureCurrency

DecodeTradeBlocksOriginalLegsGroup(bytes) ==
    LET legSymbol == ReadBytes(bytes, 50) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legSymbol.rest, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legSecurityGroup == ReadBytes(legSecurityId.rest, 12) IN IF ~legSecurityGroup.ok THEN Fail ELSE
    LET legId == ReadBytes(legSecurityGroup.rest, 17) IN IF ~legId.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legId.rest, 9) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legMaturityMonthYear == DecodeLegMaturityMonthYear(legSecurityType.rest) IN IF ~legMaturityMonthYear.ok THEN Fail ELSE
    LET legMaturityDate == ReadBytes(legMaturityMonthYear.rest, 2) IN IF ~legMaturityDate.ok THEN Fail ELSE
    LET legStrikePricePricenull == ReadBytes(legMaturityDate.rest, 8) IN IF ~legStrikePricePricenull.ok THEN Fail ELSE
    LET legUnitOfMeasure == ReadBytes(legStrikePricePricenull.rest, 5) IN IF ~legUnitOfMeasure.ok THEN Fail ELSE
    LET legUnitOfMeasureQtyPricenull == ReadBytes(legUnitOfMeasure.rest, 8) IN IF ~legUnitOfMeasureQtyPricenull.ok THEN Fail ELSE
    LET legSecurityExchange == ReadBytes(legUnitOfMeasureQtyPricenull.rest, 4) IN IF ~legSecurityExchange.ok THEN Fail ELSE
    LET legRatioQtyUInt16Null == ReadBytes(legSecurityExchange.rest, 2) IN IF ~legRatioQtyUInt16Null.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQtyUInt16Null.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legPutOrCall == ReadBytes(legSide.rest, 1) IN IF ~legPutOrCall.ok THEN Fail ELSE
    LET legUnitOfMeasureCurrency == ReadBytes(legPutOrCall.rest, 3) IN IF ~legUnitOfMeasureCurrency.ok THEN Fail ELSE
    Ok([ legSymbol                    |-> legSymbol.value,
         legSecurityId                |-> legSecurityId.value,
         legSecurityGroup             |-> legSecurityGroup.value,
         legId                        |-> legId.value,
         legSecurityType              |-> legSecurityType.value,
         legMaturityMonthYear         |-> legMaturityMonthYear.value,
         legMaturityDate              |-> legMaturityDate.value,
         legStrikePricePricenull      |-> legStrikePricePricenull.value,
         legUnitOfMeasure             |-> legUnitOfMeasure.value,
         legUnitOfMeasureQtyPricenull |-> legUnitOfMeasureQtyPricenull.value,
         legSecurityExchange          |-> legSecurityExchange.value,
         legRatioQtyUInt16Null        |-> legRatioQtyUInt16Null.value,
         legSide                      |-> legSide.value,
         legPutOrCall                 |-> legPutOrCall.value,
         legUnitOfMeasureCurrency     |-> legUnitOfMeasureCurrency.value ], legUnitOfMeasureCurrency.rest)

ZeroTradeBlocksOriginalLegsGroup ==
    [ legSymbol                    |-> [i \in 1 .. 50 |-> 0],
      legSecurityId                |-> [i \in 1 .. 8 |-> 0],
      legSecurityGroup             |-> [i \in 1 .. 12 |-> 0],
      legId                        |-> [i \in 1 .. 17 |-> 0],
      legSecurityType              |-> [i \in 1 .. 9 |-> 0],
      legMaturityMonthYear         |-> ZeroLegMaturityMonthYear,
      legMaturityDate              |-> [i \in 1 .. 2 |-> 0],
      legStrikePricePricenull      |-> [i \in 1 .. 8 |-> 0],
      legUnitOfMeasure             |-> [i \in 1 .. 5 |-> 0],
      legUnitOfMeasureQtyPricenull |-> [i \in 1 .. 8 |-> 0],
      legSecurityExchange          |-> [i \in 1 .. 4 |-> 0],
      legRatioQtyUInt16Null        |-> [i \in 1 .. 2 |-> 0],
      legSide                      |-> [i \in 1 .. 1 |-> 0],
      legPutOrCall                 |-> [i \in 1 .. 1 |-> 0],
      legUnitOfMeasureCurrency     |-> [i \in 1 .. 3 |-> 0] ]

(* Trade Blocks Original Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksOriginalLegsGroup ==
    { ZeroTradeBlocksOriginalLegsGroup }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legSecurityGroup = one] : one \in Sample(12) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legId = one] : one \in Sample(17) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legMaturityMonthYear = one] : one \in CheckedLegMaturityMonthYear }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legMaturityDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legStrikePricePricenull = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legUnitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legUnitOfMeasureQtyPricenull = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legSecurityExchange = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legRatioQtyUInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legPutOrCall = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup EXCEPT !.legUnitOfMeasureCurrency = one] : one \in Sample(3) }

(* A run of Trade Blocks Original Legs Group, written one after another *)
RECURSIVE EncodeTradeBlocksOriginalLegsGroupList(_)
EncodeTradeBlocksOriginalLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksOriginalLegsGroup(Head(messages)) \o EncodeTradeBlocksOriginalLegsGroupList(Tail(messages))

(* As many Trade Blocks Original Legs Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksOriginalLegsGroupList(_, _)
ReadTradeBlocksOriginalLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksOriginalLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksOriginalLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Original Legs Group of each kind, for the lists that carry them *)
OneTradeBlocksOriginalLegsGroup == { ZeroTradeBlocksOriginalLegsGroup }

(***************************************************************************)
(* Trade Blocks Original Legs Groups                                       *)
(***************************************************************************)

TradeBlocksOriginalLegsGroups ==
    [ blockLength                  : Sample(2),
      tradeBlocksOriginalLegsGroup : SampleLists(OneTradeBlocksOriginalLegsGroup) ]

EncodeTradeBlocksOriginalLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksOriginalLegsGroup), 1)
        \o EncodeTradeBlocksOriginalLegsGroupList(message.tradeBlocksOriginalLegsGroup)

DecodeTradeBlocksOriginalLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksOriginalLegsGroup == ReadTradeBlocksOriginalLegsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksOriginalLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         tradeBlocksOriginalLegsGroup |-> tradeBlocksOriginalLegsGroup.value ], tradeBlocksOriginalLegsGroup.rest)

ZeroTradeBlocksOriginalLegsGroups ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksOriginalLegsGroup |-> << >> ]

(* Trade Blocks Original Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksOriginalLegsGroups ==
    { ZeroTradeBlocksOriginalLegsGroups }
        \cup { [ZeroTradeBlocksOriginalLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalLegsGroups EXCEPT !.tradeBlocksOriginalLegsGroup = one] : one \in SampleLists(OneTradeBlocksOriginalLegsGroup) }

(***************************************************************************)
(* Trade Blocks Original Group                                             *)
(***************************************************************************)

TradeBlocksOriginalGroup ==
    [ mdUpdateAction                : Sample(1),
      securityId                    : Sample(8),
      rptSeq                        : Sample(4),
      mdEntryPxOptional             : Sample(8),
      mdEntrySizeOptional           : Sample(8),
      numberOfOrders                : Sample(4),
      tradeId                       : Sample(4),
      aggressorSide                 : Sample(1),
      symbol                        : Sample(50),
      securityGroup12               : Sample(12),
      securityType                  : Sample(9),
      securitySubType               : Sample(2),
      maturityMonthYear             : MaturityMonthYear,
      securityExchange4             : Sample(4),
      maturityDate                  : Sample(2),
      unitOfMeasure                 : Sample(5),
      unitOfMeasureCurrency3        : Sample(3),
      unitOfMeasureQtyOptional      : Sample(8),
      couponRate                    : Sample(4),
      priceType                     : Sample(2),
      trdType                       : Sample(1),
      mdEntryId                     : Sample(26),
      putOrCall                     : Sample(1),
      strikePrice                   : Sample(8),
      restructuringType             : Sample(2),
      seniority                     : Sample(2),
      referenceId100                : Sample(100),
      strategyLinkId                : Sample(26),
      legRefId                      : Sample(17),
      tradeBlocksUnderlyingsGroups  : TradeBlocksUnderlyingsGroups,
      tradeBlocksPartyIdsGroups     : TradeBlocksPartyIdsGroups,
      tradeBlocksOriginalLegsGroups : TradeBlocksOriginalLegsGroups ]

EncodeTradeBlocksOriginalGroup(message) ==
    message.mdUpdateAction
        \o message.securityId
        \o message.rptSeq
        \o message.mdEntryPxOptional
        \o message.mdEntrySizeOptional
        \o message.numberOfOrders
        \o message.tradeId
        \o message.aggressorSide
        \o message.symbol
        \o message.securityGroup12
        \o message.securityType
        \o message.securitySubType
        \o EncodeMaturityMonthYear(message.maturityMonthYear)
        \o message.securityExchange4
        \o message.maturityDate
        \o message.unitOfMeasure
        \o message.unitOfMeasureCurrency3
        \o message.unitOfMeasureQtyOptional
        \o message.couponRate
        \o message.priceType
        \o message.trdType
        \o message.mdEntryId
        \o message.putOrCall
        \o message.strikePrice
        \o message.restructuringType
        \o message.seniority
        \o message.referenceId100
        \o message.strategyLinkId
        \o message.legRefId
        \o EncodeTradeBlocksUnderlyingsGroups(message.tradeBlocksUnderlyingsGroups)
        \o EncodeTradeBlocksPartyIdsGroups(message.tradeBlocksPartyIdsGroups)
        \o EncodeTradeBlocksOriginalLegsGroups(message.tradeBlocksOriginalLegsGroups)

DecodeTradeBlocksOriginalGroup(bytes) ==
    LET mdUpdateAction == ReadBytes(bytes, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdUpdateAction.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPxOptional == ReadBytes(rptSeq.rest, 8) IN IF ~mdEntryPxOptional.ok THEN Fail ELSE
    LET mdEntrySizeOptional == ReadBytes(mdEntryPxOptional.rest, 8) IN IF ~mdEntrySizeOptional.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(mdEntrySizeOptional.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET tradeId == ReadBytes(numberOfOrders.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(tradeId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET symbol == ReadBytes(aggressorSide.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup12 == ReadBytes(symbol.rest, 12) IN IF ~securityGroup12.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup12.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(securityType.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear(securitySubType.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET securityExchange4 == ReadBytes(maturityMonthYear.rest, 4) IN IF ~securityExchange4.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityExchange4.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(maturityDate.rest, 5) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureCurrency3 == ReadBytes(unitOfMeasure.rest, 3) IN IF ~unitOfMeasureCurrency3.ok THEN Fail ELSE
    LET unitOfMeasureQtyOptional == ReadBytes(unitOfMeasureCurrency3.rest, 8) IN IF ~unitOfMeasureQtyOptional.ok THEN Fail ELSE
    LET couponRate == ReadBytes(unitOfMeasureQtyOptional.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET priceType == ReadBytes(couponRate.rest, 2) IN IF ~priceType.ok THEN Fail ELSE
    LET trdType == ReadBytes(priceType.rest, 1) IN IF ~trdType.ok THEN Fail ELSE
    LET mdEntryId == ReadBytes(trdType.rest, 26) IN IF ~mdEntryId.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(mdEntryId.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET restructuringType == ReadBytes(strikePrice.rest, 2) IN IF ~restructuringType.ok THEN Fail ELSE
    LET seniority == ReadBytes(restructuringType.rest, 2) IN IF ~seniority.ok THEN Fail ELSE
    LET referenceId100 == ReadBytes(seniority.rest, 100) IN IF ~referenceId100.ok THEN Fail ELSE
    LET strategyLinkId == ReadBytes(referenceId100.rest, 26) IN IF ~strategyLinkId.ok THEN Fail ELSE
    LET legRefId == ReadBytes(strategyLinkId.rest, 17) IN IF ~legRefId.ok THEN Fail ELSE
    LET tradeBlocksUnderlyingsGroups == DecodeTradeBlocksUnderlyingsGroups(legRefId.rest) IN IF ~tradeBlocksUnderlyingsGroups.ok THEN Fail ELSE
    LET tradeBlocksPartyIdsGroups == DecodeTradeBlocksPartyIdsGroups(tradeBlocksUnderlyingsGroups.rest) IN IF ~tradeBlocksPartyIdsGroups.ok THEN Fail ELSE
    LET tradeBlocksOriginalLegsGroups == DecodeTradeBlocksOriginalLegsGroups(tradeBlocksPartyIdsGroups.rest) IN IF ~tradeBlocksOriginalLegsGroups.ok THEN Fail ELSE
    Ok([ mdUpdateAction                |-> mdUpdateAction.value,
         securityId                    |-> securityId.value,
         rptSeq                        |-> rptSeq.value,
         mdEntryPxOptional             |-> mdEntryPxOptional.value,
         mdEntrySizeOptional           |-> mdEntrySizeOptional.value,
         numberOfOrders                |-> numberOfOrders.value,
         tradeId                       |-> tradeId.value,
         aggressorSide                 |-> aggressorSide.value,
         symbol                        |-> symbol.value,
         securityGroup12               |-> securityGroup12.value,
         securityType                  |-> securityType.value,
         securitySubType               |-> securitySubType.value,
         maturityMonthYear             |-> maturityMonthYear.value,
         securityExchange4             |-> securityExchange4.value,
         maturityDate                  |-> maturityDate.value,
         unitOfMeasure                 |-> unitOfMeasure.value,
         unitOfMeasureCurrency3        |-> unitOfMeasureCurrency3.value,
         unitOfMeasureQtyOptional      |-> unitOfMeasureQtyOptional.value,
         couponRate                    |-> couponRate.value,
         priceType                     |-> priceType.value,
         trdType                       |-> trdType.value,
         mdEntryId                     |-> mdEntryId.value,
         putOrCall                     |-> putOrCall.value,
         strikePrice                   |-> strikePrice.value,
         restructuringType             |-> restructuringType.value,
         seniority                     |-> seniority.value,
         referenceId100                |-> referenceId100.value,
         strategyLinkId                |-> strategyLinkId.value,
         legRefId                      |-> legRefId.value,
         tradeBlocksUnderlyingsGroups  |-> tradeBlocksUnderlyingsGroups.value,
         tradeBlocksPartyIdsGroups     |-> tradeBlocksPartyIdsGroups.value,
         tradeBlocksOriginalLegsGroups |-> tradeBlocksOriginalLegsGroups.value ], tradeBlocksOriginalLegsGroups.rest)

ZeroTradeBlocksOriginalGroup ==
    [ mdUpdateAction                |-> [i \in 1 .. 1 |-> 0],
      securityId                    |-> [i \in 1 .. 8 |-> 0],
      rptSeq                        |-> [i \in 1 .. 4 |-> 0],
      mdEntryPxOptional             |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeOptional           |-> [i \in 1 .. 8 |-> 0],
      numberOfOrders                |-> [i \in 1 .. 4 |-> 0],
      tradeId                       |-> [i \in 1 .. 4 |-> 0],
      aggressorSide                 |-> [i \in 1 .. 1 |-> 0],
      symbol                        |-> [i \in 1 .. 50 |-> 0],
      securityGroup12               |-> [i \in 1 .. 12 |-> 0],
      securityType                  |-> [i \in 1 .. 9 |-> 0],
      securitySubType               |-> [i \in 1 .. 2 |-> 0],
      maturityMonthYear             |-> ZeroMaturityMonthYear,
      securityExchange4             |-> [i \in 1 .. 4 |-> 0],
      maturityDate                  |-> [i \in 1 .. 2 |-> 0],
      unitOfMeasure                 |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureCurrency3        |-> [i \in 1 .. 3 |-> 0],
      unitOfMeasureQtyOptional      |-> [i \in 1 .. 8 |-> 0],
      couponRate                    |-> [i \in 1 .. 4 |-> 0],
      priceType                     |-> [i \in 1 .. 2 |-> 0],
      trdType                       |-> [i \in 1 .. 1 |-> 0],
      mdEntryId                     |-> [i \in 1 .. 26 |-> 0],
      putOrCall                     |-> [i \in 1 .. 1 |-> 0],
      strikePrice                   |-> [i \in 1 .. 8 |-> 0],
      restructuringType             |-> [i \in 1 .. 2 |-> 0],
      seniority                     |-> [i \in 1 .. 2 |-> 0],
      referenceId100                |-> [i \in 1 .. 100 |-> 0],
      strategyLinkId                |-> [i \in 1 .. 26 |-> 0],
      legRefId                      |-> [i \in 1 .. 17 |-> 0],
      tradeBlocksUnderlyingsGroups  |-> ZeroTradeBlocksUnderlyingsGroups,
      tradeBlocksPartyIdsGroups     |-> ZeroTradeBlocksPartyIdsGroups,
      tradeBlocksOriginalLegsGroups |-> ZeroTradeBlocksOriginalLegsGroups ]

(* Trade Blocks Original Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksOriginalGroup ==
    { ZeroTradeBlocksOriginalGroup }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.mdEntryPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.mdEntrySizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.securityGroup12 = one] : one \in Sample(12) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.securityExchange4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.unitOfMeasureCurrency3 = one] : one \in Sample(3) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.unitOfMeasureQtyOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.priceType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.trdType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.mdEntryId = one] : one \in Sample(26) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.restructuringType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.seniority = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.referenceId100 = one] : one \in Sample(100) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.strategyLinkId = one] : one \in Sample(26) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.legRefId = one] : one \in Sample(17) }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.tradeBlocksUnderlyingsGroups = one] : one \in CheckedTradeBlocksUnderlyingsGroups }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.tradeBlocksPartyIdsGroups = one] : one \in CheckedTradeBlocksPartyIdsGroups }
        \cup { [ZeroTradeBlocksOriginalGroup EXCEPT !.tradeBlocksOriginalLegsGroups = one] : one \in CheckedTradeBlocksOriginalLegsGroups }

(* A run of Trade Blocks Original Group, written one after another *)
RECURSIVE EncodeTradeBlocksOriginalGroupList(_)
EncodeTradeBlocksOriginalGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksOriginalGroup(Head(messages)) \o EncodeTradeBlocksOriginalGroupList(Tail(messages))

(* As many Trade Blocks Original Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksOriginalGroupList(_, _)
ReadTradeBlocksOriginalGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksOriginalGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksOriginalGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Original Group of each kind, for the lists that carry them *)
OneTradeBlocksOriginalGroup == { ZeroTradeBlocksOriginalGroup }

(***************************************************************************)
(* Trade Blocks Original Groups                                            *)
(***************************************************************************)

TradeBlocksOriginalGroups ==
    [ blockLength              : Sample(2),
      tradeBlocksOriginalGroup : SampleLists(OneTradeBlocksOriginalGroup) ]

EncodeTradeBlocksOriginalGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksOriginalGroup), 1)
        \o EncodeTradeBlocksOriginalGroupList(message.tradeBlocksOriginalGroup)

DecodeTradeBlocksOriginalGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksOriginalGroup == ReadTradeBlocksOriginalGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksOriginalGroup.ok THEN Fail ELSE
    Ok([ blockLength              |-> blockLength.value,
         tradeBlocksOriginalGroup |-> tradeBlocksOriginalGroup.value ], tradeBlocksOriginalGroup.rest)

ZeroTradeBlocksOriginalGroups ==
    [ blockLength              |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksOriginalGroup |-> << >> ]

(* Trade Blocks Original Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksOriginalGroups ==
    { ZeroTradeBlocksOriginalGroups }
        \cup { [ZeroTradeBlocksOriginalGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalGroups EXCEPT !.tradeBlocksOriginalGroup = one] : one \in SampleLists(OneTradeBlocksOriginalGroup) }

(***************************************************************************)
(* Md Incremental Refresh Trade Blocks 340                                 *)
(***************************************************************************)

MdIncrementalRefreshTradeBlocks340 ==
    [ transactTime              : Sample(8),
      matchEventIndicator       : Sample(1),
      batchTotalMessages        : Sample(2),
      tradeBlocksOriginalGroups : TradeBlocksOriginalGroups ]

EncodeMdIncrementalRefreshTradeBlocks340(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.batchTotalMessages
        \o EncodeTradeBlocksOriginalGroups(message.tradeBlocksOriginalGroups)

DecodeMdIncrementalRefreshTradeBlocks340(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessages == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessages.ok THEN Fail ELSE
    LET tradeBlocksOriginalGroups == DecodeTradeBlocksOriginalGroups(batchTotalMessages.rest) IN IF ~tradeBlocksOriginalGroups.ok THEN Fail ELSE
    Ok([ transactTime              |-> transactTime.value,
         matchEventIndicator       |-> matchEventIndicator.value,
         batchTotalMessages        |-> batchTotalMessages.value,
         tradeBlocksOriginalGroups |-> tradeBlocksOriginalGroups.value ], tradeBlocksOriginalGroups.rest)

ZeroMdIncrementalRefreshTradeBlocks340 ==
    [ transactTime              |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator       |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessages        |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksOriginalGroups |-> ZeroTradeBlocksOriginalGroups ]

(* Md Incremental Refresh Trade Blocks 340 at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshTradeBlocks340 ==
    { ZeroMdIncrementalRefreshTradeBlocks340 }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks340 EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks340 EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks340 EXCEPT !.batchTotalMessages = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks340 EXCEPT !.tradeBlocksOriginalGroups = one] : one \in CheckedTradeBlocksOriginalGroups }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup2 ==
    [ eventTypeOptional : Sample(1),
      eventTimeOptional : Sample(8) ]

EncodeEventsGroup2(message) ==
    message.eventTypeOptional
        \o message.eventTimeOptional

DecodeEventsGroup2(bytes) ==
    LET eventTypeOptional == ReadBytes(bytes, 1) IN IF ~eventTypeOptional.ok THEN Fail ELSE
    LET eventTimeOptional == ReadBytes(eventTypeOptional.rest, 8) IN IF ~eventTimeOptional.ok THEN Fail ELSE
    Ok([ eventTypeOptional |-> eventTypeOptional.value,
         eventTimeOptional |-> eventTimeOptional.value ], eventTimeOptional.rest)

ZeroEventsGroup2 ==
    [ eventTypeOptional |-> [i \in 1 .. 1 |-> 0],
      eventTimeOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup2 ==
    { ZeroEventsGroup2 }
        \cup { [ZeroEventsGroup2 EXCEPT !.eventTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup2 EXCEPT !.eventTimeOptional = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup2List(_)
EncodeEventsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup2(Head(messages)) \o EncodeEventsGroup2List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup2List(_, _)
ReadEventsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup2 == { ZeroEventsGroup2 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups2 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup2) ]

EncodeEventsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup2List(message.eventsGroup)

DecodeEventsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup2List(numInGroup8.rest, numInGroup8.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups2 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups2 ==
    { ZeroEventsGroups2 }
        \cup { [ZeroEventsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups2 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup2) }

(***************************************************************************)
(* Quote Request Related Sym Group                                         *)
(***************************************************************************)

QuoteRequestRelatedSymGroup ==
    [ symbol           : Sample(50),
      couponRate       : Sample(4),
      orderQty         : Sample(8),
      securityExchange : Sample(4),
      productOptional  : Sample(1),
      securityGroup26  : Sample(26),
      maturityDate     : Sample(2),
      securityType4    : Sample(4),
      quoteType        : Sample(1),
      eventsGroups     : EventsGroups2 ]

EncodeQuoteRequestRelatedSymGroup(message) ==
    message.symbol
        \o message.couponRate
        \o message.orderQty
        \o message.securityExchange
        \o message.productOptional
        \o message.securityGroup26
        \o message.maturityDate
        \o message.securityType4
        \o message.quoteType
        \o EncodeEventsGroups2(message.eventsGroups)

DecodeQuoteRequestRelatedSymGroup(bytes) ==
    LET symbol == ReadBytes(bytes, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET couponRate == ReadBytes(symbol.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET orderQty == ReadBytes(couponRate.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(orderQty.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET productOptional == ReadBytes(securityExchange.rest, 1) IN IF ~productOptional.ok THEN Fail ELSE
    LET securityGroup26 == ReadBytes(productOptional.rest, 26) IN IF ~securityGroup26.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityGroup26.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET securityType4 == ReadBytes(maturityDate.rest, 4) IN IF ~securityType4.ok THEN Fail ELSE
    LET quoteType == ReadBytes(securityType4.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups2(quoteType.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    Ok([ symbol           |-> symbol.value,
         couponRate       |-> couponRate.value,
         orderQty         |-> orderQty.value,
         securityExchange |-> securityExchange.value,
         productOptional  |-> productOptional.value,
         securityGroup26  |-> securityGroup26.value,
         maturityDate     |-> maturityDate.value,
         securityType4    |-> securityType4.value,
         quoteType        |-> quoteType.value,
         eventsGroups     |-> eventsGroups.value ], eventsGroups.rest)

ZeroQuoteRequestRelatedSymGroup ==
    [ symbol           |-> [i \in 1 .. 50 |-> 0],
      couponRate       |-> [i \in 1 .. 4 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      securityExchange |-> [i \in 1 .. 4 |-> 0],
      productOptional  |-> [i \in 1 .. 1 |-> 0],
      securityGroup26  |-> [i \in 1 .. 26 |-> 0],
      maturityDate     |-> [i \in 1 .. 2 |-> 0],
      securityType4    |-> [i \in 1 .. 4 |-> 0],
      quoteType        |-> [i \in 1 .. 1 |-> 0],
      eventsGroups     |-> ZeroEventsGroups2 ]

(* Quote Request Related Sym Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestRelatedSymGroup ==
    { ZeroQuoteRequestRelatedSymGroup }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.productOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.securityGroup26 = one] : one \in Sample(26) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.securityType4 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestRelatedSymGroup EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups2 }

(* A run of Quote Request Related Sym Group, written one after another *)
RECURSIVE EncodeQuoteRequestRelatedSymGroupList(_)
EncodeQuoteRequestRelatedSymGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteRequestRelatedSymGroup(Head(messages)) \o EncodeQuoteRequestRelatedSymGroupList(Tail(messages))

(* As many Quote Request Related Sym Group as the field that counts them says *)
RECURSIVE ReadQuoteRequestRelatedSymGroupList(_, _)
ReadQuoteRequestRelatedSymGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteRequestRelatedSymGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteRequestRelatedSymGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Request Related Sym Group of each kind, for the lists that carry them *)
OneQuoteRequestRelatedSymGroup == { ZeroQuoteRequestRelatedSymGroup }

(***************************************************************************)
(* Quote Request Related Sym Groups                                        *)
(***************************************************************************)

QuoteRequestRelatedSymGroups ==
    [ blockLength                 : Sample(2),
      quoteRequestRelatedSymGroup : SampleLists(OneQuoteRequestRelatedSymGroup) ]

EncodeQuoteRequestRelatedSymGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.quoteRequestRelatedSymGroup), 1)
        \o EncodeQuoteRequestRelatedSymGroupList(message.quoteRequestRelatedSymGroup)

DecodeQuoteRequestRelatedSymGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET quoteRequestRelatedSymGroup == ReadQuoteRequestRelatedSymGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~quoteRequestRelatedSymGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         quoteRequestRelatedSymGroup |-> quoteRequestRelatedSymGroup.value ], quoteRequestRelatedSymGroup.rest)

ZeroQuoteRequestRelatedSymGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      quoteRequestRelatedSymGroup |-> << >> ]

(* Quote Request Related Sym Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestRelatedSymGroups ==
    { ZeroQuoteRequestRelatedSymGroups }
        \cup { [ZeroQuoteRequestRelatedSymGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroQuoteRequestRelatedSymGroups EXCEPT !.quoteRequestRelatedSymGroup = one] : one \in SampleLists(OneQuoteRequestRelatedSymGroup) }

(***************************************************************************)
(* Quote Request                                                           *)
(***************************************************************************)

QuoteRequest ==
    [ transactTime                 : Sample(8),
      matchEventIndicator          : Sample(1),
      quoteReqId                   : Sample(26),
      quoteRequestRelatedSymGroups : QuoteRequestRelatedSymGroups ]

EncodeQuoteRequest(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.quoteReqId
        \o EncodeQuoteRequestRelatedSymGroups(message.quoteRequestRelatedSymGroups)

DecodeQuoteRequest(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(matchEventIndicator.rest, 26) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET quoteRequestRelatedSymGroups == DecodeQuoteRequestRelatedSymGroups(quoteReqId.rest) IN IF ~quoteRequestRelatedSymGroups.ok THEN Fail ELSE
    Ok([ transactTime                 |-> transactTime.value,
         matchEventIndicator          |-> matchEventIndicator.value,
         quoteReqId                   |-> quoteReqId.value,
         quoteRequestRelatedSymGroups |-> quoteRequestRelatedSymGroups.value ], quoteRequestRelatedSymGroups.rest)

ZeroQuoteRequest ==
    [ transactTime                 |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator          |-> [i \in 1 .. 1 |-> 0],
      quoteReqId                   |-> [i \in 1 .. 26 |-> 0],
      quoteRequestRelatedSymGroups |-> ZeroQuoteRequestRelatedSymGroups ]

(* Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequest ==
    { ZeroQuoteRequest }
        \cup { [ZeroQuoteRequest EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequest EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequest EXCEPT !.quoteReqId = one] : one \in Sample(26) }
        \cup { [ZeroQuoteRequest EXCEPT !.quoteRequestRelatedSymGroups = one] : one \in CheckedQuoteRequestRelatedSymGroups }

(***************************************************************************)
(* Inst Attrib Group: 101 bytes                                            *)
(***************************************************************************)

InstAttribGroup ==
    [ instAttribType  : Sample(1),
      instAttribValue : Sample(100) ]

EncodeInstAttribGroup(message) ==
    message.instAttribType
        \o message.instAttribValue

DecodeInstAttribGroup(bytes) ==
    LET instAttribType == ReadBytes(bytes, 1) IN IF ~instAttribType.ok THEN Fail ELSE
    LET instAttribValue == ReadBytes(instAttribType.rest, 100) IN IF ~instAttribValue.ok THEN Fail ELSE
    Ok([ instAttribType  |-> instAttribType.value,
         instAttribValue |-> instAttribValue.value ], instAttribValue.rest)

ZeroInstAttribGroup ==
    [ instAttribType  |-> [i \in 1 .. 1 |-> 0],
      instAttribValue |-> [i \in 1 .. 100 |-> 0] ]

(* Inst Attrib Group at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroup ==
    { ZeroInstAttribGroup }
        \cup { [ZeroInstAttribGroup EXCEPT !.instAttribType = one] : one \in Sample(1) }
        \cup { [ZeroInstAttribGroup EXCEPT !.instAttribValue = one] : one \in Sample(100) }

(* A run of Inst Attrib Group, written one after another *)
RECURSIVE EncodeInstAttribGroupList(_)
EncodeInstAttribGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstAttribGroup(Head(messages)) \o EncodeInstAttribGroupList(Tail(messages))

(* As many Inst Attrib Group as the field that counts them says *)
RECURSIVE ReadInstAttribGroupList(_, _)
ReadInstAttribGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstAttribGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstAttribGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Inst Attrib Group of each kind, for the lists that carry them *)
OneInstAttribGroup == { ZeroInstAttribGroup }

(***************************************************************************)
(* Inst Attrib Groups                                                      *)
(***************************************************************************)

InstAttribGroups ==
    [ blockLength     : Sample(2),
      instAttribGroup : SampleLists(OneInstAttribGroup) ]

EncodeInstAttribGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.instAttribGroup), 2)
        \o EncodeInstAttribGroupList(message.instAttribGroup)

DecodeInstAttribGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instAttribGroup == ReadInstAttribGroupList(numInGroup.rest, numInGroup.value) IN IF ~instAttribGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         instAttribGroup |-> instAttribGroup.value ], instAttribGroup.rest)

ZeroInstAttribGroups ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      instAttribGroup |-> << >> ]

(* Inst Attrib Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroups ==
    { ZeroInstAttribGroups }
        \cup { [ZeroInstAttribGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstAttribGroups EXCEPT !.instAttribGroup = one] : one \in SampleLists(OneInstAttribGroup) }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup3 ==
    [ eventTypeOptional : Sample(1),
      eventTimeOptional : Sample(8) ]

EncodeEventsGroup3(message) ==
    message.eventTypeOptional
        \o message.eventTimeOptional

DecodeEventsGroup3(bytes) ==
    LET eventTypeOptional == ReadBytes(bytes, 1) IN IF ~eventTypeOptional.ok THEN Fail ELSE
    LET eventTimeOptional == ReadBytes(eventTypeOptional.rest, 8) IN IF ~eventTimeOptional.ok THEN Fail ELSE
    Ok([ eventTypeOptional |-> eventTypeOptional.value,
         eventTimeOptional |-> eventTimeOptional.value ], eventTimeOptional.rest)

ZeroEventsGroup3 ==
    [ eventTypeOptional |-> [i \in 1 .. 1 |-> 0],
      eventTimeOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup3 ==
    { ZeroEventsGroup3 }
        \cup { [ZeroEventsGroup3 EXCEPT !.eventTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup3 EXCEPT !.eventTimeOptional = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup3List(_)
EncodeEventsGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup3(Head(messages)) \o EncodeEventsGroup3List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup3List(_, _)
ReadEventsGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup3 == { ZeroEventsGroup3 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups3 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup3) ]

EncodeEventsGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup3List(message.eventsGroup)

DecodeEventsGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup3List(numInGroup8.rest, numInGroup8.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups3 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups3 ==
    { ZeroEventsGroups3 }
        \cup { [ZeroEventsGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups3 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup3) }

(***************************************************************************)
(* Md Instrument Definition Indices                                        *)
(***************************************************************************)

MdInstrumentDefinitionIndices ==
    [ symbol               : Sample(50),
      product              : Sample(1),
      securityExchange     : Sample(4),
      currency             : Sample(3),
      securityUpdateAction : Sample(1),
      mdFeedType           : Sample(2),
      applId               : Sample(2),
      instAttribGroups     : InstAttribGroups,
      eventsGroups         : EventsGroups3 ]

EncodeMdInstrumentDefinitionIndices(message) ==
    message.symbol
        \o message.product
        \o message.securityExchange
        \o message.currency
        \o message.securityUpdateAction
        \o message.mdFeedType
        \o message.applId
        \o EncodeInstAttribGroups(message.instAttribGroups)
        \o EncodeEventsGroups3(message.eventsGroups)

DecodeMdInstrumentDefinitionIndices(bytes) ==
    LET symbol == ReadBytes(bytes, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET product == ReadBytes(symbol.rest, 1) IN IF ~product.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(product.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET currency == ReadBytes(securityExchange.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(currency.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET mdFeedType == ReadBytes(securityUpdateAction.rest, 2) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET applId == ReadBytes(mdFeedType.rest, 2) IN IF ~applId.ok THEN Fail ELSE
    LET instAttribGroups == DecodeInstAttribGroups(applId.rest) IN IF ~instAttribGroups.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups3(instAttribGroups.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    Ok([ symbol               |-> symbol.value,
         product              |-> product.value,
         securityExchange     |-> securityExchange.value,
         currency             |-> currency.value,
         securityUpdateAction |-> securityUpdateAction.value,
         mdFeedType           |-> mdFeedType.value,
         applId               |-> applId.value,
         instAttribGroups     |-> instAttribGroups.value,
         eventsGroups         |-> eventsGroups.value ], eventsGroups.rest)

ZeroMdInstrumentDefinitionIndices ==
    [ symbol               |-> [i \in 1 .. 50 |-> 0],
      product              |-> [i \in 1 .. 1 |-> 0],
      securityExchange     |-> [i \in 1 .. 4 |-> 0],
      currency             |-> [i \in 1 .. 3 |-> 0],
      securityUpdateAction |-> [i \in 1 .. 1 |-> 0],
      mdFeedType           |-> [i \in 1 .. 2 |-> 0],
      applId               |-> [i \in 1 .. 2 |-> 0],
      instAttribGroups     |-> ZeroInstAttribGroups,
      eventsGroups         |-> ZeroEventsGroups3 ]

(* Md Instrument Definition Indices at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentDefinitionIndices ==
    { ZeroMdInstrumentDefinitionIndices }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.product = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.mdFeedType = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.applId = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.instAttribGroups = one] : one \in CheckedInstAttribGroups }
        \cup { [ZeroMdInstrumentDefinitionIndices EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups3 }

(***************************************************************************)
(* Md Entry Px Decimal: 9 bytes                                            *)
(***************************************************************************)

MdEntryPxDecimal ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntryPxDecimal(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntryPxDecimal(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntryPxDecimal ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Px Decimal at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPxDecimal ==
    { ZeroMdEntryPxDecimal }
        \cup { [ZeroMdEntryPxDecimal EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntryPxDecimal EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Yield: 9 bytes                                                          *)
(***************************************************************************)

Yield ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeYield(message) ==
    message.mantissa
        \o message.exponent

DecodeYield(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroYield ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Yield at zero, then each field in turn at the values it is checked at *)
CheckedYield ==
    { ZeroYield }
        \cup { [ZeroYield EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroYield EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Net Chg Prev Day: 9 bytes                                               *)
(***************************************************************************)

NetChgPrevDay ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeNetChgPrevDay(message) ==
    message.mantissa
        \o message.exponent

DecodeNetChgPrevDay(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroNetChgPrevDay ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Net Chg Prev Day at zero, then each field in turn at the values it is checked at *)
CheckedNetChgPrevDay ==
    { ZeroNetChgPrevDay }
        \cup { [ZeroNetChgPrevDay EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroNetChgPrevDay EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Net Pct Chg: 9 bytes                                                    *)
(***************************************************************************)

NetPctChg ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeNetPctChg(message) ==
    message.mantissa
        \o message.exponent

DecodeNetPctChg(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroNetPctChg ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Net Pct Chg at zero, then each field in turn at the values it is checked at *)
CheckedNetPctChg ==
    { ZeroNetPctChg }
        \cup { [ZeroNetPctChg EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroNetPctChg EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Percent Trading: 9 bytes                                                *)
(***************************************************************************)

PercentTrading ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodePercentTrading(message) ==
    message.mantissa
        \o message.exponent

DecodePercentTrading(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroPercentTrading ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Percent Trading at zero, then each field in turn at the values it is checked at *)
CheckedPercentTrading ==
    { ZeroPercentTrading }
        \cup { [ZeroPercentTrading EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroPercentTrading EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Incremental Refresh Indices Group: 176 bytes                            *)
(***************************************************************************)

IncrementalRefreshIndicesGroup ==
    [ mdEntryTypeIndices  : Sample(1),
      rptSeq              : Sample(4),
      mdEntryPxDecimal    : MdEntryPxDecimal,
      mdEntrySizeOptional : Sample(8),
      symbol              : Sample(50),
      openCloseSettlFlag  : Sample(1),
      yieldType           : Sample(8),
      yield               : Yield,
      netChgPrevDay       : NetChgPrevDay,
      netPctChg           : NetPctChg,
      percentTrading      : PercentTrading,
      mdEntryCode         : Sample(1),
      mdEntryDate         : Sample(4),
      mdEntryTime         : Sample(4),
      referenceId50       : Sample(50) ]

EncodeIncrementalRefreshIndicesGroup(message) ==
    message.mdEntryTypeIndices
        \o message.rptSeq
        \o EncodeMdEntryPxDecimal(message.mdEntryPxDecimal)
        \o message.mdEntrySizeOptional
        \o message.symbol
        \o message.openCloseSettlFlag
        \o message.yieldType
        \o EncodeYield(message.yield)
        \o EncodeNetChgPrevDay(message.netChgPrevDay)
        \o EncodeNetPctChg(message.netPctChg)
        \o EncodePercentTrading(message.percentTrading)
        \o message.mdEntryCode
        \o message.mdEntryDate
        \o message.mdEntryTime
        \o message.referenceId50

DecodeIncrementalRefreshIndicesGroup(bytes) ==
    LET mdEntryTypeIndices == ReadBytes(bytes, 1) IN IF ~mdEntryTypeIndices.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTypeIndices.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPxDecimal == DecodeMdEntryPxDecimal(rptSeq.rest) IN IF ~mdEntryPxDecimal.ok THEN Fail ELSE
    LET mdEntrySizeOptional == ReadBytes(mdEntryPxDecimal.rest, 8) IN IF ~mdEntrySizeOptional.ok THEN Fail ELSE
    LET symbol == ReadBytes(mdEntrySizeOptional.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(symbol.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET yieldType == ReadBytes(openCloseSettlFlag.rest, 8) IN IF ~yieldType.ok THEN Fail ELSE
    LET yield == DecodeYield(yieldType.rest) IN IF ~yield.ok THEN Fail ELSE
    LET netChgPrevDay == DecodeNetChgPrevDay(yield.rest) IN IF ~netChgPrevDay.ok THEN Fail ELSE
    LET netPctChg == DecodeNetPctChg(netChgPrevDay.rest) IN IF ~netPctChg.ok THEN Fail ELSE
    LET percentTrading == DecodePercentTrading(netPctChg.rest) IN IF ~percentTrading.ok THEN Fail ELSE
    LET mdEntryCode == ReadBytes(percentTrading.rest, 1) IN IF ~mdEntryCode.ok THEN Fail ELSE
    LET mdEntryDate == ReadBytes(mdEntryCode.rest, 4) IN IF ~mdEntryDate.ok THEN Fail ELSE
    LET mdEntryTime == ReadBytes(mdEntryDate.rest, 4) IN IF ~mdEntryTime.ok THEN Fail ELSE
    LET referenceId50 == ReadBytes(mdEntryTime.rest, 50) IN IF ~referenceId50.ok THEN Fail ELSE
    Ok([ mdEntryTypeIndices  |-> mdEntryTypeIndices.value,
         rptSeq              |-> rptSeq.value,
         mdEntryPxDecimal    |-> mdEntryPxDecimal.value,
         mdEntrySizeOptional |-> mdEntrySizeOptional.value,
         symbol              |-> symbol.value,
         openCloseSettlFlag  |-> openCloseSettlFlag.value,
         yieldType           |-> yieldType.value,
         yield               |-> yield.value,
         netChgPrevDay       |-> netChgPrevDay.value,
         netPctChg           |-> netPctChg.value,
         percentTrading      |-> percentTrading.value,
         mdEntryCode         |-> mdEntryCode.value,
         mdEntryDate         |-> mdEntryDate.value,
         mdEntryTime         |-> mdEntryTime.value,
         referenceId50       |-> referenceId50.value ], referenceId50.rest)

ZeroIncrementalRefreshIndicesGroup ==
    [ mdEntryTypeIndices  |-> [i \in 1 .. 1 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      mdEntryPxDecimal    |-> ZeroMdEntryPxDecimal,
      mdEntrySizeOptional |-> [i \in 1 .. 8 |-> 0],
      symbol              |-> [i \in 1 .. 50 |-> 0],
      openCloseSettlFlag  |-> [i \in 1 .. 1 |-> 0],
      yieldType           |-> [i \in 1 .. 8 |-> 0],
      yield               |-> ZeroYield,
      netChgPrevDay       |-> ZeroNetChgPrevDay,
      netPctChg           |-> ZeroNetPctChg,
      percentTrading      |-> ZeroPercentTrading,
      mdEntryCode         |-> [i \in 1 .. 1 |-> 0],
      mdEntryDate         |-> [i \in 1 .. 4 |-> 0],
      mdEntryTime         |-> [i \in 1 .. 4 |-> 0],
      referenceId50       |-> [i \in 1 .. 50 |-> 0] ]

(* Incremental Refresh Indices Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshIndicesGroup ==
    { ZeroIncrementalRefreshIndicesGroup }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.mdEntryTypeIndices = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.mdEntryPxDecimal = one] : one \in CheckedMdEntryPxDecimal }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.mdEntrySizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.yieldType = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.yield = one] : one \in CheckedYield }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.netChgPrevDay = one] : one \in CheckedNetChgPrevDay }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.netPctChg = one] : one \in CheckedNetPctChg }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.percentTrading = one] : one \in CheckedPercentTrading }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.mdEntryCode = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.mdEntryDate = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.mdEntryTime = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshIndicesGroup EXCEPT !.referenceId50 = one] : one \in Sample(50) }

(* A run of Incremental Refresh Indices Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshIndicesGroupList(_)
EncodeIncrementalRefreshIndicesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshIndicesGroup(Head(messages)) \o EncodeIncrementalRefreshIndicesGroupList(Tail(messages))

(* As many Incremental Refresh Indices Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshIndicesGroupList(_, _)
ReadIncrementalRefreshIndicesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshIndicesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshIndicesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Indices Group of each kind, for the lists that carry them *)
OneIncrementalRefreshIndicesGroup == { ZeroIncrementalRefreshIndicesGroup }

(***************************************************************************)
(* Incremental Refresh Indices Groups                                      *)
(***************************************************************************)

IncrementalRefreshIndicesGroups ==
    [ blockLength                    : Sample(2),
      incrementalRefreshIndicesGroup : SampleLists(OneIncrementalRefreshIndicesGroup) ]

EncodeIncrementalRefreshIndicesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshIndicesGroup), 1)
        \o EncodeIncrementalRefreshIndicesGroupList(message.incrementalRefreshIndicesGroup)

DecodeIncrementalRefreshIndicesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET incrementalRefreshIndicesGroup == ReadIncrementalRefreshIndicesGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~incrementalRefreshIndicesGroup.ok THEN Fail ELSE
    Ok([ blockLength                    |-> blockLength.value,
         incrementalRefreshIndicesGroup |-> incrementalRefreshIndicesGroup.value ], incrementalRefreshIndicesGroup.rest)

ZeroIncrementalRefreshIndicesGroups ==
    [ blockLength                    |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshIndicesGroup |-> << >> ]

(* Incremental Refresh Indices Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshIndicesGroups ==
    { ZeroIncrementalRefreshIndicesGroups }
        \cup { [ZeroIncrementalRefreshIndicesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshIndicesGroups EXCEPT !.incrementalRefreshIndicesGroup = one] : one \in SampleLists(OneIncrementalRefreshIndicesGroup) }

(***************************************************************************)
(* Md Incremental Refresh Indices                                          *)
(***************************************************************************)

MdIncrementalRefreshIndices ==
    [ transactTime                    : Sample(8),
      mdFeedType                      : Sample(2),
      matchEventIndicator             : Sample(1),
      batchTotalMessagesOptional      : Sample(2),
      incrementalRefreshIndicesGroups : IncrementalRefreshIndicesGroups ]

EncodeMdIncrementalRefreshIndices(message) ==
    message.transactTime
        \o message.mdFeedType
        \o message.matchEventIndicator
        \o message.batchTotalMessagesOptional
        \o EncodeIncrementalRefreshIndicesGroups(message.incrementalRefreshIndicesGroups)

DecodeMdIncrementalRefreshIndices(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mdFeedType == ReadBytes(transactTime.rest, 2) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(mdFeedType.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessagesOptional == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessagesOptional.ok THEN Fail ELSE
    LET incrementalRefreshIndicesGroups == DecodeIncrementalRefreshIndicesGroups(batchTotalMessagesOptional.rest) IN IF ~incrementalRefreshIndicesGroups.ok THEN Fail ELSE
    Ok([ transactTime                    |-> transactTime.value,
         mdFeedType                      |-> mdFeedType.value,
         matchEventIndicator             |-> matchEventIndicator.value,
         batchTotalMessagesOptional      |-> batchTotalMessagesOptional.value,
         incrementalRefreshIndicesGroups |-> incrementalRefreshIndicesGroups.value ], incrementalRefreshIndicesGroups.rest)

ZeroMdIncrementalRefreshIndices ==
    [ transactTime                    |-> [i \in 1 .. 8 |-> 0],
      mdFeedType                      |-> [i \in 1 .. 2 |-> 0],
      matchEventIndicator             |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessagesOptional      |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshIndicesGroups |-> ZeroIncrementalRefreshIndicesGroups ]

(* Md Incremental Refresh Indices at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshIndices ==
    { ZeroMdIncrementalRefreshIndices }
        \cup { [ZeroMdIncrementalRefreshIndices EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshIndices EXCEPT !.mdFeedType = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshIndices EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshIndices EXCEPT !.batchTotalMessagesOptional = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshIndices EXCEPT !.incrementalRefreshIndicesGroups = one] : one \in CheckedIncrementalRefreshIndicesGroups }

(***************************************************************************)
(* Md Entry Size: 9 bytes                                                  *)
(***************************************************************************)

MdEntrySize ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntrySize(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntrySize(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntrySize ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Size at zero, then each field in turn at the values it is checked at *)
CheckedMdEntrySize ==
    { ZeroMdEntrySize }
        \cup { [ZeroMdEntrySize EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntrySize EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear2 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear2(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear2 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear2 ==
    { ZeroMaturityMonthYear2 }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear2 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear2(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear2 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear2 ==
    { ZeroUnderlyingMaturityMonthYear2 }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear2 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Blocks Underlyings Group: 68 bytes                                *)
(***************************************************************************)

TradeBlocksUnderlyingsGroup2 ==
    [ underlyingSymbol                  : Sample(50),
      underlyingMaturityMonthYear       : UnderlyingMaturityMonthYear2,
      underlyingSecurityType            : Sample(9),
      underlyingSecurityExchangeString4 : Sample(4) ]

EncodeTradeBlocksUnderlyingsGroup2(message) ==
    message.underlyingSymbol
        \o EncodeUnderlyingMaturityMonthYear2(message.underlyingMaturityMonthYear)
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchangeString4

DecodeTradeBlocksUnderlyingsGroup2(bytes) ==
    LET underlyingSymbol == ReadBytes(bytes, 50) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear2(underlyingSymbol.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingMaturityMonthYear.rest, 9) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchangeString4 == ReadBytes(underlyingSecurityType.rest, 4) IN IF ~underlyingSecurityExchangeString4.ok THEN Fail ELSE
    Ok([ underlyingSymbol                  |-> underlyingSymbol.value,
         underlyingMaturityMonthYear       |-> underlyingMaturityMonthYear.value,
         underlyingSecurityType            |-> underlyingSecurityType.value,
         underlyingSecurityExchangeString4 |-> underlyingSecurityExchangeString4.value ], underlyingSecurityExchangeString4.rest)

ZeroTradeBlocksUnderlyingsGroup2 ==
    [ underlyingSymbol                  |-> [i \in 1 .. 50 |-> 0],
      underlyingMaturityMonthYear       |-> ZeroUnderlyingMaturityMonthYear2,
      underlyingSecurityType            |-> [i \in 1 .. 9 |-> 0],
      underlyingSecurityExchangeString4 |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Blocks Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksUnderlyingsGroup2 ==
    { ZeroTradeBlocksUnderlyingsGroup2 }
        \cup { [ZeroTradeBlocksUnderlyingsGroup2 EXCEPT !.underlyingSymbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksUnderlyingsGroup2 EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear2 }
        \cup { [ZeroTradeBlocksUnderlyingsGroup2 EXCEPT !.underlyingSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksUnderlyingsGroup2 EXCEPT !.underlyingSecurityExchangeString4 = one] : one \in Sample(4) }

(* A run of Trade Blocks Underlyings Group, written one after another *)
RECURSIVE EncodeTradeBlocksUnderlyingsGroup2List(_)
EncodeTradeBlocksUnderlyingsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksUnderlyingsGroup2(Head(messages)) \o EncodeTradeBlocksUnderlyingsGroup2List(Tail(messages))

(* As many Trade Blocks Underlyings Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksUnderlyingsGroup2List(_, _)
ReadTradeBlocksUnderlyingsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksUnderlyingsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksUnderlyingsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Underlyings Group of each kind, for the lists that carry them *)
OneTradeBlocksUnderlyingsGroup2 == { ZeroTradeBlocksUnderlyingsGroup2 }

(***************************************************************************)
(* Trade Blocks Underlyings Groups                                         *)
(***************************************************************************)

TradeBlocksUnderlyingsGroups2 ==
    [ blockLength                 : Sample(2),
      tradeBlocksUnderlyingsGroup : SampleLists(OneTradeBlocksUnderlyingsGroup2) ]

EncodeTradeBlocksUnderlyingsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksUnderlyingsGroup), 1)
        \o EncodeTradeBlocksUnderlyingsGroup2List(message.tradeBlocksUnderlyingsGroup)

DecodeTradeBlocksUnderlyingsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksUnderlyingsGroup == ReadTradeBlocksUnderlyingsGroup2List(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         tradeBlocksUnderlyingsGroup |-> tradeBlocksUnderlyingsGroup.value ], tradeBlocksUnderlyingsGroup.rest)

ZeroTradeBlocksUnderlyingsGroups2 ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksUnderlyingsGroup |-> << >> ]

(* Trade Blocks Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksUnderlyingsGroups2 ==
    { ZeroTradeBlocksUnderlyingsGroups2 }
        \cup { [ZeroTradeBlocksUnderlyingsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksUnderlyingsGroups2 EXCEPT !.tradeBlocksUnderlyingsGroup = one] : one \in SampleLists(OneTradeBlocksUnderlyingsGroup2) }

(***************************************************************************)
(* Trade Blocks Party Ids Group: 52 bytes                                  *)
(***************************************************************************)

TradeBlocksPartyIdsGroup2 ==
    [ partyId   : Sample(50),
      partyRole : Sample(2) ]

EncodeTradeBlocksPartyIdsGroup2(message) ==
    message.partyId
        \o message.partyRole

DecodeTradeBlocksPartyIdsGroup2(bytes) ==
    LET partyId == ReadBytes(bytes, 50) IN IF ~partyId.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyId.rest, 2) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId   |-> partyId.value,
         partyRole |-> partyRole.value ], partyRole.rest)

ZeroTradeBlocksPartyIdsGroup2 ==
    [ partyId   |-> [i \in 1 .. 50 |-> 0],
      partyRole |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Blocks Party Ids Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksPartyIdsGroup2 ==
    { ZeroTradeBlocksPartyIdsGroup2 }
        \cup { [ZeroTradeBlocksPartyIdsGroup2 EXCEPT !.partyId = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksPartyIdsGroup2 EXCEPT !.partyRole = one] : one \in Sample(2) }

(* A run of Trade Blocks Party Ids Group, written one after another *)
RECURSIVE EncodeTradeBlocksPartyIdsGroup2List(_)
EncodeTradeBlocksPartyIdsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksPartyIdsGroup2(Head(messages)) \o EncodeTradeBlocksPartyIdsGroup2List(Tail(messages))

(* As many Trade Blocks Party Ids Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksPartyIdsGroup2List(_, _)
ReadTradeBlocksPartyIdsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksPartyIdsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksPartyIdsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Party Ids Group of each kind, for the lists that carry them *)
OneTradeBlocksPartyIdsGroup2 == { ZeroTradeBlocksPartyIdsGroup2 }

(***************************************************************************)
(* Trade Blocks Party Ids Groups                                           *)
(***************************************************************************)

TradeBlocksPartyIdsGroups2 ==
    [ blockLength              : Sample(2),
      tradeBlocksPartyIdsGroup : SampleLists(OneTradeBlocksPartyIdsGroup2) ]

EncodeTradeBlocksPartyIdsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksPartyIdsGroup), 1)
        \o EncodeTradeBlocksPartyIdsGroup2List(message.tradeBlocksPartyIdsGroup)

DecodeTradeBlocksPartyIdsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksPartyIdsGroup == ReadTradeBlocksPartyIdsGroup2List(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksPartyIdsGroup.ok THEN Fail ELSE
    Ok([ blockLength              |-> blockLength.value,
         tradeBlocksPartyIdsGroup |-> tradeBlocksPartyIdsGroup.value ], tradeBlocksPartyIdsGroup.rest)

ZeroTradeBlocksPartyIdsGroups2 ==
    [ blockLength              |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksPartyIdsGroup |-> << >> ]

(* Trade Blocks Party Ids Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksPartyIdsGroups2 ==
    { ZeroTradeBlocksPartyIdsGroups2 }
        \cup { [ZeroTradeBlocksPartyIdsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksPartyIdsGroups2 EXCEPT !.tradeBlocksPartyIdsGroup = one] : one \in SampleLists(OneTradeBlocksPartyIdsGroup2) }

(***************************************************************************)
(* Leg Maturity Month Year: 5 bytes                                        *)
(***************************************************************************)

LegMaturityMonthYear2 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeLegMaturityMonthYear2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeLegMaturityMonthYear2(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroLegMaturityMonthYear2 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedLegMaturityMonthYear2 ==
    { ZeroLegMaturityMonthYear2 }
        \cup { [ZeroLegMaturityMonthYear2 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLegMaturityMonthYear2 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroLegMaturityMonthYear2 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroLegMaturityMonthYear2 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Blocks Original Legs Group: 135 bytes                             *)
(***************************************************************************)

TradeBlocksOriginalLegsGroup2 ==
    [ legSymbol                    : Sample(50),
      legSecurityId                : Sample(8),
      legSecurityGroup             : Sample(12),
      legId                        : Sample(17),
      legSecurityType              : Sample(9),
      legMaturityMonthYear         : LegMaturityMonthYear2,
      legMaturityDate              : Sample(2),
      legStrikePricePricenull      : Sample(8),
      legUnitOfMeasure             : Sample(5),
      legUnitOfMeasureQtyPricenull : Sample(8),
      legSecurityExchange          : Sample(4),
      legRatioQtyUInt16Null        : Sample(2),
      legSide                      : Sample(1),
      legPutOrCall                 : Sample(1),
      legUnitOfMeasureCurrency     : Sample(3) ]

EncodeTradeBlocksOriginalLegsGroup2(message) ==
    message.legSymbol
        \o message.legSecurityId
        \o message.legSecurityGroup
        \o message.legId
        \o message.legSecurityType
        \o EncodeLegMaturityMonthYear2(message.legMaturityMonthYear)
        \o message.legMaturityDate
        \o message.legStrikePricePricenull
        \o message.legUnitOfMeasure
        \o message.legUnitOfMeasureQtyPricenull
        \o message.legSecurityExchange
        \o message.legRatioQtyUInt16Null
        \o message.legSide
        \o message.legPutOrCall
        \o message.legUnitOfMeasureCurrency

DecodeTradeBlocksOriginalLegsGroup2(bytes) ==
    LET legSymbol == ReadBytes(bytes, 50) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legSymbol.rest, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legSecurityGroup == ReadBytes(legSecurityId.rest, 12) IN IF ~legSecurityGroup.ok THEN Fail ELSE
    LET legId == ReadBytes(legSecurityGroup.rest, 17) IN IF ~legId.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legId.rest, 9) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legMaturityMonthYear == DecodeLegMaturityMonthYear2(legSecurityType.rest) IN IF ~legMaturityMonthYear.ok THEN Fail ELSE
    LET legMaturityDate == ReadBytes(legMaturityMonthYear.rest, 2) IN IF ~legMaturityDate.ok THEN Fail ELSE
    LET legStrikePricePricenull == ReadBytes(legMaturityDate.rest, 8) IN IF ~legStrikePricePricenull.ok THEN Fail ELSE
    LET legUnitOfMeasure == ReadBytes(legStrikePricePricenull.rest, 5) IN IF ~legUnitOfMeasure.ok THEN Fail ELSE
    LET legUnitOfMeasureQtyPricenull == ReadBytes(legUnitOfMeasure.rest, 8) IN IF ~legUnitOfMeasureQtyPricenull.ok THEN Fail ELSE
    LET legSecurityExchange == ReadBytes(legUnitOfMeasureQtyPricenull.rest, 4) IN IF ~legSecurityExchange.ok THEN Fail ELSE
    LET legRatioQtyUInt16Null == ReadBytes(legSecurityExchange.rest, 2) IN IF ~legRatioQtyUInt16Null.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQtyUInt16Null.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legPutOrCall == ReadBytes(legSide.rest, 1) IN IF ~legPutOrCall.ok THEN Fail ELSE
    LET legUnitOfMeasureCurrency == ReadBytes(legPutOrCall.rest, 3) IN IF ~legUnitOfMeasureCurrency.ok THEN Fail ELSE
    Ok([ legSymbol                    |-> legSymbol.value,
         legSecurityId                |-> legSecurityId.value,
         legSecurityGroup             |-> legSecurityGroup.value,
         legId                        |-> legId.value,
         legSecurityType              |-> legSecurityType.value,
         legMaturityMonthYear         |-> legMaturityMonthYear.value,
         legMaturityDate              |-> legMaturityDate.value,
         legStrikePricePricenull      |-> legStrikePricePricenull.value,
         legUnitOfMeasure             |-> legUnitOfMeasure.value,
         legUnitOfMeasureQtyPricenull |-> legUnitOfMeasureQtyPricenull.value,
         legSecurityExchange          |-> legSecurityExchange.value,
         legRatioQtyUInt16Null        |-> legRatioQtyUInt16Null.value,
         legSide                      |-> legSide.value,
         legPutOrCall                 |-> legPutOrCall.value,
         legUnitOfMeasureCurrency     |-> legUnitOfMeasureCurrency.value ], legUnitOfMeasureCurrency.rest)

ZeroTradeBlocksOriginalLegsGroup2 ==
    [ legSymbol                    |-> [i \in 1 .. 50 |-> 0],
      legSecurityId                |-> [i \in 1 .. 8 |-> 0],
      legSecurityGroup             |-> [i \in 1 .. 12 |-> 0],
      legId                        |-> [i \in 1 .. 17 |-> 0],
      legSecurityType              |-> [i \in 1 .. 9 |-> 0],
      legMaturityMonthYear         |-> ZeroLegMaturityMonthYear2,
      legMaturityDate              |-> [i \in 1 .. 2 |-> 0],
      legStrikePricePricenull      |-> [i \in 1 .. 8 |-> 0],
      legUnitOfMeasure             |-> [i \in 1 .. 5 |-> 0],
      legUnitOfMeasureQtyPricenull |-> [i \in 1 .. 8 |-> 0],
      legSecurityExchange          |-> [i \in 1 .. 4 |-> 0],
      legRatioQtyUInt16Null        |-> [i \in 1 .. 2 |-> 0],
      legSide                      |-> [i \in 1 .. 1 |-> 0],
      legPutOrCall                 |-> [i \in 1 .. 1 |-> 0],
      legUnitOfMeasureCurrency     |-> [i \in 1 .. 3 |-> 0] ]

(* Trade Blocks Original Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksOriginalLegsGroup2 ==
    { ZeroTradeBlocksOriginalLegsGroup2 }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legSymbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legSecurityGroup = one] : one \in Sample(12) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legId = one] : one \in Sample(17) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legMaturityMonthYear = one] : one \in CheckedLegMaturityMonthYear2 }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legMaturityDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legStrikePricePricenull = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legUnitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legUnitOfMeasureQtyPricenull = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legSecurityExchange = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legRatioQtyUInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legPutOrCall = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksOriginalLegsGroup2 EXCEPT !.legUnitOfMeasureCurrency = one] : one \in Sample(3) }

(* A run of Trade Blocks Original Legs Group, written one after another *)
RECURSIVE EncodeTradeBlocksOriginalLegsGroup2List(_)
EncodeTradeBlocksOriginalLegsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksOriginalLegsGroup2(Head(messages)) \o EncodeTradeBlocksOriginalLegsGroup2List(Tail(messages))

(* As many Trade Blocks Original Legs Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksOriginalLegsGroup2List(_, _)
ReadTradeBlocksOriginalLegsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksOriginalLegsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksOriginalLegsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Original Legs Group of each kind, for the lists that carry them *)
OneTradeBlocksOriginalLegsGroup2 == { ZeroTradeBlocksOriginalLegsGroup2 }

(***************************************************************************)
(* Trade Blocks Original Legs Groups                                       *)
(***************************************************************************)

TradeBlocksOriginalLegsGroups2 ==
    [ blockLength                  : Sample(2),
      tradeBlocksOriginalLegsGroup : SampleLists(OneTradeBlocksOriginalLegsGroup2) ]

EncodeTradeBlocksOriginalLegsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksOriginalLegsGroup), 1)
        \o EncodeTradeBlocksOriginalLegsGroup2List(message.tradeBlocksOriginalLegsGroup)

DecodeTradeBlocksOriginalLegsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksOriginalLegsGroup == ReadTradeBlocksOriginalLegsGroup2List(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksOriginalLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         tradeBlocksOriginalLegsGroup |-> tradeBlocksOriginalLegsGroup.value ], tradeBlocksOriginalLegsGroup.rest)

ZeroTradeBlocksOriginalLegsGroups2 ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksOriginalLegsGroup |-> << >> ]

(* Trade Blocks Original Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksOriginalLegsGroups2 ==
    { ZeroTradeBlocksOriginalLegsGroups2 }
        \cup { [ZeroTradeBlocksOriginalLegsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksOriginalLegsGroups2 EXCEPT !.tradeBlocksOriginalLegsGroup = one] : one \in SampleLists(OneTradeBlocksOriginalLegsGroup2) }

(***************************************************************************)
(* Trade Blocks Legacy Group                                               *)
(***************************************************************************)

TradeBlocksLegacyGroup ==
    [ mdUpdateAction                : Sample(1),
      securityId                    : Sample(8),
      rptSeq                        : Sample(4),
      mdEntryPxOptional             : Sample(8),
      mdEntrySize                   : MdEntrySize,
      numberOfOrders                : Sample(4),
      tradeId                       : Sample(4),
      aggressorSide                 : Sample(1),
      symbol                        : Sample(50),
      securityGroup12               : Sample(12),
      securityType                  : Sample(9),
      securitySubType               : Sample(2),
      maturityMonthYear             : MaturityMonthYear2,
      securityExchange4             : Sample(4),
      maturityDate                  : Sample(2),
      unitOfMeasure                 : Sample(5),
      unitOfMeasureCurrency3        : Sample(3),
      unitOfMeasureQtyOptional      : Sample(8),
      couponRate                    : Sample(4),
      priceType                     : Sample(2),
      trdType                       : Sample(1),
      mdEntryId                     : Sample(26),
      putOrCall                     : Sample(1),
      strikePrice                   : Sample(8),
      restructuringType             : Sample(2),
      seniority                     : Sample(2),
      referenceId100                : Sample(100),
      strategyLinkId                : Sample(26),
      legRefId                      : Sample(17),
      tradeBlocksUnderlyingsGroups  : TradeBlocksUnderlyingsGroups2,
      tradeBlocksPartyIdsGroups     : TradeBlocksPartyIdsGroups2,
      tradeBlocksOriginalLegsGroups : TradeBlocksOriginalLegsGroups2 ]

EncodeTradeBlocksLegacyGroup(message) ==
    message.mdUpdateAction
        \o message.securityId
        \o message.rptSeq
        \o message.mdEntryPxOptional
        \o EncodeMdEntrySize(message.mdEntrySize)
        \o message.numberOfOrders
        \o message.tradeId
        \o message.aggressorSide
        \o message.symbol
        \o message.securityGroup12
        \o message.securityType
        \o message.securitySubType
        \o EncodeMaturityMonthYear2(message.maturityMonthYear)
        \o message.securityExchange4
        \o message.maturityDate
        \o message.unitOfMeasure
        \o message.unitOfMeasureCurrency3
        \o message.unitOfMeasureQtyOptional
        \o message.couponRate
        \o message.priceType
        \o message.trdType
        \o message.mdEntryId
        \o message.putOrCall
        \o message.strikePrice
        \o message.restructuringType
        \o message.seniority
        \o message.referenceId100
        \o message.strategyLinkId
        \o message.legRefId
        \o EncodeTradeBlocksUnderlyingsGroups2(message.tradeBlocksUnderlyingsGroups)
        \o EncodeTradeBlocksPartyIdsGroups2(message.tradeBlocksPartyIdsGroups)
        \o EncodeTradeBlocksOriginalLegsGroups2(message.tradeBlocksOriginalLegsGroups)

DecodeTradeBlocksLegacyGroup(bytes) ==
    LET mdUpdateAction == ReadBytes(bytes, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdUpdateAction.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPxOptional == ReadBytes(rptSeq.rest, 8) IN IF ~mdEntryPxOptional.ok THEN Fail ELSE
    LET mdEntrySize == DecodeMdEntrySize(mdEntryPxOptional.rest) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(mdEntrySize.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET tradeId == ReadBytes(numberOfOrders.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(tradeId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET symbol == ReadBytes(aggressorSide.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup12 == ReadBytes(symbol.rest, 12) IN IF ~securityGroup12.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup12.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(securityType.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear2(securitySubType.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET securityExchange4 == ReadBytes(maturityMonthYear.rest, 4) IN IF ~securityExchange4.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityExchange4.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(maturityDate.rest, 5) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureCurrency3 == ReadBytes(unitOfMeasure.rest, 3) IN IF ~unitOfMeasureCurrency3.ok THEN Fail ELSE
    LET unitOfMeasureQtyOptional == ReadBytes(unitOfMeasureCurrency3.rest, 8) IN IF ~unitOfMeasureQtyOptional.ok THEN Fail ELSE
    LET couponRate == ReadBytes(unitOfMeasureQtyOptional.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET priceType == ReadBytes(couponRate.rest, 2) IN IF ~priceType.ok THEN Fail ELSE
    LET trdType == ReadBytes(priceType.rest, 1) IN IF ~trdType.ok THEN Fail ELSE
    LET mdEntryId == ReadBytes(trdType.rest, 26) IN IF ~mdEntryId.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(mdEntryId.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET restructuringType == ReadBytes(strikePrice.rest, 2) IN IF ~restructuringType.ok THEN Fail ELSE
    LET seniority == ReadBytes(restructuringType.rest, 2) IN IF ~seniority.ok THEN Fail ELSE
    LET referenceId100 == ReadBytes(seniority.rest, 100) IN IF ~referenceId100.ok THEN Fail ELSE
    LET strategyLinkId == ReadBytes(referenceId100.rest, 26) IN IF ~strategyLinkId.ok THEN Fail ELSE
    LET legRefId == ReadBytes(strategyLinkId.rest, 17) IN IF ~legRefId.ok THEN Fail ELSE
    LET tradeBlocksUnderlyingsGroups == DecodeTradeBlocksUnderlyingsGroups2(legRefId.rest) IN IF ~tradeBlocksUnderlyingsGroups.ok THEN Fail ELSE
    LET tradeBlocksPartyIdsGroups == DecodeTradeBlocksPartyIdsGroups2(tradeBlocksUnderlyingsGroups.rest) IN IF ~tradeBlocksPartyIdsGroups.ok THEN Fail ELSE
    LET tradeBlocksOriginalLegsGroups == DecodeTradeBlocksOriginalLegsGroups2(tradeBlocksPartyIdsGroups.rest) IN IF ~tradeBlocksOriginalLegsGroups.ok THEN Fail ELSE
    Ok([ mdUpdateAction                |-> mdUpdateAction.value,
         securityId                    |-> securityId.value,
         rptSeq                        |-> rptSeq.value,
         mdEntryPxOptional             |-> mdEntryPxOptional.value,
         mdEntrySize                   |-> mdEntrySize.value,
         numberOfOrders                |-> numberOfOrders.value,
         tradeId                       |-> tradeId.value,
         aggressorSide                 |-> aggressorSide.value,
         symbol                        |-> symbol.value,
         securityGroup12               |-> securityGroup12.value,
         securityType                  |-> securityType.value,
         securitySubType               |-> securitySubType.value,
         maturityMonthYear             |-> maturityMonthYear.value,
         securityExchange4             |-> securityExchange4.value,
         maturityDate                  |-> maturityDate.value,
         unitOfMeasure                 |-> unitOfMeasure.value,
         unitOfMeasureCurrency3        |-> unitOfMeasureCurrency3.value,
         unitOfMeasureQtyOptional      |-> unitOfMeasureQtyOptional.value,
         couponRate                    |-> couponRate.value,
         priceType                     |-> priceType.value,
         trdType                       |-> trdType.value,
         mdEntryId                     |-> mdEntryId.value,
         putOrCall                     |-> putOrCall.value,
         strikePrice                   |-> strikePrice.value,
         restructuringType             |-> restructuringType.value,
         seniority                     |-> seniority.value,
         referenceId100                |-> referenceId100.value,
         strategyLinkId                |-> strategyLinkId.value,
         legRefId                      |-> legRefId.value,
         tradeBlocksUnderlyingsGroups  |-> tradeBlocksUnderlyingsGroups.value,
         tradeBlocksPartyIdsGroups     |-> tradeBlocksPartyIdsGroups.value,
         tradeBlocksOriginalLegsGroups |-> tradeBlocksOriginalLegsGroups.value ], tradeBlocksOriginalLegsGroups.rest)

ZeroTradeBlocksLegacyGroup ==
    [ mdUpdateAction                |-> [i \in 1 .. 1 |-> 0],
      securityId                    |-> [i \in 1 .. 8 |-> 0],
      rptSeq                        |-> [i \in 1 .. 4 |-> 0],
      mdEntryPxOptional             |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                   |-> ZeroMdEntrySize,
      numberOfOrders                |-> [i \in 1 .. 4 |-> 0],
      tradeId                       |-> [i \in 1 .. 4 |-> 0],
      aggressorSide                 |-> [i \in 1 .. 1 |-> 0],
      symbol                        |-> [i \in 1 .. 50 |-> 0],
      securityGroup12               |-> [i \in 1 .. 12 |-> 0],
      securityType                  |-> [i \in 1 .. 9 |-> 0],
      securitySubType               |-> [i \in 1 .. 2 |-> 0],
      maturityMonthYear             |-> ZeroMaturityMonthYear2,
      securityExchange4             |-> [i \in 1 .. 4 |-> 0],
      maturityDate                  |-> [i \in 1 .. 2 |-> 0],
      unitOfMeasure                 |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureCurrency3        |-> [i \in 1 .. 3 |-> 0],
      unitOfMeasureQtyOptional      |-> [i \in 1 .. 8 |-> 0],
      couponRate                    |-> [i \in 1 .. 4 |-> 0],
      priceType                     |-> [i \in 1 .. 2 |-> 0],
      trdType                       |-> [i \in 1 .. 1 |-> 0],
      mdEntryId                     |-> [i \in 1 .. 26 |-> 0],
      putOrCall                     |-> [i \in 1 .. 1 |-> 0],
      strikePrice                   |-> [i \in 1 .. 8 |-> 0],
      restructuringType             |-> [i \in 1 .. 2 |-> 0],
      seniority                     |-> [i \in 1 .. 2 |-> 0],
      referenceId100                |-> [i \in 1 .. 100 |-> 0],
      strategyLinkId                |-> [i \in 1 .. 26 |-> 0],
      legRefId                      |-> [i \in 1 .. 17 |-> 0],
      tradeBlocksUnderlyingsGroups  |-> ZeroTradeBlocksUnderlyingsGroups2,
      tradeBlocksPartyIdsGroups     |-> ZeroTradeBlocksPartyIdsGroups2,
      tradeBlocksOriginalLegsGroups |-> ZeroTradeBlocksOriginalLegsGroups2 ]

(* Trade Blocks Legacy Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksLegacyGroup ==
    { ZeroTradeBlocksLegacyGroup }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.mdEntryPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.mdEntrySize = one] : one \in CheckedMdEntrySize }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.securityGroup12 = one] : one \in Sample(12) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear2 }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.securityExchange4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.unitOfMeasureCurrency3 = one] : one \in Sample(3) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.unitOfMeasureQtyOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.priceType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.trdType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.mdEntryId = one] : one \in Sample(26) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.restructuringType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.seniority = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.referenceId100 = one] : one \in Sample(100) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.strategyLinkId = one] : one \in Sample(26) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.legRefId = one] : one \in Sample(17) }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.tradeBlocksUnderlyingsGroups = one] : one \in CheckedTradeBlocksUnderlyingsGroups2 }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.tradeBlocksPartyIdsGroups = one] : one \in CheckedTradeBlocksPartyIdsGroups2 }
        \cup { [ZeroTradeBlocksLegacyGroup EXCEPT !.tradeBlocksOriginalLegsGroups = one] : one \in CheckedTradeBlocksOriginalLegsGroups2 }

(* A run of Trade Blocks Legacy Group, written one after another *)
RECURSIVE EncodeTradeBlocksLegacyGroupList(_)
EncodeTradeBlocksLegacyGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksLegacyGroup(Head(messages)) \o EncodeTradeBlocksLegacyGroupList(Tail(messages))

(* As many Trade Blocks Legacy Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksLegacyGroupList(_, _)
ReadTradeBlocksLegacyGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksLegacyGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksLegacyGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Legacy Group of each kind, for the lists that carry them *)
OneTradeBlocksLegacyGroup == { ZeroTradeBlocksLegacyGroup }

(***************************************************************************)
(* Trade Blocks Legacy Groups                                              *)
(***************************************************************************)

TradeBlocksLegacyGroups ==
    [ blockLength            : Sample(2),
      tradeBlocksLegacyGroup : SampleLists(OneTradeBlocksLegacyGroup) ]

EncodeTradeBlocksLegacyGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksLegacyGroup), 1)
        \o EncodeTradeBlocksLegacyGroupList(message.tradeBlocksLegacyGroup)

DecodeTradeBlocksLegacyGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksLegacyGroup == ReadTradeBlocksLegacyGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksLegacyGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         tradeBlocksLegacyGroup |-> tradeBlocksLegacyGroup.value ], tradeBlocksLegacyGroup.rest)

ZeroTradeBlocksLegacyGroups ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksLegacyGroup |-> << >> ]

(* Trade Blocks Legacy Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksLegacyGroups ==
    { ZeroTradeBlocksLegacyGroups }
        \cup { [ZeroTradeBlocksLegacyGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegacyGroups EXCEPT !.tradeBlocksLegacyGroup = one] : one \in SampleLists(OneTradeBlocksLegacyGroup) }

(***************************************************************************)
(* Md Incremental Refresh Trade Blocks 349                                 *)
(***************************************************************************)

MdIncrementalRefreshTradeBlocks349 ==
    [ transactTimeOptional    : Sample(8),
      matchEventIndicator     : Sample(1),
      batchTotalMessages      : Sample(2),
      tradeDate               : Sample(2),
      tradeBlocksLegacyGroups : TradeBlocksLegacyGroups ]

EncodeMdIncrementalRefreshTradeBlocks349(message) ==
    message.transactTimeOptional
        \o message.matchEventIndicator
        \o message.batchTotalMessages
        \o message.tradeDate
        \o EncodeTradeBlocksLegacyGroups(message.tradeBlocksLegacyGroups)

DecodeMdIncrementalRefreshTradeBlocks349(bytes) ==
    LET transactTimeOptional == ReadBytes(bytes, 8) IN IF ~transactTimeOptional.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTimeOptional.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessages == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessages.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(batchTotalMessages.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeBlocksLegacyGroups == DecodeTradeBlocksLegacyGroups(tradeDate.rest) IN IF ~tradeBlocksLegacyGroups.ok THEN Fail ELSE
    Ok([ transactTimeOptional    |-> transactTimeOptional.value,
         matchEventIndicator     |-> matchEventIndicator.value,
         batchTotalMessages      |-> batchTotalMessages.value,
         tradeDate               |-> tradeDate.value,
         tradeBlocksLegacyGroups |-> tradeBlocksLegacyGroups.value ], tradeBlocksLegacyGroups.rest)

ZeroMdIncrementalRefreshTradeBlocks349 ==
    [ transactTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator     |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessages      |-> [i \in 1 .. 2 |-> 0],
      tradeDate               |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksLegacyGroups |-> ZeroTradeBlocksLegacyGroups ]

(* Md Incremental Refresh Trade Blocks 349 at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshTradeBlocks349 ==
    { ZeroMdIncrementalRefreshTradeBlocks349 }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks349 EXCEPT !.transactTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks349 EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks349 EXCEPT !.batchTotalMessages = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks349 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks349 EXCEPT !.tradeBlocksLegacyGroups = one] : one \in CheckedTradeBlocksLegacyGroups }

(***************************************************************************)
(* Md Entry Px Decimal: 9 bytes                                            *)
(***************************************************************************)

MdEntryPxDecimal2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntryPxDecimal2(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntryPxDecimal2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntryPxDecimal2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Px Decimal at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPxDecimal2 ==
    { ZeroMdEntryPxDecimal2 }
        \cup { [ZeroMdEntryPxDecimal2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntryPxDecimal2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Cal Fut Px: 9 bytes                                                     *)
(***************************************************************************)

CalFutPx ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeCalFutPx(message) ==
    message.mantissa
        \o message.exponent

DecodeCalFutPx(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroCalFutPx ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Cal Fut Px at zero, then each field in turn at the values it is checked at *)
CheckedCalFutPx ==
    { ZeroCalFutPx }
        \cup { [ZeroCalFutPx EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroCalFutPx EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Eris Security Alt Id Group: 27 bytes                                    *)
(***************************************************************************)

ErisSecurityAltIdGroup2 ==
    [ securityAltId50             : Sample(26),
      securityAltIdSourceOptional : Sample(1) ]

EncodeErisSecurityAltIdGroup2(message) ==
    message.securityAltId50
        \o message.securityAltIdSourceOptional

DecodeErisSecurityAltIdGroup2(bytes) ==
    LET securityAltId50 == ReadBytes(bytes, 26) IN IF ~securityAltId50.ok THEN Fail ELSE
    LET securityAltIdSourceOptional == ReadBytes(securityAltId50.rest, 1) IN IF ~securityAltIdSourceOptional.ok THEN Fail ELSE
    Ok([ securityAltId50             |-> securityAltId50.value,
         securityAltIdSourceOptional |-> securityAltIdSourceOptional.value ], securityAltIdSourceOptional.rest)

ZeroErisSecurityAltIdGroup2 ==
    [ securityAltId50             |-> [i \in 1 .. 26 |-> 0],
      securityAltIdSourceOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Eris Security Alt Id Group at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroup2 ==
    { ZeroErisSecurityAltIdGroup2 }
        \cup { [ZeroErisSecurityAltIdGroup2 EXCEPT !.securityAltId50 = one] : one \in Sample(26) }
        \cup { [ZeroErisSecurityAltIdGroup2 EXCEPT !.securityAltIdSourceOptional = one] : one \in Sample(1) }

(* A run of Eris Security Alt Id Group, written one after another *)
RECURSIVE EncodeErisSecurityAltIdGroup2List(_)
EncodeErisSecurityAltIdGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisSecurityAltIdGroup2(Head(messages)) \o EncodeErisSecurityAltIdGroup2List(Tail(messages))

(* As many Eris Security Alt Id Group as the field that counts them says *)
RECURSIVE ReadErisSecurityAltIdGroup2List(_, _)
ReadErisSecurityAltIdGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisSecurityAltIdGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisSecurityAltIdGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Security Alt Id Group of each kind, for the lists that carry them *)
OneErisSecurityAltIdGroup2 == { ZeroErisSecurityAltIdGroup2 }

(***************************************************************************)
(* Eris Security Alt Id Groups                                             *)
(***************************************************************************)

ErisSecurityAltIdGroups2 ==
    [ blockLength            : Sample(2),
      erisSecurityAltIdGroup : SampleLists(OneErisSecurityAltIdGroup2) ]

EncodeErisSecurityAltIdGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisSecurityAltIdGroup), 1)
        \o EncodeErisSecurityAltIdGroup2List(message.erisSecurityAltIdGroup)

DecodeErisSecurityAltIdGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisSecurityAltIdGroup == ReadErisSecurityAltIdGroup2List(numInGroup8.rest, numInGroup8.value) IN IF ~erisSecurityAltIdGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         erisSecurityAltIdGroup |-> erisSecurityAltIdGroup.value ], erisSecurityAltIdGroup.rest)

ZeroErisSecurityAltIdGroups2 ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      erisSecurityAltIdGroup |-> << >> ]

(* Eris Security Alt Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroups2 ==
    { ZeroErisSecurityAltIdGroups2 }
        \cup { [ZeroErisSecurityAltIdGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisSecurityAltIdGroups2 EXCEPT !.erisSecurityAltIdGroup = one] : one \in SampleLists(OneErisSecurityAltIdGroup2) }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup4 ==
    [ eventTypeOptional : Sample(1),
      eventTimeOptional : Sample(8) ]

EncodeEventsGroup4(message) ==
    message.eventTypeOptional
        \o message.eventTimeOptional

DecodeEventsGroup4(bytes) ==
    LET eventTypeOptional == ReadBytes(bytes, 1) IN IF ~eventTypeOptional.ok THEN Fail ELSE
    LET eventTimeOptional == ReadBytes(eventTypeOptional.rest, 8) IN IF ~eventTimeOptional.ok THEN Fail ELSE
    Ok([ eventTypeOptional |-> eventTypeOptional.value,
         eventTimeOptional |-> eventTimeOptional.value ], eventTimeOptional.rest)

ZeroEventsGroup4 ==
    [ eventTypeOptional |-> [i \in 1 .. 1 |-> 0],
      eventTimeOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup4 ==
    { ZeroEventsGroup4 }
        \cup { [ZeroEventsGroup4 EXCEPT !.eventTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup4 EXCEPT !.eventTimeOptional = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup4List(_)
EncodeEventsGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup4(Head(messages)) \o EncodeEventsGroup4List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup4List(_, _)
ReadEventsGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup4 == { ZeroEventsGroup4 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups4 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup4) ]

EncodeEventsGroups4(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup4List(message.eventsGroup)

DecodeEventsGroups4(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup4List(numInGroup8.rest, numInGroup8.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups4 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups4 ==
    { ZeroEventsGroups4 }
        \cup { [ZeroEventsGroups4 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups4 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup4) }

(***************************************************************************)
(* Eris Original Group                                                     *)
(***************************************************************************)

ErisOriginalGroup ==
    [ mdUpdateActionChar      : Sample(1),
      mdEntryType             : Sample(1),
      rptSeq                  : Sample(4),
      mdEntryPxDecimal        : MdEntryPxDecimal2,
      mdEntrySizeOptional     : Sample(8),
      calFutPx                : CalFutPx,
      mdEntryPositionNo       : Sample(4),
      numberOfOrders          : Sample(4),
      tradeId                 : Sample(4),
      aggressorSide           : Sample(1),
      symbol                  : Sample(50),
      securityGroup26         : Sample(26),
      securityType            : Sample(9),
      securityExchange        : Sample(4),
      productOptional         : Sample(1),
      maturityDate            : Sample(2),
      referenceId50           : Sample(50),
      erisSecurityAltIdGroups : ErisSecurityAltIdGroups2,
      eventsGroups            : EventsGroups4 ]

EncodeErisOriginalGroup(message) ==
    message.mdUpdateActionChar
        \o message.mdEntryType
        \o message.rptSeq
        \o EncodeMdEntryPxDecimal2(message.mdEntryPxDecimal)
        \o message.mdEntrySizeOptional
        \o EncodeCalFutPx(message.calFutPx)
        \o message.mdEntryPositionNo
        \o message.numberOfOrders
        \o message.tradeId
        \o message.aggressorSide
        \o message.symbol
        \o message.securityGroup26
        \o message.securityType
        \o message.securityExchange
        \o message.productOptional
        \o message.maturityDate
        \o message.referenceId50
        \o EncodeErisSecurityAltIdGroups2(message.erisSecurityAltIdGroups)
        \o EncodeEventsGroups4(message.eventsGroups)

DecodeErisOriginalGroup(bytes) ==
    LET mdUpdateActionChar == ReadBytes(bytes, 1) IN IF ~mdUpdateActionChar.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateActionChar.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryType.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPxDecimal == DecodeMdEntryPxDecimal2(rptSeq.rest) IN IF ~mdEntryPxDecimal.ok THEN Fail ELSE
    LET mdEntrySizeOptional == ReadBytes(mdEntryPxDecimal.rest, 8) IN IF ~mdEntrySizeOptional.ok THEN Fail ELSE
    LET calFutPx == DecodeCalFutPx(mdEntrySizeOptional.rest) IN IF ~calFutPx.ok THEN Fail ELSE
    LET mdEntryPositionNo == ReadBytes(calFutPx.rest, 4) IN IF ~mdEntryPositionNo.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(mdEntryPositionNo.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET tradeId == ReadBytes(numberOfOrders.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(tradeId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET symbol == ReadBytes(aggressorSide.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup26 == ReadBytes(symbol.rest, 26) IN IF ~securityGroup26.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup26.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityType.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET productOptional == ReadBytes(securityExchange.rest, 1) IN IF ~productOptional.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(productOptional.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET referenceId50 == ReadBytes(maturityDate.rest, 50) IN IF ~referenceId50.ok THEN Fail ELSE
    LET erisSecurityAltIdGroups == DecodeErisSecurityAltIdGroups2(referenceId50.rest) IN IF ~erisSecurityAltIdGroups.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups4(erisSecurityAltIdGroups.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    Ok([ mdUpdateActionChar      |-> mdUpdateActionChar.value,
         mdEntryType             |-> mdEntryType.value,
         rptSeq                  |-> rptSeq.value,
         mdEntryPxDecimal        |-> mdEntryPxDecimal.value,
         mdEntrySizeOptional     |-> mdEntrySizeOptional.value,
         calFutPx                |-> calFutPx.value,
         mdEntryPositionNo       |-> mdEntryPositionNo.value,
         numberOfOrders          |-> numberOfOrders.value,
         tradeId                 |-> tradeId.value,
         aggressorSide           |-> aggressorSide.value,
         symbol                  |-> symbol.value,
         securityGroup26         |-> securityGroup26.value,
         securityType            |-> securityType.value,
         securityExchange        |-> securityExchange.value,
         productOptional         |-> productOptional.value,
         maturityDate            |-> maturityDate.value,
         referenceId50           |-> referenceId50.value,
         erisSecurityAltIdGroups |-> erisSecurityAltIdGroups.value,
         eventsGroups            |-> eventsGroups.value ], eventsGroups.rest)

ZeroErisOriginalGroup ==
    [ mdUpdateActionChar      |-> [i \in 1 .. 1 |-> 0],
      mdEntryType             |-> [i \in 1 .. 1 |-> 0],
      rptSeq                  |-> [i \in 1 .. 4 |-> 0],
      mdEntryPxDecimal        |-> ZeroMdEntryPxDecimal2,
      mdEntrySizeOptional     |-> [i \in 1 .. 8 |-> 0],
      calFutPx                |-> ZeroCalFutPx,
      mdEntryPositionNo       |-> [i \in 1 .. 4 |-> 0],
      numberOfOrders          |-> [i \in 1 .. 4 |-> 0],
      tradeId                 |-> [i \in 1 .. 4 |-> 0],
      aggressorSide           |-> [i \in 1 .. 1 |-> 0],
      symbol                  |-> [i \in 1 .. 50 |-> 0],
      securityGroup26         |-> [i \in 1 .. 26 |-> 0],
      securityType            |-> [i \in 1 .. 9 |-> 0],
      securityExchange        |-> [i \in 1 .. 4 |-> 0],
      productOptional         |-> [i \in 1 .. 1 |-> 0],
      maturityDate            |-> [i \in 1 .. 2 |-> 0],
      referenceId50           |-> [i \in 1 .. 50 |-> 0],
      erisSecurityAltIdGroups |-> ZeroErisSecurityAltIdGroups2,
      eventsGroups            |-> ZeroEventsGroups4 ]

(* Eris Original Group at zero, then each field in turn at the values it is checked at *)
CheckedErisOriginalGroup ==
    { ZeroErisOriginalGroup }
        \cup { [ZeroErisOriginalGroup EXCEPT !.mdUpdateActionChar = one] : one \in Sample(1) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.mdEntryPxDecimal = one] : one \in CheckedMdEntryPxDecimal2 }
        \cup { [ZeroErisOriginalGroup EXCEPT !.mdEntrySizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.calFutPx = one] : one \in CheckedCalFutPx }
        \cup { [ZeroErisOriginalGroup EXCEPT !.mdEntryPositionNo = one] : one \in Sample(4) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.securityGroup26 = one] : one \in Sample(26) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.productOptional = one] : one \in Sample(1) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.referenceId50 = one] : one \in Sample(50) }
        \cup { [ZeroErisOriginalGroup EXCEPT !.erisSecurityAltIdGroups = one] : one \in CheckedErisSecurityAltIdGroups2 }
        \cup { [ZeroErisOriginalGroup EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups4 }

(* A run of Eris Original Group, written one after another *)
RECURSIVE EncodeErisOriginalGroupList(_)
EncodeErisOriginalGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisOriginalGroup(Head(messages)) \o EncodeErisOriginalGroupList(Tail(messages))

(* As many Eris Original Group as the field that counts them says *)
RECURSIVE ReadErisOriginalGroupList(_, _)
ReadErisOriginalGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisOriginalGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisOriginalGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Original Group of each kind, for the lists that carry them *)
OneErisOriginalGroup == { ZeroErisOriginalGroup }

(***************************************************************************)
(* Eris Original Groups                                                    *)
(***************************************************************************)

ErisOriginalGroups ==
    [ blockLength       : Sample(2),
      erisOriginalGroup : SampleLists(OneErisOriginalGroup) ]

EncodeErisOriginalGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisOriginalGroup), 1)
        \o EncodeErisOriginalGroupList(message.erisOriginalGroup)

DecodeErisOriginalGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisOriginalGroup == ReadErisOriginalGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~erisOriginalGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         erisOriginalGroup |-> erisOriginalGroup.value ], erisOriginalGroup.rest)

ZeroErisOriginalGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      erisOriginalGroup |-> << >> ]

(* Eris Original Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisOriginalGroups ==
    { ZeroErisOriginalGroups }
        \cup { [ZeroErisOriginalGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisOriginalGroups EXCEPT !.erisOriginalGroup = one] : one \in SampleLists(OneErisOriginalGroup) }

(***************************************************************************)
(* Md Incremental Refresh Eris 351                                         *)
(***************************************************************************)

MdIncrementalRefreshEris351 ==
    [ transactTime               : Sample(8),
      matchEventIndicator        : Sample(1),
      batchTotalMessagesOptional : Sample(2),
      erisOriginalGroups         : ErisOriginalGroups ]

EncodeMdIncrementalRefreshEris351(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.batchTotalMessagesOptional
        \o EncodeErisOriginalGroups(message.erisOriginalGroups)

DecodeMdIncrementalRefreshEris351(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessagesOptional == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessagesOptional.ok THEN Fail ELSE
    LET erisOriginalGroups == DecodeErisOriginalGroups(batchTotalMessagesOptional.rest) IN IF ~erisOriginalGroups.ok THEN Fail ELSE
    Ok([ transactTime               |-> transactTime.value,
         matchEventIndicator        |-> matchEventIndicator.value,
         batchTotalMessagesOptional |-> batchTotalMessagesOptional.value,
         erisOriginalGroups         |-> erisOriginalGroups.value ], erisOriginalGroups.rest)

ZeroMdIncrementalRefreshEris351 ==
    [ transactTime               |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator        |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessagesOptional |-> [i \in 1 .. 2 |-> 0],
      erisOriginalGroups         |-> ZeroErisOriginalGroups ]

(* Md Incremental Refresh Eris 351 at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshEris351 ==
    { ZeroMdIncrementalRefreshEris351 }
        \cup { [ZeroMdIncrementalRefreshEris351 EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshEris351 EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshEris351 EXCEPT !.batchTotalMessagesOptional = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshEris351 EXCEPT !.erisOriginalGroups = one] : one \in CheckedErisOriginalGroups }

(***************************************************************************)
(* Md Entry Px Decimal: 9 bytes                                            *)
(***************************************************************************)

MdEntryPxDecimal3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntryPxDecimal3(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntryPxDecimal3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntryPxDecimal3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Px Decimal at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPxDecimal3 ==
    { ZeroMdEntryPxDecimal3 }
        \cup { [ZeroMdEntryPxDecimal3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntryPxDecimal3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Cal Fut Px: 9 bytes                                                     *)
(***************************************************************************)

CalFutPx2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeCalFutPx2(message) ==
    message.mantissa
        \o message.exponent

DecodeCalFutPx2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroCalFutPx2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Cal Fut Px at zero, then each field in turn at the values it is checked at *)
CheckedCalFutPx2 ==
    { ZeroCalFutPx2 }
        \cup { [ZeroCalFutPx2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroCalFutPx2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Eris Security Alt Id Group: 27 bytes                                    *)
(***************************************************************************)

ErisSecurityAltIdGroup3 ==
    [ securityAltId50             : Sample(26),
      securityAltIdSourceOptional : Sample(1) ]

EncodeErisSecurityAltIdGroup3(message) ==
    message.securityAltId50
        \o message.securityAltIdSourceOptional

DecodeErisSecurityAltIdGroup3(bytes) ==
    LET securityAltId50 == ReadBytes(bytes, 26) IN IF ~securityAltId50.ok THEN Fail ELSE
    LET securityAltIdSourceOptional == ReadBytes(securityAltId50.rest, 1) IN IF ~securityAltIdSourceOptional.ok THEN Fail ELSE
    Ok([ securityAltId50             |-> securityAltId50.value,
         securityAltIdSourceOptional |-> securityAltIdSourceOptional.value ], securityAltIdSourceOptional.rest)

ZeroErisSecurityAltIdGroup3 ==
    [ securityAltId50             |-> [i \in 1 .. 26 |-> 0],
      securityAltIdSourceOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Eris Security Alt Id Group at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroup3 ==
    { ZeroErisSecurityAltIdGroup3 }
        \cup { [ZeroErisSecurityAltIdGroup3 EXCEPT !.securityAltId50 = one] : one \in Sample(26) }
        \cup { [ZeroErisSecurityAltIdGroup3 EXCEPT !.securityAltIdSourceOptional = one] : one \in Sample(1) }

(* A run of Eris Security Alt Id Group, written one after another *)
RECURSIVE EncodeErisSecurityAltIdGroup3List(_)
EncodeErisSecurityAltIdGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisSecurityAltIdGroup3(Head(messages)) \o EncodeErisSecurityAltIdGroup3List(Tail(messages))

(* As many Eris Security Alt Id Group as the field that counts them says *)
RECURSIVE ReadErisSecurityAltIdGroup3List(_, _)
ReadErisSecurityAltIdGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisSecurityAltIdGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisSecurityAltIdGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Security Alt Id Group of each kind, for the lists that carry them *)
OneErisSecurityAltIdGroup3 == { ZeroErisSecurityAltIdGroup3 }

(***************************************************************************)
(* Eris Security Alt Id Groups                                             *)
(***************************************************************************)

ErisSecurityAltIdGroups3 ==
    [ blockLength            : Sample(2),
      erisSecurityAltIdGroup : SampleLists(OneErisSecurityAltIdGroup3) ]

EncodeErisSecurityAltIdGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisSecurityAltIdGroup), 1)
        \o EncodeErisSecurityAltIdGroup3List(message.erisSecurityAltIdGroup)

DecodeErisSecurityAltIdGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisSecurityAltIdGroup == ReadErisSecurityAltIdGroup3List(numInGroup8.rest, numInGroup8.value) IN IF ~erisSecurityAltIdGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         erisSecurityAltIdGroup |-> erisSecurityAltIdGroup.value ], erisSecurityAltIdGroup.rest)

ZeroErisSecurityAltIdGroups3 ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      erisSecurityAltIdGroup |-> << >> ]

(* Eris Security Alt Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroups3 ==
    { ZeroErisSecurityAltIdGroups3 }
        \cup { [ZeroErisSecurityAltIdGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisSecurityAltIdGroups3 EXCEPT !.erisSecurityAltIdGroup = one] : one \in SampleLists(OneErisSecurityAltIdGroup3) }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup5 ==
    [ eventTypeOptional : Sample(1),
      eventTimeOptional : Sample(8) ]

EncodeEventsGroup5(message) ==
    message.eventTypeOptional
        \o message.eventTimeOptional

DecodeEventsGroup5(bytes) ==
    LET eventTypeOptional == ReadBytes(bytes, 1) IN IF ~eventTypeOptional.ok THEN Fail ELSE
    LET eventTimeOptional == ReadBytes(eventTypeOptional.rest, 8) IN IF ~eventTimeOptional.ok THEN Fail ELSE
    Ok([ eventTypeOptional |-> eventTypeOptional.value,
         eventTimeOptional |-> eventTimeOptional.value ], eventTimeOptional.rest)

ZeroEventsGroup5 ==
    [ eventTypeOptional |-> [i \in 1 .. 1 |-> 0],
      eventTimeOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup5 ==
    { ZeroEventsGroup5 }
        \cup { [ZeroEventsGroup5 EXCEPT !.eventTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup5 EXCEPT !.eventTimeOptional = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup5List(_)
EncodeEventsGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup5(Head(messages)) \o EncodeEventsGroup5List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup5List(_, _)
ReadEventsGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup5 == { ZeroEventsGroup5 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups5 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup5) ]

EncodeEventsGroups5(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup5List(message.eventsGroup)

DecodeEventsGroups5(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup5List(numInGroup8.rest, numInGroup8.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups5 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups5 ==
    { ZeroEventsGroups5 }
        \cup { [ZeroEventsGroups5 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups5 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup5) }

(***************************************************************************)
(* Eris Group                                                              *)
(***************************************************************************)

ErisGroup ==
    [ mdUpdateActionChar      : Sample(1),
      mdEntryType             : Sample(1),
      rptSeq                  : Sample(4),
      mdEntryPxDecimal        : MdEntryPxDecimal3,
      mdEntrySizeOptional     : Sample(8),
      calFutPx                : CalFutPx2,
      mdEntryPositionNo       : Sample(4),
      numberOfOrders          : Sample(4),
      tradeId                 : Sample(4),
      aggressorSide           : Sample(1),
      symbol                  : Sample(50),
      securityGroup26         : Sample(26),
      securityType            : Sample(9),
      securityExchange        : Sample(4),
      productOptional         : Sample(1),
      maturityDate            : Sample(2),
      referenceId50           : Sample(50),
      mdQuoteType             : Sample(1),
      erisSecurityAltIdGroups : ErisSecurityAltIdGroups3,
      eventsGroups            : EventsGroups5 ]

EncodeErisGroup(message) ==
    message.mdUpdateActionChar
        \o message.mdEntryType
        \o message.rptSeq
        \o EncodeMdEntryPxDecimal3(message.mdEntryPxDecimal)
        \o message.mdEntrySizeOptional
        \o EncodeCalFutPx2(message.calFutPx)
        \o message.mdEntryPositionNo
        \o message.numberOfOrders
        \o message.tradeId
        \o message.aggressorSide
        \o message.symbol
        \o message.securityGroup26
        \o message.securityType
        \o message.securityExchange
        \o message.productOptional
        \o message.maturityDate
        \o message.referenceId50
        \o message.mdQuoteType
        \o EncodeErisSecurityAltIdGroups3(message.erisSecurityAltIdGroups)
        \o EncodeEventsGroups5(message.eventsGroups)

DecodeErisGroup(bytes) ==
    LET mdUpdateActionChar == ReadBytes(bytes, 1) IN IF ~mdUpdateActionChar.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateActionChar.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryType.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPxDecimal == DecodeMdEntryPxDecimal3(rptSeq.rest) IN IF ~mdEntryPxDecimal.ok THEN Fail ELSE
    LET mdEntrySizeOptional == ReadBytes(mdEntryPxDecimal.rest, 8) IN IF ~mdEntrySizeOptional.ok THEN Fail ELSE
    LET calFutPx == DecodeCalFutPx2(mdEntrySizeOptional.rest) IN IF ~calFutPx.ok THEN Fail ELSE
    LET mdEntryPositionNo == ReadBytes(calFutPx.rest, 4) IN IF ~mdEntryPositionNo.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(mdEntryPositionNo.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET tradeId == ReadBytes(numberOfOrders.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(tradeId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET symbol == ReadBytes(aggressorSide.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup26 == ReadBytes(symbol.rest, 26) IN IF ~securityGroup26.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup26.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityType.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET productOptional == ReadBytes(securityExchange.rest, 1) IN IF ~productOptional.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(productOptional.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET referenceId50 == ReadBytes(maturityDate.rest, 50) IN IF ~referenceId50.ok THEN Fail ELSE
    LET mdQuoteType == ReadBytes(referenceId50.rest, 1) IN IF ~mdQuoteType.ok THEN Fail ELSE
    LET erisSecurityAltIdGroups == DecodeErisSecurityAltIdGroups3(mdQuoteType.rest) IN IF ~erisSecurityAltIdGroups.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups5(erisSecurityAltIdGroups.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    Ok([ mdUpdateActionChar      |-> mdUpdateActionChar.value,
         mdEntryType             |-> mdEntryType.value,
         rptSeq                  |-> rptSeq.value,
         mdEntryPxDecimal        |-> mdEntryPxDecimal.value,
         mdEntrySizeOptional     |-> mdEntrySizeOptional.value,
         calFutPx                |-> calFutPx.value,
         mdEntryPositionNo       |-> mdEntryPositionNo.value,
         numberOfOrders          |-> numberOfOrders.value,
         tradeId                 |-> tradeId.value,
         aggressorSide           |-> aggressorSide.value,
         symbol                  |-> symbol.value,
         securityGroup26         |-> securityGroup26.value,
         securityType            |-> securityType.value,
         securityExchange        |-> securityExchange.value,
         productOptional         |-> productOptional.value,
         maturityDate            |-> maturityDate.value,
         referenceId50           |-> referenceId50.value,
         mdQuoteType             |-> mdQuoteType.value,
         erisSecurityAltIdGroups |-> erisSecurityAltIdGroups.value,
         eventsGroups            |-> eventsGroups.value ], eventsGroups.rest)

ZeroErisGroup ==
    [ mdUpdateActionChar      |-> [i \in 1 .. 1 |-> 0],
      mdEntryType             |-> [i \in 1 .. 1 |-> 0],
      rptSeq                  |-> [i \in 1 .. 4 |-> 0],
      mdEntryPxDecimal        |-> ZeroMdEntryPxDecimal3,
      mdEntrySizeOptional     |-> [i \in 1 .. 8 |-> 0],
      calFutPx                |-> ZeroCalFutPx2,
      mdEntryPositionNo       |-> [i \in 1 .. 4 |-> 0],
      numberOfOrders          |-> [i \in 1 .. 4 |-> 0],
      tradeId                 |-> [i \in 1 .. 4 |-> 0],
      aggressorSide           |-> [i \in 1 .. 1 |-> 0],
      symbol                  |-> [i \in 1 .. 50 |-> 0],
      securityGroup26         |-> [i \in 1 .. 26 |-> 0],
      securityType            |-> [i \in 1 .. 9 |-> 0],
      securityExchange        |-> [i \in 1 .. 4 |-> 0],
      productOptional         |-> [i \in 1 .. 1 |-> 0],
      maturityDate            |-> [i \in 1 .. 2 |-> 0],
      referenceId50           |-> [i \in 1 .. 50 |-> 0],
      mdQuoteType             |-> [i \in 1 .. 1 |-> 0],
      erisSecurityAltIdGroups |-> ZeroErisSecurityAltIdGroups3,
      eventsGroups            |-> ZeroEventsGroups5 ]

(* Eris Group at zero, then each field in turn at the values it is checked at *)
CheckedErisGroup ==
    { ZeroErisGroup }
        \cup { [ZeroErisGroup EXCEPT !.mdUpdateActionChar = one] : one \in Sample(1) }
        \cup { [ZeroErisGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroErisGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroErisGroup EXCEPT !.mdEntryPxDecimal = one] : one \in CheckedMdEntryPxDecimal3 }
        \cup { [ZeroErisGroup EXCEPT !.mdEntrySizeOptional = one] : one \in Sample(8) }
        \cup { [ZeroErisGroup EXCEPT !.calFutPx = one] : one \in CheckedCalFutPx2 }
        \cup { [ZeroErisGroup EXCEPT !.mdEntryPositionNo = one] : one \in Sample(4) }
        \cup { [ZeroErisGroup EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroErisGroup EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroErisGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroErisGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroErisGroup EXCEPT !.securityGroup26 = one] : one \in Sample(26) }
        \cup { [ZeroErisGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroErisGroup EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroErisGroup EXCEPT !.productOptional = one] : one \in Sample(1) }
        \cup { [ZeroErisGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroErisGroup EXCEPT !.referenceId50 = one] : one \in Sample(50) }
        \cup { [ZeroErisGroup EXCEPT !.mdQuoteType = one] : one \in Sample(1) }
        \cup { [ZeroErisGroup EXCEPT !.erisSecurityAltIdGroups = one] : one \in CheckedErisSecurityAltIdGroups3 }
        \cup { [ZeroErisGroup EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups5 }

(* A run of Eris Group, written one after another *)
RECURSIVE EncodeErisGroupList(_)
EncodeErisGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisGroup(Head(messages)) \o EncodeErisGroupList(Tail(messages))

(* As many Eris Group as the field that counts them says *)
RECURSIVE ReadErisGroupList(_, _)
ReadErisGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Group of each kind, for the lists that carry them *)
OneErisGroup == { ZeroErisGroup }

(***************************************************************************)
(* Eris Groups                                                             *)
(***************************************************************************)

ErisGroups ==
    [ blockLength : Sample(2),
      erisGroup   : SampleLists(OneErisGroup) ]

EncodeErisGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisGroup), 1)
        \o EncodeErisGroupList(message.erisGroup)

DecodeErisGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisGroup == ReadErisGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~erisGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         erisGroup   |-> erisGroup.value ], erisGroup.rest)

ZeroErisGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      erisGroup   |-> << >> ]

(* Eris Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisGroups ==
    { ZeroErisGroups }
        \cup { [ZeroErisGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisGroups EXCEPT !.erisGroup = one] : one \in SampleLists(OneErisGroup) }

(***************************************************************************)
(* Md Incremental Refresh Eris 353                                         *)
(***************************************************************************)

MdIncrementalRefreshEris353 ==
    [ transactTime               : Sample(8),
      matchEventIndicator        : Sample(1),
      batchTotalMessagesOptional : Sample(2),
      erisGroups                 : ErisGroups ]

EncodeMdIncrementalRefreshEris353(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.batchTotalMessagesOptional
        \o EncodeErisGroups(message.erisGroups)

DecodeMdIncrementalRefreshEris353(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessagesOptional == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessagesOptional.ok THEN Fail ELSE
    LET erisGroups == DecodeErisGroups(batchTotalMessagesOptional.rest) IN IF ~erisGroups.ok THEN Fail ELSE
    Ok([ transactTime               |-> transactTime.value,
         matchEventIndicator        |-> matchEventIndicator.value,
         batchTotalMessagesOptional |-> batchTotalMessagesOptional.value,
         erisGroups                 |-> erisGroups.value ], erisGroups.rest)

ZeroMdIncrementalRefreshEris353 ==
    [ transactTime               |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator        |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessagesOptional |-> [i \in 1 .. 2 |-> 0],
      erisGroups                 |-> ZeroErisGroups ]

(* Md Incremental Refresh Eris 353 at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshEris353 ==
    { ZeroMdIncrementalRefreshEris353 }
        \cup { [ZeroMdIncrementalRefreshEris353 EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshEris353 EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshEris353 EXCEPT !.batchTotalMessagesOptional = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshEris353 EXCEPT !.erisGroups = one] : one \in CheckedErisGroups }

(***************************************************************************)
(* Md Entry Size: 9 bytes                                                  *)
(***************************************************************************)

MdEntrySize2 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntrySize2(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntrySize2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntrySize2 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Size at zero, then each field in turn at the values it is checked at *)
CheckedMdEntrySize2 ==
    { ZeroMdEntrySize2 }
        \cup { [ZeroMdEntrySize2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntrySize2 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear3 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear3(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear3 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear3 ==
    { ZeroMaturityMonthYear3 }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Strike Price Decimal: 9 bytes                                           *)
(***************************************************************************)

StrikePriceDecimal ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeStrikePriceDecimal(message) ==
    message.mantissa
        \o message.exponent

DecodeStrikePriceDecimal(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroStrikePriceDecimal ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Strike Price Decimal at zero, then each field in turn at the values it is checked at *)
CheckedStrikePriceDecimal ==
    { ZeroStrikePriceDecimal }
        \cup { [ZeroStrikePriceDecimal EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroStrikePriceDecimal EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Unit Of Measure Qty Decimal: 9 bytes                                    *)
(***************************************************************************)

UnitOfMeasureQtyDecimal ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeUnitOfMeasureQtyDecimal(message) ==
    message.mantissa
        \o message.exponent

DecodeUnitOfMeasureQtyDecimal(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroUnitOfMeasureQtyDecimal ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Unit Of Measure Qty Decimal at zero, then each field in turn at the values it is checked at *)
CheckedUnitOfMeasureQtyDecimal ==
    { ZeroUnitOfMeasureQtyDecimal }
        \cup { [ZeroUnitOfMeasureQtyDecimal EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroUnitOfMeasureQtyDecimal EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear3 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear3(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear3 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear3 ==
    { ZeroUnderlyingMaturityMonthYear3 }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear3 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Otc Underlyings Group: 68 bytes                                         *)
(***************************************************************************)

OtcUnderlyingsGroup ==
    [ underlyingSymbol                           : Sample(50),
      underlyingMaturityMonthYear                : UnderlyingMaturityMonthYear3,
      underlyingSecurityType                     : Sample(9),
      underlyingSecurityExchangeSecurityExchange : Sample(4) ]

EncodeOtcUnderlyingsGroup(message) ==
    message.underlyingSymbol
        \o EncodeUnderlyingMaturityMonthYear3(message.underlyingMaturityMonthYear)
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchangeSecurityExchange

DecodeOtcUnderlyingsGroup(bytes) ==
    LET underlyingSymbol == ReadBytes(bytes, 50) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear3(underlyingSymbol.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingMaturityMonthYear.rest, 9) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchangeSecurityExchange == ReadBytes(underlyingSecurityType.rest, 4) IN IF ~underlyingSecurityExchangeSecurityExchange.ok THEN Fail ELSE
    Ok([ underlyingSymbol                           |-> underlyingSymbol.value,
         underlyingMaturityMonthYear                |-> underlyingMaturityMonthYear.value,
         underlyingSecurityType                     |-> underlyingSecurityType.value,
         underlyingSecurityExchangeSecurityExchange |-> underlyingSecurityExchangeSecurityExchange.value ], underlyingSecurityExchangeSecurityExchange.rest)

ZeroOtcUnderlyingsGroup ==
    [ underlyingSymbol                           |-> [i \in 1 .. 50 |-> 0],
      underlyingMaturityMonthYear                |-> ZeroUnderlyingMaturityMonthYear3,
      underlyingSecurityType                     |-> [i \in 1 .. 9 |-> 0],
      underlyingSecurityExchangeSecurityExchange |-> [i \in 1 .. 4 |-> 0] ]

(* Otc Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedOtcUnderlyingsGroup ==
    { ZeroOtcUnderlyingsGroup }
        \cup { [ZeroOtcUnderlyingsGroup EXCEPT !.underlyingSymbol = one] : one \in Sample(50) }
        \cup { [ZeroOtcUnderlyingsGroup EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear3 }
        \cup { [ZeroOtcUnderlyingsGroup EXCEPT !.underlyingSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroOtcUnderlyingsGroup EXCEPT !.underlyingSecurityExchangeSecurityExchange = one] : one \in Sample(4) }

(* A run of Otc Underlyings Group, written one after another *)
RECURSIVE EncodeOtcUnderlyingsGroupList(_)
EncodeOtcUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOtcUnderlyingsGroup(Head(messages)) \o EncodeOtcUnderlyingsGroupList(Tail(messages))

(* As many Otc Underlyings Group as the field that counts them says *)
RECURSIVE ReadOtcUnderlyingsGroupList(_, _)
ReadOtcUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOtcUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOtcUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Otc Underlyings Group of each kind, for the lists that carry them *)
OneOtcUnderlyingsGroup == { ZeroOtcUnderlyingsGroup }

(***************************************************************************)
(* Otc Underlyings Groups                                                  *)
(***************************************************************************)

OtcUnderlyingsGroups ==
    [ blockLength         : Sample(2),
      otcUnderlyingsGroup : SampleLists(OneOtcUnderlyingsGroup) ]

EncodeOtcUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.otcUnderlyingsGroup), 1)
        \o EncodeOtcUnderlyingsGroupList(message.otcUnderlyingsGroup)

DecodeOtcUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET otcUnderlyingsGroup == ReadOtcUnderlyingsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~otcUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength         |-> blockLength.value,
         otcUnderlyingsGroup |-> otcUnderlyingsGroup.value ], otcUnderlyingsGroup.rest)

ZeroOtcUnderlyingsGroups ==
    [ blockLength         |-> [i \in 1 .. 2 |-> 0],
      otcUnderlyingsGroup |-> << >> ]

(* Otc Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtcUnderlyingsGroups ==
    { ZeroOtcUnderlyingsGroups }
        \cup { [ZeroOtcUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOtcUnderlyingsGroups EXCEPT !.otcUnderlyingsGroup = one] : one \in SampleLists(OneOtcUnderlyingsGroup) }

(***************************************************************************)
(* Otc Security Alt Id Group: 51 bytes                                     *)
(***************************************************************************)

OtcSecurityAltIdGroup ==
    [ securityAltIDStringLength50 : Sample(50),
      securityAltIdSource         : Sample(1) ]

EncodeOtcSecurityAltIdGroup(message) ==
    message.securityAltIDStringLength50
        \o message.securityAltIdSource

DecodeOtcSecurityAltIdGroup(bytes) ==
    LET securityAltIDStringLength50 == ReadBytes(bytes, 50) IN IF ~securityAltIDStringLength50.ok THEN Fail ELSE
    LET securityAltIdSource == ReadBytes(securityAltIDStringLength50.rest, 1) IN IF ~securityAltIdSource.ok THEN Fail ELSE
    Ok([ securityAltIDStringLength50 |-> securityAltIDStringLength50.value,
         securityAltIdSource         |-> securityAltIdSource.value ], securityAltIdSource.rest)

ZeroOtcSecurityAltIdGroup ==
    [ securityAltIDStringLength50 |-> [i \in 1 .. 50 |-> 0],
      securityAltIdSource         |-> [i \in 1 .. 1 |-> 0] ]

(* Otc Security Alt Id Group at zero, then each field in turn at the values it is checked at *)
CheckedOtcSecurityAltIdGroup ==
    { ZeroOtcSecurityAltIdGroup }
        \cup { [ZeroOtcSecurityAltIdGroup EXCEPT !.securityAltIDStringLength50 = one] : one \in Sample(50) }
        \cup { [ZeroOtcSecurityAltIdGroup EXCEPT !.securityAltIdSource = one] : one \in Sample(1) }

(* A run of Otc Security Alt Id Group, written one after another *)
RECURSIVE EncodeOtcSecurityAltIdGroupList(_)
EncodeOtcSecurityAltIdGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOtcSecurityAltIdGroup(Head(messages)) \o EncodeOtcSecurityAltIdGroupList(Tail(messages))

(* As many Otc Security Alt Id Group as the field that counts them says *)
RECURSIVE ReadOtcSecurityAltIdGroupList(_, _)
ReadOtcSecurityAltIdGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOtcSecurityAltIdGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOtcSecurityAltIdGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Otc Security Alt Id Group of each kind, for the lists that carry them *)
OneOtcSecurityAltIdGroup == { ZeroOtcSecurityAltIdGroup }

(***************************************************************************)
(* Otc Security Alt Id Groups                                              *)
(***************************************************************************)

OtcSecurityAltIdGroups ==
    [ blockLength           : Sample(2),
      otcSecurityAltIdGroup : SampleLists(OneOtcSecurityAltIdGroup) ]

EncodeOtcSecurityAltIdGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.otcSecurityAltIdGroup), 1)
        \o EncodeOtcSecurityAltIdGroupList(message.otcSecurityAltIdGroup)

DecodeOtcSecurityAltIdGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET otcSecurityAltIdGroup == ReadOtcSecurityAltIdGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~otcSecurityAltIdGroup.ok THEN Fail ELSE
    Ok([ blockLength           |-> blockLength.value,
         otcSecurityAltIdGroup |-> otcSecurityAltIdGroup.value ], otcSecurityAltIdGroup.rest)

ZeroOtcSecurityAltIdGroups ==
    [ blockLength           |-> [i \in 1 .. 2 |-> 0],
      otcSecurityAltIdGroup |-> << >> ]

(* Otc Security Alt Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtcSecurityAltIdGroups ==
    { ZeroOtcSecurityAltIdGroups }
        \cup { [ZeroOtcSecurityAltIdGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOtcSecurityAltIdGroups EXCEPT !.otcSecurityAltIdGroup = one] : one \in SampleLists(OneOtcSecurityAltIdGroup) }

(***************************************************************************)
(* Otc Original Group                                                      *)
(***************************************************************************)

OtcOriginalGroup ==
    [ mdEntryType                   : Sample(1),
      rptSeq                        : Sample(4),
      mdEntryPxOptional             : Sample(8),
      mdEntrySize                   : MdEntrySize2,
      symbol                        : Sample(50),
      securityGroup12               : Sample(12),
      securityType                  : Sample(9),
      maturityMonthYear             : MaturityMonthYear3,
      securityExchange              : Sample(4),
      productOptional               : Sample(1),
      maturityDate                  : Sample(2),
      couponRate                    : Sample(4),
      restructuringType             : Sample(2),
      seniority                     : Sample(2),
      notionalPercentageOutstanding : Sample(4),
      putOrCall                     : Sample(1),
      strikePriceDecimal            : StrikePriceDecimal,
      unitOfMeasure                 : Sample(5),
      unitOfMeasureCurrency         : Sample(3),
      unitOfMeasureQtyDecimal       : UnitOfMeasureQtyDecimal,
      mdEntryDate                   : Sample(4),
      openCloseSettlFlag            : Sample(1),
      priceType                     : Sample(2),
      settlDate                     : Sample(2),
      quoteCondition                : Sample(1),
      marketSector                  : Sample(26),
      sectorGroup                   : Sample(2),
      sectorSubGroup                : Sample(26),
      productComplex                : Sample(26),
      securitySubType               : Sample(2),
      volType                       : Sample(2),
      referenceId100                : Sample(100),
      otcUnderlyingsGroups          : OtcUnderlyingsGroups,
      otcSecurityAltIdGroups        : OtcSecurityAltIdGroups ]

EncodeOtcOriginalGroup(message) ==
    message.mdEntryType
        \o message.rptSeq
        \o message.mdEntryPxOptional
        \o EncodeMdEntrySize2(message.mdEntrySize)
        \o message.symbol
        \o message.securityGroup12
        \o message.securityType
        \o EncodeMaturityMonthYear3(message.maturityMonthYear)
        \o message.securityExchange
        \o message.productOptional
        \o message.maturityDate
        \o message.couponRate
        \o message.restructuringType
        \o message.seniority
        \o message.notionalPercentageOutstanding
        \o message.putOrCall
        \o EncodeStrikePriceDecimal(message.strikePriceDecimal)
        \o message.unitOfMeasure
        \o message.unitOfMeasureCurrency
        \o EncodeUnitOfMeasureQtyDecimal(message.unitOfMeasureQtyDecimal)
        \o message.mdEntryDate
        \o message.openCloseSettlFlag
        \o message.priceType
        \o message.settlDate
        \o message.quoteCondition
        \o message.marketSector
        \o message.sectorGroup
        \o message.sectorSubGroup
        \o message.productComplex
        \o message.securitySubType
        \o message.volType
        \o message.referenceId100
        \o EncodeOtcUnderlyingsGroups(message.otcUnderlyingsGroups)
        \o EncodeOtcSecurityAltIdGroups(message.otcSecurityAltIdGroups)

DecodeOtcOriginalGroup(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryType.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPxOptional == ReadBytes(rptSeq.rest, 8) IN IF ~mdEntryPxOptional.ok THEN Fail ELSE
    LET mdEntrySize == DecodeMdEntrySize2(mdEntryPxOptional.rest) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET symbol == ReadBytes(mdEntrySize.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup12 == ReadBytes(symbol.rest, 12) IN IF ~securityGroup12.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup12.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear3(securityType.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(maturityMonthYear.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET productOptional == ReadBytes(securityExchange.rest, 1) IN IF ~productOptional.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(productOptional.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET couponRate == ReadBytes(maturityDate.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET restructuringType == ReadBytes(couponRate.rest, 2) IN IF ~restructuringType.ok THEN Fail ELSE
    LET seniority == ReadBytes(restructuringType.rest, 2) IN IF ~seniority.ok THEN Fail ELSE
    LET notionalPercentageOutstanding == ReadBytes(seniority.rest, 4) IN IF ~notionalPercentageOutstanding.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(notionalPercentageOutstanding.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePriceDecimal == DecodeStrikePriceDecimal(putOrCall.rest) IN IF ~strikePriceDecimal.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(strikePriceDecimal.rest, 5) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureCurrency == ReadBytes(unitOfMeasure.rest, 3) IN IF ~unitOfMeasureCurrency.ok THEN Fail ELSE
    LET unitOfMeasureQtyDecimal == DecodeUnitOfMeasureQtyDecimal(unitOfMeasureCurrency.rest) IN IF ~unitOfMeasureQtyDecimal.ok THEN Fail ELSE
    LET mdEntryDate == ReadBytes(unitOfMeasureQtyDecimal.rest, 4) IN IF ~mdEntryDate.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdEntryDate.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET priceType == ReadBytes(openCloseSettlFlag.rest, 2) IN IF ~priceType.ok THEN Fail ELSE
    LET settlDate == ReadBytes(priceType.rest, 2) IN IF ~settlDate.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(settlDate.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET marketSector == ReadBytes(quoteCondition.rest, 26) IN IF ~marketSector.ok THEN Fail ELSE
    LET sectorGroup == ReadBytes(marketSector.rest, 2) IN IF ~sectorGroup.ok THEN Fail ELSE
    LET sectorSubGroup == ReadBytes(sectorGroup.rest, 26) IN IF ~sectorSubGroup.ok THEN Fail ELSE
    LET productComplex == ReadBytes(sectorSubGroup.rest, 26) IN IF ~productComplex.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(productComplex.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET volType == ReadBytes(securitySubType.rest, 2) IN IF ~volType.ok THEN Fail ELSE
    LET referenceId100 == ReadBytes(volType.rest, 100) IN IF ~referenceId100.ok THEN Fail ELSE
    LET otcUnderlyingsGroups == DecodeOtcUnderlyingsGroups(referenceId100.rest) IN IF ~otcUnderlyingsGroups.ok THEN Fail ELSE
    LET otcSecurityAltIdGroups == DecodeOtcSecurityAltIdGroups(otcUnderlyingsGroups.rest) IN IF ~otcSecurityAltIdGroups.ok THEN Fail ELSE
    Ok([ mdEntryType                   |-> mdEntryType.value,
         rptSeq                        |-> rptSeq.value,
         mdEntryPxOptional             |-> mdEntryPxOptional.value,
         mdEntrySize                   |-> mdEntrySize.value,
         symbol                        |-> symbol.value,
         securityGroup12               |-> securityGroup12.value,
         securityType                  |-> securityType.value,
         maturityMonthYear             |-> maturityMonthYear.value,
         securityExchange              |-> securityExchange.value,
         productOptional               |-> productOptional.value,
         maturityDate                  |-> maturityDate.value,
         couponRate                    |-> couponRate.value,
         restructuringType             |-> restructuringType.value,
         seniority                     |-> seniority.value,
         notionalPercentageOutstanding |-> notionalPercentageOutstanding.value,
         putOrCall                     |-> putOrCall.value,
         strikePriceDecimal            |-> strikePriceDecimal.value,
         unitOfMeasure                 |-> unitOfMeasure.value,
         unitOfMeasureCurrency         |-> unitOfMeasureCurrency.value,
         unitOfMeasureQtyDecimal       |-> unitOfMeasureQtyDecimal.value,
         mdEntryDate                   |-> mdEntryDate.value,
         openCloseSettlFlag            |-> openCloseSettlFlag.value,
         priceType                     |-> priceType.value,
         settlDate                     |-> settlDate.value,
         quoteCondition                |-> quoteCondition.value,
         marketSector                  |-> marketSector.value,
         sectorGroup                   |-> sectorGroup.value,
         sectorSubGroup                |-> sectorSubGroup.value,
         productComplex                |-> productComplex.value,
         securitySubType               |-> securitySubType.value,
         volType                       |-> volType.value,
         referenceId100                |-> referenceId100.value,
         otcUnderlyingsGroups          |-> otcUnderlyingsGroups.value,
         otcSecurityAltIdGroups        |-> otcSecurityAltIdGroups.value ], otcSecurityAltIdGroups.rest)

ZeroOtcOriginalGroup ==
    [ mdEntryType                   |-> [i \in 1 .. 1 |-> 0],
      rptSeq                        |-> [i \in 1 .. 4 |-> 0],
      mdEntryPxOptional             |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                   |-> ZeroMdEntrySize2,
      symbol                        |-> [i \in 1 .. 50 |-> 0],
      securityGroup12               |-> [i \in 1 .. 12 |-> 0],
      securityType                  |-> [i \in 1 .. 9 |-> 0],
      maturityMonthYear             |-> ZeroMaturityMonthYear3,
      securityExchange              |-> [i \in 1 .. 4 |-> 0],
      productOptional               |-> [i \in 1 .. 1 |-> 0],
      maturityDate                  |-> [i \in 1 .. 2 |-> 0],
      couponRate                    |-> [i \in 1 .. 4 |-> 0],
      restructuringType             |-> [i \in 1 .. 2 |-> 0],
      seniority                     |-> [i \in 1 .. 2 |-> 0],
      notionalPercentageOutstanding |-> [i \in 1 .. 4 |-> 0],
      putOrCall                     |-> [i \in 1 .. 1 |-> 0],
      strikePriceDecimal            |-> ZeroStrikePriceDecimal,
      unitOfMeasure                 |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureCurrency         |-> [i \in 1 .. 3 |-> 0],
      unitOfMeasureQtyDecimal       |-> ZeroUnitOfMeasureQtyDecimal,
      mdEntryDate                   |-> [i \in 1 .. 4 |-> 0],
      openCloseSettlFlag            |-> [i \in 1 .. 1 |-> 0],
      priceType                     |-> [i \in 1 .. 2 |-> 0],
      settlDate                     |-> [i \in 1 .. 2 |-> 0],
      quoteCondition                |-> [i \in 1 .. 1 |-> 0],
      marketSector                  |-> [i \in 1 .. 26 |-> 0],
      sectorGroup                   |-> [i \in 1 .. 2 |-> 0],
      sectorSubGroup                |-> [i \in 1 .. 26 |-> 0],
      productComplex                |-> [i \in 1 .. 26 |-> 0],
      securitySubType               |-> [i \in 1 .. 2 |-> 0],
      volType                       |-> [i \in 1 .. 2 |-> 0],
      referenceId100                |-> [i \in 1 .. 100 |-> 0],
      otcUnderlyingsGroups          |-> ZeroOtcUnderlyingsGroups,
      otcSecurityAltIdGroups        |-> ZeroOtcSecurityAltIdGroups ]

(* Otc Original Group at zero, then each field in turn at the values it is checked at *)
CheckedOtcOriginalGroup ==
    { ZeroOtcOriginalGroup }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.mdEntryPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.mdEntrySize = one] : one \in CheckedMdEntrySize2 }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.securityGroup12 = one] : one \in Sample(12) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear3 }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.productOptional = one] : one \in Sample(1) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.restructuringType = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.seniority = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.notionalPercentageOutstanding = one] : one \in Sample(4) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.strikePriceDecimal = one] : one \in CheckedStrikePriceDecimal }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.unitOfMeasureCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.unitOfMeasureQtyDecimal = one] : one \in CheckedUnitOfMeasureQtyDecimal }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.mdEntryDate = one] : one \in Sample(4) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.priceType = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.settlDate = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.marketSector = one] : one \in Sample(26) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.sectorGroup = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.sectorSubGroup = one] : one \in Sample(26) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.productComplex = one] : one \in Sample(26) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.volType = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.referenceId100 = one] : one \in Sample(100) }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.otcUnderlyingsGroups = one] : one \in CheckedOtcUnderlyingsGroups }
        \cup { [ZeroOtcOriginalGroup EXCEPT !.otcSecurityAltIdGroups = one] : one \in CheckedOtcSecurityAltIdGroups }

(* A run of Otc Original Group, written one after another *)
RECURSIVE EncodeOtcOriginalGroupList(_)
EncodeOtcOriginalGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOtcOriginalGroup(Head(messages)) \o EncodeOtcOriginalGroupList(Tail(messages))

(* As many Otc Original Group as the field that counts them says *)
RECURSIVE ReadOtcOriginalGroupList(_, _)
ReadOtcOriginalGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOtcOriginalGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOtcOriginalGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Otc Original Group of each kind, for the lists that carry them *)
OneOtcOriginalGroup == { ZeroOtcOriginalGroup }

(***************************************************************************)
(* Otc Original Groups                                                     *)
(***************************************************************************)

OtcOriginalGroups ==
    [ blockLength      : Sample(2),
      otcOriginalGroup : SampleLists(OneOtcOriginalGroup) ]

EncodeOtcOriginalGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.otcOriginalGroup), 1)
        \o EncodeOtcOriginalGroupList(message.otcOriginalGroup)

DecodeOtcOriginalGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET otcOriginalGroup == ReadOtcOriginalGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~otcOriginalGroup.ok THEN Fail ELSE
    Ok([ blockLength      |-> blockLength.value,
         otcOriginalGroup |-> otcOriginalGroup.value ], otcOriginalGroup.rest)

ZeroOtcOriginalGroups ==
    [ blockLength      |-> [i \in 1 .. 2 |-> 0],
      otcOriginalGroup |-> << >> ]

(* Otc Original Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtcOriginalGroups ==
    { ZeroOtcOriginalGroups }
        \cup { [ZeroOtcOriginalGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOtcOriginalGroups EXCEPT !.otcOriginalGroup = one] : one \in SampleLists(OneOtcOriginalGroup) }

(***************************************************************************)
(* Md Incremental Refresh Ot C 356                                         *)
(***************************************************************************)

MdIncrementalRefreshOtC356 ==
    [ transactTime               : Sample(8),
      tradeDate                  : Sample(2),
      matchEventIndicator        : Sample(1),
      batchTotalMessagesOptional : Sample(2),
      otcOriginalGroups          : OtcOriginalGroups ]

EncodeMdIncrementalRefreshOtC356(message) ==
    message.transactTime
        \o message.tradeDate
        \o message.matchEventIndicator
        \o message.batchTotalMessagesOptional
        \o EncodeOtcOriginalGroups(message.otcOriginalGroups)

DecodeMdIncrementalRefreshOtC356(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(transactTime.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(tradeDate.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessagesOptional == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessagesOptional.ok THEN Fail ELSE
    LET otcOriginalGroups == DecodeOtcOriginalGroups(batchTotalMessagesOptional.rest) IN IF ~otcOriginalGroups.ok THEN Fail ELSE
    Ok([ transactTime               |-> transactTime.value,
         tradeDate                  |-> tradeDate.value,
         matchEventIndicator        |-> matchEventIndicator.value,
         batchTotalMessagesOptional |-> batchTotalMessagesOptional.value,
         otcOriginalGroups          |-> otcOriginalGroups.value ], otcOriginalGroups.rest)

ZeroMdIncrementalRefreshOtC356 ==
    [ transactTime               |-> [i \in 1 .. 8 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      matchEventIndicator        |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessagesOptional |-> [i \in 1 .. 2 |-> 0],
      otcOriginalGroups          |-> ZeroOtcOriginalGroups ]

(* Md Incremental Refresh Ot C 356 at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshOtC356 ==
    { ZeroMdIncrementalRefreshOtC356 }
        \cup { [ZeroMdIncrementalRefreshOtC356 EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshOtC356 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshOtC356 EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshOtC356 EXCEPT !.batchTotalMessagesOptional = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshOtC356 EXCEPT !.otcOriginalGroups = one] : one \in CheckedOtcOriginalGroups }

(***************************************************************************)
(* Min Price Increment: 9 bytes                                            *)
(***************************************************************************)

MinPriceIncrement ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMinPriceIncrement(message) ==
    message.mantissa
        \o message.exponent

DecodeMinPriceIncrement(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMinPriceIncrement ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Min Price Increment at zero, then each field in turn at the values it is checked at *)
CheckedMinPriceIncrement ==
    { ZeroMinPriceIncrement }
        \cup { [ZeroMinPriceIncrement EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMinPriceIncrement EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Eris Feed Types Group: 4 bytes                                          *)
(***************************************************************************)

ErisFeedTypesGroup ==
    [ mdFeedType3 : Sample(3),
      marketDepth : Sample(1) ]

EncodeErisFeedTypesGroup(message) ==
    message.mdFeedType3
        \o message.marketDepth

DecodeErisFeedTypesGroup(bytes) ==
    LET mdFeedType3 == ReadBytes(bytes, 3) IN IF ~mdFeedType3.ok THEN Fail ELSE
    LET marketDepth == ReadBytes(mdFeedType3.rest, 1) IN IF ~marketDepth.ok THEN Fail ELSE
    Ok([ mdFeedType3 |-> mdFeedType3.value,
         marketDepth |-> marketDepth.value ], marketDepth.rest)

ZeroErisFeedTypesGroup ==
    [ mdFeedType3 |-> [i \in 1 .. 3 |-> 0],
      marketDepth |-> [i \in 1 .. 1 |-> 0] ]

(* Eris Feed Types Group at zero, then each field in turn at the values it is checked at *)
CheckedErisFeedTypesGroup ==
    { ZeroErisFeedTypesGroup }
        \cup { [ZeroErisFeedTypesGroup EXCEPT !.mdFeedType3 = one] : one \in Sample(3) }
        \cup { [ZeroErisFeedTypesGroup EXCEPT !.marketDepth = one] : one \in Sample(1) }

(* A run of Eris Feed Types Group, written one after another *)
RECURSIVE EncodeErisFeedTypesGroupList(_)
EncodeErisFeedTypesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisFeedTypesGroup(Head(messages)) \o EncodeErisFeedTypesGroupList(Tail(messages))

(* As many Eris Feed Types Group as the field that counts them says *)
RECURSIVE ReadErisFeedTypesGroupList(_, _)
ReadErisFeedTypesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisFeedTypesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisFeedTypesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Feed Types Group of each kind, for the lists that carry them *)
OneErisFeedTypesGroup == { ZeroErisFeedTypesGroup }

(***************************************************************************)
(* Eris Feed Types Groups                                                  *)
(***************************************************************************)

ErisFeedTypesGroups ==
    [ blockLength        : Sample(2),
      erisFeedTypesGroup : SampleLists(OneErisFeedTypesGroup) ]

EncodeErisFeedTypesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisFeedTypesGroup), 1)
        \o EncodeErisFeedTypesGroupList(message.erisFeedTypesGroup)

DecodeErisFeedTypesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisFeedTypesGroup == ReadErisFeedTypesGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~erisFeedTypesGroup.ok THEN Fail ELSE
    Ok([ blockLength        |-> blockLength.value,
         erisFeedTypesGroup |-> erisFeedTypesGroup.value ], erisFeedTypesGroup.rest)

ZeroErisFeedTypesGroups ==
    [ blockLength        |-> [i \in 1 .. 2 |-> 0],
      erisFeedTypesGroup |-> << >> ]

(* Eris Feed Types Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisFeedTypesGroups ==
    { ZeroErisFeedTypesGroups }
        \cup { [ZeroErisFeedTypesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisFeedTypesGroups EXCEPT !.erisFeedTypesGroup = one] : one \in SampleLists(OneErisFeedTypesGroup) }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup6 ==
    [ eventTypeOptional : Sample(1),
      eventTimeOptional : Sample(8) ]

EncodeEventsGroup6(message) ==
    message.eventTypeOptional
        \o message.eventTimeOptional

DecodeEventsGroup6(bytes) ==
    LET eventTypeOptional == ReadBytes(bytes, 1) IN IF ~eventTypeOptional.ok THEN Fail ELSE
    LET eventTimeOptional == ReadBytes(eventTypeOptional.rest, 8) IN IF ~eventTimeOptional.ok THEN Fail ELSE
    Ok([ eventTypeOptional |-> eventTypeOptional.value,
         eventTimeOptional |-> eventTimeOptional.value ], eventTimeOptional.rest)

ZeroEventsGroup6 ==
    [ eventTypeOptional |-> [i \in 1 .. 1 |-> 0],
      eventTimeOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup6 ==
    { ZeroEventsGroup6 }
        \cup { [ZeroEventsGroup6 EXCEPT !.eventTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup6 EXCEPT !.eventTimeOptional = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup6List(_)
EncodeEventsGroup6List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup6(Head(messages)) \o EncodeEventsGroup6List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup6List(_, _)
ReadEventsGroup6List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup6(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup6List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup6 == { ZeroEventsGroup6 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups6 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup6) ]

EncodeEventsGroups6(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup6List(message.eventsGroup)

DecodeEventsGroups6(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup6List(numInGroup8.rest, numInGroup8.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups6 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups6 ==
    { ZeroEventsGroups6 }
        \cup { [ZeroEventsGroups6 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups6 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup6) }

(***************************************************************************)
(* Eris Security Alt Id Group: 27 bytes                                    *)
(***************************************************************************)

ErisSecurityAltIdGroup4 ==
    [ securityAltId50             : Sample(26),
      securityAltIdSourceOptional : Sample(1) ]

EncodeErisSecurityAltIdGroup4(message) ==
    message.securityAltId50
        \o message.securityAltIdSourceOptional

DecodeErisSecurityAltIdGroup4(bytes) ==
    LET securityAltId50 == ReadBytes(bytes, 26) IN IF ~securityAltId50.ok THEN Fail ELSE
    LET securityAltIdSourceOptional == ReadBytes(securityAltId50.rest, 1) IN IF ~securityAltIdSourceOptional.ok THEN Fail ELSE
    Ok([ securityAltId50             |-> securityAltId50.value,
         securityAltIdSourceOptional |-> securityAltIdSourceOptional.value ], securityAltIdSourceOptional.rest)

ZeroErisSecurityAltIdGroup4 ==
    [ securityAltId50             |-> [i \in 1 .. 26 |-> 0],
      securityAltIdSourceOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Eris Security Alt Id Group at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroup4 ==
    { ZeroErisSecurityAltIdGroup4 }
        \cup { [ZeroErisSecurityAltIdGroup4 EXCEPT !.securityAltId50 = one] : one \in Sample(26) }
        \cup { [ZeroErisSecurityAltIdGroup4 EXCEPT !.securityAltIdSourceOptional = one] : one \in Sample(1) }

(* A run of Eris Security Alt Id Group, written one after another *)
RECURSIVE EncodeErisSecurityAltIdGroup4List(_)
EncodeErisSecurityAltIdGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisSecurityAltIdGroup4(Head(messages)) \o EncodeErisSecurityAltIdGroup4List(Tail(messages))

(* As many Eris Security Alt Id Group as the field that counts them says *)
RECURSIVE ReadErisSecurityAltIdGroup4List(_, _)
ReadErisSecurityAltIdGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisSecurityAltIdGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisSecurityAltIdGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Security Alt Id Group of each kind, for the lists that carry them *)
OneErisSecurityAltIdGroup4 == { ZeroErisSecurityAltIdGroup4 }

(***************************************************************************)
(* Eris Security Alt Id Groups                                             *)
(***************************************************************************)

ErisSecurityAltIdGroups4 ==
    [ blockLength            : Sample(2),
      erisSecurityAltIdGroup : SampleLists(OneErisSecurityAltIdGroup4) ]

EncodeErisSecurityAltIdGroups4(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisSecurityAltIdGroup), 1)
        \o EncodeErisSecurityAltIdGroup4List(message.erisSecurityAltIdGroup)

DecodeErisSecurityAltIdGroups4(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisSecurityAltIdGroup == ReadErisSecurityAltIdGroup4List(numInGroup8.rest, numInGroup8.value) IN IF ~erisSecurityAltIdGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         erisSecurityAltIdGroup |-> erisSecurityAltIdGroup.value ], erisSecurityAltIdGroup.rest)

ZeroErisSecurityAltIdGroups4 ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      erisSecurityAltIdGroup |-> << >> ]

(* Eris Security Alt Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroups4 ==
    { ZeroErisSecurityAltIdGroups4 }
        \cup { [ZeroErisSecurityAltIdGroups4 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisSecurityAltIdGroups4 EXCEPT !.erisSecurityAltIdGroup = one] : one \in SampleLists(OneErisSecurityAltIdGroup4) }

(***************************************************************************)
(* Previous Fixing Rate: 9 bytes                                           *)
(***************************************************************************)

PreviousFixingRate ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodePreviousFixingRate(message) ==
    message.mantissa
        \o message.exponent

DecodePreviousFixingRate(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroPreviousFixingRate ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Previous Fixing Rate at zero, then each field in turn at the values it is checked at *)
CheckedPreviousFixingRate ==
    { ZeroPreviousFixingRate }
        \cup { [ZeroPreviousFixingRate EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroPreviousFixingRate EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Interpolation Factor: 9 bytes                                           *)
(***************************************************************************)

InterpolationFactor ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeInterpolationFactor(message) ==
    message.mantissa
        \o message.exponent

DecodeInterpolationFactor(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroInterpolationFactor ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Interpolation Factor at zero, then each field in turn at the values it is checked at *)
CheckedInterpolationFactor ==
    { ZeroInterpolationFactor }
        \cup { [ZeroInterpolationFactor EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroInterpolationFactor EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Eris Security Alt Id Group: 27 bytes                                    *)
(***************************************************************************)

ErisSecurityAltIdGroup5 ==
    [ securityAltId50             : Sample(26),
      securityAltIdSourceOptional : Sample(1) ]

EncodeErisSecurityAltIdGroup5(message) ==
    message.securityAltId50
        \o message.securityAltIdSourceOptional

DecodeErisSecurityAltIdGroup5(bytes) ==
    LET securityAltId50 == ReadBytes(bytes, 26) IN IF ~securityAltId50.ok THEN Fail ELSE
    LET securityAltIdSourceOptional == ReadBytes(securityAltId50.rest, 1) IN IF ~securityAltIdSourceOptional.ok THEN Fail ELSE
    Ok([ securityAltId50             |-> securityAltId50.value,
         securityAltIdSourceOptional |-> securityAltIdSourceOptional.value ], securityAltIdSourceOptional.rest)

ZeroErisSecurityAltIdGroup5 ==
    [ securityAltId50             |-> [i \in 1 .. 26 |-> 0],
      securityAltIdSourceOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Eris Security Alt Id Group at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroup5 ==
    { ZeroErisSecurityAltIdGroup5 }
        \cup { [ZeroErisSecurityAltIdGroup5 EXCEPT !.securityAltId50 = one] : one \in Sample(26) }
        \cup { [ZeroErisSecurityAltIdGroup5 EXCEPT !.securityAltIdSourceOptional = one] : one \in Sample(1) }

(* A run of Eris Security Alt Id Group, written one after another *)
RECURSIVE EncodeErisSecurityAltIdGroup5List(_)
EncodeErisSecurityAltIdGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisSecurityAltIdGroup5(Head(messages)) \o EncodeErisSecurityAltIdGroup5List(Tail(messages))

(* As many Eris Security Alt Id Group as the field that counts them says *)
RECURSIVE ReadErisSecurityAltIdGroup5List(_, _)
ReadErisSecurityAltIdGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisSecurityAltIdGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisSecurityAltIdGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Security Alt Id Group of each kind, for the lists that carry them *)
OneErisSecurityAltIdGroup5 == { ZeroErisSecurityAltIdGroup5 }

(***************************************************************************)
(* Eris Security Alt Id Groups                                             *)
(***************************************************************************)

ErisSecurityAltIdGroups5 ==
    [ blockLength            : Sample(2),
      erisSecurityAltIdGroup : SampleLists(OneErisSecurityAltIdGroup5) ]

EncodeErisSecurityAltIdGroups5(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisSecurityAltIdGroup), 1)
        \o EncodeErisSecurityAltIdGroup5List(message.erisSecurityAltIdGroup)

DecodeErisSecurityAltIdGroups5(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisSecurityAltIdGroup == ReadErisSecurityAltIdGroup5List(numInGroup8.rest, numInGroup8.value) IN IF ~erisSecurityAltIdGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         erisSecurityAltIdGroup |-> erisSecurityAltIdGroup.value ], erisSecurityAltIdGroup.rest)

ZeroErisSecurityAltIdGroups5 ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      erisSecurityAltIdGroup |-> << >> ]

(* Eris Security Alt Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisSecurityAltIdGroups5 ==
    { ZeroErisSecurityAltIdGroups5 }
        \cup { [ZeroErisSecurityAltIdGroups5 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisSecurityAltIdGroups5 EXCEPT !.erisSecurityAltIdGroup = one] : one \in SampleLists(OneErisSecurityAltIdGroup5) }

(***************************************************************************)
(* Eris Legs Group                                                         *)
(***************************************************************************)

ErisLegsGroup ==
    [ legBenchmarkCurveName   : Sample(5),
      rateDescriptor          : Sample(8),
      previousFixingDate      : Sample(2),
      legPayFrequencey        : Sample(3),
      previousFixingRate      : PreviousFixingRate,
      legSymbol               : Sample(50),
      legRatioQtyInt32Null    : Sample(4),
      legSide                 : Sample(1),
      legCurrency             : Sample(3),
      legSecurityType4        : Sample(8),
      legSecurityGroup        : Sample(12),
      legDateOffset           : Sample(1),
      interpolationFactor     : InterpolationFactor,
      erisSecurityAltIdGroups : ErisSecurityAltIdGroups5 ]

EncodeErisLegsGroup(message) ==
    message.legBenchmarkCurveName
        \o message.rateDescriptor
        \o message.previousFixingDate
        \o message.legPayFrequencey
        \o EncodePreviousFixingRate(message.previousFixingRate)
        \o message.legSymbol
        \o message.legRatioQtyInt32Null
        \o message.legSide
        \o message.legCurrency
        \o message.legSecurityType4
        \o message.legSecurityGroup
        \o message.legDateOffset
        \o EncodeInterpolationFactor(message.interpolationFactor)
        \o EncodeErisSecurityAltIdGroups5(message.erisSecurityAltIdGroups)

DecodeErisLegsGroup(bytes) ==
    LET legBenchmarkCurveName == ReadBytes(bytes, 5) IN IF ~legBenchmarkCurveName.ok THEN Fail ELSE
    LET rateDescriptor == ReadBytes(legBenchmarkCurveName.rest, 8) IN IF ~rateDescriptor.ok THEN Fail ELSE
    LET previousFixingDate == ReadBytes(rateDescriptor.rest, 2) IN IF ~previousFixingDate.ok THEN Fail ELSE
    LET legPayFrequencey == ReadBytes(previousFixingDate.rest, 3) IN IF ~legPayFrequencey.ok THEN Fail ELSE
    LET previousFixingRate == DecodePreviousFixingRate(legPayFrequencey.rest) IN IF ~previousFixingRate.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(previousFixingRate.rest, 50) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatioQtyInt32Null == ReadBytes(legSymbol.rest, 4) IN IF ~legRatioQtyInt32Null.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQtyInt32Null.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legCurrency == ReadBytes(legSide.rest, 3) IN IF ~legCurrency.ok THEN Fail ELSE
    LET legSecurityType4 == ReadBytes(legCurrency.rest, 8) IN IF ~legSecurityType4.ok THEN Fail ELSE
    LET legSecurityGroup == ReadBytes(legSecurityType4.rest, 12) IN IF ~legSecurityGroup.ok THEN Fail ELSE
    LET legDateOffset == ReadBytes(legSecurityGroup.rest, 1) IN IF ~legDateOffset.ok THEN Fail ELSE
    LET interpolationFactor == DecodeInterpolationFactor(legDateOffset.rest) IN IF ~interpolationFactor.ok THEN Fail ELSE
    LET erisSecurityAltIdGroups == DecodeErisSecurityAltIdGroups5(interpolationFactor.rest) IN IF ~erisSecurityAltIdGroups.ok THEN Fail ELSE
    Ok([ legBenchmarkCurveName   |-> legBenchmarkCurveName.value,
         rateDescriptor          |-> rateDescriptor.value,
         previousFixingDate      |-> previousFixingDate.value,
         legPayFrequencey        |-> legPayFrequencey.value,
         previousFixingRate      |-> previousFixingRate.value,
         legSymbol               |-> legSymbol.value,
         legRatioQtyInt32Null    |-> legRatioQtyInt32Null.value,
         legSide                 |-> legSide.value,
         legCurrency             |-> legCurrency.value,
         legSecurityType4        |-> legSecurityType4.value,
         legSecurityGroup        |-> legSecurityGroup.value,
         legDateOffset           |-> legDateOffset.value,
         interpolationFactor     |-> interpolationFactor.value,
         erisSecurityAltIdGroups |-> erisSecurityAltIdGroups.value ], erisSecurityAltIdGroups.rest)

ZeroErisLegsGroup ==
    [ legBenchmarkCurveName   |-> [i \in 1 .. 5 |-> 0],
      rateDescriptor          |-> [i \in 1 .. 8 |-> 0],
      previousFixingDate      |-> [i \in 1 .. 2 |-> 0],
      legPayFrequencey        |-> [i \in 1 .. 3 |-> 0],
      previousFixingRate      |-> ZeroPreviousFixingRate,
      legSymbol               |-> [i \in 1 .. 50 |-> 0],
      legRatioQtyInt32Null    |-> [i \in 1 .. 4 |-> 0],
      legSide                 |-> [i \in 1 .. 1 |-> 0],
      legCurrency             |-> [i \in 1 .. 3 |-> 0],
      legSecurityType4        |-> [i \in 1 .. 8 |-> 0],
      legSecurityGroup        |-> [i \in 1 .. 12 |-> 0],
      legDateOffset           |-> [i \in 1 .. 1 |-> 0],
      interpolationFactor     |-> ZeroInterpolationFactor,
      erisSecurityAltIdGroups |-> ZeroErisSecurityAltIdGroups5 ]

(* Eris Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedErisLegsGroup ==
    { ZeroErisLegsGroup }
        \cup { [ZeroErisLegsGroup EXCEPT !.legBenchmarkCurveName = one] : one \in Sample(5) }
        \cup { [ZeroErisLegsGroup EXCEPT !.rateDescriptor = one] : one \in Sample(8) }
        \cup { [ZeroErisLegsGroup EXCEPT !.previousFixingDate = one] : one \in Sample(2) }
        \cup { [ZeroErisLegsGroup EXCEPT !.legPayFrequencey = one] : one \in Sample(3) }
        \cup { [ZeroErisLegsGroup EXCEPT !.previousFixingRate = one] : one \in CheckedPreviousFixingRate }
        \cup { [ZeroErisLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(50) }
        \cup { [ZeroErisLegsGroup EXCEPT !.legRatioQtyInt32Null = one] : one \in Sample(4) }
        \cup { [ZeroErisLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroErisLegsGroup EXCEPT !.legCurrency = one] : one \in Sample(3) }
        \cup { [ZeroErisLegsGroup EXCEPT !.legSecurityType4 = one] : one \in Sample(8) }
        \cup { [ZeroErisLegsGroup EXCEPT !.legSecurityGroup = one] : one \in Sample(12) }
        \cup { [ZeroErisLegsGroup EXCEPT !.legDateOffset = one] : one \in Sample(1) }
        \cup { [ZeroErisLegsGroup EXCEPT !.interpolationFactor = one] : one \in CheckedInterpolationFactor }
        \cup { [ZeroErisLegsGroup EXCEPT !.erisSecurityAltIdGroups = one] : one \in CheckedErisSecurityAltIdGroups5 }

(* A run of Eris Legs Group, written one after another *)
RECURSIVE EncodeErisLegsGroupList(_)
EncodeErisLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeErisLegsGroup(Head(messages)) \o EncodeErisLegsGroupList(Tail(messages))

(* As many Eris Legs Group as the field that counts them says *)
RECURSIVE ReadErisLegsGroupList(_, _)
ReadErisLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeErisLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadErisLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Eris Legs Group of each kind, for the lists that carry them *)
OneErisLegsGroup == { ZeroErisLegsGroup }

(***************************************************************************)
(* Eris Legs Groups                                                        *)
(***************************************************************************)

ErisLegsGroups ==
    [ blockLength   : Sample(2),
      erisLegsGroup : SampleLists(OneErisLegsGroup) ]

EncodeErisLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.erisLegsGroup), 1)
        \o EncodeErisLegsGroupList(message.erisLegsGroup)

DecodeErisLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET erisLegsGroup == ReadErisLegsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~erisLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         erisLegsGroup |-> erisLegsGroup.value ], erisLegsGroup.rest)

ZeroErisLegsGroups ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      erisLegsGroup |-> << >> ]

(* Eris Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedErisLegsGroups ==
    { ZeroErisLegsGroups }
        \cup { [ZeroErisLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroErisLegsGroups EXCEPT !.erisLegsGroup = one] : one \in SampleLists(OneErisLegsGroup) }

(***************************************************************************)
(* Md Instrument Definition Eris                                           *)
(***************************************************************************)

MdInstrumentDefinitionEris ==
    [ securityGroup12         : Sample(12),
      symbol                  : Sample(50),
      securityType4           : Sample(4),
      productOptional         : Sample(1),
      securityExchange        : Sample(4),
      maturityDate            : Sample(2),
      currency                : Sample(3),
      minPriceIncrement       : MinPriceIncrement,
      securityUpdateAction    : Sample(1),
      rateType                : Sample(2),
      couponRate              : Sample(4),
      userDefinedInstrument   : Sample(1),
      applId                  : Sample(2),
      erisFeedTypesGroups     : ErisFeedTypesGroups,
      eventsGroups            : EventsGroups6,
      erisSecurityAltIdGroups : ErisSecurityAltIdGroups4,
      erisLegsGroups          : ErisLegsGroups ]

EncodeMdInstrumentDefinitionEris(message) ==
    message.securityGroup12
        \o message.symbol
        \o message.securityType4
        \o message.productOptional
        \o message.securityExchange
        \o message.maturityDate
        \o message.currency
        \o EncodeMinPriceIncrement(message.minPriceIncrement)
        \o message.securityUpdateAction
        \o message.rateType
        \o message.couponRate
        \o message.userDefinedInstrument
        \o message.applId
        \o EncodeErisFeedTypesGroups(message.erisFeedTypesGroups)
        \o EncodeEventsGroups6(message.eventsGroups)
        \o EncodeErisSecurityAltIdGroups4(message.erisSecurityAltIdGroups)
        \o EncodeErisLegsGroups(message.erisLegsGroups)

DecodeMdInstrumentDefinitionEris(bytes) ==
    LET securityGroup12 == ReadBytes(bytes, 12) IN IF ~securityGroup12.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityGroup12.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityType4 == ReadBytes(symbol.rest, 4) IN IF ~securityType4.ok THEN Fail ELSE
    LET productOptional == ReadBytes(securityType4.rest, 1) IN IF ~productOptional.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(productOptional.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityExchange.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET currency == ReadBytes(maturityDate.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET minPriceIncrement == DecodeMinPriceIncrement(currency.rest) IN IF ~minPriceIncrement.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(minPriceIncrement.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET rateType == ReadBytes(securityUpdateAction.rest, 2) IN IF ~rateType.ok THEN Fail ELSE
    LET couponRate == ReadBytes(rateType.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET userDefinedInstrument == ReadBytes(couponRate.rest, 1) IN IF ~userDefinedInstrument.ok THEN Fail ELSE
    LET applId == ReadBytes(userDefinedInstrument.rest, 2) IN IF ~applId.ok THEN Fail ELSE
    LET erisFeedTypesGroups == DecodeErisFeedTypesGroups(applId.rest) IN IF ~erisFeedTypesGroups.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups6(erisFeedTypesGroups.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    LET erisSecurityAltIdGroups == DecodeErisSecurityAltIdGroups4(eventsGroups.rest) IN IF ~erisSecurityAltIdGroups.ok THEN Fail ELSE
    LET erisLegsGroups == DecodeErisLegsGroups(erisSecurityAltIdGroups.rest) IN IF ~erisLegsGroups.ok THEN Fail ELSE
    Ok([ securityGroup12         |-> securityGroup12.value,
         symbol                  |-> symbol.value,
         securityType4           |-> securityType4.value,
         productOptional         |-> productOptional.value,
         securityExchange        |-> securityExchange.value,
         maturityDate            |-> maturityDate.value,
         currency                |-> currency.value,
         minPriceIncrement       |-> minPriceIncrement.value,
         securityUpdateAction    |-> securityUpdateAction.value,
         rateType                |-> rateType.value,
         couponRate              |-> couponRate.value,
         userDefinedInstrument   |-> userDefinedInstrument.value,
         applId                  |-> applId.value,
         erisFeedTypesGroups     |-> erisFeedTypesGroups.value,
         eventsGroups            |-> eventsGroups.value,
         erisSecurityAltIdGroups |-> erisSecurityAltIdGroups.value,
         erisLegsGroups          |-> erisLegsGroups.value ], erisLegsGroups.rest)

ZeroMdInstrumentDefinitionEris ==
    [ securityGroup12         |-> [i \in 1 .. 12 |-> 0],
      symbol                  |-> [i \in 1 .. 50 |-> 0],
      securityType4           |-> [i \in 1 .. 4 |-> 0],
      productOptional         |-> [i \in 1 .. 1 |-> 0],
      securityExchange        |-> [i \in 1 .. 4 |-> 0],
      maturityDate            |-> [i \in 1 .. 2 |-> 0],
      currency                |-> [i \in 1 .. 3 |-> 0],
      minPriceIncrement       |-> ZeroMinPriceIncrement,
      securityUpdateAction    |-> [i \in 1 .. 1 |-> 0],
      rateType                |-> [i \in 1 .. 2 |-> 0],
      couponRate              |-> [i \in 1 .. 4 |-> 0],
      userDefinedInstrument   |-> [i \in 1 .. 1 |-> 0],
      applId                  |-> [i \in 1 .. 2 |-> 0],
      erisFeedTypesGroups     |-> ZeroErisFeedTypesGroups,
      eventsGroups            |-> ZeroEventsGroups6,
      erisSecurityAltIdGroups |-> ZeroErisSecurityAltIdGroups4,
      erisLegsGroups          |-> ZeroErisLegsGroups ]

(* Md Instrument Definition Eris at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentDefinitionEris ==
    { ZeroMdInstrumentDefinitionEris }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.securityGroup12 = one] : one \in Sample(12) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.securityType4 = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.productOptional = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.minPriceIncrement = one] : one \in CheckedMinPriceIncrement }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.rateType = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.userDefinedInstrument = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.applId = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.erisFeedTypesGroups = one] : one \in CheckedErisFeedTypesGroups }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups6 }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.erisSecurityAltIdGroups = one] : one \in CheckedErisSecurityAltIdGroups4 }
        \cup { [ZeroMdInstrumentDefinitionEris EXCEPT !.erisLegsGroups = one] : one \in CheckedErisLegsGroups }

(***************************************************************************)
(* Md Entry Size: 9 bytes                                                  *)
(***************************************************************************)

MdEntrySize3 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntrySize3(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntrySize3(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntrySize3 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Size at zero, then each field in turn at the values it is checked at *)
CheckedMdEntrySize3 ==
    { ZeroMdEntrySize3 }
        \cup { [ZeroMdEntrySize3 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntrySize3 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear4 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear4(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear4(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear4 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear4 ==
    { ZeroMaturityMonthYear4 }
        \cup { [ZeroMaturityMonthYear4 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear4 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear4 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear4 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Unit Of Measure Qty Decimal Optional: 9 bytes                           *)
(***************************************************************************)

UnitOfMeasureQtyDecimalOptional ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeUnitOfMeasureQtyDecimalOptional(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeUnitOfMeasureQtyDecimalOptional(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroUnitOfMeasureQtyDecimalOptional ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Unit Of Measure Qty Decimal Optional at zero, then each field in turn at the values it is checked at *)
CheckedUnitOfMeasureQtyDecimalOptional ==
    { ZeroUnitOfMeasureQtyDecimalOptional }
        \cup { [ZeroUnitOfMeasureQtyDecimalOptional EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroUnitOfMeasureQtyDecimalOptional EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Strike Price Decimal Optional: 9 bytes                                  *)
(***************************************************************************)

StrikePriceDecimalOptional ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeStrikePriceDecimalOptional(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeStrikePriceDecimalOptional(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroStrikePriceDecimalOptional ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Strike Price Decimal Optional at zero, then each field in turn at the values it is checked at *)
CheckedStrikePriceDecimalOptional ==
    { ZeroStrikePriceDecimalOptional }
        \cup { [ZeroStrikePriceDecimalOptional EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroStrikePriceDecimalOptional EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear4 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear4(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear4(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear4 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear4 ==
    { ZeroUnderlyingMaturityMonthYear4 }
        \cup { [ZeroUnderlyingMaturityMonthYear4 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear4 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear4 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear4 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Blocks Underlyings Group: 68 bytes                                *)
(***************************************************************************)

TradeBlocksUnderlyingsGroup3 ==
    [ underlyingSymbol                  : Sample(50),
      underlyingMaturityMonthYear       : UnderlyingMaturityMonthYear4,
      underlyingSecurityType            : Sample(9),
      underlyingSecurityExchangeString4 : Sample(4) ]

EncodeTradeBlocksUnderlyingsGroup3(message) ==
    message.underlyingSymbol
        \o EncodeUnderlyingMaturityMonthYear4(message.underlyingMaturityMonthYear)
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchangeString4

DecodeTradeBlocksUnderlyingsGroup3(bytes) ==
    LET underlyingSymbol == ReadBytes(bytes, 50) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear4(underlyingSymbol.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingMaturityMonthYear.rest, 9) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchangeString4 == ReadBytes(underlyingSecurityType.rest, 4) IN IF ~underlyingSecurityExchangeString4.ok THEN Fail ELSE
    Ok([ underlyingSymbol                  |-> underlyingSymbol.value,
         underlyingMaturityMonthYear       |-> underlyingMaturityMonthYear.value,
         underlyingSecurityType            |-> underlyingSecurityType.value,
         underlyingSecurityExchangeString4 |-> underlyingSecurityExchangeString4.value ], underlyingSecurityExchangeString4.rest)

ZeroTradeBlocksUnderlyingsGroup3 ==
    [ underlyingSymbol                  |-> [i \in 1 .. 50 |-> 0],
      underlyingMaturityMonthYear       |-> ZeroUnderlyingMaturityMonthYear4,
      underlyingSecurityType            |-> [i \in 1 .. 9 |-> 0],
      underlyingSecurityExchangeString4 |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Blocks Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksUnderlyingsGroup3 ==
    { ZeroTradeBlocksUnderlyingsGroup3 }
        \cup { [ZeroTradeBlocksUnderlyingsGroup3 EXCEPT !.underlyingSymbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksUnderlyingsGroup3 EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear4 }
        \cup { [ZeroTradeBlocksUnderlyingsGroup3 EXCEPT !.underlyingSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksUnderlyingsGroup3 EXCEPT !.underlyingSecurityExchangeString4 = one] : one \in Sample(4) }

(* A run of Trade Blocks Underlyings Group, written one after another *)
RECURSIVE EncodeTradeBlocksUnderlyingsGroup3List(_)
EncodeTradeBlocksUnderlyingsGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksUnderlyingsGroup3(Head(messages)) \o EncodeTradeBlocksUnderlyingsGroup3List(Tail(messages))

(* As many Trade Blocks Underlyings Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksUnderlyingsGroup3List(_, _)
ReadTradeBlocksUnderlyingsGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksUnderlyingsGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksUnderlyingsGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Underlyings Group of each kind, for the lists that carry them *)
OneTradeBlocksUnderlyingsGroup3 == { ZeroTradeBlocksUnderlyingsGroup3 }

(***************************************************************************)
(* Trade Blocks Underlyings Groups                                         *)
(***************************************************************************)

TradeBlocksUnderlyingsGroups3 ==
    [ blockLength                 : Sample(2),
      tradeBlocksUnderlyingsGroup : SampleLists(OneTradeBlocksUnderlyingsGroup3) ]

EncodeTradeBlocksUnderlyingsGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksUnderlyingsGroup), 1)
        \o EncodeTradeBlocksUnderlyingsGroup3List(message.tradeBlocksUnderlyingsGroup)

DecodeTradeBlocksUnderlyingsGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksUnderlyingsGroup == ReadTradeBlocksUnderlyingsGroup3List(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         tradeBlocksUnderlyingsGroup |-> tradeBlocksUnderlyingsGroup.value ], tradeBlocksUnderlyingsGroup.rest)

ZeroTradeBlocksUnderlyingsGroups3 ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksUnderlyingsGroup |-> << >> ]

(* Trade Blocks Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksUnderlyingsGroups3 ==
    { ZeroTradeBlocksUnderlyingsGroups3 }
        \cup { [ZeroTradeBlocksUnderlyingsGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksUnderlyingsGroups3 EXCEPT !.tradeBlocksUnderlyingsGroup = one] : one \in SampleLists(OneTradeBlocksUnderlyingsGroup3) }

(***************************************************************************)
(* Trade Blocks Party Ids Group: 52 bytes                                  *)
(***************************************************************************)

TradeBlocksPartyIdsGroup3 ==
    [ partyId   : Sample(50),
      partyRole : Sample(2) ]

EncodeTradeBlocksPartyIdsGroup3(message) ==
    message.partyId
        \o message.partyRole

DecodeTradeBlocksPartyIdsGroup3(bytes) ==
    LET partyId == ReadBytes(bytes, 50) IN IF ~partyId.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyId.rest, 2) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId   |-> partyId.value,
         partyRole |-> partyRole.value ], partyRole.rest)

ZeroTradeBlocksPartyIdsGroup3 ==
    [ partyId   |-> [i \in 1 .. 50 |-> 0],
      partyRole |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Blocks Party Ids Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksPartyIdsGroup3 ==
    { ZeroTradeBlocksPartyIdsGroup3 }
        \cup { [ZeroTradeBlocksPartyIdsGroup3 EXCEPT !.partyId = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksPartyIdsGroup3 EXCEPT !.partyRole = one] : one \in Sample(2) }

(* A run of Trade Blocks Party Ids Group, written one after another *)
RECURSIVE EncodeTradeBlocksPartyIdsGroup3List(_)
EncodeTradeBlocksPartyIdsGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksPartyIdsGroup3(Head(messages)) \o EncodeTradeBlocksPartyIdsGroup3List(Tail(messages))

(* As many Trade Blocks Party Ids Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksPartyIdsGroup3List(_, _)
ReadTradeBlocksPartyIdsGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksPartyIdsGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksPartyIdsGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Party Ids Group of each kind, for the lists that carry them *)
OneTradeBlocksPartyIdsGroup3 == { ZeroTradeBlocksPartyIdsGroup3 }

(***************************************************************************)
(* Trade Blocks Party Ids Groups                                           *)
(***************************************************************************)

TradeBlocksPartyIdsGroups3 ==
    [ blockLength              : Sample(2),
      tradeBlocksPartyIdsGroup : SampleLists(OneTradeBlocksPartyIdsGroup3) ]

EncodeTradeBlocksPartyIdsGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksPartyIdsGroup), 1)
        \o EncodeTradeBlocksPartyIdsGroup3List(message.tradeBlocksPartyIdsGroup)

DecodeTradeBlocksPartyIdsGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksPartyIdsGroup == ReadTradeBlocksPartyIdsGroup3List(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksPartyIdsGroup.ok THEN Fail ELSE
    Ok([ blockLength              |-> blockLength.value,
         tradeBlocksPartyIdsGroup |-> tradeBlocksPartyIdsGroup.value ], tradeBlocksPartyIdsGroup.rest)

ZeroTradeBlocksPartyIdsGroups3 ==
    [ blockLength              |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksPartyIdsGroup |-> << >> ]

(* Trade Blocks Party Ids Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksPartyIdsGroups3 ==
    { ZeroTradeBlocksPartyIdsGroups3 }
        \cup { [ZeroTradeBlocksPartyIdsGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksPartyIdsGroups3 EXCEPT !.tradeBlocksPartyIdsGroup = one] : one \in SampleLists(OneTradeBlocksPartyIdsGroup3) }

(***************************************************************************)
(* Leg Maturity Month Year: 5 bytes                                        *)
(***************************************************************************)

LegMaturityMonthYear3 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeLegMaturityMonthYear3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeLegMaturityMonthYear3(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroLegMaturityMonthYear3 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedLegMaturityMonthYear3 ==
    { ZeroLegMaturityMonthYear3 }
        \cup { [ZeroLegMaturityMonthYear3 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLegMaturityMonthYear3 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroLegMaturityMonthYear3 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroLegMaturityMonthYear3 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Strike Price Decimal 64 Null: 9 bytes                               *)
(***************************************************************************)

LegStrikePriceDecimal64Null ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeLegStrikePriceDecimal64Null(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeLegStrikePriceDecimal64Null(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroLegStrikePriceDecimal64Null ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Strike Price Decimal 64 Null at zero, then each field in turn at the values it is checked at *)
CheckedLegStrikePriceDecimal64Null ==
    { ZeroLegStrikePriceDecimal64Null }
        \cup { [ZeroLegStrikePriceDecimal64Null EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroLegStrikePriceDecimal64Null EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Leg Unit Of Measure Qty Decimal 64 Null: 9 bytes                        *)
(***************************************************************************)

LegUnitOfMeasureQtyDecimal64Null ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeLegUnitOfMeasureQtyDecimal64Null(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeLegUnitOfMeasureQtyDecimal64Null(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroLegUnitOfMeasureQtyDecimal64Null ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Unit Of Measure Qty Decimal 64 Null at zero, then each field in turn at the values it is checked at *)
CheckedLegUnitOfMeasureQtyDecimal64Null ==
    { ZeroLegUnitOfMeasureQtyDecimal64Null }
        \cup { [ZeroLegUnitOfMeasureQtyDecimal64Null EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroLegUnitOfMeasureQtyDecimal64Null EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Blocks Legs Group: 137 bytes                                      *)
(***************************************************************************)

TradeBlocksLegsGroup ==
    [ legSymbol                        : Sample(50),
      legSecurityId                    : Sample(8),
      legSecurityGroup                 : Sample(12),
      legId                            : Sample(17),
      legSecurityType                  : Sample(9),
      legMaturityMonthYear             : LegMaturityMonthYear3,
      legMaturityDate                  : Sample(2),
      legStrikePriceDecimal64Null      : LegStrikePriceDecimal64Null,
      legUnitOfMeasure                 : Sample(5),
      legUnitOfMeasureQtyDecimal64Null : LegUnitOfMeasureQtyDecimal64Null,
      legSecurityExchange              : Sample(4),
      legRatioQtyUInt16Null            : Sample(2),
      legSide                          : Sample(1),
      legPutOrCall                     : Sample(1),
      legUnitOfMeasureCurrency         : Sample(3) ]

EncodeTradeBlocksLegsGroup(message) ==
    message.legSymbol
        \o message.legSecurityId
        \o message.legSecurityGroup
        \o message.legId
        \o message.legSecurityType
        \o EncodeLegMaturityMonthYear3(message.legMaturityMonthYear)
        \o message.legMaturityDate
        \o EncodeLegStrikePriceDecimal64Null(message.legStrikePriceDecimal64Null)
        \o message.legUnitOfMeasure
        \o EncodeLegUnitOfMeasureQtyDecimal64Null(message.legUnitOfMeasureQtyDecimal64Null)
        \o message.legSecurityExchange
        \o message.legRatioQtyUInt16Null
        \o message.legSide
        \o message.legPutOrCall
        \o message.legUnitOfMeasureCurrency

DecodeTradeBlocksLegsGroup(bytes) ==
    LET legSymbol == ReadBytes(bytes, 50) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legSymbol.rest, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legSecurityGroup == ReadBytes(legSecurityId.rest, 12) IN IF ~legSecurityGroup.ok THEN Fail ELSE
    LET legId == ReadBytes(legSecurityGroup.rest, 17) IN IF ~legId.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legId.rest, 9) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legMaturityMonthYear == DecodeLegMaturityMonthYear3(legSecurityType.rest) IN IF ~legMaturityMonthYear.ok THEN Fail ELSE
    LET legMaturityDate == ReadBytes(legMaturityMonthYear.rest, 2) IN IF ~legMaturityDate.ok THEN Fail ELSE
    LET legStrikePriceDecimal64Null == DecodeLegStrikePriceDecimal64Null(legMaturityDate.rest) IN IF ~legStrikePriceDecimal64Null.ok THEN Fail ELSE
    LET legUnitOfMeasure == ReadBytes(legStrikePriceDecimal64Null.rest, 5) IN IF ~legUnitOfMeasure.ok THEN Fail ELSE
    LET legUnitOfMeasureQtyDecimal64Null == DecodeLegUnitOfMeasureQtyDecimal64Null(legUnitOfMeasure.rest) IN IF ~legUnitOfMeasureQtyDecimal64Null.ok THEN Fail ELSE
    LET legSecurityExchange == ReadBytes(legUnitOfMeasureQtyDecimal64Null.rest, 4) IN IF ~legSecurityExchange.ok THEN Fail ELSE
    LET legRatioQtyUInt16Null == ReadBytes(legSecurityExchange.rest, 2) IN IF ~legRatioQtyUInt16Null.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQtyUInt16Null.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legPutOrCall == ReadBytes(legSide.rest, 1) IN IF ~legPutOrCall.ok THEN Fail ELSE
    LET legUnitOfMeasureCurrency == ReadBytes(legPutOrCall.rest, 3) IN IF ~legUnitOfMeasureCurrency.ok THEN Fail ELSE
    Ok([ legSymbol                        |-> legSymbol.value,
         legSecurityId                    |-> legSecurityId.value,
         legSecurityGroup                 |-> legSecurityGroup.value,
         legId                            |-> legId.value,
         legSecurityType                  |-> legSecurityType.value,
         legMaturityMonthYear             |-> legMaturityMonthYear.value,
         legMaturityDate                  |-> legMaturityDate.value,
         legStrikePriceDecimal64Null      |-> legStrikePriceDecimal64Null.value,
         legUnitOfMeasure                 |-> legUnitOfMeasure.value,
         legUnitOfMeasureQtyDecimal64Null |-> legUnitOfMeasureQtyDecimal64Null.value,
         legSecurityExchange              |-> legSecurityExchange.value,
         legRatioQtyUInt16Null            |-> legRatioQtyUInt16Null.value,
         legSide                          |-> legSide.value,
         legPutOrCall                     |-> legPutOrCall.value,
         legUnitOfMeasureCurrency         |-> legUnitOfMeasureCurrency.value ], legUnitOfMeasureCurrency.rest)

ZeroTradeBlocksLegsGroup ==
    [ legSymbol                        |-> [i \in 1 .. 50 |-> 0],
      legSecurityId                    |-> [i \in 1 .. 8 |-> 0],
      legSecurityGroup                 |-> [i \in 1 .. 12 |-> 0],
      legId                            |-> [i \in 1 .. 17 |-> 0],
      legSecurityType                  |-> [i \in 1 .. 9 |-> 0],
      legMaturityMonthYear             |-> ZeroLegMaturityMonthYear3,
      legMaturityDate                  |-> [i \in 1 .. 2 |-> 0],
      legStrikePriceDecimal64Null      |-> ZeroLegStrikePriceDecimal64Null,
      legUnitOfMeasure                 |-> [i \in 1 .. 5 |-> 0],
      legUnitOfMeasureQtyDecimal64Null |-> ZeroLegUnitOfMeasureQtyDecimal64Null,
      legSecurityExchange              |-> [i \in 1 .. 4 |-> 0],
      legRatioQtyUInt16Null            |-> [i \in 1 .. 2 |-> 0],
      legSide                          |-> [i \in 1 .. 1 |-> 0],
      legPutOrCall                     |-> [i \in 1 .. 1 |-> 0],
      legUnitOfMeasureCurrency         |-> [i \in 1 .. 3 |-> 0] ]

(* Trade Blocks Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksLegsGroup ==
    { ZeroTradeBlocksLegsGroup }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legSecurityGroup = one] : one \in Sample(12) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legId = one] : one \in Sample(17) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legMaturityMonthYear = one] : one \in CheckedLegMaturityMonthYear3 }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legMaturityDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legStrikePriceDecimal64Null = one] : one \in CheckedLegStrikePriceDecimal64Null }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legUnitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legUnitOfMeasureQtyDecimal64Null = one] : one \in CheckedLegUnitOfMeasureQtyDecimal64Null }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legSecurityExchange = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legRatioQtyUInt16Null = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legPutOrCall = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksLegsGroup EXCEPT !.legUnitOfMeasureCurrency = one] : one \in Sample(3) }

(* A run of Trade Blocks Legs Group, written one after another *)
RECURSIVE EncodeTradeBlocksLegsGroupList(_)
EncodeTradeBlocksLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksLegsGroup(Head(messages)) \o EncodeTradeBlocksLegsGroupList(Tail(messages))

(* As many Trade Blocks Legs Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksLegsGroupList(_, _)
ReadTradeBlocksLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Legs Group of each kind, for the lists that carry them *)
OneTradeBlocksLegsGroup == { ZeroTradeBlocksLegsGroup }

(***************************************************************************)
(* Trade Blocks Legs Groups                                                *)
(***************************************************************************)

TradeBlocksLegsGroups ==
    [ blockLength          : Sample(2),
      tradeBlocksLegsGroup : SampleLists(OneTradeBlocksLegsGroup) ]

EncodeTradeBlocksLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksLegsGroup), 1)
        \o EncodeTradeBlocksLegsGroupList(message.tradeBlocksLegsGroup)

DecodeTradeBlocksLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksLegsGroup == ReadTradeBlocksLegsGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength          |-> blockLength.value,
         tradeBlocksLegsGroup |-> tradeBlocksLegsGroup.value ], tradeBlocksLegsGroup.rest)

ZeroTradeBlocksLegsGroups ==
    [ blockLength          |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksLegsGroup |-> << >> ]

(* Trade Blocks Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksLegsGroups ==
    { ZeroTradeBlocksLegsGroups }
        \cup { [ZeroTradeBlocksLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksLegsGroups EXCEPT !.tradeBlocksLegsGroup = one] : one \in SampleLists(OneTradeBlocksLegsGroup) }

(***************************************************************************)
(* Trade Blocks Group                                                      *)
(***************************************************************************)

TradeBlocksGroup ==
    [ mdUpdateAction                  : Sample(1),
      securityId                      : Sample(8),
      rptSeq                          : Sample(4),
      mdEntryPx                       : Sample(8),
      mdEntrySize                     : MdEntrySize3,
      numberOfOrders                  : Sample(4),
      tradeId                         : Sample(4),
      aggressorSide                   : Sample(1),
      symbol                          : Sample(50),
      securityGroup12                 : Sample(12),
      securityType                    : Sample(9),
      securitySubType                 : Sample(2),
      maturityMonthYear               : MaturityMonthYear4,
      securityExchange4               : Sample(4),
      maturityDate                    : Sample(2),
      unitOfMeasure                   : Sample(5),
      unitOfMeasureCurrency3          : Sample(3),
      unitOfMeasureQtyDecimalOptional : UnitOfMeasureQtyDecimalOptional,
      couponRate                      : Sample(4),
      priceType                       : Sample(2),
      trdType                         : Sample(1),
      mdEntryId                       : Sample(26),
      putOrCall                       : Sample(1),
      strikePriceDecimalOptional      : StrikePriceDecimalOptional,
      restructuringType               : Sample(2),
      seniority                       : Sample(2),
      referenceId100                  : Sample(100),
      strategyLinkId                  : Sample(26),
      legRefId                        : Sample(17),
      tradeBlocksUnderlyingsGroups    : TradeBlocksUnderlyingsGroups3,
      tradeBlocksPartyIdsGroups       : TradeBlocksPartyIdsGroups3,
      tradeBlocksLegsGroups           : TradeBlocksLegsGroups ]

EncodeTradeBlocksGroup(message) ==
    message.mdUpdateAction
        \o message.securityId
        \o message.rptSeq
        \o message.mdEntryPx
        \o EncodeMdEntrySize3(message.mdEntrySize)
        \o message.numberOfOrders
        \o message.tradeId
        \o message.aggressorSide
        \o message.symbol
        \o message.securityGroup12
        \o message.securityType
        \o message.securitySubType
        \o EncodeMaturityMonthYear4(message.maturityMonthYear)
        \o message.securityExchange4
        \o message.maturityDate
        \o message.unitOfMeasure
        \o message.unitOfMeasureCurrency3
        \o EncodeUnitOfMeasureQtyDecimalOptional(message.unitOfMeasureQtyDecimalOptional)
        \o message.couponRate
        \o message.priceType
        \o message.trdType
        \o message.mdEntryId
        \o message.putOrCall
        \o EncodeStrikePriceDecimalOptional(message.strikePriceDecimalOptional)
        \o message.restructuringType
        \o message.seniority
        \o message.referenceId100
        \o message.strategyLinkId
        \o message.legRefId
        \o EncodeTradeBlocksUnderlyingsGroups3(message.tradeBlocksUnderlyingsGroups)
        \o EncodeTradeBlocksPartyIdsGroups3(message.tradeBlocksPartyIdsGroups)
        \o EncodeTradeBlocksLegsGroups(message.tradeBlocksLegsGroups)

DecodeTradeBlocksGroup(bytes) ==
    LET mdUpdateAction == ReadBytes(bytes, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdUpdateAction.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(rptSeq.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == DecodeMdEntrySize3(mdEntryPx.rest) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(mdEntrySize.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET tradeId == ReadBytes(numberOfOrders.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(tradeId.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET symbol == ReadBytes(aggressorSide.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup12 == ReadBytes(symbol.rest, 12) IN IF ~securityGroup12.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup12.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(securityType.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear4(securitySubType.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET securityExchange4 == ReadBytes(maturityMonthYear.rest, 4) IN IF ~securityExchange4.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityExchange4.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(maturityDate.rest, 5) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureCurrency3 == ReadBytes(unitOfMeasure.rest, 3) IN IF ~unitOfMeasureCurrency3.ok THEN Fail ELSE
    LET unitOfMeasureQtyDecimalOptional == DecodeUnitOfMeasureQtyDecimalOptional(unitOfMeasureCurrency3.rest) IN IF ~unitOfMeasureQtyDecimalOptional.ok THEN Fail ELSE
    LET couponRate == ReadBytes(unitOfMeasureQtyDecimalOptional.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET priceType == ReadBytes(couponRate.rest, 2) IN IF ~priceType.ok THEN Fail ELSE
    LET trdType == ReadBytes(priceType.rest, 1) IN IF ~trdType.ok THEN Fail ELSE
    LET mdEntryId == ReadBytes(trdType.rest, 26) IN IF ~mdEntryId.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(mdEntryId.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePriceDecimalOptional == DecodeStrikePriceDecimalOptional(putOrCall.rest) IN IF ~strikePriceDecimalOptional.ok THEN Fail ELSE
    LET restructuringType == ReadBytes(strikePriceDecimalOptional.rest, 2) IN IF ~restructuringType.ok THEN Fail ELSE
    LET seniority == ReadBytes(restructuringType.rest, 2) IN IF ~seniority.ok THEN Fail ELSE
    LET referenceId100 == ReadBytes(seniority.rest, 100) IN IF ~referenceId100.ok THEN Fail ELSE
    LET strategyLinkId == ReadBytes(referenceId100.rest, 26) IN IF ~strategyLinkId.ok THEN Fail ELSE
    LET legRefId == ReadBytes(strategyLinkId.rest, 17) IN IF ~legRefId.ok THEN Fail ELSE
    LET tradeBlocksUnderlyingsGroups == DecodeTradeBlocksUnderlyingsGroups3(legRefId.rest) IN IF ~tradeBlocksUnderlyingsGroups.ok THEN Fail ELSE
    LET tradeBlocksPartyIdsGroups == DecodeTradeBlocksPartyIdsGroups3(tradeBlocksUnderlyingsGroups.rest) IN IF ~tradeBlocksPartyIdsGroups.ok THEN Fail ELSE
    LET tradeBlocksLegsGroups == DecodeTradeBlocksLegsGroups(tradeBlocksPartyIdsGroups.rest) IN IF ~tradeBlocksLegsGroups.ok THEN Fail ELSE
    Ok([ mdUpdateAction                  |-> mdUpdateAction.value,
         securityId                      |-> securityId.value,
         rptSeq                          |-> rptSeq.value,
         mdEntryPx                       |-> mdEntryPx.value,
         mdEntrySize                     |-> mdEntrySize.value,
         numberOfOrders                  |-> numberOfOrders.value,
         tradeId                         |-> tradeId.value,
         aggressorSide                   |-> aggressorSide.value,
         symbol                          |-> symbol.value,
         securityGroup12                 |-> securityGroup12.value,
         securityType                    |-> securityType.value,
         securitySubType                 |-> securitySubType.value,
         maturityMonthYear               |-> maturityMonthYear.value,
         securityExchange4               |-> securityExchange4.value,
         maturityDate                    |-> maturityDate.value,
         unitOfMeasure                   |-> unitOfMeasure.value,
         unitOfMeasureCurrency3          |-> unitOfMeasureCurrency3.value,
         unitOfMeasureQtyDecimalOptional |-> unitOfMeasureQtyDecimalOptional.value,
         couponRate                      |-> couponRate.value,
         priceType                       |-> priceType.value,
         trdType                         |-> trdType.value,
         mdEntryId                       |-> mdEntryId.value,
         putOrCall                       |-> putOrCall.value,
         strikePriceDecimalOptional      |-> strikePriceDecimalOptional.value,
         restructuringType               |-> restructuringType.value,
         seniority                       |-> seniority.value,
         referenceId100                  |-> referenceId100.value,
         strategyLinkId                  |-> strategyLinkId.value,
         legRefId                        |-> legRefId.value,
         tradeBlocksUnderlyingsGroups    |-> tradeBlocksUnderlyingsGroups.value,
         tradeBlocksPartyIdsGroups       |-> tradeBlocksPartyIdsGroups.value,
         tradeBlocksLegsGroups           |-> tradeBlocksLegsGroups.value ], tradeBlocksLegsGroups.rest)

ZeroTradeBlocksGroup ==
    [ mdUpdateAction                  |-> [i \in 1 .. 1 |-> 0],
      securityId                      |-> [i \in 1 .. 8 |-> 0],
      rptSeq                          |-> [i \in 1 .. 4 |-> 0],
      mdEntryPx                       |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                     |-> ZeroMdEntrySize3,
      numberOfOrders                  |-> [i \in 1 .. 4 |-> 0],
      tradeId                         |-> [i \in 1 .. 4 |-> 0],
      aggressorSide                   |-> [i \in 1 .. 1 |-> 0],
      symbol                          |-> [i \in 1 .. 50 |-> 0],
      securityGroup12                 |-> [i \in 1 .. 12 |-> 0],
      securityType                    |-> [i \in 1 .. 9 |-> 0],
      securitySubType                 |-> [i \in 1 .. 2 |-> 0],
      maturityMonthYear               |-> ZeroMaturityMonthYear4,
      securityExchange4               |-> [i \in 1 .. 4 |-> 0],
      maturityDate                    |-> [i \in 1 .. 2 |-> 0],
      unitOfMeasure                   |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureCurrency3          |-> [i \in 1 .. 3 |-> 0],
      unitOfMeasureQtyDecimalOptional |-> ZeroUnitOfMeasureQtyDecimalOptional,
      couponRate                      |-> [i \in 1 .. 4 |-> 0],
      priceType                       |-> [i \in 1 .. 2 |-> 0],
      trdType                         |-> [i \in 1 .. 1 |-> 0],
      mdEntryId                       |-> [i \in 1 .. 26 |-> 0],
      putOrCall                       |-> [i \in 1 .. 1 |-> 0],
      strikePriceDecimalOptional      |-> ZeroStrikePriceDecimalOptional,
      restructuringType               |-> [i \in 1 .. 2 |-> 0],
      seniority                       |-> [i \in 1 .. 2 |-> 0],
      referenceId100                  |-> [i \in 1 .. 100 |-> 0],
      strategyLinkId                  |-> [i \in 1 .. 26 |-> 0],
      legRefId                        |-> [i \in 1 .. 17 |-> 0],
      tradeBlocksUnderlyingsGroups    |-> ZeroTradeBlocksUnderlyingsGroups3,
      tradeBlocksPartyIdsGroups       |-> ZeroTradeBlocksPartyIdsGroups3,
      tradeBlocksLegsGroups           |-> ZeroTradeBlocksLegsGroups ]

(* Trade Blocks Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksGroup ==
    { ZeroTradeBlocksGroup }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.mdEntrySize = one] : one \in CheckedMdEntrySize3 }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.securityGroup12 = one] : one \in Sample(12) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear4 }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.securityExchange4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.unitOfMeasureCurrency3 = one] : one \in Sample(3) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.unitOfMeasureQtyDecimalOptional = one] : one \in CheckedUnitOfMeasureQtyDecimalOptional }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.priceType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.trdType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.mdEntryId = one] : one \in Sample(26) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.strikePriceDecimalOptional = one] : one \in CheckedStrikePriceDecimalOptional }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.restructuringType = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.seniority = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.referenceId100 = one] : one \in Sample(100) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.strategyLinkId = one] : one \in Sample(26) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.legRefId = one] : one \in Sample(17) }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.tradeBlocksUnderlyingsGroups = one] : one \in CheckedTradeBlocksUnderlyingsGroups3 }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.tradeBlocksPartyIdsGroups = one] : one \in CheckedTradeBlocksPartyIdsGroups3 }
        \cup { [ZeroTradeBlocksGroup EXCEPT !.tradeBlocksLegsGroups = one] : one \in CheckedTradeBlocksLegsGroups }

(* A run of Trade Blocks Group, written one after another *)
RECURSIVE EncodeTradeBlocksGroupList(_)
EncodeTradeBlocksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBlocksGroup(Head(messages)) \o EncodeTradeBlocksGroupList(Tail(messages))

(* As many Trade Blocks Group as the field that counts them says *)
RECURSIVE ReadTradeBlocksGroupList(_, _)
ReadTradeBlocksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBlocksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBlocksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Blocks Group of each kind, for the lists that carry them *)
OneTradeBlocksGroup == { ZeroTradeBlocksGroup }

(***************************************************************************)
(* Trade Blocks Groups                                                     *)
(***************************************************************************)

TradeBlocksGroups ==
    [ blockLength      : Sample(2),
      tradeBlocksGroup : SampleLists(OneTradeBlocksGroup) ]

EncodeTradeBlocksGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBlocksGroup), 1)
        \o EncodeTradeBlocksGroupList(message.tradeBlocksGroup)

DecodeTradeBlocksGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET tradeBlocksGroup == ReadTradeBlocksGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~tradeBlocksGroup.ok THEN Fail ELSE
    Ok([ blockLength      |-> blockLength.value,
         tradeBlocksGroup |-> tradeBlocksGroup.value ], tradeBlocksGroup.rest)

ZeroTradeBlocksGroups ==
    [ blockLength      |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksGroup |-> << >> ]

(* Trade Blocks Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBlocksGroups ==
    { ZeroTradeBlocksGroups }
        \cup { [ZeroTradeBlocksGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBlocksGroups EXCEPT !.tradeBlocksGroup = one] : one \in SampleLists(OneTradeBlocksGroup) }

(***************************************************************************)
(* Md Incremental Refresh Trade Blocks 365                                 *)
(***************************************************************************)

MdIncrementalRefreshTradeBlocks365 ==
    [ transactTimeOptional : Sample(8),
      matchEventIndicator  : Sample(1),
      batchTotalMessages   : Sample(2),
      tradeDate            : Sample(2),
      tradeBlocksGroups    : TradeBlocksGroups ]

EncodeMdIncrementalRefreshTradeBlocks365(message) ==
    message.transactTimeOptional
        \o message.matchEventIndicator
        \o message.batchTotalMessages
        \o message.tradeDate
        \o EncodeTradeBlocksGroups(message.tradeBlocksGroups)

DecodeMdIncrementalRefreshTradeBlocks365(bytes) ==
    LET transactTimeOptional == ReadBytes(bytes, 8) IN IF ~transactTimeOptional.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTimeOptional.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessages == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessages.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(batchTotalMessages.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeBlocksGroups == DecodeTradeBlocksGroups(tradeDate.rest) IN IF ~tradeBlocksGroups.ok THEN Fail ELSE
    Ok([ transactTimeOptional |-> transactTimeOptional.value,
         matchEventIndicator  |-> matchEventIndicator.value,
         batchTotalMessages   |-> batchTotalMessages.value,
         tradeDate            |-> tradeDate.value,
         tradeBlocksGroups    |-> tradeBlocksGroups.value ], tradeBlocksGroups.rest)

ZeroMdIncrementalRefreshTradeBlocks365 ==
    [ transactTimeOptional |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator  |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessages   |-> [i \in 1 .. 2 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      tradeBlocksGroups    |-> ZeroTradeBlocksGroups ]

(* Md Incremental Refresh Trade Blocks 365 at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshTradeBlocks365 ==
    { ZeroMdIncrementalRefreshTradeBlocks365 }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks365 EXCEPT !.transactTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks365 EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks365 EXCEPT !.batchTotalMessages = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks365 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshTradeBlocks365 EXCEPT !.tradeBlocksGroups = one] : one \in CheckedTradeBlocksGroups }

(***************************************************************************)
(* Md Entry Size: 9 bytes                                                  *)
(***************************************************************************)

MdEntrySize4 ==
    [ mantissa : Sample(8),
      exponent : Sample(1) ]

EncodeMdEntrySize4(message) ==
    message.mantissa
        \o message.exponent

DecodeMdEntrySize4(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa |-> mantissa.value,
         exponent |-> exponent.value ], exponent.rest)

ZeroMdEntrySize4 ==
    [ mantissa |-> [i \in 1 .. 8 |-> 0],
      exponent |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry Size at zero, then each field in turn at the values it is checked at *)
CheckedMdEntrySize4 ==
    { ZeroMdEntrySize4 }
        \cup { [ZeroMdEntrySize4 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroMdEntrySize4 EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear5 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear5(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear5(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear5 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear5 ==
    { ZeroMaturityMonthYear5 }
        \cup { [ZeroMaturityMonthYear5 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear5 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear5 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear5 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Strike Price Decimal Optional: 9 bytes                                  *)
(***************************************************************************)

StrikePriceDecimalOptional2 ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeStrikePriceDecimalOptional2(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeStrikePriceDecimalOptional2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroStrikePriceDecimalOptional2 ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Strike Price Decimal Optional at zero, then each field in turn at the values it is checked at *)
CheckedStrikePriceDecimalOptional2 ==
    { ZeroStrikePriceDecimalOptional2 }
        \cup { [ZeroStrikePriceDecimalOptional2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroStrikePriceDecimalOptional2 EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Unit Of Measure Qty Decimal Optional: 9 bytes                           *)
(***************************************************************************)

UnitOfMeasureQtyDecimalOptional2 ==
    [ mantissa         : Sample(8),
      exponentOptional : Sample(1) ]

EncodeUnitOfMeasureQtyDecimalOptional2(message) ==
    message.mantissa
        \o message.exponentOptional

DecodeUnitOfMeasureQtyDecimalOptional2(bytes) ==
    LET mantissa == ReadBytes(bytes, 8) IN IF ~mantissa.ok THEN Fail ELSE
    LET exponentOptional == ReadBytes(mantissa.rest, 1) IN IF ~exponentOptional.ok THEN Fail ELSE
    Ok([ mantissa         |-> mantissa.value,
         exponentOptional |-> exponentOptional.value ], exponentOptional.rest)

ZeroUnitOfMeasureQtyDecimalOptional2 ==
    [ mantissa         |-> [i \in 1 .. 8 |-> 0],
      exponentOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Unit Of Measure Qty Decimal Optional at zero, then each field in turn at the values it is checked at *)
CheckedUnitOfMeasureQtyDecimalOptional2 ==
    { ZeroUnitOfMeasureQtyDecimalOptional2 }
        \cup { [ZeroUnitOfMeasureQtyDecimalOptional2 EXCEPT !.mantissa = one] : one \in Sample(8) }
        \cup { [ZeroUnitOfMeasureQtyDecimalOptional2 EXCEPT !.exponentOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Maturity Month Year: 5 bytes                                 *)
(***************************************************************************)

UnderlyingMaturityMonthYear5 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeUnderlyingMaturityMonthYear5(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeUnderlyingMaturityMonthYear5(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroUnderlyingMaturityMonthYear5 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingMaturityMonthYear5 ==
    { ZeroUnderlyingMaturityMonthYear5 }
        \cup { [ZeroUnderlyingMaturityMonthYear5 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingMaturityMonthYear5 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear5 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingMaturityMonthYear5 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Otc Underlyings Group: 68 bytes                                         *)
(***************************************************************************)

OtcUnderlyingsGroup2 ==
    [ underlyingSymbol                           : Sample(50),
      underlyingMaturityMonthYear                : UnderlyingMaturityMonthYear5,
      underlyingSecurityType                     : Sample(9),
      underlyingSecurityExchangeSecurityExchange : Sample(4) ]

EncodeOtcUnderlyingsGroup2(message) ==
    message.underlyingSymbol
        \o EncodeUnderlyingMaturityMonthYear5(message.underlyingMaturityMonthYear)
        \o message.underlyingSecurityType
        \o message.underlyingSecurityExchangeSecurityExchange

DecodeOtcUnderlyingsGroup2(bytes) ==
    LET underlyingSymbol == ReadBytes(bytes, 50) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingMaturityMonthYear == DecodeUnderlyingMaturityMonthYear5(underlyingSymbol.rest) IN IF ~underlyingMaturityMonthYear.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingMaturityMonthYear.rest, 9) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingSecurityExchangeSecurityExchange == ReadBytes(underlyingSecurityType.rest, 4) IN IF ~underlyingSecurityExchangeSecurityExchange.ok THEN Fail ELSE
    Ok([ underlyingSymbol                           |-> underlyingSymbol.value,
         underlyingMaturityMonthYear                |-> underlyingMaturityMonthYear.value,
         underlyingSecurityType                     |-> underlyingSecurityType.value,
         underlyingSecurityExchangeSecurityExchange |-> underlyingSecurityExchangeSecurityExchange.value ], underlyingSecurityExchangeSecurityExchange.rest)

ZeroOtcUnderlyingsGroup2 ==
    [ underlyingSymbol                           |-> [i \in 1 .. 50 |-> 0],
      underlyingMaturityMonthYear                |-> ZeroUnderlyingMaturityMonthYear5,
      underlyingSecurityType                     |-> [i \in 1 .. 9 |-> 0],
      underlyingSecurityExchangeSecurityExchange |-> [i \in 1 .. 4 |-> 0] ]

(* Otc Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedOtcUnderlyingsGroup2 ==
    { ZeroOtcUnderlyingsGroup2 }
        \cup { [ZeroOtcUnderlyingsGroup2 EXCEPT !.underlyingSymbol = one] : one \in Sample(50) }
        \cup { [ZeroOtcUnderlyingsGroup2 EXCEPT !.underlyingMaturityMonthYear = one] : one \in CheckedUnderlyingMaturityMonthYear5 }
        \cup { [ZeroOtcUnderlyingsGroup2 EXCEPT !.underlyingSecurityType = one] : one \in Sample(9) }
        \cup { [ZeroOtcUnderlyingsGroup2 EXCEPT !.underlyingSecurityExchangeSecurityExchange = one] : one \in Sample(4) }

(* A run of Otc Underlyings Group, written one after another *)
RECURSIVE EncodeOtcUnderlyingsGroup2List(_)
EncodeOtcUnderlyingsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOtcUnderlyingsGroup2(Head(messages)) \o EncodeOtcUnderlyingsGroup2List(Tail(messages))

(* As many Otc Underlyings Group as the field that counts them says *)
RECURSIVE ReadOtcUnderlyingsGroup2List(_, _)
ReadOtcUnderlyingsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOtcUnderlyingsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOtcUnderlyingsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Otc Underlyings Group of each kind, for the lists that carry them *)
OneOtcUnderlyingsGroup2 == { ZeroOtcUnderlyingsGroup2 }

(***************************************************************************)
(* Otc Underlyings Groups                                                  *)
(***************************************************************************)

OtcUnderlyingsGroups2 ==
    [ blockLength         : Sample(2),
      otcUnderlyingsGroup : SampleLists(OneOtcUnderlyingsGroup2) ]

EncodeOtcUnderlyingsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.otcUnderlyingsGroup), 1)
        \o EncodeOtcUnderlyingsGroup2List(message.otcUnderlyingsGroup)

DecodeOtcUnderlyingsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET otcUnderlyingsGroup == ReadOtcUnderlyingsGroup2List(numInGroup8.rest, numInGroup8.value) IN IF ~otcUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength         |-> blockLength.value,
         otcUnderlyingsGroup |-> otcUnderlyingsGroup.value ], otcUnderlyingsGroup.rest)

ZeroOtcUnderlyingsGroups2 ==
    [ blockLength         |-> [i \in 1 .. 2 |-> 0],
      otcUnderlyingsGroup |-> << >> ]

(* Otc Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtcUnderlyingsGroups2 ==
    { ZeroOtcUnderlyingsGroups2 }
        \cup { [ZeroOtcUnderlyingsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOtcUnderlyingsGroups2 EXCEPT !.otcUnderlyingsGroup = one] : one \in SampleLists(OneOtcUnderlyingsGroup2) }

(***************************************************************************)
(* Otc Security Alt Id Group: 51 bytes                                     *)
(***************************************************************************)

OtcSecurityAltIdGroup2 ==
    [ securityAltIDStringLength50 : Sample(50),
      securityAltIdSource         : Sample(1) ]

EncodeOtcSecurityAltIdGroup2(message) ==
    message.securityAltIDStringLength50
        \o message.securityAltIdSource

DecodeOtcSecurityAltIdGroup2(bytes) ==
    LET securityAltIDStringLength50 == ReadBytes(bytes, 50) IN IF ~securityAltIDStringLength50.ok THEN Fail ELSE
    LET securityAltIdSource == ReadBytes(securityAltIDStringLength50.rest, 1) IN IF ~securityAltIdSource.ok THEN Fail ELSE
    Ok([ securityAltIDStringLength50 |-> securityAltIDStringLength50.value,
         securityAltIdSource         |-> securityAltIdSource.value ], securityAltIdSource.rest)

ZeroOtcSecurityAltIdGroup2 ==
    [ securityAltIDStringLength50 |-> [i \in 1 .. 50 |-> 0],
      securityAltIdSource         |-> [i \in 1 .. 1 |-> 0] ]

(* Otc Security Alt Id Group at zero, then each field in turn at the values it is checked at *)
CheckedOtcSecurityAltIdGroup2 ==
    { ZeroOtcSecurityAltIdGroup2 }
        \cup { [ZeroOtcSecurityAltIdGroup2 EXCEPT !.securityAltIDStringLength50 = one] : one \in Sample(50) }
        \cup { [ZeroOtcSecurityAltIdGroup2 EXCEPT !.securityAltIdSource = one] : one \in Sample(1) }

(* A run of Otc Security Alt Id Group, written one after another *)
RECURSIVE EncodeOtcSecurityAltIdGroup2List(_)
EncodeOtcSecurityAltIdGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOtcSecurityAltIdGroup2(Head(messages)) \o EncodeOtcSecurityAltIdGroup2List(Tail(messages))

(* As many Otc Security Alt Id Group as the field that counts them says *)
RECURSIVE ReadOtcSecurityAltIdGroup2List(_, _)
ReadOtcSecurityAltIdGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOtcSecurityAltIdGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOtcSecurityAltIdGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Otc Security Alt Id Group of each kind, for the lists that carry them *)
OneOtcSecurityAltIdGroup2 == { ZeroOtcSecurityAltIdGroup2 }

(***************************************************************************)
(* Otc Security Alt Id Groups                                              *)
(***************************************************************************)

OtcSecurityAltIdGroups2 ==
    [ blockLength           : Sample(2),
      otcSecurityAltIdGroup : SampleLists(OneOtcSecurityAltIdGroup2) ]

EncodeOtcSecurityAltIdGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.otcSecurityAltIdGroup), 1)
        \o EncodeOtcSecurityAltIdGroup2List(message.otcSecurityAltIdGroup)

DecodeOtcSecurityAltIdGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET otcSecurityAltIdGroup == ReadOtcSecurityAltIdGroup2List(numInGroup8.rest, numInGroup8.value) IN IF ~otcSecurityAltIdGroup.ok THEN Fail ELSE
    Ok([ blockLength           |-> blockLength.value,
         otcSecurityAltIdGroup |-> otcSecurityAltIdGroup.value ], otcSecurityAltIdGroup.rest)

ZeroOtcSecurityAltIdGroups2 ==
    [ blockLength           |-> [i \in 1 .. 2 |-> 0],
      otcSecurityAltIdGroup |-> << >> ]

(* Otc Security Alt Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtcSecurityAltIdGroups2 ==
    { ZeroOtcSecurityAltIdGroups2 }
        \cup { [ZeroOtcSecurityAltIdGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOtcSecurityAltIdGroups2 EXCEPT !.otcSecurityAltIdGroup = one] : one \in SampleLists(OneOtcSecurityAltIdGroup2) }

(***************************************************************************)
(* Otc Group                                                               *)
(***************************************************************************)

OtcGroup ==
    [ mdEntryType                     : Sample(1),
      rptSeq                          : Sample(4),
      mdEntryPx                       : Sample(8),
      mdEntrySize                     : MdEntrySize4,
      symbol                          : Sample(50),
      securityGroup12                 : Sample(12),
      securityType                    : Sample(9),
      maturityMonthYear               : MaturityMonthYear5,
      securityExchange                : Sample(4),
      productOptional                 : Sample(1),
      maturityDate                    : Sample(2),
      couponRate                      : Sample(4),
      restructuringType               : Sample(2),
      seniority                       : Sample(2),
      notionalPercentageOutstanding   : Sample(4),
      putOrCall                       : Sample(1),
      strikePriceDecimalOptional      : StrikePriceDecimalOptional2,
      unitOfMeasure                   : Sample(5),
      unitOfMeasureCurrency           : Sample(3),
      unitOfMeasureQtyDecimalOptional : UnitOfMeasureQtyDecimalOptional2,
      mdEntryDate                     : Sample(4),
      openCloseSettlFlag              : Sample(1),
      priceType                       : Sample(2),
      settlDate                       : Sample(2),
      quoteCondition                  : Sample(1),
      marketSector                    : Sample(26),
      sectorGroup                     : Sample(2),
      sectorSubGroup                  : Sample(26),
      productComplex                  : Sample(26),
      securitySubType                 : Sample(2),
      volType                         : Sample(2),
      referenceId100                  : Sample(100),
      otcUnderlyingsGroups            : OtcUnderlyingsGroups2,
      otcSecurityAltIdGroups          : OtcSecurityAltIdGroups2 ]

EncodeOtcGroup(message) ==
    message.mdEntryType
        \o message.rptSeq
        \o message.mdEntryPx
        \o EncodeMdEntrySize4(message.mdEntrySize)
        \o message.symbol
        \o message.securityGroup12
        \o message.securityType
        \o EncodeMaturityMonthYear5(message.maturityMonthYear)
        \o message.securityExchange
        \o message.productOptional
        \o message.maturityDate
        \o message.couponRate
        \o message.restructuringType
        \o message.seniority
        \o message.notionalPercentageOutstanding
        \o message.putOrCall
        \o EncodeStrikePriceDecimalOptional2(message.strikePriceDecimalOptional)
        \o message.unitOfMeasure
        \o message.unitOfMeasureCurrency
        \o EncodeUnitOfMeasureQtyDecimalOptional2(message.unitOfMeasureQtyDecimalOptional)
        \o message.mdEntryDate
        \o message.openCloseSettlFlag
        \o message.priceType
        \o message.settlDate
        \o message.quoteCondition
        \o message.marketSector
        \o message.sectorGroup
        \o message.sectorSubGroup
        \o message.productComplex
        \o message.securitySubType
        \o message.volType
        \o message.referenceId100
        \o EncodeOtcUnderlyingsGroups2(message.otcUnderlyingsGroups)
        \o EncodeOtcSecurityAltIdGroups2(message.otcSecurityAltIdGroups)

DecodeOtcGroup(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryType.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(rptSeq.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == DecodeMdEntrySize4(mdEntryPx.rest) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET symbol == ReadBytes(mdEntrySize.rest, 50) IN IF ~symbol.ok THEN Fail ELSE
    LET securityGroup12 == ReadBytes(symbol.rest, 12) IN IF ~securityGroup12.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityGroup12.rest, 9) IN IF ~securityType.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear5(securityType.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(maturityMonthYear.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET productOptional == ReadBytes(securityExchange.rest, 1) IN IF ~productOptional.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(productOptional.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET couponRate == ReadBytes(maturityDate.rest, 4) IN IF ~couponRate.ok THEN Fail ELSE
    LET restructuringType == ReadBytes(couponRate.rest, 2) IN IF ~restructuringType.ok THEN Fail ELSE
    LET seniority == ReadBytes(restructuringType.rest, 2) IN IF ~seniority.ok THEN Fail ELSE
    LET notionalPercentageOutstanding == ReadBytes(seniority.rest, 4) IN IF ~notionalPercentageOutstanding.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(notionalPercentageOutstanding.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePriceDecimalOptional == DecodeStrikePriceDecimalOptional2(putOrCall.rest) IN IF ~strikePriceDecimalOptional.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(strikePriceDecimalOptional.rest, 5) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureCurrency == ReadBytes(unitOfMeasure.rest, 3) IN IF ~unitOfMeasureCurrency.ok THEN Fail ELSE
    LET unitOfMeasureQtyDecimalOptional == DecodeUnitOfMeasureQtyDecimalOptional2(unitOfMeasureCurrency.rest) IN IF ~unitOfMeasureQtyDecimalOptional.ok THEN Fail ELSE
    LET mdEntryDate == ReadBytes(unitOfMeasureQtyDecimalOptional.rest, 4) IN IF ~mdEntryDate.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdEntryDate.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET priceType == ReadBytes(openCloseSettlFlag.rest, 2) IN IF ~priceType.ok THEN Fail ELSE
    LET settlDate == ReadBytes(priceType.rest, 2) IN IF ~settlDate.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(settlDate.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET marketSector == ReadBytes(quoteCondition.rest, 26) IN IF ~marketSector.ok THEN Fail ELSE
    LET sectorGroup == ReadBytes(marketSector.rest, 2) IN IF ~sectorGroup.ok THEN Fail ELSE
    LET sectorSubGroup == ReadBytes(sectorGroup.rest, 26) IN IF ~sectorSubGroup.ok THEN Fail ELSE
    LET productComplex == ReadBytes(sectorSubGroup.rest, 26) IN IF ~productComplex.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(productComplex.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET volType == ReadBytes(securitySubType.rest, 2) IN IF ~volType.ok THEN Fail ELSE
    LET referenceId100 == ReadBytes(volType.rest, 100) IN IF ~referenceId100.ok THEN Fail ELSE
    LET otcUnderlyingsGroups == DecodeOtcUnderlyingsGroups2(referenceId100.rest) IN IF ~otcUnderlyingsGroups.ok THEN Fail ELSE
    LET otcSecurityAltIdGroups == DecodeOtcSecurityAltIdGroups2(otcUnderlyingsGroups.rest) IN IF ~otcSecurityAltIdGroups.ok THEN Fail ELSE
    Ok([ mdEntryType                     |-> mdEntryType.value,
         rptSeq                          |-> rptSeq.value,
         mdEntryPx                       |-> mdEntryPx.value,
         mdEntrySize                     |-> mdEntrySize.value,
         symbol                          |-> symbol.value,
         securityGroup12                 |-> securityGroup12.value,
         securityType                    |-> securityType.value,
         maturityMonthYear               |-> maturityMonthYear.value,
         securityExchange                |-> securityExchange.value,
         productOptional                 |-> productOptional.value,
         maturityDate                    |-> maturityDate.value,
         couponRate                      |-> couponRate.value,
         restructuringType               |-> restructuringType.value,
         seniority                       |-> seniority.value,
         notionalPercentageOutstanding   |-> notionalPercentageOutstanding.value,
         putOrCall                       |-> putOrCall.value,
         strikePriceDecimalOptional      |-> strikePriceDecimalOptional.value,
         unitOfMeasure                   |-> unitOfMeasure.value,
         unitOfMeasureCurrency           |-> unitOfMeasureCurrency.value,
         unitOfMeasureQtyDecimalOptional |-> unitOfMeasureQtyDecimalOptional.value,
         mdEntryDate                     |-> mdEntryDate.value,
         openCloseSettlFlag              |-> openCloseSettlFlag.value,
         priceType                       |-> priceType.value,
         settlDate                       |-> settlDate.value,
         quoteCondition                  |-> quoteCondition.value,
         marketSector                    |-> marketSector.value,
         sectorGroup                     |-> sectorGroup.value,
         sectorSubGroup                  |-> sectorSubGroup.value,
         productComplex                  |-> productComplex.value,
         securitySubType                 |-> securitySubType.value,
         volType                         |-> volType.value,
         referenceId100                  |-> referenceId100.value,
         otcUnderlyingsGroups            |-> otcUnderlyingsGroups.value,
         otcSecurityAltIdGroups          |-> otcSecurityAltIdGroups.value ], otcSecurityAltIdGroups.rest)

ZeroOtcGroup ==
    [ mdEntryType                     |-> [i \in 1 .. 1 |-> 0],
      rptSeq                          |-> [i \in 1 .. 4 |-> 0],
      mdEntryPx                       |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize                     |-> ZeroMdEntrySize4,
      symbol                          |-> [i \in 1 .. 50 |-> 0],
      securityGroup12                 |-> [i \in 1 .. 12 |-> 0],
      securityType                    |-> [i \in 1 .. 9 |-> 0],
      maturityMonthYear               |-> ZeroMaturityMonthYear5,
      securityExchange                |-> [i \in 1 .. 4 |-> 0],
      productOptional                 |-> [i \in 1 .. 1 |-> 0],
      maturityDate                    |-> [i \in 1 .. 2 |-> 0],
      couponRate                      |-> [i \in 1 .. 4 |-> 0],
      restructuringType               |-> [i \in 1 .. 2 |-> 0],
      seniority                       |-> [i \in 1 .. 2 |-> 0],
      notionalPercentageOutstanding   |-> [i \in 1 .. 4 |-> 0],
      putOrCall                       |-> [i \in 1 .. 1 |-> 0],
      strikePriceDecimalOptional      |-> ZeroStrikePriceDecimalOptional2,
      unitOfMeasure                   |-> [i \in 1 .. 5 |-> 0],
      unitOfMeasureCurrency           |-> [i \in 1 .. 3 |-> 0],
      unitOfMeasureQtyDecimalOptional |-> ZeroUnitOfMeasureQtyDecimalOptional2,
      mdEntryDate                     |-> [i \in 1 .. 4 |-> 0],
      openCloseSettlFlag              |-> [i \in 1 .. 1 |-> 0],
      priceType                       |-> [i \in 1 .. 2 |-> 0],
      settlDate                       |-> [i \in 1 .. 2 |-> 0],
      quoteCondition                  |-> [i \in 1 .. 1 |-> 0],
      marketSector                    |-> [i \in 1 .. 26 |-> 0],
      sectorGroup                     |-> [i \in 1 .. 2 |-> 0],
      sectorSubGroup                  |-> [i \in 1 .. 26 |-> 0],
      productComplex                  |-> [i \in 1 .. 26 |-> 0],
      securitySubType                 |-> [i \in 1 .. 2 |-> 0],
      volType                         |-> [i \in 1 .. 2 |-> 0],
      referenceId100                  |-> [i \in 1 .. 100 |-> 0],
      otcUnderlyingsGroups            |-> ZeroOtcUnderlyingsGroups2,
      otcSecurityAltIdGroups          |-> ZeroOtcSecurityAltIdGroups2 ]

(* Otc Group at zero, then each field in turn at the values it is checked at *)
CheckedOtcGroup ==
    { ZeroOtcGroup }
        \cup { [ZeroOtcGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroOtcGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOtcGroup EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroOtcGroup EXCEPT !.mdEntrySize = one] : one \in CheckedMdEntrySize4 }
        \cup { [ZeroOtcGroup EXCEPT !.symbol = one] : one \in Sample(50) }
        \cup { [ZeroOtcGroup EXCEPT !.securityGroup12 = one] : one \in Sample(12) }
        \cup { [ZeroOtcGroup EXCEPT !.securityType = one] : one \in Sample(9) }
        \cup { [ZeroOtcGroup EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear5 }
        \cup { [ZeroOtcGroup EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroOtcGroup EXCEPT !.productOptional = one] : one \in Sample(1) }
        \cup { [ZeroOtcGroup EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.couponRate = one] : one \in Sample(4) }
        \cup { [ZeroOtcGroup EXCEPT !.restructuringType = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.seniority = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.notionalPercentageOutstanding = one] : one \in Sample(4) }
        \cup { [ZeroOtcGroup EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroOtcGroup EXCEPT !.strikePriceDecimalOptional = one] : one \in CheckedStrikePriceDecimalOptional2 }
        \cup { [ZeroOtcGroup EXCEPT !.unitOfMeasure = one] : one \in Sample(5) }
        \cup { [ZeroOtcGroup EXCEPT !.unitOfMeasureCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOtcGroup EXCEPT !.unitOfMeasureQtyDecimalOptional = one] : one \in CheckedUnitOfMeasureQtyDecimalOptional2 }
        \cup { [ZeroOtcGroup EXCEPT !.mdEntryDate = one] : one \in Sample(4) }
        \cup { [ZeroOtcGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroOtcGroup EXCEPT !.priceType = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.settlDate = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroOtcGroup EXCEPT !.marketSector = one] : one \in Sample(26) }
        \cup { [ZeroOtcGroup EXCEPT !.sectorGroup = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.sectorSubGroup = one] : one \in Sample(26) }
        \cup { [ZeroOtcGroup EXCEPT !.productComplex = one] : one \in Sample(26) }
        \cup { [ZeroOtcGroup EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.volType = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroup EXCEPT !.referenceId100 = one] : one \in Sample(100) }
        \cup { [ZeroOtcGroup EXCEPT !.otcUnderlyingsGroups = one] : one \in CheckedOtcUnderlyingsGroups2 }
        \cup { [ZeroOtcGroup EXCEPT !.otcSecurityAltIdGroups = one] : one \in CheckedOtcSecurityAltIdGroups2 }

(* A run of Otc Group, written one after another *)
RECURSIVE EncodeOtcGroupList(_)
EncodeOtcGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOtcGroup(Head(messages)) \o EncodeOtcGroupList(Tail(messages))

(* As many Otc Group as the field that counts them says *)
RECURSIVE ReadOtcGroupList(_, _)
ReadOtcGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOtcGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOtcGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Otc Group of each kind, for the lists that carry them *)
OneOtcGroup == { ZeroOtcGroup }

(***************************************************************************)
(* Otc Groups                                                              *)
(***************************************************************************)

OtcGroups ==
    [ blockLength : Sample(2),
      otcGroup    : SampleLists(OneOtcGroup) ]

EncodeOtcGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.otcGroup), 1)
        \o EncodeOtcGroupList(message.otcGroup)

DecodeOtcGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup8 == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup8.ok THEN Fail ELSE
    LET otcGroup == ReadOtcGroupList(numInGroup8.rest, numInGroup8.value) IN IF ~otcGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         otcGroup    |-> otcGroup.value ], otcGroup.rest)

ZeroOtcGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      otcGroup    |-> << >> ]

(* Otc Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtcGroups ==
    { ZeroOtcGroups }
        \cup { [ZeroOtcGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOtcGroups EXCEPT !.otcGroup = one] : one \in SampleLists(OneOtcGroup) }

(***************************************************************************)
(* Md Incremental Refresh Ot C 366                                         *)
(***************************************************************************)

MdIncrementalRefreshOtC366 ==
    [ transactTime               : Sample(8),
      tradeDate                  : Sample(2),
      matchEventIndicator        : Sample(1),
      batchTotalMessagesOptional : Sample(2),
      otcGroups                  : OtcGroups ]

EncodeMdIncrementalRefreshOtC366(message) ==
    message.transactTime
        \o message.tradeDate
        \o message.matchEventIndicator
        \o message.batchTotalMessagesOptional
        \o EncodeOtcGroups(message.otcGroups)

DecodeMdIncrementalRefreshOtC366(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(transactTime.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(tradeDate.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET batchTotalMessagesOptional == ReadBytes(matchEventIndicator.rest, 2) IN IF ~batchTotalMessagesOptional.ok THEN Fail ELSE
    LET otcGroups == DecodeOtcGroups(batchTotalMessagesOptional.rest) IN IF ~otcGroups.ok THEN Fail ELSE
    Ok([ transactTime               |-> transactTime.value,
         tradeDate                  |-> tradeDate.value,
         matchEventIndicator        |-> matchEventIndicator.value,
         batchTotalMessagesOptional |-> batchTotalMessagesOptional.value,
         otcGroups                  |-> otcGroups.value ], otcGroups.rest)

ZeroMdIncrementalRefreshOtC366 ==
    [ transactTime               |-> [i \in 1 .. 8 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      matchEventIndicator        |-> [i \in 1 .. 1 |-> 0],
      batchTotalMessagesOptional |-> [i \in 1 .. 2 |-> 0],
      otcGroups                  |-> ZeroOtcGroups ]

(* Md Incremental Refresh Ot C 366 at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshOtC366 ==
    { ZeroMdIncrementalRefreshOtC366 }
        \cup { [ZeroMdIncrementalRefreshOtC366 EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshOtC366 EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshOtC366 EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshOtC366 EXCEPT !.batchTotalMessagesOptional = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshOtC366 EXCEPT !.otcGroups = one] : one \in CheckedOtcGroups }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

AdminHeartbeatCode == 312  \* 0x138
AdminLoginCode == 315  \* 0x13b
AdminLogoutCode == 316  \* 0x13c
MdIncrementalRefreshErisReferenceDataAndDailyStatisticsCode == 333  \* 0x14d
MdNewsIndicesCode == 339  \* 0x153
MdIncrementalRefreshTradeBlocks340Code == 340  \* 0x154
QuoteRequestCode == 345  \* 0x159
MdInstrumentDefinitionIndicesCode == 347  \* 0x15b
MdIncrementalRefreshIndicesCode == 348  \* 0x15c
MdIncrementalRefreshTradeBlocks349Code == 349  \* 0x15d
MdIncrementalRefreshEris351Code == 351  \* 0x15f
MdIncrementalRefreshEris353Code == 353  \* 0x161
MdIncrementalRefreshOtC356Code == 356  \* 0x164
MdInstrumentDefinitionErisCode == 363  \* 0x16b
MdIncrementalRefreshTradeBlocks365Code == 365  \* 0x16d
MdIncrementalRefreshOtC366Code == 366  \* 0x16e

Payload ==
    [ tag : {AdminHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {AdminLoginCode}, body : AdminLogin ]
        \cup [ tag : {AdminLogoutCode}, body : AdminLogout ]
        \cup [ tag : {MdIncrementalRefreshErisReferenceDataAndDailyStatisticsCode}, body : MdIncrementalRefreshErisReferenceDataAndDailyStatistics ]
        \cup [ tag : {MdNewsIndicesCode}, body : MdNewsIndices ]
        \cup [ tag : {MdIncrementalRefreshTradeBlocks340Code}, body : MdIncrementalRefreshTradeBlocks340 ]
        \cup [ tag : {QuoteRequestCode}, body : QuoteRequest ]
        \cup [ tag : {MdInstrumentDefinitionIndicesCode}, body : MdInstrumentDefinitionIndices ]
        \cup [ tag : {MdIncrementalRefreshIndicesCode}, body : MdIncrementalRefreshIndices ]
        \cup [ tag : {MdIncrementalRefreshTradeBlocks349Code}, body : MdIncrementalRefreshTradeBlocks349 ]
        \cup [ tag : {MdIncrementalRefreshEris351Code}, body : MdIncrementalRefreshEris351 ]
        \cup [ tag : {MdIncrementalRefreshEris353Code}, body : MdIncrementalRefreshEris353 ]
        \cup [ tag : {MdIncrementalRefreshOtC356Code}, body : MdIncrementalRefreshOtC356 ]
        \cup [ tag : {MdInstrumentDefinitionErisCode}, body : MdInstrumentDefinitionEris ]
        \cup [ tag : {MdIncrementalRefreshTradeBlocks365Code}, body : MdIncrementalRefreshTradeBlocks365 ]
        \cup [ tag : {MdIncrementalRefreshOtC366Code}, body : MdIncrementalRefreshOtC366 ]

EncodePayload(message) ==
    CASE message.tag = AdminHeartbeatCode -> << >>
      [] message.tag = AdminLoginCode -> EncodeAdminLogin(message.body)
      [] message.tag = AdminLogoutCode -> EncodeAdminLogout(message.body)
      [] message.tag = MdIncrementalRefreshErisReferenceDataAndDailyStatisticsCode -> EncodeMdIncrementalRefreshErisReferenceDataAndDailyStatistics(message.body)
      [] message.tag = MdNewsIndicesCode -> EncodeMdNewsIndices(message.body)
      [] message.tag = MdIncrementalRefreshTradeBlocks340Code -> EncodeMdIncrementalRefreshTradeBlocks340(message.body)
      [] message.tag = QuoteRequestCode -> EncodeQuoteRequest(message.body)
      [] message.tag = MdInstrumentDefinitionIndicesCode -> EncodeMdInstrumentDefinitionIndices(message.body)
      [] message.tag = MdIncrementalRefreshIndicesCode -> EncodeMdIncrementalRefreshIndices(message.body)
      [] message.tag = MdIncrementalRefreshTradeBlocks349Code -> EncodeMdIncrementalRefreshTradeBlocks349(message.body)
      [] message.tag = MdIncrementalRefreshEris351Code -> EncodeMdIncrementalRefreshEris351(message.body)
      [] message.tag = MdIncrementalRefreshEris353Code -> EncodeMdIncrementalRefreshEris353(message.body)
      [] message.tag = MdIncrementalRefreshOtC356Code -> EncodeMdIncrementalRefreshOtC356(message.body)
      [] message.tag = MdInstrumentDefinitionErisCode -> EncodeMdInstrumentDefinitionEris(message.body)
      [] message.tag = MdIncrementalRefreshTradeBlocks365Code -> EncodeMdIncrementalRefreshTradeBlocks365(message.body)
      [] message.tag = MdIncrementalRefreshOtC366Code -> EncodeMdIncrementalRefreshOtC366(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = AdminHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = AdminLoginCode -> DecodeAdminLogin(bytes)
              [] tag = AdminLogoutCode -> DecodeAdminLogout(bytes)
              [] tag = MdIncrementalRefreshErisReferenceDataAndDailyStatisticsCode -> DecodeMdIncrementalRefreshErisReferenceDataAndDailyStatistics(bytes)
              [] tag = MdNewsIndicesCode -> DecodeMdNewsIndices(bytes)
              [] tag = MdIncrementalRefreshTradeBlocks340Code -> DecodeMdIncrementalRefreshTradeBlocks340(bytes)
              [] tag = QuoteRequestCode -> DecodeQuoteRequest(bytes)
              [] tag = MdInstrumentDefinitionIndicesCode -> DecodeMdInstrumentDefinitionIndices(bytes)
              [] tag = MdIncrementalRefreshIndicesCode -> DecodeMdIncrementalRefreshIndices(bytes)
              [] tag = MdIncrementalRefreshTradeBlocks349Code -> DecodeMdIncrementalRefreshTradeBlocks349(bytes)
              [] tag = MdIncrementalRefreshEris351Code -> DecodeMdIncrementalRefreshEris351(bytes)
              [] tag = MdIncrementalRefreshEris353Code -> DecodeMdIncrementalRefreshEris353(bytes)
              [] tag = MdIncrementalRefreshOtC356Code -> DecodeMdIncrementalRefreshOtC356(bytes)
              [] tag = MdInstrumentDefinitionErisCode -> DecodeMdInstrumentDefinitionEris(bytes)
              [] tag = MdIncrementalRefreshTradeBlocks365Code -> DecodeMdIncrementalRefreshTradeBlocks365(bytes)
              [] tag = MdIncrementalRefreshOtC366Code -> DecodeMdIncrementalRefreshOtC366(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> AdminLoginCode, body |-> one] : one \in CheckedAdminLogin }
        \cup { [tag |-> AdminLogoutCode, body |-> one] : one \in CheckedAdminLogout }
        \cup { [tag |-> MdIncrementalRefreshErisReferenceDataAndDailyStatisticsCode, body |-> one] : one \in CheckedMdIncrementalRefreshErisReferenceDataAndDailyStatistics }
        \cup { [tag |-> MdNewsIndicesCode, body |-> one] : one \in CheckedMdNewsIndices }
        \cup { [tag |-> MdIncrementalRefreshTradeBlocks340Code, body |-> one] : one \in CheckedMdIncrementalRefreshTradeBlocks340 }
        \cup { [tag |-> QuoteRequestCode, body |-> one] : one \in CheckedQuoteRequest }
        \cup { [tag |-> MdInstrumentDefinitionIndicesCode, body |-> one] : one \in CheckedMdInstrumentDefinitionIndices }
        \cup { [tag |-> MdIncrementalRefreshIndicesCode, body |-> one] : one \in CheckedMdIncrementalRefreshIndices }
        \cup { [tag |-> MdIncrementalRefreshTradeBlocks349Code, body |-> one] : one \in CheckedMdIncrementalRefreshTradeBlocks349 }
        \cup { [tag |-> MdIncrementalRefreshEris351Code, body |-> one] : one \in CheckedMdIncrementalRefreshEris351 }
        \cup { [tag |-> MdIncrementalRefreshEris353Code, body |-> one] : one \in CheckedMdIncrementalRefreshEris353 }
        \cup { [tag |-> MdIncrementalRefreshOtC356Code, body |-> one] : one \in CheckedMdIncrementalRefreshOtC356 }
        \cup { [tag |-> MdInstrumentDefinitionErisCode, body |-> one] : one \in CheckedMdInstrumentDefinitionEris }
        \cup { [tag |-> MdIncrementalRefreshTradeBlocks365Code, body |-> one] : one \in CheckedMdIncrementalRefreshTradeBlocks365 }
        \cup { [tag |-> MdIncrementalRefreshOtC366Code, body |-> one] : one \in CheckedMdIncrementalRefreshOtC366 }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> AdminLoginCode, body |-> ZeroAdminLogin]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdminLogoutCode, body |-> ZeroAdminLogout]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshErisReferenceDataAndDailyStatisticsCode, body |-> ZeroMdIncrementalRefreshErisReferenceDataAndDailyStatistics]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdNewsIndicesCode, body |-> ZeroMdNewsIndices]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshTradeBlocks340Code, body |-> ZeroMdIncrementalRefreshTradeBlocks340]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestCode, body |-> ZeroQuoteRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdInstrumentDefinitionIndicesCode, body |-> ZeroMdInstrumentDefinitionIndices]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshIndicesCode, body |-> ZeroMdIncrementalRefreshIndices]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshTradeBlocks349Code, body |-> ZeroMdIncrementalRefreshTradeBlocks349]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshEris351Code, body |-> ZeroMdIncrementalRefreshEris351]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshEris353Code, body |-> ZeroMdIncrementalRefreshEris353]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshOtC356Code, body |-> ZeroMdIncrementalRefreshOtC356]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdInstrumentDefinitionErisCode, body |-> ZeroMdInstrumentDefinitionEris]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshTradeBlocks365Code, body |-> ZeroMdIncrementalRefreshTradeBlocks365]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshOtC366Code, body |-> ZeroMdIncrementalRefreshOtC366]] }

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

(* Every Admin Login decodes back to what was encoded, and leaves nothing over *)
RoundTripAdminLogin ==
    \A message \in CheckedAdminLogin :
        LET read == DecodeAdminLogin(EncodeAdminLogin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Admin Logout decodes back to what was encoded, and leaves nothing over *)
RoundTripAdminLogout ==
    \A message \in CheckedAdminLogout :
        LET read == DecodeAdminLogout(EncodeAdminLogout(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px Decimal Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPxDecimalOptional ==
    \A message \in CheckedMdEntryPxDecimalOptional :
        LET read == DecodeMdEntryPxDecimalOptional(EncodeMdEntryPxDecimalOptional(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cal Fut Px Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripCalFutPxOptional ==
    \A message \in CheckedCalFutPxOptional :
        LET read == DecodeCalFutPxOptional(EncodeCalFutPxOptional(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Coupon Rate Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripCouponRateOptional ==
    \A message \in CheckedCouponRateOptional :
        LET read == DecodeCouponRateOptional(EncodeCouponRateOptional(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fair Coupon Pct decodes back to what was encoded, and leaves nothing over *)
RoundTripFairCouponPct ==
    \A message \in CheckedFairCouponPct :
        LET read == DecodeFairCouponPct(EncodeFairCouponPct(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Purchase Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripLegPurchaseRate ==
    \A message \in CheckedLegPurchaseRate :
        LET read == DecodeLegPurchaseRate(EncodeLegPurchaseRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fixed Npv decodes back to what was encoded, and leaves nothing over *)
RoundTripFixedNpv ==
    \A message \in CheckedFixedNpv :
        LET read == DecodeFixedNpv(EncodeFixedNpv(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Float Npv decodes back to what was encoded, and leaves nothing over *)
RoundTripFloatNpv ==
    \A message \in CheckedFloatNpv :
        LET read == DecodeFloatNpv(EncodeFloatNpv(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Npv decodes back to what was encoded, and leaves nothing over *)
RoundTripNpv ==
    \A message \in CheckedNpv :
        LET read == DecodeNpv(EncodeNpv(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Accrued Coupons decodes back to what was encoded, and leaves nothing over *)
RoundTripAccruedCoupons ==
    \A message \in CheckedAccruedCoupons :
        LET read == DecodeAccruedCoupons(EncodeAccruedCoupons(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Daily Incremental Eris Pai decodes back to what was encoded, and leaves nothing over *)
RoundTripDailyIncrementalErisPai ==
    \A message \in CheckedDailyIncrementalErisPai :
        LET read == DecodeDailyIncrementalErisPai(EncodeDailyIncrementalErisPai(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Pai decodes back to what was encoded, and leaves nothing over *)
RoundTripErisPai ==
    \A message \in CheckedErisPai :
        LET read == DecodeErisPai(EncodeErisPai(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fed Funds Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripFedFundsRate ==
    \A message \in CheckedFedFundsRate :
        LET read == DecodeFedFundsRate(EncodeFedFundsRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Price Increment Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripMinPriceIncrementOptional ==
    \A message \in CheckedMinPriceIncrementOptional :
        LET read == DecodeMinPriceIncrementOptional(EncodeMinPriceIncrementOptional(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fixed Payment decodes back to what was encoded, and leaves nothing over *)
RoundTripFixedPayment ==
    \A message \in CheckedFixedPayment :
        LET read == DecodeFixedPayment(EncodeFixedPayment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Floating Payment decodes back to what was encoded, and leaves nothing over *)
RoundTripFloatingPayment ==
    \A message \in CheckedFloatingPayment :
        LET read == DecodeFloatingPayment(EncodeFloatingPayment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Next Fixed Payment Amount decodes back to what was encoded, and leaves nothing over *)
RoundTripNextFixedPaymentAmount ==
    \A message \in CheckedNextFixedPaymentAmount :
        LET read == DecodeNextFixedPaymentAmount(EncodeNextFixedPaymentAmount(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Next Floating Payment Amount decodes back to what was encoded, and leaves nothing over *)
RoundTripNextFloatingPaymentAmount ==
    \A message \in CheckedNextFloatingPaymentAmount :
        LET read == DecodeNextFloatingPaymentAmount(EncodeNextFloatingPaymentAmount(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Previous Eris Pai decodes back to what was encoded, and leaves nothing over *)
RoundTripPreviousErisPai ==
    \A message \in CheckedPreviousErisPai :
        LET read == DecodePreviousErisPai(EncodePreviousErisPai(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Contract Multiplier decodes back to what was encoded, and leaves nothing over *)
RoundTripLegContractMultiplier ==
    \A message \in CheckedLegContractMultiplier :
        LET read == DecodeLegContractMultiplier(EncodeLegContractMultiplier(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every P V 01 decodes back to what was encoded, and leaves nothing over *)
RoundTripPV01 ==
    \A message \in CheckedPV01 :
        LET read == DecodePV01(EncodePV01(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every D V 01 decodes back to what was encoded, and leaves nothing over *)
RoundTripDV01 ==
    \A message \in CheckedDV01 :
        LET read == DecodeDV01(EncodeDV01(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Npv decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementNpv ==
    \A message \in CheckedSettlementNpv :
        LET read == DecodeSettlementNpv(EncodeSettlementNpv(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Final Settlement Futures Price decodes back to what was encoded, and leaves nothing over *)
RoundTripFinalSettlementFuturesPrice ==
    \A message \in CheckedFinalSettlementFuturesPrice :
        LET read == DecodeFinalSettlementFuturesPrice(EncodeFinalSettlementFuturesPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroup ==
    \A message \in CheckedErisSecurityAltIdGroup :
        LET read == DecodeErisSecurityAltIdGroup(EncodeErisSecurityAltIdGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroups ==
    \A message \in CheckedErisSecurityAltIdGroups :
        LET read == DecodeErisSecurityAltIdGroups(EncodeErisSecurityAltIdGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Eris Related Instruments Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshErisRelatedInstrumentsGroup ==
    \A message \in CheckedIncrementalRefreshErisRelatedInstrumentsGroup :
        LET read == DecodeIncrementalRefreshErisRelatedInstrumentsGroup(EncodeIncrementalRefreshErisRelatedInstrumentsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Eris Related Instruments Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshErisRelatedInstrumentsGroups ==
    \A message \in CheckedIncrementalRefreshErisRelatedInstrumentsGroups :
        LET read == DecodeIncrementalRefreshErisRelatedInstrumentsGroups(EncodeIncrementalRefreshErisRelatedInstrumentsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup ==
    \A message \in CheckedEventsGroup :
        LET read == DecodeEventsGroup(EncodeEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups ==
    \A message \in CheckedEventsGroups :
        LET read == DecodeEventsGroups(EncodeEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Reference Data Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisReferenceDataGroup ==
    \A message \in CheckedErisReferenceDataGroup :
        LET read == DecodeErisReferenceDataGroup(EncodeErisReferenceDataGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Reference Data Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisReferenceDataGroups ==
    \A message \in CheckedErisReferenceDataGroups :
        LET read == DecodeErisReferenceDataGroups(EncodeErisReferenceDataGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Eris Reference Data And Daily Statistics decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshErisReferenceDataAndDailyStatistics ==
    \A message \in CheckedMdIncrementalRefreshErisReferenceDataAndDailyStatistics :
        LET read == DecodeMdIncrementalRefreshErisReferenceDataAndDailyStatistics(EncodeMdIncrementalRefreshErisReferenceDataAndDailyStatistics(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Indices Related Sym Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsIndicesRelatedSymGroup ==
    \A message \in CheckedNewsIndicesRelatedSymGroup :
        LET read == DecodeNewsIndicesRelatedSymGroup(EncodeNewsIndicesRelatedSymGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Indices Related Sym Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsIndicesRelatedSymGroups ==
    \A message \in CheckedNewsIndicesRelatedSymGroups :
        LET read == DecodeNewsIndicesRelatedSymGroups(EncodeNewsIndicesRelatedSymGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lines Of Text Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLinesOfTextGroup ==
    \A message \in CheckedLinesOfTextGroup :
        LET read == DecodeLinesOfTextGroup(EncodeLinesOfTextGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lines Of Text Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLinesOfTextGroups ==
    \A message \in CheckedLinesOfTextGroups :
        LET read == DecodeLinesOfTextGroups(EncodeLinesOfTextGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md News Indices decodes back to what was encoded, and leaves nothing over *)
RoundTripMdNewsIndices ==
    \A message \in CheckedMdNewsIndices :
        LET read == DecodeMdNewsIndices(EncodeMdNewsIndices(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear ==
    \A message \in CheckedMaturityMonthYear :
        LET read == DecodeMaturityMonthYear(EncodeMaturityMonthYear(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear ==
    \A message \in CheckedUnderlyingMaturityMonthYear :
        LET read == DecodeUnderlyingMaturityMonthYear(EncodeUnderlyingMaturityMonthYear(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksUnderlyingsGroup ==
    \A message \in CheckedTradeBlocksUnderlyingsGroup :
        LET read == DecodeTradeBlocksUnderlyingsGroup(EncodeTradeBlocksUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksUnderlyingsGroups ==
    \A message \in CheckedTradeBlocksUnderlyingsGroups :
        LET read == DecodeTradeBlocksUnderlyingsGroups(EncodeTradeBlocksUnderlyingsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Party Ids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksPartyIdsGroup ==
    \A message \in CheckedTradeBlocksPartyIdsGroup :
        LET read == DecodeTradeBlocksPartyIdsGroup(EncodeTradeBlocksPartyIdsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Party Ids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksPartyIdsGroups ==
    \A message \in CheckedTradeBlocksPartyIdsGroups :
        LET read == DecodeTradeBlocksPartyIdsGroups(EncodeTradeBlocksPartyIdsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripLegMaturityMonthYear ==
    \A message \in CheckedLegMaturityMonthYear :
        LET read == DecodeLegMaturityMonthYear(EncodeLegMaturityMonthYear(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Original Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksOriginalLegsGroup ==
    \A message \in CheckedTradeBlocksOriginalLegsGroup :
        LET read == DecodeTradeBlocksOriginalLegsGroup(EncodeTradeBlocksOriginalLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Original Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksOriginalLegsGroups ==
    \A message \in CheckedTradeBlocksOriginalLegsGroups :
        LET read == DecodeTradeBlocksOriginalLegsGroups(EncodeTradeBlocksOriginalLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Original Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksOriginalGroup ==
    \A message \in CheckedTradeBlocksOriginalGroup :
        LET read == DecodeTradeBlocksOriginalGroup(EncodeTradeBlocksOriginalGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Original Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksOriginalGroups ==
    \A message \in CheckedTradeBlocksOriginalGroups :
        LET read == DecodeTradeBlocksOriginalGroups(EncodeTradeBlocksOriginalGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Trade Blocks 340 decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshTradeBlocks340 ==
    \A message \in CheckedMdIncrementalRefreshTradeBlocks340 :
        LET read == DecodeMdIncrementalRefreshTradeBlocks340(EncodeMdIncrementalRefreshTradeBlocks340(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup2 ==
    \A message \in CheckedEventsGroup2 :
        LET read == DecodeEventsGroup2(EncodeEventsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups2 ==
    \A message \in CheckedEventsGroups2 :
        LET read == DecodeEventsGroups2(EncodeEventsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Related Sym Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestRelatedSymGroup ==
    \A message \in CheckedQuoteRequestRelatedSymGroup :
        LET read == DecodeQuoteRequestRelatedSymGroup(EncodeQuoteRequestRelatedSymGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Related Sym Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestRelatedSymGroups ==
    \A message \in CheckedQuoteRequestRelatedSymGroups :
        LET read == DecodeQuoteRequestRelatedSymGroups(EncodeQuoteRequestRelatedSymGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequest ==
    \A message \in CheckedQuoteRequest :
        LET read == DecodeQuoteRequest(EncodeQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroup ==
    \A message \in CheckedInstAttribGroup :
        LET read == DecodeInstAttribGroup(EncodeInstAttribGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroups ==
    \A message \in CheckedInstAttribGroups :
        LET read == DecodeInstAttribGroups(EncodeInstAttribGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup3 ==
    \A message \in CheckedEventsGroup3 :
        LET read == DecodeEventsGroup3(EncodeEventsGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups3 ==
    \A message \in CheckedEventsGroups3 :
        LET read == DecodeEventsGroups3(EncodeEventsGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Definition Indices decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentDefinitionIndices ==
    \A message \in CheckedMdInstrumentDefinitionIndices :
        LET read == DecodeMdInstrumentDefinitionIndices(EncodeMdInstrumentDefinitionIndices(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px Decimal decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPxDecimal ==
    \A message \in CheckedMdEntryPxDecimal :
        LET read == DecodeMdEntryPxDecimal(EncodeMdEntryPxDecimal(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Yield decodes back to what was encoded, and leaves nothing over *)
RoundTripYield ==
    \A message \in CheckedYield :
        LET read == DecodeYield(EncodeYield(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Net Chg Prev Day decodes back to what was encoded, and leaves nothing over *)
RoundTripNetChgPrevDay ==
    \A message \in CheckedNetChgPrevDay :
        LET read == DecodeNetChgPrevDay(EncodeNetChgPrevDay(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Net Pct Chg decodes back to what was encoded, and leaves nothing over *)
RoundTripNetPctChg ==
    \A message \in CheckedNetPctChg :
        LET read == DecodeNetPctChg(EncodeNetPctChg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Percent Trading decodes back to what was encoded, and leaves nothing over *)
RoundTripPercentTrading ==
    \A message \in CheckedPercentTrading :
        LET read == DecodePercentTrading(EncodePercentTrading(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Indices Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshIndicesGroup ==
    \A message \in CheckedIncrementalRefreshIndicesGroup :
        LET read == DecodeIncrementalRefreshIndicesGroup(EncodeIncrementalRefreshIndicesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Indices Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshIndicesGroups ==
    \A message \in CheckedIncrementalRefreshIndicesGroups :
        LET read == DecodeIncrementalRefreshIndicesGroups(EncodeIncrementalRefreshIndicesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Indices decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshIndices ==
    \A message \in CheckedMdIncrementalRefreshIndices :
        LET read == DecodeMdIncrementalRefreshIndices(EncodeMdIncrementalRefreshIndices(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Size decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntrySize ==
    \A message \in CheckedMdEntrySize :
        LET read == DecodeMdEntrySize(EncodeMdEntrySize(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear2 ==
    \A message \in CheckedMaturityMonthYear2 :
        LET read == DecodeMaturityMonthYear2(EncodeMaturityMonthYear2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear2 ==
    \A message \in CheckedUnderlyingMaturityMonthYear2 :
        LET read == DecodeUnderlyingMaturityMonthYear2(EncodeUnderlyingMaturityMonthYear2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksUnderlyingsGroup2 ==
    \A message \in CheckedTradeBlocksUnderlyingsGroup2 :
        LET read == DecodeTradeBlocksUnderlyingsGroup2(EncodeTradeBlocksUnderlyingsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksUnderlyingsGroups2 ==
    \A message \in CheckedTradeBlocksUnderlyingsGroups2 :
        LET read == DecodeTradeBlocksUnderlyingsGroups2(EncodeTradeBlocksUnderlyingsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Party Ids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksPartyIdsGroup2 ==
    \A message \in CheckedTradeBlocksPartyIdsGroup2 :
        LET read == DecodeTradeBlocksPartyIdsGroup2(EncodeTradeBlocksPartyIdsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Party Ids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksPartyIdsGroups2 ==
    \A message \in CheckedTradeBlocksPartyIdsGroups2 :
        LET read == DecodeTradeBlocksPartyIdsGroups2(EncodeTradeBlocksPartyIdsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripLegMaturityMonthYear2 ==
    \A message \in CheckedLegMaturityMonthYear2 :
        LET read == DecodeLegMaturityMonthYear2(EncodeLegMaturityMonthYear2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Original Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksOriginalLegsGroup2 ==
    \A message \in CheckedTradeBlocksOriginalLegsGroup2 :
        LET read == DecodeTradeBlocksOriginalLegsGroup2(EncodeTradeBlocksOriginalLegsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Original Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksOriginalLegsGroups2 ==
    \A message \in CheckedTradeBlocksOriginalLegsGroups2 :
        LET read == DecodeTradeBlocksOriginalLegsGroups2(EncodeTradeBlocksOriginalLegsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Legacy Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksLegacyGroup ==
    \A message \in CheckedTradeBlocksLegacyGroup :
        LET read == DecodeTradeBlocksLegacyGroup(EncodeTradeBlocksLegacyGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Legacy Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksLegacyGroups ==
    \A message \in CheckedTradeBlocksLegacyGroups :
        LET read == DecodeTradeBlocksLegacyGroups(EncodeTradeBlocksLegacyGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Trade Blocks 349 decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshTradeBlocks349 ==
    \A message \in CheckedMdIncrementalRefreshTradeBlocks349 :
        LET read == DecodeMdIncrementalRefreshTradeBlocks349(EncodeMdIncrementalRefreshTradeBlocks349(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px Decimal decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPxDecimal2 ==
    \A message \in CheckedMdEntryPxDecimal2 :
        LET read == DecodeMdEntryPxDecimal2(EncodeMdEntryPxDecimal2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cal Fut Px decodes back to what was encoded, and leaves nothing over *)
RoundTripCalFutPx ==
    \A message \in CheckedCalFutPx :
        LET read == DecodeCalFutPx(EncodeCalFutPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroup2 ==
    \A message \in CheckedErisSecurityAltIdGroup2 :
        LET read == DecodeErisSecurityAltIdGroup2(EncodeErisSecurityAltIdGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroups2 ==
    \A message \in CheckedErisSecurityAltIdGroups2 :
        LET read == DecodeErisSecurityAltIdGroups2(EncodeErisSecurityAltIdGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup4 ==
    \A message \in CheckedEventsGroup4 :
        LET read == DecodeEventsGroup4(EncodeEventsGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups4 ==
    \A message \in CheckedEventsGroups4 :
        LET read == DecodeEventsGroups4(EncodeEventsGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Original Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisOriginalGroup ==
    \A message \in CheckedErisOriginalGroup :
        LET read == DecodeErisOriginalGroup(EncodeErisOriginalGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Original Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisOriginalGroups ==
    \A message \in CheckedErisOriginalGroups :
        LET read == DecodeErisOriginalGroups(EncodeErisOriginalGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Eris 351 decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshEris351 ==
    \A message \in CheckedMdIncrementalRefreshEris351 :
        LET read == DecodeMdIncrementalRefreshEris351(EncodeMdIncrementalRefreshEris351(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px Decimal decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPxDecimal3 ==
    \A message \in CheckedMdEntryPxDecimal3 :
        LET read == DecodeMdEntryPxDecimal3(EncodeMdEntryPxDecimal3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cal Fut Px decodes back to what was encoded, and leaves nothing over *)
RoundTripCalFutPx2 ==
    \A message \in CheckedCalFutPx2 :
        LET read == DecodeCalFutPx2(EncodeCalFutPx2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroup3 ==
    \A message \in CheckedErisSecurityAltIdGroup3 :
        LET read == DecodeErisSecurityAltIdGroup3(EncodeErisSecurityAltIdGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroups3 ==
    \A message \in CheckedErisSecurityAltIdGroups3 :
        LET read == DecodeErisSecurityAltIdGroups3(EncodeErisSecurityAltIdGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup5 ==
    \A message \in CheckedEventsGroup5 :
        LET read == DecodeEventsGroup5(EncodeEventsGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups5 ==
    \A message \in CheckedEventsGroups5 :
        LET read == DecodeEventsGroups5(EncodeEventsGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisGroup ==
    \A message \in CheckedErisGroup :
        LET read == DecodeErisGroup(EncodeErisGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisGroups ==
    \A message \in CheckedErisGroups :
        LET read == DecodeErisGroups(EncodeErisGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Eris 353 decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshEris353 ==
    \A message \in CheckedMdIncrementalRefreshEris353 :
        LET read == DecodeMdIncrementalRefreshEris353(EncodeMdIncrementalRefreshEris353(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Size decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntrySize2 ==
    \A message \in CheckedMdEntrySize2 :
        LET read == DecodeMdEntrySize2(EncodeMdEntrySize2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear3 ==
    \A message \in CheckedMaturityMonthYear3 :
        LET read == DecodeMaturityMonthYear3(EncodeMaturityMonthYear3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strike Price Decimal decodes back to what was encoded, and leaves nothing over *)
RoundTripStrikePriceDecimal ==
    \A message \in CheckedStrikePriceDecimal :
        LET read == DecodeStrikePriceDecimal(EncodeStrikePriceDecimal(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Of Measure Qty Decimal decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitOfMeasureQtyDecimal ==
    \A message \in CheckedUnitOfMeasureQtyDecimal :
        LET read == DecodeUnitOfMeasureQtyDecimal(EncodeUnitOfMeasureQtyDecimal(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear3 ==
    \A message \in CheckedUnderlyingMaturityMonthYear3 :
        LET read == DecodeUnderlyingMaturityMonthYear3(EncodeUnderlyingMaturityMonthYear3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcUnderlyingsGroup ==
    \A message \in CheckedOtcUnderlyingsGroup :
        LET read == DecodeOtcUnderlyingsGroup(EncodeOtcUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcUnderlyingsGroups ==
    \A message \in CheckedOtcUnderlyingsGroups :
        LET read == DecodeOtcUnderlyingsGroups(EncodeOtcUnderlyingsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Security Alt Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcSecurityAltIdGroup ==
    \A message \in CheckedOtcSecurityAltIdGroup :
        LET read == DecodeOtcSecurityAltIdGroup(EncodeOtcSecurityAltIdGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Security Alt Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcSecurityAltIdGroups ==
    \A message \in CheckedOtcSecurityAltIdGroups :
        LET read == DecodeOtcSecurityAltIdGroups(EncodeOtcSecurityAltIdGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Original Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcOriginalGroup ==
    \A message \in CheckedOtcOriginalGroup :
        LET read == DecodeOtcOriginalGroup(EncodeOtcOriginalGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Original Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcOriginalGroups ==
    \A message \in CheckedOtcOriginalGroups :
        LET read == DecodeOtcOriginalGroups(EncodeOtcOriginalGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Ot C 356 decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshOtC356 ==
    \A message \in CheckedMdIncrementalRefreshOtC356 :
        LET read == DecodeMdIncrementalRefreshOtC356(EncodeMdIncrementalRefreshOtC356(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Price Increment decodes back to what was encoded, and leaves nothing over *)
RoundTripMinPriceIncrement ==
    \A message \in CheckedMinPriceIncrement :
        LET read == DecodeMinPriceIncrement(EncodeMinPriceIncrement(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Feed Types Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisFeedTypesGroup ==
    \A message \in CheckedErisFeedTypesGroup :
        LET read == DecodeErisFeedTypesGroup(EncodeErisFeedTypesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Feed Types Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisFeedTypesGroups ==
    \A message \in CheckedErisFeedTypesGroups :
        LET read == DecodeErisFeedTypesGroups(EncodeErisFeedTypesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup6 ==
    \A message \in CheckedEventsGroup6 :
        LET read == DecodeEventsGroup6(EncodeEventsGroup6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups6 ==
    \A message \in CheckedEventsGroups6 :
        LET read == DecodeEventsGroups6(EncodeEventsGroups6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroup4 ==
    \A message \in CheckedErisSecurityAltIdGroup4 :
        LET read == DecodeErisSecurityAltIdGroup4(EncodeErisSecurityAltIdGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroups4 ==
    \A message \in CheckedErisSecurityAltIdGroups4 :
        LET read == DecodeErisSecurityAltIdGroups4(EncodeErisSecurityAltIdGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Previous Fixing Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripPreviousFixingRate ==
    \A message \in CheckedPreviousFixingRate :
        LET read == DecodePreviousFixingRate(EncodePreviousFixingRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Interpolation Factor decodes back to what was encoded, and leaves nothing over *)
RoundTripInterpolationFactor ==
    \A message \in CheckedInterpolationFactor :
        LET read == DecodeInterpolationFactor(EncodeInterpolationFactor(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroup5 ==
    \A message \in CheckedErisSecurityAltIdGroup5 :
        LET read == DecodeErisSecurityAltIdGroup5(EncodeErisSecurityAltIdGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Security Alt Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisSecurityAltIdGroups5 ==
    \A message \in CheckedErisSecurityAltIdGroups5 :
        LET read == DecodeErisSecurityAltIdGroups5(EncodeErisSecurityAltIdGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripErisLegsGroup ==
    \A message \in CheckedErisLegsGroup :
        LET read == DecodeErisLegsGroup(EncodeErisLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eris Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripErisLegsGroups ==
    \A message \in CheckedErisLegsGroups :
        LET read == DecodeErisLegsGroups(EncodeErisLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Definition Eris decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentDefinitionEris ==
    \A message \in CheckedMdInstrumentDefinitionEris :
        LET read == DecodeMdInstrumentDefinitionEris(EncodeMdInstrumentDefinitionEris(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Size decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntrySize3 ==
    \A message \in CheckedMdEntrySize3 :
        LET read == DecodeMdEntrySize3(EncodeMdEntrySize3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear4 ==
    \A message \in CheckedMaturityMonthYear4 :
        LET read == DecodeMaturityMonthYear4(EncodeMaturityMonthYear4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Of Measure Qty Decimal Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitOfMeasureQtyDecimalOptional ==
    \A message \in CheckedUnitOfMeasureQtyDecimalOptional :
        LET read == DecodeUnitOfMeasureQtyDecimalOptional(EncodeUnitOfMeasureQtyDecimalOptional(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strike Price Decimal Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripStrikePriceDecimalOptional ==
    \A message \in CheckedStrikePriceDecimalOptional :
        LET read == DecodeStrikePriceDecimalOptional(EncodeStrikePriceDecimalOptional(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear4 ==
    \A message \in CheckedUnderlyingMaturityMonthYear4 :
        LET read == DecodeUnderlyingMaturityMonthYear4(EncodeUnderlyingMaturityMonthYear4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksUnderlyingsGroup3 ==
    \A message \in CheckedTradeBlocksUnderlyingsGroup3 :
        LET read == DecodeTradeBlocksUnderlyingsGroup3(EncodeTradeBlocksUnderlyingsGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksUnderlyingsGroups3 ==
    \A message \in CheckedTradeBlocksUnderlyingsGroups3 :
        LET read == DecodeTradeBlocksUnderlyingsGroups3(EncodeTradeBlocksUnderlyingsGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Party Ids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksPartyIdsGroup3 ==
    \A message \in CheckedTradeBlocksPartyIdsGroup3 :
        LET read == DecodeTradeBlocksPartyIdsGroup3(EncodeTradeBlocksPartyIdsGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Party Ids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksPartyIdsGroups3 ==
    \A message \in CheckedTradeBlocksPartyIdsGroups3 :
        LET read == DecodeTradeBlocksPartyIdsGroups3(EncodeTradeBlocksPartyIdsGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripLegMaturityMonthYear3 ==
    \A message \in CheckedLegMaturityMonthYear3 :
        LET read == DecodeLegMaturityMonthYear3(EncodeLegMaturityMonthYear3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Strike Price Decimal 64 Null decodes back to what was encoded, and leaves nothing over *)
RoundTripLegStrikePriceDecimal64Null ==
    \A message \in CheckedLegStrikePriceDecimal64Null :
        LET read == DecodeLegStrikePriceDecimal64Null(EncodeLegStrikePriceDecimal64Null(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Unit Of Measure Qty Decimal 64 Null decodes back to what was encoded, and leaves nothing over *)
RoundTripLegUnitOfMeasureQtyDecimal64Null ==
    \A message \in CheckedLegUnitOfMeasureQtyDecimal64Null :
        LET read == DecodeLegUnitOfMeasureQtyDecimal64Null(EncodeLegUnitOfMeasureQtyDecimal64Null(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksLegsGroup ==
    \A message \in CheckedTradeBlocksLegsGroup :
        LET read == DecodeTradeBlocksLegsGroup(EncodeTradeBlocksLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksLegsGroups ==
    \A message \in CheckedTradeBlocksLegsGroups :
        LET read == DecodeTradeBlocksLegsGroups(EncodeTradeBlocksLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksGroup ==
    \A message \in CheckedTradeBlocksGroup :
        LET read == DecodeTradeBlocksGroup(EncodeTradeBlocksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Blocks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBlocksGroups ==
    \A message \in CheckedTradeBlocksGroups :
        LET read == DecodeTradeBlocksGroups(EncodeTradeBlocksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Trade Blocks 365 decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshTradeBlocks365 ==
    \A message \in CheckedMdIncrementalRefreshTradeBlocks365 :
        LET read == DecodeMdIncrementalRefreshTradeBlocks365(EncodeMdIncrementalRefreshTradeBlocks365(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Size decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntrySize4 ==
    \A message \in CheckedMdEntrySize4 :
        LET read == DecodeMdEntrySize4(EncodeMdEntrySize4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear5 ==
    \A message \in CheckedMaturityMonthYear5 :
        LET read == DecodeMaturityMonthYear5(EncodeMaturityMonthYear5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strike Price Decimal Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripStrikePriceDecimalOptional2 ==
    \A message \in CheckedStrikePriceDecimalOptional2 :
        LET read == DecodeStrikePriceDecimalOptional2(EncodeStrikePriceDecimalOptional2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Of Measure Qty Decimal Optional decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitOfMeasureQtyDecimalOptional2 ==
    \A message \in CheckedUnitOfMeasureQtyDecimalOptional2 :
        LET read == DecodeUnitOfMeasureQtyDecimalOptional2(EncodeUnitOfMeasureQtyDecimalOptional2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingMaturityMonthYear5 ==
    \A message \in CheckedUnderlyingMaturityMonthYear5 :
        LET read == DecodeUnderlyingMaturityMonthYear5(EncodeUnderlyingMaturityMonthYear5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcUnderlyingsGroup2 ==
    \A message \in CheckedOtcUnderlyingsGroup2 :
        LET read == DecodeOtcUnderlyingsGroup2(EncodeOtcUnderlyingsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcUnderlyingsGroups2 ==
    \A message \in CheckedOtcUnderlyingsGroups2 :
        LET read == DecodeOtcUnderlyingsGroups2(EncodeOtcUnderlyingsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Security Alt Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcSecurityAltIdGroup2 ==
    \A message \in CheckedOtcSecurityAltIdGroup2 :
        LET read == DecodeOtcSecurityAltIdGroup2(EncodeOtcSecurityAltIdGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Security Alt Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcSecurityAltIdGroups2 ==
    \A message \in CheckedOtcSecurityAltIdGroups2 :
        LET read == DecodeOtcSecurityAltIdGroups2(EncodeOtcSecurityAltIdGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcGroup ==
    \A message \in CheckedOtcGroup :
        LET read == DecodeOtcGroup(EncodeOtcGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Otc Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtcGroups ==
    \A message \in CheckedOtcGroups :
        LET read == DecodeOtcGroups(EncodeOtcGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Ot C 366 decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshOtC366 ==
    \A message \in CheckedMdIncrementalRefreshOtC366 :
        LET read == DecodeMdIncrementalRefreshOtC366(EncodeMdIncrementalRefreshOtC366(message))
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
