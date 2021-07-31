// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/LongShortPairFinancialProductLibrary.sol";
import "./libraries/Lockable.sol";

/**
 * @title Impermanent Loss Long Short Pair Financial Product Library
 */
contract ImpermanentLossLongShortPairFinancialProductLibrary is LongShortPairFinancialProductLibrary, Lockable {
    using FixedPoint for FixedPoint.Unsigned;
    using SignedSafeMath for int256;

    struct ImpermanentLossParameters {
        uint256 priceCap;
        uint256 priceFloor;
        uint256 initialPrice; // Price in terms of paired asset
        uint256 leverageFactor;
    }

    mapping(address => ImpermanentLossParameters) public longShortPairParameters;

    function setLongShortPairParameters(
        address longShortPair,
        uint256 priceCap,
        uint256 priceFloor,
        uint256 initialPrice,
        uint256 leverageFactor
    ) public nonReentrant() {
        require(ExpiringContractInterface(longShortPair).expirationTimestamp() != 0, "Invalid LSP address");
        require(priceCap > priceFloor, "Invalid bounds");
        require(leverageFactor <= 5, "Please reduce leverageFactor"); // TODO Should leverage be capped?

        longShortPairParameters[longShortPair] = ImpermanentLossParameters({
            priceCap: priceCap,
            priceFloor: priceFloor,
            initialPrice: initialPrice,
            leverageFactor: leverageFactor
        });
    }

    // il_payout = abs((2 * sqrt(p) / p + 1) - 1) + 1
    //   where p = price_initial / price_expiry

    // Note: ETH collateral used for this synth

    // TODO write example
    // Ex.
    // price_initial =
    // price_expiry =
    // cap =
    // floor =
    // leverageFactor =

    // p =
    // => il_payout =
    function percentageLongCollateralAtExpiry(int256 expiryPrice)
        public
        view
        override
        nonReentrantView()
        returns (uint256)
    {
        ImpermanentLossParameters memory params = longShortPairParameters[msg.sender];

        require(params.priceCap != 0 || params.priceFloor != 0, "Params not set for calling LSP");

        // Expiry price should always be above 0
        uint256 positiveExpiryPrice = expiryPrice > 0 ? uint256(expiryPrice) : 0;

        // Find ratio of price_initial to price_expiry
        FixedPoint.Unsigned memory priceRatio =
            FixedPoint.div(
                FixedPoint.fromUnscaledUint(params.initialPrice),
                FixedPoint.fromUnscaledUint(positiveExpiryPrice)
            );

        // Perform IL calculation
        int256 impLoss = 0; // 2 * sqrt(priceRatio) / (priceRatio + 1)

        // Take inverse of IL and add 1 to make synth payout
        uint256 impLossPayout = 0; //abs(impLoss) + 1

        //int256 levEthReturn = intEthReturn * int256(params.leverageFactor);
        //int256 levEthPrice = levEthReturn + 1e18;
        ////ensure positivity before converting back to uint
        //uint256 positiveLevEthPrice = levEthPrice >= int256(params.priceFloor) ? uint256(levEthPrice) : 0;
        //uint256 upperCappedLevEthPrice =
        //    FixedPoint.max(FixedPoint.Unsigned(positiveLevEthPrice), FixedPoint.Unsigned(params.priceFloor)).rawValue;
        //return
        //    FixedPoint.min(FixedPoint.Unsigned(upperCappedLevEthPrice), FixedPoint.Unsigned(params.priceCap)).rawValue;
        //do one more test on this
    }
}
