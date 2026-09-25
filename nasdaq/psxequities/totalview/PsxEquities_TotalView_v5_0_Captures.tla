---------------- MODULE PsxEquities_TotalView_v5_0_Captures ----------------
(***************************************************************************)
(* Recorded National Association of Securities Dealers Automated           *)
(* Quotations (Nasdaq) TotalView Itch v5.0 packets, as the bytes they were *)
(* captured as. Each one decodes, consumes the whole packet, and encodes   *)
(* back to exactly the bytes it was read from.                             *)
(***************************************************************************)
EXTENDS PsxEquities_TotalView_v5_0

AddOrderNoMpidAttributionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 16, 58, 0, 0, 31, 26, 206, 220, 24,
       20, 0, 0, 0, 0, 0, 14, 7, 160, 83, 0, 0, 3, 232, 70, 88,
       89, 32, 32, 32, 32, 32, 0, 9, 185, 216 >>

AddOrderNoMpidAttributionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 40, 30, 0, 0, 31, 26, 206, 220, 28,
       102, 0, 0, 0, 0, 0, 14, 7, 161, 66, 0, 0, 0, 100, 85, 66,
       84, 32, 32, 32, 32, 32, 0, 3, 19, 28 >>

AddOrderNoMpidAttributionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 13, 161, 0, 0, 31, 26, 206, 220, 31,
       238, 0, 0, 0, 0, 0, 14, 7, 162, 66, 0, 0, 13, 72, 69, 87,
       67, 32, 32, 32, 32, 32, 0, 5, 39, 36 >>

AddOrderNoMpidAttributionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 0, 138, 0, 0, 31, 26, 206, 220, 34,
       225, 0, 0, 0, 0, 0, 14, 7, 163, 83, 0, 0, 2, 188, 65, 67,
       87, 73, 32, 32, 32, 32, 0, 14, 114, 12 >>

AddOrderNoMpidAttributionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 65, 35, 12, 0, 0, 31, 26, 206, 220, 39,
       169, 0, 0, 0, 0, 0, 14, 7, 164, 66, 0, 0, 0, 100, 83, 67,
       72, 79, 32, 32, 32, 32, 0, 7, 78, 80 >>

AddOrderWithMpidAttributionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 26, 3, 0, 0, 31, 26, 206, 243, 39,
       95, 0, 0, 0, 0, 0, 14, 9, 0, 66, 0, 0, 0, 100, 77, 77,
       77, 32, 32, 32, 32, 32, 0, 12, 36, 152, 80, 85, 78, 68 >>

AddOrderWithMpidAttributionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 26, 3, 0, 0, 31, 26, 206, 243, 82,
       210, 0, 0, 0, 0, 0, 14, 9, 1, 66, 0, 0, 0, 100, 77, 77,
       77, 32, 32, 32, 32, 32, 0, 12, 36, 152, 80, 85, 78, 68 >>

AddOrderWithMpidAttributionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 32, 187, 0, 0, 31, 26, 206, 247, 58,
       3, 0, 0, 0, 0, 0, 14, 9, 67, 66, 0, 0, 0, 100, 81, 81,
       81, 32, 32, 32, 32, 32, 0, 44, 190, 76, 80, 85, 78, 68 >>

AddOrderWithMpidAttributionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 38, 124, 0, 0, 31, 26, 206, 251, 158,
       209, 0, 0, 0, 0, 0, 14, 9, 114, 83, 0, 0, 0, 100, 84, 68,
       87, 32, 32, 32, 32, 32, 0, 12, 7, 76, 80, 85, 78, 68 >>

AddOrderWithMpidAttributionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 40, 70, 26, 143, 0, 0, 31, 26, 206, 252, 143,
       57, 0, 0, 0, 0, 0, 14, 9, 130, 66, 0, 0, 0, 100, 77, 83,
       67, 73, 32, 32, 32, 32, 0, 63, 216, 136, 80, 85, 78, 68 >>

OrderCancelMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 6, 34, 0, 0, 31, 26, 207, 134, 129,
       232, 0, 0, 0, 0, 0, 13, 234, 198, 0, 0, 0, 100 >>

OrderCancelMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 4, 228, 0, 0, 31, 26, 207, 135, 32,
       167, 0, 0, 0, 0, 0, 13, 234, 206, 0, 0, 5, 220 >>

OrderCancelMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 4, 228, 0, 0, 31, 26, 207, 140, 230,
       203, 0, 0, 0, 0, 0, 13, 234, 206, 0, 0, 2, 88 >>

OrderCancelMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 4, 16, 0, 0, 31, 26, 214, 239, 215,
       215, 0, 0, 0, 0, 0, 13, 212, 182, 0, 0, 11, 184 >>

OrderCancelMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 23, 88, 16, 49, 0, 0, 31, 26, 224, 127, 192,
       63, 0, 0, 0, 0, 0, 14, 248, 157, 0, 0, 0, 100 >>

OrderDeleteMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 11, 138, 0, 0, 31, 26, 206, 224, 24,
       130, 0, 0, 0, 0, 0, 14, 7, 166 >>

OrderDeleteMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 37, 37, 0, 0, 31, 26, 206, 228, 117,
       4, 0, 0, 0, 0, 0, 14, 3, 64 >>

OrderDeleteMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 21, 177, 0, 0, 31, 26, 206, 228, 244,
       178, 0, 0, 0, 0, 0, 14, 4, 131 >>

OrderDeleteMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 37, 37, 0, 0, 31, 26, 206, 229, 166,
       188, 0, 0, 0, 0, 0, 14, 8, 11 >>

OrderDeleteMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 19, 68, 37, 37, 0, 0, 31, 26, 206, 229, 210,
       232, 0, 0, 0, 0, 0, 14, 8, 16 >>

OrderExecutedMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 36, 197, 0, 2, 31, 26, 206, 238, 83,
       126, 0, 0, 0, 0, 0, 14, 7, 102, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 0, 104, 69 >>

OrderExecutedMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 12, 35, 0, 2, 31, 26, 207, 51, 100,
       76, 0, 0, 0, 0, 0, 14, 15, 9, 0, 0, 5, 220, 0, 0, 0,
       0, 0, 0, 104, 70 >>

OrderExecutedMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 36, 197, 0, 2, 31, 26, 207, 59, 94,
       223, 0, 0, 0, 0, 0, 14, 9, 70, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 0, 104, 71 >>

OrderExecutedMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 36, 197, 0, 2, 31, 26, 207, 168, 2,
       106, 0, 0, 0, 0, 0, 14, 20, 89, 0, 0, 0, 200, 0, 0, 0,
       0, 0, 0, 104, 72 >>

OrderExecutedMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 31, 69, 32, 187, 0, 2, 31, 26, 207, 227, 30,
       251, 0, 0, 0, 0, 0, 14, 7, 237, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 0, 104, 73 >>

OrderExecutedWithPriceMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 16, 9, 0, 2, 31, 26, 237, 248, 31,
       91, 0, 0, 0, 0, 0, 14, 97, 255, 0, 0, 0, 100, 0, 0, 0,
       0, 0, 0, 104, 141, 89, 0, 0, 206, 164 >>

OrderExecutedWithPriceMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 7, 189, 0, 2, 31, 27, 22, 172, 223,
       182, 0, 0, 0, 0, 0, 16, 19, 158, 0, 0, 0, 3, 0, 0, 0,
       0, 0, 0, 104, 241, 89, 0, 1, 20, 144 >>

OrderExecutedWithPriceMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 39, 101, 0, 2, 31, 27, 30, 177, 90,
       185, 0, 0, 0, 0, 0, 16, 15, 20, 0, 0, 0, 34, 0, 0, 0,
       0, 0, 0, 105, 17, 89, 0, 5, 242, 68 >>

OrderExecutedWithPriceMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 13, 188, 0, 2, 31, 27, 171, 189, 191,
       254, 0, 0, 0, 0, 0, 16, 230, 220, 0, 0, 0, 1, 0, 0, 0,
       0, 0, 0, 105, 211, 89, 0, 4, 177, 244 >>

OrderExecutedWithPriceMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 36, 67, 33, 153, 0, 2, 31, 27, 198, 131, 103,
       85, 0, 0, 0, 0, 0, 16, 255, 66, 0, 0, 0, 90, 0, 0, 0,
       0, 0, 0, 105, 249, 89, 0, 0, 82, 208 >>

OrderReplaceMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 25, 231, 0, 0, 31, 26, 206, 228, 106,
       181, 0, 0, 0, 0, 0, 8, 151, 215, 0, 0, 0, 0, 0, 14, 8,
       45, 0, 0, 0, 100, 0, 2, 25, 228 >>

OrderReplaceMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 41, 231, 0, 0, 31, 26, 206, 234, 130,
       99, 0, 0, 0, 0, 0, 13, 180, 184, 0, 0, 0, 0, 0, 14, 8,
       134, 0, 0, 0, 100, 0, 4, 28, 188 >>

OrderReplaceMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 30, 147, 0, 0, 31, 26, 206, 236, 75,
       81, 0, 0, 0, 0, 0, 8, 162, 206, 0, 0, 0, 0, 0, 14, 8,
       163, 0, 0, 0, 100, 0, 3, 112, 120 >>

OrderReplaceMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 19, 47, 0, 0, 31, 26, 206, 239, 122,
       204, 0, 0, 0, 0, 0, 8, 94, 101, 0, 0, 0, 0, 0, 14, 8,
       213, 0, 0, 0, 100, 0, 9, 69, 12 >>

OrderReplaceMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 35, 85, 42, 221, 0, 0, 31, 26, 206, 252, 16,
       32, 0, 0, 0, 0, 0, 8, 90, 66, 0, 0, 0, 0, 0, 14, 9,
       123, 0, 0, 0, 100, 0, 0, 12, 75 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 36, 189, 0, 0, 31, 26, 213, 207, 48,
       165, 83, 79, 80, 65, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 8, 234, 0, 0, 31, 26, 215, 215, 4,
       167, 67, 80, 72, 73, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 9, 149, 0, 0, 31, 26, 216, 44, 150,
       113, 67, 85, 69, 78, 87, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 26, 150, 0, 0, 31, 26, 216, 48, 23,
       14, 77, 83, 71, 77, 32, 32, 32, 32, 49 >>

RegShoShortSalePriceTestRestrictedIndicatorMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 20, 89, 43, 195, 0, 0, 31, 26, 216, 124, 47,
       186, 89, 67, 66, 68, 45, 65, 32, 32, 49 >>

StockTradingActionMessageCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 44, 61, 0, 0, 31, 30, 112, 58, 174,
       209, 90, 88, 90, 90, 84, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 44, 56, 0, 0, 31, 30, 154, 138, 53,
       10, 90, 86, 90, 90, 84, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 6, 171, 0, 0, 31, 31, 154, 166, 21,
       112, 67, 65, 77, 76, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 24, 141, 0, 0, 31, 36, 125, 104, 75,
       61, 76, 84, 82, 89, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

StockTradingActionMessageCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 25, 72, 9, 74, 0, 0, 31, 40, 249, 202, 30,
       58, 67, 83, 77, 68, 32, 32, 32, 32, 72, 32, 32, 32, 32, 32 >>

SystemEventMessageCapture ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 12, 83, 0, 0, 0, 0, 31, 26, 206, 219, 133,
       252, 81 >>

TradeMessageNoncrossCapture1 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 1, 199, 0, 2, 31, 26, 208, 162, 201,
       239, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 1, 65, 77,
       65, 84, 32, 32, 32, 32, 0, 23, 8, 24, 0, 0, 0, 0, 0, 0,
       104, 77 >>

TradeMessageNoncrossCapture2 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 26, 38, 0, 2, 31, 26, 224, 54, 173,
       127, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 100, 77, 79,
       65, 84, 32, 32, 32, 32, 0, 11, 235, 44, 0, 0, 0, 0, 0, 0,
       104, 99 >>

TradeMessageNoncrossCapture3 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 1, 199, 0, 2, 31, 26, 231, 179, 239,
       164, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 1, 65, 77,
       65, 84, 32, 32, 32, 32, 0, 23, 8, 24, 0, 0, 0, 0, 0, 0,
       104, 130 >>

TradeMessageNoncrossCapture4 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 44, 33, 0, 2, 31, 26, 232, 107, 25,
       170, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 24, 90, 77,
       32, 32, 32, 32, 32, 32, 0, 10, 65, 200, 0, 0, 0, 0, 0, 0,
       104, 135 >>

TradeMessageNoncrossCapture5 ==
    << 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 1, 0, 44, 80, 39, 177, 0, 2, 31, 26, 233, 59, 97,
       48, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 60, 84, 83,
       76, 65, 32, 32, 32, 32, 0, 36, 171, 228, 0, 0, 0, 0, 0, 0,
       104, 136 >>

Captures == { AddOrderNoMpidAttributionMessageCapture1, AddOrderNoMpidAttributionMessageCapture2, AddOrderNoMpidAttributionMessageCapture3, AddOrderNoMpidAttributionMessageCapture4, AddOrderNoMpidAttributionMessageCapture5, AddOrderWithMpidAttributionMessageCapture1, AddOrderWithMpidAttributionMessageCapture2, AddOrderWithMpidAttributionMessageCapture3, AddOrderWithMpidAttributionMessageCapture4, AddOrderWithMpidAttributionMessageCapture5, OrderCancelMessageCapture1, OrderCancelMessageCapture2, OrderCancelMessageCapture3, OrderCancelMessageCapture4, OrderCancelMessageCapture5, OrderDeleteMessageCapture1, OrderDeleteMessageCapture2, OrderDeleteMessageCapture3, OrderDeleteMessageCapture4, OrderDeleteMessageCapture5, OrderExecutedMessageCapture1, OrderExecutedMessageCapture2, OrderExecutedMessageCapture3, OrderExecutedMessageCapture4, OrderExecutedMessageCapture5, OrderExecutedWithPriceMessageCapture1, OrderExecutedWithPriceMessageCapture2, OrderExecutedWithPriceMessageCapture3, OrderExecutedWithPriceMessageCapture4, OrderExecutedWithPriceMessageCapture5, OrderReplaceMessageCapture1, OrderReplaceMessageCapture2, OrderReplaceMessageCapture3, OrderReplaceMessageCapture4, OrderReplaceMessageCapture5, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture1, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture2, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture3, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture4, RegShoShortSalePriceTestRestrictedIndicatorMessageCapture5, StockTradingActionMessageCapture1, StockTradingActionMessageCapture2, StockTradingActionMessageCapture3, StockTradingActionMessageCapture4, StockTradingActionMessageCapture5, SystemEventMessageCapture, TradeMessageNoncrossCapture1, TradeMessageNoncrossCapture2, TradeMessageNoncrossCapture3, TradeMessageNoncrossCapture4, TradeMessageNoncrossCapture5 }

(* Every recorded packet reads, reads whole, and writes back unchanged *)
CapturesRoundTrip ==
    \A bytes \in Captures :
        LET read == DecodePacket(bytes)
        IN  /\ read.ok
            /\ read.rest = << >>
            /\ EncodePacket(read.value) = bytes

(* Every recorded packet is bytes *)
CapturesAreBytes == \A bytes \in Captures : \A i \in 1 .. Len(bytes) : bytes[i] \in Byte

=============================================================================
