pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;
import "./FixedProductMarketMakerFactoryOR.sol";
import "./ORMarketLib.sol";
import "../TimeDependent/TimeDependent.sol";

contract ORPredictionMarket is FixedProductMarketMakerFactory, TimeDependent {

    

    ConditionalTokens public ct = ConditionalTokens(0x6A6B973E3AF061dB947673801e859159F963C026);

    address governanceAdd;

    mapping(bytes32 => address) public proposalIds;

    constructor() public {

        governanceAdd = msg.sender;
    }

    function createMarketProposal(string memory marketQuestionID, uint256 participationEndTime, uint256 resolvingEndTime, IERC20 collateralToken, uint256 initialLiq) public {
        bytes32 questionId = bytes32(marketsCount);
        require(proposalIds[questionId] == address(0), "proposal Id already used");

        ct.prepareCondition(governanceAdd, questionId, 2);
        bytes32[]  memory conditionIds = new bytes32[](1);
        conditionIds[0] = ct.getConditionId(governanceAdd, questionId, 2);

        ORFPMarket fpMarket = createFixedProductMarketMaker(ct, collateralToken, conditionIds, 20000000000000000);

        fpMarket.setConfig(marketQuestionID, msg.sender, governanceAdd, getCurrentTime(), participationEndTime, resolvingEndTime, questionId);
        
        proposalIds[questionId] = address(fpMarket);
        
        // Add liquidity
        collateralToken.transferFrom(msg.sender,address(this),initialLiq);
        collateralToken.approve(address(fpMarket),initialLiq);
        fpMarket.addLiquidity(initialLiq);
        fpMarket.transfer(msg.sender,fpMarket.balanceOf(address(this)));
        //TODO: check collateralToken is from the list
    }

    modifier governance {
        require(msg.sender == governanceAdd);
        _;
    }

    function getMarketsCount(ORMarketLib.MarketState marketState) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }
    
    function getMarketCountByProposer(address account) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }
    
    function getMarketCountByProposerNState(address account, ORMarketLib.MarketState marketState) public view returns(uint256){
        uint256 marketsInStateCount = 0;
        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                marketsInStateCount++;
            }
        }

        return marketsInStateCount;
    }

    function getMarkets(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketsCount(marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposer(account);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }
    
    
    function getMarketsByProposerNState(address account, ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposerNState(account,marketState);
            if(startIndex >= mc){
                return markets;
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return markets;
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                }
                marketInStateIndex++;
            }
        }

        return markets;
    }

    function getMarketsQuestionIDs(ORMarketLib.MarketState marketState, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketsCount(marketState);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].state() == marketState){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    function getMarketsQuestionIDsByProposer(address account, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposer(account);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }
    
    
    function getMarketsQuestionIDsByProposerNState(address account, ORMarketLib.MarketState marketStat, uint256 startIndex, int256 length) public view returns(ORFPMarket[] memory markets,string[] memory questionsIDs){
        uint256 uLength;

        if(length <0){
            uint256 mc = getMarketCountByProposerNState(account,marketStat);
            if(startIndex >= mc){
                return (markets,questionsIDs);
            }
            uLength = mc - startIndex;
        }else{
            uLength = uint256(length);
        }

        markets = new ORFPMarket[](uLength);
        questionsIDs = new string[](uLength);
        uint256 marketInStateIndex = 0;
         for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
            if(fpMarkets[marketIndex].proposer() == account && fpMarkets[marketIndex].state() == marketStat){
                if(marketInStateIndex >= startIndex){
                    uint256 currentIndex = marketInStateIndex - startIndex;
                    if(currentIndex >=  uLength){
                        return (markets,questionsIDs);
                    }

                    markets[currentIndex] = fpMarkets[marketIndex];
                    questionsIDs[currentIndex] = fpMarkets[marketIndex].getMarketQuestionID();
                }
                marketInStateIndex++;
            }
        }

        return (markets,questionsIDs);
    }

    function getMarket(string memory marketQuestionID) public view returns(ORFPMarket  market){

        for(uint256 marketIndex=0;marketIndex < marketsCount;marketIndex ++){
             string memory mqID = fpMarkets[marketIndex].getMarketQuestionID();
             if(hashCompareWithLengthCheck(mqID,marketQuestionID) == true){
                 return fpMarkets[marketIndex];
             }
        }
    }

    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);

        if(bytesA.length != bytesB.length) {
            return false;
        } else {
            return keccak256(bytesA) == keccak256(bytesB);
        }
    }
}
